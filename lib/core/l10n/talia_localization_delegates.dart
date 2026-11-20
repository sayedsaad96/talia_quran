import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// Localization delegates for the app's `material_ui` / `cupertino_ui` widgets.
///
/// The generated `AppLocalizations.localizationsDelegates` list still points at
/// the deprecated `flutter_localizations` Material and Cupertino delegates,
/// which provide a different `MaterialLocalizations` type than the one
/// `material_ui` widgets look up. Use this list instead.
const List<LocalizationsDelegate<dynamic>> taliaLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];
