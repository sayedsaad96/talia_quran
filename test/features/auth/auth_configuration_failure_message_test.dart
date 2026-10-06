import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/localization_helpers.dart';
import 'package:talia_quran/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'missing cloud config shows a user message, not build settings '
      '(${locale.languageCode})',
      (tester) async {
        late BuildContext captured;
        await tester.pumpWidget(
          Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final text = captured.localizedCubitMessage(
          const AuthConfigurationFailure().message,
        );

        expect(text, lookupAppLocalizations(locale).authCloudUnavailable);
        expect(text, isNot(contains('SUPABASE')));
      },
    );
  }
}
