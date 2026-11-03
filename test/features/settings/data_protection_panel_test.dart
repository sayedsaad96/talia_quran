import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/domain/entities/data_protection_status.dart';
import 'package:talia_quran/features/settings/presentation/cubits/data_protection_cubit.dart';
import 'package:talia_quran/features/settings/presentation/widgets/data_protection_panel.dart';

void main() {
  testWidgets('shows independent domain statuses', (tester) async {
    final cubit = DataProtectionCubit(
      () async => DataProtectionStatus(
        signedIn: true,
        domains: {
          ProtectionDomain.progress: const ProtectionDomainStatus(
            ProtectionState.synced,
          ),
          ProtectionDomain.bookmarks: const ProtectionDomainStatus(
            ProtectionState.failed,
          ),
        },
      ),
    );
    await cubit.refresh();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: DataProtectionPanel()),
          ),
        ),
      ),
    );
    expect(find.textContaining('Reading progress'), findsOneWidget);
    expect(find.textContaining('Bookmark'), findsOneWidget);
    await cubit.close();
  });
}
