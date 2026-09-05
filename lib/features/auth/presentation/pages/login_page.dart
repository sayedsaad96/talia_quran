import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../presentation/cubits/auth_cubit.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../domain/entities/auth_error_code.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _AuthFeedback {
  const _AuthFeedback({
    required this.message,
    required this.type,
    this.title,
    this.showResend = false,
  });

  final String message;
  final ErrorInfoBannerType type;
  final String? title;
  final bool showResend;
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isSyncing = false;
  bool _syncFailed = false;
  bool _postLoginRouteInFlight = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AuthFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _syncFailed = context.read<AuthCubit>().state is AuthOwnerDataFailure;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    try {
      if (_isSignUp) {
        await cubit.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      } else {
        await cubit.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (_) {
      _showSyncFailure();
    }
  }

  /// After a successful sign-in, wait for the first cloud sync to complete so
  /// the restored profile is ready before routing. If sync fails, stay on the
  /// login page with a retry button (prevents routing with blank profile).
  Future<void> _routeAfterLogin(BuildContext context) async {
    if (_postLoginRouteInFlight || !context.mounted) return;
    _postLoginRouteInFlight = true;
    try {
      await _performPostLoginRoute(context);
    } finally {
      _postLoginRouteInFlight = false;
    }
  }

  Future<void> _performPostLoginRoute(BuildContext context) async {
    final cubit = context.read<AuthCubit>();
    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });
    try {
      await cubit.ensureCloudSyncComplete();
    } catch (_) {
      _showSyncFailure();
      return;
    }
    if (!context.mounted) return;
    setState(() => _isSyncing = false);
    final destination = await _resolvePostLoginDestination();
    if (!context.mounted) return;
    context.go(destination);
  }

  void _showSyncFailure() {
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _syncFailed = true;
    });
  }

  Future<String> _resolvePostLoginDestination() async {
    try {
      final profileResult = await getIt<MemorizationPlusRepository>()
          .getMemorizationProfile();
      final isChild = profileResult.fold(
        (_) => _isChildFromOnboardingPrefs(),
        (profile) => profile.isChild,
      );
      return isChild ? AppRoutes.memorizationPlusGuardianLinking : '/';
    } catch (_) {
      return _isChildFromOnboardingPrefs()
          ? AppRoutes.memorizationPlusGuardianLinking
          : '/';
    }
  }

  bool _isChildFromOnboardingPrefs() {
    final prefs = getIt<SharedPreferences>();
    return prefs.getString(OnboardingCubit.userTypeKey) ==
        OnboardingUserType.child.storageValue;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: context.textDirection,
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              setState(() {
                _feedback = null;
                _syncFailed = false;
              });
              // Update local profile automatically with the user's display name
              context.read<ProfileCubit>().updateProfile(
                name: state.user.displayName,
              );
              unawaited(_routeAfterLogin(context));
            }
            if (state is AuthPasswordResetSent) {
              setState(
                () => _feedback = _AuthFeedback(
                  title: context.l10n.forgotPassword,
                  message: context.l10n.passwordResetEmailSent,
                  type: ErrorInfoBannerType.success,
                ),
              );
            }
            if (state is AuthResendConfirmationSuccess) {
              setState(
                () => _feedback = _AuthFeedback(
                  message: context.l10n.confirmationEmailSent,
                  type: ErrorInfoBannerType.success,
                ),
              );
            }
            if (state is AuthOwnerDataFailure) {
              _showSyncFailure();
            }
            if (state is AuthError) {
              // Resolve the stable error code; unknown/legacy messages fall
              // back to a generic localized error â€” never raw backend text.
              final code = _authCodeFromMessage(state.message);
              setState(
                () => _feedback = _AuthFeedback(
                  message: code != null
                      ? _localizedAuthMessage(context, state.message)
                      : context.l10n.authGenericError,
                  type: ErrorInfoBannerType.error,
                  showResend: code == AuthErrorCode.emailNotConfirmed,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading || _isSyncing;

            // Restoring overlay shown while awaiting sync after login
            if (_isSyncing) {
              return SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.restoringProgress,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sync failed: stay on page, show retry
            if (_syncFailed) {
              return SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.l10n.authGenericError,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.pagePadding),
                        FilledButton(
                          onPressed: () => unawaited(_routeAfterLogin(context)),
                          child: Text(context.l10n.retrySyncAfterError),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            context.l10n.syncProgressDesc,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (_feedback != null) ...[
                            ErrorInfoBanner(
                              type: _feedback!.type,
                              title:
                                  _feedback!.title ??
                                  (_feedback!.type ==
                                          ErrorInfoBannerType.success
                                      ? context.l10n.confirmationEmailSent
                                      : context.l10n.authGenericError),
                              message: _feedback!.message,
                              actionLabel: _feedback!.showResend
                                  ? context.l10n.resendConfirmation
                                  : null,
                              onAction: _feedback!.showResend
                                  ? () => context
                                        .read<AuthCubit>()
                                        .resendConfirmation(
                                          _emailController.text.trim(),
                                        )
                                  : null,
                              onDismissed: () =>
                                  setState(() => _feedback = null),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Sign In / Sign Up toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildToggle(
                                context.l10n.signIn,
                                !_isSignUp,
                                cs,
                                isLoading
                                    ? null
                                    : () => setState(() => _isSignUp = false),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildToggle(
                                context.l10n.signUp,
                                _isSignUp,
                                cs,
                                isLoading
                                    ? null
                                    : () => setState(() => _isSignUp = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Name field (sign up only)
                          if (_isSignUp) ...[
                            TextFormField(
                              textCapitalization: TextCapitalization.words,
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: context.l10n.name,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? context.l10n.enterName
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: context.l10n.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return context.l10n.enterEmail;
                              }
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(v.trim())) {
                                return context.l10n.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: context.l10n.password,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                tooltip: _obscurePassword
                                    ? context.l10n.showPassword
                                    : context.l10n.hidePassword,
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return context.l10n.enterPassword;
                              }
                              if (_isSignUp && v.length < 6) {
                                return context.l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          if (!_isSignUp) ...[
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () {
                                  final email = _emailController.text.trim();
                                  if (email.isEmpty ||
                                      !email.contains('@') ||
                                      !email.contains('.')) {
                                    setState(
                                      () => _feedback = _AuthFeedback(
                                        message: context
                                            .l10n
                                            .forgotPasswordEnterEmail,
                                        type: ErrorInfoBannerType.error,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<AuthCubit>().resetPassword(
                                    email,
                                  );
                                },
                                child: Text(
                                  context.l10n.forgotPassword,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp
                                          ? context.l10n.createAccount
                                          : context.l10n.signIn,
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.itemGap),
                          TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(
                              context.l10n.skip,
                              style: AppTypography.labelLarge.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggle(
    String label,
    bool isActive,
    ColorScheme cs,
    VoidCallback? onTap,
  ) {
    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? cs.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            border: Border.all(
              color: isActive ? cs.primary : cs.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _localizedAuthMessage(BuildContext context, String message) {
    final l10n = context.l10n;
    final code = _authCodeFromMessage(message);
    if (code == null) return l10n.authGenericError;

    return switch (code) {
      AuthErrorCode.emailAlreadyRegistered => l10n.authEmailAlreadyRegistered,
      AuthErrorCode.emailNotConfirmed => l10n.authConfirmEmailFirst,
      AuthErrorCode.invalidCredentials => l10n.authInvalidCredentials,
      AuthErrorCode.passwordTooShort => l10n.passwordTooShort,
      AuthErrorCode.invalidEmailFormat => l10n.invalidEmail,
      AuthErrorCode.tooManyRequests => l10n.authTooManyRequests,
      AuthErrorCode.networkError => l10n.authNoInternet,
      AuthErrorCode.userNotFound => l10n.authAccountNotFound,
      AuthErrorCode.samePasswordAsOld => l10n.authPasswordSameAsOld,
      AuthErrorCode.sessionExpired => l10n.authSessionExpired,
      AuthErrorCode.unknown => l10n.authGenericError,
    };
  }

  /// Parses a stable [AuthErrorCode] name out of an auth failure message.
  static AuthErrorCode? _authCodeFromMessage(String message) {
    for (final code in AuthErrorCode.values) {
      if (message == code.name) return code;
    }
    return null;
  }
}
