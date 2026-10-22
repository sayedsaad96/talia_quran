import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/prayer_review/prayer_review_home_loader.dart';
import '../../../../core/prayer_review/prayer_review_notification_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../prayer_companion/domain/entities/prayer_companion.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

/// A Home-only fallback for a prayer-review occurrence that has no configured
/// Companion preparation notification. It owns no selection or review data.
class PrayerReviewHomeSlot extends StatefulWidget {
  const PrayerReviewHomeSlot({
    super.key,
    required this.skin,
    required this.isEnabled,
    required this.isAdult,
    this.loader,
    this.loadOffer,
    this.accountChanges,
    this.onOpen,
    this._now,
  });

  final HomeSkin skin;
  final bool isEnabled;
  final bool isAdult;
  final PrayerReviewHomeLoader? loader;
  final Future<PrayerReviewHomeOffer?> Function()? loadOffer;
  final Stream<void>? accountChanges;
  final FutureOr<void> Function(PrayerOccurrence occurrence)? onOpen;
  final DateTime Function()? _now;

  @override
  State<PrayerReviewHomeSlot> createState() => _PrayerReviewHomeSlotState();
}

class _PrayerReviewHomeSlotState extends State<PrayerReviewHomeSlot> {
  PrayerReviewHomeLoader? _loader;
  PrayerReviewHomeOffer? _offer;
  StreamSubscription<void>? _changes;
  Timer? _ticker;
  Timer? _expiry;
  var _generation = 0;

  bool get _allowed => widget.isEnabled && widget.isAdult;
  DateTime get _now => (widget._now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant PrayerReviewHomeSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled ||
        oldWidget.isAdult != widget.isAdult ||
        oldWidget.loader != widget.loader ||
        oldWidget.loadOffer != widget.loadOffer) {
      _stop();
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (!_allowed) {
      return;
    }
    _loader = widget.loader ?? _registeredLoader();
    final changes = widget.accountChanges ?? _loader?.accountChanges;
    _changes = changes?.listen((_) => _invalidate());
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _refresh();
  }

  PrayerReviewHomeLoader? _registeredLoader() {
    final services = GetIt.instance;
    if (!services.isRegistered<PrayerReviewHomeLoader>()) {
      return null;
    }
    return services<PrayerReviewHomeLoader>();
  }

  void _stop() {
    _generation++;
    _changes?.cancel();
    _ticker?.cancel();
    _expiry?.cancel();
    _changes = null;
    _ticker = null;
    _expiry = null;
    _loader = null;
    _offer = null;
  }

  Future<void> _refresh() async {
    if (!_allowed) {
      return;
    }
    final load = widget.loadOffer ?? _loader?.load;
    if (load == null) {
      return;
    }
    final request = ++_generation;
    try {
      final loaded = await load();
      if (!mounted || request != _generation || !_allowed) {
        return;
      }
      if (loaded == null || !_now.isBefore(loaded.occurrence.scheduledAt)) {
        _clear();
        return;
      }
      setState(() => _offer = loaded);
      _scheduleExpiry(loaded.occurrence.scheduledAt);
    } catch (_) {
      if (mounted && request == _generation) {
        _clear();
      }
    }
  }

  void _invalidate() {
    _generation++;
    _clear();
  }

  void _clear() {
    _expiry?.cancel();
    _expiry = null;
    if (mounted && _offer != null) setState(() => _offer = null);
  }

  void _scheduleExpiry(DateTime prayerAt) {
    _expiry?.cancel();
    final delay = prayerAt.difference(_now);
    if (delay <= Duration.zero) {
      _clear();
      return;
    }
    _expiry = Timer(delay, _invalidate);
  }

  Future<void> _open(PrayerReviewHomeOffer offer) async {
    try {
      if (!_allowed || !_now.isBefore(offer.occurrence.scheduledAt)) {
        _invalidate();
        return;
      }
      offer.offer.authority.check();
      final callback = widget.onOpen;
      if (callback != null) {
        await Future<void>.sync(() => callback(offer.occurrence));
      } else if (mounted) {
        await context.push(AppRoutes.prayerReview, extra: offer.occurrence);
      }
    } catch (_) {
      _invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    if (!_allowed || offer == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final reference = prayerReviewReference(offer.offer.selection, l10n);
    return Semantics(
      container: true,
      label: l10n.prayerReviewTitle,
      child: GlassPanel(
        skin: widget.skin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.prayerReviewTitle,
              style: AppTypography.titleMedium.copyWith(
                color: widget.skin.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.prayerReviewSuggestion(reference),
              style: AppTypography.bodySmall.copyWith(
                color: widget.skin.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('prayer_review_home_open'),
                onPressed: () => _open(offer),
                style: TextButton.styleFrom(
                  foregroundColor: widget.skin.accent,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                child: Text(l10n.prayerReviewTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
