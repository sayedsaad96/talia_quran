import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/services/achievement_service.dart';
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
    // M05 FIX: Restore both portrait orientations when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<File> _captureAsFile() async {
    final bytes = await _screenshotController.captureFromWidget(
      CertificateWidget(
        userName: widget.userName,
        award: widget.award,
        completionDate: widget.award.earnedAt, // L02 FIX
      ),
      pixelRatio: 3.0,
    );
    final dir = await getTemporaryDirectory();
    final fileName = switch (widget.award.type) {
      CertificateType.juz =>
        'talia_certificate_juz_${widget.award.juzNumber}.png',
      CertificateType.surah =>
        'talia_certificate_surah_${widget.award.surahId}.png',
      CertificateType.halfQuran => 'talia_certificate_half_quran.png',
      CertificateType.fullQuran => 'talia_certificate_full_quran.png',
    };
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _share() async {
    setState(() => _isSaving = true);
    try {
      // Always share as a high-quality image
      final file = await _captureAsFile();
      final shareText = switch (widget.award.type) {
        CertificateType.juz =>
          'بفضل الله أتممت حفظ الجزء ${widget.award.juzNumber} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙',
        CertificateType.surah =>
          'بفضل الله أتممت حفظ سورة ${widget.award.surahNameAr ?? ""} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙',
        CertificateType.halfQuran =>
          'بفضل الله أتممت حفظ نصف القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙',
        CertificateType.fullQuran =>
          'بفضل الله أتممت حفظ القرآن الكريم كاملاً 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙',
      };

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: shareText),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء المشاركة')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              const SnackBar(
                content: Text('يجب منح صلاحية الوصول للاستوديو لحفظ الشهادة'),
              ),
            );
            // M06 FIX: Reset saving state before returning
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      final file = await _captureAsFile();
      await Gal.putImage(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الشهادة في الاستوديو بنجاح ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _screenshotController.captureFromWidget(
        CertificateWidget(
          userName: widget.userName,
          award: widget.award,
          completionDate: widget.award.earnedAt, // L02 FIX
        ),
        pixelRatio: 3.0,
      );

      final pdf = pw.Document();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'talia_certificate.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء إنشاء ملف PDF')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSaveOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر صيغة الحفظ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.blue),
              title: const Text(
                'حفظ كصورة (في الاستوديو)',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveToGallery();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'حفظ كملف PDF',
                style: TextStyle(color: Colors.white),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Certificate Viewer (Full Screen)
            Positioned.fill(
              child: SafeArea(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Screenshot(
                        controller: _screenshotController,
                        child: CertificateWidget(
                          userName: widget.userName,
                          award: widget.award,
                          completionDate: widget
                              .award
                              .earnedAt, // L02 FIX: Use actual earned date
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Back Button (Top Right)
            Positioned(
              top: 16,
              right: 16,
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

            // 3. Action Buttons (Floating at bottom left)
            Positioned(
              bottom: 24,
              left: 24,
              child: SafeArea(
                child: _isSaving
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: Color(0xFFC9A84C),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _share,
                            icon: const Icon(Icons.share_rounded),
                            label: const Text(
                              'مشاركة',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC9A84C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showSaveOptions,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text(
                              'حفظ',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
