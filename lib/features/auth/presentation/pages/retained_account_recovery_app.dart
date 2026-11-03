import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/repositories/retained_account_recovery_repository.dart';
import '../cubits/retained_account_recovery_cubit.dart';

/// A private authentication-only app; normal providers and progress stay closed.
class RetainedAccountRecoveryApp extends StatelessWidget {
  const RetainedAccountRecoveryApp({
    super.key,
    required this.repository,
    required this.resume,
    this.canSignIn = true,
    this.locale = const Locale('ar'),
  });
  final RetainedAccountRecoveryRepository repository;
  final Future<void> Function() resume;
  final bool canSignIn;
  final Locale locale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider(
      create: (_) =>
          RetainedAccountRecoveryCubit(repository: repository, resume: resume),
      child: _RecoveryPage(canSignIn: canSignIn),
    ),
  );
}

class _RecoveryPage extends StatefulWidget {
  const _RecoveryPage({required this.canSignIn});
  final bool canSignIn;
  @override
  State<_RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<_RecoveryPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child:
              BlocBuilder<
                RetainedAccountRecoveryCubit,
                RetainedAccountRecoveryState
              >(builder: _buildContent),
        ),
      ),
    ),
  );

  Widget _buildContent(
    BuildContext context,
    RetainedAccountRecoveryState state,
  ) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RetainedAccountRecoveryCubit>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.retainedAccountRecoveryTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.retainedAccountRecoveryBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (widget.canSignIn)
          ..._credentials(l10n, state, cubit)
        else
          Text(l10n.retainedAccountRecoveryUnknownOwner),
        if (state.error case final error?) ...[
          const SizedBox(height: 16),
          _errorMessage(context, l10n, error),
        ],
        if (state.busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        TextButton(
          key: const Key('retained-retry'),
          onPressed: state.busy ? null : cubit.retry,
          child: Text(l10n.retryLabel),
        ),
      ],
    );
  }

  List<Widget> _credentials(
    AppLocalizations l10n,
    RetainedAccountRecoveryState state,
    RetainedAccountRecoveryCubit cubit,
  ) => [
    TextField(
      key: const Key('retained-email'),
      controller: _email,
      enabled: !state.busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: l10n.email),
    ),
    const SizedBox(height: 16),
    TextField(
      key: const Key('retained-password'),
      controller: _password,
      enabled: !state.busy,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: l10n.password),
    ),
    const SizedBox(height: 24),
    FilledButton(
      key: const Key('retained-sign-in'),
      onPressed: state.busy
          ? null
          : () => cubit.signIn(email: _email.text, password: _password.text),
      child: Text(l10n.signIn),
    ),
  ];

  Widget _errorMessage(
    BuildContext context,
    AppLocalizations l10n,
    RetainedAccountRecoveryResult error,
  ) => Semantics(
    liveRegion: true,
    child: Text(switch (error) {
      RetainedAccountRecoveryResult.wrongAccount =>
        l10n.retainedAccountRecoveryWrongAccount,
      RetainedAccountRecoveryResult.unavailable =>
        l10n.retainedAccountRecoveryUnavailable,
      RetainedAccountRecoveryResult.failed ||
      RetainedAccountRecoveryResult.recovered =>
        l10n.retainedAccountRecoveryFailed,
    }, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  );
}
