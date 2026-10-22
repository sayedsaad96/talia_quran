import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_attempt_service.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_confusion_detector.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AccountDataBarrier barrier;
  const owner = FixedRecordOwnerProvider('owner-a');
  const spoken = 'one two three four';
  final evidence = const V2RecitationEvaluator().evaluate(
    targetText: 'alpha beta gamma delta',
    spokenText: spoken,
  );
  late int profileReads;
  late int candidateReads;
  late bool enabled;
  late bool adult;
  late Future<List<SimilarAyahCandidate>?> Function() load;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    )..owner = owner;
    profileReads = candidateReads = 0;
    enabled = adult = true;
    load = () async => const [SimilarAyahCandidate(key: '2:2', text: spoken)];
  });

  SimilarAyahAttemptService service() => SimilarAyahAttemptService(
    owner: owner,
    barrier: barrier,
    isEnabled: () => enabled,
    readAdultEligibility: () async {
      profileReads++;
      return adult;
    },
    candidates: _Source((key) {
      candidateReads++;
      return load();
    }),
  );

  test('captures owner before loading and returns identifiers only', () async {
    final coordinator = service();
    final authority = coordinator.captureAuthority()!;
    final match = await coordinator.detect(
      authority: authority,
      targetKey: '2:1',
      spokenText: spoken,
      original: evidence,
      phase: V2SessionPhase.reciting,
      acceptedFailure: true,
    );
    expect(authority.ownerId, 'owner-a');
    expect(match?.otherKey, '2:2');
    expect(profileReads, 1);
    expect(candidateReads, 1);
  });

  test(
    'disabled and nonfailure attempts do not read profile or corpus',
    () async {
      final coordinator = service();
      final enabledAuthority = coordinator.captureAuthority()!;
      enabled = false;
      expect(
        await coordinator.detect(
          authority: enabledAuthority,
          targetKey: '2:1',
          spokenText: spoken,
          original: evidence,
          phase: V2SessionPhase.reciting,
          acceptedFailure: true,
        ),
        isNull,
      );
      enabled = true;
      expect(
        await coordinator.detect(
          authority: coordinator.captureAuthority()!,
          targetKey: '2:1',
          spokenText: spoken,
          original: evidence,
          phase: V2SessionPhase.blockReview,
          acceptedFailure: true,
        ),
        isNull,
      );
      expect(profileReads, 0);
      expect(candidateReads, 0);
    },
  );

  test('trainer off: no authority, even while the account barrier is blocked '
      '(sessions keep the pre-trainer path)', () {
    enabled = false;
    barrier.prepareOwner('owner-b');
    expect(service().captureAuthority(), isNull);
    enabled = true;
    expect(
      () => service().captureAuthority(),
      throwsA(isA<AccountDataUnavailableException>()),
    );
  });

  test(
    'requires authoritative adult profile before loading candidates',
    () async {
      adult = false;
      final coordinator = service();
      expect(
        await coordinator.detect(
          authority: coordinator.captureAuthority()!,
          targetKey: '2:1',
          spokenText: spoken,
          original: evidence,
          phase: V2SessionPhase.reciting,
          acceptedFailure: true,
        ),
        isNull,
      );
      expect(candidateReads, 0);
    },
  );

  test(
    'candidate failures abstain without exposing exception payloads',
    () async {
      load = () async => throw StateError('ephemeral payload');
      final coordinator = service();
      expect(
        await coordinator.detect(
          authority: coordinator.captureAuthority()!,
          targetKey: '2:1',
          spokenText: spoken,
          original: evidence,
          phase: V2SessionPhase.reciting,
          acceptedFailure: true,
        ),
        isNull,
      );
      expect(evidence.passed, isFalse);
    },
  );

  test(
    'account invalidation during candidate load discards old evidence',
    () async {
      final pending = Completer<List<SimilarAyahCandidate>?>();
      final started = Completer<void>();
      load = () {
        started.complete();
        return pending.future;
      };
      final coordinator = service();
      final result = coordinator.detect(
        authority: coordinator.captureAuthority()!,
        targetKey: '2:1',
        spokenText: spoken,
        original: evidence,
        phase: V2SessionPhase.reciting,
        acceptedFailure: true,
      );
      await started.future;
      barrier.invalidate();
      pending.complete(const [SimilarAyahCandidate(key: '2:2', text: spoken)]);
      await expectLater(
        result,
        throwsA(isA<AccountDataUnavailableException>()),
      );
    },
  );

  test(
    'unapproved candidate source abstains without an asset lookup',
    () async {
      expect(
        await const UnavailableSimilarAyahCandidateSource().loadCandidates(
          '2:1',
        ),
        isNull,
      );
    },
  );
}

final class _Source implements SimilarAyahCandidateSource {
  const _Source(this.load);
  final Future<List<SimilarAyahCandidate>?> Function(String) load;
  @override
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey) =>
      load(targetKey);
}
