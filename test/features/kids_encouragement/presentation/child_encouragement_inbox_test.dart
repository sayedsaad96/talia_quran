import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/kids_encouragement/data/kids_encouragement_repository_impl.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/cubits/child_encouragement_inbox_cubit.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/widgets/child_encouragement_inbox.dart';

void main() {
  testWidgets(
    'offline Done survives reopening and account reset removes the card immediately',
    (tester) async {
      late SharedPreferences prefs;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });
      const owner = FixedRecordOwnerProvider('child-a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      var acknowledgements = 0;
      final repository = KidsEncouragementRepositoryImpl(
        prefs: prefs,
        selectSeen: (_) async => [],
        owner: owner,
        barrier: barrier,
        isEnabled: () => true,
        rpc: (_, _) async {
          acknowledgements++;
          throw StateError('offline');
        },
        selectForChild: (_) async => [_row(1, 'proud'), _row(2, 'well_done')],
      );
      ChildEncouragementInboxCubit createCubit() =>
          ChildEncouragementInboxCubit(
            repository: repository,
            owner: owner,
            barrier: barrier,
            accountChanges: barrier.changes,
          );
      var cubit = createCubit();
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      expect(find.text('أنا فخور بك!'), findsOneWidget);
      expect(acknowledgements, 0);
      await tester.tap(find.byKey(const ValueKey('encouragement-done')));
      await tester.pumpAndSettle();
      expect(find.text('أحسنت!'), findsOneWidget);
      expect(acknowledgements, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(cubit.close);
      cubit = createCubit();
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();
      expect(find.text('أنا فخور بك!'), findsNothing);
      expect(find.text('أحسنت!'), findsOneWidget);

      barrier.invalidate();
      expect(cubit.state.pending, isEmpty);
      // Deliver the Cubit stream event, then render its scheduled frame.
      await tester.pump();
      await tester.pump();
      expect(find.text('أحسنت!'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(cubit.close);
    },
  );
}

Widget _app(ChildEncouragementInboxCubit cubit) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: BlocProvider.value(
      value: cubit,
      child: const ChildEncouragementInbox(),
    ),
  ),
);

Map<String, dynamic> _row(int id, String message) => {
  'id': id,
  'parent_user_id': 'parent-a',
  'child_user_id': 'child-a',
  'message_key': message,
  'sticker_key': 'star_reward',
  'created_at': '2026-10-21T00:00:00Z',
  'seen_at': null,
  'client_request_id': '00000000-0000-4000-8000-00000000000$id',
};
