import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/child_detail_page.dart';

void main() {
  test(
    'presentation pages and widgets do not invoke guardian unlink before hosted proof',
    () {
      final presentationRoot = Directory(
        'lib/features/memorization_plus/presentation',
      );
      final scannedFiles = presentationRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                (file.path.contains(
                      '${Platform.pathSeparator}pages${Platform.pathSeparator}',
                    ) ||
                    file.path.contains(
                      '${Platform.pathSeparator}widgets${Platform.pathSeparator}',
                    )),
          )
          .toList();

      final scannedNames = scannedFiles
          .map((file) => file.uri.pathSegments.last)
          .toSet();
      expect(scannedNames, contains('family_dashboard_page.dart'));
      expect(scannedNames, contains('child_detail_page.dart'));

      final forbiddenInvocation = RegExp(
        r'\b(?:unlinkGuardian|removeChild)\s*\(',
      );
      final violations = <String>[];
      for (final file in scannedFiles) {
        final matches = forbiddenInvocation.allMatches(file.readAsStringSync());
        if (matches.isNotEmpty) {
          violations.add(
            '${file.path}: ${matches.length} forbidden invocation(s)',
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Guardian unlink/remove-child must stay absent from production '
            'presentation pages and widgets until hosted proof exists.\n'
            '${violations.join('\n')}',
      );
    },
  );

  testWidgets(
    'remote child detail does not expose unlink before hosted proof',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const _TestApp(
          child: ChildDetailPage(
            child: FamilyChildEntry(
              childUserId: 'child-1',
              displayName: 'Remote child',
              isLocal: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove child'), findsNothing);
      expect(find.byTooltip('Remove child'), findsNothing);
      expect(find.byIcon(Icons.link_off_rounded), findsNothing);
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
