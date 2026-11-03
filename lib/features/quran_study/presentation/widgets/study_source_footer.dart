import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../domain/entities/study_entry.dart';

class StudySourceFooter extends StatelessWidget {
  const StudySourceFooter({
    super.key,
    required this.source,
    required this.surahId,
    required this.ayahNumber,
  });
  final StudySource source;
  final int surahId, ayahNumber;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${context.l10n.ayahStudySource}: ${source.title} — ${source.publisher} — ${source.edition}',
      ),
      Text(source.attribution),
      SelectableText(source.url, textDirection: TextDirection.ltr),
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(
              text:
                  '${source.title} | ${source.edition} | ${source.url} | $surahId:$ayahNumber',
            ),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.ayahStudyCopied)),
            );
          }
        },
        icon: const TaliaIcon(TaliaIcons.copy),
        label: Text(context.l10n.ayahStudyCopyReport),
      ),
    ],
  );
}
