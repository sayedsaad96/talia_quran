import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_monthly_report.dart';
import '../widgets/kids_monthly_report_view.dart';

/// Renders the report view to PNG bytes.
typedef KidsReportCapture =
    Future<Uint8List> Function(Widget view, BuildContext context);

/// Shares the PNG [bytes] under [fileName] with [text].
typedef KidsReportShareImage =
    Future<void> Function(Uint8List bytes, String fileName, String text);

/// Turns the PNG [bytes] into an A4 portrait PDF and offers it for saving.
typedef KidsReportSavePdf =
    Future<void> Function(Uint8List bytes, String fileName);

/// A4 at 96 dpi, the canvas the report is captured on.
const Size kidsReportCanvasSize = Size(794, 1123);

/// The fixed A4 canvas the report is captured on. Ignores the app text scale
/// and scales tall content down instead of overflowing or clipping it.
@visibleForTesting
class KidsReportCaptureCanvas extends StatelessWidget {
  const KidsReportCaptureCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.noScaling),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox.fromSize(
          size: kidsReportCanvasSize,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: kidsReportCanvasSize.width, child: child),
          ),
        ),
      ),
    );
  }
}

Future<Uint8List> _defaultCapture(Widget view, BuildContext context) {
  return ScreenshotController().captureFromWidget(
    Directionality(
      textDirection: context.textDirection,
      child: Localizations.override(
        context: context,
        child: KidsReportCaptureCanvas(child: view),
      ),
    ),
    context: context,
    targetSize: kidsReportCanvasSize,
    pixelRatio: 2.0,
  );
}

Future<void> _defaultShare(Uint8List bytes, String fileName, String text) =>
    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        text: text,
      ),
    );

Future<void> _defaultSavePdf(Uint8List bytes, String fileName) async {
  final pdf = pw.Document();
  final image = pw.MemoryImage(bytes);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Image(image, fit: pw.BoxFit.contain),
      ),
    ),
  );
  final pdfBytes = await pdf.save();
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
    name: fileName,
  );
}

/// Route payload for [KidsMonthlyReportPage].
class KidsMonthlyReportRouteArgs {
  const KidsMonthlyReportRouteArgs({
    required this.report,
    this.childName,
    this.historyComplete = true,
  });

  final KidsMonthlyReport report;
  final String? childName;
  final bool historyComplete;
}

/// The guardian's monthly report with an optional note (not stored) and image
/// or PDF export. Capture, share and PDF are injectable for tests.
class KidsMonthlyReportPage extends StatefulWidget {
  const KidsMonthlyReportPage({
    super.key,
    required this.report,
    this.childName,
    this.historyComplete = true,
    this.captureView = _defaultCapture,
    this.onShareImage = _defaultShare,
    this.onSavePdf = _defaultSavePdf,
  });

  final KidsMonthlyReport report;
  final String? childName;
  final bool historyComplete;
  final KidsReportCapture captureView;
  final KidsReportShareImage onShareImage;
  final KidsReportSavePdf onSavePdf;

  /// Longest guardian note, in characters.
  static const int noteMaxLength = 200;

  @override
  State<KidsMonthlyReportPage> createState() => _KidsMonthlyReportPageState();
}

class _KidsMonthlyReportPageState extends State<KidsMonthlyReportPage> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Widget _view() => KidsMonthlyReportView(
    report: widget.report,
    note: _note.text,
    childName: widget.childName,
    historyComplete: widget.historyComplete,
  );

  String get _stamp {
    final end = widget.report.periodEnd;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${end.year}${two(end.month)}${two(end.day)}';
  }

  Future<void> _run(
    Future<void> Function(Uint8List bytes) action,
    String errorText,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(await widget.captureView(_view(), context));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = widget.report.isEmpty;
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.monthlyReportTitle, style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          ListenableBuilder(
            listenable: _note,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: _view(),
            ),
          ),
          if (!empty) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('monthly-report-note'),
              controller: _note,
              maxLength: KidsMonthlyReportPage.noteMaxLength,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.monthlyReportNote,
                helperText: l10n.monthlyReportNoteHint,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('monthly-report-share'),
                    icon: const Icon(TaliaIcons.share),
                    label: Text(l10n.monthlyReportShare),
                    onPressed: () => _run(
                      (bytes) => widget.onShareImage(
                        bytes,
                        'talia_monthly_report_$_stamp.png',
                        l10n.monthlyReportShareText,
                      ),
                      l10n.certificateShareError,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('monthly-report-pdf'),
                    icon: const Icon(TaliaIcons.pdf),
                    label: Text(l10n.monthlyReportSavePdf),
                    onPressed: () => _run(
                      (bytes) => widget.onSavePdf(
                        bytes,
                        'talia_monthly_report_$_stamp.pdf',
                      ),
                      l10n.certificatePdfError,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
