import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/plan_schedule_policy.dart';
import '../cubits/custom_plan_cubit.dart';

part 'custom_plan_setup_form.dart';
part 'custom_plan_setup_selectors.dart';
part 'custom_plan_setup_widgets.dart';
part 'custom_plan_setup_shared.dart';

const List<int> _standardSurahAyahCounts = [
  0,
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

class CustomPlanSetupPage extends StatelessWidget {
  const CustomPlanSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomPlanCubit>()..load(),
      child: const _CustomPlanSetupView(),
    );
  }
}

class _CustomPlanSetupView extends StatefulWidget {
  const _CustomPlanSetupView();

  @override
  State<_CustomPlanSetupView> createState() => _CustomPlanSetupViewState();
}

abstract class _CustomPlanSetupController extends State<_CustomPlanSetupView> {
  void applyPlanChange(VoidCallback change) => setState(change);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startAyahController = TextEditingController(text: '1');

  int _startSurahId = 1;
  int _endSurahId = 114;
  int _startAyah = 1;
  int _newAyahsPerDay = 3;

  /// The quick preset last applied; it stays highlighted while its values
  /// are unchanged.
  ({String name, int newAyahs, int days, int minutes})? _appliedPreset;

  String? get _activePresetName {
    final preset = _appliedPreset;
    if (preset == null ||
        preset.newAyahs != _newAyahsPerDay ||
        preset.days != _availableDays ||
        preset.minutes != _sessionMinutes) {
      return null;
    }
    return preset.name;
  }

  int _availableDays = 7;
  int _sessionMinutes = 30;
  MemorizationDifficulty _difficulty = MemorizationDifficulty.moderate;
  bool _enableNearRevision = true;
  bool _enableFarRevision = true;
  int _nearRevisionCount = 5;
  int _farRevisionCount = 3;
  PlanTargetUser _targetUser = PlanTargetUser.adult;
  bool _didLoadSurahNames = false;

