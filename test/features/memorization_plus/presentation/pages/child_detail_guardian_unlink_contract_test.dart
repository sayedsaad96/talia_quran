import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/child_detail_page.dart';

void main() {
  // `revoke_guardian_link` was checked on the hosted project on 2026-10-05
  // (security definer, authenticated only, active links, both caller
  // branches). The child's own unlink is offered only through the PIN-gated
  // kids settings tile; the guardian's removal (product decision 2026-10-07)
  // only through the confirming button on a linked child's detail page.
  test(
    'presentation pages and widgets do not invoke guardian unlink directly',
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
      const allowed = {'remove_child_from_family_button.dart'};
      final violations = <String>[];
      for (final file in scannedFiles) {
        if (allowed.contains(file.uri.pathSegments.last)) continue;
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
            'Guardian unlink/remove-child must not be called straight from '
            'presentation pages and widgets.\n'
            '${violations.join('\n')}',
      );

      final childUnlinkUsers = scannedFiles
          .where(
            (file) => file.readAsStringSync().contains('UnlinkGuardianUsecase'),
          )
          .map((file) => file.uri.pathSegments.last)
          .toList();
      expect(childUnlinkUsers, [
        'guardian_unlink_tile.dart',
      ], reason: 'the child unlink must stay behind the PIN-gated tile');
    },
  );

  testWidgets('only a linked child offers removal from the family', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);
    final repository = _UnusedRepository();
    final cubit = FamilyDashboardCubit(
      ParentAccessUsecase(repository),
      ParentRemoteLinkUsecase(repository),
      GetFamilyDashboardUsecase(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _TestApp(
        child: BlocProvider.value(
          value: cubit,
          child: const ChildDetailPage(
            child: FamilyChildEntry(
              childUserId: 'child-1',
              displayName: 'Remote child',
              isLocal: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('family-remove-child')), findsOneWidget);

    await tester.pumpWidget(
      _TestApp(
        child: BlocProvider.value(
          value: cubit,
          child: const ChildDetailPage(
            child: FamilyChildEntry(
              childUserId: 'local-child',
              displayName: 'This device',
              isLocal: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The child on this device has no server link to end from here.
    expect(find.byKey(const ValueKey('family-remove-child')), findsNothing);
  });
}

class _UnusedRepository implements MemorizationPlusRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
