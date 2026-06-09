import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../presentation/cubits/auth_cubit.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AuthFeedback? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    if (_isSignUp) {
      cubit.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
    } else {
      cubit.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  /// After a successful sign-in, route child profiles into the guardian-linking
  /// flow (which auto-forwards to the kids journey if already linked) so the
  /// child + sign-in onboarding branch is not dropped at the adult home shell.
  Future<void> _routeAfterLogin(BuildContext context) async {
    if (!context.mounted) return;
    context.go(await _resolvePostLoginDestination());
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
              setState(() => _feedback = null);
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
            if (state is AuthError) {
              // Email not confirmed — offer resend button
              final isNotConfirmed =
                  state.message.contains('تأكيد') ||
                  state.message.contains('تفقّد') ||
                  state.message.contains('confirmed');
              setState(
                () => _feedback = _AuthFeedback(
                  message: _localizedAuthMessage(context, state.message),
                  type: ErrorInfoBannerType.error,
                  showResend: isNotConfirmed,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Icon(
                        Icons.menu_book_rounded,
                        size: 80,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.appName,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.syncProgressDesc,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_feedback != null) ...[
                        ErrorInfoBanner(
                          type: _feedback!.type,
                          title:
                              _feedback!.title ??
                              (_feedback!.type == ErrorInfoBannerType.success
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
                          onDismissed: () => setState(() => _feedback = null),
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
                            () => setState(() => _isSignUp = false),
                          ),
                          const SizedBox(width: 8),
                          _buildToggle(
                            context.l10n.signUp,
                            _isSignUp,
                            cs,
                            () => setState(() => _isSignUp = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
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
                                    message:
                                        context.l10n.forgotPasswordEnterEmail,
                                    type: ErrorInfoBannerType.error,
                                  ),
                                );
                                return;
                              }
                              context.read<AuthCubit>().resetPassword(email);
                            },
                            child: Text(
                              context.l10n.forgotPassword,
                              style: TextStyle(color: cs.primary, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          context.l10n.skip,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
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
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? cs.primary : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _localizedAuthMessage(BuildContext context, String message) {
    final l10n = context.l10n;
    if (message.contains('مسجل بالفعل')) {
      return l10n.authEmailAlreadyRegistered;
    }
    if (message.contains('تأكيد') ||
        message.contains('تفقّد') ||
        message.contains('confirmed')) {
      return l10n.authConfirmEmailFirst;
    }
    if (message.contains('غير صحيحة')) return l10n.authInvalidCredentials;
    if (message.contains('قصيرة')) return l10n.passwordTooShort;
    if (message.contains('صيغة البريد')) return l10n.invalidEmail;
    if (message.contains('محاولات كثيرة')) return l10n.authTooManyRequests;
    if (message.contains('اتصال بالإنترنت')) return l10n.authNoInternet;
    if (message.contains('لا يوجد حساب')) return l10n.authAccountNotFound;
    if (message.contains('فشل إنشاء الحساب') ||
        message.contains('أثناء إنشاء الحساب')) {
      return l10n.authSignupFailed;
    }
    if (message.contains('فشل تسجيل الدخول') ||
        message.contains('أثناء تسجيل الدخول')) {
      return l10n.authSigninFailed;
    }
    if (message.contains('تسجيل الخروج')) return l10n.authSignoutFailed;
    if (message.contains('حدث خطأ')) return l10n.authGenericError;
    return message;
  }
}