  /// Surah names loaded from data layer (1-indexed, index 0 is placeholder)
  List<String> _surahNames = [''];
  List<int> _surahAyahCounts = _standardSurahAyahCounts;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final formatted = context.digitText(
      LocaleNumberFormatter.western(_startAyahController.text),
    );
    if (_startAyahController.text != formatted) {
      _startAyahController.value = _startAyahController.value.copyWith(
        text: formatted,
      );
    }
    if (_didLoadSurahNames) return;
    _didLoadSurahNames = true;
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final surahsResult = await getIt<QuranRepository>().getSurahs();
      surahsResult.fold(
        (failure) {
          _loadFallbackSurahNames();
        },
        (surahs) {
          if (mounted) {
            final isArabic = context.isArabic;
            setState(() {
              _surahNames = [
                '',
                ...surahs.map((s) => isArabic ? s.nameAr : s.nameEn),
              ];
              _surahAyahCounts = [0, ...surahs.map((s) => s.ayahCount)];
              _clampStartAyahForSurah();
            });
          }
        },
      );
    } catch (_) {
      _loadFallbackSurahNames();
    }
  }

  void _loadFallbackSurahNames() {
    if (mounted) {
      final surahLabel = context.l10n.surah;
      setState(() {
        _surahNames = List.generate(115, (i) => i == 0 ? '' : '$surahLabel $i');
        _surahAyahCounts = _standardSurahAyahCounts;
        _clampStartAyahForSurah();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startAyahController.dispose();
    super.dispose();
  }

  void _populateFromExisting(CustomMemorizationPlan plan) {
    _nameController.text = plan.name;
    _startSurahId = plan.startSurahId;
    _endSurahId = plan.endSurahId;
    _startAyah = plan.startAyah;
    _startAyahController.text = context.numText(_startAyah);
    _newAyahsPerDay = plan.newAyahsPerDay;
    _availableDays = plan.availableDaysPerWeek;
    _sessionMinutes = plan.sessionMinutes;
    _difficulty = plan.difficulty;
    _enableNearRevision = plan.enableNearRevision;
    _enableFarRevision = plan.enableFarRevision;
    _nearRevisionCount = plan.nearRevisionCount;
    _farRevisionCount = plan.farRevisionCount;
    _targetUser = plan.targetUser;
  }

  void _applyPreset({
    required String name,
    required int newAyahs,
    required int days,
    required int minutes,
    required MemorizationDifficulty difficulty,
    int? startSurahId,
    int? endSurahId,
  }) {
    setState(() {
      _appliedPreset = (
        name: name,
        newAyahs: newAyahs,
        days: days,
        minutes: minutes,
      );
      _nameController.text = name;
      _newAyahsPerDay = newAyahs;
      _availableDays = days;
      _sessionMinutes = minutes;
      _difficulty = difficulty;
      if (startSurahId != null) _startSurahId = startSurahId;
      if (endSurahId != null) _endSurahId = endSurahId;
      _clampStartAyahForSurah();
    });
  }

  int _ayahCountForSurah(int surahId) {
    if (surahId >= 1 && surahId < _surahAyahCounts.length) {
      return _surahAyahCounts[surahId];
    }
    return 286;
  }

  void _setStartSurah(int surahId) {
    _startSurahId = surahId;
    // Entry/exit model (no forced ordering): "من" is where memorization
    // starts, "إلى" is where it ends — either direction is legal (a Juz Amma
    // plan runs 114 → 78). The direction hint below makes the flow explicit.
    _clampStartAyahForSurah();
  }

  void _clampStartAyahForSurah() {
    final maxAyah = _ayahCountForSurah(_startSurahId);
    if (_startAyah > maxAyah) {
      _startAyah = maxAyah;
      _startAyahController.text = context.numText(_startAyah);
    }
    if (_startAyah < 1) {
      _startAyah = 1;
      _startAyahController.text = context.numText(1);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _startAyah =
        int.tryParse(
          LocaleNumberFormatter.western(_startAyahController.text.trim()),
        ) ??
        _startAyah;

    final plan = CustomMemorizationPlan(
      name: _nameController.text.trim(),
      startSurahId: _startSurahId,
      endSurahId: _endSurahId,
      startAyah: _startAyah,
      newAyahsPerDay: _newAyahsPerDay,
      availableDaysPerWeek: _availableDays,
      sessionMinutes: _sessionMinutes,
      difficulty: _difficulty,
      enableNearRevision: _enableNearRevision,
      enableFarRevision: _enableFarRevision,
      nearRevisionCount: _nearRevisionCount,
      farRevisionCount: _farRevisionCount,
      createdAt: DateTime.now(),
      targetUser: _targetUser,
    );

    context.read<CustomPlanCubit>().savePlan(plan);
  }

  Future<void> _goToSavedPlan(
    BuildContext context,
    CustomMemorizationPlan plan,
  ) async {
    final resolver = MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    );
    final destination = plan.targetUser == PlanTargetUser.child
        ? await resolver.childOnboardingLocation()
        : await resolver.adultEntryLocation();
    if (!context.mounted) return;
    context.go(destination);
  }

  Future<void> _showDeletePlanConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeletePlanDialog(
        confirmText: context.l10n.customPlanDeleteConfirmPhrase,
        title: context.l10n.customPlanDeleteTitle,
        keepsText: context.l10n.customPlanDeleteKeeps,
        removesText: context.l10n.customPlanDeleteRemoves,
        instructionText: context.l10n.customPlanDeleteInstruction,
        cancelText: context.l10n.cancel,
        actionText: context.l10n.customPlanDeleteAction,
      ),
    );

    if (confirmed == true && context.mounted) {
      unawaited(context.read<CustomPlanCubit>().deletePlan());
    }
  }
}

class _CustomPlanSetupViewState extends _CustomPlanSetupController
    with _CustomPlanRangeFields, _CustomPlanSelectors {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: BlocConsumer<CustomPlanCubit, CustomPlanState>(
        listener: (context, state) {
          if (state is CustomPlanSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.customPlanSaved),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
            // Navigate directly into the freshly saved plan (session/journey)
            // instead of dropping the user back on the hub.
            _goToSavedPlan(context, state.plan);
          } else if (state is CustomPlanLoaded) {
            _populateFromExisting(state.plan);
          }
        },
        builder: (context, state) {
          if (state is CustomPlanLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return _CustomPlanFormBody(
            host: this,
            planState: state,
            isDark: isDark,
            primaryColor: primaryColor,
          );
        },
      ),
    );
  }
}
