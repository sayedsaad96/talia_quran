part of 'family_dashboard_page.dart';

// ─── PIN Gate (reused from parent dashboard) ──────────────────────────────────

class _PinGate extends StatefulWidget {
  const _PinGate({
    required this.title,
    required this.buttonText,
    required this.controller,
    required this.onSubmit,
    this.requiresConfirmation = false,
    this.onForgot,
    this.helpText,
    this.onSkip,
  });

  final String title;
  final String buttonText;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool requiresConfirmation;
  final VoidCallback? onForgot;

  /// Replaces the default "protects the dashboard" line.
  final String? helpText;

  /// Set when the lock is optional (the guardian's own phone).
  final VoidCallback? onSkip;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = widget.controller.text.trim();
    final confirm = _confirmController.text.trim();
    if (widget.requiresConfirmation && pin != confirm) {
      setState(() => _error = context.l10n.parentDashboardPinMismatch);
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 54, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(widget.title, style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.helpText ?? context.l10n.parentDashboardPinHelp,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'PIN',
              ),
            ),
            if (widget.requiresConfirmation) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: context.l10n.parentDashboardPinConfirm,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.buttonText),
              ),
            ),
            if (widget.onForgot != null)
              TextButton(
                onPressed: widget.onForgot,
                child: Text(context.l10n.parentDashboardForgotPin),
              ),
            if (widget.onSkip != null)
              TextButton(
                key: const ValueKey('family-pin-skip'),
                onPressed: widget.onSkip,
                child: Text(context.l10n.familyPinSkip),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Forgotten PIN ────────────────────────────────────────────────────────────

class _ForgotPinDialog extends StatefulWidget {
  const _ForgotPinDialog({required this.email});
  final String email;

  @override
  State<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<_ForgotPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardForgotPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.parentDashboardForgotPinBody(widget.email)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(labelText: context.l10n.password),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.parentDashboardForgotPinConfirm),
        ),
      ],
    );
  }
}

// ─── Add Child Logic ──────────────────────────────────────────────────────────

void _showAddChildOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Material(
      color: context.tokens.background,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.familyDashboardAddChild,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.familyDashboardNoChildrenHint,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
              ),
              title: Text(context.l10n.parentDashboardScanQr),
              onTap: () {
                Navigator.pop(sheetContext);
                _openScanner(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.keyboard_rounded,
                color: AppColors.primary,
              ),
              title: Text(context.l10n.parentDashboardEnterLinkingCode),
              onTap: () {
                Navigator.pop(sheetContext);
                _showManualTokenDialog(context);
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(sheetContext).bottom),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openScanner(BuildContext context) async {
  final token = await Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
  if (token != null && context.mounted) {
    await _linkChild(context, token);
  }
}

Future<void> _showManualTokenDialog(BuildContext context) async {
  final token = await showDialog<String>(
    context: context,
    builder: (_) => const _ManualTokenDialog(),
  );
  if (token != null && token.isNotEmpty && context.mounted) {
    await _linkChild(context, token);
  }
}

/// Links with a visible "linking…" step, so the guardian is never left
/// wondering whether the scan or the typed code was taken.
Future<void> _linkChild(BuildContext context, String token) async {
  final cubit = context.read<FamilyDashboardCubit>();
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          key: const ValueKey('family-linking-progress'),
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(dialogContext.l10n.familyDashboardLinking)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    await cubit.acceptRemoteToken(token);
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}

class _ManualTokenDialog extends StatefulWidget {
  const _ManualTokenDialog();

  @override
  State<_ManualTokenDialog> createState() => _ManualTokenDialogState();
}

class _ManualTokenDialogState extends State<_ManualTokenDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardEnterLinkingCode),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardLinkHint,
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.parentDashboardLinkAction),
        ),
      ],
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();
  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  // One result per code: the scanner keeps reporting while the page closes,
  // and a second pop would close the family dashboard too.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.parentDashboardScanQr)),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_handled) return;
          for (final barcode in capture.barcodes) {
            final raw = barcode.rawValue;
            if (raw == null) continue;
            // Accept the shared kids-link contract payload (and the legacy
            // prefix) instead of a hard-coded literal that drifted from the
            // child-side generator and silently broke QR pairing.
            if (!KidsQrLinkContract.isLinkPayload(raw)) {
              if (raw != _lastRejected) {
                _lastRejected = raw;
                context.showSnackBar(
                  context.l10n.parentDashboardNotLinkCode,
                  isError: true,
                );
              }
              continue;
            }
            _handled = true;
            Navigator.pop(context, KidsQrLinkContract.extractToken(raw));
            return;
          }
        },
      ),
    );
  }
}
