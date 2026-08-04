import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_cloud_gateway.dart';
import 'memorization_profile_store.dart';

/// Guardian pairing, child-link tokens and parent-guardian mode.
///
/// Owns the child↔guardian relationship lifecycle: pairing sessions (QR/code),
/// token creation/acceptance with server-side hashing, server-side revocation
/// and the parent-guardian mode toggle.
class MemorizationParentAccessService {
  MemorizationParentAccessService(
    this._datasource,
    this._profileStore,
    this._gateway,
  );

  static const _pairingSessionLifetime = Duration(minutes: 10);

  final MemorizationPlusLocalDatasource _datasource;
  final MemorizationProfileStore _profileStore;
  final MemorizationCloudGateway _gateway;

  Either<Failure, SupabaseClient> get _supabaseOrFailure =>
      _gateway.supabaseOrFailure();

  Future<MemorizationProfile> _loadProfile() => _profileStore.loadProfile();

  Future<MemorizationProfile> _saveProfile(MemorizationProfile profile) =>
      _profileStore.saveProfile(profile);

  Future<Either<Failure, PairingSession>> createGuardianPairingSession() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) {
        return const Left(
          CacheFailure('Guardian linking is only for children'),
        );
      }
      if (profile.isGuardianLinked) {
        return const Left(
          CacheFailure('Unlink the current guardian before linking another'),
        );
      }
      final tokenResult = await createChildLinkToken();
      return await tokenResult.fold((failure) async => Left(failure), (
        token,
      ) async {
        final now = DateTime.now();
        final session = PairingSession(
          id: now.microsecondsSinceEpoch.toString(),
          pairingCode: token,
          qrData: 'talia-kids-link:$token',
          createdAt: now,
          expiresAt: now.add(_pairingSessionLifetime),
          status: PairingSessionStatus.pending,
          isUsed: false,
        );
        await _datasource.savePairingSession(
          PairingSessionModel.fromEntity(session),
        );
        await _saveProfile(
          profile.copyWith(
            guardianLinkStatus: GuardianLinkStatus.pending,
            guardianOnboardingStatus: GuardianOnboardingStatus.required,
          ),
        );
        return Right(session);
      });
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  ) async {
    try {
      final result = await acceptChildLinkToken(codeOrQrData);
      return await result.fold((failure) async => Left(failure), (_) async {
        final clientResult = _supabaseOrFailure;
        final clientFailure = clientResult.fold(
          (failure) => failure,
          (_) => null,
        );
        if (clientFailure != null) return Left(clientFailure);
        final client = clientResult.getOrElse(
          () => throw StateError('unreachable'),
        );

        final userId = client.auth.currentUser?.id;
        final profile = await _loadProfile();
        final linkedChildId = !profile.isChild && userId != null
            ? await _gateway.latestActiveChildIdForParent(userId)
            : null;
        final guardianId = profile.isChild && userId != null
            ? await _gateway.activeGuardianIdForChild(userId)
            : null;
        final saved = await _saveProfile(
          profile.isChild
              ? profile.copyWith(
                  guardianLinkStatus: GuardianLinkStatus.linked,
                  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
                  guardianId: guardianId ?? userId,
                )
              : profile.copyWith(
                  isParentGuardian: true,
                  linkedChildId: linkedChildId,
                ),
        );
        await _datasource.setIsParentMode(saved.isParentGuardian);
        final session = await _datasource.getPairingSession();
        if (session != null) {
          await _datasource.savePairingSession(
            PairingSessionModel.fromEntity(
              session.copyWith(
                status: PairingSessionStatus.completed,
                isUsed: true,
                guardianId: userId,
              ),
            ),
          );
        }
        return Right(saved);
      });
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, PairingSession?>> refreshPairingSession() async {
    try {
      final session = await _datasource.getPairingSession();
      if (session == null) return const Right(null);
      if (session.status == PairingSessionStatus.pending &&
          DateTime.now().isAfter(session.expiresAt)) {
        final expired = session.copyWith(
          status: PairingSessionStatus.expired,
          failureReason: 'Code expired',
        );
        await _datasource.savePairingSession(
          PairingSessionModel.fromEntity(expired),
        );
        final profile = await _loadProfile();
        if (profile.guardianLinkStatus == GuardianLinkStatus.pending) {
          await _saveProfile(
            profile.copyWith(guardianLinkStatus: GuardianLinkStatus.none),
          );
        }
        return Right(expired);
      }
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, MemorizationProfile>> unlinkGuardian() async {
    try {
      final profile = await _loadProfile();
      // Server-side revocation must succeed first: the DB must never disagree
      // with what the child device believes about the link (Phase 5).
      final guardianId = profile.guardianId;
      if (guardianId != null) {
        final revokeResult = await revokeGuardianLink(guardianId);
        final revokeFailure = revokeResult.fold(
          (failure) => failure,
          (_) => null,
        );
        if (revokeFailure != null) return Left(revokeFailure);
      }
      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          clearGuardianId: true,
          clearLinkedChildId: true,
        ),
      );
      await _datasource.clearPairingSession();
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) async {
    try {
      final profile = await _loadProfile();
      if (value && profile.selectedPath != MemorizationPath.adult) {
        return const Left(
          CacheFailure('Parent guardian mode is only available for adults'),
        );
      }
      final saved = await _saveProfile(
        profile.copyWith(isParentGuardian: value, clearLinkedChildId: !value),
      );
      await _datasource.setIsParentMode(value);
      if (!value) {
        await _datasource.clearPairingSession();
      }
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, MemorizationProfile>>
  refreshChildGuardianLink() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) return Right(profile);
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Right(profile);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) return Right(profile);

      final guardianId = await _gateway.activeGuardianIdForChild(user.id);
      if (guardianId != null) {
        final saved = await _saveProfile(
          profile.copyWith(
            guardianLinkStatus: GuardianLinkStatus.linked,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            guardianId: guardianId,
          ),
        );
        final session = await _datasource.getPairingSession();
        if (session != null && session.status == PairingSessionStatus.pending) {
          await _datasource.savePairingSession(
            PairingSessionModel.fromEntity(
              session.copyWith(
                status: PairingSessionStatus.completed,
                isUsed: true,
                guardianId: guardianId,
              ),
            ),
          );
        }
        return Right(saved);
      }

      if (!profile.isGuardianLinked) return Right(profile);

      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          clearGuardianId: true,
        ),
      );
      return Right(saved);
    } catch (_) {
      return Right(await _loadProfile());
    }
  }

  Future<Either<Failure, String>> createChildLinkToken() async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure('Guardian linking requires signing in first'),
        );
      }

      // Generate random 12-char uppercase hex token (no pgcrypto needed)
      final rng = Random.secure();
      final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      final token = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .substring(0, 12)
          .toUpperCase();

      // Hash the token with SHA-256 (matches what the DB used to do)
      final tokenHash = sha256.convert(utf8.encode(token)).toString();

      await client.rpc(
        'create_child_link_request_with_hash',
        params: {'p_token_hash': tokenHash},
      );

      return Right(token);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> acceptChildLinkToken(String token) async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure('سجّل الدخول أولاً على جهاز ولي الأمر'),
        );
      }
      // Hash the token client-side (no pgcrypto needed)
      final rawToken = _extractToken(token).toUpperCase().trim();
      final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
      await client.rpc(
        'accept_child_link_token_with_hash',
        params: {'p_token_hash': tokenHash},
      );
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> revokeGuardianLink(
    String counterpartUserId,
  ) async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      await client.rpc(
        'revoke_guardian_link',
        params: {'p_counterpart_user_id': counterpartUserId},
      );
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> removeChild(String childUserId) =>
      revokeGuardianLink(childUserId);

  Either<Failure, bool> getIsParentMode() {
    try {
      // Synchronous fast-path: check the cached datasource profile first.
      // The profile is always written by saveProfile which keeps the legacy
      // flag in sync, so this is safe and avoids an async round-trip.
      return Right(_datasource.getIsParentMode());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Async variant that reads the authoritative MemorizationProfile.
  /// Prefer this over [getIsParentMode] wherever async is acceptable.
  Future<Either<Failure, bool>> getIsParentModeFromProfile() async {
    try {
      final profile = await _loadProfile();
      return Right(profile.isParentGuardian);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> setIsParentMode(bool value) async {
    try {
      final result = await setParentGuardianMode(value);
      return result.fold(Left.new, (_) => const Right(null));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  String _extractToken(String raw) {
    const prefix = 'talia-kids-link:';
    final trimmed = raw.trim();
    return trimmed.toLowerCase().startsWith(prefix)
        ? trimmed.substring(prefix.length)
        : trimmed;
  }
}
