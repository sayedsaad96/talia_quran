import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../widgets/certificate_widget.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({
    super.key,
    required this.award,
    required this.userName,
  });

  final CertificateAward award;
  final String userName;

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final _screenshotController = ScreenshotController();
  CertificateStyleType _selectedStyle = CertificateStyleType.classicParchment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation for better certificate viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String get _certificateFileName => switch (widget.award.type) {
    CertificateType.juz =>
      'talia_certificate_juz_${widget.award.juzNumber}.png',
    CertificateType.surah =>
      'talia_certificate_surah_${widget.award.surahId}.png',
    CertificateType.halfQuran => 'talia_certificate_half_quran.png',
    CertificateType.fullQuran => 'talia_certificate_full_quran.png',
  };

  Future<Uint8List> _captureCertificateBytes() =>
      _screenshotController.captureFromWidget(
        CertificateWidget(
          userName: widget.userName,
          award: widget.award,
          completionDate: widget.award.earnedAt,
          styleType: _selectedStyle,
        ),
        pixelRatio: 3.0,
      );

  Future<void> _share() async {
    setState(() => _isSaving = true);
    try {
      final l10n = context.l10n;
      final isArabic = context.isArabic;
      final shareText = switch (widget.award.type) {
        CertificateType.juz => l10n.shareCertificateJuz(
          widget.award.juzNumber ?? 1,
        ),
        CertificateType.surah => l10n.shareCertificateSurah(
          isArabic
              ? widget.award.surahNameAr ?? ''
              : widget.award.surahNameEn ?? widget.award.surahNameAr ?? '',
        ),
        CertificateType.halfQuran => l10n.shareCertificateHalfQuran,
        CertificateType.fullQuran => l10n.shareCertificateFullQuran,
      };

      final bytes = await _captureCertificateBytes();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: _certificateFileName,
            ),
          ],
          text: '$shareText\nكود التوثيق: ${widget.award.verificationCode}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.certificateShareError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareToSocialMediaCard() {
    final data = SocialShareData.certificate(
      award: widget.award,
      userName: widget.userName,
    );
    SocialShareSheet.show(context, data);
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.certificateGalleryPermissionError),
              ),
            );
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      final bytes = await _captureCertificateBytes();
      await Gal.putImageBytes(
        bytes,
        name: _certificateFileName.replaceFirst('.png', ''),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.certificateGallerySaveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.certificateSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureCertificateBytes();

      final pdf = pw.Document();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'talia_certificate_${widget.award.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.certificatePdfError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSaveOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final dividerColor = isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.saveFormatTitle,
              style: AppTypography.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(
                Icons.image_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                context.l10n.saveAsImage,
                style: AppTypography.bodyLarge.copyWith(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveToGallery();
              },
            ),
            Divider(color: dividerColor),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.red,
              ),
              title: Text(
                context.l10n.saveAsPdf,
                style: AppTypography.bodyLarge.copyWith(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveAsPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      body: Stack(
        children: [
          // 1. Certificate Viewer (Full Screen, Arabic layout)
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                      child: Screenshot(
                        controller: _screenshotController,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: CertificateWidget(
                            key: ValueKey(_selectedStyle),
                            userName: widget.userName,
                            award: widget.award,
                            completionDate: widget.award.earnedAt,
                            styleType: _selectedStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Close button
          PositionedDirectional(
            top: 16,
            start: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 3. Style Switcher Bar (Bottom Center)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: CertificateStyleType.values.map((style) {
                      final isSelected = style == _selectedStyle;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            style.displayName,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE5C158),
                          backgroundColor: Colors.white12,
                          onSelected: (selected) {
                            if (selected) {
                              unawaited(HapticFeedback.selectionClick());
                              setState(() => _selectedStyle = style);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // 4. Action Buttons (Bottom Left / Start)
          PositionedDirectional(
            bottom: 20,
            start: 24,
            child: SafeArea(
              child: _isSaving
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFFC9A84C),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'مشاركة الشهادة',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC9A84C),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _shareToSocialMediaCard,
                          icon: const Icon(Icons.stars_rounded, size: 20),
                          tooltip: 'بطاقة سوشيال ميديا',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: const Color(0xFFE5C158),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _showSaveOptions,
                          icon: const Icon(Icons.download_rounded, size: 20),
                          tooltip: 'حفظ الشهادة',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
