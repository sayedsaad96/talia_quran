import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../cubits/memorization_identity_cubit.dart';
import '../widgets/memorization_path_choice_card.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../../../core/extensions/context_extensions.dart';

class PathSelectionPage extends StatelessWidget {
  const PathSelectionPage({super.key, this.preferredPath});

  final MemorizationPath? preferredPath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MemorizationIdentityCubit>(),
      child: _PathSelectionView(preferredPath: preferredPath),
    );
  }
}

class _PathSelectionView extends StatelessWidget {
  const _PathSelectionView({this.preferredPath});

  final MemorizationPath? preferredPath;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.memorizationPathTitle,
      body: BlocConsumer<MemorizationIdentityCubit, MemorizationIdentityState>(
        listener: (context, state) {
          if (state is MemorizationIdentitySuccess) {
            final profile = state.profile;
            if (profile.isAdult) {
              unawaited(_goToAdultEntry(context));
            } else if (profile.isChild) {
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthAuthenticated) {
                context.go(AppRoutes.memorizationPlusGuardianLinking);
              } else {
                unawaited(_goToKidsEntry(context));
              }
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is MemorizationIdentityLoading;
          final isDark = context.isDark;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.memorizationPathQuestion,
                      style: AppTypography.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.memorizationPathDescription,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state is MemorizationIdentityError) ...[
                      const SizedBox(height: 20),
                      ErrorInfoBanner(
                        type: ErrorInfoBannerType.error,
                        title:
                            context.l10n.memorizationPathSelectionFailedTitle,
                        message: state.message,
                      ),
                    ],
                    const SizedBox(height: 48),
                    ..._pathCards(context, isLoading),
                    if (isLoading) ...[
                      const SizedBox(height: 32),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _goToAdultEntry(BuildContext context) async {
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).adultEntryLocation();
    if (context.mounted) context.go(location);
  }

  Future<void> _goToKidsEntry(BuildContext context) async {
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).childOnboardingLocation();
    if (context.mounted) context.go(location);
  }

  List<Widget> _pathCards(BuildContext context, bool isLoading) {
    final adultsCard = MemorizationPathChoiceCard(
      title: context.l10n.memorizationPathAdultsTitle,
      description: context.l10n.memorizationPathAdultsDesc,
      icon: Icons.person_outline,
      accentColor: AppColors.primary,
      isLoading: isLoading,
      onTap: () {
        _confirmPathSelection(
          context,
          path: MemorizationPath.adult,
          title: context.l10n.memorizationPathAdultsTitle,
          description: context.l10n.memorizationPathAdultsDesc,
        );
      },
    );
    final kidsCard = MemorizationPathChoiceCard(
      title: context.l10n.memorizationPathKidsTitle,
      description: context.l10n.memorizationPathKidsDesc,
      icon: Icons.child_care,
      accentColor: AppColors.primaryLight,
      isLoading: isLoading,
      onTap: () => _showChildSetup(context),
    );
    const spacer = SizedBox(height: 24);

    if (preferredPath == MemorizationPath.child) {
      return [kidsCard, spacer, adultsCard];
    }
    return [adultsCard, spacer, kidsCard];
  }

  Future<void> _showChildSetup(BuildContext context) async {
    final draft = await showModalBottomSheet<_ChildSetupDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ChildSetupSheet(),
    );
    if (draft == null || !context.mounted) return;
    unawaited(
      context.read<MemorizationIdentityCubit>().setupChild(
        nickname: draft.nickname,
        age: draft.age,
        pin: draft.pin,
        reminderHour: draft.reminderHour,
        reminderMinute: draft.reminderMinute,
        weeklyGoalSessions: draft.weeklyGoalSessions,
        guidanceAudioEnabled: draft.guidanceAudioEnabled,
        startingSurahId: draft.startingSurahId,
      ),
    );
  }

