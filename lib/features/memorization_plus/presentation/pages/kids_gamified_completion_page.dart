import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_reward_dialog.dart';

class KidsGamifiedCompletionPage extends StatefulWidget {
  const KidsGamifiedCompletionPage({
    super.key,
    required this.surahId,
    required this.completedAyahNumber,
    this.starsEarned = 1,
    this.gemsEarned = 0,
    this.onNext,
    this.onReturnToMap,
  });

  final int surahId;
  final int completedAyahNumber;
  final int starsEarned;
  final int gemsEarned;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  State<KidsGamifiedCompletionPage> createState() =>
      _KidsGamifiedCompletionPageState();
}

class _KidsGamifiedCompletionPageState
    extends State<KidsGamifiedCompletionPage> {
  bool? _hasNextAyah;

  @override
  void initState() {
    super.initState();
    _loadNextAyahAvailability();
  }

  Future<void> _loadNextAyahAvailability() async {
    final result = await getIt<QuranRepository>().getSurahDetail(
      widget.surahId,
    );
    if (!mounted) return;
    final ayahCount = result.fold(
      (_) => null,
      (detail) => detail.surah.ayahCount,
    );
    setState(() {
      _hasNextAyah =
          ayahCount != null && widget.completedAyahNumber < ayahCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KidsGamifiedCompletionContent(
      starsEarned: widget.starsEarned,
      gemsEarned: widget.gemsEarned,
      showNextButton: _hasNextAyah ?? true,
      onNext: widget.onNext ?? () => _openNextAyah(context),
      onReturnToMap: widget.onReturnToMap ?? () => _returnToMap(context),
    );
  }

  Future<void> _openNextAyah(BuildContext context) async {
    if (_hasNextAyah == false) {
      _returnToMap(context);
      return;
    }

    final result = await getIt<QuranRepository>().getSurahDetail(
      widget.surahId,
    );
    if (!context.mounted) return;

    final ayahCount = result.fold(
      (_) => null,
      (detail) => detail.surah.ayahCount,
    );
    if (ayahCount == null || widget.completedAyahNumber >= ayahCount) {
      _returnToMap(context);
      return;
    }

    context.pushReplacement(
      '${AppRoutes.memorizationPlusKids}?surahId=${widget.surahId}'
      '&ayahNumber=${widget.completedAyahNumber + 1}',
    );
  }

  void _returnToMap(BuildContext context) {
    context.go(
      '${AppRoutes.memorizationPlusKidsJourney}?surahId=${widget.surahId}',
    );
  }
}

@visibleForTesting
class KidsGamifiedCompletionContent extends StatelessWidget {
  const KidsGamifiedCompletionContent({
    super.key,
    required this.starsEarned,
    this.gemsEarned = 0,
    this.showNextButton = true,
    required this.onNext,
    required this.onReturnToMap,
  });

  final int starsEarned;
  final int gemsEarned;
  final bool showNextButton;
  final VoidCallback onNext;
  final VoidCallback onReturnToMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: KidsRewardDialog(
                starsEarned: starsEarned,
                gemsEarned: gemsEarned,
                showNextButton: showNextButton,
                onNext: onNext,
                onReturnToMap: onReturnToMap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
