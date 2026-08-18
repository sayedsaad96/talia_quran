import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/user_profile.dart';
import '../cubits/profile_cubit.dart';
import 'settings_section.dart';

void _showSettingsError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.error),
  );
}

class ProfileSettingTile extends StatelessWidget {
  const ProfileSettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = (state is ProfileLoaded)
            ? state.profile
            : const UserProfile();

        return InkWell(
          onTap: () => _showEditProfileDialog(context, profile, isDark),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.hasName
                            ? profile.displayName
                            : context.l10n.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: profile.hasName
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (profile.age != null)
                        Text(
                          '${context.l10n.age}: ${profile.age}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        )
                      else
                        Text(
                          context.l10n.editProfile,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          EditProfileDialog(profile: profile, isDark: isDark),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.isDark,
  });

  final UserProfile profile;
  final bool isDark;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Text(
        context.l10n.editProfile,
        style: AppTypography.titleLarge.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.name,
                hintText: context.l10n.enterName,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: 4,
                right: 4,
              ),
              child: Text(
                context.l10n.arabicNameHint,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.age,
                hintText: context.l10n.enterAge,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.l10n.cancel,
            style: AppTypography.labelLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final ageText = _ageController.text.trim();
            final age = ageText.isEmpty ? null : int.tryParse(ageText);

            if (ageText.isNotEmpty && (age == null || age < 1 || age > 120)) {
              _showSettingsError(context, context.l10n.invalidAge);
              return;
            }

            final saved = await context.read<ProfileCubit>().updateProfile(
              name: name,
              age: age,
            );

            if (!context.mounted) return;

            if (!saved) {
              _showSettingsError(context, context.l10n.profileSaveError);
              return;
            }

            Navigator.of(context).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.profileUpdated)),
            );
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.isDark,
    required this.icon,
    this.label,
    this.isSignedIn = false,
  });

  final bool isDark;
  final IconData icon;
  final String? label;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isSignedIn ? AppColors.primaryGradient : null,
        color: isSignedIn ? null : primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.45),
          width: 1,
        ),
      ),
      child: label == null
          ? Icon(icon, color: primary, size: 28)
          : Text(
              label!,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

String _accountInitials(AppUser user) {
  final source = user.displayName.trim().isNotEmpty
      ? user.displayName.trim()
      : user.email.trim();
  if (source.isEmpty) return 'T';

  final parts = source
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  return source.characters.take(2).toString().toUpperCase();
}

class AccountSection extends StatefulWidget {
  const AccountSection({super.key, required this.isDark});
  final bool isDark;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is AuthSignOutBlockedPendingData) {
          _confirmForceSignOut(context);
        } else if (state is AuthAccountDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.settingsAccountDeletedMessage),
              backgroundColor: AppColors.primary,
            ),
          );
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          final user = state.user;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccountAvatar(
                      isDark: widget.isDark,
                      icon: Icons.person_rounded,
                      label: _accountInitials(user),
                      isSignedIn: true,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: AppTypography.labelSmall.copyWith(
                              color: subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.settingsSignedInStatus,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 0.5,
                color: widget.isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
                indent: 16,
                endIndent: 16,
              ),
              InkWell(
                onTap: () => _confirmGuestDataImport(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          context.isArabic
                              ? 'نقل بيانات الحفظ المحلية'
                              : 'Import local memorization data',
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _confirmSignOut(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          context.l10n.signOut,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AccountAvatar(
                    isDark: widget.isDark,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.settingsGuestStatusTitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.settingsGuestStatusSubtitle,
                          style: AppTypography.labelSmall.copyWith(
                            color: subtextColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(context.l10n.settingsSignInCreateAccount),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    textStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmForceSignOut(BuildContext context) {
    final isDark = context.isDark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.signOutPendingDataTitle,
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          context.l10n.signOutPendingDataWarning,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthCubit>().signOut(force: true);
            },
            child: Text(context.l10n.signOutAnyway),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final isDark = context.isDark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.signOut,
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          context.l10n.signOutWarning,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthCubit>().signOut();
            },
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmGuestDataImport(BuildContext context) async {
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.isArabic
              ? 'نقل بيانات الحفظ المحلية؟'
              : 'Import local memorization data?',
        ),
        content: Text(
          context.isArabic
              ? 'سيتم ربط بيانات الحفظ التي أُنشئت دون تسجيل دخول بهذا الحساب ومزامنتها معه.'
              : 'Guest memorization data will be linked to this account and synced to it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.isArabic ? 'نقل' : 'Import'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !context.mounted) return;

    final claim = await context.read<AuthCubit>().importGuestReviewRecords();
    if (!context.mounted) return;
    claim.fold(
      (failure) => _showSettingsError(context, failure.message),
      (count) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.isArabic
                ? 'تم نقل $count من سجلات الحفظ.'
                : 'Imported $count memorization records.',
          ),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({
    super.key,
    required this.isDark,
    required this.email,
  });

  final bool isDark;
  final String email;

  @override
  Widget build(BuildContext context) {
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => _confirmDeleteAccount(context, email),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsDeleteAccountTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.l10n.settingsDeleteAccountSubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.settingsDeleteAccountTitle),
        content: Text(context.l10n.settingsDeleteAccountWarning(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().deleteAccount();
    }
  }
}