  Future<void> _confirmPathSelection(
    BuildContext context, {
    required MemorizationPath path,
    required String title,
    required String description,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.memorizationPathConfirmTitle,
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$title\n$description',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.memorizationPathCanChangeLater,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(context.l10n.confirm),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<MemorizationIdentityCubit>().selectPath(path));
    }
  }
}

class _ChildSetupDraft {
  const _ChildSetupDraft({
    required this.nickname,
    required this.age,
    required this.pin,
    required this.reminderHour,
    required this.reminderMinute,
    required this.weeklyGoalSessions,
    required this.guidanceAudioEnabled,
    required this.startingSurahId,
  });

  final String nickname;
  final int age;
  final String pin;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyGoalSessions;
  final bool guidanceAudioEnabled;
  final int startingSurahId;
}

class _ChildSetupSheet extends StatefulWidget {
  const _ChildSetupSheet();

  @override
  State<_ChildSetupSheet> createState() => _ChildSetupSheetState();
}

class _ChildSetupSheetState extends State<_ChildSetupSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _pinController;
  late final TextEditingController _confirmPinController;
  var _age = 6;
  var _reminderTime = const TimeOfDay(hour: 18, minute: 30);
  var _weeklyGoalSessions = 5;
  var _guidanceAudioEnabled = true;
  var _startingSurahId = 114;
  var _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _pinController = TextEditingController();
    _confirmPinController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _refreshValidity() {
    setState(() {
      _canSubmit =
          _nameController.text.trim().isNotEmpty &&
          _pinController.text.length == 4 &&
          _pinController.text == _confirmPinController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.memorizationPathKidsTitle,
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.name,
                  hintText: context.l10n.enterName,
                ),
                onChanged: (_) => _refreshValidity(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _age,
                decoration: InputDecoration(
                  labelText: context.l10n.age,
                ),
                items: [
                  for (var value = 5; value <= 12; value++)
                    DropdownMenuItem(
                      value: value,
                      child: Text('$value'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _age = value;
                      _guidanceAudioEnabled = value <= 7;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _startingSurahId,
                decoration: InputDecoration(
                  labelText: context.l10n.kidsSetupStartingSurah,
                ),
                items: [
                  for (var value = 114; value >= 78; value--)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        context.isArabic
                            ? SurahNames.nameAr(value)
                            : SurahNames.nameEn(value),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _startingSurahId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _weeklyGoalSessions,
                decoration: InputDecoration(
                  labelText: context.l10n.kidsSetupWeeklyGoal,
                ),
                items: [
                  for (final value in const [3, 5, 7])
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        context.l10n.kidsSetupWeeklyGoalValue(value),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _weeklyGoalSessions = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.kidsSetupReminderTime),
                trailing: TextButton(
                  onPressed: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (selected != null && mounted) {
                      setState(() => _reminderTime = selected);
                    }
                  },
                  child: Text(_reminderTime.format(context)),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.kidsGuidanceAudioTitle),
                subtitle: Text(
                  context.l10n.kidsGuidanceAudioDescription,
                ),
                value: _guidanceAudioEnabled,
                onChanged: (value) {
                  setState(() => _guidanceAudioEnabled = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.parentDashboardCreatePinTitle,
                  helperText: context.l10n.parentDashboardPinHelp,
                ),
                onChanged: (_) => _refreshValidity(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.parentDashboardPinConfirm,
                ),
                onChanged: (_) => _refreshValidity(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: !_canSubmit
                    ? null
                    : () => Navigator.pop(
                        context,
                        _ChildSetupDraft(
                          nickname: _nameController.text.trim(),
                          age: _age,
                          pin: _pinController.text,
                          reminderHour: _reminderTime.hour,
                          reminderMinute: _reminderTime.minute,
                          weeklyGoalSessions: _weeklyGoalSessions,
                          guidanceAudioEnabled: _guidanceAudioEnabled,
                          startingSurahId: _startingSurahId,
                        ),
                      ),
                child: Text(context.l10n.confirm),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

