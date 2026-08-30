import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../domain/entities/auth_error_code.dart';
import '../cubits/auth_cubit.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().updatePassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: context.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.updatePasswordTitle),
          leading: IconButton(
            tooltip: context.l10n.close,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/login'),
          ),
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordUpdated) {
              // signOut is handled in the repository right after updateUser,
              // so we just navigate to login and show a success snackbar.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.passwordUpdated),
                    duration: const Duration(seconds: 4),
                  ),
                );
                context.go('/login');
              }
            }
            if (state is AuthError) {
              // Show a stable, localized message — never raw backend text.
              AuthErrorCode? code;
              for (final c in AuthErrorCode.values) {
                if (state.message == c.name) code = c;
              }
              setState(
                () => _error = switch (code) {
                  AuthErrorCode.passwordTooShort =>
                    context.l10n.passwordTooShort,
                  AuthErrorCode.samePasswordAsOld =>
                    context.l10n.authPasswordSameAsOld,
                  AuthErrorCode.networkError => context.l10n.authNoInternet,
                  AuthErrorCode.sessionExpired =>
                    context.l10n.authSessionExpired,
                  _ => context.l10n.authGenericError,
                },
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          Icon(
                            Icons.lock_reset_rounded,
                            size: 72,
                            color: cs.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.updatePasswordTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.updatePasswordSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          if (_error != null) ...[
                            ErrorInfoBanner(
                              type: ErrorInfoBannerType.error,
                              title: context.l10n.authGenericError,
                              message: _error!,
                              onDismissed: () => setState(() => _error = null),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: context.l10n.newPassword,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.enterPassword;
                              }
                              if (value.length < 6) {
                                return context.l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: context.l10n.confirmNewPassword,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                tooltip: _obscureConfirmPassword
                                    ? context.l10n.showPassword
                                    : context.l10n.hidePassword,
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.enterPassword;
                              }
                              if (value != _passwordController.text) {
                                return context.l10n.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
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
                                    context.l10n.updatePasswordButton,
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
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
}
