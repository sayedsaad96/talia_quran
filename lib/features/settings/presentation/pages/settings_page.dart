import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../../data/user_profile.dart';

part 'settings_page_tiles.dart';

void _showSettingsError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedTrack;
  String? _selectedHifzPath;
  bool _isParentMode = false;

  @override
  void initState() {
    super.initState();
    _loadTrackAndParentMode();
  }

  Future<void> _loadTrackAndParentMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedTrack = prefs.getString('mem_plus_track');
      _selectedHifzPath = prefs.getString(AppConstants.kHifzPathMode);
      _isParentMode = prefs.getBool('mem_plus_is_parent_mode') ?? false;
    });
  }

  Future<void> _toggleParentMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mem_plus_is_parent_mode', value);
    if (!mounted) return;
    setState(() => _isParentMode = value);
  }

  /// Show parent section if:
  /// 1. Kids track selected (always)
  /// 2. Adults track + user toggled "I am a parent"
  bool get _shouldShowParentSection {
    if (_selectedTrack == 'kids') return true;
    if (_selectedHifzPath == 'backward') return true;
    if (_selectedTrack == 'adults' && _isParentMode) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Account (Google Sign-In) ───────────────────────
                _SettingsSection(
                  title: context.l10n.account,
                  children: [_AccountSection(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.profile,
                  children: [_ProfileSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Parent Mode Toggle (for adults track) ──────────
                if (_selectedTrack == 'adults') ...[
                  _SettingsSection(
                    title: 'وضع ولي الأمر',
                    children: [
                      _ParentModeToggle(
                        isDark: isDark,
                        isParentMode: _isParentMode,
                        onChanged: _toggleParentMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ─── Parent Dashboard (conditional) ─────────────────
                if (_shouldShowParentSection) ...[
                  _SettingsSection(
                    title: 'الأطفال وولي الأمر',
                    children: [_ParentDashboardTile(isDark: isDark)],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _SettingsSection(
                  title: context.l10n.theme,
                  children: [_ThemeSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.language,
                  children: [_LocaleSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.recitationAccuracy,
                  children: [_AccuracySettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.notifications,
                  children: [_NotificationSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.about,
                  children: [
                    _TutorialGuideTile(isDark: isDark),
                    Divider(
                      height: 0.5,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      indent: 56,
                    ),
                    _AboutTile(isDark: isDark),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Text(
        context.l10n.settings,
        style: AppTypography.headlineSmall.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }
}
