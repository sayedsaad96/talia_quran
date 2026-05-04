import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<File> _captureAsFile() async {
    final bytes = await _screenshotController.captureFromWidget(
      CertificateWidget(
        userName: widget.userName,
        award: widget.award,
        completionDate: DateTime.now(),
      ),
      pixelRatio: 3.0,
    );
    final dir = await getTemporaryDirectory();
    final fileName = widget.award.type == CertificateType.juz 
        ? 'talia_certificate_juz_${widget.award.juzNumber}.png'
        : 'talia_certificate_surah_${widget.award.surahId}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _share() async {
    setState(() => _isSaving = true);
    try {
      final file = await _captureAsFile();
      final shareText = widget.award.type == CertificateType.juz
          ? 'بفضل الله أتممت حفظ الجزء ${widget.award.juzNumber} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙'
          : 'بفضل الله أتممت حفظ سورة ${widget.award.surahNameAr ?? ""} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙';
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareText,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المشاركة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = await _captureAsFile();
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = widget.award.type == CertificateType.juz 
          ? 'talia_certificate_juz_${widget.award.juzNumber}.png'
          : 'talia_certificate_surah_${widget.award.surahId}.png';
      final savedFile = await file.copy('${docsDir.path}/$fileName');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الشهادة في: ${savedFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('شهادتك', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: CertificateWidget(
                    userName: widget.userName,
                    award: widget.award,
                    completionDate: DateTime.now(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveToGallery,
                              icon: const Icon(Icons.download),
                              label: const Text('حفظ'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _share,
                              icon: const Icon(Icons.share),
                              label: const Text('مشاركة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC9A84C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
