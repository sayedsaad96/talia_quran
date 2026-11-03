import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_ayah_study.dart';
import 'ayah_study_sheet.dart';

bool readerStudyAvailable() =>
    getIt.isRegistered<GetAyahStudy>() &&
    getIt.isRegistered<ExperienceFlags>() &&
    getIt<ExperienceFlags>().isEnabled(ExperienceFeature.approvedAyahStudy);

Future<void> showReaderStudy(BuildContext context, int surah, int ayah) async {
  if (!readerStudyAvailable() || !context.mounted) return;
  await AyahStudySheet.show(
    context,
    surahId: surah,
    ayahNumber: ayah,
    getAyahStudy: getIt<GetAyahStudy>(),
  );
}

/// An explicit ayah choice is the accessible alternative to long press.
Future<void> chooseReaderStudyAyah(
  BuildContext context,
  int page, {
  bool Function()? isCurrent,
}) async {
  bool eligible() => context.mounted && (isCurrent?.call() ?? true);
  if (!readerStudyAvailable() || !eligible()) return;
  final result = await getIt<QuranRepository>().getQuranPage(page);
  if (!context.mounted || !eligible()) return;
  final detail = result.fold((_) => null, (value) => value);
  if (detail == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.ayahStudyUnavailable)));
    return;
  }
  final chosen = await showModalBottomSheet<({int surah, int ayah})>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(sheetContext.l10n.ayahStudySelectAyah),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final ayah in detail.ayahs)
                    ListTile(
                      title: Text(ayah.text, textDirection: TextDirection.rtl),
                      subtitle: Text('${ayah.surahId}:${ayah.numberInSurah}'),
                      onTap: () => Navigator.pop(sheetContext, (
                        surah: ayah.surahId,
                        ayah: ayah.numberInSurah,
                      )),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (chosen != null && context.mounted && eligible()) {
    await showReaderStudy(context, chosen.surah, chosen.ayah);
  }
}
