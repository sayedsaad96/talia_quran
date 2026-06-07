# Audit file review and start

**Session ID:** ses_178231534ffe9I8MQQVm1oKD1z
**Created:** 02/06/2026, 13:24:22
**Updated:** 02/06/2026, 13:37:14

---

## User

read docs/audit.md file and start 

---

## Assistant (Build · MiniMax M3 Free · 27.0s)

_Thinking:_

The user wants me to read the docs/audit.md file. Let me do that.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\docs\\audit.md"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\docs\audit.md</path>
<type>file</type>
<content>


(End of file - total 0 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 35.6s)

_Thinking:_

The file is empty. The user said "read docs/audit.md file and start" - this is ambiguous. The file is empty, so there's nothing to "start" based on content. Let me check if there are related files or context.

The file `docs/audit.md` is empty (0 lines). What would you like me to do? Possible next steps:

**Tool: question**

**Input:**
```json
{
  "questions": [
    {
      "question": "The docs/audit.md file is empty. What would you like to do?",
      "header": "Empty file action",
      "options": [
        {
          "label": "Specify the task first",
          "description": "Wait for you to provide instructions or content before proceeding"
        },
        {
          "label": "Check related files for context",
          "description": "Look at the codebase, specs, or other docs to understand what audit to perform"
        },
        {
          "label": "Run a speckit skill workflow",
          "description": "Use a Spec Kit skill (e.g., speckit-analyze, speckit-specify) to begin the audit"
        }
      ]
    }
  ]
}
```

**Error:**
```
The user dismissed this question
```

---

## User

read docs/audit.md file and start 

---

## Assistant (Build · MiniMax M3 Free · 6.6s)

_Thinking:_

The user is asking me to read the docs/audit.md file and start. The file was empty last time. Let me read it again to make sure nothing has changed.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\docs\\audit.md"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\docs\audit.md</path>
<type>file</type>
<content>
1: Start fixing.
2: 
3: You are a senior Flutter architect and release-readiness code reviewer.
4: 
5: Goal:
6: Audit and fix the entire memorization system in Talia Quran app before production release.
7: 
8: Main objective:
9: Ensure there is no conflict, duplication, or broken logic between:
10: - Kids memorization path
11: - Adult memorization path
12: - Smart memorization system
13: - Basic memorization system
14: - Home screen continuation cards
15: - Progress tracking
16: 
17: Critical release rule:
18: This is a production app close to publishing.
19: Do NOT rewrite the whole system.
20: Do NOT break existing progress.
21: Do NOT change Quran source files.
22: Do NOT change storage/database models unless absolutely necessary.
23: Prefer safe refactoring, routing fixes, and centralized source of truth.
24: 
25: Required final behavior:
26: 
27: 1. Path separation
28: - Kids path and adult path must be fully separated in UI, routing, progress display, and continuation logic.
29: - No Kids UI should appear for adult path.
30: - No adult/basic old UI should appear for kids path.
31: - Switching path should immediately update the visible UI everywhere.
32: 
33: 2. Smart memorization behavior
34: - Smart memorization must be linked to the selected memorization path.
35: - If selected path is Kids:
36:   - Smart memorization shows the Kids Gamified UI.
37: - If selected path is Adult:
38:   - Smart memorization shows the adult/basic UI.
39: - Smart memorization must not have a separate inconsistent UI state.
40: 
41: 3. Basic memorization behavior
42: - Basic memorization must also follow the selected path.
43: - If selected path is Kids:
44:   - Basic memorization shows Kids Gamified UI.
45: - If selected path is Adult:
46:   - Basic memorization shows adult/basic UI.
47: 
48: 4. Home screen behavior
49: - Home screen continuation/progress cards must reflect the currently selected memorization path.
50: - If selected path changes:
51:   - Home screen must update accordingly.
52: - Continue memorization button/card must navigate to the correct UI based on selected path.
53: - Home screen must not show stale progress from another path.
54: - Home screen must not mix Kids and Adult progress.
55: 
56: 5. Progress logic
57: - Progress must be based only on actual completed memorization.
58: - Do not increase progress just because a screen was opened.
59: - Do not duplicate progress between kids/adult paths incorrectly.
60: - Do not reset existing user progress.
61: - Verify locked/current/completed states are calculated correctly.
62: - Verify stage completion depends on actual ayah completion.
63: - Verify smart memorization progress and basic memorization progress use the same reliable source of truth where appropriate.
64: 
65: 6. Routing consistency
66: Audit all routes and navigation entry points:
67: - Home screen continue button
68: - Memorization tab
69: - Kids path entry
70: - Adult path entry
71: - Smart memorization entry
72: - Basic memorization entry
73: - Stage details
74: - Listen/repeat/test pages
75: - Back navigation
76: 
77: Required routing rule:
78: Create or use one central router/wrapper if needed:
79: 
80: MemorizationPathRouterScreen
81: 
82: Pseudo logic:
83: final selectedPath = selected path source of truth;
84: 
85: if selectedPath == kids:
86:   return KidsGamifiedMemorizationFlow(...);
87: 
88: return AdultMemorizationFlow(...);
89: 
90: This router must be used by all memorization entry points.
91: 
92: 7. Single source of truth
93: Audit selected memorization path state.
94: There must be one reliable source of truth for:
95: - selected path
96: - current active memorization mode if needed
97: - current progress
98: - current surah/stage/ayah
99: 
100: If duplicates exist:
101: - Identify them.
102: - Remove or deprecate duplicated state safely.
103: - Do not introduce another duplicate state.
104: 
105: 8. UI consistency
106: - Kids path uses only Kids Gamified UI.
107: - Adult path uses only adult/basic UI.
108: - Smart and basic modes must not decide UI independently.
109: - UI must depend on selected path, not entry source.
110: 
111: 9. Data safety
112: Before making changes:
113: - Identify all storage keys, local DB boxes, repositories, or services related to:
114:   - selected memorization path
115:   - progress
116:   - smart memorization settings
117:   - basic memorization progress
118: - Do not rename storage keys unless a migration is added.
119: - Do not delete old user progress.
120: 
121: 10. Required audit output before fixing
122: First provide:
123: - Current architecture summary
124: - All memorization-related screens/widgets
125: - All related Cubits/Bloc/providers
126: - All repositories/services/storage keys
127: - All routes/navigation entry points
128: - Identified conflicts/duplications
129: - Risk level for each issue
130: - Safe fix plan
131: 
132: Then implement only after the audit plan is clear.
133: 
134: 11. Required fixes
135: Fix only confirmed issues, including:
136: - Kids UI not appearing consistently across all flows
137: - Smart/basic memorization using different UI decisions
138: - Home screen showing stale or wrong path progress
139: - Path switching not refreshing related screens
140: - Duplicated progress calculations
141: - Any unsafe route bypassing the central router
142: - Any progress update triggered by screen open instead of actual memorization completion
143: 
144: 12. Testing requirements
145: After fixes, test these scenarios manually and/or with widget/unit tests where possible:
146: 
147: Scenario A:
148: - Select Kids path
149: - Open basic memorization
150: - Expected: Kids Gamified UI appears
151: 
152: Scenario B:
153: - Select Kids path
154: - Open smart memorization
155: - Expected: Kids Gamified UI appears
156: 
157: Scenario C:
158: - Select Adult path
159: - Open basic memorization
160: - Expected: Adult UI appears
161: 
162: Scenario D:
163: - Select Adult path
164: - Open smart memorization
165: - Expected: Adult UI appears
166: 
167: Scenario E:
168: - Change path from Kids to Adult
169: - Return to home
170: - Expected: Home continuation card updates to Adult path
171: 
172: Scenario F:
173: - Change path from Adult to Kids
174: - Return to home
175: - Expected: Home continuation card updates to Kids path
176: 
177: Scenario G:
178: - Complete an ayah in Kids path
179: - Expected: Kids progress updates only
180: 
181: Scenario H:
182: - Complete an ayah in Adult path
183: - Expected: Adult progress updates only
184: 
185: Scenario I:
186: - Open a memorization screen without completing anything
187: - Expected: progress does not increase
188: 
189: Scenario J:
190: - Restart the app
191: - Expected: selected path and progress load correctly
192: 
193: 13. Verification commands
194: Run:
195: - flutter analyze
196: - flutter test
197: - flutter pub get if needed
198: 
199: 14. Deliverables
200: At the end, provide:
201: - Files changed
202: - Issues found
203: - Issues fixed
204: - Remaining risks
205: - Confirmation that Quran source files were not modified
206: - Confirmation that user progress was not reset
207: - Confirmation that Kids and Adult paths are isolated
208: - Confirmation that home screen follows selected path
209: - Confirmation that app is safer for release
210: 
211: *** Do the audit first. Do not edit code until you show me the architecture summary and safe fix plan. 

(End of file - total 211 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 17.5s)

_Thinking:_

The audit.md file is now populated with a comprehensive task. The user wants me to:

1. First do a thorough audit of the memorization system in Talia Quran Flutter app
2. Show architecture summary and safe fix plan FIRST
3. Do NOT edit code until they approve

Let me start by exploring the codebase to understand:
- Architecture summary
- All memorization-related screens/widgets
- All related Cubits/Bloc/providers
- All repositories/services/storage keys
- All routes/navigation entry points
- Identified conflicts/duplications
- Risk level for each issue
- Safe fix plan

Let me start with a thorough exploration. I should use the explore agent for this.

Let me first do a quick scan of the project structure.

I'll start the audit. Let me explore the codebase systematically before any fixes.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Explore project structure and architecture",
      "status": "in_progress",
      "priority": "high"
    },
    {
      "content": "Identify all memorization screens/widgets",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Identify all Cubits/Bloc/providers related to memorization",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Identify repositories/services/storage keys",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Map all routes/navigation entry points",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Identify conflicts/duplications and risk levels",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Produce safe fix plan and present for approval",
      "status": "pending",
      "priority": "high"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Explore project structure and architecture",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Identify all memorization screens/widgets",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Identify all Cubits/Bloc/providers related to memorization",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Identify repositories/services/storage keys",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Map all routes/navigation entry points",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Identify conflicts/duplications and risk levels",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Produce safe fix plan and present for approval",
    "status": "pending",
    "priority": "high"
  }
]
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran</path>
<type>directory</type>
<entries>
.agents/
.codex-remote-attachments/
.dart_tool/
.env
.env.example
.flutter-plugins-dependencies
.git/
.gitignore
.idea/
.metadata
.specify/
.vscode/
analysis_options.yaml
analyze_output.txt
android/
assets/
build/
coverage/
devtools_options.yaml
docs/
flutter_launcher_icons.yaml
GEMINI.md
ios/
l10n.yaml
lib/
linux/
macos/
pubspec.lock
pubspec.yaml
README.md
scripts/
specs/
supabase_schema.sql
talia_quran.iml
test_builder.jar
test/
third_party/
web/
windows/

(39 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 4.6s)

_Thinking:_

Let me explore the lib/ directory structure first.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib</path>
<type>directory</type>
<entries>
app.dart
core/
features/
main.dart

(4 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\pubspec.yaml"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\pubspec.yaml</path>
<type>file</type>
<content>
1: name: talia_quran
2: description: "تالية — تطبيق تحفيظ القرآن الذكي | Talia Quran Memorization App"
3: # The following line prevents the package from being accidentally published to
4: # pub.dev using `flutter pub publish`. This is preferred for private packages.
5: publish_to: 'none' # Remove this line if you wish to publish to pub.dev
6: 
7: # The following defines the version and build number for your application.
8: # A version number is three numbers separated by dots, like 1.2.43
9: # followed by an optional build number separated by a +.
10: # Both the version and the builder number may be overridden in flutter
11: # build by specifying --build-name and --build-number, respectively.
12: # In Android, build-name is used as versionName while build-number used as versionCode.
13: # Read more about Android versioning at https://developer.android.com/studio/publish/versioning
14: # In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
15: # Read more about iOS versioning at
16: # https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
17: # In Windows, build-name is used as the major, minor, and patch parts
18: # of the product and file versions while build-number is used as the build suffix.
19: version: 1.0.0+1
20: 
21: environment:
22:   sdk: ^3.11.4
23: 
24: # Dependencies specify other packages that your package needs in order to work.
25: # To automatically upgrade your package dependencies to the latest versions
26: # consider running `flutter pub upgrade --major-versions`. Alternatively,
27: # dependencies can be manually updated by changing the version numbers below to
28: # the latest version available on pub.dev. To see which dependencies have newer
29: # versions available, run `flutter pub outdated`.
30: dependencies:
31:   cupertino_icons: ^1.0.8
32:   dartz: ^0.10.1
33:   equatable: ^2.0.8
34:   flutter:
35:     sdk: flutter
36:   flutter_animate: ^4.5.2
37:   flutter_bloc: ^9.1.1
38:   flutter_cache_manager: ^3.4.1
39:   flutter_local_notifications: ^21.0.0
40:   flutter_localizations:
41:     sdk: flutter
42:   get_it: ^9.2.1
43:   go_router: ^17.2.1
44:   google_fonts: ^8.0.2
45:   isar: ^3.1.0+1
46:   isar_flutter_libs: ^3.1.0+1
47:   just_audio: ^0.10.5
48:   path_provider: ^2.1.5
49:   percent_indicator: ^4.2.5
50:   permission_handler: ^12.0.1
51:   share_plus: ^13.1.0
52:   shared_preferences: ^2.5.5
53:   shimmer: ^3.0.0
54:   speech_to_text: ^7.3.0
55:   string_similarity: ^2.2.0
56:   timezone: ^0.11.0
57:   flutter_timezone: ^3.0.0
58:   confetti: ^0.7.0
59:   screenshot: ^3.0.0
60:   supabase_flutter: ^2.8.0
61:   flutter_dotenv: ^5.2.1
62:   cached_network_image: ^3.4.1
63:   crypto: ^3.0.6
64:   qcf_quran_plus: ^0.0.8
65:   qr_flutter: ^4.1.0
66:   mobile_scanner: ^7.1.3
67:   gal: ^2.3.2
68:   pdf: ^3.12.0
69:   printing: ^5.14.3
70: 
71: 
72: dev_dependencies:
73:   build_runner: ^2.4.13
74: 
75:   flutter_launcher_icons: ^0.14.4
76: 
77:   # The "flutter_lints" package below contains a set of recommended lints to
78:   # encourage good coding practices. The lint set provided by the package is
79:   # activated in the `analysis_options.yaml` file located at the root of your
80:   # package. See that file for information about deactivating specific lint
81:   # rules and activating additional ones.
82:   flutter_lints: ^6.0.0
83:   flutter_native_splash: ^2.4.0
84:   flutter_test:
85:     sdk: flutter
86:   isar_generator: ^3.1.0+1
87:   mockito: ^5.4.4
88: 
89: flutter_launcher_icons:
90:   android: "launcher_icon"
91:   ios: true
92:   image_path: "assets/icon/icon.png"
93:   adaptive_icon_background: "#061811" # لون أخضر داكن جداً يطابق خلفية الشعار
94:   adaptive_icon_foreground: "assets/icon/icon.png"
95: 
96: flutter_native_splash:
97:   color: "#ffffff"
98:   image: "assets/images/splash.png"
99:   fullscreen: true
100:   ios_content_mode: scaleAspectFit
101:   android_gravity: center
102:   android_12:
103:     image: "assets/images/splash_android12.png"
104:     icon_background_color: "#ffffff"
105: 
106: # For information on the generic Dart part of this file, see the
107: # following page: https://dart.dev/tools/pub/pubspec
108: # The following section is specific to Flutter packages.
109: flutter:
110:   generate: true
111: 
112:   # The following line ensures that the Material Icons font is
113:   # included with your application, so that you can use the icons in
114:   # the material Icons class.
115:   uses-material-design: true
116: 
117:   # To add assets to your application, add an assets section, like this:
118:   assets:
119:     - .env
120:     - assets/data/
121:     - assets/fonts/
122:     - assets/images/
123:     - assets/images/kids/
124:     
125: 
126:   # An image asset can refer to one or more resolution-specific "variants", see
127:   # https://flutter.dev/to/resolution-aware-images
128:   # For details regarding adding assets from package dependencies, see
129:   # https://flutter.dev/to/asset-from-package
130:   # To add custom fonts to your application, add a fonts section here,
131:   # in this "flutter" section. Each entry in this list should have a
132:   # "family" key with the font family name, and a "fonts" key with a
133:   # list giving the asset and other descriptors for the font. For
134:   # example:
135:   fonts:
136:     - family: Amiri
137:       fonts:
138:         - asset: assets/fonts/Amiri/Amiri-Regular.ttf
139:         - asset: assets/fonts/Amiri/Amiri-Bold.ttf
140:           weight: 700
141:     - family: Noto_Naskh_Arabic
142:       fonts:
143:         - asset: assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf
144:         - asset: assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Bold.ttf
145:           weight: 700
146:     - family: MrsSaintDelafield
147:       fonts:
148:         - asset: assets/fonts/Mrs_Saint_Delafield/MrsSaintDelafield-Regular.ttf
149:   # For details regarding fonts from package dependencies,
150:   # see https://flutter.dev/to/font-from-package

(End of file - total 150 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 9.0s)

_Thinking:_

Now I have a good idea of the project structure. It's using:
- Flutter with Bloc (flutter_bloc)
- go_router for navigation
- isar for local DB
- shared_preferences for settings
- supabase_flutter for backend
- get_it for DI

Let me explore the lib/ features and core directories.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features</path>
<type>directory</type>
<entries>
auth/
azkar/
certificate/
hifz/
home/
memorization_plus/
onboarding/
progress/
quran/
settings/
splash/
streak/
tutorial_guide/
xp/

(14 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core</path>
<type>directory</type>
<entries>
constants/
database/
di/
error/
extensions/
l10n/
router/
services/
theme/
utils/
widgets/

(11 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\app.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\app.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: 
3: import 'package:flutter/material.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import 'package:flutter_localizations/flutter_localizations.dart';
6: 
7: import 'core/l10n/app_localizations.dart';
8: import 'core/router/app_router.dart';
9: import 'core/services/app_session_service.dart';
10: import 'core/theme/app_theme.dart';
11: import 'core/theme/theme_cubit.dart';
12: import 'core/l10n/locale_cubit.dart';
13: import 'core/di/injection.dart';
14: import 'features/settings/presentation/cubits/profile_cubit.dart';
15: import 'features/auth/presentation/cubits/auth_cubit.dart';
16: 
17: import 'core/services/notification_service.dart';
18: 
19: class TaliaApp extends StatefulWidget {
20:   const TaliaApp({super.key});
21: 
22:   @override
23:   State<TaliaApp> createState() => _TaliaAppState();
24: }
25: 
26: class _TaliaAppState extends State<TaliaApp> with WidgetsBindingObserver {
27:   late final TaliaNotificationService _notificationService =
28:       getIt<TaliaNotificationService>();
29: 
30:   @override
31:   void initState() {
32:     super.initState();
33:     WidgetsBinding.instance.addObserver(this);
34:     _notificationService.onPayloadReceived = _openNotification;
35:     AppRouter.router.routerDelegate.addListener(_saveCurrentLocation);
36:     WidgetsBinding.instance.addPostFrameCallback((_) {
37:       final payload = _notificationService.takePendingLaunchPayload();
38:       if (payload != null) {
39:         _openNotification(payload);
40:       }
41:     });
42:   }
43: 
44:   @override
45:   void dispose() {
46:     WidgetsBinding.instance.removeObserver(this);
47:     _notificationService.onPayloadReceived = null;
48:     AppRouter.router.routerDelegate.removeListener(_saveCurrentLocation);
49:     super.dispose();
50:   }
51: 
52:   @override
53:   void didChangeAppLifecycleState(AppLifecycleState state) {
54:     if (state == AppLifecycleState.resumed) {
55:       // Refresh notifications on resume to sync timezone/time
56:       _notificationService.refreshNotifications();
57:     } else if (state == AppLifecycleState.inactive ||
58:         state == AppLifecycleState.hidden ||
59:         state == AppLifecycleState.paused ||
60:         state == AppLifecycleState.detached) {
61:       _saveCurrentLocation();
62:     }
63:   }
64: 
65:   void _openNotification(String payload) {
66:     if (!mounted || payload.isEmpty || !payload.startsWith('/')) return;
67:     AppRouter.router.go(payload);
68:   }
69: 
70:   void _saveCurrentLocation() {
71:     final location = AppRouter.router.routerDelegate.currentConfiguration.uri
72:         .toString();
73:     unawaited(getIt<AppSessionService>().saveLocation(location));
74:   }
75: 
76:   @override
77:   Widget build(BuildContext context) {
78:     return MultiBlocProvider(
79:       providers: [
80:         BlocProvider(create: (_) => getIt<ThemeCubit>()..loadTheme()),
81:         BlocProvider(create: (_) => getIt<LocaleCubit>()..loadLocale()),
82:         BlocProvider(create: (_) => getIt<ProfileCubit>()..loadProfile()),
83:         // AuthCubit is a GetIt singleton — use value: so the framework does
84:         // not dispose it when this widget is torn down.
85:         BlocProvider.value(value: getIt<AuthCubit>()),
86:       ],
87:       child: BlocBuilder<LocaleCubit, Locale>(
88:         builder: (context, locale) {
89:           return BlocBuilder<ThemeCubit, ThemeMode>(
90:             builder: (context, themeMode) {
91:               return MaterialApp.router(
92:                 title: 'تالية',
93:                 debugShowCheckedModeBanner: false,
94:                 themeMode: themeMode,
95:                 theme: AppTheme.light,
96:                 darkTheme: AppTheme.dark,
97:                 locale: locale,
98:                 supportedLocales: AppLocalizations.supportedLocales,
99:                 localizationsDelegates: const [
100:                   AppLocalizations.delegate,
101:                   GlobalMaterialLocalizations.delegate,
102:                   GlobalWidgetsLocalizations.delegate,
103:                   GlobalCupertinoLocalizations.delegate,
104:                 ],
105:                 routerConfig: AppRouter.router,
106:               );
107:             },
108:           );
109:         },
110:       ),
111:     );
112:   }
113: }

(End of file - total 113 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\main.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\main.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: import 'package:flutter/foundation.dart';
3: import 'package:flutter/material.dart';
4: import 'package:flutter/services.dart';
5: import 'package:flutter_dotenv/flutter_dotenv.dart';
6: import 'package:google_fonts/google_fonts.dart';
7: import 'package:qcf_quran_plus/qcf_quran_plus.dart';
8: import 'package:shared_preferences/shared_preferences.dart';
9: import 'package:supabase_flutter/supabase_flutter.dart';
10: import 'app.dart';
11: import 'core/di/injection.dart';
12: import 'core/services/notification_service.dart';
13: import 'core/utils/talia_logger.dart';
14: 
15: Future<void> main() async {
16:   await runZonedGuarded(
17:     () async {
18:       WidgetsFlutterBinding.ensureInitialized();
19: 
20:       // M01 FIX: Global error handler — show friendly UI in production instead of red screen
21:       FlutterError.onError = (details) {
22:         TaliaLogger.e(
23:           'Flutter framework error',
24:           details.exception,
25:           details.stack,
26:         );
27:         if (kDebugMode) {
28:           FlutterError.presentError(details);
29:         }
30:       };
31: 
32:       // M01 FIX: Friendly error widget for production
33:       if (!kDebugMode) {
34:         ErrorWidget.builder = (details) => const Directionality(
35:           textDirection: TextDirection.rtl,
36:           child: Center(
37:             child: Padding(
38:               padding: EdgeInsets.all(24),
39:               child: Text(
40:                 'حدث خطأ غير متوقع.\nيرجى إعادة تشغيل التطبيق.',
41:                 textAlign: TextAlign.center,
42:                 style: TextStyle(fontSize: 16, color: Colors.grey),
43:               ),
44:             ),
45:           ),
46:         );
47:       }
48: 
49:       try {
50:         await _bootstrapAndRun();
51:       } catch (error, stack) {
52:         TaliaLogger.e('App bootstrap failed', error, stack);
53:         runApp(const _StartupFailureApp());
54:       }
55:     },
56:     (error, stack) {
57:       TaliaLogger.e('Uncaught async error', error, stack);
58:     },
59:   );
60: }
61: 
62: Future<void> _bootstrapAndRun() async {
63:   // Load environment variables from .env (excluded from Git via .gitignore).
64:   // Wrapped in try-catch: if .env is absent (CI, release build without asset,
65:   // or after Phase 3 removal from pubspec assets), the app continues in
66:   // offline mode rather than crashing before any local content is reachable.
67:   try {
68:     await dotenv.load(fileName: '.env');
69:   } catch (_) {
70:     // .env not found — continue without Supabase config (offline mode).
71:   }
72: 
73:   // Prevent Google Fonts from fetching fonts at runtime — all fonts are bundled as assets
74:   GoogleFonts.config.allowRuntimeFetching = false;
75: 
76:   await QcfFontLoader.setupFontsAtStartup(onProgress: (_) {});
77: 
78:   // Lock to portrait
79:   await SystemChrome.setPreferredOrientations([
80:     DeviceOrientation.portraitUp,
81:     DeviceOrientation.portraitDown,
82:   ]);
83: 
84:   // Configure status bar
85:   SystemChrome.setSystemUIOverlayStyle(
86:     const SystemUiOverlayStyle(
87:       statusBarColor: Colors.transparent,
88:       statusBarIconBrightness: Brightness.dark,
89:       statusBarBrightness: Brightness.light,
90:     ),
91:   );
92: 
93:   final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
94:   final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
95: 
96:   // OFFLINE-FIRST FIX (FIND-STAB01): If Supabase credentials are absent or
97:   // incomplete, continue in offline mode rather than crashing the app.
98:   // Auth-dependent features will be unavailable, but core Quran/Hifz/Azkar
99:   // functionality is fully offline and remains accessible.
100:   final hasSupabaseConfig =
101:       supabaseUrl != null &&
102:       supabaseUrl.isNotEmpty &&
103:       supabaseAnonKey != null &&
104:       supabaseAnonKey.isNotEmpty;
105: 
106:   if (hasSupabaseConfig) {
107:     // Initialize Supabase — credentials loaded from .env (never hardcoded)
108:     await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
109:   }
110:   // Note: if hasSupabaseConfig is false, the app starts in offline mode.
111:   // Auth features (LoginPage) will show an appropriate error when Supabase
112:   // client is accessed, but all local features remain fully functional.
113: 
114:   // Initialize dependency injection
115:   await configureDependencies();
116: 
117:   // Initialize notifications with sensible defaults
118:   final notificationService = getIt<TaliaNotificationService>();
119:   await notificationService.initialize();
120:   // M05 FIX: Do not await requestPermissions() before runApp.
121:   // Awaiting this before runApp() on Android 13+ blocks the main isolate
122:   // while the OS permission dialog is active. If the dialog is hidden behind
123:   // the splash screen, the app will appear to hang infinitely.
124:   unawaited(
125:     notificationService.requestPermissions(),
126:   ); // intentionally not awaited
127: 
128:   final prefs = getIt<SharedPreferences>();
129: 
130:   // M03 FIX: Only schedule default notifications on first launch.
131:   // Both flags are merged to prevent the old double-scheduling bug where
132:   // morning/evening azkar and daily dua were scheduled in both blocks.
133:   final notificationsInitialized =
134:       prefs.getBool('notifications_initialized') ?? false;
135:   if (!notificationsInitialized) {
136:     // Read (or default) all per-type preferences before first scheduling
137:     final reviewEnabled =
138:         prefs.getBool(TaliaNotificationService.dailyReviewPreferenceKey) ??
139:         true;
140:     final morningAzkarEnabled =
141:         prefs.getBool(TaliaNotificationService.morningAzkarPreferenceKey) ??
142:         true;
143:     final eveningAzkarEnabled =
144:         prefs.getBool(TaliaNotificationService.eveningAzkarPreferenceKey) ??
145:         true;
146:     final dailyDuaEnabled =
147:         prefs.getBool(TaliaNotificationService.dailyDuaPreferenceKey) ?? true;
148: 
149:     // Persist defaults so Settings page reads them correctly
150:     await prefs.setBool(
151:       TaliaNotificationService.morningAzkarPreferenceKey,
152:       morningAzkarEnabled,
153:     );
154:     await prefs.setBool(
155:       TaliaNotificationService.eveningAzkarPreferenceKey,
156:       eveningAzkarEnabled,
157:     );
158:     await prefs.setBool(
159:       TaliaNotificationService.dailyDuaPreferenceKey,
160:       dailyDuaEnabled,
161:     );
162: 
163:     // Schedule each notification exactly once, respecting the defaults above
164:     if (reviewEnabled) {
165:       await notificationService.scheduleDailyReviewReminder(); // 8:00 PM
166:     }
167:     await notificationService.scheduleDailyAyahReminder(); // 7:00 AM
168:     if (morningAzkarEnabled) {
169:       await notificationService.scheduleMorningAzkarReminder(); // 6:00 AM
170:     }
171:     if (eveningAzkarEnabled) {
172:       await notificationService.scheduleEveningAzkarReminder(); // 6:00 PM
173:     }
174:     if (dailyDuaEnabled) {
175:       await notificationService.scheduleDailyDuaReminder(); // 9:00 AM
176:     }
177: 
178:     await prefs.setBool('notifications_initialized', true);
179:     // Mark the old azkar flag too so existing installs don't re-run the old block
180:     await prefs.setBool('notifications_azkar_initialized', true);
181:   }
182: 
183:   await notificationService
184:       .cancelStreakAlert(); // Cancel stale alerts on launch
185: 
186:   runApp(const TaliaApp());
187: }
188: 
189: class _StartupFailureApp extends StatelessWidget {
190:   const _StartupFailureApp();
191: 
192:   @override
193:   Widget build(BuildContext context) {
194:     return const MaterialApp(
195:       debugShowCheckedModeBanner: false,
196:       home: Directionality(
197:         textDirection: TextDirection.rtl,
198:         child: Scaffold(
199:           body: Center(
200:             child: Padding(
201:               padding: EdgeInsets.all(24),
202:               child: Text(
203:                 'تعذر تشغيل تالية حالياً.\nتأكد من إعدادات التطبيق ثم أعد المحاولة.',
204:                 textAlign: TextAlign.center,
205:                 style: TextStyle(fontSize: 16, color: Colors.grey),
206:               ),
207:             ),
208:           ),
209:         ),
210:       ),
211:     );
212:   }
213: }

(End of file - total 213 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.7s)

_Thinking:_

Let me look at the key features related to memorization: hifz, memorization_plus, home, progress. Let me also look at the router and di.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\router"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\router</path>
<type>directory</type>
<entries>
app_router.dart

(1 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\di"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\di</path>
<type>directory</type>
<entries>
injection.dart

(1 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz</path>
<type>directory</type>
<entries>
data/
domain/
presentation/

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus</path>
<type>directory</type>
<entries>
data/
domain/
presentation/

(3 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 8.2s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\router\\app_router.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\router\app_router.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: import 'package:flutter/foundation.dart';
3: import 'package:flutter/material.dart';
4: import 'package:go_router/go_router.dart';
5: import 'package:shared_preferences/shared_preferences.dart';
6: import '../../features/auth/presentation/cubits/auth_cubit.dart';
7: import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
8: import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
9: import '../constants/app_constants.dart';
10: import '../di/injection.dart';
11: 
12: import '../../features/home/presentation/pages/home_page.dart';
13: import '../../features/quran/presentation/pages/quran_page.dart';
14: import '../../features/quran/presentation/pages/quran_reader_page.dart';
15: import '../../features/hifz/presentation/pages/hifz_page.dart';
16: import '../../features/hifz/presentation/pages/hifz_session_page.dart';
17: import '../../features/azkar/presentation/pages/azkar_page.dart';
18: import '../../features/azkar/presentation/pages/azkar_category_page.dart';
19: import '../../features/azkar/presentation/pages/general_azkar_page.dart';
20: import '../../features/azkar/domain/entities/azkar_entities.dart';
21: import '../../features/progress/presentation/pages/progress_page.dart';
22: import '../../features/settings/presentation/pages/settings_page.dart';
23: import '../../features/memorization_plus/presentation/pages/path_selection_page.dart';
24: import '../../features/memorization_plus/presentation/pages/guardian_linking_page.dart';
25: import '../../features/memorization_plus/presentation/pages/daily_plan_page.dart';
26: import '../../features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';
27: import '../../features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
28: import '../../features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
29: import '../../features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
30: import '../../features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';
31: import '../../features/memorization_plus/presentation/pages/parent_dashboard_page.dart';
32: import '../../features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
33: import '../../features/memorization_plus/presentation/pages/quiz_page.dart';
34: import '../../features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart';
35: import '../../features/splash/presentation/pages/splash_page.dart';
36: import '../../features/onboarding/presentation/pages/onboarding_page.dart';
37: import '../../features/certificate/presentation/pages/certificate_page.dart';
38: import '../../features/auth/presentation/pages/login_page.dart';
39: import '../../features/tutorial_guide/presentation/pages/tutorial_guide_page.dart';
40: import '../../features/settings/presentation/pages/privacy_policy_page.dart';
41: import '../services/achievement_service.dart';
42: import '../widgets/app_shell.dart';
43: 
44: abstract class AppRoutes {
45:   static const String splash = '/splash';
46:   static const String onboarding = '/onboarding';
47:   static const String home = '/';
48:   static const String quran = '/quran';
49:   static const String hifz = '/hifz';
50:   static const String azkar = '/azkar';
51:   static const String progress = '/progress';
52:   static const String hifzSession = '/hifz/session';
53:   static const String settings = '/settings';
54:   static const String memorizationPlus = '/memorization-plus';
55:   static const String memorizationPlusGuardianLinking =
56:       '/memorization-plus/guardian-linking';
57:   static const String memorizationPlusDailyPlan =
58:       '/memorization-plus/daily-plan';
59:   static const String memorizationPlusKidsJourney =
60:       '/memorization-plus/kids-journey';
61:   static const String memorizationPlusKids = '/memorization-plus/kids';
62:   static const String memorizationPlusKidsHome = '/memorization-plus/kids-home';
63:   static const String memorizationPlusKidsStage =
64:       '/memorization-plus/kids-stage';
65:   static const String memorizationPlusKidsCompletion =
66:       '/memorization-plus/kids-completion';
67:   static const String parentDashboard = '/memorization-plus/parent-dashboard';
68:   static const String memorizationPlusCustomPlan =
69:       '/memorization-plus/custom-plan';
70:   static const String memorizationPlusQuiz = '/memorization-plus/quiz';
71:   static const String qcfRenderingPoc = '/debug/qcf-rendering-poc';
72:   static const String login = '/login';
73:   static const String certificate = '/certificate';
74:   static const String tutorialGuide = '/tutorial-guide';
75:   static const String privacyPolicy = '/settings/privacy-policy';
76: }
77: 
78: /// Bridges [AuthCubit] state stream into a [Listenable] so [GoRouter]
79: /// re-evaluates its [redirect] automatically whenever auth state changes.
80: class _AuthNotifier extends ChangeNotifier {
81:   _AuthNotifier(AuthCubit cubit) {
82:     _sub = cubit.stream.listen((_) => notifyListeners());
83:   }
84: 
85:   late final StreamSubscription<AuthState> _sub;
86: 
87:   @override
88:   void dispose() {
89:     _sub.cancel();
90:     super.dispose();
91:   }
92: }
93: 
94: /// Routes that are always accessible without authentication.
95: final _publicRoutes = <String>[
96:   AppRoutes.splash,
97:   AppRoutes.onboarding,
98:   AppRoutes.login,
99:   AppRoutes.home,
100:   AppRoutes.quran,
101:   AppRoutes.hifz,
102:   AppRoutes.azkar,
103:   AppRoutes.progress,
104:   AppRoutes.settings,
105:   AppRoutes.certificate,
106:   AppRoutes.tutorialGuide,
107:   AppRoutes.privacyPolicy,
108:   if (kDebugMode) AppRoutes.qcfRenderingPoc,
109: ];
110: 
111: abstract class AppRouter {
112:   // UX-4 FIX: Removed _shellNavigatorKey — no longer needed with StatefulShellRoute.
113:   static final _rootNavigatorKey = GlobalKey<NavigatorState>();
114: 
115:   static final GoRouter router = GoRouter(
116:     navigatorKey: _rootNavigatorKey,
117:     initialLocation: AppRoutes.splash,
118:     debugLogDiagnostics: kDebugMode,
119:     // AUTH GATE: redirect unauthenticated users to /login for all protected routes.
120:     refreshListenable: _AuthNotifier(getIt<AuthCubit>()),
121:     redirect: (context, state) {
122:       final authState = getIt<AuthCubit>().state;
123:       final location = state.matchedLocation;
124:       final isPublic = _publicRoutes.any((r) {
125:         if (r == AppRoutes.home) return location == AppRoutes.home;
126:         return location.startsWith(r);
127:       });
128:       if (isPublic) return null;
129:       if (authState is AuthAuthenticated) return null;
130:       if (authState is AuthInitial) return null; // still initialising
131:       return AppRoutes.login; // unauthenticated on protected route
132:     },
133:     // OFFLINE-SAFE: GoRouter wraps any exception thrown inside an async
134:     // redirect as a GoException and re-throws it as an uncaught async error.
135:     // This handler silently swallows network-related redirect failures
136:     // (e.g. AuthRetryableFetchException when Supabase is unreachable)
137:     // and keeps the user on their current page rather than crashing.
138:     onException: (context, state, router) {
139:       // No-op: let the user stay on the current page.
140:       // The per-route try-catch blocks already return safe fallbacks for
141:       // known network errors; this is a last-resort safety net.
142:     },
143:     routes: [
144:       // ── Full-screen routes (push over shell, own back button) ─────────────
145:       GoRoute(
146:         parentNavigatorKey: _rootNavigatorKey,
147:         path: AppRoutes.splash,
148:         builder: (context, state) => const SplashPage(),
149:       ),
150:       GoRoute(
151:         parentNavigatorKey: _rootNavigatorKey,
152:         path: AppRoutes.onboarding,
153:         builder: (context, state) => const OnboardingPage(),
154:       ),
155:       GoRoute(
156:         parentNavigatorKey: _rootNavigatorKey,
157:         path: AppRoutes.login,
158:         builder: (context, state) => const LoginPage(),
159:       ),
160:       GoRoute(
161:         parentNavigatorKey: _rootNavigatorKey,
162:         path: AppRoutes.tutorialGuide,
163:         builder: (context, state) => const TutorialGuidePage(),
164:       ),
165:       if (kDebugMode)
166:         GoRoute(
167:           parentNavigatorKey: _rootNavigatorKey,
168:           path: AppRoutes.qcfRenderingPoc,
169:           builder: (context, state) => const QcfRenderingPocPage(),
170:         ),
171:       GoRoute(
172:         parentNavigatorKey: _rootNavigatorKey,
173:         path: '/certificate',
174:         builder: (context, state) {
175:           final extra = state.extra as Map<String, dynamic>?;
176:           final userName = extra?['userName'] as String? ?? 'مستخدم تالية';
177: 
178:           CertificateAward? award;
179:           final rawAward = extra?['award'];
180:           if (rawAward is CertificateAward) {
181:             award = rawAward;
182:           } else if (rawAward is Map<String, dynamic>) {
183:             award = CertificateAward.fromJson(rawAward);
184:           }
185: 
186:           if (award == null) {
187:             return const Scaffold(
188:               body: Center(child: Text('لم يتم العثور على الشهادة')),
189:             );
190:           }
191:           return CertificatePage(award: award, userName: userName);
192:         },
193:       ),
194:       GoRoute(
195:         parentNavigatorKey: _rootNavigatorKey,
196:         path: '/quran/surah/:surahId',
197:         builder: (context, state) {
198:           final surahId =
199:               int.tryParse(state.pathParameters['surahId'] ?? '1') ?? 1;
200:           return QuranReaderPage(surahId: surahId);
201:         },
202:       ),
203:       GoRoute(
204:         parentNavigatorKey: _rootNavigatorKey,
205:         path: '/quran/page/:pageNumber',
206:         builder: (context, state) {
207:           final pageNumber =
208:               int.tryParse(state.pathParameters['pageNumber'] ?? '1') ?? 1;
209:           return QuranReaderPage(pageNumber: pageNumber);
210:         },
211:       ),
212:       GoRoute(
213:         parentNavigatorKey: _rootNavigatorKey,
214:         path: AppRoutes.hifzSession,
215:         redirect: (context, state) async {
216:           if (!await _isKidsPathSelected()) return null;
217: 
218:           final extra = state.extra as Map<String, dynamic>?;
219:           final surahId =
220:               extra?['surahId'] as int? ??
221:               int.tryParse(state.uri.queryParameters['surahId'] ?? '');
222:           final startAyah =
223:               extra?['startAyah'] as int? ??
224:               int.tryParse(state.uri.queryParameters['startAyah'] ?? '');
225: 
226:           if (_isValidSurahId(surahId) && startAyah != null && startAyah > 0) {
227:             return _kidsListenLocation(
228:               surahId: surahId!,
229:               ayahNumber: startAyah,
230:             );
231:           }
232:           return AppRoutes.memorizationPlusKidsHome;
233:         },
234:         builder: (context, state) {
235:           final extra = state.extra as Map<String, dynamic>?;
236:           final surahId =
237:               extra?['surahId'] as int? ??
238:               int.tryParse(state.uri.queryParameters['surahId'] ?? '');
239:           final startAyah =
240:               extra?['startAyah'] as int? ??
241:               int.tryParse(state.uri.queryParameters['startAyah'] ?? '');
242:           return HifzSessionPage(
243:             surahId: _isValidSurahId(surahId) ? surahId! : 1,
244:             startAyah: startAyah != null && startAyah > 0 ? startAyah : 1,
245:           );
246:         },
247:       ),
248:       GoRoute(
249:         parentNavigatorKey: _rootNavigatorKey,
250:         path: '/azkar/:category',
251:         builder: (context, state) {
252:           final category = state.pathParameters['category'] ?? 'morning';
253:           if (category == 'general' || category == 'duas') {
254:             return GeneralAzkarPage(
255:               category: category == 'duas'
256:                   ? AzkarCategory.duas
257:                   : AzkarCategory.general,
258:             );
259:           }
260:           return AzkarCategoryPage(category: category);
261:         },
262:       ),
263:       GoRoute(
264:         parentNavigatorKey: _rootNavigatorKey,
265:         path: AppRoutes.settings,
266:         builder: (context, state) => const SettingsPage(),
267:       ),
268:       GoRoute(
269:         parentNavigatorKey: _rootNavigatorKey,
270:         path: AppRoutes.privacyPolicy,
271:         builder: (context, state) => const PrivacyPolicyPage(),
272:       ),
273:       GoRoute(
274:         parentNavigatorKey: _rootNavigatorKey,
275:         path: AppRoutes.memorizationPlus,
276:         redirect: (context, state) async {
277:           // OFFLINE-SAFE: wrap in try/catch(Object) to guard against
278:           // AuthRetryableFetchException when the network is unavailable.
279:           // GoRouter wraps any uncaught async error as GoException which
280:           // crashes the router — returning null is a safe no-op fallback.
281:           try {
282:             final repo = getIt<MemorizationPlusRepository>();
283:             final profileResult = await repo.getMemorizationProfile();
284:             final profile = profileResult.fold((_) => null, (p) => p);
285:             if (profile == null) return null;
286: 
287:             if (profile.hasSelectedPath) {
288:               if (profile.isAdult) {
289:                 final planResult = await repo.getCustomPlan();
290:                 final hasPlan = planResult.fold(
291:                   (_) => false,
292:                   (plan) => plan != null,
293:                 );
294:                 if (!hasPlan) return AppRoutes.memorizationPlusCustomPlan;
295:                 return AppRoutes.memorizationPlusDailyPlan;
296:               }
297:               if (profile.isChild) {
298:                 return AppRoutes.memorizationPlusKidsHome;
299:               }
300:             }
301:             return null;
302:           } catch (_) {
303:             // Network unavailable or auth token refresh failed — show
304:             // PathSelectionPage so the user sees their last known state.
305:             return null;
306:           }
307:         },
308:         builder: (context, state) => const PathSelectionPage(),
309:       ),
310:       GoRoute(
311:         parentNavigatorKey: _rootNavigatorKey,
312:         path: AppRoutes.memorizationPlusGuardianLinking,
313:         // T036 route guard: only reachable for children who still need
314:         // guardian onboarding. Adults, skipped children, and already-linked
315:         // children are redirected back to the track-selection entry point.
316:         // OFFLINE-SAFE: catch(Object) ensures network failures never propagate
317:         // out of the redirect callback and crash GoRouter.
318:         redirect: (context, state) async {
319:           try {
320:             final repo = getIt<MemorizationPlusRepository>();
321:             final profileResult = await repo.getMemorizationProfile();
322:             return profileResult.fold(
323:               (_) => null, // on data error, show guardian page (offline-safe)
324:               (profile) {
325:                 // Allow only: child with onboarding still required
326:                 if (profile.isChild &&
327:                     profile.guardianOnboardingStatus ==
328:                         GuardianOnboardingStatus.required) {
329:                   return null; // permit navigation
330:                 }
331:                 return AppRoutes.memorizationPlus; // redirect all other states
332:               },
333:             );
334:           } catch (_) {
335:             // Network unavailable — allow guardian-linking page to load;
336:             // it will show its own offline-aware UI.
337:             return null;
338:           }
339:         },
340:         builder: (context, state) => const GuardianLinkingPage(),
341:       ),
342:       GoRoute(
343:         parentNavigatorKey: _rootNavigatorKey,
344:         path: AppRoutes.memorizationPlusDailyPlan,
345:         redirect: (context, state) => _redirectKidsPathToKidsHome(),
346:         builder: (context, state) {
347:           final extra = state.extra as Map<String, dynamic>?;
348:           final surahId =
349:               extra?['surahId'] as int? ??
350:               int.tryParse(state.uri.queryParameters['surahId'] ?? '') ??
351:               1; // M06 FIX: Default to 1 to prevent redirect loops
352:           if (!_isValidSurahId(surahId)) {
353:             return const PathSelectionPage();
354:           }
355:           return DailyPlanPage(surahId: surahId);
356:         },
357:       ),
358:       GoRoute(
359:         parentNavigatorKey: _rootNavigatorKey,
360:         path: AppRoutes.memorizationPlusKidsJourney,
361:         redirect: (context, state) => _redirectNonKidsPathToMemorization(),
362:         builder: (context, state) {
363:           final extra = state.extra as Map<String, dynamic>?;
364:           final surahId =
365:               extra?['surahId'] as int? ??
366:               int.tryParse(state.uri.queryParameters['surahId'] ?? '') ??
367:               1; // M06 FIX: Default to 1 to prevent redirect loops
368:           if (!_isValidSurahId(surahId)) {
369:             return const PathSelectionPage();
370:           }
371:           return KidsGamifiedJourneyPage(surahId: surahId);
372:         },
373:       ),
374:       GoRoute(
375:         parentNavigatorKey: _rootNavigatorKey,
376:         path: AppRoutes.memorizationPlusKids,
377:         redirect: (context, state) => _redirectNonKidsPathToMemorization(),
378:         builder: (context, state) {
379:           final extra = state.extra as Map<String, dynamic>?;
380:           final surahId =
381:               extra?['surahId'] as int? ??
382:               int.tryParse(state.uri.queryParameters['surahId'] ?? '');
383:           final ayahNumber =
384:               extra?['ayahNumber'] as int? ??
385:               int.tryParse(state.uri.queryParameters['ayahNumber'] ?? '');
386:           if (!_isValidSurahId(surahId) ||
387:               ayahNumber == null ||
388:               ayahNumber < 1) {
389:             return const PathSelectionPage();
390:           }
391:           final resolvedSurahId = surahId!;
392:           final ayahText = extra?['ayahText'] as String? ?? '';
393:           return KidsGamifiedListenPage(
394:             surahId: resolvedSurahId,
395:             ayahNumber: ayahNumber,
396:             ayahText: ayahText,
397:           );
398:         },
399:       ),
400:       GoRoute(
401:         parentNavigatorKey: _rootNavigatorKey,
402:         path: AppRoutes.memorizationPlusKidsHome,
403:         redirect: (context, state) => _redirectNonKidsPathToMemorization(),
404:         builder: (context, state) {
405:           final extra = state.extra as Map<String, dynamic>?;
406:           final surahId =
407:               extra?['surahId'] as int? ??
408:               int.tryParse(state.uri.queryParameters['surahId'] ?? '') ??
409:               1;
410:           if (!_isValidSurahId(surahId)) {
411:             return const PathSelectionPage();
412:           }
413:           return KidsGamifiedHomePage(surahId: surahId);
414:         },
415:       ),
416:       GoRoute(
417:         parentNavigatorKey: _rootNavigatorKey,
418:         path: AppRoutes.memorizationPlusKidsStage,
419:         redirect: (context, state) => _redirectNonKidsPathToMemorization(),
420:         builder: (context, state) {
421:           final stage = _parseKidsJourneyStage(state);
422:           if (stage == null || !_isValidSurahId(stage.surahId)) {
423:             return const PathSelectionPage();
424:           }
425:           return KidsGamifiedStagePage(
426:             stage: stage,
427:             surahName: state.uri.queryParameters['surahName'],
428:           );
429:         },
430:       ),
431:       GoRoute(
432:         parentNavigatorKey: _rootNavigatorKey,
433:         path: AppRoutes.memorizationPlusKidsCompletion,
434:         redirect: (context, state) => _redirectNonKidsPathToMemorization(),
435:         builder: (context, state) {
436:           final extra = state.extra as Map<String, dynamic>?;
437:           final surahId =
438:               extra?['surahId'] as int? ??
439:               int.tryParse(state.uri.queryParameters['surahId'] ?? '');
440:           final completedAyahNumber =
441:               extra?['completedAyahNumber'] as int? ??
442:               int.tryParse(
443:                 state.uri.queryParameters['completedAyahNumber'] ?? '',
444:               );
445:           if (!_isValidSurahId(surahId) ||
446:               completedAyahNumber == null ||
447:               completedAyahNumber < 1) {
448:             return const PathSelectionPage();
449:           }
450:           final starsEarned =
451:               extra?['starsEarned'] as int? ??
452:               int.tryParse(state.uri.queryParameters['starsEarned'] ?? '') ??
453:               1;
454:           final gemsEarned =
455:               extra?['gemsEarned'] as int? ??
456:               int.tryParse(state.uri.queryParameters['gemsEarned'] ?? '') ??
457:               0;
458:           return KidsGamifiedCompletionPage(
459:             surahId: surahId!,
460:             completedAyahNumber: completedAyahNumber,
461:             starsEarned: starsEarned,
462:             gemsEarned: gemsEarned,
463:           );
464:         },
465:       ),
466:       GoRoute(
467:         parentNavigatorKey: _rootNavigatorKey,
468:         path: AppRoutes.parentDashboard,
469:         builder: (context, state) {
470:           final surahId =
471:               int.tryParse(state.uri.queryParameters['surahId'] ?? '') ?? 1;
472:           return ParentDashboardPage(
473:             surahId: _isValidSurahId(surahId) ? surahId : 1,
474:           );
475:         },
476:       ),
477:       GoRoute(
478:         parentNavigatorKey: _rootNavigatorKey,
479:         path: AppRoutes.memorizationPlusCustomPlan,
480:         redirect: (context, state) => _redirectKidsPathToKidsHome(),
481:         builder: (context, state) => const CustomPlanSetupPage(),
482:       ),
483:       GoRoute(
484:         parentNavigatorKey: _rootNavigatorKey,
485:         path: AppRoutes.memorizationPlusQuiz,
486:         builder: (context, state) {
487:           final extra = state.extra as Map<String, dynamic>?;
488:           final surahId =
489:               extra?['surahId'] as int? ??
490:               int.tryParse(state.uri.queryParameters['surahId'] ?? '');
491:           if (!_isValidSurahId(surahId)) {
492:             return const PathSelectionPage();
493:           }
494:           final rawAyahNumbers = extra?['ayahNumbers'];
495:           final ayahNumbers = rawAyahNumbers is List<int>
496:               ? rawAyahNumbers
497:               : rawAyahNumbers is List
498:               ? rawAyahNumbers.whereType<int>().toList()
499:               : _parseAyahNumbers(state.uri.queryParameters['ayahNumbers']);
500:           return QuizPage(surahId: surahId!, ayahNumbers: ayahNumbers);
501:         },
502:       ),
503: 
504:       // ── Shell (bottom nav) ─────────────────────────────────────────────────
505:       // UX-4 FIX: StatefulShellRoute.indexedStack preserves each tab's
506:       // Navigator stack independently, so scroll position and BLoC state
507:       // are NOT destroyed when the user switches between bottom-nav tabs.
508:       StatefulShellRoute.indexedStack(
509:         builder: (context, state, navigationShell) =>
510:             AppShell(navigationShell: navigationShell),
511:         branches: [
512:           StatefulShellBranch(
513:             routes: [
514:               GoRoute(
515:                 path: AppRoutes.home,
516:                 pageBuilder: (_, _) =>
517:                     const NoTransitionPage(child: HomePage()),
518:               ),
519:             ],
520:           ),
521:           StatefulShellBranch(
522:             routes: [
523:               GoRoute(
524:                 path: AppRoutes.quran,
525:                 pageBuilder: (_, _) =>
526:                     const NoTransitionPage(child: QuranPage()),
527:               ),
528:             ],
529:           ),
530:           StatefulShellBranch(
531:             routes: [
532:               GoRoute(
533:                 path: AppRoutes.hifz,
534:                 redirect: (context, state) async {
535:                   try {
536:                     final repo = getIt<MemorizationPlusRepository>();
537:                     final profileResult = await repo.getMemorizationProfile();
538:                     final profile = profileResult.fold((_) => null, (p) => p);
539:                     if (profile?.isChild == true) {
540:                       return AppRoutes.memorizationPlusKidsHome;
541:                     }
542:                     if (profile?.hasSelectedPath == true) return null;
543: 
544:                     final prefs = getIt<SharedPreferences>();
545:                     final legacyPath = prefs.getString(
546:                       AppConstants.kHifzPathMode,
547:                     );
548:                     if (legacyPath != null && legacyPath.isNotEmpty) {
549:                       return null;
550:                     }
551:                     return AppRoutes.memorizationPlus;
552:                   } catch (_) {
553:                     return null;
554:                   }
555:                 },
556:                 pageBuilder: (_, _) =>
557:                     const NoTransitionPage(child: HifzPage()),
558:               ),
559:             ],
560:           ),
561:           StatefulShellBranch(
562:             routes: [
563:               GoRoute(
564:                 path: AppRoutes.azkar,
565:                 pageBuilder: (_, _) =>
566:                     const NoTransitionPage(child: AzkarPage()),
567:               ),
568:             ],
569:           ),
570:           StatefulShellBranch(
571:             routes: [
572:               GoRoute(
573:                 path: AppRoutes.progress,
574:                 pageBuilder: (_, _) =>
575:                     const NoTransitionPage(child: ProgressPage()),
576:               ),
577:             ],
578:           ),
579:         ],
580:       ),
581:     ],
582:   );
583: 
584:   const AppRouter._();
585: 
586:   static bool _isValidSurahId(int? surahId) =>
587:       surahId != null && surahId >= 1 && surahId <= 114;
588: 
589:   static Future<MemorizationProfile?> _readMemorizationProfile() async {
590:     try {
591:       final repo = getIt<MemorizationPlusRepository>();
592:       final profileResult = await repo.getMemorizationProfile();
593:       return profileResult.fold((_) => null, (profile) => profile);
594:     } catch (_) {
595:       return null;
596:     }
597:   }
598: 
599:   static Future<bool> _isKidsPathSelected() async {
600:     final profile = await _readMemorizationProfile();
601:     return profile?.isChild == true;
602:   }
603: 
604:   static Future<String?> _redirectKidsPathToKidsHome() async {
605:     return await _isKidsPathSelected()
606:         ? AppRoutes.memorizationPlusKidsHome
607:         : null;
608:   }
609: 
610:   static Future<String?> _redirectNonKidsPathToMemorization() async {
611:     final profile = await _readMemorizationProfile();
612:     if (profile == null || profile.isChild) return null;
613:     return AppRoutes.memorizationPlus;
614:   }
615: 
616:   static String _kidsListenLocation({
617:     required int surahId,
618:     required int ayahNumber,
619:   }) {
620:     final query = Uri(
621:       queryParameters: {'surahId': '$surahId', 'ayahNumber': '$ayahNumber'},
622:     ).query;
623:     return '${AppRoutes.memorizationPlusKids}?$query';
624:   }
625: 
626:   static KidsJourneyStage? _parseKidsJourneyStage(GoRouterState state) {
627:     final extra = state.extra;
628:     if (extra is KidsJourneyStage) return extra;
629: 
630:     final extraMap = extra is Map<String, dynamic> ? extra : null;
631:     final query = state.uri.queryParameters;
632:     final surahId =
633:         extraMap?['surahId'] as int? ?? int.tryParse(query['surahId'] ?? '');
634:     final stageNumber =
635:         extraMap?['stageNumber'] as int? ??
636:         int.tryParse(query['stageNumber'] ?? '');
637:     final startAyah =
638:         extraMap?['startAyah'] as int? ??
639:         int.tryParse(query['startAyah'] ?? '');
640:     final endAyah =
641:         extraMap?['endAyah'] as int? ?? int.tryParse(query['endAyah'] ?? '');
642: 
643:     if (!_isValidSurahId(surahId) ||
644:         stageNumber == null ||
645:         stageNumber < 1 ||
646:         startAyah == null ||
647:         startAyah < 1 ||
648:         endAyah == null ||
649:         endAyah < startAyah) {
650:       return null;
651:     }
652: 
653:     final completedAyahs = extraMap?['completedAyahs'] is List<int>
654:         ? extraMap!['completedAyahs'] as List<int>
655:         : _parseAyahNumbers(query['completedAyahs']) ?? const <int>[];
656:     final status = _parseKidsJourneyStageStatus(
657:       extraMap?['status'] as String? ?? query['status'],
658:     );
659: 
660:     return KidsJourneyStage(
661:       stageNumber: stageNumber,
662:       surahId: surahId!,
663:       startAyah: startAyah,
664:       endAyah: endAyah,
665:       completedAyahs: completedAyahs,
666:       status: status,
667:     );
668:   }
669: 
670:   static KidsJourneyStageStatus _parseKidsJourneyStageStatus(String? value) {
671:     if (value == null || value.isEmpty) return KidsJourneyStageStatus.current;
672:     for (final status in KidsJourneyStageStatus.values) {
673:       if (status.name == value) return status;
674:     }
675:     return KidsJourneyStageStatus.current;
676:   }
677: 
678:   static List<int>? _parseAyahNumbers(String? value) {
679:     if (value == null || value.trim().isEmpty) return null;
680:     final numbers = value
681:         .split(',')
682:         .map((item) => int.tryParse(item.trim()))
683:         .whereType<int>()
684:         .where((number) => number > 0)
685:         .toList();
686:     return numbers.isEmpty ? null : numbers;
687:   }
688: }

(End of file - total 688 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 7.7s)

_Thinking:_

Now I have a good understanding of the routing. Let me explore the home page, hifz, and memorization_plus features.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home</path>
<type>directory</type>
<entries>
data/
domain/
presentation/

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation</path>
<type>directory</type>
<entries>
cubits/
pages/
widgets/

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation</path>
<type>directory</type>
<entries>
cubits/
pages/
theme/
widgets/

(4 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\di\\injection.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\di\injection.dart</path>
<type>file</type>
<content>
1: import 'package:get_it/get_it.dart';
2: import 'package:shared_preferences/shared_preferences.dart';
3: import 'package:isar/isar.dart';
4: import 'package:path_provider/path_provider.dart';
5: 
6: import '../services/audio_cache_service.dart';
7: import '../services/app_session_service.dart';
8: import '../services/notification_service.dart';
9: import '../services/streak_service.dart';
10: import '../services/xp_service.dart';
11: import '../services/subscription_service.dart';
12: import '../services/achievement_service.dart';
13: import '../theme/theme_cubit.dart';
14: import '../l10n/locale_cubit.dart';
15: import '../../features/quran/data/datasources/quran_local_datasource.dart';
16: import '../../features/quran/data/datasources/bookmark_service.dart';
17: import '../../features/quran/data/repositories/quran_repository_impl.dart';
18: import '../../features/quran/domain/repositories/quran_repository.dart';
19: import '../../features/quran/domain/usecases/get_surahs_usecase.dart';
20: // GetSurahDetailUsecase is defined in get_surahs_usecase.dart
21: import '../../features/quran/presentation/cubits/surah_list_cubit.dart';
22: import '../../features/quran/presentation/cubits/surah_detail_cubit.dart';
23: import '../../features/quran/presentation/cubits/quran_page_cubit.dart';
24: import '../../features/quran/presentation/cubits/search_quran_cubit.dart';
25: import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
26: import '../../features/hifz/data/datasources/isar_hifz_local_datasource_impl.dart';
27: import '../../features/hifz/data/models/isar_ayah_progress.dart';
28: import '../../features/hifz/data/repositories/hifz_repository_impl.dart';
29: import '../../features/hifz/domain/repositories/hifz_repository.dart';
30: import '../../features/hifz/domain/usecases/get_hifz_progress_usecase.dart';
31: import '../../features/hifz/domain/usecases/save_ayah_progress_usecase.dart';
32: import '../../features/hifz/presentation/cubits/hifz_cubit.dart';
33: import '../../features/hifz/presentation/cubits/hifz_session_cubit.dart';
34: import '../../features/azkar/data/datasources/azkar_local_datasource.dart';
35: import '../../features/azkar/data/repositories/azkar_repository_impl.dart';
36: import '../../features/azkar/domain/repositories/azkar_repository.dart';
37: import '../../features/azkar/domain/usecases/get_azkar_usecase.dart';
38: import '../../features/azkar/presentation/cubits/azkar_cubit.dart';
39: import '../../features/progress/data/datasources/progress_local_datasource.dart';
40: import '../../features/progress/data/repositories/progress_repository_impl.dart';
41: import '../../features/progress/domain/repositories/progress_repository.dart';
42: import '../../features/progress/domain/usecases/get_progress_usecase.dart';
43: import '../../features/progress/domain/usecases/save_read_page_usecase.dart';
44: import '../../features/progress/presentation/cubits/progress_cubit.dart';
45: import '../../features/home/presentation/cubits/home_cubit.dart';
46: import '../../features/home/domain/usecases/get_activity_heatmap_usecase.dart';
47: import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
48: import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
49: import '../../features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
50: import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
51: import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
52: import '../../features/memorization_plus/presentation/cubits/daily_plan_cubit.dart';
53: import '../../features/memorization_plus/presentation/cubits/guardian_linking_cubit.dart';
54: import '../../features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
55: import '../../features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
56: import '../../features/memorization_plus/presentation/cubits/parent_dashboard_cubit.dart';
57: import '../../features/memorization_plus/presentation/cubits/track_selection_cubit.dart';
58: import '../../features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
59: import '../../features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart';
60: import '../../features/memorization_plus/presentation/cubits/quiz_cubit.dart';
61: import '../../features/settings/presentation/cubits/profile_cubit.dart';
62: import '../../features/settings/presentation/cubits/settings_cubit.dart';
63: import '../../features/settings/domain/repositories/settings_repository.dart';
64: import '../../features/settings/data/repositories/settings_repository_impl.dart';
65: import '../../features/streak/data/models/streak_isar.dart';
66: import '../../features/streak/data/models/daily_activity_isar.dart';
67: import '../../features/streak/presentation/cubits/streak_cubit.dart';
68: import '../../features/xp/data/models/xp_isar.dart';
69: import '../../features/auth/domain/repositories/auth_repository.dart';
70: import '../../features/auth/data/repositories/auth_repository_impl.dart';
71: import '../../features/auth/presentation/cubits/auth_cubit.dart';
72: 
73: final GetIt getIt = GetIt.instance;
74: 
75: Future<void> configureDependencies() async {
76:   // ─── External ───────────────────────────────────────────────────────────────
77:   final sharedPrefs = await SharedPreferences.getInstance();
78:   getIt.registerSingleton<SharedPreferences>(sharedPrefs);
79: 
80:   final dir = await getApplicationDocumentsDirectory();
81:   final isar = await Isar.open([
82:     IsarAyahProgressSchema,
83:     IsarAyahReviewRecordSchema,
84:     StreakIsarSchema,
85:     XpIsarSchema,
86:     DailyActivityIsarSchema, // For yearly activity heatmap
87:   ], directory: dir.path);
88:   getIt.registerSingleton<Isar>(isar);
89: 
90:   // Migrate old SharedPreferences Hifz data to Isar if needed
91:   final hifzDatasource = IsarHifzLocalDatasourceImpl(isar, sharedPrefs);
92:   await hifzDatasource.migrateFromSharedPreferencesIfNeeded();
93:   getIt.registerLazySingleton<HifzLocalDatasource>(() => hifzDatasource);
94: 
95:   final memorizationPlusDatasource = MemorizationPlusLocalDatasourceImpl(
96:     sharedPrefs,
97:     isar: isar,
98:   );
99:   await memorizationPlusDatasource.migrateReviewRecordsToIsarIfNeeded();
100: 
101:   // ─── Core ───────────────────────────────────────────────────────────────────
102:   getIt.registerLazySingleton<ThemeCubit>(
103:     () => ThemeCubit(getIt<SharedPreferences>()),
104:   );
105:   getIt.registerLazySingleton<LocaleCubit>(
106:     () => LocaleCubit(getIt<SharedPreferences>()),
107:   );
108:   getIt.registerLazySingleton<ProfileCubit>(
109:     () => ProfileCubit(getIt<SharedPreferences>()),
110:   );
111:   getIt.registerFactory<SettingsCubit>(
112:     () => SettingsCubit(
113:       getIt<MemorizationPlusRepository>(),
114:       getIt<SharedPreferences>(),
115:     ),
116:   );
117:   getIt.registerSingleton<AudioCacheService>(AudioCacheService.instance);
118:   getIt.registerSingleton<AppSessionService>(
119:     AppSessionService(getIt<SharedPreferences>()),
120:   );
121:   getIt.registerLazySingleton<TaliaNotificationService>(
122:     TaliaNotificationService.new,
123:   );
124: 
125:   // ─── New Core Services ──────────────────────────────────────────────────────
126:   // ─── Datasources ────────────────────────────────────────────────────────────
127:   getIt.registerLazySingleton<ProgressLocalDatasource>(
128:     () => ProgressLocalDatasourceImpl(getIt<SharedPreferences>()),
129:   );
130:   getIt.registerLazySingleton<MemorizationPlusLocalDatasource>(
131:     () => memorizationPlusDatasource,
132:   );
133:   getIt.registerLazySingleton<QuranLocalDatasource>(
134:     () => QuranLocalDatasourceImpl(),
135:   );
136:   getIt.registerLazySingleton<SettingsRepository>(
137:     () => SettingsRepositoryImpl(getIt<SharedPreferences>()),
138:   );
139:   getIt.registerLazySingleton<BookmarkService>(
140:     () => BookmarkService(getIt<SharedPreferences>()),
141:   );
142:   getIt.registerLazySingleton<AzkarLocalDatasource>(
143:     () => AzkarLocalDatasourceImpl(),
144:   );
145: 
146:   // ─── Core Services ──────────────────────────────────────────────────────────
147:   getIt.registerSingleton<StreakService>(StreakService(getIt<Isar>()));
148:   getIt.registerSingleton<XpService>(XpService(getIt<Isar>()));
149:   getIt.registerSingleton<SubscriptionService>(SubscriptionService());
150:   getIt.registerSingleton<AchievementService>(
151:     AchievementService(
152:       getIt<SharedPreferences>(),
153:       hifzDatasource,
154:       getIt<MemorizationPlusLocalDatasource>(),
155:       getIt<QuranLocalDatasource>(),
156:     ),
157:   );
158: 
159:   // ─── Repositories ───────────────────────────────────────────────────────────
160:   getIt.registerLazySingleton<ProgressRepository>(
161:     () => ProgressRepositoryImpl(
162:       getIt<ProgressLocalDatasource>(),
163:       getIt<HifzLocalDatasource>(),
164:       getIt<MemorizationPlusLocalDatasource>(),
165:       getIt<QuranLocalDatasource>(),
166:     ),
167:   );
168:   getIt.registerLazySingleton<QuranRepository>(
169:     () => QuranRepositoryImpl(getIt<QuranLocalDatasource>()),
170:   );
171:   getIt.registerLazySingleton<HifzRepository>(
172:     () => HifzRepositoryImpl(
173:       getIt<HifzLocalDatasource>(),
174:       getIt<QuranLocalDatasource>(),
175:     ),
176:   );
177:   getIt.registerLazySingleton<AzkarRepository>(
178:     () => AzkarRepositoryImpl(getIt<AzkarLocalDatasource>()),
179:   );
180:   getIt.registerLazySingleton<MemorizationPlusRepository>(
181:     () => MemorizationPlusRepositoryImpl(
182:       getIt<MemorizationPlusLocalDatasource>(),
183:       getIt<QuranRepository>(),
184:     ),
185:   );
186:   getIt.registerLazySingleton<AuthRepository>(
187:     () => AuthRepositoryImpl(getIt<Isar>()),
188:   );
189: 
190:   // ─── Usecases ───────────────────────────────────────────────────────────────
191:   getIt.registerLazySingleton<GetProgressUsecase>(
192:     () => GetProgressUsecase(getIt<ProgressRepository>()),
193:   );
194:   getIt.registerLazySingleton<SaveReadPageUsecase>(
195:     () => SaveReadPageUsecase(getIt<ProgressRepository>()),
196:   );
197:   getIt.registerLazySingleton<GetSurahsUsecase>(
198:     () => GetSurahsUsecase(getIt<QuranRepository>()),
199:   );
200:   getIt.registerLazySingleton<GetSurahDetailUsecase>(
201:     () => GetSurahDetailUsecase(getIt<QuranRepository>()),
202:   );
203:   getIt.registerLazySingleton<GetHifzProgressUsecase>(
204:     () => GetHifzProgressUsecase(getIt<HifzRepository>()),
205:   );
206:   getIt.registerLazySingleton<GetProgressForSurahUsecase>(
207:     () => GetProgressForSurahUsecase(getIt<HifzRepository>()),
208:   );
209:   getIt.registerLazySingleton<SaveAyahProgressUsecase>(
210:     () => SaveAyahProgressUsecase(getIt<HifzRepository>()),
211:   );
212:   getIt.registerLazySingleton<GetHifzPathUsecase>(
213:     () => GetHifzPathUsecase(getIt<HifzRepository>()),
214:   );
215:   getIt.registerLazySingleton<SaveHifzPathUsecase>(
216:     () => SaveHifzPathUsecase(getIt<HifzRepository>()),
217:   );
218:   getIt.registerLazySingleton<GenerateHifzSegmentsUsecase>(
219:     () => const GenerateHifzSegmentsUsecase(),
220:   );
221:   getIt.registerLazySingleton<CheckNextAyahUnlockUsecase>(
222:     () => const CheckNextAyahUnlockUsecase(),
223:   );
224:   getIt.registerLazySingleton<GetNextRequiredReviewCheckpointUsecase>(
225:     () => const GetNextRequiredReviewCheckpointUsecase(),
226:   );
227:   getIt.registerLazySingleton<GetPassedCheckpointKeysUsecase>(
228:     () => GetPassedCheckpointKeysUsecase(getIt<HifzRepository>()),
229:   );
230:   getIt.registerLazySingleton<MarkCheckpointReviewPassedUsecase>(
231:     () => MarkCheckpointReviewPassedUsecase(getIt<HifzRepository>()),
232:   );
233:   getIt.registerLazySingleton<GetAzkarUsecase>(
234:     () => GetAzkarUsecase(getIt<AzkarRepository>()),
235:   );
236:   getIt.registerLazySingleton<GenerateDailyPlanUsecase>(
237:     () => GenerateDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
238:   );
239:   getIt.registerLazySingleton<EvaluateMemorizationUsecase>(
240:     () => EvaluateMemorizationUsecase(getIt<MemorizationPlusRepository>()),
241:   );
242:   getIt.registerLazySingleton<MarkAyahMemorizedUsecase>(
243:     () => MarkAyahMemorizedUsecase(getIt<MemorizationPlusRepository>()),
244:   );
245:   getIt.registerLazySingleton<GetCachedDailyPlanUsecase>(
246:     () => GetCachedDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
247:   );
248:   getIt.registerLazySingleton<GetKidsProgressUsecase>(
249:     () => GetKidsProgressUsecase(getIt<MemorizationPlusRepository>()),
250:   );
251:   getIt.registerLazySingleton<AwardKidsPointsUsecase>(
252:     () => AwardKidsPointsUsecase(getIt<MemorizationPlusRepository>()),
253:   );
254:   getIt.registerLazySingleton<GetQuranPageUsecase>(
255:     () => GetQuranPageUsecase(getIt<QuranRepository>()),
256:   );
257:   getIt.registerLazySingleton<GetCustomPlanUsecase>(
258:     () => GetCustomPlanUsecase(getIt<MemorizationPlusRepository>()),
259:   );
260:   getIt.registerLazySingleton<SaveDailyPlanUsecase>(
261:     () => SaveDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
262:   );
263:   getIt.registerLazySingleton<GetKidsJourneyUsecase>(
264:     () => GetKidsJourneyUsecase(getIt<MemorizationPlusRepository>()),
265:   );
266:   getIt.registerLazySingleton<SaveKidsSessionLogUsecase>(
267:     () => SaveKidsSessionLogUsecase(getIt<MemorizationPlusRepository>()),
268:   );
269:   getIt.registerLazySingleton<GetParentDashboardUsecase>(
270:     () => GetParentDashboardUsecase(getIt<MemorizationPlusRepository>()),
271:   );
272:   getIt.registerLazySingleton<ParentAccessUsecase>(
273:     () => ParentAccessUsecase(getIt<MemorizationPlusRepository>()),
274:   );
275:   getIt.registerLazySingleton<ParentRemoteLinkUsecase>(
276:     () => ParentRemoteLinkUsecase(getIt<MemorizationPlusRepository>()),
277:   );
278:   getIt.registerLazySingleton<GetMemorizationProfileUsecase>(
279:     () => GetMemorizationProfileUsecase(getIt<MemorizationPlusRepository>()),
280:   );
281:   getIt.registerLazySingleton<SelectMemorizationPathUsecase>(
282:     () => SelectMemorizationPathUsecase(getIt<MemorizationPlusRepository>()),
283:   );
284:   getIt.registerLazySingleton<ContinueWithoutGuardianUsecase>(
285:     () => ContinueWithoutGuardianUsecase(getIt<MemorizationPlusRepository>()),
286:   );
287:   getIt.registerLazySingleton<CreateGuardianPairingSessionUsecase>(
288:     () => CreateGuardianPairingSessionUsecase(
289:       getIt<MemorizationPlusRepository>(),
290:     ),
291:   );
292:   getIt.registerLazySingleton<AcceptGuardianPairingCodeUsecase>(
293:     () => AcceptGuardianPairingCodeUsecase(getIt<MemorizationPlusRepository>()),
294:   );
295:   getIt.registerLazySingleton<RefreshPairingSessionUsecase>(
296:     () => RefreshPairingSessionUsecase(getIt<MemorizationPlusRepository>()),
297:   );
298:   getIt.registerLazySingleton<UnlinkGuardianUsecase>(
299:     () => UnlinkGuardianUsecase(getIt<MemorizationPlusRepository>()),
300:   );
301:   getIt.registerLazySingleton<SetParentGuardianModeUsecase>(
302:     () => SetParentGuardianModeUsecase(getIt<MemorizationPlusRepository>()),
303:   );
304:   getIt.registerLazySingleton<RefreshChildGuardianLinkUsecase>(
305:     () => RefreshChildGuardianLinkUsecase(getIt<MemorizationPlusRepository>()),
306:   );
307:   getIt.registerLazySingleton<ResetMemorizationIdentityUsecase>(
308:     () => ResetMemorizationIdentityUsecase(getIt<MemorizationPlusRepository>()),
309:   );
310:   getIt.registerLazySingleton<GetSmartMemorizationSettingsUsecase>(
311:     () => GetSmartMemorizationSettingsUsecase(
312:       getIt<MemorizationPlusRepository>(),
313:     ),
314:   );
315:   getIt.registerLazySingleton<SaveSmartMemorizationSettingsUsecase>(
316:     () => SaveSmartMemorizationSettingsUsecase(
317:       getIt<MemorizationPlusRepository>(),
318:     ),
319:   );
320: 
321:   // ─── Cubits ─────────────────────────────────────────────────────────────────
322:   getIt.registerFactory<ProgressCubit>(
323:     () => ProgressCubit(getIt<GetProgressUsecase>()),
324:   );
325:   getIt.registerFactory<SurahListCubit>(
326:     () => SurahListCubit(getIt<GetSurahsUsecase>()),
327:   );
328:   getIt.registerFactory<SurahDetailCubit>(
329:     () => SurahDetailCubit(getIt<GetSurahDetailUsecase>()),
330:   );
331:   getIt.registerFactory<QuranPageCubit>(
332:     () => QuranPageCubit(
333:       getIt<QuranRepository>(),
334:       getIt<SaveReadPageUsecase>(),
335:       getIt<StreakService>(),
336:     ),
337:   );
338:   getIt.registerFactory<SearchQuranCubit>(
339:     () => SearchQuranCubit(getIt<QuranRepository>()),
340:   );
341:   getIt.registerFactory<HifzCubit>(
342:     () => HifzCubit(
343:       getIt<GetSurahsUsecase>(),
344:       getIt<GetHifzProgressUsecase>(),
345:       getIt<GetHifzPathUsecase>(),
346:       getIt<SaveHifzPathUsecase>(),
347:       getIt<MemorizationPlusRepository>(),
348:     ),
349:   );
350:   getIt.registerFactory<HifzSessionCubit>(
351:     () => HifzSessionCubit(
352:       getIt<GetSurahsUsecase>(),
353:       getIt<GetSurahDetailUsecase>(),
354:       getIt<SaveAyahProgressUsecase>(),
355:       getIt<GetProgressForSurahUsecase>(),
356:       getIt<GetHifzProgressUsecase>(),
357:       getIt<GetHifzPathUsecase>(),
358:       getIt<GenerateHifzSegmentsUsecase>(),
359:       getIt<CheckNextAyahUnlockUsecase>(),
360:       getIt<GetNextRequiredReviewCheckpointUsecase>(),
361:       getIt<GetPassedCheckpointKeysUsecase>(),
362:       getIt<MarkCheckpointReviewPassedUsecase>(),
363:       getIt<SettingsRepository>(),
364:       getIt<StreakService>(),
365:       getIt<XpService>(),
366:       getIt<AchievementService>(),
367:     ),
368:   );
369:   getIt.registerFactory<AzkarCubit>(
370:     () => AzkarCubit(getIt<GetAzkarUsecase>(), getIt<SharedPreferences>()),
371:   );
372:   getIt.registerFactory<TrackSelectionCubit>(
373:     () => TrackSelectionCubit(getIt<MemorizationPlusRepository>()),
374:   );
375:   getIt.registerFactory<GuardianLinkingCubit>(
376:     () => GuardianLinkingCubit(getIt<MemorizationPlusRepository>()),
377:   );
378:   getIt.registerFactory<MemorizationIdentityCubit>(
379:     () => MemorizationIdentityCubit(
380:       repository: getIt<MemorizationPlusRepository>(),
381:     ),
382:   );
383:   getIt.registerFactory<DailyPlanCubit>(
384:     () => DailyPlanCubit(
385:       getIt<GenerateDailyPlanUsecase>(),
386:       getIt<GetCachedDailyPlanUsecase>(),
387:       getIt<EvaluateMemorizationUsecase>(),
388:       getIt<SaveDailyPlanUsecase>(),
389:       getIt<AchievementService>(),
390:       getIt<StreakService>(), // RISK-5 FIX
391:       getIt<XpService>(), // RISK-5 FIX
392:     ),
393:   );
394:   getIt.registerFactory<KidsModeCubit>(
395:     () => KidsModeCubit(
396:       getIt<GetKidsProgressUsecase>(),
397:       getIt<AwardKidsPointsUsecase>(),
398:       getIt<MarkAyahMemorizedUsecase>(),
399:       getIt<SaveKidsSessionLogUsecase>(),
400:       getIt<AchievementService>(),
401:       getIt<QuranRepository>(),
402:       getIt<StreakService>(), // RISK-5 FIX
403:       getIt<XpService>(), // RISK-5 FIX
404:     ),
405:   );
406:   getIt.registerFactory<CustomPlanCubit>(
407:     () => CustomPlanCubit(getIt<MemorizationPlusRepository>()),
408:   );
409:   getIt.registerFactory<KidsJourneyCubit>(
410:     () => KidsJourneyCubit(
411:       getIt<GetKidsJourneyUsecase>(),
412:       getIt<GetKidsProgressUsecase>(),
413:       getIt<ParentRemoteLinkUsecase>(),
414:       getIt<QuranRepository>(),
415:     ),
416:   );
417:   getIt.registerFactory<ParentDashboardCubit>(
418:     () => ParentDashboardCubit(
419:       getIt<GetParentDashboardUsecase>(),
420:       getIt<ParentAccessUsecase>(),
421:       getIt<ParentRemoteLinkUsecase>(),
422:     ),
423:   );
424:   getIt.registerFactory<QuizCubit>(
425:     () => QuizCubit(
426:       getIt<MemorizationPlusRepository>(),
427:       getIt<QuranRepository>(),
428:       getIt<AchievementService>(),
429:     ),
430:   );
431:   getIt.registerFactory<HomeCubit>(
432:     () => HomeCubit(
433:       getIt<GetProgressUsecase>(),
434:       getIt<GetHifzProgressUsecase>(),
435:       getIt<GetQuranPageUsecase>(),
436:       getIt<GetCustomPlanUsecase>(),
437:       getIt<MemorizationPlusRepository>(),
438:       getIt<AppSessionService>(),
439:       GetActivityHeatmapUsecase(getIt<Isar>()),
440:     ),
441:   );
442:   getIt.registerFactory<StreakCubit>(() => StreakCubit(getIt<StreakService>()));
443:   getIt.registerSingleton<AuthCubit>(AuthCubit(getIt<AuthRepository>()));
444: }

(End of file - total 444 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 12.3s)

_Thinking:_

Now let me look at the home and hifz feature presentation files.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\pages"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\pages</path>
<type>directory</type>
<entries>
home_page_widgets.dart
home_page.dart

(2 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\widgets"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\widgets</path>
<type>directory</type>
<entries>


(0 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\data"
}
```

**Error:**
```
File not found: D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\data
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\pages"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\pages</path>
<type>directory</type>
<entries>
hifz_page.dart
hifz_session_page.dart

(2 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 5.9s)

_Thinking:_

Now let me look at the home, hifz and key memorization plus pages and cubits in parallel.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\pages\\home_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\pages\home_page.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: import 'dart:ui';
3: 
4: import 'package:flutter/foundation.dart';
5: import 'package:flutter/material.dart';
6: import 'package:flutter_animate/flutter_animate.dart';
7: import 'package:flutter_bloc/flutter_bloc.dart';
8: import 'package:go_router/go_router.dart';
9: import 'package:shared_preferences/shared_preferences.dart';
10: import '../../../../core/constants/app_spacing.dart';
11: import '../../../../core/constants/xp_constants.dart';
12: import '../../../../core/di/injection.dart';
13: import '../../../../core/extensions/context_extensions.dart';
14: import '../../../../core/l10n/localization_helpers.dart';
15: import '../../../../core/services/xp_service.dart';
16: import '../../../../core/theme/app_colors.dart';
17: import '../../../../core/theme/app_typography.dart';
18: import '../../../../core/theme/theme_cubit.dart';
19: import '../../../../core/widgets/activity_heatmap.dart';
20: import '../../../../core/widgets/state_widgets.dart';
21: import '../../../../core/widgets/section_header.dart';
22: import '../../../../core/router/app_router.dart';
23: import '../../../../core/services/achievement_service.dart';
24: import '../../../../core/services/app_session_service.dart';
25: import '../../../auth/presentation/cubits/auth_cubit.dart';
26: import '../../../progress/domain/entities/progress_entities.dart';
27: import '../../../memorization_plus/domain/entities/memorization_entities.dart';
28: import '../../../settings/presentation/cubits/profile_cubit.dart';
29: import '../../../streak/presentation/cubits/streak_cubit.dart';
30: import '../cubits/home_cubit.dart';
31: part 'home_page_widgets.dart';
32: 
33: class HomePage extends StatelessWidget {
34:   const HomePage({super.key});
35: 
36:   @override
37:   Widget build(BuildContext context) {
38:     return MultiBlocProvider(
39:       providers: [
40:         BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
41:         BlocProvider(create: (_) => getIt<StreakCubit>()..loadStreak()),
42:       ],
43:       child: BlocBuilder<ThemeCubit, ThemeMode>(
44:         builder: (context, _) => const _HomeView(),
45:       ),
46:     );
47:   }
48: }
49: 
50: class _HomeView extends StatelessWidget {
51:   const _HomeView();
52: 
53:   @override
54:   Widget build(BuildContext context) {
55:     final isDark = context.isDark;
56: 
57:     return Scaffold(
58:       backgroundColor: isDark
59:           ? AppColors.darkBackground
60:           : AppColors.lightBackground,
61:       body: BlocBuilder<HomeCubit, HomeState>(
62:         builder: (context, state) {
63:           if (state is HomeLoading) {
64:             return const Center(child: LoadingWidget());
65:           }
66:           if (state is HomeError) {
67:             return ErrorStateWidget(
68:               message: state.message,
69:               onRetry: () => context.read<HomeCubit>().load(),
70:             );
71:           }
72:           if (state is HomeLoaded) {
73:             return _HomeContent(state: state, isDark: isDark);
74:           }
75:           return const SizedBox.shrink();
76:         },
77:       ),
78:     );
79:   }
80: }
81: 
82: class _HomeContent extends StatelessWidget {
83:   const _HomeContent({required this.state, required this.isDark});
84:   final HomeLoaded state;
85:   final bool isDark;
86: 
87:   @override
88:   Widget build(BuildContext context) {
89:     return CustomScrollView(
90:       slivers: [
91:         // ─── Hero Header ─────────────────────────────────────────────────────
92:         SliverToBoxAdapter(
93:           child: _HeroHeader(state: state, isDark: isDark),
94:         ),
95: 
96:         // ─── Streak & XP Row ─────────────────────────────────────────────────
97:         SliverToBoxAdapter(
98:           child: Padding(
99:             padding: const EdgeInsets.fromLTRB(
100:               AppSpacing.pagePadding,
101:               AppSpacing.lg,
102:               AppSpacing.pagePadding,
103:               0,
104:             ),
105:             child: _StreakXpRow(isDark: isDark),
106:           ),
107:         ),
108: 
109:         // ─── Sign-In Nudge Banner ───────────────────────────────────────────
110:         SliverToBoxAdapter(child: _SignInNudgeBanner(isDark: isDark)),
111: 
112:         SliverToBoxAdapter(child: _StartHereStrip(isDark: isDark)),
113: 
114:         if (state.lastRestorableLocation != null)
115:           SliverToBoxAdapter(
116:             child: Padding(
117:               padding: const EdgeInsets.fromLTRB(
118:                 AppSpacing.pagePadding,
119:                 AppSpacing.md,
120:                 AppSpacing.pagePadding,
121:                 0,
122:               ),
123:               child: _ResumeSessionCard(
124:                 location: state.lastRestorableLocation!,
125:                 isDark: isDark,
126:               ),
127:             ),
128:           )
129:         // Only show the "Next Best Action" card when there is no active
130:         // restorable session. Showing both at once is redundant since both
131:         // can point to the same memorization feature.
132:         else
133:           SliverToBoxAdapter(
134:             child: Padding(
135:               padding: const EdgeInsets.fromLTRB(
136:                 AppSpacing.pagePadding,
137:                 AppSpacing.md,
138:                 AppSpacing.pagePadding,
139:                 0,
140:               ),
141:               child: _NextBestActionCard(state: state, isDark: isDark),
142:             ),
143:           ),
144: 
145:         // ─── Daily Wird Card ────────────────────────────────────────────────
146:         SliverToBoxAdapter(
147:           child: Padding(
148:             padding: const EdgeInsets.fromLTRB(
149:               AppSpacing.pagePadding,
150:               AppSpacing.sectionGap,
151:               AppSpacing.pagePadding,
152:               0,
153:             ),
154:             child: _DailyWirdCard(state: state, isDark: isDark),
155:           ),
156:         ),
157: 
158:         // ─── Progress Section ────────────────────────────────────────────────
159:         SliverToBoxAdapter(
160:           child: Padding(
161:             padding: const EdgeInsets.fromLTRB(
162:               AppSpacing.pagePadding,
163:               AppSpacing.lg,
164:               AppSpacing.pagePadding,
165:               AppSpacing.sm,
166:             ),
167:             child: SectionHeader(
168:               title: context.l10n.overallProgress,
169:               padding: EdgeInsets.zero,
170:               action: GestureDetector(
171:                 onTap: () => context.go('/progress'),
172:                 child: Text(
173:                   context.l10n.viewAll,
174:                   style: AppTypography.labelMedium.copyWith(
175:                     color: isDark ? AppColors.primaryLight : AppColors.primary,
176:                   ),
177:                 ),
178:               ),
179:             ),
180:           ),
181:         ),
182: 
183:         SliverToBoxAdapter(
184:           child: Padding(
185:             padding: const EdgeInsets.symmetric(
186:               horizontal: AppSpacing.pagePadding,
187:             ),
188:             child: _ProgressSection(progress: state.progress, isDark: isDark),
189:           ),
190:         ),
191: 
192:         // ─── Azkar Shortcut ──────────────────────────────────────────────────
193:         SliverToBoxAdapter(
194:           child: Padding(
195:             padding: const EdgeInsets.fromLTRB(
196:               AppSpacing.pagePadding,
197:               AppSpacing.lg,
198:               AppSpacing.pagePadding,
199:               0,
200:             ),
201:             child: _AzkarShortcutRow(isDark: isDark),
202:           ),
203:         ),
204: 
205:         // ─── Active Custom Plan Card OR MemorizationPlus Card ────────────────
206:         if (state.customPlan != null)
207:           SliverToBoxAdapter(
208:             child: Padding(
209:               padding: const EdgeInsets.fromLTRB(
210:                 AppSpacing.pagePadding,
211:                 AppSpacing.lg,
212:                 AppSpacing.pagePadding,
213:                 0,
214:               ),
215:               child: _ActiveCustomPlanCard(
216:                 plan: state.customPlan!,
217:                 isDark: isDark,
218:               ),
219:             ),
220:           )
221:         else
222:           SliverToBoxAdapter(
223:             child: Padding(
224:               padding: const EdgeInsets.fromLTRB(
225:                 AppSpacing.pagePadding,
226:                 AppSpacing.lg,
227:                 AppSpacing.pagePadding,
228:                 0,
229:               ),
230:               child: _MemorizationPlusCard(isDark: isDark),
231:             ),
232:           ),
233: 
234:         // ─── Parent Dashboard Shortcut (If Parent Mode / Kids Track) ──────────
235:         if (state.selectedTrack == MemorizationTrack.kids || state.isParentMode)
236:           SliverToBoxAdapter(
237:             child: Padding(
238:               padding: const EdgeInsets.fromLTRB(
239:                 AppSpacing.pagePadding,
240:                 AppSpacing.lg,
241:                 AppSpacing.pagePadding,
242:                 0,
243:               ),
244:               child: _ParentDashboardShortcutCard(isDark: isDark),
245:             ),
246:           ),
247: 
248:         // ─── Activity Heatmap ─────────────────────────────────────────────────
249:         SliverToBoxAdapter(
250:           child: Padding(
251:             padding: const EdgeInsets.fromLTRB(
252:               AppSpacing.pagePadding,
253:               AppSpacing.sectionGap,
254:               AppSpacing.pagePadding,
255:               0,
256:             ),
257:             child: ActivityHeatmap(
258:               activityCountsByDay: state.activityCountsByDay,
259:               startDate: state.activityStartDate,
260:             ),
261:           ),
262:         ),
263: 
264:         // ─── Debug Certificate Preview (Debug Mode Only) ──────────────────
265:         if (kDebugMode)
266:           SliverToBoxAdapter(
267:             child: Padding(
268:               padding: const EdgeInsets.fromLTRB(
269:                 AppSpacing.pagePadding,
270:                 AppSpacing.lg,
271:                 AppSpacing.pagePadding,
272:                 0,
273:               ),
274:               child: _DebugCertificatePreview(isDark: isDark),
275:             ),
276:           ),
277: 
278:         // ─── Bottom padding (above nav bar) ──────────────────────────────────
279:         const SliverToBoxAdapter(child: SizedBox(height: 120)),
280:       ],
281:     );
282:   }
283: }

(End of file - total 283 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 6.2s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\pages\\home_page_widgets.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\pages\home_page_widgets.dart</path>
<type>file</type>
<content>
1: part of 'home_page.dart';
2: 
3: // ─── Hero Header ──────────────────────────────────────────────────────────────
4: 
5: class _HeroHeader extends StatelessWidget {
6:   const _HeroHeader({required this.state, required this.isDark});
7:   final HomeLoaded state;
8:   final bool isDark;
9: 
10:   String _greetingText(BuildContext ctx) => switch (state.greeting) {
11:     'morning' => ctx.l10n.greetingMorning,
12:     'afternoon' => ctx.l10n.greetingAfternoon,
13:     'evening' => ctx.l10n.greetingEvening,
14:     _ => ctx.l10n.greetingNight,
15:   };
16: 
17:   IconData _greetingIcon() => switch (state.greeting) {
18:     'morning' => Icons.wb_sunny_rounded,
19:     'afternoon' => Icons.wb_cloudy_rounded,
20:     'evening' => Icons.wb_twilight_rounded,
21:     _ => Icons.nightlight_round,
22:   };
23: 
24:   @override
25:   Widget build(BuildContext context) {
26:     final bottomColor = isDark
27:         ? AppColors.darkBackground
28:         : AppColors.lightBackground;
29: 
30:     return ClipRRect(
31:       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
32:       child: Stack(
33:         children: [
34:           Positioned.fill(
35:             child: Image.asset(
36:               'assets/images/mosque_bg.png',
37:               fit: BoxFit.cover,
38:               alignment: Alignment.centerLeft,
39:             ),
40:           ),
41:           Positioned.fill(
42:             child: DecoratedBox(
43:               decoration: BoxDecoration(
44:                 gradient: LinearGradient(
45:                   begin: Alignment.topCenter,
46:                   end: Alignment.bottomCenter,
47:                   colors: [
48:                     const Color(0xFF020A08).withValues(alpha: 0.88),
49:                     const Color(0xFF0D3F34).withValues(alpha: 0.54),
50:                     bottomColor.withValues(alpha: 0.98),
51:                   ],
52:                   stops: const [0, 0.55, 1],
53:                 ),
54:               ),
55:             ),
56:           ),
57:           Positioned.fill(
58:             child: DecoratedBox(
59:               decoration: BoxDecoration(
60:                 gradient: RadialGradient(
61:                   center: const Alignment(-0.3, 0.05),
62:                   radius: 0.92,
63:                   colors: [
64:                     AppColors.primaryLight.withValues(alpha: 0.28),
65:                     Colors.transparent,
66:                   ],
67:                 ),
68:               ),
69:             ),
70:           ),
71:           SafeArea(
72:             bottom: false,
73:             child: Padding(
74:               padding: const EdgeInsets.fromLTRB(
75:                 AppSpacing.pagePadding,
76:                 AppSpacing.md,
77:                 AppSpacing.pagePadding,
78:                 AppSpacing.lg,
79:               ),
80:               child: Column(
81:                 crossAxisAlignment: CrossAxisAlignment.start,
82:                 children: [
83:                   // ─── Top row ────────────────────────────────────────────────
84:                   Row(
85:                     children: [
86:                       Icon(
87:                         _greetingIcon(),
88:                         color: AppColors.goldLight,
89:                         size: 22,
90:                       ),
91:                       const SizedBox(width: 8),
92:                       Expanded(
93:                         child: BlocBuilder<ProfileCubit, ProfileState>(
94:                           builder: (context, profileState) {
95:                             final hasName =
96:                                 profileState is ProfileLoaded &&
97:                                 profileState.profile.hasName;
98:                             final nameStr = hasName
99:                                 ? ', ${profileState.profile.displayName}'
100:                                 : '';
101:                             return Text(
102:                               '${_greetingText(context)}$nameStr',
103:                               maxLines: 1,
104:                               overflow: TextOverflow.ellipsis,
105:                               style: AppTypography.bodyMedium.copyWith(
106:                                 color: Colors.white.withValues(alpha: 0.78),
107:                                 fontWeight: FontWeight.w600,
108:                               ),
109:                             );
110:                           },
111:                         ),
112:                       ),
113:                       const SizedBox(width: AppSpacing.sm),
114:                       _HeroIconButton(
115:                         icon: Icons.settings_suggest_rounded,
116:                         onTap: () => context.push(AppRoutes.settings),
117:                       ),
118:                     ],
119:                   ).animate().fadeIn(duration: 350.ms),
120: 
121:                   const SizedBox(height: AppSpacing.md),
122: 
123:                   // ─── App name + Bismillah ────────────────────────────────────
124:                   Text(
125:                     'تالية',
126:                     style: AppTypography.displayMedium.copyWith(
127:                       fontFamily: 'Amiri',
128:                       color: Colors.white,
129:                       fontWeight: FontWeight.w800,
130:                       shadows: const [
131:                         Shadow(
132:                           color: Color(0x99000000),
133:                           blurRadius: 18,
134:                           offset: Offset(0, 4),
135:                         ),
136:                       ],
137:                     ),
138:                   ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04),
139: 
140:                   const SizedBox(height: 2),
141: 
142:                   Text(
143:                     'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
144:                     style: AppTypography.bodySmall.copyWith(
145:                       color: Colors.white.withValues(alpha: 0.68),
146:                       fontFamily: 'Amiri',
147:                       fontSize: 14,
148:                     ),
149:                     textDirection: TextDirection.rtl,
150:                   ).animate().fadeIn(duration: 460.ms),
151: 
152:                   const SizedBox(height: AppSpacing.lg),
153: 
154:                   // ─── Achievement Badges ──────────────────────────────────
155:                   Builder(
156:                     builder: (context) {
157:                       final readingAchievements = state.progress.achievements
158:                           .where(
159:                             (a) =>
160:                                 a.isUnlocked &&
161:                                 a.category == AchievementCategory.reading,
162:                           );
163:                       final memAchievements = state.progress.achievements.where(
164:                         (a) =>
165:                             a.isUnlocked &&
166:                             a.category == AchievementCategory.memorization,
167:                       );
168: 
169:                       final highestReading = readingAchievements.isNotEmpty
170:                           ? readingAchievements.last
171:                           : null;
172:                       final highestMem = memAchievements.isNotEmpty
173:                           ? memAchievements.last
174:                           : null;
175: 
176:                       return Wrap(
177:                         spacing: AppSpacing.sm,
178:                         runSpacing: AppSpacing.sm,
179:                         children: [
180:                           if (highestReading != null)
181:                             _AchievementBadge(
182:                                   achievement: highestReading,
183:                                   isDark: true,
184:                                 )
185:                                 .animate()
186:                                 .fadeIn(duration: 300.ms)
187:                                 .slideY(begin: 0.04),
188:                           if (highestMem != null)
189:                             _AchievementBadge(
190:                                   achievement: highestMem,
191:                                   isDark: true,
192:                                 )
193:                                 .animate()
194:                                 .fadeIn(duration: 350.ms)
195:                                 .slideY(begin: 0.04),
196:                           if (highestReading == null && highestMem == null)
197:                             const _AchievementBadge(
198:                                   achievement: null,
199:                                   isDark: true,
200:                                 )
201:                                 .animate()
202:                                 .fadeIn(duration: 300.ms)
203:                                 .slideY(begin: 0.04),
204:                         ],
205:                       );
206:                     },
207:                   ),
208:                 ],
209:               ),
210:             ),
211:           ),
212:         ],
213:       ),
214:     ).animate().fadeIn(duration: 420.ms, curve: Curves.easeOut);
215:   }
216: }
217: 
218: class _HeroIconButton extends StatelessWidget {
219:   const _HeroIconButton({required this.icon, required this.onTap});
220: 
221:   final IconData icon;
222:   final VoidCallback onTap;
223: 
224:   @override
225:   Widget build(BuildContext context) {
226:     return ClipRRect(
227:       borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
228:       child: BackdropFilter(
229:         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
230:         child: Material(
231:           color: Colors.white.withValues(alpha: 0.1),
232:           child: InkWell(
233:             onTap: onTap,
234:             child: Container(
235:               width: 42,
236:               height: 42,
237:               decoration: BoxDecoration(
238:                 borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
239:                 border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
240:               ),
241:               child: Icon(
242:                 icon,
243:                 color: Colors.white.withValues(alpha: 0.82),
244:                 size: 20,
245:               ),
246:             ),
247:           ),
248:         ),
249:       ),
250:     );
251:   }
252: }
253: 
254: class _AchievementBadge extends StatelessWidget {
255:   const _AchievementBadge({required this.achievement, required this.isDark});
256:   final Achievement? achievement;
257:   final bool isDark;
258: 
259:   @override
260:   Widget build(BuildContext context) {
261:     String badgeTitle = context.l10n.levelBeginner;
262:     IconData badgeIcon = Icons.stars_rounded;
263:     Color badgeColor = const Color(0xFFC0C0C0); // Silver for default
264:     String categoryLabel = '';
265: 
266:     if (achievement != null) {
267:       final best = achievement!;
268:       badgeTitle = context.localizedAchievementTitle(best);
269: 
270:       // Determine color, icon, and label based on category
271:       if (best.category == AchievementCategory.memorization) {
272:         badgeColor = const Color(0xFFFFD700); // Gold for memorization
273:         badgeIcon = Icons.workspace_premium_rounded;
274:         categoryLabel = context.l10n.memorization;
275:       } else {
276:         badgeColor = const Color(0xFF82C8E5); // Light blue/cyan for reading
277:         badgeIcon = Icons.menu_book_rounded;
278:         categoryLabel = context.l10n.reading;
279:       }
280: 
281:       // Special override for highest achievements
282:       if (best.id == 'full_quran_read' || best.id == 'full_quran_memorized') {
283:         badgeColor = const Color(0xFFE5C158); // Premium gold
284:         badgeIcon = Icons.diamond_rounded;
285:       }
286:     }
287: 
288:     return GestureDetector(
289:       onTap: () {
290:         // C01 FIX: Show real certificates instead of dummy data
291:         final earnedCerts = getIt<AchievementService>().getEarnedCertificates();
292:         if (earnedCerts.isEmpty) {
293:           // No certificates yet — go to progress page
294:           context.go('/progress');
295:           return;
296:         }
297:         final latestAward = earnedCerts.first; // sorted by date desc
298:         context.push(
299:           '/certificate',
300:           extra: {
301:             'award': latestAward,
302:             'userName': context.read<ProfileCubit>().state is ProfileLoaded
303:                 ? (context.read<ProfileCubit>().state as ProfileLoaded)
304:                       .profile
305:                       .displayName
306:                 : (context.l10n.taliaUser),
307:           },
308:         );
309:       },
310:       child: Container(
311:         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
312:         decoration: BoxDecoration(
313:           gradient: LinearGradient(
314:             colors: [
315:               badgeColor.withValues(alpha: 0.25),
316:               badgeColor.withValues(alpha: 0.05),
317:             ],
318:             begin: Alignment.topLeft,
319:             end: Alignment.bottomRight,
320:           ),
321:           borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
322:           border: Border.all(
323:             color: badgeColor.withValues(alpha: 0.4),
324:             width: 1.5,
325:           ),
326:           boxShadow: [
327:             BoxShadow(
328:               color: badgeColor.withValues(alpha: 0.1),
329:               blurRadius: 8,
330:               offset: const Offset(0, 2),
331:             ),
332:           ],
333:         ),
334:         child: Row(
335:           mainAxisSize: MainAxisSize.min,
336:           children: [
337:             Icon(badgeIcon, color: badgeColor, size: 24),
338:             const SizedBox(width: 8),
339:             if (categoryLabel.isNotEmpty) ...[
340:               Text(
341:                 categoryLabel,
342:                 style: AppTypography.titleSmall.copyWith(
343:                   color: badgeColor.withValues(alpha: 0.9),
344:                   fontWeight: FontWeight.w600,
345:                 ),
346:               ),
347:               Container(
348:                 margin: const EdgeInsets.symmetric(horizontal: 8),
349:                 height: 16,
350:                 width: 1.5,
351:                 color: badgeColor.withValues(alpha: 0.4),
352:               ),
353:             ],
354:             Text(
355:               badgeTitle,
356:               style: AppTypography.titleMedium.copyWith(
357:                 color: badgeColor,
358:                 fontWeight: FontWeight.w800,
359:                 fontSize: 16,
360:               ),
361:             ),
362:           ],
363:         ),
364:       ),
365:     );
366:   }
367: }
368: 
369: // ─── Daily Wird Card ──────────────────────────────────────────────────────────
370: 
371: class _DailyWirdCard extends StatelessWidget {
372:   const _DailyWirdCard({required this.state, required this.isDark});
373:   final HomeLoaded state;
374:   final bool isDark;
375: 
376:   @override
377:   Widget build(BuildContext context) {
378:     final pageNumber = state.dailyWirdPageDetail?.pageNumber ?? 1;
379:     String wird = context.isArabic
380:         ? 'قراءة الصفحة $pageNumber من القرآن الكريم'
381:         : 'Read page $pageNumber of the Holy Quran';
382: 
383:     if (state.dailyWirdPageDetail != null &&
384:         state.dailyWirdPageDetail!.surahs.isNotEmpty) {
385:       final surah = state.dailyWirdPageDetail!.surahs.first;
386:       final surahName = context.isArabic ? surah.nameAr : surah.nameEn;
387:       wird = context.isArabic
388:           ? 'سورة $surahName — صفحة $pageNumber'
389:           : 'Surah $surahName — Page $pageNumber';
390:     }
391: 
392:     final primaryText = isDark
393:         ? AppColors.darkTextPrimary
394:         : AppColors.lightTextPrimary;
395: 
396:     return GestureDetector(
397:       onTap: () => context.push('/quran/page/$pageNumber'),
398:       child: Container(
399:         padding: const EdgeInsets.all(AppSpacing.md),
400:         decoration: BoxDecoration(
401:           gradient: LinearGradient(
402:             begin: Alignment.topLeft,
403:             end: Alignment.bottomRight,
404:             colors: isDark
405:                 ? [const Color(0xFF1A2A1A), const Color(0xFF0D1A12)]
406:                 : [const Color(0xFFE8F5EF), const Color(0xFFD4EDE0)],
407:           ),
408:           borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
409:           border: Border.all(
410:             color: AppColors.primary.withValues(alpha: 0.2),
411:             width: 1,
412:           ),
413:         ),
414:         child: Row(
415:           children: [
416:             Container(
417:               width: 48,
418:               height: 48,
419:               decoration: BoxDecoration(
420:                 color: AppColors.primary.withValues(alpha: 0.12),
421:                 borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
422:               ),
423:               child: const Icon(
424:                 Icons.bookmark_rounded,
425:                 color: AppColors.primary,
426:                 size: 24,
427:               ),
428:             ),
429:             const SizedBox(width: AppSpacing.md),
430:             Expanded(
431:               child: Column(
432:                 crossAxisAlignment: CrossAxisAlignment.start,
433:                 children: [
434:                   Text(
435:                     context.l10n.dailyWird,
436:                     style: AppTypography.labelMedium.copyWith(
437:                       color: AppColors.primary,
438:                       fontWeight: FontWeight.w700,
439:                     ),
440:                   ),
441:                   const SizedBox(height: 4),
442:                   Text(
443:                     wird,
444:                     maxLines: 2,
445:                     overflow: TextOverflow.ellipsis,
446:                     style: AppTypography.titleMedium.copyWith(
447:                       color: primaryText,
448:                       fontFamily: context.isArabic ? 'Amiri' : null,
449:                       height: 1.35,
450:                     ),
451:                     textDirection: context.isArabic
452:                         ? TextDirection.rtl
453:                         : TextDirection.ltr,
454:                   ),
455:                 ],
456:               ),
457:             ),
458:             const Icon(
459:               Icons.arrow_forward_ios_rounded,
460:               size: 14,
461:               color: AppColors.primary,
462:             ),
463:           ],
464:         ),
465:       ),
466:     ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
467:   }
468: }
469: 
470: // ─── Progress Section ──────────────────────────────────────────────────────────
471: 
472: class _ProgressSection extends StatelessWidget {
473:   const _ProgressSection({required this.progress, required this.isDark});
474:   final OverallProgress progress;
475:   final bool isDark;
476: 
477:   @override
478:   Widget build(BuildContext context) {
479:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
480:     final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
481: 
482:     return Column(
483:       children: [
484:         // ── Streak pill ─────────────────────────────────────────────
485:         Container(
486:           width: double.infinity,
487:           padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
488:           decoration: BoxDecoration(
489:             gradient: const LinearGradient(
490:               colors: [Color(0xFFFF8C42), Color(0xFFFF6B00)],
491:             ),
492:             borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
493:             boxShadow: [
494:               BoxShadow(
495:                 color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
496:                 blurRadius: 12,
497:                 offset: const Offset(0, 4),
498:               ),
499:             ],
500:           ),
501:           child: Row(
502:             mainAxisAlignment: MainAxisAlignment.center,
503:             children: [
504:               const Icon(
505:                 Icons.local_fire_department_rounded,
506:                 color: Colors.white,
507:                 size: 22,
508:               ),
509:               const SizedBox(width: 8),
510:               Text(
511:                 '${progress.streakDays}',
512:                 style: AppTypography.titleLarge.copyWith(
513:                   color: Colors.white,
514:                   fontWeight: FontWeight.w800,
515:                 ),
516:               ),
517:               const SizedBox(width: 6),
518:               Text(
519:                 context.l10n.days,
520:                 style: AppTypography.bodyMedium.copyWith(
521:                   color: Colors.white.withValues(alpha: 0.85),
522:                 ),
523:               ),
524:               const SizedBox(width: 4),
525:               Text(
526:                 context.l10n.streak,
527:                 style: AppTypography.bodySmall.copyWith(
528:                   color: Colors.white.withValues(alpha: 0.7),
529:                 ),
530:               ),
531:             ],
532:           ),
533:         ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03),
534: 
535:         const SizedBox(height: AppSpacing.md),
536: 
537:         // ── Two progress cards side by side ─────────────────────────
538:         Row(
539:           children: [
540:             // Reading card
541:             Expanded(
542:               child: _MiniProgressCard(
543:                 icon: Icons.menu_book_rounded,
544:                 iconColor: AppColors.primary,
545:                 gradientColors: isDark
546:                     ? [const Color(0xFF0D2818), const Color(0xFF0A1F14)]
547:                     : [const Color(0xFFE8F5EF), const Color(0xFFD4EDE0)],
548:                 title: context.l10n.reading,
549:                 value: progress.readPagesCount,
550:                 total: progress.totalQuranPages,
551:                 unit: context.l10n.page,
552:                 isDark: isDark,
553:                 surface: surface,
554:                 border: border,
555:               ),
556:             ),
557:             const SizedBox(width: AppSpacing.sm),
558:             // Memorization card
559:             Expanded(
560:               child: _MiniProgressCard(
561:                 icon: Icons.auto_stories_rounded,
562:                 iconColor: const Color(0xFF2D5A8E),
563:                 gradientColors: isDark
564:                     ? [const Color(0xFF0D1A2E), const Color(0xFF0A1422)]
565:                     : [const Color(0xFFE8EEF5), const Color(0xFFD4DEE8)],
566:                 title: context.l10n.hifz,
567:                 value: progress.memorizedAyahs,
568:                 total: progress.totalAyahs,
569:                 unit: context.l10n.ayah,
570:                 isDark: isDark,
571:                 surface: surface,
572:                 border: border,
573:               ),
574:             ),
575:           ],
576:         ).animate().fadeIn(duration: 250.ms, delay: 100.ms),
577:       ],
578:     );
579:   }
580: }
581: 
582: class _MiniProgressCard extends StatelessWidget {
583:   const _MiniProgressCard({
584:     required this.icon,
585:     required this.iconColor,
586:     required this.gradientColors,
587:     required this.title,
588:     required this.value,
589:     required this.total,
590:     required this.unit,
591:     required this.isDark,
592:     required this.surface,
593:     required this.border,
594:   });
595: 
596:   final IconData icon;
597:   final Color iconColor;
598:   final List<Color> gradientColors;
599:   final String title;
600:   final int value;
601:   final int total;
602:   final String unit;
603:   final bool isDark;
604:   final Color surface;
605:   final Color border;
606: 
607:   @override
608:   Widget build(BuildContext context) {
609:     final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
610: 
611:     return Container(
612:       padding: const EdgeInsets.all(AppSpacing.md),
613:       decoration: BoxDecoration(
614:         gradient: LinearGradient(
615:           begin: Alignment.topLeft,
616:           end: Alignment.bottomRight,
617:           colors: gradientColors,
618:         ),
619:         borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
620:         border: Border.all(color: border, width: 0.5),
621:       ),
622:       child: Column(
623:         crossAxisAlignment: CrossAxisAlignment.start,
624:         children: [
625:           // Header row
626:           Row(
627:             children: [
628:               Container(
629:                 padding: const EdgeInsets.all(6),
630:                 decoration: BoxDecoration(
631:                   color: iconColor.withValues(alpha: 0.12),
632:                   borderRadius: BorderRadius.circular(8),
633:                 ),
634:                 child: Icon(icon, color: iconColor, size: 18),
635:               ),
636:               const SizedBox(width: 8),
637:               Expanded(
638:                 child: Text(
639:                   title,
640:                   style: AppTypography.labelMedium.copyWith(
641:                     color: isDark
642:                         ? AppColors.darkTextSecondary
643:                         : AppColors.lightTextSecondary,
644:                   ),
645:                 ),
646:               ),
647:             ],
648:           ),
649:           const SizedBox(height: AppSpacing.md),
650: 
651:           // Big number
652:           Text(
653:             '$value',
654:             style: AppTypography.displaySmall.copyWith(
655:               color: iconColor,
656:               fontWeight: FontWeight.w700,
657:               fontSize: 28,
658:             ),
659:           ),
660:           Text(
661:             context.l10n.miniProgressOf(total, unit),
662:             style: AppTypography.labelSmall.copyWith(
663:               color: isDark
664:                   ? AppColors.darkTextSecondary
665:                   : AppColors.lightTextSecondary,
666:               fontSize: 10,
667:             ),
668:           ),
669: 
670:           const SizedBox(height: AppSpacing.sm),
671: 
672:           // Progress bar
673:           ClipRRect(
674:             borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
675:             child: LinearProgressIndicator(
676:               value: pct,
677:               backgroundColor: iconColor.withValues(alpha: 0.1),
678:               valueColor: AlwaysStoppedAnimation<Color>(iconColor),
679:               minHeight: 5,
680:             ),
681:           ),
682: 
683:           const SizedBox(height: 4),
684: 
685:           // Percentage
686:           Align(
687:             alignment: AlignmentDirectional.centerEnd,
688:             child: Text(
689:               '${(pct * 100).toStringAsFixed(1)}%',
690:               style: AppTypography.labelSmall.copyWith(
691:                 color: iconColor,
692:                 fontWeight: FontWeight.w600,
693:                 fontSize: 10,
694:               ),
695:             ),
696:           ),
697:         ],
698:       ),
699:     );
700:   }
701: }
702: 
703: // ─── Azkar Shortcut Row ───────────────────────────────────────────────────────
704: 
705: class _AzkarShortcutRow extends StatelessWidget {
706:   const _AzkarShortcutRow({required this.isDark});
707:   final bool isDark;
708: 
709:   @override
710:   Widget build(BuildContext context) {
711:     return Column(
712:       crossAxisAlignment: CrossAxisAlignment.start,
713:       children: [
714:         SectionHeader(
715:           title: context.l10n.azkar,
716:           padding: EdgeInsets.zero,
717:           action: GestureDetector(
718:             onTap: () => context.go('/azkar'),
719:             child: Text(
720:               context.l10n.viewAll,
721:               style: AppTypography.labelMedium.copyWith(
722:                 color: isDark ? AppColors.primaryLight : AppColors.primary,
723:               ),
724:             ),
725:           ),
726:         ),
727:         const SizedBox(height: AppSpacing.md),
728:         Row(
729:           children: [
730:             Expanded(
731:               child: _AzkarShortcut(
732:                 label: context.l10n.morningAzkar,
733:                 icon: Icons.wb_sunny_rounded,
734:                 route: '/azkar/morning',
735:                 colors: const [Color(0xFFFF8C42), Color(0xFFFF6B00)],
736:                 isDark: isDark,
737:                 delay: 0,
738:               ),
739:             ),
740:             const SizedBox(width: AppSpacing.sm),
741:             Expanded(
742:               child: _AzkarShortcut(
743:                 label: context.l10n.eveningAzkar,
744:                 icon: Icons.nightlight_round,
745:                 route: '/azkar/evening',
746:                 colors: const [Color(0xFF2D5A8E), Color(0xFF1A3A5C)],
747:                 isDark: isDark,
748:                 delay: 80,
749:               ),
750:             ),
751:           ],
752:         ),
753:       ],
754:     );
755:   }
756: }
757: 
758: class _AzkarShortcut extends StatelessWidget {
759:   const _AzkarShortcut({
760:     required this.label,
761:     required this.icon,
762:     required this.route,
763:     required this.colors,
764:     required this.isDark,
765:     required this.delay,
766:   });
767: 
768:   final String label;
769:   final IconData icon;
770:   final String route;
771:   final List<Color> colors;
772:   final bool isDark;
773:   final int delay;
774: 
775:   @override
776:   Widget build(BuildContext context) {
777:     return GestureDetector(
778:       onTap: () => context.push(route),
779:       child: ConstrainedBox(
780:         constraints: const BoxConstraints(minHeight: 80),
781:         child: Container(
782:           decoration: BoxDecoration(
783:             gradient: LinearGradient(
784:               begin: Alignment.topLeft,
785:               end: Alignment.bottomRight,
786:               colors: colors,
787:             ),
788:             borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
789:             boxShadow: [
790:               BoxShadow(
791:                 color: colors[0].withValues(alpha: 0.25),
792:                 blurRadius: 12,
793:                 offset: const Offset(0, 4),
794:               ),
795:             ],
796:           ),
797:           child: Padding(
798:             padding: const EdgeInsets.symmetric(
799:               vertical: AppSpacing.md,
800:               horizontal: AppSpacing.sm,
801:             ),
802:             child: Row(
803:               mainAxisAlignment: MainAxisAlignment.center,
804:               children: [
805:                 Icon(icon, color: Colors.white, size: 22),
806:                 const SizedBox(width: 8),
807:                 Text(
808:                   label,
809:                   style: AppTypography.titleMedium.copyWith(
810:                     color: Colors.white,
811:                     fontFamily: 'Amiri',
812:                   ),
813:                 ),
814:               ],
815:             ),
816:           ),
817:         ),
818:       ),
819:     ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
820:   }
821: }
822: 
823: // ─── MemorizationPlus Card (Entry Point) ─────────────────────────────────────
824: 
825: class _MemorizationPlusCard extends StatelessWidget {
826:   const _MemorizationPlusCard({required this.isDark});
827:   final bool isDark;
828: 
829:   @override
830:   Widget build(BuildContext context) {
831:     return GestureDetector(
832:       onTap: () => context.push(AppRoutes.memorizationPlus),
833:       child: Container(
834:         padding: const EdgeInsets.all(AppSpacing.lg),
835:         decoration: BoxDecoration(
836:           gradient: const LinearGradient(
837:             begin: Alignment.topLeft,
838:             end: Alignment.bottomRight,
839:             colors: [Color(0xFF1A3A5C), Color(0xFF1A6B5A)],
840:           ),
841:           borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
842:           boxShadow: [
843:             BoxShadow(
844:               color: AppColors.primary.withValues(alpha: 0.25),
845:               blurRadius: 16,
846:               offset: const Offset(0, 6),
847:             ),
848:           ],
849:         ),
850:         child: Row(
851:           children: [
852:             Container(
853:               padding: const EdgeInsets.all(14),
854:               decoration: BoxDecoration(
855:                 color: Colors.white.withValues(alpha: 0.15),
856:                 borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
857:               ),
858:               child: const Icon(
859:                 Icons.psychology_rounded,
860:                 color: Colors.white,
861:                 size: 28,
862:               ),
863:             ),
864:             const SizedBox(width: AppSpacing.md),
865:             Expanded(
866:               child: Column(
867:                 crossAxisAlignment: CrossAxisAlignment.start,
868:                 children: [
869:                   Text(
870:                     context.l10n.smartMemorization,
871:                     style: AppTypography.titleLarge.copyWith(
872:                       color: Colors.white,
873:                       fontFamily: 'Amiri',
874:                       fontWeight: FontWeight.w700,
875:                     ),
876:                   ),
877:                   const SizedBox(height: 2),
878:                   Text(
879:                     context.l10n.smartMemorizationSubtitle,
880:                     style: AppTypography.bodySmall.copyWith(
881:                       color: Colors.white70,
882:                       fontFamily: 'Amiri',
883:                     ),
884:                   ),
885:                 ],
886:               ),
887:             ),
888:             const Icon(
889:               Icons.arrow_forward_ios_rounded,
890:               color: Colors.white54,
891:               size: 16,
892:             ),
893:           ],
894:         ),
895:       ),
896:     ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
897:   }
898: }
899: 
900: // ─── Active Custom Plan Card ─────────────────────────────────────────────────
901: 
902: class _ActiveCustomPlanCard extends StatelessWidget {
903:   const _ActiveCustomPlanCard({required this.plan, required this.isDark});
904:   final CustomMemorizationPlan plan;
905:   final bool isDark;
906: 
907:   @override
908:   Widget build(BuildContext context) {
909:     return GestureDetector(
910:       onTap: () => context
911:           .push('/memorization-plus/daily-plan?surahId=${plan.startSurahId}')
912:           .then((_) {
913:             if (context.mounted) {
914:               context.read<HomeCubit>().load();
915:             }
916:           }),
917:       child: Container(
918:         padding: const EdgeInsets.all(AppSpacing.lg),
919:         decoration: BoxDecoration(
920:           gradient: LinearGradient(
921:             begin: Alignment.topLeft,
922:             end: Alignment.bottomRight,
923:             colors: [
924:               const Color(0xFF6C3483).withValues(alpha: 0.9),
925:               AppColors.primary.withValues(alpha: 0.8),
926:             ],
927:           ),
928:           borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
929:           boxShadow: [
930:             BoxShadow(
931:               color: const Color(0xFF6C3483).withValues(alpha: 0.25),
932:               blurRadius: 16,
933:               offset: const Offset(0, 6),
934:             ),
935:           ],
936:         ),
937:         child: Row(
938:           children: [
939:             Container(
940:               padding: const EdgeInsets.all(14),
941:               decoration: BoxDecoration(
942:                 color: Colors.white.withValues(alpha: 0.15),
943:                 shape: BoxShape.circle,
944:               ),
945:               child: const Icon(
946:                 Icons.menu_book_rounded,
947:                 color: Colors.white,
948:                 size: 28,
949:               ),
950:             ),
951:             const SizedBox(width: AppSpacing.md),
952:             Expanded(
953:               child: Column(
954:                 crossAxisAlignment: CrossAxisAlignment.start,
955:                 children: [
956:                   Text(
957:                     plan.name,
958:                     style: AppTypography.titleLarge.copyWith(
959:                       color: Colors.white,
960:                       fontFamily: 'Amiri',
961:                       fontWeight: FontWeight.w700,
962:                     ),
963:                     maxLines: 1,
964:                     overflow: TextOverflow.ellipsis,
965:                   ),
966:                   const SizedBox(height: 2),
967:                   Text(
968:                     context.l10n.dailyPlanSummary(
969:                       plan.newAyahsPerDay,
970:                       plan.sessionMinutes,
971:                     ),
972:                     style: AppTypography.bodySmall.copyWith(
973:                       color: Colors.white70,
974:                       fontFamily: 'Amiri',
975:                     ),
976:                   ),
977:                 ],
978:               ),
979:             ),
980:             Container(
981:               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
982:               decoration: BoxDecoration(
983:                 color: Colors.white.withValues(alpha: 0.15),
984:                 borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
985:               ),
986:               child: Text(
987:                 context.l10n.continueMemorizing,
988:                 style: AppTypography.labelSmall.copyWith(
989:                   color: Colors.white,
990:                   fontWeight: FontWeight.bold,
991:                 ),
992:               ),
993:             ),
994:           ],
995:         ),
996:       ),
997:     ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
998:   }
999: }
1000: 
1001: // ─── Streak & XP Row ──────────────────────────────────────────────────────────
1002: 
1003: class _StreakXpRow extends StatelessWidget {
1004:   const _StreakXpRow({required this.isDark});
1005:   final bool isDark;
1006: 
1007:   @override
1008:   Widget build(BuildContext context) {
1009:     return Row(
1010:       children: [
1011:         // ─── Streak Card ─────────────────────────────────────────────
1012:         Expanded(
1013:           child: BlocBuilder<StreakCubit, StreakState>(
1014:             builder: (context, state) {
1015:               int currentStreak = 0;
1016:               int longestStreak = 0;
1017:               if (state is StreakLoaded) {
1018:                 currentStreak = state.streak.currentStreak;
1019:                 longestStreak = state.streak.longestStreak;
1020:               }
1021:               return Container(
1022:                 padding: const EdgeInsets.all(16),
1023:                 decoration: BoxDecoration(
1024:                   color: isDark ? AppColors.darkCard : Colors.white,
1025:                   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
1026:                   border: Border.all(
1027:                     color: currentStreak > 0
1028:                         ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
1029:                         : (isDark ? Colors.white12 : Colors.black12),
1030:                   ),
1031:                   boxShadow: [
1032:                     if (!isDark)
1033:                       BoxShadow(
1034:                         color: Colors.black.withValues(alpha: 0.05),
1035:                         blurRadius: 8,
1036:                         offset: const Offset(0, 2),
1037:                       ),
1038:                   ],
1039:                 ),
1040:                 child: Column(
1041:                   crossAxisAlignment: CrossAxisAlignment.start,
1042:                   children: [
1043:                     Row(
1044:                       children: [
1045:                         Text(
1046:                           currentStreak > 0 ? '🔥' : '❄️',
1047:                           style: const TextStyle(fontSize: 24),
1048:                         ),
1049:                         const SizedBox(width: 8),
1050:                         Text(
1051:                           '$currentStreak',
1052:                           style: AppTypography.headlineMedium.copyWith(
1053:                             fontWeight: FontWeight.bold,
1054:                             color: currentStreak > 0
1055:                                 ? const Color(0xFFF59E0B)
1056:                                 : (isDark ? Colors.white54 : Colors.black38),
1057:                           ),
1058:                         ),
1059:                       ],
1060:                     ),
1061:                     const SizedBox(height: 4),
1062:                     Text(
1063:                       context.l10n.consecutiveDays,
1064:                       style: AppTypography.labelSmall.copyWith(
1065:                         color: isDark ? Colors.white60 : Colors.black54,
1066:                       ),
1067:                     ),
1068:                     if (longestStreak > 0) ...[
1069:                       const SizedBox(height: 2),
1070:                       Text(
1071:                         context.l10n.bestStreak(longestStreak),
1072:                         style: AppTypography.labelSmall.copyWith(
1073:                           color: isDark ? Colors.white38 : Colors.black38,
1074:                           fontSize: 10,
1075:                         ),
1076:                       ),
1077:                     ],
1078:                   ],
1079:                 ),
1080:               ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.02);
1081:             },
1082:           ),
1083:         ),
1084: 
1085:         const SizedBox(width: AppSpacing.md),
1086: 
1087:         // ─── XP Card ─────────────────────────────────────────────────
1088:         Expanded(
1089:           child: FutureBuilder<int>(
1090:             future: getIt<XpService>().getTotalXp(),
1091:             builder: (context, snapshot) {
1092:               final totalXp = snapshot.data ?? 0;
1093:               final xpService = getIt<XpService>();
1094:               final level = xpService.getCurrentLevel(totalXp);
1095:               const levels = XpConstants.levels;
1096:               final currentIdx = levels.indexWhere((l) => l.name == level.name);
1097:               final nextLevel = currentIdx < levels.length - 1
1098:                   ? levels[currentIdx + 1]
1099:                   : null;
1100:               final progress = nextLevel != null
1101:                   ? ((totalXp - level.minXp) / (nextLevel.minXp - level.minXp))
1102:                         .clamp(0.0, 1.0)
1103:                   : 1.0;
1104:               return Container(
1105:                 padding: const EdgeInsets.all(16),
1106:                 decoration: BoxDecoration(
1107:                   color: isDark ? AppColors.darkCard : Colors.white,
1108:                   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
1109:                   border: Border.all(
1110:                     color: isDark ? Colors.white12 : Colors.black12,
1111:                   ),
1112:                   boxShadow: [
1113:                     if (!isDark)
1114:                       BoxShadow(
1115:                         color: Colors.black.withValues(alpha: 0.05),
1116:                         blurRadius: 8,
1117:                         offset: const Offset(0, 2),
1118:                       ),
1119:                   ],
1120:                 ),
1121:                 child: Column(
1122:                   crossAxisAlignment: CrossAxisAlignment.start,
1123:                   children: [
1124:                     Row(
1125:                       children: [
1126:                         Text(level.icon, style: const TextStyle(fontSize: 24)),
1127:                         const SizedBox(width: 8),
1128:                         Text(
1129:                           context.localizeLevelName(level.name),
1130:                           style: AppTypography.headlineSmall.copyWith(
1131:                             fontWeight: FontWeight.bold,
1132:                             color: isDark ? Colors.white : Colors.black87,
1133:                             fontFamily: 'Amiri',
1134:                           ),
1135:                         ),
1136:                       ],
1137:                     ),
1138:                     const SizedBox(height: 4),
1139:                     Text(
1140:                       '$totalXp ${context.l10n.points}',
1141:                       style: AppTypography.labelSmall.copyWith(
1142:                         color: isDark ? Colors.white60 : Colors.black54,
1143:                       ),
1144:                     ),
1145:                     const SizedBox(height: 4),
1146:                     ClipRRect(
1147:                       borderRadius: BorderRadius.circular(4),
1148:                       child: LinearProgressIndicator(
1149:                         value: progress,
1150:                         minHeight: 4,
1151:                         backgroundColor: isDark
1152:                             ? Colors.white12
1153:                             : Colors.black12,
1154:                         valueColor: AlwaysStoppedAnimation(
1155:                           Color(level.colorHex),
1156:                         ),
1157:                       ),
1158:                     ),
1159:                   ],
1160:                 ),
1161:               ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.02);
1162:             },
1163:           ),
1164:         ),
1165:       ],
1166:     );
1167:   }
1168: }
1169: 
1170: // ─── Parent Dashboard Shortcut Card ──────────────────────────────────────────
1171: 
1172: class _ParentDashboardShortcutCard extends StatelessWidget {
1173:   const _ParentDashboardShortcutCard({required this.isDark});
1174:   final bool isDark;
1175: 
1176:   @override
1177:   Widget build(BuildContext context) {
1178:     return GestureDetector(
1179:       onTap: () => context.push('${AppRoutes.parentDashboard}?surahId=1'),
1180:       child: Container(
1181:         padding: const EdgeInsets.all(AppSpacing.lg),
1182:         decoration: BoxDecoration(
1183:           color: isDark ? AppColors.darkCard : Colors.white,
1184:           borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
1185:           border: Border.all(
1186:             color: const Color(0xFF2D8E4C).withValues(alpha: 0.2),
1187:           ),
1188:           boxShadow: [
1189:             if (!isDark)
1190:               BoxShadow(
1191:                 color: const Color(0xFF2D8E4C).withValues(alpha: 0.08),
1192:                 blurRadius: 16,
1193:                 offset: const Offset(0, 4),
1194:               ),
1195:           ],
1196:         ),
1197:         child: Row(
1198:           children: [
1199:             Container(
1200:               padding: const EdgeInsets.all(12),
1201:               decoration: BoxDecoration(
1202:                 color: const Color(0xFF2D8E4C).withValues(alpha: 0.12),
1203:                 shape: BoxShape.circle,
1204:               ),
1205:               child: const Icon(
1206:                 Icons.family_restroom_rounded,
1207:                 color: Color(0xFF2D8E4C),
1208:                 size: 28,
1209:               ),
1210:             ),
1211:             const SizedBox(width: AppSpacing.md),
1212:             Expanded(
1213:               child: Column(
1214:                 crossAxisAlignment: CrossAxisAlignment.start,
1215:                 children: [
1216:                   Text(
1217:                     context.l10n.parentDashboardTitle,
1218:                     style: AppTypography.titleLarge.copyWith(
1219:                       color: isDark ? Colors.white : Colors.black87,
1220:                       fontFamily: 'Amiri',
1221:                       fontWeight: FontWeight.w700,
1222:                     ),
1223:                     maxLines: 1,
1224:                     overflow: TextOverflow.ellipsis,
1225:                   ),
1226:                   const SizedBox(height: 2),
1227:                   Text(
1228:                     context.l10n.parentDashboardCardSubtitle,
1229:                     style: AppTypography.bodySmall.copyWith(
1230:                       color: isDark ? Colors.white70 : Colors.black54,
1231:                     ),
1232:                   ),
1233:                 ],
1234:               ),
1235:             ),
1236:             Container(
1237:               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
1238:               decoration: BoxDecoration(
1239:                 color: const Color(0xFF2D8E4C).withValues(alpha: 0.1),
1240:                 borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
1241:               ),
1242:               child: Text(
1243:                 context.l10n.viewDashboard,
1244:                 style: AppTypography.labelSmall.copyWith(
1245:                   color: const Color(0xFF2D8E4C),
1246:                   fontWeight: FontWeight.bold,
1247:                 ),
1248:               ),
1249:             ),
1250:           ],
1251:         ),
1252:       ),
1253:     ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
1254:   }
1255: }
1256: 
1257: // ─── Sign-In Nudge Banner ──────────────────────────────────────────────────────
1258: 
1259: class _SignInNudgeBanner extends StatefulWidget {
1260:   const _SignInNudgeBanner({required this.isDark});
1261:   final bool isDark;
1262: 
1263:   @override
1264:   State<_SignInNudgeBanner> createState() => _SignInNudgeBannerState();
1265: }
1266: 
1267: class _SignInNudgeBannerState extends State<_SignInNudgeBanner> {
1268:   static const _dismissedKey = 'sign_in_nudge_dismissed';
1269:   bool _dismissed = false;
1270:   bool _loaded = false;
1271: 
1272:   @override
1273:   void initState() {
1274:     super.initState();
1275:     _checkDismissed();
1276:   }
1277: 
1278:   Future<void> _checkDismissed() async {
1279:     final prefs = getIt<SharedPreferences>();
1280:     final dismissed = prefs.getBool(_dismissedKey) ?? false;
1281:     if (mounted) {
1282:       setState(() {
1283:         _dismissed = dismissed;
1284:         _loaded = true;
1285:       });
1286:     }
1287:   }
1288: 
1289:   Future<void> _dismiss() async {
1290:     final prefs = getIt<SharedPreferences>();
1291:     await prefs.setBool(_dismissedKey, true);
1292:     if (mounted) setState(() => _dismissed = true);
1293:   }
1294: 
1295:   @override
1296:   Widget build(BuildContext context) {
1297:     if (!_loaded || _dismissed) return const SizedBox.shrink();
1298: 
1299:     // Only show if user is not signed in
1300:     return BlocBuilder<AuthCubit, AuthState>(
1301:       builder: (context, authState) {
1302:         if (authState is AuthAuthenticated) return const SizedBox.shrink();
1303: 
1304:         // Only show if user has made some progress (streak > 0 or XP > 0)
1305:         return BlocBuilder<StreakCubit, StreakState>(
1306:           builder: (context, streakState) {
1307:             final hasProgress =
1308:                 streakState is StreakLoaded &&
1309:                 streakState.streak.currentStreak > 0;
1310: 
1311:             if (!hasProgress) return const SizedBox.shrink();
1312: 
1313:             final primary = widget.isDark
1314:                 ? AppColors.primaryLight
1315:                 : AppColors.primary;
1316: 
1317:             return Padding(
1318:               padding: const EdgeInsets.fromLTRB(
1319:                 AppSpacing.pagePadding,
1320:                 AppSpacing.md,
1321:                 AppSpacing.pagePadding,
1322:                 0,
1323:               ),
1324:               child: Container(
1325:                 padding: const EdgeInsets.all(14),
1326:                 decoration: BoxDecoration(
1327:                   gradient: LinearGradient(
1328:                     colors: [
1329:                       primary.withValues(alpha: 0.12),
1330:                       primary.withValues(alpha: 0.06),
1331:                     ],
1332:                   ),
1333:                   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
1334:                   border: Border.all(color: primary.withValues(alpha: 0.25)),
1335:                 ),
1336:                 child: Row(
1337:                   children: [
1338:                     // Cloud icon
1339:                     Container(
1340:                       width: 40,
1341:                       height: 40,
1342:                       decoration: BoxDecoration(
1343:                         color: primary.withValues(alpha: 0.15),
1344:                         shape: BoxShape.circle,
1345:                       ),
1346:                       child: Icon(
1347:                         Icons.cloud_upload_rounded,
1348:                         color: primary,
1349:                         size: 22,
1350:                       ),
1351:                     ),
1352:                     const SizedBox(width: 12),
1353:                     // Text
1354:                     Expanded(
1355:                       child: Column(
1356:                         crossAxisAlignment: CrossAxisAlignment.start,
1357:                         children: [
1358:                           Text(
1359:                             context.l10n.backupProgressTitle,
1360:                             style: AppTypography.labelMedium.copyWith(
1361:                               color: widget.isDark
1362:                                   ? AppColors.darkTextPrimary
1363:                                   : AppColors.lightTextPrimary,
1364:                               fontWeight: FontWeight.bold,
1365:                             ),
1366:                           ),
1367:                           Text(
1368:                             context.l10n.backupProgressDesc,
1369:                             style: AppTypography.labelSmall.copyWith(
1370:                               color: widget.isDark
1371:                                   ? AppColors.darkTextSecondary
1372:                                   : AppColors.lightTextSecondary,
1373:                             ),
1374:                           ),
1375:                         ],
1376:                       ),
1377:                     ),
1378:                     const SizedBox(width: 8),
1379:                     // Action + Dismiss
1380:                     Column(
1381:                       mainAxisSize: MainAxisSize.min,
1382:                       children: [
1383:                         GestureDetector(
1384:                           onTap: () => context.push(AppRoutes.settings),
1385:                           child: Container(
1386:                             padding: const EdgeInsets.symmetric(
1387:                               horizontal: 10,
1388:                               vertical: 6,
1389:                             ),
1390:                             decoration: BoxDecoration(
1391:                               color: primary,
1392:                               borderRadius: BorderRadius.circular(
1393:                                 AppSpacing.radiusSm,
1394:                               ),
1395:                             ),
1396:                             child: Text(
1397:                               context.l10n.signIn,
1398:                               style: const TextStyle(
1399:                                 color: Colors.white,
1400:                                 fontSize: 11,
1401:                                 fontWeight: FontWeight.bold,
1402:                               ),
1403:                             ),
1404:                           ),
1405:                         ),
1406:                         const SizedBox(height: 4),

(Output capped at 50 KB. Showing lines 1-1406. Use offset=1407 to continue.)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 6.6s)

_Thinking:_

Let me continue reading home_page_widgets and look at HomeCubit which is the source of truth for home screen data.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\pages\\home_page_widgets.dart",
  "offset": 1406
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\pages\home_page_widgets.dart</path>
<type>file</type>
<content>
1406:                         const SizedBox(height: 4),
1407:                         GestureDetector(
1408:                           onTap: _dismiss,
1409:                           child: Text(
1410:                             context.l10n.later,
1411:                             style: AppTypography.labelSmall.copyWith(
1412:                               color: widget.isDark
1413:                                   ? AppColors.darkTextHint
1414:                                   : AppColors.lightTextHint,
1415:                               fontSize: 10,
1416:                             ),
1417:                           ),
1418:                         ),
1419:                       ],
1420:                     ),
1421:                   ],
1422:                 ),
1423:               ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
1424:             );
1425:           },
1426:         );
1427:       },
1428:     );
1429:   }
1430: }
1431: 
1432: // ─── Debug Certificate Preview (Debug Mode Only) ──────────────────────────────
1433: 
1434: class _DebugCertificatePreview extends StatelessWidget {
1435:   const _DebugCertificatePreview({required this.isDark});
1436:   final bool isDark;
1437: 
1438:   @override
1439:   Widget build(BuildContext context) {
1440:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
1441:     final textColor = isDark
1442:         ? AppColors.darkTextPrimary
1443:         : AppColors.lightTextPrimary;
1444: 
1445:     return Container(
1446:       padding: const EdgeInsets.all(AppSpacing.md),
1447:       decoration: BoxDecoration(
1448:         color: surface,
1449:         borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
1450:         border: Border.all(
1451:           color: Colors.orange.withValues(alpha: 0.5),
1452:           width: 1.5,
1453:         ),
1454:       ),
1455:       child: Column(
1456:         crossAxisAlignment: CrossAxisAlignment.start,
1457:         children: [
1458:           Row(
1459:             children: [
1460:               const Icon(
1461:                 Icons.bug_report_rounded,
1462:                 color: Colors.orange,
1463:                 size: 20,
1464:               ),
1465:               const SizedBox(width: 8),
1466:               Text(
1467:                 context.l10n.debugCertificatePreview,
1468:                 style: AppTypography.titleSmall.copyWith(
1469:                   color: Colors.orange,
1470:                   fontWeight: FontWeight.bold,
1471:                 ),
1472:               ),
1473:             ],
1474:           ),
1475:           const SizedBox(height: AppSpacing.sm),
1476:           Text(
1477:             context.l10n.debugCertificatePreviewDesc,
1478:             style: AppTypography.bodySmall.copyWith(
1479:               color: textColor.withValues(alpha: 0.7),
1480:             ),
1481:           ),
1482:           const SizedBox(height: AppSpacing.md),
1483:           Wrap(
1484:             spacing: AppSpacing.sm,
1485:             runSpacing: AppSpacing.sm,
1486:             children: [
1487:               _debugCertButton(
1488:                 context,
1489:                 context.l10n.debugCertJuz30,
1490:                 CertificateType.juz,
1491:                 juzNumber: 30,
1492:               ),
1493:               _debugCertButton(
1494:                 context,
1495:                 context.l10n.debugCertSurahBaqarah,
1496:                 CertificateType.surah,
1497:                 surahId: 2,
1498:                 surahNameAr: 'البقرة',
1499:               ),
1500:               _debugCertButton(
1501:                 context,
1502:                 context.l10n.debugCertHalfQuran,
1503:                 CertificateType.halfQuran,
1504:               ),
1505:               _debugCertButton(
1506:                 context,
1507:                 context.l10n.debugCertFullQuran,
1508:                 CertificateType.fullQuran,
1509:               ),
1510:             ],
1511:           ),
1512:         ],
1513:       ),
1514:     );
1515:   }
1516: 
1517:   Widget _debugCertButton(
1518:     BuildContext context,
1519:     String label,
1520:     CertificateType type, {
1521:     int? juzNumber,
1522:     int? surahId,
1523:     String? surahNameAr,
1524:   }) {
1525:     return ElevatedButton(
1526:       style: ElevatedButton.styleFrom(
1527:         backgroundColor: Colors.orange.withValues(alpha: 0.15),
1528:         foregroundColor: Colors.orange,
1529:         elevation: 0,
1530:         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
1531:         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
1532:       ),
1533:       onPressed: () {
1534:         final userName = context.read<ProfileCubit>().state is ProfileLoaded
1535:             ? (context.read<ProfileCubit>().state as ProfileLoaded)
1536:                   .profile
1537:                   .displayName
1538:             : context.l10n.taliaUser;
1539: 
1540:         final debugAward = CertificateAward(
1541:           id: 'debug_${type.name}',
1542:           titleAr: _debugTitle(type, juzNumber, surahNameAr),
1543:           type: type,
1544:           earnedAt: DateTime.now(),
1545:           juzNumber: juzNumber,
1546:           surahId: surahId,
1547:           surahNameAr: surahNameAr,
1548:         );
1549: 
1550:         context.push(
1551:           '/certificate',
1552:           extra: {'award': debugAward, 'userName': userName},
1553:         );
1554:       },
1555:       child: Text(label, style: const TextStyle(fontSize: 12)),
1556:     );
1557:   }
1558: 
1559:   String _debugTitle(
1560:     CertificateType type,
1561:     int? juzNumber,
1562:     String? surahNameAr,
1563:   ) {
1564:     return switch (type) {
1565:       CertificateType.juz => 'شهادة حفظ الجزء ${juzNumber ?? 1}',
1566:       CertificateType.surah => 'شهادة حفظ سورة ${surahNameAr ?? 'البقرة'}',
1567:       CertificateType.halfQuran => 'شهادة حفظ نصف القرآن الكريم',
1568:       CertificateType.fullQuran => 'شهادة ختم القرآن الكريم كاملاً',
1569:     };
1570:   }
1571: }
1572: 
1573: // ─── Continue Reading Chip ────────────────────────────────────────────────────
1574: 
1575: class _StartHereStrip extends StatefulWidget {
1576:   const _StartHereStrip({required this.isDark});
1577:   final bool isDark;
1578: 
1579:   @override
1580:   State<_StartHereStrip> createState() => _StartHereStripState();
1581: }
1582: 
1583: class _StartHereStripState extends State<_StartHereStrip> {
1584:   static const _skippedKey = 'onboarding_skipped';
1585:   static const _completedKey = 'first_action_completed';
1586:   bool _visible = false;
1587:   bool _loaded = false;
1588: 
1589:   @override
1590:   void initState() {
1591:     super.initState();
1592:     _load();
1593:   }
1594: 
1595:   Future<void> _load() async {
1596:     final prefs = getIt<SharedPreferences>();
1597:     final skipped = prefs.getBool(_skippedKey) ?? false;
1598:     final completed = prefs.getBool(_completedKey) ?? false;
1599:     if (mounted) {
1600:       setState(() {
1601:         _visible = skipped && !completed;
1602:         _loaded = true;
1603:       });
1604:     }
1605:   }
1606: 
1607:   Future<void> _completeAndGo(String route) async {
1608:     await getIt<SharedPreferences>().setBool(_completedKey, true);
1609:     if (!mounted) return;
1610:     setState(() => _visible = false);
1611:     unawaited(context.push(route));
1612:   }
1613: 
1614:   @override
1615:   Widget build(BuildContext context) {
1616:     if (!_loaded || !_visible) return const SizedBox.shrink();
1617:     final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
1618:     final textColor = widget.isDark
1619:         ? AppColors.darkTextPrimary
1620:         : AppColors.lightTextPrimary;
1621:     final subTextColor = widget.isDark
1622:         ? AppColors.darkTextSecondary
1623:         : AppColors.lightTextSecondary;
1624: 
1625:     return Padding(
1626:       padding: const EdgeInsets.fromLTRB(
1627:         AppSpacing.pagePadding,
1628:         AppSpacing.md,
1629:         AppSpacing.pagePadding,
1630:         0,
1631:       ),
1632:       child: Container(
1633:         padding: const EdgeInsets.all(AppSpacing.md),
1634:         decoration: BoxDecoration(
1635:           color: primary.withValues(alpha: 0.08),
1636:           borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
1637:           border: Border.all(color: primary.withValues(alpha: 0.22)),
1638:         ),
1639:         child: Column(
1640:           crossAxisAlignment: CrossAxisAlignment.start,
1641:           children: [
1642:             Row(
1643:               children: [
1644:                 Icon(Icons.flag_rounded, color: primary, size: 20),
1645:                 const SizedBox(width: 8),
1646:                 Expanded(
1647:                   child: Text(
1648:                     'ابدأ من هنا',
1649:                     style: AppTypography.titleMedium.copyWith(
1650:                       color: textColor,
1651:                       fontFamily: 'Amiri',
1652:                       fontWeight: FontWeight.w700,
1653:                     ),
1654:                   ),
1655:                 ),
1656:                 IconButton(
1657:                   onPressed: () async {
1658:                     await getIt<SharedPreferences>().setBool(
1659:                       _completedKey,
1660:                       true,
1661:                     );
1662:                     if (mounted) setState(() => _visible = false);
1663:                   },
1664:                   icon: Icon(Icons.close_rounded, color: subTextColor),
1665:                   visualDensity: VisualDensity.compact,
1666:                 ),
1667:               ],
1668:             ),
1669:             const SizedBox(height: AppSpacing.sm),
1670:             Wrap(
1671:               spacing: AppSpacing.sm,
1672:               runSpacing: AppSpacing.sm,
1673:               children: [
1674:                 _StartActionChip(
1675:                   icon: Icons.menu_book_rounded,
1676:                   label: 'اقرأ صفحة',
1677:                   onTap: () => _completeAndGo('/quran'),
1678:                 ),
1679:                 _StartActionChip(
1680:                   icon: Icons.psychology_alt_rounded,
1681:                   label: 'ابدأ الحفظ',
1682:                   onTap: () => _completeAndGo('/memorization-plus'),
1683:                 ),
1684:                 _StartActionChip(
1685:                   icon: Icons.help_outline_rounded,
1686:                   label: 'دليل سريع',
1687:                   onTap: () => _completeAndGo('/tutorial-guide'),
1688:                 ),
1689:               ],
1690:             ),
1691:           ],
1692:         ),
1693:       ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04),
1694:     );
1695:   }
1696: }
1697: 
1698: class _StartActionChip extends StatelessWidget {
1699:   const _StartActionChip({
1700:     required this.icon,
1701:     required this.label,
1702:     required this.onTap,
1703:   });
1704: 
1705:   final IconData icon;
1706:   final String label;
1707:   final VoidCallback onTap;
1708: 
1709:   @override
1710:   Widget build(BuildContext context) {
1711:     return ActionChip(
1712:       avatar: Icon(icon, size: 18),
1713:       label: Text(label),
1714:       onPressed: onTap,
1715:     );
1716:   }
1717: }
1718: 
1719: class _ResumeSessionCard extends StatelessWidget {
1720:   const _ResumeSessionCard({required this.location, required this.isDark});
1721: 
1722:   final String location;
1723:   final bool isDark;
1724: 
1725:   String _description(BuildContext context) {
1726:     final uri = Uri.tryParse(location);
1727:     if (uri == null) return context.l10n.resumeWhereYouLeft;
1728:     if (uri.path.startsWith('/quran/page/')) return context.l10n.lastSavedReading;
1729:     if (uri.path == '/hifz/session') return context.l10n.incompleteHifzSession;
1730:     if (uri.path == '/memorization-plus/daily-plan') return context.l10n.dailyMemorizationPlan;
1731:     if (uri.path == '/memorization-plus/kids') return context.l10n.incompleteKidsSession;
1732:     if (uri.path == '/memorization-plus/quiz') return context.l10n.previousHifzQuiz;
1733:     return context.l10n.savedPreviousActivity;
1734:   }
1735: 
1736:   @override
1737:   Widget build(BuildContext context) {
1738:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
1739:     final textColor = isDark
1740:         ? AppColors.darkTextPrimary
1741:         : AppColors.lightTextPrimary;
1742:     final subTextColor = isDark
1743:         ? AppColors.darkTextSecondary
1744:         : AppColors.lightTextSecondary;
1745: 
1746:     return Container(
1747:       padding: const EdgeInsets.all(AppSpacing.md),
1748:       decoration: BoxDecoration(
1749:         color: isDark ? AppColors.darkCard : AppColors.lightCard,
1750:         borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
1751:         border: Border.all(color: primary.withValues(alpha: 0.22)),
1752:       ),
1753:       child: Row(
1754:         children: [
1755:           Icon(Icons.play_circle_fill_rounded, color: primary, size: 34),
1756:           const SizedBox(width: AppSpacing.md),
1757:           Expanded(
1758:             child: Column(
1759:               crossAxisAlignment: CrossAxisAlignment.start,
1760:               children: [
1761:                 Text(
1762:                   context.l10n.resumeWhereYouLeft,
1763:                   style: AppTypography.titleMedium.copyWith(
1764:                     color: textColor,
1765:                     fontFamily: 'Amiri',
1766:                     fontWeight: FontWeight.w700,
1767:                   ),
1768:                 ),
1769:                 Text(
1770:                   _description(context),
1771:                   style: AppTypography.bodySmall.copyWith(color: subTextColor),
1772:                 ),
1773:               ],
1774:             ),
1775:           ),
1776:           TextButton(
1777:             onPressed: () => unawaited(context.push(location)),
1778:             child: Text(context.l10n.resumeAction),
1779:           ),
1780:           IconButton(
1781:             onPressed: () async {
1782:               await getIt<AppSessionService>().clearLastRestorableLocation();
1783:               if (context.mounted) {
1784:                 unawaited(context.read<HomeCubit>().load());
1785:               }
1786:             },
1787:             icon: Icon(Icons.close_rounded, color: subTextColor),
1788:             tooltip: context.l10n.notNow,
1789:           ),
1790:         ],
1791:       ),
1792:     ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
1793:   }
1794: }
1795: 
1796: class _NextBestActionCard extends StatefulWidget {
1797:   const _NextBestActionCard({required this.state, required this.isDark});
1798: 
1799:   final HomeLoaded state;
1800:   final bool isDark;
1801: 
1802:   @override
1803:   State<_NextBestActionCard> createState() => _NextBestActionCardState();
1804: }
1805: 
1806: class _NextBestActionCardState extends State<_NextBestActionCard> {
1807:   String? _goal;
1808: 
1809:   @override
1810:   void initState() {
1811:     super.initState();
1812:     _goal = getIt<SharedPreferences>().getString('user_primary_goal');
1813:   }
1814: 
1815:   (String, String, IconData, String) _action(BuildContext context) {
1816:     if (widget.state.customPlan != null) {
1817:       return (
1818:         context.l10n.completeTodaysHifz,
1819:         context.l10n.planReadySmallStep,
1820:         Icons.psychology_alt_rounded,
1821:         '/memorization-plus',
1822:       );
1823:     }
1824:     if (widget.state.dailyWirdPageDetail != null) {
1825:       return (
1826:         context.l10n.readTodaysPortion,
1827:         context.l10n.onePageMakesProgress,
1828:         Icons.menu_book_rounded,
1829:         '/quran/page/${widget.state.dailyWirdPageDetail!.pageNumber}',
1830:       );
1831:     }
1832:     if (_goal == 'azkar') {
1833:       return (
1834:         context.l10n.timeForDhikr,
1835:         context.l10n.startShortAzkarNow,
1836:         Icons.volunteer_activism_rounded,
1837:         '/azkar',
1838:       );
1839:     }
1840:     if (_goal == 'child') {
1841:       return (
1842:         context.l10n.followChildJourney,
1843:         context.l10n.reviewProgressOrReward,
1844:         Icons.family_restroom_rounded,
1845:         '${AppRoutes.parentDashboard}?surahId=1',
1846:       );
1847:     }
1848:     return (
1849:       context.l10n.startQuranStepNow,
1850:       context.l10n.chooseReadingOrMemorization,
1851:       Icons.auto_awesome_rounded,
1852:       _goal == 'memorization' ? '/memorization-plus' : '/quran',
1853:     );
1854:   }
1855: 
1856:   @override
1857:   Widget build(BuildContext context) {
1858:     final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
1859:     final textColor = widget.isDark
1860:         ? AppColors.darkTextPrimary
1861:         : AppColors.lightTextPrimary;
1862:     final subTextColor = widget.isDark
1863:         ? AppColors.darkTextSecondary
1864:         : AppColors.lightTextSecondary;
1865:     final action = _action(context);
1866: 
1867:     return InkWell(
1868:       onTap: () => context.push(action.$4),
1869:       borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
1870:       child: Container(
1871:         padding: const EdgeInsets.all(AppSpacing.md),
1872:         decoration: BoxDecoration(
1873:           gradient: LinearGradient(
1874:             colors: [
1875:               primary.withValues(alpha: 0.14),
1876:               primary.withValues(alpha: 0.05),
1877:             ],
1878:           ),
1879:           borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
1880:           border: Border.all(color: primary.withValues(alpha: 0.24)),
1881:         ),
1882:         child: Row(
1883:           children: [
1884:             Icon(action.$3, color: primary, size: 30),
1885:             const SizedBox(width: AppSpacing.md),
1886:             Expanded(
1887:               child: Column(
1888:                 crossAxisAlignment: CrossAxisAlignment.start,
1889:                 children: [
1890:                   Text(
1891:                     action.$1,
1892:                     style: AppTypography.titleMedium.copyWith(
1893:                       color: textColor,
1894:                       fontFamily: 'Amiri',
1895:                       fontWeight: FontWeight.w800,
1896:                     ),
1897:                   ),
1898:                   Text(
1899:                     action.$2,
1900:                     style: AppTypography.bodySmall.copyWith(
1901:                       color: subTextColor,
1902:                     ),
1903:                   ),
1904:                 ],
1905:               ),
1906:             ),
1907:             Icon(Icons.arrow_forward_ios_rounded, color: primary, size: 16),
1908:           ],
1909:         ),
1910:       ),
1911:     ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
1912:   }
1913: }
1914: 
1915: // ignore: unused_element
1916: class _ContinueReadingChip extends StatelessWidget {
1917:   const _ContinueReadingChip({required this.location, required this.isDark});
1918: 
1919:   final String location;
1920:   final bool isDark;
1921: 
1922:   /// Parses `/quran/page/42` → 'صفحة 42' (Arabic).
1923:   /// Falls back to a generic label for other restorable locations.
1924:   String _label(BuildContext context) {
1925:     final uri = Uri.tryParse(location);
1926:     if (uri == null) return context.isArabic ? 'استكمال القراءة' : 'Continue';
1927:     final segments = uri.pathSegments;
1928:     if (segments.length == 3 && segments[0] == 'quran') {
1929:       if (segments[1] == 'page') {
1930:         return context.isArabic
1931:             ? 'استكمال القراءة — صفحة ${segments[2]}'
1932:             : 'Continue Reading — Page ${segments[2]}';
1933:       }
1934:       if (segments[1] == 'surah') {
1935:         return context.isArabic
1936:             ? 'استكمال قراءة السورة ${segments[2]}'
1937:             : 'Continue Surah ${segments[2]}';
1938:       }
1939:     }
1940:     return context.isArabic
1941:         ? 'استكمال من حيث توقفت'
1942:         : 'Continue where you left off';
1943:   }
1944: 
1945:   @override
1946:   Widget build(BuildContext context) {
1947:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
1948: 
1949:     return GestureDetector(
1950:       onTap: () => context.push(location),
1951:       child: Container(
1952:         padding: const EdgeInsets.symmetric(
1953:           horizontal: AppSpacing.md,
1954:           vertical: AppSpacing.sm,
1955:         ),
1956:         decoration: BoxDecoration(
1957:           color: primary.withValues(alpha: 0.08),
1958:           borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
1959:           border: Border.all(color: primary.withValues(alpha: 0.25)),
1960:         ),
1961:         child: Row(
1962:           mainAxisSize: MainAxisSize.min,
1963:           children: [
1964:             Icon(Icons.play_circle_outline_rounded, color: primary, size: 18),
1965:             const SizedBox(width: 8),
1966:             Flexible(
1967:               child: Text(
1968:                 _label(context),
1969:                 maxLines: 1,
1970:                 overflow: TextOverflow.ellipsis,
1971:                 style: AppTypography.labelMedium.copyWith(
1972:                   color: primary,
1973:                   fontWeight: FontWeight.w600,
1974:                 ),
1975:               ),
1976:             ),
1977:           ],
1978:         ),
1979:       ),
1980:     ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.02);
1981:   }
1982: }

(End of file - total 1982 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 9.5s)

_Thinking:_

Now let me look at the home_cubit and hifz files in parallel.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\cubits"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\cubits</path>
<type>directory</type>
<entries>
home_cubit.dart
home_state.dart

(2 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\cubits"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\cubits</path>
<type>directory</type>
<entries>
hifz_cubit.dart
hifz_session_cubit.dart
hifz_session_state.dart
hifz_state.dart

(4 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\cubits"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\cubits</path>
<type>directory</type>
<entries>
custom_plan_cubit.dart
custom_plan_state.dart
daily_plan_cubit.dart
daily_plan_state.dart
guardian_linking_cubit.dart
guardian_linking_state.dart
kids_journey_cubit.dart
kids_journey_state.dart
kids_mode_cubit.dart
kids_mode_state.dart
memorization_identity_cubit.dart
memorization_identity_state.dart
parent_dashboard_cubit.dart
parent_dashboard_state.dart
quiz_cubit.dart
quiz_state.dart
track_selection_cubit.dart
track_selection_state.dart

(18 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 7.2s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\cubits\\home_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\cubits\home_cubit.dart</path>
<type>file</type>
<content>
1: import 'dart:math';
2: import 'package:equatable/equatable.dart';
3: import 'package:flutter/foundation.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import '../../../progress/domain/entities/progress_entities.dart';
6: import '../../../progress/domain/usecases/get_progress_usecase.dart';
7: import '../../../hifz/domain/usecases/get_hifz_progress_usecase.dart';
8: import '../../../hifz/domain/entities/hifz_entities.dart';
9: import '../../../quran/domain/usecases/get_surahs_usecase.dart';
10: import '../../../quran/domain/entities/quran_entities.dart';
11: import '../../../memorization_plus/domain/entities/memorization_entities.dart';
12: import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
13: import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
14: import '../../../../core/services/app_session_service.dart';
15: import '../../domain/usecases/get_activity_heatmap_usecase.dart';
16: 
17: part 'home_state.dart';
18: 
19: class HomeCubit extends Cubit<HomeState> {
20:   final GetProgressUsecase _getProgress;
21:   final GetHifzProgressUsecase _getHifzProgress;
22:   final GetQuranPageUsecase _getQuranPage;
23:   final GetCustomPlanUsecase _getCustomPlan;
24:   final MemorizationPlusRepository _memorizationRepository;
25:   final AppSessionService _sessionService;
26:   final GetActivityHeatmapUsecase _getHeatmap;
27: 
28:   HomeCubit(
29:     this._getProgress,
30:     this._getHifzProgress,
31:     this._getQuranPage,
32:     this._getCustomPlan,
33:     this._memorizationRepository,
34:     this._sessionService,
35:     this._getHeatmap,
36:   ) : super(const HomeInitial());
37: 
38:   Future<void> load() async {
39:     emit(const HomeLoading());
40: 
41:     final now = DateTime.now();
42:     // Use date-based seed to ensure the random page stays the same for the whole day
43:     final today = DateTime(now.year, now.month, now.day);
44:     final random = Random(today.millisecondsSinceEpoch);
45:     final pageNumber = random.nextInt(604) + 1;
46: 
47:     final progressFuture = _getProgress();
48:     final hifzFuture = _getHifzProgress();
49:     final quranPageFuture = _getQuranPage(pageNumber);
50:     final planFuture = _getCustomPlan();
51:     final heatmapFuture = _getHeatmap();
52: 
53:     final progressResult = await progressFuture;
54:     final hifzResult = await hifzFuture;
55:     final quranPageResult = await quranPageFuture;
56:     QuranPageDetail? dailyWirdDetail;
57:     quranPageResult.fold((l) => null, (r) => dailyWirdDetail = r);
58: 
59:     CustomMemorizationPlan? customPlan;
60:     final planResult = await planFuture;
61:     planResult.fold((l) => null, (plan) => customPlan = plan);
62:     final heatmap = await heatmapFuture;
63: 
64:     // Load last restorable location for "Continue Reading" chip
65:     final lastLocation = _sessionService.getLastRestorableLocation();
66: 
67:     // Load parent tracking preferences
68:     MemorizationTrack? selectedTrack;
69:     _memorizationRepository.getSelectedTrack().fold(
70:       (_) {},
71:       (t) => selectedTrack = t,
72:     );
73:     bool isParentMode = false;
74:     _memorizationRepository.getIsParentMode().fold(
75:       (_) {},
76:       (m) => isParentMode = m,
77:     );
78: 
79:     progressResult.fold((f) => emit(HomeError(f.message)), (progress) {
80:       final hifzProgress = hifzResult.getOrElse(() => []);
81:       emit(
82:         HomeLoaded(
83:           progress: progress,
84:           hifzSurahProgress: hifzProgress,
85:           greeting: _greeting(),
86:           dailyWirdPageDetail: dailyWirdDetail,
87:           customPlan: customPlan,
88:           selectedTrack: selectedTrack,
89:           isParentMode: isParentMode,
90:           lastRestorableLocation: lastLocation,
91:           activityCountsByDay: heatmap.countsByDay,
92:           activityStartDate: heatmap.startDate,
93:         ),
94:       );
95:     });
96:   }
97: 
98:   String _greeting() {
99:     final hour = DateTime.now().hour;
100:     if (hour >= 5 && hour < 12) return 'morning';
101:     if (hour >= 12 && hour < 17) return 'afternoon';
102:     if (hour >= 17 && hour < 21) return 'evening';
103:     return 'night';
104:   }
105: }

(End of file - total 105 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 12.9s)

_Thinking:_

I notice HomeCubit calls getSelectedTrack and getIsParentMode but doesn't await them - they may be sync but let me check. Also it doesn't load the MemorizationProfile properly. Let me also check the HomeState.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\home\\presentation\\cubits\\home_state.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\home\presentation\cubits\home_state.dart</path>
<type>file</type>
<content>
1: part of 'home_cubit.dart';
2: 
3: @immutable
4: abstract class HomeState extends Equatable {
5:   const HomeState();
6:   @override
7:   List<Object?> get props => [];
8: }
9: 
10: class HomeInitial extends HomeState {
11:   const HomeInitial();
12: }
13: 
14: class HomeLoading extends HomeState {
15:   const HomeLoading();
16: }
17: 
18: class HomeLoaded extends HomeState {
19:   const HomeLoaded({
20:     required this.progress,
21:     required this.hifzSurahProgress,
22:     required this.greeting,
23:     this.dailyWirdPageDetail,
24:     this.customPlan,
25:     this.selectedTrack,
26:     this.isParentMode = false,
27:     this.lastRestorableLocation,
28:     this.activityCountsByDay = const {},
29:     required this.activityStartDate,
30:   });
31: 
32:   final OverallProgress progress;
33:   final List<SurahHifzProgress> hifzSurahProgress;
34:   final String greeting; // 'morning' | 'afternoon' | 'evening' | 'night'
35:   final QuranPageDetail? dailyWirdPageDetail;
36:   final CustomMemorizationPlan? customPlan;
37:   final MemorizationTrack? selectedTrack;
38:   final bool isParentMode;
39: 
40:   /// Last restorable GoRouter path, e.g. `/quran/page/42`.
41:   /// Null when the user has never read anything.
42:   final String? lastRestorableLocation;
43:   final Map<String, int> activityCountsByDay;
44:   final DateTime activityStartDate;
45: 
46:   @override
47:   List<Object?> get props => [
48:     progress,
49:     hifzSurahProgress,
50:     greeting,
51:     dailyWirdPageDetail,
52:     customPlan,
53:     selectedTrack,
54:     isParentMode,
55:     lastRestorableLocation,
56:     activityCountsByDay,
57:     activityStartDate,
58:   ];
59: }
60: 
61: class HomeError extends HomeState {
62:   const HomeError(this.message);
63:   final String message;
64:   @override
65:   List<Object?> get props => [message];
66: }

(End of file - total 66 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\cubits\\hifz_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\cubits\hifz_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'package:equatable/equatable.dart';
3: import 'package:flutter_bloc/flutter_bloc.dart';
4: import '../../../quran/domain/entities/quran_entities.dart';
5: import '../../../quran/domain/usecases/get_surahs_usecase.dart';
6: import '../../domain/hifz_unlock_rules.dart';
7: import '../../domain/entities/hifz_entities.dart';
8: import '../../domain/usecases/get_hifz_progress_usecase.dart';
9: import '../../../memorization_plus/domain/entities/memorization_entities.dart';
10: import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
11: 
12: part 'hifz_state.dart';
13: 
14: class HifzCubit extends Cubit<HifzState> {
15:   HifzCubit(
16:     this._getSurahs,
17:     this._getProgress,
18:     this._getPath,
19:     this._savePath,
20:     this._memorizationRepository,
21:   ) : super(const HifzInitial());
22: 
23:   final GetSurahsUsecase _getSurahs;
24:   final GetHifzProgressUsecase _getProgress;
25:   final GetHifzPathUsecase _getPath;
26:   final SaveHifzPathUsecase _savePath;
27:   final MemorizationPlusRepository _memorizationRepository;
28: 
29:   Future<void> load() async {
30:     emit(const HifzLoading());
31:     final surahsResult = await _getSurahs();
32:     final progressResult = await _getProgress();
33:     final pathResult = await _getPath();
34:     final profileResult = await _memorizationRepository
35:         .getMemorizationProfile();
36: 
37:     surahsResult.fold((f) => emit(HifzError(f.message)), (surahs) {
38:       progressResult.fold((f) => emit(HifzError(f.message)), (progress) {
39:         pathResult.fold((f) => emit(HifzError(f.message)), (path) {
40:           final profile = profileResult.fold((_) => null, (profile) => profile);
41:           final effectivePath = profile?.hifzPathValue ?? path;
42:           final progressMap = {for (final p in progress) p.surahId: p};
43:           final sortedSurahs = sortSurahsForHifzPath(
44:             surahs: surahs,
45:             path: effectivePath,
46:           );
47:           final unlockedSurahIds = buildUnlockedSurahIds(
48:             orderedSurahs: sortedSurahs,
49:             progressMap: progressMap,
50:           );
51: 
52:           emit(
53:             HifzLoaded(
54:               surahs: sortedSurahs,
55:               progressMap: progressMap,
56:               selectedPath: effectivePath,
57:               unlockedSurahIds: unlockedSurahIds,
58:             ),
59:           );
60:         });
61:       });
62:     });
63:   }
64: 
65:   Future<void> selectPath(String path) async {
66:     final currentState = state;
67:     if (currentState is HifzLoaded) {
68:       final saveResult = await _savePath(path);
69:       final failure = saveResult.fold((f) => f, (_) => null);
70:       if (failure != null) {
71:         emit(HifzError(failure.message));
72:         return;
73:       }
74: 
75:       final sortedSurahs = sortSurahsForHifzPath(
76:         surahs: currentState.surahs,
77:         path: path,
78:       );
79:       final unlockedSurahIds = buildUnlockedSurahIds(
80:         orderedSurahs: sortedSurahs,
81:         progressMap: currentState.progressMap,
82:       );
83: 
84:       emit(
85:         HifzLoaded(
86:           surahs: sortedSurahs,
87:           progressMap: currentState.progressMap,
88:           selectedPath: path,
89:           unlockedSurahIds: unlockedSurahIds,
90:         ),
91:       );
92:       final memPath = path == 'backward'
93:           ? MemorizationPath.child
94:           : MemorizationPath.adult;
95:       await _memorizationRepository.selectMemorizationPath(memPath);
96:     }
97:   }
98: }
99: 

(End of file - total 99 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\cubits\\hifz_state.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\cubits\hifz_state.dart</path>
<type>file</type>
<content>
1: part of 'hifz_cubit.dart';
2: 
3: @immutable
4: abstract class HifzState extends Equatable {
5:   const HifzState();
6:   @override
7:   List<Object?> get props => [];
8: }
9: 
10: class HifzInitial extends HifzState {
11:   const HifzInitial();
12: }
13: 
14: class HifzLoading extends HifzState {
15:   const HifzLoading();
16: }
17: 
18: class HifzLoaded extends HifzState {
19:   const HifzLoaded({
20:     required this.surahs,
21:     required this.progressMap,
22:     required this.unlockedSurahIds,
23:     this.selectedPath,
24:   });
25:   final List<Surah> surahs;
26:   final Map<int, SurahHifzProgress> progressMap;
27:   final Set<int> unlockedSurahIds;
28:   final String? selectedPath;
29: 
30:   bool isSurahUnlocked(int surahId) => unlockedSurahIds.contains(surahId);
31: 
32:   @override
33:   List<Object?> get props {
34:     final unlockedIds = unlockedSurahIds.toList()..sort();
35:     return [surahs, progressMap, selectedPath, ...unlockedIds];
36:   }
37: }
38: 
39: class HifzError extends HifzState {
40:   const HifzError(this.message);
41:   final String message;
42:   @override
43:   List<Object?> get props => [message];
44: }

(End of file - total 44 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 10.9s)

_Thinking:_

Now let me look at hifz_page, the hifz session, and key memorization plus pages in parallel.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\pages\\hifz_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\pages\hifz_page.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/material.dart';
2: import 'package:flutter_animate/flutter_animate.dart';
3: import 'package:flutter_bloc/flutter_bloc.dart';
4: import 'package:go_router/go_router.dart';
5: import 'package:percent_indicator/percent_indicator.dart';
6: 
7: import '../../../../core/constants/app_spacing.dart';
8: import '../../../../core/di/injection.dart';
9: import '../../../../core/extensions/context_extensions.dart';
10: import '../../../../core/theme/app_colors.dart';
11: import '../../../../core/theme/app_typography.dart';
12: import '../../../../core/widgets/state_widgets.dart';
13: import '../../../../core/widgets/section_header.dart';
14: import '../../domain/entities/hifz_entities.dart';
15: import '../cubits/hifz_cubit.dart';
16: import '../../../quran/domain/entities/quran_entities.dart';
17: import '../../../../core/router/app_router.dart';
18: import '../../../memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';
19: 
20: class HifzPage extends StatelessWidget {
21:   const HifzPage({super.key});
22: 
23:   @override
24:   Widget build(BuildContext context) {
25:     return BlocProvider(
26:       create: (_) => getIt<HifzCubit>()..load(),
27:       child: const _HifzView(),
28:     );
29:   }
30: }
31: 
32: class _HifzView extends StatelessWidget {
33:   const _HifzView();
34: 
35:   @override
36:   Widget build(BuildContext context) {
37:     final isDark = context.isDark;
38:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
39: 
40:     return Scaffold(
41:       backgroundColor: isDark
42:           ? AppColors.darkBackground
43:           : AppColors.lightBackground,
44:       body: BlocBuilder<HifzCubit, HifzState>(
45:         builder: (context, state) {
46:           return CustomScrollView(
47:             slivers: [
48:               _buildAppBar(context, isDark, primary, state),
49:               // ─── MemorizationPlus entry banner ─────────────────────────────
50:               if (state is HifzLoaded && state.selectedPath != null)
51:                 SliverToBoxAdapter(child: _MemPlusBanner(isDark: isDark)),
52:               if (state is HifzLoading)
53:                 const SliverFillRemaining(child: LoadingWidget()),
54:               if (state is HifzError)
55:                 SliverFillRemaining(
56:                   child: ErrorStateWidget(
57:                     message: state.message,
58:                     onRetry: () => context.read<HifzCubit>().load(),
59:                   ),
60:                 ),
61:               if (state is HifzLoaded)
62:                 // T028: When no path is set, delegate to the authoritative
63:                 // MemorizationPlus identity gate rather than showing the
64:                 // duplicate inline path-chooser.
65:                 if (state.selectedPath == null) ...[
66:                   SliverFillRemaining(
67:                     hasScrollBody: false,
68:                     child: EmptyStateWidget(
69:                       icon: Icons.route_rounded,
70:                       message: context.l10n.chooseMemorizationPath,
71:                     ),
72:                   ),
73:                 ] else ...[
74:                   if (state.progressMap.isNotEmpty) ...[
75:                     SliverToBoxAdapter(
76:                       child: Padding(
77:                         padding: const EdgeInsets.only(
78:                           top: AppSpacing.lg,
79:                           bottom: AppSpacing.sm,
80:                         ),
81:                         child: SectionHeader(
82:                           title: context.l10n.hifzProgress,
83:                           subtitle:
84:                               '${state.progressMap.length} ${context.l10n.surahs}',
85:                         ),
86:                       ),
87:                     ),
88:                     SliverToBoxAdapter(
89:                       child: _ProgressOverviewCard(
90:                         progressMap: state.progressMap,
91:                         isDark: isDark,
92:                         primary: primary,
93:                       ),
94:                     ),
95:                   ],
96:                   SliverToBoxAdapter(
97:                     child: Padding(
98:                       padding: const EdgeInsets.only(
99:                         top: AppSpacing.lg,
100:                         bottom: AppSpacing.sm,
101:                       ),
102:                       child: SectionHeader(title: context.l10n.selectSurah),
103:                     ),
104:                   ),
105:                   SliverPadding(
106:                     padding: const EdgeInsets.fromLTRB(
107:                       AppSpacing.pagePadding,
108:                       0,
109:                       AppSpacing.pagePadding,
110:                       120, // Prevent cutoff by bottom nav
111:                     ),
112:                     sliver: SliverList(
113:                       delegate: SliverChildBuilderDelegate(
114:                         (ctx, i) => _HifzSurahTile(
115:                           surah: state.surahs[i],
116:                           progress: state.progressMap[state.surahs[i].id],
117:                           isUnlocked: state.isSurahUnlocked(state.surahs[i].id),
118:                           requiredPreviousSurah: i > 0
119:                               ? state.surahs[i - 1]
120:                               : null,
121:                           index: i,
122:                           isDark: isDark,
123:                           primary: primary,
124:                         ),
125:                         childCount: state.surahs.length,
126:                       ),
127:                     ),
128:                   ),
129:                 ],
130:             ],
131:           );
132:         },
133:       ),
134:     );
135:   }
136: 
137:   SliverAppBar _buildAppBar(
138:     BuildContext ctx,
139:     bool isDark,
140:     Color primary,
141:     HifzState state,
142:   ) {
143:     return SliverAppBar(
144:       expandedHeight: 140,
145:       pinned: true,
146:       backgroundColor: isDark
147:           ? AppColors.darkBackground
148:           : AppColors.lightBackground,
149:       elevation: 0,
150:       scrolledUnderElevation: 0,
151:       flexibleSpace: FlexibleSpaceBar(
152:         collapseMode: CollapseMode.pin,
153:         background: Container(
154:           decoration: BoxDecoration(
155:             gradient: isDark
156:                 ? const LinearGradient(
157:                     begin: Alignment.topLeft,
158:                     end: Alignment.bottomRight,
159:                     colors: [Color(0xFF0A2A22), Color(0xFF0D1117)],
160:                   )
161:                 : const LinearGradient(
162:                     begin: Alignment.topLeft,
163:                     end: Alignment.bottomRight,
164:                     colors: [Color(0xFF1A6B5A), Color(0xFF2D5A8E)],
165:                   ),
166:           ),
167:           child: SafeArea(
168:             child: Padding(
169:               padding: const EdgeInsets.fromLTRB(
170:                 AppSpacing.pagePadding,
171:                 AppSpacing.lg,
172:                 AppSpacing.pagePadding,
173:                 AppSpacing.md,
174:               ),
175:               child: Column(
176:                 crossAxisAlignment: CrossAxisAlignment.start,
177:                 children: [
178:                   Row(
179:                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
180:                     crossAxisAlignment: CrossAxisAlignment.start,
181:                     children: [
182:                       Column(
183:                         crossAxisAlignment: CrossAxisAlignment.start,
184:                         children: [
185:                           Text(
186:                             ctx.l10n.memorization,
187:                             style: AppTypography.headlineLarge.copyWith(
188:                               color: Colors.white,
189:                               fontFamily: 'Amiri',
190:                             ),
191:                           ),
192:                           Text(
193:                             ctx.l10n.selectSurah,
194:                             style: AppTypography.bodySmall.copyWith(
195:                               color: Colors.white70,
196:                             ),
197:                           ),
198:                         ],
199:                       ),
200:                       if (state is HifzLoaded && state.selectedPath != null)
201:                         IconButton(
202:                           icon: const Icon(
203:                             Icons.settings_suggest_rounded,
204:                             color: Colors.white,
205:                           ),
206:                           tooltip: ctx.l10n.changeMemorizationPath,
207:                           // T028: Path changes are managed exclusively through
208:                           // the Settings page (Reset / Change path control)
209:                           // to preserve shared identity integrity.
210:                           // UPDATE: User requested to not go to the main settings page.
211:                           onPressed: () => showMemorizationPathSettingsSheet(
212:                             ctx,
213:                             isDark: isDark,
214:                           ),
215:                         ),
216:                     ],
217:                   ),
218:                 ],
219:               ),
220:             ),
221:           ),
222:         ),
223:       ),
224:     );
225:   }
226: }
227: 
228: class _ProgressOverviewCard extends StatelessWidget {
229:   const _ProgressOverviewCard({
230:     required this.progressMap,
231:     required this.isDark,
232:     required this.primary,
233:   });
234: 
235:   final Map<int, SurahHifzProgress> progressMap;
236:   final bool isDark;
237:   final Color primary;
238: 
239:   @override
240:   Widget build(BuildContext context) {
241:     final totalMemorized = progressMap.values.fold(
242:       0,
243:       (s, p) => s + p.memorizedCount,
244:     );
245: 
246:     return Container(
247:       margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
248:       padding: const EdgeInsets.all(AppSpacing.lg),
249:       decoration: BoxDecoration(
250:         gradient: isDark
251:             ? AppColors.heroGradientDark
252:             : AppColors.heroGradientLight,
253:         borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
254:       ),
255:       child: Row(
256:         children: [
257:           Expanded(
258:             child: Column(
259:               crossAxisAlignment: CrossAxisAlignment.start,
260:               children: [
261:                 Text(
262:                   '$totalMemorized',
263:                   style: AppTypography.displayMedium.copyWith(
264:                     color: Colors.white,
265:                     fontWeight: FontWeight.w700,
266:                   ),
267:                 ),
268:                 Text(
269:                   context.l10n.memorized,
270:                   style: AppTypography.bodySmall.copyWith(
271:                     color: Colors.white70,
272:                   ),
273:                 ),
274:               ],
275:             ),
276:           ),
277:           CircularPercentIndicator(
278:             radius: 36,
279:             lineWidth: 5,
280:             percent: (totalMemorized / 6236).clamp(0.0, 1.0),
281:             center: Text(
282:               '${((totalMemorized / 6236) * 100).toStringAsFixed(1)}%',
283:               style: AppTypography.labelSmall.copyWith(
284:                 color: Colors.white,
285:                 fontSize: 9,
286:               ),
287:             ),
288:             progressColor: AppColors.gold,
289:             backgroundColor: Colors.white.withValues(alpha: 0.2),
290:             circularStrokeCap: CircularStrokeCap.round,
291:           ),
292:         ],
293:       ),
294:     ).animate().fadeIn(duration: 250.ms);
295:   }
296: }
297: 
298: class _HifzSurahTile extends StatelessWidget {
299:   const _HifzSurahTile({
300:     required this.surah,
301:     required this.progress,
302:     required this.isUnlocked,
303:     required this.requiredPreviousSurah,
304:     required this.index,
305:     required this.isDark,
306:     required this.primary,
307:   });
308: 
309:   final Surah surah;
310:   final SurahHifzProgress? progress;
311:   final bool isUnlocked;
312:   final Surah? requiredPreviousSurah;
313:   final int index;
314:   final bool isDark;
315:   final Color primary;
316: 
317:   @override
318:   Widget build(BuildContext context) {
319:     final hasProgress = progress != null;
320:     final percent = hasProgress
321:         ? progress!.memorizedCount / surah.ayahCount
322:         : 0.0;
323:     final isLocked = !isUnlocked;
324:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
325:     final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
326:     final previousSurahName = context.isArabic
327:         ? requiredPreviousSurah?.nameAr ?? context.l10n.surah
328:         : requiredPreviousSurah?.nameEn ?? context.l10n.surah;
329:     final lockedText = context.l10n.completePreviousSurahFirst(
330:       previousSurahName,
331:     );
332: 
333:     return GestureDetector(
334:       onTap: () {
335:         if (isLocked) {
336:           ScaffoldMessenger.of(
337:             context,
338:           ).showSnackBar(SnackBar(content: Text(lockedText)));
339:           return;
340:         }
341:         context.push('/hifz/session?surahId=${surah.id}&startAyah=1');
342:       },
343:       child: Container(
344:         margin: const EdgeInsets.only(bottom: AppSpacing.sm),
345:         padding: const EdgeInsets.all(AppSpacing.md),
346:         decoration: BoxDecoration(
347:           color: isLocked ? surface.withValues(alpha: 0.82) : surface,
348:           borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
349:           border: Border.all(
350:             color: isLocked ? border.withValues(alpha: 0.65) : border,
351:             width: 0.5,
352:           ),
353:         ),
354:         child: Row(
355:           children: [
356:             // Number
357:             Container(
358:               width: 40,
359:               height: 40,
360:               decoration: BoxDecoration(
361:                 color: isLocked
362:                     ? (isDark ? Colors.white10 : Colors.black12)
363:                     : hasProgress
364:                     ? primary.withValues(alpha: 0.12)
365:                     : primary.withValues(alpha: 0.06),
366:                 borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
367:               ),
368:               child: Center(
369:                 child: Text(
370:                   '${surah.id}',
371:                   style: AppTypography.labelMedium.copyWith(
372:                     color: isLocked
373:                         ? (isDark
374:                               ? AppColors.darkTextHint
375:                               : AppColors.lightTextHint)
376:                         : primary,
377:                   ),
378:                 ),
379:               ),
380:             ),
381:             const SizedBox(width: AppSpacing.md),
382:             Expanded(
383:               child: Column(
384:                 crossAxisAlignment: CrossAxisAlignment.start,
385:                 children: [
386:                   Text(
387:                     context.isArabic ? surah.nameAr : surah.nameEn,
388:                     style: context.isArabic
389:                         ? AppTypography.surahTitle.copyWith(
390:                             color: isLocked
391:                                 ? (isDark
392:                                       ? AppColors.darkTextSecondary
393:                                       : AppColors.lightTextSecondary)
394:                                 : primary,
395:                             fontSize: 18,
396:                           )
397:                         : AppTypography.titleMedium.copyWith(
398:                             color: isLocked
399:                                 ? (isDark
400:                                       ? AppColors.darkTextSecondary
401:                                       : AppColors.lightTextSecondary)
402:                                 : isDark
403:                                 ? AppColors.darkTextPrimary
404:                                 : AppColors.lightTextPrimary,
405:                           ),
406:                   ),
407:                   const SizedBox(height: 6),
408:                   if (isLocked) ...[
409:                     Row(
410:                       children: [
411:                         Icon(
412:                           Icons.lock_rounded,
413:                           size: 14,
414:                           color: isDark
415:                               ? AppColors.darkTextHint
416:                               : AppColors.lightTextHint,
417:                         ),
418:                         const SizedBox(width: 4),
419:                         Expanded(
420:                           child: Text(
421:                             lockedText,
422:                             style: AppTypography.bodySmall.copyWith(
423:                               color: isDark
424:                                   ? AppColors.darkTextHint
425:                                   : AppColors.lightTextHint,
426:                             ),
427:                           ),
428:                         ),
429:                       ],
430:                     ),
431:                     const SizedBox(height: 4),
432:                   ],
433:                   if (hasProgress) ...[
434:                     LinearPercentIndicator(
435:                       lineHeight: 4,
436:                       percent: percent.clamp(0.0, 1.0),
437:                       progressColor: AppColors.gold,
438:                       backgroundColor: primary.withValues(alpha: 0.1),
439:                       barRadius: const Radius.circular(4),
440:                       padding: EdgeInsets.zero,
441:                     ),
442:                     const SizedBox(height: 4),
443:                     Text(
444:                       '${progress!.memorizedCount} / ${surah.ayahCount} ${context.l10n.ayahs}',
445:                       style: AppTypography.bodySmall.copyWith(
446:                         color: isDark
447:                             ? AppColors.darkTextHint
448:                             : AppColors.lightTextHint,
449:                       ),
450:                     ),
451:                   ] else
452:                     Text(
453:                       '${surah.ayahCount} ${context.l10n.ayahs}',
454:                       style: AppTypography.bodySmall.copyWith(
455:                         color: isDark
456:                             ? AppColors.darkTextHint
457:                             : AppColors.lightTextHint,
458:                       ),
459:                     ),
460:                 ],
461:               ),
462:             ),
463:             const SizedBox(width: AppSpacing.sm),
464:             Icon(
465:               isLocked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
466:               size: 14,
467:               color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
468:             ),
469:           ],
470:         ),
471:       ),
472:     ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.02, end: 0);
473:   }
474: }
475: 
476: // ─── MemorizationPlus Banner (Hifz Entry Point) ───────────────────────────────
477: 
478: class _MemPlusBanner extends StatelessWidget {
479:   const _MemPlusBanner({required this.isDark});
480:   final bool isDark;
481: 
482:   @override
483:   Widget build(BuildContext context) {
484:     return GestureDetector(
485:       onTap: () => context.push(AppRoutes.memorizationPlus),
486:       child: Container(
487:         margin: const EdgeInsets.fromLTRB(
488:           AppSpacing.pagePadding,
489:           AppSpacing.md,
490:           AppSpacing.pagePadding,
491:           0,
492:         ),
493:         padding: const EdgeInsets.symmetric(
494:           horizontal: AppSpacing.lg,
495:           vertical: AppSpacing.md,
496:         ),
497:         decoration: BoxDecoration(
498:           gradient: const LinearGradient(
499:             begin: Alignment.centerLeft,
500:             end: Alignment.centerRight,
501:             colors: [Color(0xFF1A3A5C), Color(0xFF1A6B5A)],
502:           ),
503:           borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
504:         ),
505:         child: Row(
506:           children: [
507:             const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
508:             const SizedBox(width: AppSpacing.md),
509:             Expanded(
510:               child: Column(
511:                 crossAxisAlignment: CrossAxisAlignment.start,
512:                 children: [
513:                   Text(
514:                     context.l10n.smartMemorization,
515:                     style: AppTypography.titleMedium.copyWith(
516:                       color: Colors.white,
517:                       fontFamily: 'Amiri',
518:                     ),
519:                   ),
520:                   Text(
521:                     context.l10n.smartMemorizationSubtitle,
522:                     style: AppTypography.bodySmall.copyWith(
523:                       color: Colors.white70,
524:                     ),
525:                   ),
526:                 ],
527:               ),
528:             ),
529:             const Icon(
530:               Icons.arrow_forward_ios_rounded,
531:               color: Colors.white54,
532:               size: 14,
533:             ),
534:           ],
535:         ),
536:       ),
537:     );
538:   }
539: }

(End of file - total 539 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 11.2s)

_Thinking:_

Let me look at the memorization_plus domain to understand the entities.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain</path>
<type>directory</type>
<entries>
entities/
repositories/
usecases/

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\data</path>
<type>directory</type>
<entries>
datasources/
models/
repositories/

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\data"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\data</path>
<type>directory</type>
<entries>
datasources/
models/
repositories/

(3 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 9.1s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\entities"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\entities</path>
<type>directory</type>
<entries>
memorization_entities.dart
memorization_profile.dart
pairing_session.dart
smart_memorization_settings.dart

(4 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\repositories"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\repositories</path>
<type>directory</type>
<entries>
memorization_plus_repository.dart

(1 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\usecases"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\usecases</path>
<type>directory</type>
<entries>
memorization_plus_usecases.dart

(1 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data\\datasources"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\data\datasources</path>
<type>directory</type>
<entries>
memorization_plus_local_datasource.dart

(1 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 6.6s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\entities\\memorization_profile.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\entities\memorization_profile.dart</path>
<type>file</type>
<content>
1: import 'package:equatable/equatable.dart';
2: import 'memorization_entities.dart';
3: 
4: enum MemorizationPath { adult, child }
5: 
6: enum GuardianLinkStatus { none, pending, linked }
7: 
8: enum GuardianOnboardingStatus { required, skipped, completed }
9: 
10: class MemorizationProfile extends Equatable {
11:   const MemorizationProfile({
12:     required this.schemaVersion,
13:     required this.selectedPath,
14:     required this.guardianLinkStatus,
15:     required this.guardianOnboardingStatus,
16:     required this.isParentGuardian,
17:     required this.createdAt,
18:     required this.updatedAt,
19:     this.linkedChildId,
20:     this.guardianId,
21:   });
22: 
23:   factory MemorizationProfile.empty() {
24:     // UTC: profile timestamps must match the UTC policy used everywhere else.
25:     final now = DateTime.now().toUtc();
26:     return MemorizationProfile(
27:       schemaVersion: 1,
28:       selectedPath: null,
29:       guardianLinkStatus: GuardianLinkStatus.none,
30:       guardianOnboardingStatus: GuardianOnboardingStatus.required,
31:       isParentGuardian: false,
32:       createdAt: now,
33:       updatedAt: now,
34:     );
35:   }
36: 
37:   final int schemaVersion;
38:   final MemorizationPath? selectedPath;
39:   final GuardianLinkStatus guardianLinkStatus;
40:   final GuardianOnboardingStatus guardianOnboardingStatus;
41:   final bool isParentGuardian;
42:   final String? linkedChildId;
43:   final String? guardianId;
44:   final DateTime createdAt;
45:   final DateTime updatedAt;
46: 
47:   bool get hasSelectedPath => selectedPath != null;
48:   bool get isAdult => selectedPath == MemorizationPath.adult;
49:   bool get isChild => selectedPath == MemorizationPath.child;
50:   bool get isGuardianLinked => guardianLinkStatus == GuardianLinkStatus.linked;
51: 
52:   MemorizationTrack? get legacyTrack => isAdult
53:       ? MemorizationTrack.adults
54:       : (isChild ? MemorizationTrack.kids : null);
55:   String? get hifzPathValue =>
56:       isAdult ? 'forward' : (isChild ? 'backward' : null);
57:   bool get needsGuardianOnboarding =>
58:       isChild &&
59:       guardianOnboardingStatus == GuardianOnboardingStatus.required &&
60:       guardianLinkStatus != GuardianLinkStatus.linked;
61: 
62:   MemorizationProfile copyWith({
63:     int? schemaVersion,
64:     MemorizationPath? selectedPath,
65:     bool clearSelectedPath = false,
66:     GuardianLinkStatus? guardianLinkStatus,
67:     GuardianOnboardingStatus? guardianOnboardingStatus,
68:     bool? isParentGuardian,
69:     String? linkedChildId,
70:     bool clearLinkedChildId = false,
71:     String? guardianId,
72:     bool clearGuardianId = false,
73:     DateTime? createdAt,
74:     DateTime? updatedAt,
75:   }) => MemorizationProfile(
76:     schemaVersion: schemaVersion ?? this.schemaVersion,
77:     selectedPath: clearSelectedPath
78:         ? null
79:         : (selectedPath ?? this.selectedPath),
80:     guardianLinkStatus: guardianLinkStatus ?? this.guardianLinkStatus,
81:     guardianOnboardingStatus:
82:         guardianOnboardingStatus ?? this.guardianOnboardingStatus,
83:     isParentGuardian: isParentGuardian ?? this.isParentGuardian,
84:     linkedChildId: clearLinkedChildId
85:         ? null
86:         : (linkedChildId ?? this.linkedChildId),
87:     guardianId: clearGuardianId ? null : (guardianId ?? this.guardianId),
88:     createdAt: createdAt ?? this.createdAt,
89:     updatedAt: updatedAt ?? DateTime.now().toUtc(),
90:   );
91: 
92:   @override
93:   List<Object?> get props => [
94:     schemaVersion,
95:     selectedPath,
96:     guardianLinkStatus,
97:     guardianOnboardingStatus,
98:     isParentGuardian,
99:     linkedChildId,
100:     guardianId,
101:     createdAt,
102:     updatedAt,
103:   ];
104: }

(End of file - total 104 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\entities\\memorization_entities.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\entities\memorization_entities.dart</path>
<type>file</type>
<content>
1: import 'package:equatable/equatable.dart';
2: 
3: export 'memorization_profile.dart';
4: export 'pairing_session.dart';
5: export 'smart_memorization_settings.dart';
6: 
7: // ─── Enums ────────────────────────────────────────────────────────────────────
8: 
9: enum MemorizationTrack { adults, kids }
10: 
11: enum PerformanceRating { excellent, average, weak }
12: 
13: enum KidsJourneyStageStatus { locked, current, completed, needsReview }
14: 
15: enum ParentRewardStatus { locked, unlocked, claimed }
16: 
17: enum PlanTargetUser { adult, child }
18: 
19: // ─── Memorization Identity (Moved to separate files) ──────────
20: 
21: // ─── AyahReviewRecord ─────────────────────────────────────────────────────────
22: 
23: /// Enhanced per-ayah progress record used exclusively by MemorizationPlus.
24: /// Lives alongside existing [AyahProgress] without replacing it.
25: class AyahReviewRecord extends Equatable {
26:   const AyahReviewRecord({
27:     required this.surahId,
28:     required this.ayahNumber,
29:     required this.strengthLevel,
30:     required this.intervalDays,
31:     required this.lastReviewedAt,
32:     required this.nextReviewDate,
33:     required this.totalReviews,
34:     required this.lastRating,
35:   });
36: 
37:   final int surahId;
38:   final int ayahNumber;
39: 
40:   /// 0 = new, 1–5 = weak→strong, 6+ = memorized
41:   final int strengthLevel;
42: 
43:   /// Current interval in days
44:   final int intervalDays;
45: 
46:   final DateTime lastReviewedAt;
47:   final DateTime nextReviewDate;
48:   final int totalReviews;
49:   final PerformanceRating? lastRating;
50: 
51:   bool get isDue => !DateTime.now().toUtc().isBefore(nextReviewDate.toUtc());
52:   bool get isNew => totalReviews == 0;
53:   bool get isMemorized => strengthLevel >= 6;
54: 
55:   /// Near revision: reviewed within last 5 days
56:   bool get isNearRevision {
57:     if (isNew) return false;
58:     final diff = DateTime.now().toUtc().difference(lastReviewedAt.toUtc()).inDays;
59:     return diff <= 5 && !isMemorized;
60:   }
61: 
62:   /// Far revision: reviewed more than 5 days ago
63:   bool get isFarRevision {
64:     if (isNew) return false;
65:     final diff = DateTime.now().toUtc().difference(lastReviewedAt.toUtc()).inDays;
66:     return diff > 5 && !isMemorized;
67:   }
68: 
69:   String get key => '${surahId}_$ayahNumber';
70: 
71:   AyahReviewRecord copyWith({
72:     int? strengthLevel,
73:     int? intervalDays,
74:     DateTime? lastReviewedAt,
75:     DateTime? nextReviewDate,
76:     int? totalReviews,
77:     PerformanceRating? lastRating,
78:   }) => AyahReviewRecord(
79:     surahId: surahId,
80:     ayahNumber: ayahNumber,
81:     strengthLevel: strengthLevel ?? this.strengthLevel,
82:     intervalDays: intervalDays ?? this.intervalDays,
83:     lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
84:     nextReviewDate: nextReviewDate ?? this.nextReviewDate,
85:     totalReviews: totalReviews ?? this.totalReviews,
86:     lastRating: lastRating ?? this.lastRating,
87:   );
88: 
89:   @override
90:   List<Object?> get props => [
91:     surahId,
92:     ayahNumber,
93:     strengthLevel,
94:     intervalDays,
95:     nextReviewDate,
96:     totalReviews,
97:     lastRating,
98:   ];
99: }
100: 
101: // ─── DailyPlan ────────────────────────────────────────────────────────────────
102: 
103: class DailyPlanAyah extends Equatable {
104:   const DailyPlanAyah({
105:     required this.surahId,
106:     required this.ayahNumber,
107:     required this.ayahText,
108:     required this.record,
109:   });
110: 
111:   final int surahId;
112:   final int ayahNumber;
113:   final String ayahText;
114:   final AyahReviewRecord? record;
115: 
116:   bool get isNew => record == null || record!.isNew;
117: 
118:   @override
119:   List<Object?> get props => [surahId, ayahNumber, ayahText];
120: }
121: 
122: class DailyPlan extends Equatable {
123:   const DailyPlan({
124:     required this.generatedAt,
125:     required this.surahId,
126:     required this.newAyahs,
127:     required this.nearRevision,
128:     required this.farRevision,
129:     required this.completedAyahNums,
130:   });
131: 
132:   final DateTime generatedAt;
133:   final int surahId;
134:   final List<DailyPlanAyah> newAyahs;
135:   final List<DailyPlanAyah> nearRevision;
136:   final List<DailyPlanAyah> farRevision;
137:   final List<int> completedAyahNums;
138: 
139:   int get totalItems =>
140:       newAyahs.length + nearRevision.length + farRevision.length;
141:   int get completedCount => completedAyahNums.length;
142:   double get progress => totalItems == 0 ? 0 : completedCount / totalItems;
143: 
144:   bool isCompleted(int ayahNumber) => completedAyahNums.contains(ayahNumber);
145: 
146:   DailyPlan withCompleted(int ayahNumber) {
147:     if (completedAyahNums.contains(ayahNumber)) return this;
148:     return DailyPlan(
149:       generatedAt: generatedAt,
150:       surahId: surahId,
151:       newAyahs: newAyahs,
152:       nearRevision: nearRevision,
153:       farRevision: farRevision,
154:       completedAyahNums: [...completedAyahNums, ayahNumber],
155:     );
156:   }
157: 
158:   @override
159:   List<Object?> get props => [
160:     generatedAt,
161:     surahId,
162:     newAyahs,
163:     nearRevision,
164:     farRevision,
165:     completedAyahNums,
166:   ];
167: }
168: 
169: // ─── KidsProgress ─────────────────────────────────────────────────────────────
170: 
171: class KidsProgress extends Equatable {
172:   const KidsProgress({
173:     required this.totalPoints,
174:     required this.currentLevel,
175:     required this.currentStreak,
176:     required this.starsEarned,
177:     required this.ayahsCompleted,
178:     required this.lastSessionAt,
179:   });
180: 
181:   const KidsProgress.initial()
182:     : totalPoints = 0,
183:       currentLevel = 1,
184:       currentStreak = 0,
185:       starsEarned = 0,
186:       ayahsCompleted = 0,
187:       lastSessionAt = null;
188: 
189:   final int totalPoints;
190:   final int currentLevel;
191:   final int currentStreak;
192:   final int starsEarned;
193:   final int ayahsCompleted;
194:   final DateTime? lastSessionAt;
195: 
196:   /// Points needed to reach next level (exponential growth)
197:   int get pointsForNextLevel => currentLevel * 100;
198: 
199:   /// Points earned in current level
200:   int get pointsInCurrentLevel {
201:     int spent = 0;
202:     for (int i = 1; i < currentLevel; i++) {
203:       spent += i * 100;
204:     }
205:     return totalPoints - spent;
206:   }
207: 
208:   double get levelProgress => pointsInCurrentLevel / pointsForNextLevel;
209: 
210:   int get starsForLevel => switch (currentLevel) {
211:     <= 3 => 1,
212:     <= 7 => 2,
213:     _ => 3,
214:   };
215: 
216:   KidsProgress addPoints(int points) {
217:     final newTotal = totalPoints + points;
218:     int level = currentLevel;
219:     int needed = level * 100;
220:     int spent = 0;
221:     for (int i = 1; i < level; i++) {
222:       spent += i * 100;
223:     }
224:     while (newTotal - spent >= needed) {
225:       spent += needed;
226:       level++;
227:       needed = level * 100;
228:     }
229: 
230:     // Only increment streak when the session is on a new UTC calendar day.
231:     // Without this check, calling addPoints() multiple times in the same day
232:     // would inflate the streak counter incorrectly.
233:     final now = DateTime.now().toUtc();
234:     final todayKey = DateTime.utc(now.year, now.month, now.day);
235:     final lastKey = lastSessionAt == null
236:         ? null
237:         : DateTime.utc(
238:             lastSessionAt!.toUtc().year,
239:             lastSessionAt!.toUtc().month,
240:             lastSessionAt!.toUtc().day,
241:           );
242:     final isNewDay = lastKey == null || todayKey.isAfter(lastKey);
243: 
244:     return KidsProgress(
245:       totalPoints: newTotal,
246:       currentLevel: level,
247:       currentStreak: isNewDay ? currentStreak + 1 : currentStreak,
248:       starsEarned: starsEarned + _starsForRating(),
249:       ayahsCompleted: ayahsCompleted + 1,
250:       lastSessionAt: now,
251:     );
252:   }
253: 
254:   int _starsForRating() => 1; // base, can be extended
255: 
256:   KidsProgress withStar() => KidsProgress(
257:     totalPoints: totalPoints,
258:     currentLevel: currentLevel,
259:     currentStreak: currentStreak,
260:     starsEarned: starsEarned + 1,
261:     ayahsCompleted: ayahsCompleted,
262:     lastSessionAt: lastSessionAt,
263:   );
264: 
265:   @override
266:   List<Object?> get props => [
267:     totalPoints,
268:     currentLevel,
269:     currentStreak,
270:     starsEarned,
271:     ayahsCompleted,
272:   ];
273: }
274: 
275: class KidsJourneyStage extends Equatable {
276:   const KidsJourneyStage({
277:     required this.stageNumber,
278:     required this.surahId,
279:     required this.startAyah,
280:     required this.endAyah,
281:     required this.completedAyahs,
282:     required this.status,
283:   });
284: 
285:   final int stageNumber;
286:   final int surahId;
287:   final int startAyah;
288:   final int endAyah;
289:   final List<int> completedAyahs;
290:   final KidsJourneyStageStatus status;
291: 
292:   int get totalAyahs => endAyah - startAyah + 1;
293:   int get completedCount => completedAyahs.length;
294:   double get progress => totalAyahs <= 0 ? 0 : completedCount / totalAyahs;
295:   bool get isUnlocked => status != KidsJourneyStageStatus.locked;
296: 
297:   /// The next ayah to start memorizing. If all ayahs are completed,
298:   /// returns [startAyah] to allow reviewing from the beginning.
299:   int get nextAyahToStart =>
300:       completedAyahs.length >= totalAyahs ? startAyah : startAyah + completedAyahs.length;
301: 
302:   @override
303:   List<Object?> get props => [
304:     stageNumber,
305:     surahId,
306:     startAyah,
307:     endAyah,
308:     completedAyahs,
309:     status,
310:   ];
311: }
312: 
313: class KidsSessionLog extends Equatable {
314:   const KidsSessionLog({
315:     required this.id,
316:     required this.surahId,
317:     required this.ayahNumber,
318:     required this.repeatsCompleted,
319:     required this.pointsEarned,
320:     required this.completedAt,
321:     this.syncedAt,
322:   });
323: 
324:   final String id;
325:   final int surahId;
326:   final int ayahNumber;
327:   final int repeatsCompleted;
328:   final int pointsEarned;
329:   final DateTime completedAt;
330:   final DateTime? syncedAt;
331: 
332:   bool get isSynced => syncedAt != null;
333: 
334:   KidsSessionLog copyWith({DateTime? syncedAt}) => KidsSessionLog(
335:     id: id,
336:     surahId: surahId,
337:     ayahNumber: ayahNumber,
338:     repeatsCompleted: repeatsCompleted,
339:     pointsEarned: pointsEarned,
340:     completedAt: completedAt,
341:     syncedAt: syncedAt ?? this.syncedAt,
342:   );
343: 
344:   @override
345:   List<Object?> get props => [
346:     id,
347:     surahId,
348:     ayahNumber,
349:     repeatsCompleted,
350:     pointsEarned,
351:     completedAt,
352:     syncedAt,
353:   ];
354: }
355: 
356: class ParentSettings extends Equatable {
357:   const ParentSettings({
358:     this.pinHash,
359:     this.reminderEnabled = true,
360:     this.reminderHour = 18,
361:     this.reminderMinute = 30,
362:     this.weeklyGoalSessions = 5,
363:     this.remoteLinkEnabled = false,
364:   });
365: 
366:   final String? pinHash;
367:   final bool reminderEnabled;
368:   final int reminderHour;
369:   final int reminderMinute;
370:   final int weeklyGoalSessions;
371:   final bool remoteLinkEnabled;
372: 
373:   bool get hasPin => pinHash != null && pinHash!.isNotEmpty;
374: 
375:   ParentSettings copyWith({
376:     String? pinHash,
377:     bool clearPin = false,
378:     bool? reminderEnabled,
379:     int? reminderHour,
380:     int? reminderMinute,
381:     int? weeklyGoalSessions,
382:     bool? remoteLinkEnabled,
383:   }) => ParentSettings(
384:     pinHash: clearPin ? null : (pinHash ?? this.pinHash),
385:     reminderEnabled: reminderEnabled ?? this.reminderEnabled,
386:     reminderHour: reminderHour ?? this.reminderHour,
387:     reminderMinute: reminderMinute ?? this.reminderMinute,
388:     weeklyGoalSessions: weeklyGoalSessions ?? this.weeklyGoalSessions,
389:     remoteLinkEnabled: remoteLinkEnabled ?? this.remoteLinkEnabled,
390:   );
391: 
392:   @override
393:   List<Object?> get props => [
394:     pinHash,
395:     reminderEnabled,
396:     reminderHour,
397:     reminderMinute,
398:     weeklyGoalSessions,
399:     remoteLinkEnabled,
400:   ];
401: }
402: 
403: class ParentReward extends Equatable {
404:   const ParentReward({
405:     required this.id,
406:     required this.title,
407:     required this.status,
408:     required this.createdAt,
409:     this.unlockedAt,
410:     this.claimedAt,
411:   });
412: 
413:   final String id;
414:   final String title;
415:   final ParentRewardStatus status;
416:   final DateTime createdAt;
417:   final DateTime? unlockedAt;
418:   final DateTime? claimedAt;
419: 
420:   ParentReward copyWith({
421:     String? title,
422:     ParentRewardStatus? status,
423:     DateTime? unlockedAt,
424:     DateTime? claimedAt,
425:   }) => ParentReward(
426:     id: id,
427:     title: title ?? this.title,
428:     status: status ?? this.status,
429:     createdAt: createdAt,
430:     unlockedAt: unlockedAt ?? this.unlockedAt,
431:     claimedAt: claimedAt ?? this.claimedAt,
432:   );
433: 
434:   @override
435:   List<Object?> get props => [
436:     id,
437:     title,
438:     status,
439:     createdAt,
440:     unlockedAt,
441:     claimedAt,
442:   ];
443: }
444: 
445: class ParentDashboard extends Equatable {
446:   const ParentDashboard({
447:     required this.progress,
448:     required this.stages,
449:     required this.logs,
450:     required this.rewards,
451:     required this.settings,
452:   });
453: 
454:   final KidsProgress progress;
455:   final List<KidsJourneyStage> stages;
456:   final List<KidsSessionLog> logs;
457:   final List<ParentReward> rewards;
458:   final ParentSettings settings;
459: 
460:   int get weeklyCompletedSessions {
461:     final now = DateTime.now().toUtc();
462:     final weekStart = DateTime.utc(
463:       now.year,
464:       now.month,
465:       now.day,
466:     ).subtract(Duration(days: now.weekday - 1));
467:     return logs.where((log) => !log.completedAt.toUtc().isBefore(weekStart)).length;
468:   }
469: 
470:   @override
471:   List<Object?> get props => [progress, stages, logs, rewards, settings];
472: }
473: 
474: class RemoteChildSummary extends Equatable {
475:   const RemoteChildSummary({
476:     required this.childUserId,
477:     required this.displayName,
478:     required this.progress,
479:     required this.logs,
480:     required this.rewards,
481:   });
482: 
483:   final String childUserId;
484:   final String displayName;
485:   final KidsProgress progress;
486:   final List<KidsSessionLog> logs;
487:   final List<ParentReward> rewards;
488: 
489:   @override
490:   List<Object?> get props => [
491:     childUserId,
492:     displayName,
493:     progress,
494:     logs,
495:     rewards,
496:   ];
497: }
498: 
499: // ─── CustomMemorizationPlan ───────────────────────────────────────────────────
500: 
501: /// Difficulty level affects the spaced repetition multiplier.
502: enum MemorizationDifficulty { easy, moderate, challenging }
503: 
504: /// A user-defined memorization plan with all scheduling parameters.
505: class CustomMemorizationPlan extends Equatable {
506:   const CustomMemorizationPlan({
507:     required this.name,
508:     required this.startSurahId,
509:     required this.endSurahId,
510:     required this.newAyahsPerDay,
511:     required this.availableDaysPerWeek,
512:     required this.sessionMinutes,
513:     required this.difficulty,
514:     required this.enableNearRevision,
515:     required this.enableFarRevision,
516:     required this.nearRevisionCount,
517:     required this.farRevisionCount,
518:     required this.startAyah,
519:     required this.createdAt,
520:     this.isActive = true,
521:     this.targetUser = PlanTargetUser.adult,
522:   });
523: 
524:   /// User-given plan name, e.g. "خطتي لحفظ جزء عمّ"
525:   final String name;
526: 
527:   /// Surah range (inclusive)
528:   final int startSurahId;
529:   final int endSurahId;
530: 
531:   /// Starting ayah inside [startSurahId] (1-based)
532:   final int startAyah;
533: 
534:   /// How many new ayahs to introduce each session
535:   final int newAyahsPerDay;
536: 
537:   /// How many days per week the user can dedicate
538:   final int availableDaysPerWeek;
539: 
540:   /// Ideal session duration in minutes
541:   final int sessionMinutes;
542: 
543:   /// Affects review interval multiplier
544:   final MemorizationDifficulty difficulty;
545: 
546:   /// Whether to include near-revision and far-revision sections
547:   final bool enableNearRevision;
548:   final bool enableFarRevision;
549: 
550:   /// Max ayahs to include in each revision section
551:   final int nearRevisionCount;
552:   final int farRevisionCount;
553: 
554:   final DateTime createdAt;
555:   final bool isActive;
556:   final PlanTargetUser targetUser;
557: 
558:   bool get isForChild => targetUser == PlanTargetUser.child;
559: 
560:   /// Estimated days to finish based on **actual** surah ayah counts.
561:   int get estimatedDays {
562:     int totalAyahs = 0;
563:     for (int s = startSurahId; s <= endSurahId; s++) {
564:       totalAyahs += _surahAyahCounts[s] ?? 20;
565:     }
566:     // Subtract ayahs before startAyah in the first surah
567:     if (startAyah > 1) {
568:       totalAyahs -= (startAyah - 1);
569:     }
570:     if (newAyahsPerDay == 0) return 0;
571:     final sessionsNeeded = (totalAyahs / newAyahsPerDay).ceil();
572:     return (sessionsNeeded / (availableDaysPerWeek / 7.0)).ceil();
573:   }
574: 
575:   // RISK-4 FIX: actual ayah counts for all 114 surahs
576:   static const Map<int, int> _surahAyahCounts = {
577:     1: 7,
578:     2: 286,
579:     3: 200,
580:     4: 176,
581:     5: 120,
582:     6: 165,
583:     7: 206,
584:     8: 75,
585:     9: 129,
586:     10: 109,
587:     11: 123,
588:     12: 111,
589:     13: 43,
590:     14: 52,
591:     15: 99,
592:     16: 128,
593:     17: 111,
594:     18: 110,
595:     19: 98,
596:     20: 135,
597:     21: 112,
598:     22: 78,
599:     23: 118,
600:     24: 64,
601:     25: 77,
602:     26: 227,
603:     27: 93,
604:     28: 88,
605:     29: 69,
606:     30: 60,
607:     31: 34,
608:     32: 30,
609:     33: 73,
610:     34: 54,
611:     35: 45,
612:     36: 83,
613:     37: 182,
614:     38: 88,
615:     39: 75,
616:     40: 85,
617:     41: 54,
618:     42: 53,
619:     43: 89,
620:     44: 59,
621:     45: 37,
622:     46: 35,
623:     47: 38,
624:     48: 29,
625:     49: 18,
626:     50: 45,
627:     51: 60,
628:     52: 49,
629:     53: 62,
630:     54: 55,
631:     55: 78,
632:     56: 96,
633:     57: 29,
634:     58: 22,
635:     59: 24,
636:     60: 13,
637:     61: 14,
638:     62: 11,
639:     63: 11,
640:     64: 18,
641:     65: 12,
642:     66: 12,
643:     67: 30,
644:     68: 52,
645:     69: 52,
646:     70: 44,
647:     71: 28,
648:     72: 28,
649:     73: 20,
650:     74: 56,
651:     75: 40,
652:     76: 31,
653:     77: 50,
654:     78: 40,
655:     79: 46,
656:     80: 42,
657:     81: 29,
658:     82: 19,
659:     83: 36,
660:     84: 25,
661:     85: 22,
662:     86: 17,
663:     87: 19,
664:     88: 26,
665:     89: 30,
666:     90: 20,
667:     91: 15,
668:     92: 21,
669:     93: 11,
670:     94: 8,
671:     95: 8,
672:     96: 19,
673:     97: 5,
674:     98: 8,
675:     99: 8,
676:     100: 11,
677:     101: 11,
678:     102: 8,
679:     103: 3,
680:     104: 9,
681:     105: 5,
682:     106: 4,
683:     107: 7,
684:     108: 3,
685:     109: 6,
686:     110: 3,
687:     111: 5,
688:     112: 4,
689:     113: 5,
690:     114: 6,
691:   };
692: 
693:   CustomMemorizationPlan copyWith({
694:     String? name,
695:     int? startSurahId,
696:     int? endSurahId,
697:     int? newAyahsPerDay,
698:     int? availableDaysPerWeek,
699:     int? sessionMinutes,
700:     MemorizationDifficulty? difficulty,
701:     bool? enableNearRevision,
702:     bool? enableFarRevision,
703:     int? nearRevisionCount,
704:     int? farRevisionCount,
705:     int? startAyah,
706:     DateTime? createdAt,
707:     bool? isActive,
708:     PlanTargetUser? targetUser,
709:   }) => CustomMemorizationPlan(
710:     name: name ?? this.name,
711:     startSurahId: startSurahId ?? this.startSurahId,
712:     endSurahId: endSurahId ?? this.endSurahId,
713:     newAyahsPerDay: newAyahsPerDay ?? this.newAyahsPerDay,
714:     availableDaysPerWeek: availableDaysPerWeek ?? this.availableDaysPerWeek,
715:     sessionMinutes: sessionMinutes ?? this.sessionMinutes,
716:     difficulty: difficulty ?? this.difficulty,
717:     enableNearRevision: enableNearRevision ?? this.enableNearRevision,
718:     enableFarRevision: enableFarRevision ?? this.enableFarRevision,
719:     nearRevisionCount: nearRevisionCount ?? this.nearRevisionCount,
720:     farRevisionCount: farRevisionCount ?? this.farRevisionCount,
721:     startAyah: startAyah ?? this.startAyah,
722:     createdAt: createdAt ?? this.createdAt,
723:     isActive: isActive ?? this.isActive,
724:     targetUser: targetUser ?? this.targetUser,
725:   );
726: 
727:   @override
728:   List<Object?> get props => [
729:     name,
730:     startSurahId,
731:     endSurahId,
732:     newAyahsPerDay,
733:     availableDaysPerWeek,
734:     sessionMinutes,
735:     difficulty,
736:     enableNearRevision,
737:     enableFarRevision,
738:     nearRevisionCount,
739:     farRevisionCount,
740:     startAyah,
741:     createdAt,
742:     isActive,
743:     targetUser,
744:   ];
745: }

(End of file - total 745 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.5s)

_Thinking:_

Now let me look at the MemorizationPlusRepository and related files in parallel.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\repositories\\memorization_plus_repository.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\repositories\memorization_plus_repository.dart</path>
<type>file</type>
<content>
1: import 'package:dartz/dartz.dart';
2: import '../../../../core/error/app_failure.dart';
3: import '../entities/memorization_entities.dart';
4: 
5: abstract class MemorizationPlusRepository {
6:   // ─── Identity profile ──────────────────────────────────────────────────────
7:   Future<Either<Failure, MemorizationProfile>> getMemorizationProfile();
8:   Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
9:     MemorizationPath path,
10:   );
11:   Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian();
12:   Future<Either<Failure, PairingSession>> createGuardianPairingSession();
13:   Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
14:     String codeOrQrData,
15:   );
16:   Future<Either<Failure, PairingSession?>> refreshPairingSession();
17:   Future<Either<Failure, MemorizationProfile>> unlinkGuardian();
18:   Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
19:     bool value,
20:   );
21:   Future<Either<Failure, MemorizationProfile>> refreshChildGuardianLink();
22:   Future<Either<Failure, MemorizationProfile>> resetMemorizationIdentity();
23:   Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings();
24:   Future<Either<Failure, void>> saveSmartSettings(
25:     SmartMemorizationSettings settings,
26:   );
27: 
28:   // ─── Track selection ────────────────────────────────────────────────────────
29:   Either<Failure, MemorizationTrack?> getSelectedTrack();
30:   Future<Either<Failure, void>> saveSelectedTrack(MemorizationTrack track);
31: 
32:   // ─── Daily plan ─────────────────────────────────────────────────────────────
33:   Future<Either<Failure, DailyPlan>> generateDailyPlan({
34:     required int surahId,
35:     required int newAyahsPerDay,
36:   });
37: 
38:   Future<Either<Failure, DailyPlan?>> getCachedDailyPlan();
39:   Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan);
40: 
41:   // ─── Review records ─────────────────────────────────────────────────────────
42:   Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
43:     int surahId,
44:     int ayahNumber,
45:   );
46:   Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords();
47:   Future<Either<Failure, void>> saveReviewRecord(AyahReviewRecord record);
48: 
49:   // ─── Evaluation ─────────────────────────────────────────────────────────────
50:   Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
51:     required int surahId,
52:     required int ayahNumber,
53:     required PerformanceRating rating,
54:   });
55:   Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
56:     required int surahId,
57:     required int ayahNumber,
58:   });
59: 
60:   // ─── Kids progress ──────────────────────────────────────────────────────────
61:   Future<Either<Failure, KidsProgress>> getKidsProgress();
62:   Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress);
63:   Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
64:     required int surahId,
65:   });
66:   Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs();
67:   Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
68:     required int surahId,
69:     required int ayahNumber,
70:     required int repeatsCompleted,
71:     required int pointsEarned,
72:   });
73:   Future<Either<Failure, ParentDashboard>> getParentDashboard({
74:     required int surahId,
75:   });
76:   Future<Either<Failure, ParentSettings>> getParentSettings();
77:   Future<Either<Failure, void>> saveParentSettings(ParentSettings settings);
78:   Future<Either<Failure, bool>> verifyParentPin(String pin);
79:   Future<Either<Failure, void>> setParentPin(String pin);
80:   Future<Either<Failure, void>> resetParentAccess();
81:   Future<Either<Failure, List<ParentReward>>> saveParentReward(String title);
82:   Future<Either<Failure, List<ParentReward>>> claimParentReward(String id);
83:   Future<Either<Failure, String>> createChildLinkToken();
84:   Future<Either<Failure, void>> acceptChildLinkToken(String token);
85:   Future<Either<Failure, void>> syncKidsProgressToCloud();
86:   Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren();
87:   Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
88:     required String childUserId,
89:     required String title,
90:   });
91:   Future<Either<Failure, KidsProgress>> awardKidsPoints({
92:     required int surahId,
93:     required int ayahNumber,
94:     required int repeatsCompleted,
95:   });
96: 
97:   // ─── Custom memorization plan ──────────────────────────────────────────────
98:   Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan();
99:   Future<Either<Failure, void>> saveCustomPlan(CustomMemorizationPlan plan);
100:   Future<Either<Failure, void>> deleteCustomPlan();
101: 
102:   // ─── Parent mode toggle ───────────────────────────────────────────────────
103:   Either<Failure, bool> getIsParentMode();
104:   Future<Either<Failure, void>> setIsParentMode(bool value);
105: }

(End of file - total 105 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 6.4s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data\\datasources\\memorization_plus_local_datasource.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\data\datasources\memorization_plus_local_datasource.dart</path>
<type>file</type>
<content>
1: import 'dart:convert';
2: import 'package:isar/isar.dart';
3: import 'package:shared_preferences/shared_preferences.dart';
4: import '../models/isar_ayah_review_record.dart';
5: import '../models/memorization_models.dart';
6: 
7: abstract class MemorizationPlusLocalDatasource {
8:   // Identity profile
9:   Future<MemorizationProfileModel> getMemorizationProfile();
10:   Future<void> saveMemorizationProfile(MemorizationProfileModel profile);
11:   Future<void> clearMemorizationProfile();
12: 
13:   // Pairing
14:   Future<PairingSessionModel?> getPairingSession();
15:   Future<void> savePairingSession(PairingSessionModel session);
16:   Future<void> clearPairingSession();
17: 
18:   // Track
19:   String? getSelectedTrack();
20:   Future<void> saveSelectedTrack(String track);
21:   Future<void> clearSelectedTrack();
22: 
23:   // Review records
24:   Future<void> migrateReviewRecordsToIsarIfNeeded();
25:   Future<AyahReviewRecordModel?> getReviewRecord(int surahId, int ayahNumber);
26:   Future<List<AyahReviewRecordModel>> getAllReviewRecords();
27:   Future<void> saveReviewRecord(AyahReviewRecordModel record);
28: 
29:   // Daily plan cache
30:   Future<DailyPlanModel?> getCachedDailyPlan();
31:   Future<void> saveDailyPlan(DailyPlanModel plan);
32: 
33:   // Kids progress
34:   Future<KidsProgressModel> getKidsProgress();
35:   Future<void> saveKidsProgress(KidsProgressModel progress);
36:   Future<List<KidsSessionLogModel>> getKidsSessionLogs();
37:   Future<void> saveKidsSessionLog(KidsSessionLogModel log);
38:   Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs);
39: 
40:   // Parent dashboard
41:   Future<ParentSettingsModel> getParentSettings();
42:   Future<void> saveParentSettings(ParentSettingsModel settings);
43:   Future<List<ParentRewardModel>> getParentRewards();
44:   Future<void> saveParentRewards(List<ParentRewardModel> rewards);
45: 
46:   // Custom memorization plan
47:   Future<CustomMemorizationPlanModel?> getCustomPlan();
48:   Future<void> saveCustomPlan(CustomMemorizationPlanModel plan);
49:   Future<void> deleteCustomPlan();
50: 
51:   // Smart memorization settings
52:   Future<SmartMemorizationSettingsModel> getSmartSettings();
53:   Future<void> saveSmartSettings(SmartMemorizationSettingsModel settings);
54: 
55:   // Parent mode toggle (for adults track)
56:   bool getIsParentMode();
57:   Future<void> setIsParentMode(bool value);
58:   Future<void> clearIsParentMode();
59: }
60: 
61: class MemorizationPlusLocalDatasourceImpl
62:     implements MemorizationPlusLocalDatasource {
63:   MemorizationPlusLocalDatasourceImpl(this._prefs, {Isar? isar}) : _isar = isar;
64: 
65:   final SharedPreferences _prefs;
66:   final Isar? _isar;
67: 
68:   // ─── Key namespace (isolated from existing features) ────────────────────────
69:   static const _kProfile = 'mem_plus_profile';
70:   static const _kPairingSession = 'mem_plus_pairing_session';
71:   static const _kTrack = 'mem_plus_track';
72:   static const _kReviewPrefix = 'mem_plus_review';
73:   static const _kReviewIsarMigration = 'mem_plus_reviews_migrated_to_isar_v1';
74:   static const _kDailyPlan = 'mem_plus_daily_plan';
75:   static const _kKidsProgress = 'mem_plus_kids_progress';
76:   static const _kKidsSessionLogs = 'mem_plus_kids_session_logs';
77:   static const _kParentSettings = 'mem_plus_parent_settings';
78:   static const _kParentRewards = 'mem_plus_parent_rewards';
79:   static const _kCustomPlan = 'mem_plus_custom_plan';
80:   static const _kSmartSettings = 'mem_plus_smart_settings';
81:   static const _kIsParentMode = 'mem_plus_is_parent_mode';
82: 
83:   String _reviewKey(int surahId, int ayahNumber) =>
84:       '${_kReviewPrefix}_${surahId}_$ayahNumber';
85:   String _reviewCompositeKey(int surahId, int ayahNumber) =>
86:       '${surahId}_$ayahNumber';
87: 
88:   Map<String, dynamic>? _tryDecodeMap(String raw) {
89:     try {
90:       final decoded = jsonDecode(raw);
91:       return decoded is Map<String, dynamic> ? decoded : null;
92:     } catch (_) {
93:       return null;
94:     }
95:   }
96: 
97:   T? _tryParse<T>(String raw, T Function(Map<String, dynamic>) parser) {
98:     final decoded = _tryDecodeMap(raw);
99:     if (decoded == null) return null;
100:     try {
101:       return parser(decoded);
102:     } catch (_) {
103:       return null;
104:     }
105:   }
106: 
107:   Future<void> _setStringOrThrow(String key, String value) async {
108:     final saved = await _prefs.setString(key, value);
109:     if (!saved) {
110:       throw StateError('Failed to save value for $key');
111:     }
112:   }
113: 
114:   Future<void> _removeOrThrow(String key) async {
115:     final removed = await _prefs.remove(key);
116:     if (!removed && _prefs.containsKey(key)) {
117:       throw StateError('Failed to remove value for $key');
118:     }
119:   }
120: 
121:   // ─── Identity profile ──────────────────────────────────────────────────────
122:   @override
123:   Future<MemorizationProfileModel> getMemorizationProfile() async {
124:     final raw = _prefs.getString(_kProfile);
125:     if (raw == null) return MemorizationProfileModel.empty();
126:     return _tryParse(raw, MemorizationProfileModel.fromJson) ??
127:         MemorizationProfileModel.empty();
128:   }
129: 
130:   @override
131:   Future<void> saveMemorizationProfile(MemorizationProfileModel profile) =>
132:       _setStringOrThrow(_kProfile, jsonEncode(profile.toJson()));
133: 
134:   @override
135:   Future<void> clearMemorizationProfile() => _removeOrThrow(_kProfile);
136: 
137:   // ─── Pairing ────────────────────────────────────────────────────────────────
138:   @override
139:   Future<PairingSessionModel?> getPairingSession() async {
140:     final raw = _prefs.getString(_kPairingSession);
141:     if (raw == null) return null;
142:     return _tryParse(raw, PairingSessionModel.fromJson);
143:   }
144: 
145:   @override
146:   Future<void> savePairingSession(PairingSessionModel session) =>
147:       _setStringOrThrow(_kPairingSession, jsonEncode(session.toJson()));
148: 
149:   @override
150:   Future<void> clearPairingSession() => _removeOrThrow(_kPairingSession);
151: 
152:   // ─── Track ──────────────────────────────────────────────────────────────────
153:   @override
154:   String? getSelectedTrack() => _prefs.getString(_kTrack);
155: 
156:   @override
157:   Future<void> saveSelectedTrack(String track) =>
158:       _setStringOrThrow(_kTrack, track);
159: 
160:   @override
161:   Future<void> clearSelectedTrack() => _removeOrThrow(_kTrack);
162: 
163:   // ─── Review records ─────────────────────────────────────────────────────────
164:   @override
165:   Future<void> migrateReviewRecordsToIsarIfNeeded() async {
166:     final isar = _isar;
167:     if (isar == null || (_prefs.getBool(_kReviewIsarMigration) ?? false)) {
168:       return;
169:     }
170: 
171:     final legacyKeys = _legacyReviewKeys();
172:     if (legacyKeys.isEmpty) {
173:       await _prefs.setBool(_kReviewIsarMigration, true);
174:       return;
175:     }
176: 
177:     final records = legacyKeys
178:         .map((key) {
179:           final raw = _prefs.getString(key);
180:           return raw == null
181:               ? null
182:               : _tryParse(raw, AyahReviewRecordModel.fromJson);
183:         })
184:         .whereType<AyahReviewRecordModel>()
185:         .toList();
186: 
187:     await isar.writeTxn(() async {
188:       await isar.isarAyahReviewRecords.putAll(
189:         records.map(IsarAyahReviewRecord.fromModel).toList(),
190:       );
191:     });
192: 
193:     for (final key in legacyKeys) {
194:       await _removeOrThrow(key);
195:     }
196:     await _prefs.setBool(_kReviewIsarMigration, true);
197:   }
198: 
199:   @override
200:   Future<AyahReviewRecordModel?> getReviewRecord(
201:     int surahId,
202:     int ayahNumber,
203:   ) async {
204:     final isar = _isar;
205:     if (isar != null) {
206:       await migrateReviewRecordsToIsarIfNeeded();
207:       final record = await isar.isarAyahReviewRecords.getByCompositeKey(
208:         _reviewCompositeKey(surahId, ayahNumber),
209:       );
210:       return record?.toModel();
211:     }
212: 
213:     final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
214:     if (raw == null) return null;
215:     return _tryParse(raw, AyahReviewRecordModel.fromJson);
216:   }
217: 
218:   @override
219:   Future<List<AyahReviewRecordModel>> getAllReviewRecords() async {
220:     final isar = _isar;
221:     if (isar != null) {
222:       await migrateReviewRecordsToIsarIfNeeded();
223:       final records = await isar.isarAyahReviewRecords.where().findAll();
224:       return records.map((record) => record.toModel()).toList();
225:     }
226: 
227:     return _legacyReviewKeys()
228:         .map((k) {
229:           final raw = _prefs.getString(k);
230:           return raw == null
231:               ? null
232:               : _tryParse(raw, AyahReviewRecordModel.fromJson);
233:         })
234:         .whereType<AyahReviewRecordModel>()
235:         .toList();
236:   }
237: 
238:   @override
239:   Future<void> saveReviewRecord(AyahReviewRecordModel record) async {
240:     final isar = _isar;
241:     if (isar != null) {
242:       await migrateReviewRecordsToIsarIfNeeded();
243:       await isar.writeTxn(() async {
244:         await isar.isarAyahReviewRecords.put(
245:           IsarAyahReviewRecord.fromModel(record),
246:         );
247:       });
248:       return;
249:     }
250: 
251:     await _setStringOrThrow(
252:       _reviewKey(record.surahId, record.ayahNumber),
253:       jsonEncode(record.toJson()),
254:     );
255:   }
256: 
257:   List<String> _legacyReviewKeys() {
258:     return _prefs
259:         .getKeys()
260:         .where((key) => key.startsWith('${_kReviewPrefix}_'))
261:         .toList();
262:   }
263: 
264:   // ─── Daily plan cache ────────────────────────────────────────────────────────
265:   @override
266:   Future<DailyPlanModel?> getCachedDailyPlan() async {
267:     final raw = _prefs.getString(_kDailyPlan);
268:     if (raw == null) return null;
269:     return _tryParse(raw, DailyPlanModel.fromJson);
270:   }
271: 
272:   @override
273:   Future<void> saveDailyPlan(DailyPlanModel plan) =>
274:       _setStringOrThrow(_kDailyPlan, jsonEncode(plan.toJson()));
275: 
276:   // ─── Kids progress ───────────────────────────────────────────────────────────
277:   @override
278:   Future<KidsProgressModel> getKidsProgress() async {
279:     final raw = _prefs.getString(_kKidsProgress);
280:     if (raw == null) return const KidsProgressModel.empty();
281:     return _tryParse(raw, KidsProgressModel.fromJson) ??
282:         const KidsProgressModel.empty();
283:   }
284: 
285:   @override
286:   Future<void> saveKidsProgress(KidsProgressModel progress) =>
287:       _setStringOrThrow(_kKidsProgress, jsonEncode(progress.toJson()));
288: 
289:   @override
290:   Future<List<KidsSessionLogModel>> getKidsSessionLogs() async {
291:     final raw = _prefs.getString(_kKidsSessionLogs);
292:     if (raw == null) return const [];
293:     try {
294:       final decoded = jsonDecode(raw);
295:       if (decoded is! List) return const [];
296:       return decoded
297:           .whereType<Map<String, dynamic>>()
298:           .map(KidsSessionLogModel.fromJson)
299:           .toList();
300:     } catch (_) {
301:       return const [];
302:     }
303:   }
304: 
305:   @override
306:   Future<void> saveKidsSessionLog(KidsSessionLogModel log) async {
307:     final logs = await getKidsSessionLogs();
308:     final next = [...logs.where((item) => item.id != log.id), log]
309:       ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
310:     await saveKidsSessionLogs(next);
311:   }
312: 
313:   @override
314:   Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) =>
315:       _setStringOrThrow(
316:         _kKidsSessionLogs,
317:         jsonEncode(logs.map((log) => log.toJson()).toList()),
318:       );
319: 
320:   // ─── Parent dashboard ──────────────────────────────────────────────────────
321:   @override
322:   Future<ParentSettingsModel> getParentSettings() async {
323:     final raw = _prefs.getString(_kParentSettings);
324:     if (raw == null) return const ParentSettingsModel.defaults();
325:     return _tryParse(raw, ParentSettingsModel.fromJson) ??
326:         const ParentSettingsModel.defaults();
327:   }
328: 
329:   @override
330:   Future<void> saveParentSettings(ParentSettingsModel settings) =>
331:       _setStringOrThrow(_kParentSettings, jsonEncode(settings.toJson()));
332: 
333:   @override
334:   Future<List<ParentRewardModel>> getParentRewards() async {
335:     final raw = _prefs.getString(_kParentRewards);
336:     if (raw == null) return const [];
337:     try {
338:       final decoded = jsonDecode(raw);
339:       if (decoded is! List) return const [];
340:       return decoded
341:           .whereType<Map<String, dynamic>>()
342:           .map(ParentRewardModel.fromJson)
343:           .toList();
344:     } catch (_) {
345:       return const [];
346:     }
347:   }
348: 
349:   @override
350:   Future<void> saveParentRewards(List<ParentRewardModel> rewards) =>
351:       _setStringOrThrow(
352:         _kParentRewards,
353:         jsonEncode(rewards.map((reward) => reward.toJson()).toList()),
354:       );
355: 
356:   // ─── Custom memorization plan ───────────────────────────────────────────────
357:   @override
358:   Future<CustomMemorizationPlanModel?> getCustomPlan() async {
359:     final raw = _prefs.getString(_kCustomPlan);
360:     if (raw == null) return null;
361:     return _tryParse(raw, CustomMemorizationPlanModel.fromJson);
362:   }
363: 
364:   @override
365:   Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) =>
366:       _setStringOrThrow(_kCustomPlan, jsonEncode(plan.toJson()));
367: 
368:   @override
369:   Future<void> deleteCustomPlan() => _removeOrThrow(_kCustomPlan);
370: 
371:   // ─── Smart memorization settings ───────────────────────────────────────────
372:   @override
373:   Future<SmartMemorizationSettingsModel> getSmartSettings() async {
374:     final raw = _prefs.getString(_kSmartSettings);
375:     if (raw == null) {
376:       final customPlan = await getCustomPlan();
377:       return SmartMemorizationSettingsModel(customPlan: customPlan);
378:     }
379:     final parsed = _tryParse(raw, SmartMemorizationSettingsModel.fromJson);
380:     if (parsed != null) return parsed;
381:     return const SmartMemorizationSettingsModel();
382:   }
383: 
384:   @override
385:   Future<void> saveSmartSettings(SmartMemorizationSettingsModel settings) =>
386:       _setStringOrThrow(_kSmartSettings, jsonEncode(settings.toJson()));
387: 
388:   // ─── Parent mode toggle ─────────────────────────────────────────────────────
389:   @override
390:   bool getIsParentMode() => _prefs.getBool(_kIsParentMode) ?? false;
391: 
392:   @override
393:   Future<void> setIsParentMode(bool value) async {
394:     final saved = await _prefs.setBool(_kIsParentMode, value);
395:     if (!saved) {
396:       throw StateError('Failed to save parent mode');
397:     }
398:   }
399: 
400:   @override
401:   Future<void> clearIsParentMode() => _removeOrThrow(_kIsParentMode);
402: }

(End of file - total 402 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.8s)

_Thinking:_

Let me now look at the repository implementation and key pages like path selection, daily plan, kids journey, etc.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data\\repositories"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\data\repositories</path>
<type>directory</type>
<entries>
memorization_plus_repository_impl.dart

(1 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\pages\\path_selection_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\pages\path_selection_page.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: 
3: import 'package:flutter/material.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import 'package:go_router/go_router.dart';
6: 
7: import '../../../../core/theme/app_colors.dart';
8: import '../../../../core/theme/app_typography.dart';
9: import '../../../../core/widgets/app_scaffold.dart';
10: import '../../../../core/widgets/error_info_banner.dart';
11: import '../../../../core/router/app_router.dart';
12: import '../../../../core/di/injection.dart';
13: import '../../domain/entities/memorization_entities.dart';
14: import '../cubits/memorization_identity_cubit.dart';
15: import '../../../../core/extensions/context_extensions.dart';
16: 
17: class PathSelectionPage extends StatelessWidget {
18:   const PathSelectionPage({super.key});
19: 
20:   @override
21:   Widget build(BuildContext context) {
22:     return BlocProvider(
23:       create: (context) => getIt<MemorizationIdentityCubit>(),
24:       child: const _PathSelectionView(),
25:     );
26:   }
27: }
28: 
29: class _PathSelectionView extends StatelessWidget {
30:   const _PathSelectionView();
31: 
32:   @override
33:   Widget build(BuildContext context) {
34:     return AppScaffold(
35:       title: context.l10n.memorizationPathTitle,
36:       body: BlocConsumer<MemorizationIdentityCubit, MemorizationIdentityState>(
37:         listener: (context, state) {
38:           if (state is MemorizationIdentitySuccess) {
39:             final profile = state.profile;
40:             if (profile.isAdult) {
41:               context.go(AppRoutes.memorizationPlusCustomPlan);
42:             } else if (profile.isChild) {
43:               context.go(AppRoutes.memorizationPlusGuardianLinking);
44:             }
45:           }
46:         },
47:         builder: (context, state) {
48:           final isLoading = state is MemorizationIdentityLoading;
49:           final isDark = context.isDark;
50: 
51:           return Padding(
52:             padding: const EdgeInsets.symmetric(
53:               horizontal: 24.0,
54:               vertical: 32.0,
55:             ),
56:             child: Column(
57:               crossAxisAlignment: CrossAxisAlignment.stretch,
58:               children: [
59:                 Text(
60:                   context.l10n.memorizationPathQuestion,
61:                   style: AppTypography.headlineMedium,
62:                   textAlign: TextAlign.center,
63:                 ),
64:                 const SizedBox(height: 16),
65:                 Text(
66:                   context.l10n.memorizationPathDescription,
67:                   style: AppTypography.bodyMedium.copyWith(
68:                     color: isDark
69:                         ? AppColors.darkTextSecondary
70:                         : AppColors.lightTextSecondary,
71:                   ),
72:                   textAlign: TextAlign.center,
73:                 ),
74:                 if (state is MemorizationIdentityError) ...[
75:                   const SizedBox(height: 20),
76:                   ErrorInfoBanner(
77:                     type: ErrorInfoBannerType.error,
78:                     title: 'تعذر حفظ اختيارك',
79:                     message: state.message,
80:                   ),
81:                 ],
82:                 const SizedBox(height: 48),
83:                 _buildPathCard(
84:                   context: context,
85:                   title: context.l10n.memorizationPathAdultsTitle,
86:                   description: context.l10n.memorizationPathAdultsDesc,
87:                   icon: Icons.person_outline,
88:                   color: AppColors.primary,
89:                   isLoading: isLoading,
90:                   onTap: () {
91:                     _confirmPathSelection(
92:                       context,
93:                       path: MemorizationPath.adult,
94:                       title: context.l10n.memorizationPathAdultsTitle,
95:                       description: context.l10n.memorizationPathAdultsDesc,
96:                     );
97:                   },
98:                 ),
99:                 const SizedBox(height: 24),
100:                 _buildPathCard(
101:                   context: context,
102:                   title: context.l10n.memorizationPathKidsTitle,
103:                   description: context.l10n.memorizationPathKidsDesc,
104:                   icon: Icons.child_care,
105:                   color: AppColors.gold,
106:                   isLoading: isLoading,
107:                   onTap: () {
108:                     _confirmPathSelection(
109:                       context,
110:                       path: MemorizationPath.child,
111:                       title: context.l10n.memorizationPathKidsTitle,
112:                       description: context.l10n.memorizationPathKidsDesc,
113:                     );
114:                   },
115:                 ),
116:                 if (isLoading) ...[
117:                   const SizedBox(height: 32),
118:                   const Center(child: CircularProgressIndicator()),
119:                 ],
120:               ],
121:             ),
122:           );
123:         },
124:       ),
125:     );
126:   }
127: 
128:   Future<void> _confirmPathSelection(
129:     BuildContext context, {
130:     required MemorizationPath path,
131:     required String title,
132:     required String description,
133:   }) async {
134:     final confirmed = await showModalBottomSheet<bool>(
135:       context: context,
136:       showDragHandle: true,
137:       builder: (sheetContext) => SafeArea(
138:         child: Padding(
139:           padding: const EdgeInsets.all(24),
140:           child: Column(
141:             mainAxisSize: MainAxisSize.min,
142:             crossAxisAlignment: CrossAxisAlignment.stretch,
143:             children: [
144:               Text(
145:                 'ماذا سيحدث بعد ذلك؟',
146:                 style: AppTypography.headlineSmall.copyWith(
147:                   fontFamily: 'Amiri',
148:                 ),
149:                 textAlign: TextAlign.center,
150:               ),
151:               const SizedBox(height: 12),
152:               Text(
153:                 '$title\n$description',
154:                 style: AppTypography.bodyMedium.copyWith(height: 1.6),
155:                 textAlign: TextAlign.center,
156:               ),
157:               const SizedBox(height: 12),
158:               Row(
159:                 children: [
160:                   const Icon(Icons.info_outline_rounded, size: 18),
161:                   const SizedBox(width: 8),
162:                   Expanded(
163:                     child: Text(
164:                       'يمكن تغييره من الإعدادات لاحقاً بدون فقدان تقدمك.',
165:                       style: AppTypography.bodySmall,
166:                     ),
167:                   ),
168:                 ],
169:               ),
170:               const SizedBox(height: 20),
171:               FilledButton(
172:                 onPressed: () => Navigator.pop(sheetContext, true),
173:                 child: const Text('تأكيد'),
174:               ),
175:               TextButton(
176:                 onPressed: () => Navigator.pop(sheetContext, false),
177:                 child: const Text('رجوع'),
178:               ),
179:             ],
180:           ),
181:         ),
182:       ),
183:     );
184:     if (confirmed == true && context.mounted) {
185:       unawaited(context.read<MemorizationIdentityCubit>().selectPath(path));
186:     }
187:   }
188: 
189:   Widget _buildPathCard({
190:     required BuildContext context,
191:     required String title,
192:     required String description,
193:     required IconData icon,
194:     required Color color,
195:     required bool isLoading,
196:     required VoidCallback onTap,
197:   }) {
198:     final isDark = context.isDark;
199:     final textColor = isDark
200:         ? AppColors.darkTextPrimary
201:         : AppColors.lightTextPrimary;
202:     final secondaryTextColor = isDark
203:         ? AppColors.darkTextSecondary
204:         : AppColors.lightTextSecondary;
205: 
206:     return GestureDetector(
207:       onTap: isLoading ? null : onTap,
208:       child: Container(
209:         decoration: BoxDecoration(
210:           color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
211:           borderRadius: BorderRadius.circular(24),
212:           border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
213:           boxShadow: [
214:             BoxShadow(
215:               color: color.withValues(alpha: 0.1),
216:               blurRadius: 15,
217:               offset: const Offset(0, 8),
218:             ),
219:           ],
220:         ),
221:         padding: const EdgeInsets.all(24),
222:         child: Row(
223:           children: [
224:             Container(
225:               padding: const EdgeInsets.all(16),
226:               decoration: BoxDecoration(
227:                 color: color.withValues(alpha: 0.1),
228:                 shape: BoxShape.circle,
229:               ),
230:               child: Icon(icon, size: 40, color: color),
231:             ),
232:             const SizedBox(width: 24),
233:             Expanded(
234:               child: Column(
235:                 crossAxisAlignment: CrossAxisAlignment.start,
236:                 children: [
237:                   Text(
238:                     title,
239:                     style: AppTypography.titleLarge.copyWith(color: textColor),
240:                   ),
241:                   const SizedBox(height: 8),
242:                   Text(
243:                     description,
244:                     style: AppTypography.bodySmall.copyWith(
245:                       color: secondaryTextColor,
246:                     ),
247:                   ),
248:                 ],
249:               ),
250:             ),
251:             const SizedBox(width: 8),
252:             Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 20),
253:           ],
254:         ),
255:       ),
256:     );
257:   }
258: }

(End of file - total 258 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\cubits\\track_selection_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\cubits\track_selection_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'package:equatable/equatable.dart';
3: import 'package:flutter_bloc/flutter_bloc.dart';
4: import '../../domain/entities/memorization_entities.dart';
5: import '../../domain/repositories/memorization_plus_repository.dart';
6: 
7: part 'track_selection_state.dart';
8: 
9: class TrackSelectionCubit extends Cubit<TrackSelectionState> {
10:   TrackSelectionCubit(this._repository) : super(const TrackSelectionInitial());
11:   final MemorizationPlusRepository _repository;
12: 
13:   Future<void> load() async {
14:     final result = await _repository.getMemorizationProfile();
15:     result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
16:   }
17: 
18:   Future<void> selectTrack(MemorizationTrack track) async {
19:     final path = track == MemorizationTrack.kids
20:         ? MemorizationPath.child
21:         : MemorizationPath.adult;
22:     await selectPath(path);
23:   }
24: 
25:   Future<void> selectPath(MemorizationPath path) async {
26:     emit(const TrackSelectionSaving());
27:     final result = await _repository.selectMemorizationPath(path);
28:     result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
29:   }
30: 
31:   Future<void> refreshChildGuardianLink() async {
32:     final result = await _repository.refreshChildGuardianLink();
33:     result.fold((f) => emit(TrackSelectionError(f.message)), _emitProfileState);
34:   }
35: 
36:   void _emitProfileState(MemorizationProfile profile) {
37:     emit(TrackSelectionLoaded(profile: profile));
38:     if (!profile.hasSelectedPath) {
39:       emit(const TrackSelectionNeedsPath());
40:     } else if (profile.isAdult) {
41:       emit(TrackSelectionAdultReady(profile: profile));
42:     } else if (profile.needsGuardianOnboarding) {
43:       emit(TrackSelectionGuardianOnboardingRequired(profile: profile));
44:     } else {
45:       emit(TrackSelectionChildReady(profile: profile));
46:     }
47:   }
48: 
49:   /// BUG-9 FIX: get the last reviewed surahId so navigation can resume from
50:   /// where the user left off instead of always starting from surah 1.
51:   Future<int> getLastActiveSurahId() async {
52:     final result = await _repository.getAllReviewRecords();
53:     final records = result.fold((_) => <AyahReviewRecord>[], (r) => r);
54:     if (records.isEmpty) return 1;
55:     // Find the surah with the most recent review (using correct field name)
56:     final sorted = [...records]
57:       ..sort((a, b) => b.lastReviewedAt.compareTo(a.lastReviewedAt));
58:     return sorted.first.surahId;
59:   }
60: }
61: 

(End of file - total 61 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 7.3s)

_Thinking:_

Now let me look at the daily_plan_page, kids_gamified_home_page, and the hifz_session_page to understand all the screens.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\pages\\daily_plan_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\pages\daily_plan_page.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: 
3: import 'package:flutter/material.dart';
4: import 'package:flutter/services.dart';
5: import 'package:flutter_bloc/flutter_bloc.dart';
6: import 'package:go_router/go_router.dart';
7: import 'package:percent_indicator/percent_indicator.dart';
8: import 'package:shared_preferences/shared_preferences.dart';
9: 
10: import '../../../../core/constants/app_spacing.dart';
11: import '../../../../core/di/injection.dart';
12: import '../../../../core/extensions/context_extensions.dart';
13: import '../../../../core/theme/app_colors.dart';
14: import '../../../../core/theme/app_typography.dart';
15: import '../../../../core/widgets/ayah_listen_button.dart';
16: import '../../../../core/widgets/qcf_hifz_verse_view.dart';
17: import '../../../../core/widgets/state_widgets.dart';
18: import '../../../../core/router/app_router.dart';
19: import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
20: import '../../domain/entities/memorization_entities.dart';
21: import '../cubits/daily_plan_cubit.dart';
22: 
23: class DailyPlanPage extends StatelessWidget {
24:   const DailyPlanPage({super.key, required this.surahId});
25:   final int surahId;
26: 
27:   @override
28:   Widget build(BuildContext context) {
29:     return BlocProvider(
30:       create: (_) => getIt<DailyPlanCubit>()..load(surahId: surahId),
31:       child: _DailyPlanView(surahId: surahId),
32:     );
33:   }
34: }
35: 
36: class _DailyPlanView extends StatelessWidget {
37:   const _DailyPlanView({required this.surahId});
38:   final int surahId;
39: 
40:   @override
41:   Widget build(BuildContext context) {
42:     final isDark = context.isDark;
43:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
44: 
45:     return BlocConsumer<DailyPlanCubit, DailyPlanState>(
46:       listener: (context, state) {
47:         if (state is DailyPlanLoaded && state.newAwards.isNotEmpty) {
48:           HapticFeedback.heavyImpact();
49:           unawaited(showCertificateCelebrationDialog(context, state.newAwards));
50:           return;
51:         }
52: 
53:         // UX-011: Show celebration when all items are completed
54:         if (state is DailyPlanLoaded &&
55:             state.plan.totalItems > 0 &&
56:             state.plan.completedCount >= state.plan.totalItems &&
57:             state.lastEvaluatedAyah != null) {
58:           HapticFeedback.heavyImpact();
59:           _showCompletionCelebration(context, isDark, primary, state.plan);
60:         }
61:       },
62:       builder: (context, state) {
63:         DailyPlan? currentPlan;
64:         if (state is DailyPlanLoaded) currentPlan = state.plan;
65:         if (state is DailyPlanEvaluating) currentPlan = state.plan;
66: 
67:         return Scaffold(
68:           backgroundColor: isDark
69:               ? AppColors.darkBackground
70:               : AppColors.lightBackground,
71:           floatingActionButton:
72:               currentPlan != null && currentPlan.totalItems > 0
73:               ? FloatingActionButton.extended(
74:                   onPressed: () {
75:                     // Extract all ayahs for today
76:                     final ayahs = [
77:                       ...currentPlan!.newAyahs,
78:                       ...currentPlan.nearRevision,
79:                       ...currentPlan.farRevision,
80:                     ];
81:                     final numbers = ayahs
82:                         .map((a) => a.ayahNumber)
83:                         .toSet()
84:                         .toList();
85:                     if (numbers.isNotEmpty) {
86:                       final quizLocation = Uri(
87:                         path: '/memorization-plus/quiz',
88:                         queryParameters: {
89:                           'surahId': '$surahId',
90:                           'ayahNumbers': numbers.join(','),
91:                         },
92:                       ).toString();
93:                       context.push(quizLocation).then((_) {
94:                         // Refresh plan after quiz
95:                         if (context.mounted) {
96:                           context.read<DailyPlanCubit>().refresh(
97:                             surahId: surahId,
98:                           );
99:                         }
100:                       });
101:                     }
102:                   },
103:                   backgroundColor: primary,
104:                   icon: const Icon(Icons.quiz_rounded, color: Colors.white),
105:                   label: Text(
106:                     'اختبر حفظك',
107:                     style: AppTypography.labelLarge.copyWith(
108:                       color: Colors.white,
109:                       fontFamily: 'Amiri',
110:                       fontWeight: FontWeight.bold,
111:                     ),
112:                   ),
113:                 )
114:               : null,
115:           body: () {
116:             if (state is DailyPlanLoading || state is DailyPlanInitial) {
117:               return const Center(child: LoadingWidget());
118:             }
119:             if (state is DailyPlanError) {
120:               return ErrorStateWidget(
121:                 message: state.message,
122:                 onRetry: () =>
123:                     context.read<DailyPlanCubit>().load(surahId: surahId),
124:               );
125:             }
126:             if (state is DailyPlanLoaded || state is DailyPlanEvaluating) {
127:               final plan = currentPlan!;
128:               final evaluatingAyah = state is DailyPlanEvaluating
129:                   ? state.evaluatingAyah
130:                   : null;
131:               final lastRating = state is DailyPlanLoaded
132:                   ? state.lastRating
133:                   : null;
134:               final lastEvaluated = state is DailyPlanLoaded
135:                   ? state.lastEvaluatedAyah
136:                   : null;
137: 
138:               return CustomScrollView(
139:                 slivers: [
140:                   _buildAppBar(context, isDark, primary, plan),
141:                   if (plan.totalItems == 0)
142:                     SliverFillRemaining(child: _EmptyPlan(isDark: isDark))
143:                   else ...[
144:                     // Progress header
145:                     SliverToBoxAdapter(
146:                       child: _PlanProgressHeader(
147:                         plan: plan,
148:                         isDark: isDark,
149:                         primary: primary,
150:                       ),
151:                     ),
152: 
153:                     // Rating result snackbar
154:                     if (lastRating != null && lastEvaluated != null)
155:                       SliverToBoxAdapter(
156:                         child: _RatingBanner(
157:                           rating: lastRating,
158:                           ayahNumber: lastEvaluated,
159:                           isDark: isDark,
160:                         ),
161:                       ),
162: 
163:                     // New Ayahs
164:                     if (plan.newAyahs.isNotEmpty)
165:                       _AyahSection(
166:                         label: '📖 آيات جديدة للحفظ',
167:                         ayahs: plan.newAyahs,
168:                         plan: plan,
169:                         isDark: isDark,
170:                         primary: primary,
171:                         evaluatingAyah: evaluatingAyah,
172:                         sectionColor: primary,
173:                       ),
174: 
175:                     // Near revision
176:                     if (plan.nearRevision.isNotEmpty)
177:                       _AyahSection(
178:                         label: '🔄 مراجعة قريبة (آخر ٥ أيام)',
179:                         ayahs: plan.nearRevision,
180:                         plan: plan,
181:                         isDark: isDark,
182:                         primary: const Color(0xFF2D8E4C),
183:                         evaluatingAyah: evaluatingAyah,
184:                         sectionColor: const Color(0xFF2D8E4C),
185:                       ),
186: 
187:                     // Far revision
188:                     if (plan.farRevision.isNotEmpty)
189:                       _AyahSection(
190:                         label: '📅 مراجعة بعيدة',
191:                         ayahs: plan.farRevision,
192:                         plan: plan,
193:                         isDark: isDark,
194:                         primary: const Color(0xFFFF8C42),
195:                         evaluatingAyah: evaluatingAyah,
196:                         sectionColor: const Color(0xFFFF8C42),
197:                       ),
198: 
199:                     const SliverToBoxAdapter(child: SizedBox(height: 120)),
200:                   ],
201:                 ],
202:               );
203:             }
204:             return const SizedBox.shrink();
205:           }(),
206:         );
207:       },
208:     );
209:   }
210: 
211:   void _showCompletionCelebration(
212:     BuildContext context,
213:     bool isDark,
214:     Color primary,
215:     DailyPlan plan,
216:   ) {
217:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
218:     final textPrimary = isDark
219:         ? AppColors.darkTextPrimary
220:         : AppColors.lightTextPrimary;
221:     final textSecondary = isDark
222:         ? AppColors.darkTextSecondary
223:         : AppColors.lightTextSecondary;
224: 
225:     showModalBottomSheet(
226:       context: context,
227:       useRootNavigator: true,
228:       backgroundColor: surface,
229:       shape: const RoundedRectangleBorder(
230:         borderRadius: BorderRadius.vertical(
231:           top: Radius.circular(AppSpacing.radiusXl),
232:         ),
233:       ),
234:       builder: (_) => Padding(
235:         padding: const EdgeInsets.all(AppSpacing.xl),
236:         child: Column(
237:           mainAxisSize: MainAxisSize.min,
238:           children: [
239:             Container(
240:               width: 40,
241:               height: 4,
242:               decoration: BoxDecoration(
243:                 color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
244:                 borderRadius: BorderRadius.circular(2),
245:               ),
246:             ),
247:             const SizedBox(height: AppSpacing.xl),
248:             const Text('🎉', style: TextStyle(fontSize: 56)),
249:             const SizedBox(height: AppSpacing.md),
250:             Text(
251:               'ما شاء الله! أكملت خطتك اليومية',
252:               style: AppTypography.headlineSmall.copyWith(
253:                 color: textPrimary,
254:                 fontFamily: 'Amiri',
255:               ),
256:               textAlign: TextAlign.center,
257:             ),
258:             const SizedBox(height: AppSpacing.sm),
259:             Text(
260:               'أتممت ${plan.totalItems} عناصر بنجاح.\nثابر على هذا المستوى!',
261:               style: AppTypography.bodyMedium.copyWith(
262:                 color: textSecondary,
263:                 fontFamily: 'Amiri',
264:                 height: 1.6,
265:               ),
266:               textAlign: TextAlign.center,
267:             ),
268:             const SizedBox(height: AppSpacing.lg),
269:             Row(
270:               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
271:               children: [
272:                 _CelebrationStat(
273:                   icon: Icons.auto_stories_rounded,
274:                   label: 'آيات جديدة',
275:                   value: '${plan.newAyahs.length}',
276:                   color: primary,
277:                   isDark: isDark,
278:                 ),
279:                 _CelebrationStat(
280:                   icon: Icons.replay_rounded,
281:                   label: 'مراجعة',
282:                   value:
283:                       '${plan.nearRevision.length + plan.farRevision.length}',
284:                   color: const Color(0xFF2D8E4C),
285:                   isDark: isDark,
286:                 ),
287:               ],
288:             ),
289:             const SizedBox(height: AppSpacing.xl),
290:             SizedBox(
291:               width: double.infinity,
292:               height: 48,
293:               child: FilledButton(
294:                 onPressed: () => Navigator.pop(context),
295:                 style: FilledButton.styleFrom(
296:                   backgroundColor: primary,
297:                   foregroundColor: Colors.white,
298:                   shape: RoundedRectangleBorder(
299:                     borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
300:                   ),
301:                 ),
302:                 child: Text(
303:                   'بارك الله فيك ✨',
304:                   style: AppTypography.titleMedium.copyWith(
305:                     color: Colors.white,
306:                     fontFamily: 'Amiri',
307:                     fontWeight: FontWeight.bold,
308:                   ),
309:                 ),
310:               ),
311:             ),
312:             const SizedBox(height: AppSpacing.md),
313:           ],
314:         ),
315:       ),
316:     );
317:   }
318: 
319:   SliverAppBar _buildAppBar(
320:     BuildContext context,
321:     bool isDark,
322:     Color primary,
323:     DailyPlan plan,
324:   ) {
325:     return SliverAppBar(
326:       pinned: true,
327:       expandedHeight: 130,
328:       backgroundColor: isDark
329:           ? AppColors.darkBackground
330:           : AppColors.lightBackground,
331:       elevation: 0,
332:       leading: IconButton(
333:         icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
334:         onPressed: () {
335:           if (context.canPop()) {
336:             context.pop();
337:           } else {
338:             context.go('/');
339:           }
340:         },
341:       ),
342:       actions: [
343:         IconButton(
344:           icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
345:           tooltip: 'إعدادات مسار الحفظ الذكي',
346:           onPressed: () => context.push(AppRoutes.memorizationPlusCustomPlan),
347:         ),
348:         IconButton(
349:           icon: const Icon(Icons.refresh_rounded, color: Colors.white),
350:           tooltip: 'تحديث الخطة',
351:           onPressed: () =>
352:               context.read<DailyPlanCubit>().refresh(surahId: surahId),
353:         ),
354:       ],
355:       flexibleSpace: FlexibleSpaceBar(
356:         collapseMode: CollapseMode.pin,
357:         background: Container(
358:           decoration: BoxDecoration(
359:             gradient: isDark
360:                 ? AppColors.heroGradientDark
361:                 : AppColors.heroGradientLight,
362:           ),
363:           child: SafeArea(
364:             child: Padding(
365:               padding: const EdgeInsets.fromLTRB(
366:                 AppSpacing.pagePadding,
367:                 AppSpacing.lg,
368:                 AppSpacing.pagePadding,
369:                 AppSpacing.md,
370:               ),
371:               child: Column(
372:                 crossAxisAlignment: CrossAxisAlignment.start,
373:                 children: [
374:                   Text(
375:                     'خطتك اليومية',
376:                     style: AppTypography.headlineLarge.copyWith(
377:                       color: Colors.white,
378:                       fontFamily: 'Amiri',
379:                     ),
380:                   ),
381:                   Text(
382:                     '${plan.totalItems} عنصر • ${plan.completedCount} مكتمل',
383:                     style: AppTypography.bodySmall.copyWith(
384:                       color: Colors.white70,
385:                     ),
386:                   ),
387:                 ],
388:               ),
389:             ),
390:           ),
391:         ),
392:       ),
393:     );
394:   }
395: }
396: 
397: // ─── Plan Progress Header ─────────────────────────────────────────────────────
398: 
399: class _PlanProgressHeader extends StatelessWidget {
400:   const _PlanProgressHeader({
401:     required this.plan,
402:     required this.isDark,
403:     required this.primary,
404:   });
405:   final DailyPlan plan;
406:   final bool isDark;
407:   final Color primary;
408: 
409:   @override
410:   Widget build(BuildContext context) {
411:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
412:     return Container(
413:       margin: const EdgeInsets.all(AppSpacing.pagePadding),
414:       padding: const EdgeInsets.all(AppSpacing.lg),
415:       decoration: BoxDecoration(
416:         color: surface,
417:         borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
418:         boxShadow: [
419:           BoxShadow(
420:             color: primary.withValues(alpha: 0.08),
421:             blurRadius: 16,
422:             offset: const Offset(0, 4),
423:           ),
424:         ],
425:       ),
426:       child: Row(
427:         children: [
428:           CircularPercentIndicator(
429:             radius: 36,
430:             lineWidth: 5,
431:             percent: plan.progress,
432:             center: Text(
433:               '${(plan.progress * 100).toInt()}%',
434:               style: AppTypography.labelSmall.copyWith(
435:                 color: primary,
436:                 fontWeight: FontWeight.w700,
437:               ),
438:             ),
439:             progressColor: primary,
440:             backgroundColor: primary.withValues(alpha: 0.1),
441:             circularStrokeCap: CircularStrokeCap.round,
442:             animation: true,
443:           ),
444:           const SizedBox(width: AppSpacing.md),
445:           Expanded(
446:             child: Column(
447:               crossAxisAlignment: CrossAxisAlignment.start,
448:               children: [
449:                 Text(
450:                   '${plan.completedCount} من ${plan.totalItems}',
451:                   style: AppTypography.titleLarge.copyWith(
452:                     color: primary,
453:                     fontWeight: FontWeight.w700,
454:                   ),
455:                 ),
456:                 Text(
457:                   plan.completedCount >= plan.totalItems
458:                       ? '✅ أحسنت! أكملت خطتك اليوم'
459:                       : 'تبقّى ${plan.totalItems - plan.completedCount} عناصر',
460:                   style: AppTypography.bodySmall.copyWith(
461:                     color: isDark
462:                         ? AppColors.darkTextSecondary
463:                         : AppColors.lightTextSecondary,
464:                     fontFamily: 'Amiri',
465:                   ),
466:                 ),
467:               ],
468:             ),
469:           ),
470:         ],
471:       ),
472:     );
473:   }
474: }
475: 
476: // ─── Ayah Section ─────────────────────────────────────────────────────────────
477: 
478: class _AyahSection extends StatelessWidget {
479:   const _AyahSection({
480:     required this.label,
481:     required this.ayahs,
482:     required this.plan,
483:     required this.isDark,
484:     required this.primary,
485:     required this.sectionColor,
486:     this.evaluatingAyah,
487:   });
488: 
489:   final String label;
490:   final List<DailyPlanAyah> ayahs;
491:   final DailyPlan plan;
492:   final bool isDark;
493:   final Color primary;
494:   final Color sectionColor;
495:   final int? evaluatingAyah;
496: 
497:   @override
498:   Widget build(BuildContext context) {
499:     return SliverList(
500:       delegate: SliverChildListDelegate([
501:         Padding(
502:           padding: const EdgeInsets.fromLTRB(
503:             AppSpacing.pagePadding,
504:             AppSpacing.lg,
505:             AppSpacing.pagePadding,
506:             AppSpacing.sm,
507:           ),
508:           child: Text(
509:             label,
510:             style: AppTypography.titleMedium.copyWith(
511:               color: sectionColor,
512:               fontFamily: 'Amiri',
513:             ),
514:           ),
515:         ),
516:         ...ayahs.map(
517:           (a) => Padding(
518:             padding: const EdgeInsets.symmetric(
519:               horizontal: AppSpacing.pagePadding,
520:               vertical: 4,
521:             ),
522:             child: _AyahPlanTile(
523:               planAyah: a,
524:               plan: plan,
525:               isDark: isDark,
526:               primary: primary,
527:               isEvaluating: evaluatingAyah == a.ayahNumber,
528:             ),
529:           ),
530:         ),
531:       ]),
532:     );
533:   }
534: }
535: 
536: // ─── Ayah Plan Tile ───────────────────────────────────────────────────────────
537: 
538: class _AyahPlanTile extends StatelessWidget {
539:   const _AyahPlanTile({
540:     required this.planAyah,
541:     required this.plan,
542:     required this.isDark,
543:     required this.primary,
544:     required this.isEvaluating,
545:   });
546: 
547:   final DailyPlanAyah planAyah;
548:   final DailyPlan plan;
549:   final bool isDark;
550:   final Color primary;
551:   final bool isEvaluating;
552:   static const _ratingHintKey = 'daily_plan_rating_hint_seen';
553: 
554:   Future<void> _showRatingHintIfNeeded(BuildContext context) async {
555:     final prefs = getIt<SharedPreferences>();
556:     final seen = prefs.getBool(_ratingHintKey) ?? false;
557:     if (seen) return;
558: 
559:     await showModalBottomSheet<void>(
560:       context: context,
561:       useRootNavigator: true,
562:       backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
563:       shape: const RoundedRectangleBorder(
564:         borderRadius: BorderRadius.vertical(
565:           top: Radius.circular(AppSpacing.radiusXl),
566:         ),
567:       ),
568:       builder: (sheetContext) => SafeArea(
569:         child: Padding(
570:           padding: const EdgeInsets.all(AppSpacing.xl),
571:           child: Column(
572:             mainAxisSize: MainAxisSize.min,
573:             children: [
574:               Container(
575:                 width: 40,
576:                 height: 4,
577:                 decoration: BoxDecoration(
578:                   color: isDark
579:                       ? AppColors.darkDivider
580:                       : AppColors.lightDivider,
581:                   borderRadius: BorderRadius.circular(2),
582:                 ),
583:               ),
584:               const SizedBox(height: AppSpacing.lg),
585:               Icon(Icons.psychology_alt_rounded, color: primary, size: 34),
586:               const SizedBox(height: AppSpacing.md),
587:               Text(
588:                 sheetContext.l10n.dailyPlanRatingHintTitle,
589:                 style: AppTypography.titleLarge.copyWith(
590:                   color: isDark
591:                       ? AppColors.darkTextPrimary
592:                       : AppColors.lightTextPrimary,
593:                   fontFamily: 'Amiri',
594:                 ),
595:                 textAlign: TextAlign.center,
596:               ),
597:               const SizedBox(height: AppSpacing.sm),
598:               Text(
599:                 sheetContext.l10n.dailyPlanRatingHintBody,
600:                 style: AppTypography.bodyMedium.copyWith(
601:                   color: isDark
602:                       ? AppColors.darkTextSecondary
603:                       : AppColors.lightTextSecondary,
604:                   fontFamily: 'Amiri',
605:                   height: 1.6,
606:                 ),
607:                 textAlign: TextAlign.center,
608:               ),
609:               const SizedBox(height: AppSpacing.lg),
610:               SizedBox(
611:                 width: double.infinity,
612:                 child: FilledButton(
613:                   onPressed: () => Navigator.pop(sheetContext),
614:                   child: Text(sheetContext.l10n.understood),
615:                 ),
616:               ),
617:             ],
618:           ),
619:         ),
620:       ),
621:     );
622:     await prefs.setBool(_ratingHintKey, true);
623:   }
624: 
625:   Future<void> _evaluate(BuildContext context, PerformanceRating rating) async {
626:     await _showRatingHintIfNeeded(context);
627:     if (!context.mounted) return;
628:     await context.read<DailyPlanCubit>().evaluateAyah(
629:       surahId: planAyah.surahId,
630:       ayahNumber: planAyah.ayahNumber,
631:       rating: rating,
632:     );
633:   }
634: 
635:   @override
636:   Widget build(BuildContext context) {
637:     final isDone = plan.isCompleted(planAyah.ayahNumber);
638:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
639:     final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
640: 
641:     return AnimatedContainer(
642:       duration: const Duration(milliseconds: 300),
643:       decoration: BoxDecoration(
644:         color: isDone
645:             ? primary.withValues(alpha: 0.08)
646:             : isEvaluating
647:             ? primary.withValues(alpha: 0.05)
648:             : surface,
649:         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
650:         border: Border.all(
651:           color: isDone ? primary.withValues(alpha: 0.4) : border,
652:           width: isDone ? 1 : 0.5,
653:         ),
654:       ),
655:       child: Column(
656:         children: [
657:           ListTile(
658:             leading: Container(
659:               width: 40,
660:               height: 40,
661:               decoration: BoxDecoration(
662:                 color: isDone
663:                     ? primary.withValues(alpha: 0.15)
664:                     : primary.withValues(alpha: 0.08),
665:                 borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
666:               ),
667:               child: Center(
668:                 child: isDone
669:                     ? Icon(Icons.check_rounded, color: primary, size: 20)
670:                     : Text(
671:                         '${planAyah.ayahNumber}',
672:                         style: AppTypography.labelMedium.copyWith(
673:                           color: primary,
674:                           fontWeight: FontWeight.w600,
675:                         ),
676:                       ),
677:               ),
678:             ),
679:             title: Column(
680:               crossAxisAlignment: CrossAxisAlignment.stretch,
681:               children: [
682:                 Text(
683:                   'آية ${planAyah.ayahNumber}',
684:                   style: AppTypography.titleMedium.copyWith(
685:                     color: isDark
686:                         ? AppColors.darkTextPrimary
687:                         : AppColors.lightTextPrimary,
688:                     decoration: isDone ? TextDecoration.lineThrough : null,
689:                     fontFamily: 'Amiri',
690:                   ),
691:                 ),
692:                 const SizedBox(height: 6),
693:                 // T015: replaced with QcfHifzVerseView (compact mode)
694:                 QcfHifzVerseView(
695:                   surahNumber: planAyah.surahId,
696:                   verseNumber: planAyah.ayahNumber,
697:                   fallbackText: planAyah.ayahText,
698:                   isUnlocked: true,
699:                   isMemorized: planAyah.record?.isMemorized ?? false,
700:                   displayMode: HifzVerseDisplayMode.compact,
701:                   textAlign: TextAlign.justify,
702:                 ),
703:                 const SizedBox(height: 4),
704:               ],
705:             ),
706:             subtitle: planAyah.record != null
707:                 ? Text(
708:                     'قوة: ${planAyah.record!.strengthLevel} • '
709:                     'مراجعات: ${planAyah.record!.totalReviews}',
710:                     style: AppTypography.bodySmall.copyWith(
711:                       color: isDark
712:                           ? AppColors.darkTextHint
713:                           : AppColors.lightTextHint,
714:                     ),
715:                   )
716:                 : Text(
717:                     'جديدة',
718:                     style: AppTypography.bodySmall.copyWith(color: primary),
719:                   ),
720:           ),
721:           // Listen button + Evaluation buttons (show only if not yet done)
722:           if (!isDone && !isEvaluating)
723:             Padding(
724:               padding: const EdgeInsets.fromLTRB(
725:                 AppSpacing.md,
726:                 0,
727:                 AppSpacing.md,
728:                 AppSpacing.md,
729:               ),
730:               child: Column(
731:                 crossAxisAlignment: CrossAxisAlignment.stretch,
732:                 children: [
733:                   // ── Listen row ──────────────────────────────────────────
734:                   Row(
735:                     children: [
736:                       AyahListenButton(
737:                         surahId: planAyah.surahId,
738:                         ayahNumber: planAyah.ayahNumber,
739:                         size: AyahListenButtonSize.small,
740:                       ),
741:                       const SizedBox(width: 8),
742:                       Text(
743:                         'استمع للآية قبل التقييم',
744:                         style: AppTypography.labelSmall.copyWith(
745:                           color: isDark
746:                               ? AppColors.darkTextHint
747:                               : AppColors.lightTextHint,
748:                           fontFamily: 'Amiri',
749:                         ),
750:                       ),
751:                     ],
752:                   ),
753:                   const SizedBox(height: AppSpacing.sm),
754:                   // ── Rating buttons ──────────────────────────────────────
755:                   Row(
756:                     children: [
757:                       _EvalButton(
758:                         label: 'ضعيف',
759:                         description: context.l10n.dailyPlanRatingWeakDesc,
760:                         icon: Icons.sentiment_dissatisfied_rounded,
761:                         color: Colors.red,
762:                         onTap: () => _evaluate(context, PerformanceRating.weak),
763:                       ),
764:                       const SizedBox(width: 8),
765:                       _EvalButton(
766:                         label: 'متوسط',
767:                         description: context.l10n.dailyPlanRatingAverageDesc,
768:                         icon: Icons.sentiment_neutral_rounded,
769:                         color: const Color(0xFFFF8C42),
770:                         onTap: () =>
771:                             _evaluate(context, PerformanceRating.average),
772:                       ),
773:                       const SizedBox(width: 8),
774:                       _EvalButton(
775:                         label: 'ممتاز',
776:                         description: context.l10n.dailyPlanRatingExcellentDesc,
777:                         icon: Icons.sentiment_very_satisfied_rounded,
778:                         color: const Color(0xFF2D8E4C),
779:                         onTap: () =>
780:                             _evaluate(context, PerformanceRating.excellent),
781:                       ),
782:                     ],
783:                   ),
784:                 ],
785:               ),
786:             ),
787:           if (isEvaluating)
788:             const Padding(
789:               padding: EdgeInsets.only(bottom: AppSpacing.md),
790:               child: CircularProgressIndicator(strokeWidth: 2),
791:             ),
792:         ],
793:       ),
794:     );
795:   }
796: }
797: 
798: class _EvalButton extends StatelessWidget {
799:   const _EvalButton({
800:     required this.label,
801:     required this.description,
802:     required this.icon,
803:     required this.color,
804:     required this.onTap,
805:   });
806:   final String label;
807:   final String description;
808:   final IconData icon;
809:   final Color color;
810:   final VoidCallback onTap;
811: 
812:   @override
813:   Widget build(BuildContext context) {
814:     return Expanded(
815:       child: GestureDetector(
816:         onTap: () {
817:           HapticFeedback.lightImpact();
818:           onTap();
819:         },
820:         child: Container(
821:           padding: const EdgeInsets.symmetric(vertical: 8),
822:           decoration: BoxDecoration(
823:             color: color.withValues(alpha: 0.1),
824:             borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
825:             border: Border.all(color: color.withValues(alpha: 0.3)),
826:           ),
827:           child: Column(
828:             children: [
829:               Icon(icon, color: color, size: 20),
830:               const SizedBox(height: 2),
831:               Text(
832:                 label,
833:                 style: AppTypography.labelSmall.copyWith(color: color),
834:               ),
835:               const SizedBox(height: 2),
836:               Text(
837:                 description,
838:                 textAlign: TextAlign.center,
839:                 maxLines: 2,
840:                 overflow: TextOverflow.ellipsis,
841:                 style: AppTypography.labelSmall.copyWith(
842:                   color: color.withValues(alpha: 0.82),
843:                   fontSize: 10,
844:                   height: 1.2,
845:                 ),
846:               ),
847:             ],
848:           ),
849:         ),
850:       ),
851:     );
852:   }
853: }
854: 
855: // ─── Rating Banner ────────────────────────────────────────────────────────────
856: 
857: class _RatingBanner extends StatelessWidget {
858:   const _RatingBanner({
859:     required this.rating,
860:     required this.ayahNumber,
861:     required this.isDark,
862:   });
863:   final PerformanceRating rating;
864:   final int ayahNumber;
865:   final bool isDark;
866: 
867:   @override
868:   Widget build(BuildContext context) {
869:     final (color, message) = switch (rating) {
870:       PerformanceRating.excellent => (
871:         const Color(0xFF2D8E4C),
872:         '✅ ممتاز! تم جدولة مراجعة الآية $ayahNumber بعد فترة أطول',
873:       ),
874:       PerformanceRating.average => (
875:         const Color(0xFFFF8C42),
876:         '⏰ متوسط، سيتم المراجعة خلال فترة معتدلة',
877:       ),
878:       PerformanceRating.weak => (
879:         Colors.red,
880:         '🔁 ضعيف، ستتم مراجعة الآية $ayahNumber غداً',
881:       ),
882:     };
883: 
884:     return AnimatedContainer(
885:       duration: const Duration(milliseconds: 300),
886:       margin: const EdgeInsets.symmetric(
887:         horizontal: AppSpacing.pagePadding,
888:         vertical: AppSpacing.sm,
889:       ),
890:       padding: const EdgeInsets.all(AppSpacing.md),
891:       decoration: BoxDecoration(
892:         color: color.withValues(alpha: 0.1),
893:         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
894:         border: Border.all(color: color.withValues(alpha: 0.3)),
895:       ),
896:       child: Row(
897:         children: [
898:           Icon(Icons.info_outline_rounded, color: color, size: 18),
899:           const SizedBox(width: 8),
900:           Expanded(
901:             child: Text(
902:               message,
903:               style: AppTypography.bodySmall.copyWith(
904:                 color: color,
905:                 fontFamily: 'Amiri',
906:               ),
907:             ),
908:           ),
909:         ],
910:       ),
911:     );
912:   }
913: }
914: 
915: // ─── Empty Plan ───────────────────────────────────────────────────────────────
916: 
917: class _EmptyPlan extends StatelessWidget {
918:   const _EmptyPlan({required this.isDark});
919:   final bool isDark;
920: 
921:   @override
922:   Widget build(BuildContext context) {
923:     return Center(
924:       child: Padding(
925:         padding: const EdgeInsets.all(AppSpacing.xl),
926:         child: Column(
927:           mainAxisSize: MainAxisSize.min,
928:           children: [
929:             const Text('🎉', style: TextStyle(fontSize: 64)),
930:             const SizedBox(height: AppSpacing.lg),
931:             Text(
932:               'أحسنت! لا توجد مراجعات مطلوبة اليوم',
933:               style: AppTypography.headlineSmall.copyWith(
934:                 color: isDark
935:                     ? AppColors.darkTextPrimary
936:                     : AppColors.lightTextPrimary,
937:                 fontFamily: 'Amiri',
938:               ),
939:               textAlign: TextAlign.center,
940:             ),
941:             const SizedBox(height: AppSpacing.md),
942:             Text(
943:               'تفقّد غداً لمتابعة جدولك',
944:               style: AppTypography.bodyMedium.copyWith(
945:                 color: isDark
946:                     ? AppColors.darkTextSecondary
947:                     : AppColors.lightTextSecondary,
948:               ),
949:               textAlign: TextAlign.center,
950:             ),
951:           ],
952:         ),
953:       ),
954:     );
955:   }
956: }
957: 
958: // ─── Celebration Stat ─────────────────────────────────────────────────────────
959: 
960: class _CelebrationStat extends StatelessWidget {
961:   const _CelebrationStat({
962:     required this.icon,
963:     required this.label,
964:     required this.value,
965:     required this.color,
966:     required this.isDark,
967:   });
968:   final IconData icon;
969:   final String label;
970:   final String value;
971:   final Color color;
972:   final bool isDark;
973: 
974:   @override
975:   Widget build(BuildContext context) {
976:     return Container(
977:       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
978:       decoration: BoxDecoration(
979:         color: color.withValues(alpha: 0.08),
980:         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
981:       ),
982:       child: Column(
983:         children: [
984:           Icon(icon, color: color, size: 28),
985:           const SizedBox(height: 4),
986:           Text(
987:             value,
988:             style: AppTypography.titleLarge.copyWith(
989:               color: color,
990:               fontWeight: FontWeight.bold,
991:             ),
992:           ),
993:           Text(
994:             label,
995:             style: AppTypography.labelSmall.copyWith(
996:               color: isDark
997:                   ? AppColors.darkTextSecondary
998:                   : AppColors.lightTextSecondary,
999:             ),
1000:           ),
1001:         ],
1002:       ),
1003:     );
1004:   }
1005: }

(End of file - total 1005 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.3s)

_Thinking:_

Let me now look at the kids gamified pages, the hifz session page, and the kids_mode_cubit and daily_plan_cubit.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\pages\\kids_gamified_home_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\pages\kids_gamified_home_page.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: 
3: import 'package:flutter/material.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import 'package:go_router/go_router.dart';
6: 
7: import '../../../../core/constants/app_spacing.dart';
8: import '../../../../core/di/injection.dart';
9: import '../../../../core/extensions/context_extensions.dart';
10: import '../../../../core/router/app_router.dart';
11: import '../../../../core/theme/app_typography.dart';
12: import '../../../../core/widgets/state_widgets.dart';
13: import '../cubits/kids_journey_cubit.dart';
14: import '../theme/kids_theme.dart';
15: import '../widgets/memorization_path_settings_sheet.dart';
16: import '../widgets/kids_mission_card.dart';
17: import '../widgets/kids_progress_header.dart';
18: 
19: class KidsGamifiedHomePage extends StatelessWidget {
20:   const KidsGamifiedHomePage({
21:     super.key,
22:     required this.surahId,
23:     this.childName,
24:   });
25: 
26:   final int surahId;
27:   final String? childName;
28: 
29:   @override
30:   Widget build(BuildContext context) {
31:     return BlocProvider(
32:       create: (_) => getIt<KidsJourneyCubit>()..load(surahId: surahId),
33:       child: _KidsGamifiedHomeView(surahId: surahId, childName: childName),
34:     );
35:   }
36: }
37: 
38: class _KidsGamifiedHomeView extends StatelessWidget {
39:   const _KidsGamifiedHomeView({required this.surahId, this.childName});
40: 
41:   final int surahId;
42:   final String? childName;
43: 
44:   @override
45:   Widget build(BuildContext context) {
46:     return Scaffold(
47:       backgroundColor: KidsTheme.nightSkyDark,
48:       body: BlocConsumer<KidsJourneyCubit, KidsJourneyState>(
49:         listener: (context, state) {
50:           if (state is KidsJourneyLoaded && state.message != null) {
51:             ScaffoldMessenger.of(
52:               context,
53:             ).showSnackBar(SnackBar(content: Text(state.message!)));
54:           }
55:         },
56:         builder: (context, state) {
57:           if (state is KidsJourneyInitial || state is KidsJourneyLoading) {
58:             return const Center(child: LoadingWidget());
59:           }
60: 
61:           if (state is KidsJourneyError) {
62:             return ErrorStateWidget(
63:               message: state.message,
64:               onRetry: () =>
65:                   context.read<KidsJourneyCubit>().load(surahId: surahId),
66:             );
67:           }
68: 
69:           if (state is! KidsJourneyLoaded) return const SizedBox.shrink();
70: 
71:           return KidsGamifiedHomeContent(
72:             state: state,
73:             childName: childName,
74:             onRefresh: () =>
75:                 context.read<KidsJourneyCubit>().load(surahId: surahId),
76:             onMushafTap: () => context.go(AppRoutes.quran),
77:             onJourneyTap: () => context.push(
78:               '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
79:             ),
80:             onMissionTap: () => unawaited(_openCurrentMission(context, state)),
81:             onPathSettingsTap: () =>
82:                 showMemorizationPathSettingsSheet(context, isDark: true),
83:           );
84:         },
85:       ),
86:     );
87:   }
88: 
89:   Future<void> _openCurrentMission(
90:     BuildContext context,
91:     KidsJourneyLoaded state,
92:   ) async {
93:     final stage = state.currentStage;
94:     if (stage == null) {
95:       await context.push(
96:         '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
97:       );
98:     } else {
99:       final startAyah = stage.nextAyahToStart;
100:       await context.push(
101:         '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}&ayahNumber=$startAyah',
102:       );
103:     }
104: 
105:     if (context.mounted) {
106:       await context.read<KidsJourneyCubit>().load(surahId: state.surahId);
107:     }
108:   }
109: }
110: 
111: @visibleForTesting
112: class KidsGamifiedHomeContent extends StatelessWidget {
113:   const KidsGamifiedHomeContent({
114:     super.key,
115:     required this.state,
116:     required this.onMushafTap,
117:     required this.onJourneyTap,
118:     required this.onMissionTap,
119:     this.childName,
120:     this.onRefresh,
121:     this.onPathSettingsTap,
122:   });
123: 
124:   final KidsJourneyLoaded state;
125:   final VoidCallback onMushafTap;
126:   final VoidCallback onJourneyTap;
127:   final VoidCallback onMissionTap;
128:   final String? childName;
129:   final Future<void> Function()? onRefresh;
130:   final VoidCallback? onPathSettingsTap;
131: 
132:   @override
133:   Widget build(BuildContext context) {
134:     return Container(
135:       decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
136:       child: Scaffold(
137:         backgroundColor: Colors.transparent,
138:         bottomNavigationBar: _KidsHomeBottomNav(
139:           onMushafTap: onMushafTap,
140:           onJourneyTap: onJourneyTap,
141:           onMissionTap: onMissionTap,
142:         ),
143:         body: SafeArea(
144:           child: RefreshIndicator(
145:             onRefresh: onRefresh ?? () async {},
146:             child: CustomScrollView(
147:               key: const PageStorageKey<String>('kids-gamified-home'),
148:               physics: const AlwaysScrollableScrollPhysics(),
149:               slivers: [
150:                 SliverPadding(
151:                   padding: const EdgeInsets.fromLTRB(
152:                     AppSpacing.lg,
153:                     AppSpacing.lg,
154:                     AppSpacing.lg,
155:                     AppSpacing.xl,
156:                   ),
157:                   sliver: SliverList.list(
158:                     children: [
159:                       KidsProgressHeader(
160:                         progress: state.progress,
161:                         childName: childName,
162:                         onSettingsTap: onPathSettingsTap,
163:                       ),
164:                       const SizedBox(height: AppSpacing.lg),
165:                       KidsMissionCard(
166:                         stage: state.currentStage,
167:                         surahName:
168:                             state.surahName ??
169:                             '${context.l10n.surah} ${state.surahId}',
170:                         onContinue: onMissionTap,
171:                       ),
172:                       const SizedBox(height: AppSpacing.lg),
173:                       _KidsHomeQuickActions(
174:                         onMushafTap: onMushafTap,
175:                         onJourneyTap: onJourneyTap,
176:                         onMissionTap: onMissionTap,
177:                       ),
178:                       const SizedBox(height: 96),
179:                     ],
180:                   ),
181:                 ),
182:               ],
183:             ),
184:           ),
185:         ),
186:       ),
187:     );
188:   }
189: }
190: 
191: class _KidsHomeQuickActions extends StatelessWidget {
192:   const _KidsHomeQuickActions({
193:     required this.onMushafTap,
194:     required this.onJourneyTap,
195:     required this.onMissionTap,
196:   });
197: 
198:   final VoidCallback onMushafTap;
199:   final VoidCallback onJourneyTap;
200:   final VoidCallback onMissionTap;
201: 
202:   @override
203:   Widget build(BuildContext context) {
204:     return LayoutBuilder(
205:       builder: (context, constraints) {
206:         final twoColumns = constraints.maxWidth >= 560;
207:         return GridView.count(
208:           crossAxisCount: twoColumns ? 3 : 1,
209:           mainAxisSpacing: AppSpacing.sm,
210:           crossAxisSpacing: AppSpacing.sm,
211:           childAspectRatio: twoColumns ? 2.2 : 4.2,
212:           physics: const NeverScrollableScrollPhysics(),
213:           shrinkWrap: true,
214:           children: [
215:             _KidsHomeActionButton(
216:               key: const ValueKey('kids-home-action-mushaf'),
217:               icon: Icons.menu_book_rounded,
218:               label: context.l10n.kidsGamifiedMushaf,
219:               onTap: onMushafTap,
220:             ),
221:             _KidsHomeActionButton(
222:               key: const ValueKey('kids-home-action-journey'),
223:               icon: Icons.map_rounded,
224:               label: context.l10n.kidsGamifiedJourney,
225:               onTap: onJourneyTap,
226:             ),
227:             _KidsHomeActionButton(
228:               key: const ValueKey('kids-home-action-missions'),
229:               icon: Icons.flag_rounded,
230:               label: context.l10n.kidsGamifiedMissions,
231:               onTap: onMissionTap,
232:             ),
233:           ],
234:         );
235:       },
236:     );
237:   }
238: }
239: 
240: class _KidsHomeActionButton extends StatelessWidget {
241:   const _KidsHomeActionButton({
242:     super.key,
243:     required this.icon,
244:     required this.label,
245:     required this.onTap,
246:   });
247: 
248:   final IconData icon;
249:   final String label;
250:   final VoidCallback onTap;
251: 
252:   @override
253:   Widget build(BuildContext context) {
254:     return Material(
255:       color: KidsTheme.creamParchment,
256:       borderRadius: KidsTheme.cardRadius,
257:       child: InkWell(
258:         onTap: onTap,
259:         borderRadius: KidsTheme.cardRadius,
260:         child: Container(
261:           padding: const EdgeInsets.symmetric(
262:             horizontal: AppSpacing.md,
263:             vertical: AppSpacing.sm,
264:           ),
265:           decoration: BoxDecoration(
266:             borderRadius: KidsTheme.cardRadius,
267:             border: Border.all(color: KidsTheme.parchmentEdge),
268:           ),
269:           child: Row(
270:             children: [
271:               Container(
272:                 width: 42,
273:                 height: 42,
274:                 decoration: BoxDecoration(
275:                   color: KidsTheme.forestGreen.withValues(alpha: 0.12),
276:                   shape: BoxShape.circle,
277:                 ),
278:                 child: Icon(icon, color: KidsTheme.forestGreen),
279:               ),
280:               const SizedBox(width: AppSpacing.md),
281:               Expanded(
282:                 child: Text(
283:                   label,
284:                   maxLines: 1,
285:                   overflow: TextOverflow.ellipsis,
286:                   style: AppTypography.titleMedium.copyWith(
287:                     color: KidsTheme.nightSkyDark,
288:                     fontFamily: 'Amiri',
289:                     letterSpacing: 0,
290:                   ),
291:                 ),
292:               ),
293:               const Icon(
294:                 Icons.arrow_forward_ios_rounded,
295:                 color: KidsTheme.goldWarm,
296:                 size: 16,
297:               ),
298:             ],
299:           ),
300:         ),
301:       ),
302:     );
303:   }
304: }
305: 
306: class _KidsHomeBottomNav extends StatelessWidget {
307:   const _KidsHomeBottomNav({
308:     required this.onMushafTap,
309:     required this.onJourneyTap,
310:     required this.onMissionTap,
311:   });
312: 
313:   final VoidCallback onMushafTap;
314:   final VoidCallback onJourneyTap;
315:   final VoidCallback onMissionTap;
316: 
317:   @override
318:   Widget build(BuildContext context) {
319:     final isCompact = MediaQuery.sizeOf(context).width < 360;
320: 
321:     return NavigationBar(
322:       key: const ValueKey('kids-home-bottom-nav'),
323:       selectedIndex: 2,
324:       backgroundColor: KidsTheme.nightSkyMid,
325:       indicatorColor: KidsTheme.goldStar.withValues(alpha: 0.18),
326:       labelBehavior: isCompact
327:           ? NavigationDestinationLabelBehavior.onlyShowSelected
328:           : NavigationDestinationLabelBehavior.alwaysShow,
329:       onDestinationSelected: (index) {
330:         switch (index) {
331:           case 0:
332:             onMushafTap();
333:           case 1:
334:             onJourneyTap();
335:           case 2:
336:             onMissionTap();
337:         }
338:       },
339:       destinations: [
340:         NavigationDestination(
341:           key: const ValueKey('kids-home-nav-mushaf'),
342:           icon: const Icon(Icons.menu_book_outlined),
343:           selectedIcon: const Icon(Icons.menu_book_rounded),
344:           label: context.l10n.kidsGamifiedMushaf,
345:         ),
346:         NavigationDestination(
347:           key: const ValueKey('kids-home-nav-journey'),
348:           icon: const Icon(Icons.map_outlined),
349:           selectedIcon: const Icon(Icons.map_rounded),
350:           label: context.l10n.kidsGamifiedJourney,
351:         ),
352:         NavigationDestination(
353:           key: const ValueKey('kids-home-nav-missions'),
354:           icon: const Icon(Icons.flag_outlined),
355:           selectedIcon: const Icon(Icons.flag_rounded),
356:           label: context.l10n.kidsGamifiedMissions,
357:         ),
358:       ],
359:     );
360:   }
361: }

(End of file - total 361 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.8s)

_Thinking:_

Let me now look at the kids_mode_cubit, daily_plan_cubit, and hifz_session_page and the path settings sheet.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\cubits\\daily_plan_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\cubits\daily_plan_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'package:equatable/equatable.dart';
3: import 'package:flutter_bloc/flutter_bloc.dart';
4: import '../../../../core/services/achievement_service.dart';
5: import '../../../../core/services/streak_service.dart';
6: import '../../../../core/services/xp_service.dart';
7: import '../../domain/entities/memorization_entities.dart';
8: import '../../domain/usecases/memorization_plus_usecases.dart';
9: 
10: part 'daily_plan_state.dart';
11: 
12: class DailyPlanCubit extends Cubit<DailyPlanState> {
13:   DailyPlanCubit(
14:     this._generateDailyPlan,
15:     this._getCachedPlan,
16:     this._evaluateUsecase,
17:     this._saveDailyPlan,
18:     this._achievementService,
19:     this._streakService, // RISK-5 FIX
20:     this._xpService, // RISK-5 FIX
21:   ) : super(const DailyPlanInitial());
22: 
23:   final GenerateDailyPlanUsecase _generateDailyPlan;
24:   final GetCachedDailyPlanUsecase _getCachedPlan;
25:   final EvaluateMemorizationUsecase _evaluateUsecase;
26:   final SaveDailyPlanUsecase _saveDailyPlan;
27:   final AchievementService _achievementService;
28:   final StreakService _streakService; // RISK-5 FIX
29:   final XpService _xpService; // RISK-5 FIX
30: 
31:   Future<void> load({required int surahId, int newAyahsPerDay = 5}) async {
32:     emit(const DailyPlanLoading());
33: 
34:     // Try cache first
35:     final cached = await _getCachedPlan();
36:     final cachedPlan = cached.getOrElse(() => null);
37: 
38:     // Validate cache has actual Ayah text
39:     bool isCacheValid = false;
40:     if (cachedPlan != null && cachedPlan.surahId == surahId) {
41:       final allAyahs = [
42:         ...cachedPlan.newAyahs,
43:         ...cachedPlan.nearRevision,
44:         ...cachedPlan.farRevision,
45:       ];
46:       final hasMissingText = allAyahs.any(
47:         (a) =>
48:             a.ayahText.isEmpty ||
49:             a.ayahText == '...' ||
50:             a.ayahText == 'النص غير متوفر',
51:       );
52:       if (!hasMissingText) {
53:         isCacheValid = true;
54:       }
55:     }
56: 
57:     if (isCacheValid) {
58:       emit(DailyPlanLoaded(plan: cachedPlan!, surahId: surahId));
59:       return;
60:     }
61: 
62:     // Generate fresh plan
63:     final result = await _generateDailyPlan(
64:       GenerateDailyPlanParams(surahId: surahId, newAyahsPerDay: newAyahsPerDay),
65:     );
66: 
67:     result.fold(
68:       (f) => emit(DailyPlanError(f.message)),
69:       (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
70:     );
71:   }
72: 
73:   Future<void> refresh({required int surahId, int newAyahsPerDay = 5}) async {
74:     emit(const DailyPlanLoading());
75:     final result = await _generateDailyPlan(
76:       GenerateDailyPlanParams(surahId: surahId, newAyahsPerDay: newAyahsPerDay),
77:     );
78:     result.fold(
79:       (f) => emit(DailyPlanError(f.message)),
80:       (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
81:     );
82:   }
83: 
84:   Future<void> evaluateAyah({
85:     required int surahId,
86:     required int ayahNumber,
87:     required PerformanceRating rating,
88:   }) async {
89:     if (state is! DailyPlanLoaded) return;
90:     final current = state as DailyPlanLoaded;
91: 
92:     emit(
93:       DailyPlanEvaluating(
94:         plan: current.plan,
95:         surahId: current.surahId,
96:         evaluatingAyah: ayahNumber,
97:       ),
98:     );
99: 
100:     final result = await _evaluateUsecase(
101:       EvaluateMemorizationParams(
102:         surahId: surahId,
103:         ayahNumber: ayahNumber,
104:         rating: rating,
105:       ),
106:     );
107: 
108:     final evaluateFailure = result.fold((f) => f, (_) => null);
109:     if (evaluateFailure != null) {
110:       emit(DailyPlanError(evaluateFailure.message));
111:       return;
112:     }
113: 
114:     final isSuccessfulRating = rating != PerformanceRating.weak;
115:     final updatedPlan = isSuccessfulRating
116:         ? current.plan.withCompleted(ayahNumber)
117:         : current.plan;
118: 
119:     if (isSuccessfulRating) {
120:       // RISK-5 FIX: record streak & XP from MemorizationPlus — same as Hifz
121:       try {
122:         await _streakService.recordActivity(activityDelta: 1);
123:         await _xpService.addXp('ayah_memorized');
124:       } catch (_) {
125:         // Non-critical: don't block evaluation on streak/xp failure
126:       }
127: 
128:       final saveResult = await _saveDailyPlan(updatedPlan);
129:       final saveFailure = saveResult.fold((f) => f, (_) => null);
130:       if (saveFailure != null) {
131:         emit(DailyPlanError(saveFailure.message));
132:         return;
133:       }
134:     }
135: 
136:     final newAwards = isSuccessfulRating
137:         ? await _achievementService.checkAndUnlockCertificates()
138:         : <CertificateAward>[];
139:     emit(
140:       DailyPlanLoaded(
141:         plan: updatedPlan,
142:         surahId: current.surahId,
143:         lastEvaluatedAyah: ayahNumber,
144:         lastRating: rating,
145:         newAwards: newAwards,
146:       ),
147:     );
148:   }
149: }
150: 

(End of file - total 150 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 7.9s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\cubits\\kids_mode_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\cubits\kids_mode_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'dart:async';
3: import 'package:equatable/equatable.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import 'package:just_audio/just_audio.dart';
6: import '../../../../core/services/achievement_service.dart';
7: import '../../../../core/services/streak_service.dart'; // RISK-5 FIX
8: import '../../../../core/services/xp_service.dart'; // RISK-5 FIX
9: import '../../domain/entities/memorization_entities.dart';
10: import '../../domain/usecases/memorization_plus_usecases.dart';
11: 
12: import '../../../../core/services/quran_audio_service.dart';
13: import '../../../../features/quran/domain/repositories/quran_repository.dart';
14: 
15: part 'kids_mode_state.dart';
16: 
17: class KidsModeCubit extends Cubit<KidsModeState> {
18:   KidsModeCubit(
19:     this._getKidsProgress,
20:     this._awardPoints,
21:     this._markAyahMemorized,
22:     this._saveKidsSessionLog,
23:     this._achievementService,
24:     this._quranRepository,
25:     this._streakService, // RISK-5 FIX
26:     this._xpService, // RISK-5 FIX
27:   ) : super(const KidsModeInitial()) {
28:     _playerSub = _player.playerStateStream.listen((ps) {
29:       if (ps.processingState == ProcessingState.completed) {
30:         _onPlaybackCompleted();
31:       }
32:     });
33:     // Track buffering state separately so the UI shows a precise loading indicator
34:     _bufferingSub = _player.processingStateStream.listen((ps) {
35:       if (state is KidsModeLoaded) {
36:         final buffering = ps == ProcessingState.loading ||
37:             ps == ProcessingState.buffering;
38:         emit((state as KidsModeLoaded).copyWith(isBuffering: buffering));
39:       }
40:     });
41:   }
42: 
43:   final GetKidsProgressUsecase _getKidsProgress;
44:   final AwardKidsPointsUsecase _awardPoints;
45:   final MarkAyahMemorizedUsecase _markAyahMemorized;
46:   final SaveKidsSessionLogUsecase _saveKidsSessionLog;
47:   final AchievementService _achievementService;
48:   final QuranRepository _quranRepository;
49:   final StreakService _streakService; // RISK-5 FIX
50:   final XpService _xpService; // RISK-5 FIX
51:   final AudioPlayer _player = AudioPlayer();
52:   late final StreamSubscription<PlayerState> _playerSub;
53:   late final StreamSubscription<ProcessingState> _bufferingSub;
54: 
55:   int _loopCount = 0;
56:   static const int _maxLoops = 3;
57: 
58:   Future<void> load(int surahId, int ayahNumber, String ayahText) async {
59:     emit(const KidsModeLoading());
60: 
61:     String resolvedText = ayahText;
62:     if (resolvedText.isEmpty ||
63:         resolvedText == '...' ||
64:         resolvedText == 'النص غير متوفر') {
65:       try {
66:         final result = await _quranRepository.getSurahDetail(surahId);
67:         result.fold((_) {}, (detail) {
68:           resolvedText = detail.ayahs
69:               .firstWhere((a) => a.numberInSurah == ayahNumber)
70:               .text;
71:         });
72:       } catch (_) {}
73:       if (resolvedText.isEmpty || resolvedText == '...') {
74:         resolvedText = 'النص غير متوفر';
75:       }
76:     }
77: 
78:     final progressResult = await _getKidsProgress();
79:     final progress = progressResult.fold(
80:       (_) => const KidsProgress.initial(),
81:       (p) => p,
82:     );
83: 
84:     emit(
85:       KidsModeLoaded(
86:         surahId: surahId,
87:         ayahNumber: ayahNumber,
88:         ayahText: resolvedText,
89:         progress: progress,
90:         isPlaying: false,
91:         currentLoop: 0,
92:         maxLoops: _maxLoops,
93:         isCompleted: false,
94:       ),
95:     );
96:   }
97: 
98:   Future<void> playAudio() async {
99:     if (state is! KidsModeLoaded) return;
100:     final st = state as KidsModeLoaded;
101: 
102:     _loopCount = 0;
103:     emit(
104:       st.copyWith(
105:         isPlaying: true,
106:         isBuffering: true,
107:         currentLoop: 1,
108:         clearAudioError: true,
109:       ),
110:     );
111:     await _playAyah(st.surahId, st.ayahNumber);
112:   }
113: 
114:   Future<void> _playAyah(int surahId, int ayahNumber) async {
115:     try {
116:       final url = QuranAudioService.buildUrl(surahId, ayahNumber);
117:       await _player.setUrl(url);
118:       await _player.play();
119:     } catch (_) {
120:       if (state is KidsModeLoaded) {
121:         emit(
122:           (state as KidsModeLoaded).copyWith(
123:             isPlaying: false,
124:             audioError:
125:                 'لم يعمل الصوت الآن. جرّب مرة أخرى أو اطلب من ولي الأمر الاتصال بالإنترنت.',
126:           ),
127:         );
128:       }
129:     }
130:   }
131: 
132:   void _onPlaybackCompleted() {
133:     if (state is! KidsModeLoaded) return;
134:     final st = state as KidsModeLoaded;
135: 
136:     _loopCount++;
137:     if (_loopCount < _maxLoops) {
138:       emit(st.copyWith(currentLoop: _loopCount + 1, clearAudioError: true));
139:       _playAyah(st.surahId, st.ayahNumber);
140:     } else {
141:       emit(
142:         st.copyWith(
143:           isPlaying: false,
144:           currentLoop: _maxLoops,
145:           clearAudioError: true,
146:         ),
147:       );
148:     }
149:   }
150: 
151:   Future<void> stopAudio() async {
152:     await _player.stop();
153:     if (state is KidsModeLoaded) {
154:       emit(
155:         (state as KidsModeLoaded).copyWith(
156:           isPlaying: false,
157:           isBuffering: false,
158:         ),
159:       );
160:     }
161:   }
162: 
163:   /// Shows a brief visual recording animation, then finalises completion.
164:   /// This satisfies US4 Acceptance Scenario 3: the child sees a visual
165:   /// indicator before the session is marked as done.
166:   Future<void> startRecording() async {
167:     if (state is! KidsModeLoaded) return;
168:     final st = state as KidsModeLoaded;
169:     if (st.isCompleted) return;
170: 
171:     // Show recording indicator for 1.5 s so the child has visual feedback
172:     emit(st.copyWith(isRecording: true));
173:     await Future<void>.delayed(const Duration(milliseconds: 1500));
174: 
175:     // Guard: cubit may have been closed during the delay
176:     if (isClosed || state is! KidsModeLoaded) return;
177:     emit((state as KidsModeLoaded).copyWith(isRecording: false));
178: 
179:     await markCompleted();
180:   }
181: 
182:   Future<void> markCompleted() async {
183:     if (state is! KidsModeLoaded) return;
184:     final st = state as KidsModeLoaded;
185: 
186:     // BUG-4 FIX: prevent completing without listening the required times
187:     if (_loopCount < _maxLoops) {
188:       // Emit a warning state so the UI can show a message
189:       emit(st.copyWith(mustListenFirst: true));
190:       // Clear the flag after 2 seconds
191:       Future.delayed(const Duration(seconds: 2), () {
192:         if (state is KidsModeLoaded) {
193:           emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
194:         }
195:       });
196:       return;
197:     }
198: 
199:     final result = await _awardPoints(
200:       AwardKidsPointsParams(
201:         surahId: st.surahId,
202:         ayahNumber: st.ayahNumber,
203:         repeatsCompleted: _loopCount,
204:       ),
205:     );
206: 
207:     final updated = result.fold<KidsProgress?>((f) {
208:       emit(KidsModeError(f.message));
209:       return null;
210:     }, (progress) => progress);
211:     if (updated == null) return;
212: 
213:     final markResult = await _markAyahMemorized(
214:       MarkAyahMemorizedParams(surahId: st.surahId, ayahNumber: st.ayahNumber),
215:     );
216:     final markFailure = markResult.fold((f) => f, (_) => null);
217:     if (markFailure != null) {
218:       emit(KidsModeError(markFailure.message));
219:       return;
220:     }
221: 
222:     // RISK-5 FIX: record streak & XP from Kids Mode — same as Hifz & Adults
223:     try {
224:       await _streakService.recordActivity(activityDelta: 1);
225:       await _xpService.addXp('ayah_memorized');
226:     } catch (_) {
227:       // Non-critical
228:     }
229: 
230:     final pointsEarned = 10 + ((_loopCount - 1) * 2).clamp(0, 20);
231:     await _saveKidsSessionLog(
232:       SaveKidsSessionLogParams(
233:         surahId: st.surahId,
234:         ayahNumber: st.ayahNumber,
235:         repeatsCompleted: _loopCount,
236:         pointsEarned: pointsEarned,
237:       ),
238:     );
239: 
240:     final newAwards = await _achievementService.checkAndUnlockCertificates();
241:     emit(
242:       st.copyWith(progress: updated, isCompleted: true, newAwards: newAwards),
243:     );
244:   }
245: 
246:   @override
247:   Future<void> close() async {
248:     await _playerSub.cancel();
249:     await _bufferingSub.cancel();
250:     await _player.dispose();
251:     return super.close();
252:   }
253: }

(End of file - total 253 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\widgets"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\widgets</path>
<type>directory</type>
<entries>
kids_ayah_card.dart
kids_house_card.dart
kids_journey_map.dart
kids_mission_card.dart
kids_progress_header.dart
kids_reward_dialog.dart
kids_stage_details.dart
memorization_path_settings_sheet.dart

(8 entries)
</entries>
```

---

## Assistant (Build · MiniMax M3 Free · 8.5s)

_Thinking:_

Let me look at the memorization path settings sheet and the hifz session page.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\widgets\\memorization_path_settings_sheet.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\widgets\memorization_path_settings_sheet.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/material.dart';
2: import 'package:go_router/go_router.dart';
3: 
4: import '../../../../core/constants/app_spacing.dart';
5: import '../../../../core/di/injection.dart';
6: import '../../../../core/extensions/context_extensions.dart';
7: import '../../../../core/router/app_router.dart';
8: import '../../../../core/theme/app_colors.dart';
9: import '../../../../core/theme/app_typography.dart';
10: import '../../domain/repositories/memorization_plus_repository.dart';
11: 
12: Future<void> showMemorizationPathSettingsSheet(
13:   BuildContext context, {
14:   required bool isDark,
15:   String replacementLocation = AppRoutes.memorizationPlus,
16: }) {
17:   return showModalBottomSheet<void>(
18:     context: context,
19:     backgroundColor: isDark
20:         ? AppColors.darkBackground
21:         : AppColors.lightBackground,
22:     shape: const RoundedRectangleBorder(
23:       borderRadius: BorderRadius.vertical(
24:         top: Radius.circular(AppSpacing.radiusXl),
25:       ),
26:     ),
27:     builder: (ctx) => SafeArea(
28:       child: Padding(
29:         padding: const EdgeInsets.all(AppSpacing.lg),
30:         child: Column(
31:           mainAxisSize: MainAxisSize.min,
32:           crossAxisAlignment: CrossAxisAlignment.start,
33:           children: [
34:             Text(
35:               ctx.l10n.changeMemorizationPath,
36:               style: AppTypography.headlineSmall.copyWith(
37:                 color: isDark
38:                     ? AppColors.darkTextPrimary
39:                     : AppColors.lightTextPrimary,
40:                 fontFamily: 'Amiri',
41:               ),
42:             ),
43:             const SizedBox(height: AppSpacing.md),
44:             ListTile(
45:               leading: Container(
46:                 width: 48,
47:                 height: 48,
48:                 decoration: BoxDecoration(
49:                   color: Colors.orange.withValues(alpha: 0.12),
50:                   shape: BoxShape.circle,
51:                 ),
52:                 child: const Icon(
53:                   Icons.restart_alt_rounded,
54:                   color: Colors.orange,
55:                 ),
56:               ),
57:               title: Text(
58:                 ctx.l10n.resetMemorizationPathTileTitle,
59:                 style: AppTypography.bodyMedium.copyWith(
60:                   color: isDark
61:                       ? AppColors.darkTextPrimary
62:                       : AppColors.lightTextPrimary,
63:                   fontWeight: FontWeight.w600,
64:                 ),
65:               ),
66:               subtitle: Text(
67:                 ctx.l10n.resetMemorizationPathPreserveProgressDesc,
68:                 style: AppTypography.labelSmall.copyWith(
69:                   color: isDark
70:                       ? AppColors.darkTextSecondary
71:                       : AppColors.lightTextSecondary,
72:                 ),
73:               ),
74:               onTap: () async {
75:                 final resetQuestion = ctx.l10n.resetMemorizationPathQuestion;
76:                 final resetDialog =
77:                     ctx.l10n.resetMemorizationPathPreserveProgressDialog;
78:                 final cancelLabel = ctx.l10n.cancel;
79:                 final resetLabel = ctx.l10n.reset;
80:                 Navigator.pop(ctx);
81:                 final confirmed = await showDialog<bool>(
82:                   context: context,
83:                   builder: (dialogContext) => AlertDialog(
84:                     title: Text(
85:                       resetQuestion,
86:                       style: const TextStyle(fontFamily: 'Amiri'),
87:                     ),
88:                     content: Text(resetDialog),
89:                     actions: [
90:                       TextButton(
91:                         onPressed: () => Navigator.pop(dialogContext, false),
92:                         child: Text(cancelLabel),
93:                       ),
94:                       FilledButton(
95:                         style: FilledButton.styleFrom(
96:                           backgroundColor: Colors.orange,
97:                         ),
98:                         onPressed: () => Navigator.pop(dialogContext, true),
99:                         child: Text(resetLabel),
100:                       ),
101:                     ],
102:                   ),
103:                 );
104:                 if (confirmed == true) {
105:                   await getIt<MemorizationPlusRepository>()
106:                       .resetMemorizationIdentity();
107:                   if (context.mounted) {
108:                     context.pushReplacement(replacementLocation);
109:                   }
110:                 }
111:               },
112:             ),
113:           ],
114:         ),
115:       ),
116:     ),
117:   );
118: }

(End of file - total 118 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 7.3s)

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\pages\\hifz_session_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\pages\hifz_session_page.dart</path>
<type>file</type>
<content>
1: import 'dart:async';
2: 
3: import 'package:flutter/material.dart';
4: import 'package:flutter_animate/flutter_animate.dart';
5: import 'package:flutter_bloc/flutter_bloc.dart';
6: import 'package:shared_preferences/shared_preferences.dart';
7: import '../../../../core/constants/app_spacing.dart';
8: import '../../../../core/di/injection.dart';
9: import '../../../../core/extensions/context_extensions.dart';
10: import '../../../../core/services/app_session_service.dart';
11: import '../../../../core/theme/app_colors.dart';
12: import '../../../../core/theme/app_typography.dart';
13: import '../../../../core/widgets/qcf_hifz_verse_view.dart';
14: import '../../../../core/widgets/state_widgets.dart';
15: import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
16: import '../../domain/entities/hifz_entities.dart';
17: import '../cubits/hifz_session_cubit.dart';
18: 
19: class HifzSessionPage extends StatelessWidget {
20:   const HifzSessionPage({
21:     super.key,
22:     required this.surahId,
23:     required this.startAyah,
24:   });
25: 
26:   final int surahId;
27:   final int startAyah;
28: 
29:   @override
30:   Widget build(BuildContext context) {
31:     return BlocProvider(
32:       create: (_) =>
33:           getIt<HifzSessionCubit>()..startSession(surahId, startAyah),
34:       child: const _HifzSessionView(),
35:     );
36:   }
37: }
38: 
39: class _HifzSessionView extends StatelessWidget {
40:   const _HifzSessionView();
41: 
42:   @override
43:   Widget build(BuildContext context) {
44:     final isDark = context.isDark;
45: 
46:     return PopScope(
47:       canPop: false,
48:       onPopInvokedWithResult: (didPop, _) async {
49:         if (didPop) return;
50:         final shouldLeave = await showDialog<bool>(
51:           context: context,
52:           builder: (ctx) => AlertDialog(
53:             title: Text(context.l10n.endSessionTitle),
54:             content: Text(
55:               context.isArabic
56:                   ? 'هل تريد الخروج من جلسة الحفظ؟ سيتم حفظ تقدمك الحالي.'
57:                   : 'Do you want to leave the memorization session? Your current progress will be saved.',
58:             ),
59:             actions: [
60:               TextButton(
61:                 onPressed: () => Navigator.pop(ctx, false),
62:                 child: Text(context.l10n.continueAction),
63:               ),
64:               TextButton(
65:                 onPressed: () => Navigator.pop(ctx, true),
66:                 child: Text(
67:                   context.l10n.exitAction,
68:                   style: const TextStyle(color: Colors.red),
69:                 ),
70:               ),
71:             ],
72:           ),
73:         );
74:         if (shouldLeave == true && context.mounted) {
75:           Navigator.of(context).pop();
76:         }
77:       },
78:       child: Scaffold(
79:         backgroundColor: isDark
80:             ? AppColors.parchmentDark
81:             : AppColors.parchmentLight,
82:         body: BlocConsumer<HifzSessionCubit, HifzSessionState>(
83:           listener: (context, state) {
84:             if (state is HifzSessionLoaded) {
85:               _saveSessionLocation(state);
86:             }
87:             if (state is CertificatesEarned) {
88:               _saveSessionLocation(state.previousState);
89:               unawaited(
90:                 showCertificateCelebrationDialog(context, state.awards),
91:               );
92:             }
93:           },
94:           buildWhen: (previous, current) => current is! CertificatesEarned,
95:           builder: (context, state) {
96:             if (state is HifzSessionLoading) {
97:               return const Center(child: LoadingWidget());
98:             }
99:             if (state is HifzSessionError) {
100:               return ErrorStateWidget(message: state.message);
101:             }
102:             if (state is HifzSessionLoaded) {
103:               return _FullSurahSession(state: state, isDark: isDark);
104:             }
105:             return const SizedBox.shrink();
106:           },
107:         ),
108:       ),
109:     );
110:   }
111: 
112:   void _saveSessionLocation(HifzSessionLoaded state) {
113:     final ayah = state.ayahs[state.currentIndex];
114:     unawaited(
115:       getIt<AppSessionService>().saveLocation(
116:         '/hifz/session?surahId=${state.surah.id}&startAyah=${ayah.numberInSurah}',
117:       ),
118:     );
119:   }
120: }
121: 
122: class _FullSurahSession extends StatelessWidget {
123:   const _FullSurahSession({required this.state, required this.isDark});
124:   final HifzSessionLoaded state;
125:   final bool isDark;
126:   static const _skipHintKey = 'hifz_skip_hint_seen';
127: 
128:   Future<void> _showSkipHintIfNeeded(BuildContext context) async {
129:     final prefs = getIt<SharedPreferences>();
130:     final seen = prefs.getBool(_skipHintKey) ?? false;
131:     if (seen) return;
132: 
133:     await showModalBottomSheet<void>(
134:       context: context,
135:       useRootNavigator: true,
136:       isDismissible: false,
137:       enableDrag: false,
138:       backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
139:       shape: const RoundedRectangleBorder(
140:         borderRadius: BorderRadius.vertical(
141:           top: Radius.circular(AppSpacing.radiusXl),
142:         ),
143:       ),
144:       builder: (sheetContext) => SafeArea(
145:         child: Padding(
146:           padding: const EdgeInsets.all(AppSpacing.xl),
147:           child: Column(
148:             mainAxisSize: MainAxisSize.min,
149:             children: [
150:               const Icon(
151:                 Icons.skip_next_rounded,
152:                 color: AppColors.primary,
153:                 size: 36,
154:               ),
155:               const SizedBox(height: AppSpacing.md),
156:               Text(
157:                 sheetContext.l10n.hifzSkipHintTitle,
158:                 style: AppTypography.titleLarge.copyWith(
159:                   color: isDark
160:                       ? AppColors.darkTextPrimary
161:                       : AppColors.lightTextPrimary,
162:                   fontFamily: 'Amiri',
163:                 ),
164:                 textAlign: TextAlign.center,
165:               ),
166:               const SizedBox(height: AppSpacing.sm),
167:               Text(
168:                 sheetContext.l10n.hifzSkipHintBody,
169:                 style: AppTypography.bodyMedium.copyWith(
170:                   color: isDark
171:                       ? AppColors.darkTextSecondary
172:                       : AppColors.lightTextSecondary,
173:                   fontFamily: 'Amiri',
174:                   height: 1.6,
175:                 ),
176:                 textAlign: TextAlign.center,
177:               ),
178:               const SizedBox(height: AppSpacing.lg),
179:               SizedBox(
180:                 width: double.infinity,
181:                 child: FilledButton(
182:                   onPressed: () => Navigator.pop(sheetContext),
183:                   child: Text(sheetContext.l10n.understood),
184:                 ),
185:               ),
186:             ],
187:           ),
188:         ),
189:       ),
190:     );
191:     await prefs.setBool(_skipHintKey, true);
192:   }
193: 
194:   Future<void> _handleSkip(BuildContext context) async {
195:     await _showSkipHintIfNeeded(context);
196:     if (!context.mounted) return;
197:     await context.read<HifzSessionCubit>().skipAyah();
198:   }
199: 
200:   @override
201:   Widget build(BuildContext context) {
202:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
203:     final textColor = isDark
204:         ? AppColors.darkTextPrimary
205:         : AppColors.lightTextPrimary;
206:     final ayah = state.ayahs[state.currentIndex];
207:     final hasCheckpoint =
208:         state.requiredCheckpoint != null || state.completedCheckpoint != null;
209: 
210:     return Column(
211:       children: [
212:         AppBar(
213:           backgroundColor: Colors.transparent,
214:           elevation: 0,
215:           iconTheme: IconThemeData(color: textColor),
216:           title: Text(
217:             context.isArabic ? state.surah.nameAr : state.surah.nameEn,
218:             style: context.isArabic
219:                 ? AppTypography.surahTitle.copyWith(
220:                     color: primary,
221:                     fontSize: 24,
222:                   )
223:                 : AppTypography.titleLarge.copyWith(color: primary),
224:           ),
225:           centerTitle: true,
226:         ),
227: 
228:         Expanded(
229:           child: Padding(
230:             padding: const EdgeInsets.all(AppSpacing.lg),
231:             child: Column(
232:               mainAxisAlignment: MainAxisAlignment.center,
233:               crossAxisAlignment: CrossAxisAlignment.stretch,
234:               children: [
235:                 // Ayah Index label
236:                 Container(
237:                   alignment: Alignment.center,
238:                   padding: const EdgeInsets.symmetric(
239:                     horizontal: 16,
240:                     vertical: 8,
241:                   ),
242:                   margin: const EdgeInsets.symmetric(horizontal: 100),
243:                   decoration: BoxDecoration(
244:                     color: primary.withValues(alpha: 0.1),
245:                     borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
246:                   ),
247:                   child: Text(
248:                     '${context.isArabic ? "آية" : "Ayah"} ${ayah.numberInSurah}',
249:                     style: AppTypography.titleMedium.copyWith(color: primary),
250:                   ),
251:                 ),
252:                 const SizedBox(height: AppSpacing.xl),
253: 
254:                 // Ayah Text Area
255:                 Expanded(
256:                   child: Container(
257:                     padding: const EdgeInsets.all(AppSpacing.xl),
258:                     decoration: BoxDecoration(
259:                       color: isDark ? AppColors.darkCard : AppColors.lightCard,
260:                       borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
261:                       border: Border.all(color: primary.withValues(alpha: 0.1)),
262:                       boxShadow: [
263:                         BoxShadow(
264:                           color: isDark ? Colors.black26 : Colors.black12,
265:                           blurRadius: 10,
266:                           offset: const Offset(0, 4),
267:                         ),
268:                       ],
269:                     ),
270:                     child: Center(
271:                       child: SingleChildScrollView(
272:                         child: hasCheckpoint
273:                             ? _CheckpointReviewCard(
274:                                 state: state,
275:                                 isDark: isDark,
276:                               )
277:                             : state.isEvaluating
278:                             ? Column(
279:                                 mainAxisAlignment: MainAxisAlignment.center,
280:                                 children: [
281:                                   const CircularProgressIndicator(),
282:                                   const SizedBox(height: AppSpacing.md),
283:                                   Text(
284:                                     context.isArabic
285:                                         ? "جارِ التقييم..."
286:                                         : "Evaluating...",
287:                                     style: AppTypography.bodyLarge.copyWith(
288:                                       color: textColor,
289:                                     ),
290:                                   ),
291:                                 ],
292:                               )
293:                             : state.similarityScore != null
294:                             ? _EvaluationResult(
295:                                 state: state,
296:                                 ayahText: ayah.text,
297:                                 isDark: isDark,
298:                               )
299:                             // T013/T014: Show recording prompt while recording
300:                             // (correct text must not be revealed during recall).
301:                             // Show QcfHifzVerseView when verse is displayed normally.
302:                             : state.isRecording
303:                             ? Text(
304:                                 context.isArabic
305:                                     ? "يتم التسجيل، اقرأ الآية من حفظك..."
306:                                     : "Recording, recite from memory...",
307:                                 style: AppTypography.bodyLarge.copyWith(
308:                                   color: textColor,
309:                                   fontSize: 20,
310:                                 ),
311:                                 textAlign: TextAlign.center,
312:                               ).animate(target: 1).fade(end: 0.5)
313:                             : QcfHifzVerseView(
314:                                 surahNumber: state.surah.id,
315:                                 verseNumber: ayah.numberInSurah,
316:                                 fallbackText: ayah.text,
317:                                 isUnlocked: true,
318:                                 isMemorized:
319:                                     state
320:                                         .progressMap[ayah.numberInSurah]
321:                                         ?.status ==
322:                                     AyahStatus.memorized,
323:                                 displayMode: HifzVerseDisplayMode.single,
324:                                 textAlign: TextAlign.center,
325:                               ),
326:                       ),
327:                     ),
328:                   ),
329:                 ),
330:                 const SizedBox(height: AppSpacing.xl),
331: 
332:                 // Audio error banner
333:                 if (state.audioError != null)
334:                   Container(
335:                     margin: const EdgeInsets.only(bottom: AppSpacing.sm),
336:                     padding: const EdgeInsets.symmetric(
337:                       horizontal: 12,
338:                       vertical: 8,
339:                     ),
340:                     decoration: BoxDecoration(
341:                       color: Colors.red.withValues(alpha: 0.1),
342:                       borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
343:                       border: Border.all(
344:                         color: Colors.red.withValues(alpha: 0.3),
345:                       ),
346:                     ),
347:                     child: Row(
348:                       children: [
349:                         const Icon(
350:                           Icons.wifi_off_rounded,
351:                           color: Colors.red,
352:                           size: 18,
353:                         ),
354:                         const SizedBox(width: 8),
355:                         Expanded(
356:                           child: Text(
357:                             state.audioError!,
358:                             style: AppTypography.bodySmall.copyWith(
359:                               color: Colors.red,
360:                             ),
361:                           ),
362:                         ),
363:                       ],
364:                     ),
365:                   ),
366: 
367:                 // Controls Area
368:                 if (!hasCheckpoint &&
369:                     state.similarityScore == null &&
370:                     !state.isEvaluating) ...[
371:                   Row(
372:                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
373:                     children: [
374:                       // Listen Button
375:                       _ControlButton(
376:                         icon: state.isPlaying
377:                             ? Icons.pause_rounded
378:                             : Icons.headphones_rounded,
379:                         label: context.l10n.listen,
380:                         color: Colors.blue,
381:                         isDark: isDark,
382:                         isActive: state.isPlaying,
383:                         onTap: () {
384:                           if (state.isPlaying) {
385:                             context.read<HifzSessionCubit>().pauseAudio();
386:                           } else {
387:                             context.read<HifzSessionCubit>().playAudio();
388:                           }
389:                         },
390:                       ),
391: 
392:                       // Record / Stop Button
393:                       GestureDetector(
394:                         onTap: () {
395:                           if (state.isRecording) {
396:                             context.read<HifzSessionCubit>().stopRecording();
397:                           } else {
398:                             context.read<HifzSessionCubit>().startRecording();
399:                           }
400:                         },
401:                         child: AnimatedContainer(
402:                           duration: 300.ms,
403:                           height: 80,
404:                           width: 80,
405:                           decoration: BoxDecoration(
406:                             color: state.isRecording ? Colors.red : primary,
407:                             shape: BoxShape.circle,
408:                             boxShadow: [
409:                               if (state.isRecording)
410:                                 BoxShadow(
411:                                   color: Colors.red.withValues(alpha: 0.4),
412:                                   blurRadius: 15,
413:                                   spreadRadius: 5,
414:                                 ),
415:                             ],
416:                           ),
417:                           child: Icon(
418:                             state.isRecording
419:                                 ? Icons.stop_rounded
420:                                 : Icons.mic_rounded,
421:                             color: Colors.white,
422:                             size: 40,
423:                           ),
424:                         ),
425:                       ),
426: 
427:                       // BUG-1 FIX: Skip now calls skipAyah() which applies
428:                       // a soft penalty so skipped ayahs are rescheduled
429:                       _ControlButton(
430:                         icon: state.currentIndex == state.ayahs.length - 1
431:                             ? Icons.done_all_rounded
432:                             : Icons.skip_next_rounded,
433:                         label: state.currentIndex == state.ayahs.length - 1
434:                             ? (context.l10n.finish)
435:                             : (context.l10n.skip),
436:                         color: Colors.grey,
437:                         isDark: isDark,
438:                         isActive: false,
439:                         onTap: () {
440:                           if (state.currentIndex == state.ayahs.length - 1) {
441:                             Navigator.of(context).pop();
442:                           } else {
443:                             unawaited(_handleSkip(context));
444:                           }
445:                         },
446:                       ),
447:                     ],
448:                   ),
449:                 ],
450: 
451:                 // Result Controls
452:                 if (!hasCheckpoint &&
453:                     state.similarityScore != null &&
454:                     !state.isEvaluating) ...[
455:                   Row(
456:                     mainAxisAlignment: MainAxisAlignment.center,
457:                     children: [
458:                       // BUG-2 FIX: use state.passThreshold instead of hardcoded 0.85
459:                       if ((state.similarityScore ?? 0) < state.passThreshold)
460:                         Expanded(
461:                           child: ElevatedButton.icon(
462:                             onPressed: () =>
463:                                 context.read<HifzSessionCubit>().retryAyah(),
464:                             icon: const Icon(Icons.refresh_rounded),
465:                             label: Text(context.l10n.tryAgainAction),
466:                             style: ElevatedButton.styleFrom(
467:                               backgroundColor: Colors.orange,
468:                               foregroundColor: Colors.white,
469:                               padding: const EdgeInsets.symmetric(vertical: 16),
470:                             ),
471:                           ),
472:                         ),
473:                       if ((state.similarityScore ?? 0) < state.passThreshold)
474:                         const SizedBox(width: AppSpacing.md),
475: 
476:                       Expanded(
477:                         child: ElevatedButton.icon(
478:                           onPressed: () {
479:                             if (state.currentIndex == state.ayahs.length - 1) {
480:                               Navigator.of(context).pop();
481:                             } else {
482:                               context.read<HifzSessionCubit>().nextAyah();
483:                             }
484:                           },
485:                           icon: Icon(
486:                             state.currentIndex == state.ayahs.length - 1
487:                                 ? Icons.done_all_rounded
488:                                 : Icons.arrow_forward_rounded,
489:                           ),
490:                           label: Text(
491:                             state.currentIndex == state.ayahs.length - 1
492:                                 ? (context.isArabic
493:                                       ? 'إنهاء الجلسة'
494:                                       : 'Finish Session')
495:                                 : (context.isArabic
496:                                       ? 'الآية التالية'
497:                                       : 'Next Ayah'),
498:                           ),
499:                           style: ElevatedButton.styleFrom(
500:                             backgroundColor:
501:                                 // BUG-2 FIX: use state.passThreshold
502:                                 ((state.similarityScore ?? 0) >=
503:                                     state.passThreshold)
504:                                 ? Colors.green
505:                                 : primary,
506:                             foregroundColor: Colors.white,
507:                             padding: const EdgeInsets.symmetric(vertical: 16),
508:                           ),
509:                         ),
510:                       ),
511:                     ],
512:                   ),
513:                 ],
514: 
515:                 const SizedBox(height: AppSpacing.xl),
516:               ],
517:             ),
518:           ),
519:         ),
520:       ],
521:     );
522:   }
523: }
524: 
525: class _EvaluationResult extends StatelessWidget {
526:   const _EvaluationResult({
527:     required this.state,
528:     required this.ayahText,
529:     required this.isDark,
530:   });
531:   final HifzSessionLoaded state;
532:   final String ayahText;
533:   final bool isDark;
534: 
535:   @override
536:   Widget build(BuildContext context) {
537:     final score = (state.similarityScore ?? 0) * 100;
538:     // BUG-2 FIX: use state.passThreshold instead of hardcoded 85
539:     final pass = (state.similarityScore ?? 0) >= state.passThreshold;
540: 
541:     return Column(
542:       mainAxisAlignment: MainAxisAlignment.center,
543:       children: [
544:         Icon(
545:           pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
546:           color: pass ? Colors.green : Colors.redAccent,
547:           size: 64,
548:         ).animate().scale(delay: 100.ms),
549:         const SizedBox(height: AppSpacing.md),
550:         Text(
551:           '${score.toStringAsFixed(1)}%',
552:           style: AppTypography.displaySmall.copyWith(
553:             color: pass ? Colors.green : Colors.redAccent,
554:             fontWeight: FontWeight.bold,
555:           ),
556:         ).animate().fadeIn(),
557:         const SizedBox(height: AppSpacing.md),
558:         Text(
559:           pass
560:               ? (context.isArabic
561:                     ? 'ممتاز! حفظ متقن.'
562:                     : 'Excellent! Perfect memorization.')
563:               : (context.isArabic
564:                     ? 'تحتاج إلى مراجعة هذه الآية.'
565:                     : 'You need to review this Ayah.'),
566:           style: AppTypography.titleMedium.copyWith(
567:             color: isDark ? Colors.white70 : Colors.black87,
568:           ),
569:         ),
570:         const Divider(height: 40),
571:         Text(
572:           context.l10n.youRecited,
573:           style: AppTypography.labelSmall.copyWith(color: Colors.grey),
574:         ),
575:         const SizedBox(height: 8),
576:         Text(
577:           state.recognizedText.isEmpty
578:               ? (context.isArabic
579:                     ? "(لم يتم التعرف على صوت)"
580:                     : "(No voice recognized)")
581:               : state.recognizedText,
582:           style: AppTypography.bodyLarge.copyWith(
583:             color: isDark ? Colors.white54 : Colors.black54,
584:           ),
585:           textAlign: TextAlign.center,
586:           textDirection: TextDirection.rtl,
587:         ),
588:       ],
589:     );
590:   }
591: }
592: 
593: class _CheckpointReviewCard extends StatelessWidget {
594:   const _CheckpointReviewCard({required this.state, required this.isDark});
595: 
596:   final HifzSessionLoaded state;
597:   final bool isDark;
598: 
599:   @override
600:   Widget build(BuildContext context) {
601:     final checkpoint = state.completedCheckpoint ?? state.requiredCheckpoint!;
602:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
603:     final textColor = isDark
604:         ? AppColors.darkTextPrimary
605:         : AppColors.lightTextPrimary;
606:     final passed = state.completedCheckpoint != null;
607:     final failed =
608:         state.similarityScore != null &&
609:         (state.similarityScore ?? 0) < state.passThreshold;
610:     final isSmallFullSurah =
611:         state.surah.ayahCount <= 20 && checkpoint.isFullSurah;
612: 
613:     return Column(
614:       mainAxisAlignment: MainAxisAlignment.center,
615:       children: [
616:         Icon(
617:           passed ? Icons.verified_rounded : Icons.assignment_turned_in_rounded,
618:           color: passed ? Colors.green : AppColors.gold,
619:           size: 64,
620:         ).animate().scale(duration: 200.ms),
621:         const SizedBox(height: AppSpacing.md),
622:         Text(
623:           passed ? 'تم اجتياز المراجعة' : 'حان وقت المراجعة',
624:           style: AppTypography.titleLarge.copyWith(
625:             color: passed ? Colors.green : primary,
626:             fontWeight: FontWeight.w700,
627:           ),
628:           textAlign: TextAlign.center,
629:         ),
630:         const SizedBox(height: AppSpacing.sm),
631:         Text(
632:           isSmallFullSurah
633:               ? 'راجع السورة كاملة قبل إنهائها'
634:               : 'راجع الآيات من ${checkpoint.startAyah} إلى ${checkpoint.endAyah} قبل الانتقال للآية التالية',
635:           style: AppTypography.bodyLarge.copyWith(color: textColor),
636:           textAlign: TextAlign.center,
637:           textDirection: TextDirection.rtl,
638:         ),
639:         if (state.isEvaluating) ...[
640:           const SizedBox(height: AppSpacing.lg),
641:           const CircularProgressIndicator(),
642:           const SizedBox(height: AppSpacing.sm),
643:           Text(
644:             'جارِ تقييم المراجعة...',
645:             style: AppTypography.bodyMedium.copyWith(color: textColor),
646:           ),
647:         ] else if (state.isRecording) ...[
648:           const SizedBox(height: AppSpacing.lg),
649:           Text(
650:             'يتم التسجيل، اقرأ المقطع من حفظك...',
651:             style: AppTypography.bodyMedium.copyWith(color: textColor),
652:             textAlign: TextAlign.center,
653:           ),
654:           const SizedBox(height: AppSpacing.md),
655:           ElevatedButton.icon(
656:             onPressed: () => context.read<HifzSessionCubit>().stopRecording(),
657:             icon: const Icon(Icons.stop_rounded),
658:             label: const Text('إنهاء التسميع'),
659:             style: ElevatedButton.styleFrom(
660:               backgroundColor: Colors.red,
661:               foregroundColor: Colors.white,
662:               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
663:             ),
664:           ),
665:         ] else if (passed) ...[
666:           const SizedBox(height: AppSpacing.lg),
667:           ElevatedButton.icon(
668:             onPressed: () {
669:               if (state.currentIndex == state.ayahs.length - 1) {
670:                 Navigator.of(context).pop();
671:               } else {
672:                 context.read<HifzSessionCubit>().nextAyah();
673:               }
674:             },
675:             icon: Icon(
676:               state.currentIndex == state.ayahs.length - 1
677:                   ? Icons.done_all_rounded
678:                   : Icons.arrow_forward_rounded,
679:             ),
680:             label: Text(
681:               state.currentIndex == state.ayahs.length - 1
682:                   ? 'إنهاء الجلسة'
683:                   : 'الآية التالية',
684:             ),
685:             style: ElevatedButton.styleFrom(
686:               backgroundColor: Colors.green,
687:               foregroundColor: Colors.white,
688:               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
689:             ),
690:           ),
691:         ] else ...[
692:           if (failed) ...[
693:             const SizedBox(height: AppSpacing.md),
694:             Text(
695:               'لم يتم اجتياز المراجعة. حاول مرة أخرى.',
696:               style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent),
697:               textAlign: TextAlign.center,
698:             ),
699:           ],
700:           const SizedBox(height: AppSpacing.lg),
701:           ElevatedButton.icon(
702:             onPressed: () => context.read<HifzSessionCubit>().startRecording(),
703:             icon: const Icon(Icons.mic_rounded),
704:             label: const Text('ابدأ التسميع'),
705:             style: ElevatedButton.styleFrom(
706:               backgroundColor: primary,
707:               foregroundColor: Colors.white,
708:               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
709:             ),
710:           ),
711:         ],
712:       ],
713:     );
714:   }
715: }
716: 
717: class _ControlButton extends StatelessWidget {
718:   const _ControlButton({
719:     required this.icon,
720:     required this.label,
721:     required this.color,
722:     required this.isDark,
723:     required this.isActive,
724:     required this.onTap,
725:   });
726: 
727:   final IconData icon;
728:   final String label;
729:   final Color color;
730:   final bool isDark;
731:   final bool isActive;
732:   final VoidCallback onTap;
733: 
734:   @override
735:   Widget build(BuildContext context) {
736:     return GestureDetector(
737:       onTap: onTap,
738:       child: Column(
739:         mainAxisSize: MainAxisSize.min,
740:         children: [
741:           Container(
742:             padding: const EdgeInsets.all(16),
743:             decoration: BoxDecoration(
744:               color: isActive
745:                   ? color
746:                   : (isDark ? AppColors.darkCard : AppColors.lightCard),
747:               shape: BoxShape.circle,
748:               border: Border.all(
749:                 color: isActive ? color : color.withValues(alpha: 0.5),
750:                 width: 2,
751:               ),
752:             ),
753:             child: Icon(icon, color: isActive ? Colors.white : color, size: 28),
754:           ),
755:           const SizedBox(height: 8),
756:           Text(
757:             label,
758:             style: AppTypography.labelSmall.copyWith(
759:               color: isDark ? Colors.white70 : Colors.black87,
760:               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
761:             ),
762:           ),
763:         ],
764:       ),
765:     );
766:   }
767: }

(End of file - total 767 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 8.6s)

_Thinking:_

Let me look at the HifzSessionCubit to understand its state behavior. Let me also look at the progress entities and usecases.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\presentation\\cubits\\hifz_session_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\presentation\cubits\hifz_session_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'dart:async';
3: import 'package:equatable/equatable.dart';
4: import 'package:flutter_bloc/flutter_bloc.dart';
5: import 'package:speech_to_text/speech_to_text.dart';
6: import 'package:just_audio/just_audio.dart';
7: import 'package:string_similarity/string_similarity.dart';
8: import 'package:permission_handler/permission_handler.dart';
9: 
10: import '../../domain/hifz_unlock_rules.dart';
11: import '../../../quran/domain/entities/quran_entities.dart';
12: import '../../../quran/domain/usecases/get_surahs_usecase.dart';
13: import '../../data/models/ayah_progress_model.dart';
14: import '../../domain/entities/hifz_entities.dart';
15: import '../../domain/usecases/get_hifz_progress_usecase.dart';
16: import '../../domain/usecases/save_ayah_progress_usecase.dart';
17: import '../../../../core/services/audio_cache_service.dart';
18: import '../../../../core/utils/arabic_normalizer.dart';
19: import '../../../../core/services/haptic_service.dart';
20: import '../../../../core/services/streak_service.dart';
21: import '../../../../core/services/xp_service.dart';
22: import '../../../../core/services/achievement_service.dart';
23: import '../../../settings/domain/repositories/settings_repository.dart';
24: import '../../../../core/utils/talia_logger.dart';
25: 
26: part 'hifz_session_state.dart';
27: 
28: class HifzSessionCubit extends Cubit<HifzSessionState> {
29:   HifzSessionCubit(
30:     this._getSurahs,
31:     this._getDetail,
32:     this._saveProgress,
33:     this._getSurahProgress,
34:     this._getAllSurahProgress,
35:     this._getPath,
36:     this._generateSegments,
37:     this._checkNextAyahUnlock,
38:     this._getNextRequiredCheckpoint,
39:     this._getPassedCheckpointKeys,
40:     this._markCheckpointPassed,
41:     this._settings,
42:     this._streakService,
43:     this._xpService,
44:     this._achievementService,
45:   ) : super(const HifzSessionInitial()) {
46:     _initSpeech();
47:     // BUG-NEW-004 FIX: Store subscription reference
48:     _playerStateSub = _player.playerStateStream.listen((state) {
49:       if (state.processingState == ProcessingState.completed) {
50:         if (!isClosed && this.state is HifzSessionLoaded) {
51:           emit((this.state as HifzSessionLoaded).copyWith(isPlaying: false));
52:         }
53:       }
54:     });
55:   }
56: 
57:   final GetSurahsUsecase _getSurahs;
58:   final GetSurahDetailUsecase _getDetail;
59:   final SaveAyahProgressUsecase _saveProgress;
60:   final GetProgressForSurahUsecase _getSurahProgress;
61:   final GetHifzProgressUsecase _getAllSurahProgress;
62:   final GetHifzPathUsecase _getPath;
63:   final GenerateHifzSegmentsUsecase _generateSegments;
64:   final CheckNextAyahUnlockUsecase _checkNextAyahUnlock;
65:   final GetNextRequiredReviewCheckpointUsecase _getNextRequiredCheckpoint;
66:   final GetPassedCheckpointKeysUsecase _getPassedCheckpointKeys;
67:   final MarkCheckpointReviewPassedUsecase _markCheckpointPassed;
68:   // ARCH-3 FIX: SettingsRepository instead of direct SharedPreferences access.
69:   final SettingsRepository _settings;
70:   final StreakService _streakService;
71:   final XpService _xpService;
72:   final AchievementService _achievementService;
73: 
74:   final SpeechToText _speechToText = SpeechToText();
75:   final AudioPlayer _player = AudioPlayer();
76:   // BUG-NEW-004 FIX: Store subscription so it can be cancelled in close()
77:   StreamSubscription<PlayerState>? _playerStateSub;
78: 
79:   List<Ayah> _ayahs = [];
80:   Map<int, AyahProgressModel> _progressMap = {};
81:   List<HifzSegment> _segments = [];
82:   Set<String> _passedCheckpointKeys = {};
83:   late Surah _surah;
84: 
85:   bool _speechEnabled = false;
86: 
87:   Future<void> _initSpeech() async {
88:     _speechEnabled = await _speechToText.initialize();
89:   }
90: 
91:   AyahProgressModel _toProgressModel(AyahProgress progress) {
92:     if (progress is AyahProgressModel) return progress;
93:     return AyahProgressModel(
94:       surahId: progress.surahId,
95:       ayahNumber: progress.ayahNumber,
96:       status: progress.status,
97:       repetitions: progress.repetitions,
98:       nextReviewDate: progress.nextReviewDate,
99:       lastReviewDate: progress.lastReviewDate,
100:     );
101:   }
102: 
103:   Future<void> startSession(int surahId, int startAyah) async {
104:     emit(const HifzSessionLoading());
105: 
106:     final unlockError = await _validateSurahAccess(surahId);
107:     if (unlockError != null) {
108:       emit(HifzSessionError(unlockError));
109:       return;
110:     }
111: 
112:     final progressResult = await _getSurahProgress(surahId);
113:     final progressFailure = progressResult.fold((f) => f, (_) => null);
114:     if (progressFailure != null) {
115:       emit(HifzSessionError(progressFailure.message));
116:       return;
117:     }
118:     final existingProgress = progressResult
119:         .getOrElse(() => const [])
120:         .map(_toProgressModel)
121:         .toList();
122: 
123:     final result = await _getDetail(surahId);
124:     await result.fold((f) async => emit(HifzSessionError(f.message)), (
125:       detail,
126:     ) async {
127:       _surah = detail.surah;
128:       _ayahs = detail.ayahs;
129:       _segments = _generateSegments(
130:         surahId: _surah.id,
131:         totalAyahs: _surah.ayahCount,
132:       );
133: 
134:       final checkpointResult = await _getPassedCheckpointKeys(surahId);
135:       final checkpointFailure = checkpointResult.fold((f) => f, (_) => null);
136:       if (checkpointFailure != null) {
137:         emit(HifzSessionError(checkpointFailure.message));
138:         return;
139:       }
140:       _passedCheckpointKeys = checkpointResult.getOrElse(() => const {});
141: 
142:       final map = <int, AyahProgressModel>{};
143:       for (final p in existingProgress) {
144:         map[p.ayahNumber] = p;
145:       }
146:       for (final a in _ayahs) {
147:         if (!map.containsKey(a.numberInSurah)) {
148:           map[a.numberInSurah] = AyahProgressModel.initial(
149:             surahId,
150:             a.numberInSurah,
151:           );
152:         }
153:       }
154:       _progressMap = map;
155: 
156:       // Find the index of the startAyah
157:       int startIndex = 0;
158:       if (startAyah > 0) {
159:         final idx = _ayahs.indexWhere((a) => a.numberInSurah == startAyah);
160:         if (idx != -1) startIndex = idx;
161:       }
162: 
163:       final blockedCheckpoint = _firstBlockingCheckpointBeforeStart(
164:         _ayahs[startIndex].numberInSurah,
165:       );
166:       if (blockedCheckpoint != null) {
167:         final idx = _ayahs.indexWhere(
168:           (a) => a.numberInSurah == blockedCheckpoint.endAyah,
169:         );
170:         if (idx != -1) startIndex = idx;
171:       }
172:       final requiredCheckpoint =
173:           blockedCheckpoint ??
174:           _requiredCheckpointAfterAyah(_ayahs[startIndex].numberInSurah);
175: 
176:       emit(
177:         HifzSessionLoaded(
178:           surah: _surah,
179:           ayahs: _ayahs,
180:           progressMap: map,
181:           currentIndex: startIndex,
182:           passThreshold: _settings.getSimilarityThreshold(), // BUG-2 FIX
183:           segments: _segments,
184:           passedCheckpointKeys: _passedCheckpointKeys,
185:           requiredCheckpoint: requiredCheckpoint,
186:         ),
187:       );
188: 
189:       // Prefetch audio for the next few ayahs in the background.
190:       // Bounded to current + next 4 to avoid downloading the entire surah at once.
191:       const int prefetchWindow = 5;
192:       final prefetchNumbers = _ayahs
193:           .skip(startIndex)
194:           .take(prefetchWindow)
195:           .map((a) => a.numberInSurah)
196:           .toList();
197:       unawaited(
198:         AudioCacheService.instance.prefetchSession(
199:           surahId: surahId,
200:           ayahNumbers: prefetchNumbers,
201:         ),
202:       );
203:     });
204:   }
205: 
206:   HifzSegment? _firstBlockingCheckpointBeforeStart(int ayahNumber) {
207:     for (final segment in _segments) {
208:       if (segment.endAyah < ayahNumber &&
209:           !_passedCheckpointKeys.contains(segment.key)) {
210:         return segment;
211:       }
212:     }
213:     return null;
214:   }
215: 
216:   HifzSegment? _requiredCheckpointAfterAyah(int ayahNumber) {
217:     final checkpoint = _getNextRequiredCheckpoint(
218:       segments: _segments,
219:       passedSegmentKeys: _passedCheckpointKeys,
220:       progressMap: Map<int, AyahProgress>.from(_progressMap),
221:     );
222:     if (checkpoint == null) return null;
223:     return checkpoint.endAyah == ayahNumber ? checkpoint : null;
224:   }
225: 
226:   String _checkpointExpectedText(HifzSegment checkpoint) {
227:     return _ayahs
228:         .where(
229:           (ayah) =>
230:               ayah.numberInSurah >= checkpoint.startAyah &&
231:               ayah.numberInSurah <= checkpoint.endAyah,
232:         )
233:         .map((ayah) => ayah.text)
234:         .join(' ');
235:   }
236: 
237:   Future<void> playAudio() async {
238:     if (state is! HifzSessionLoaded) return;
239:     final st = state as HifzSessionLoaded;
240: 
241:     emit(st.copyWith(isPlaying: true));
242: 
243:     try {
244:       final ayah = st.ayahs[st.currentIndex];
245:       final audioSource = await AudioCacheService.instance.getAudioSource(
246:         st.surah.id,
247:         ayah.numberInSurah,
248:       );
249: 
250:       await AudioCacheService.playFromSource(_player, audioSource);
251:     } catch (e) {
252:       emit(
253:         st.copyWith(
254:           isPlaying: false,
255:           audioError: 'فشل تشغيل الصوت. تحقق من الاتصال بالإنترنت.',
256:         ),
257:       );
258:       // Clear the error after showing it
259:       Future.delayed(const Duration(seconds: 3), () {
260:         if (isClosed) return;
261:         if (state is HifzSessionLoaded) {
262:           emit((state as HifzSessionLoaded).copyWith(clearAudioError: true));
263:         }
264:       });
265:     }
266:   }
267: 
268:   Future<String?> _validateSurahAccess(int surahId) async {
269:     final pathResult = await _getPath();
270:     final selectedPath = pathResult.fold((_) => null, (path) => path);
271:     if (selectedPath == null) return null;
272: 
273:     final surahsResult = await _getSurahs();
274:     final progressResult = await _getAllSurahProgress();
275: 
276:     final surahs = surahsResult.fold((_) => null, (items) => items);
277:     final progress = progressResult.fold((_) => null, (items) => items);
278:     if (surahs == null || progress == null) return null;
279: 
280:     final orderedSurahs = sortSurahsForHifzPath(
281:       surahs: surahs,
282:       path: selectedPath,
283:     );
284:     final progressMap = {for (final item in progress) item.surahId: item};
285:     final unlockedSurahIds = buildUnlockedSurahIds(
286:       orderedSurahs: orderedSurahs,
287:       progressMap: progressMap,
288:     );
289: 
290:     if (unlockedSurahIds.contains(surahId)) return null;
291: 
292:     final targetIndex = orderedSurahs.indexWhere(
293:       (surah) => surah.id == surahId,
294:     );
295:     if (targetIndex <= 0) return null;
296: 
297:     final requiredSurah = orderedSurahs[targetIndex - 1];
298:     return 'هذه السورة مقفلة حالياً. أكمل حفظ سورة ${requiredSurah.nameAr} أولاً لفتحها.';
299:   }
300: 
301:   Future<void> pauseAudio() async {
302:     if (state is! HifzSessionLoaded) return;
303:     await _player.pause();
304:     emit((state as HifzSessionLoaded).copyWith(isPlaying: false));
305:   }
306: 
307:   Future<void> startRecording() async {
308:     if (state is! HifzSessionLoaded) return;
309:     final st = state as HifzSessionLoaded;
310: 
311:     if (st.isPlaying) await pauseAudio();
312: 
313:     // Check permissions
314:     var status = await Permission.microphone.status;
315:     if (!status.isGranted) {
316:       status = await Permission.microphone.request();
317:       if (!status.isGranted) {
318:         // UX-013: Emit error so UI can guide the user
319:         emit(
320:           st.copyWith(
321:             audioError:
322:                 'يحتاج التطبيق إذن الميكروفون للتسميع الصوتي. يرجى السماح من إعدادات الجهاز.',
323:           ),
324:         );
325:         Future.delayed(const Duration(seconds: 5), () {
326:           if (isClosed) return;
327:           if (state is HifzSessionLoaded) {
328:             emit((state as HifzSessionLoaded).copyWith(clearAudioError: true));
329:           }
330:         });
331:         return;
332:       }
333:     }
334: 
335:     if (!_speechEnabled) {
336:       await _initSpeech();
337:     }
338: 
339:     if (_speechEnabled) {
340:       emit(
341:         st.copyWith(
342:           isRecording: true,
343:           clearScore: true,
344:           recognizedText: '',
345:           clearCompletedCheckpoint: true,
346:           isCheckpointReviewActive: st.requiredCheckpoint != null,
347:         ),
348:       );
349:       await _speechToText.listen(
350:         onResult: (result) {
351:           if (state is HifzSessionLoaded) {
352:             emit(
353:               (state as HifzSessionLoaded).copyWith(
354:                 recognizedText: result.recognizedWords,
355:               ),
356:             );
357:           }
358:         },
359:         localeId: 'ar-SA',
360:         pauseFor: const Duration(
361:           seconds: 5,
362:         ), // auto-stop if silent for 5 seconds
363:       );
364:     }
365:   }
366: 
367:   Future<void> stopRecording() async {
368:     if (state is! HifzSessionLoaded) return;
369:     final st = state as HifzSessionLoaded;
370: 
371:     if (st.isRecording) {
372:       await _speechToText.stop();
373:       emit(st.copyWith(isRecording: false, isEvaluating: true));
374: 
375:       // Delay slightly so the UI can show "Evaluating..."
376:       await Future.delayed(const Duration(milliseconds: 500));
377:       await _evaluateRecitation();
378:     }
379:   }
380: 
381:   Future<void> _evaluateRecitation() async {
382:     if (state is! HifzSessionLoaded) return;
383:     final st = state as HifzSessionLoaded;
384: 
385:     final ayah = st.ayahs[st.currentIndex];
386:     final checkpoint = st.isCheckpointReviewActive
387:         ? st.requiredCheckpoint
388:         : null;
389: 
390:     final expectedText = checkpoint == null
391:         ? ayah.text
392:         : _checkpointExpectedText(checkpoint);
393:     final normalizedExpected = ArabicNormalizer.normalize(expectedText);
394:     final normalizedSpoken = ArabicNormalizer.normalize(st.recognizedText);
395: 
396:     // BUG-010: If STT returned empty, don't count as failure
397:     if (normalizedSpoken.isEmpty) {
398:       emit(
399:         st.copyWith(isEvaluating: false, clearScore: true, recognizedText: ''),
400:       );
401:       return;
402:     }
403: 
404:     double score = 0.0;
405:     // Dice's Coefficient to find similarity
406:     score = normalizedExpected.similarityTo(normalizedSpoken);
407: 
408:     final threshold = _settings.getSimilarityThreshold();
409:     final pass = score >= threshold;
410: 
411:     if (checkpoint != null) {
412:       if (pass) {
413:         final saveResult = await _markCheckpointPassed(checkpoint);
414:         final failure = saveResult.fold((f) => f, (_) => null);
415:         if (failure != null) {
416:           TaliaLogger.e(
417:             'Failed to save checkpoint progress in session',
418:             failure,
419:             StackTrace.current,
420:           );
421:           emit(
422:             st.copyWith(
423:               isEvaluating: false,
424:               audioError: 'فشل حفظ تقدم المراجعة. حاول مرة أخرى.',
425:               isCheckpointReviewActive: false,
426:             ),
427:           );
428:           return;
429:         }
430:         _passedCheckpointKeys = {..._passedCheckpointKeys, checkpoint.key};
431:       }
432: 
433:       if (pass) {
434:         try {
435:           await _streakService.recordActivity(activityDelta: 1);
436:           await _xpService.addXp('daily_review');
437:           final newAwards = await _achievementService
438:               .checkAndUnlockCertificates();
439:           if (newAwards.isNotEmpty && state is HifzSessionLoaded) {
440:             final prevState = state as HifzSessionLoaded;
441:             emit(
442:               CertificatesEarned(awards: newAwards, previousState: prevState),
443:             );
444:             await Future.delayed(const Duration(milliseconds: 100));
445:             if (!isClosed) emit(prevState);
446:           }
447:         } catch (e, stack) {
448:           TaliaLogger.e('Non-critical: Failed to record streak/xp', e, stack);
449:         }
450:       }
451:     } else {
452:       // Update progress with Soft Penalty instead of Hard Reset
453:       var currentProgress = _progressMap[ayah.numberInSurah];
454:       if (currentProgress != null) {
455:         if (pass) {
456:           currentProgress = currentProgress.advanceWithSpacedRepetition();
457:         } else {
458:           // Soft Penalty: decrease repetitions by 1 (min 0) and reschedule review
459:           currentProgress = currentProgress.softPenalty();
460:         }
461:         _progressMap[ayah.numberInSurah] = currentProgress;
462:         final saveResult = await _saveProgress(currentProgress);
463:         final failure = saveResult.fold((f) => f, (_) => null);
464:         if (failure != null) {
465:           TaliaLogger.e(
466:             'Failed to save ayah progress in session',
467:             failure,
468:             StackTrace.current,
469:           );
470:           emit(
471:             st.copyWith(
472:               isEvaluating: false,
473:               audioError: 'فشل حفظ تقدم الحفظ. حاول مرة أخرى.',
474:             ),
475:           );
476:           Future.delayed(const Duration(seconds: 4), () {
477:             if (isClosed) return;
478:             if (state is HifzSessionLoaded) {
479:               emit(
480:                 (state as HifzSessionLoaded).copyWith(clearAudioError: true),
481:               );
482:             }
483:           });
484:           return;
485:         }
486: 
487:         if (pass) {
488:           try {
489:             await _streakService.recordActivity(activityDelta: 1);
490:             await _xpService.addXp('ayah_memorized');
491:             final newAwards = await _achievementService
492:                 .checkAndUnlockCertificates();
493:             if (newAwards.isNotEmpty && state is HifzSessionLoaded) {
494:               final prevState = state as HifzSessionLoaded;
495:               emit(
496:                 CertificatesEarned(awards: newAwards, previousState: prevState),
497:               );
498:               await Future.delayed(const Duration(milliseconds: 100));
499:               if (!isClosed) emit(prevState);
500:             }
501:           } catch (e, stack) {
502:             TaliaLogger.e('Non-critical: Failed to record streak/xp', e, stack);
503:           }
504:         }
505:       }
506:     }
507: 
508:     // Haptic feedback on evaluation result
509:     if (pass) {
510:       unawaited(HapticService.success());
511:     } else {
512:       unawaited(HapticService.error());
513:     }
514: 
515:     emit(
516:       st.copyWith(
517:         isEvaluating: false,
518:         similarityScore: score,
519:         progressMap: Map.from(_progressMap),
520:         passedCheckpointKeys: _passedCheckpointKeys,
521:         requiredCheckpoint: pass && checkpoint == null
522:             ? _requiredCheckpointAfterAyah(ayah.numberInSurah)
523:             : null,
524:         clearRequiredCheckpoint: pass && checkpoint != null,
525:         completedCheckpoint: pass && checkpoint != null ? checkpoint : null,
526:         isCheckpointReviewActive: false,
527:         passThreshold: threshold, // BUG-2 FIX: keep threshold in sync
528:       ),
529:     );
530:   }
531: 
532:   void nextAyah() {
533:     if (state is! HifzSessionLoaded) return;
534:     final st = state as HifzSessionLoaded;
535:     if (st.currentIndex < st.ayahs.length - 1) {
536:       final currentAyah = st.ayahs[st.currentIndex].numberInSurah;
537:       final canUnlock = _checkNextAyahUnlock(
538:         currentAyah: currentAyah,
539:         totalAyahs: st.surah.ayahCount,
540:         segments: _segments,
541:         passedSegmentKeys: _passedCheckpointKeys,
542:       );
543:       if (!canUnlock) {
544:         emit(
545:           st.copyWith(
546:             requiredCheckpoint: _requiredCheckpointAfterAyah(currentAyah),
547:             clearCompletedCheckpoint: true,
548:           ),
549:         );
550:         return;
551:       }
552: 
553:       HapticService.selection();
554:       final nextIndex = st.currentIndex + 1;
555:       emit(
556:         st.copyWith(
557:           currentIndex: nextIndex,
558:           clearScore: true,
559:           recognizedText: '',
560:           clearRequiredCheckpoint: true,
561:           clearCompletedCheckpoint: true,
562:         ),
563:       );
564:       // Sliding prefetch: ensure audio is cached for the next 2 upcoming ayahs.
565:       const int slideAhead = 2;
566:       final upcomingNumbers = _ayahs
567:           .skip(nextIndex)
568:           .take(slideAhead)
569:           .map((a) => a.numberInSurah)
570:           .toList();
571:       if (upcomingNumbers.isNotEmpty) {
572:         unawaited(
573:           AudioCacheService.instance.prefetchSession(
574:             surahId: st.surah.id,
575:             ayahNumbers: upcomingNumbers,
576:           ),
577:         );
578:       }
579:     }
580:   }
581: 
582:   void retryAyah() {
583:     if (state is! HifzSessionLoaded) return;
584:     emit(
585:       (state as HifzSessionLoaded).copyWith(
586:         clearScore: true,
587:         recognizedText: '',
588:       ),
589:     );
590:   }
591: 
592:   /// BUG-1 FIX: skipAyah applies a softPenalty to the current ayah so skips
593:   /// are not silently ignored — they are rescheduled without a full reset.
594:   Future<void> skipAyah() async {
595:     if (state is! HifzSessionLoaded) return;
596:     final st = state as HifzSessionLoaded;
597:     final ayah = st.ayahs[st.currentIndex];
598: 
599:     var currentProgress = _progressMap[ayah.numberInSurah];
600:     if (currentProgress != null &&
601:         currentProgress.status != AyahStatus.notStarted) {
602:       // Apply soft penalty: moves ayah back one rep & schedules review tomorrow
603:       currentProgress = currentProgress.softPenalty();
604:       _progressMap[ayah.numberInSurah] = currentProgress;
605:       await _saveProgress(currentProgress);
606:     }
607: 
608:     unawaited(HapticService.selection());
609: 
610:     if (st.currentIndex < st.ayahs.length - 1) {
611:       final canUnlock = _checkNextAyahUnlock(
612:         currentAyah: ayah.numberInSurah,
613:         totalAyahs: st.surah.ayahCount,
614:         segments: _segments,
615:         passedSegmentKeys: _passedCheckpointKeys,
616:       );
617:       if (!canUnlock) {
618:         emit(
619:           st.copyWith(
620:             requiredCheckpoint: _requiredCheckpointAfterAyah(
621:               ayah.numberInSurah,
622:             ),
623:             progressMap: Map.from(_progressMap),
624:           ),
625:         );
626:         return;
627:       }
628: 
629:       emit(
630:         st.copyWith(
631:           currentIndex: st.currentIndex + 1,
632:           clearScore: true,
633:           recognizedText: '',
634:           progressMap: Map.from(_progressMap),
635:           clearRequiredCheckpoint: true,
636:           clearCompletedCheckpoint: true,
637:         ),
638:       );
639:     }
640:     // If last ayah, just let the UI handle navigation via the finish button
641:   }
642: 
643:   @override
644:   Future<void> close() {
645:     _playerStateSub?.cancel(); // BUG-NEW-004 FIX: Cancel subscription
646:     _player.dispose();
647:     _speechToText.cancel();
648:     return super.close();
649:   }
650: }
651: 

(End of file - total 651 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 9.6s)

_Thinking:_

Let me look at the kids journey and key widgets, and the kids_journey_cubit.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\cubits\\kids_journey_cubit.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\cubits\kids_journey_cubit.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/foundation.dart';
2: import 'package:equatable/equatable.dart';
3: import 'package:flutter_bloc/flutter_bloc.dart';
4: 
5: import '../../../quran/domain/repositories/quran_repository.dart';
6: import '../../domain/entities/memorization_entities.dart';
7: import '../../domain/usecases/memorization_plus_usecases.dart';
8: 
9: part 'kids_journey_state.dart';
10: 
11: class KidsJourneyCubit extends Cubit<KidsJourneyState> {
12:   KidsJourneyCubit(
13:     this._getJourney,
14:     this._getKidsProgress,
15:     this._remoteLink,
16:     this._quranRepository,
17:   ) : super(const KidsJourneyInitial());
18: 
19:   final GetKidsJourneyUsecase _getJourney;
20:   final GetKidsProgressUsecase _getKidsProgress;
21:   final ParentRemoteLinkUsecase _remoteLink;
22:   final QuranRepository _quranRepository;
23: 
24:   Future<void> load({required int surahId}) async {
25:     emit(const KidsJourneyLoading());
26:     final journeyResult = await _getJourney(
27:       GetKidsJourneyParams(surahId: surahId),
28:     );
29:     final progressResult = await _getKidsProgress();
30: 
31:     final failure =
32:         journeyResult.fold((f) => f, (_) => null) ??
33:         progressResult.fold((f) => f, (_) => null);
34:     if (failure != null) {
35:       emit(KidsJourneyError(failure.message));
36:       return;
37:     }
38: 
39:     // Fetch surah name — gracefully falls back to null on failure
40:     String? surahName;
41:     final surahResult = await _quranRepository.getSurahDetail(surahId);
42:     surahResult.fold((_) => null, (detail) => surahName = detail.surah.nameAr);
43: 
44:     emit(
45:       KidsJourneyLoaded(
46:         surahId: surahId,
47:         stages: journeyResult.getOrElse(() => const []),
48:         progress: progressResult.getOrElse(() => const KidsProgress.initial()),
49:         surahName: surahName,
50:       ),
51:     );
52:   }
53: 
54:   Future<void> createRemoteLinkQr() async {
55:     final current = state;
56:     if (current is! KidsJourneyLoaded) return;
57:     emit(current.copyWith(isCreatingLink: true, clearMessage: true));
58:     final result = await _remoteLink.createChildLinkToken();
59:     result.fold(
60:       (failure) => emit(
61:         current.copyWith(
62:           isCreatingLink: false,
63:           message: failure.message,
64:           clearQrPayload: true,
65:         ),
66:       ),
67:       (token) => emit(
68:         current.copyWith(
69:           isCreatingLink: false,
70:           qrPayload: 'talia-kids-link:$token',
71:           message: 'تم إنشاء رمز الربط. صالح لمدة 10 دقائق.',
72:         ),
73:       ),
74:     );
75:   }
76: }
77: 

(End of file - total 77 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\pages\\kids_gamified_listen_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\pages\kids_gamified_listen_page.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/material.dart';
2: import 'package:flutter_bloc/flutter_bloc.dart';
3: import 'package:go_router/go_router.dart';
4: 
5: import '../../../../core/constants/app_spacing.dart';
6: import '../../../../core/di/injection.dart';
7: import '../../../../core/extensions/context_extensions.dart';
8: import '../../../../core/router/app_router.dart';
9: import '../../../../core/theme/app_typography.dart';
10: import '../../../../core/widgets/state_widgets.dart';
11: import '../cubits/kids_mode_cubit.dart';
12: import '../theme/kids_theme.dart';
13: import '../widgets/kids_ayah_card.dart';
14: 
15: class KidsGamifiedListenPage extends StatelessWidget {
16:   const KidsGamifiedListenPage({
17:     super.key,
18:     required this.surahId,
19:     required this.ayahNumber,
20:     required this.ayahText,
21:   });
22: 
23:   final int surahId;
24:   final int ayahNumber;
25:   final String ayahText;
26: 
27:   @override
28:   Widget build(BuildContext context) {
29:     return BlocProvider(
30:       create: (_) =>
31:           getIt<KidsModeCubit>()..load(surahId, ayahNumber, ayahText),
32:       child: _KidsGamifiedListenView(
33:         surahId: surahId,
34:         ayahNumber: ayahNumber,
35:         ayahText: ayahText,
36:       ),
37:     );
38:   }
39: }
40: 
41: class _KidsGamifiedListenView extends StatelessWidget {
42:   const _KidsGamifiedListenView({
43:     required this.surahId,
44:     required this.ayahNumber,
45:     required this.ayahText,
46:   });
47: 
48:   final int surahId;
49:   final int ayahNumber;
50:   final String ayahText;
51: 
52:   @override
53:   Widget build(BuildContext context) {
54:     return Scaffold(
55:       backgroundColor: KidsTheme.nightSkyDark,
56:       body: BlocConsumer<KidsModeCubit, KidsModeState>(
57:         listenWhen: (previous, current) {
58:           final wasCompleted =
59:               previous is KidsModeLoaded && previous.isCompleted;
60:           final isCompleted = current is KidsModeLoaded && current.isCompleted;
61:           return current is KidsModeLoaded &&
62:               (current.audioError != null || (isCompleted && !wasCompleted));
63:         },
64:         listener: (context, state) {
65:           if (state is KidsModeLoaded && state.audioError != null) {
66:             ScaffoldMessenger.of(context).showSnackBar(
67:               SnackBar(
68:                 content: Text(context.l10n.kidsGamifiedAudioUnavailable),
69:               ),
70:             );
71:           }
72:           if (state is KidsModeLoaded && state.isCompleted) {
73:             context.push(
74:               '${AppRoutes.memorizationPlusKidsCompletion}'
75:               '?surahId=${state.surahId}'
76:               '&completedAyahNumber=${state.ayahNumber}'
77:               '&starsEarned=${state.progress.starsForLevel}',
78:             );
79:           }
80:         },
81:         builder: (context, state) {
82:           if (state is KidsModeInitial || state is KidsModeLoading) {
83:             return const Center(child: LoadingWidget());
84:           }
85: 
86:           if (state is KidsModeError) {
87:             return ErrorStateWidget(
88:               message: state.message,
89:               onRetry: () => context.read<KidsModeCubit>().load(
90:                 surahId,
91:                 ayahNumber,
92:                 ayahText,
93:               ),
94:             );
95:           }
96: 
97:           if (state is! KidsModeLoaded) return const SizedBox.shrink();
98: 
99:           return KidsGamifiedListenContent(
100:             state: state,
101:             onBack: () => context.canPop() ? context.pop() : context.go('/'),
102:             onPlayPause: () {
103:               final cubit = context.read<KidsModeCubit>();
104:               if (state.isPlaying) {
105:                 cubit.stopAudio();
106:               } else {
107:                 cubit.playAudio();
108:               }
109:             },
110:             onRecordRecitation: () =>
111:                 context.read<KidsModeCubit>().startRecording(),
112:           );
113:         },
114:       ),
115:     );
116:   }
117: }
118: 
119: @visibleForTesting
120: class KidsGamifiedListenContent extends StatelessWidget {
121:   const KidsGamifiedListenContent({
122:     super.key,
123:     required this.state,
124:     required this.onBack,
125:     required this.onPlayPause,
126:     required this.onRecordRecitation,
127:   });
128: 
129:   final KidsModeLoaded state;
130:   final VoidCallback onBack;
131:   final VoidCallback onPlayPause;
132:   final VoidCallback onRecordRecitation;
133: 
134:   @override
135:   Widget build(BuildContext context) {
136:     final audioUnavailable = state.audioError != null;
137: 
138:     return Container(
139:       decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
140:       child: Scaffold(
141:         backgroundColor: Colors.transparent,
142:         body: SafeArea(
143:           child: Column(
144:             children: [
145:               _KidsGamifiedListenAppBar(onBack: onBack),
146:               Expanded(
147:                 child: CustomScrollView(
148:                   key: const PageStorageKey<String>('kids-gamified-listen'),
149:                   physics: const AlwaysScrollableScrollPhysics(),
150:                   slivers: [
151:                     SliverPadding(
152:                       padding: const EdgeInsets.fromLTRB(
153:                         AppSpacing.lg,
154:                         AppSpacing.md,
155:                         AppSpacing.lg,
156:                         AppSpacing.xl,
157:                       ),
158:                       sliver: SliverList.list(
159:                         children: [
160:                           KidsAyahCard(
161:                             surahId: state.surahId,
162:                             ayahNumber: state.ayahNumber,
163:                             ayahText: state.ayahText,
164:                             isCompleted: state.isCompleted,
165:                             // isBuffering is true only during URL loading/buffering,
166:                             // not during actual playback — more accurate than isPlaying
167:                             isAudioLoading: state.isBuffering,
168:                             audioUnavailable: audioUnavailable,
169:                           ),
170:                           const SizedBox(height: AppSpacing.lg),
171:                           _KidsGamifiedLoopIndicator(state: state),
172:                           const SizedBox(height: AppSpacing.xl),
173:                           _KidsGamifiedAudioControls(
174:                             state: state,
175:                             onPlayPause: onPlayPause,
176:                             onRecordRecitation: onRecordRecitation,
177:                           ),
178:                           const SizedBox(height: 96),
179:                         ],
180:                       ),
181:                     ),
182:                   ],
183:                 ),
184:               ),
185:             ],
186:           ),
187:         ),
188:       ),
189:     );
190:   }
191: }
192: 
193: class _KidsGamifiedListenAppBar extends StatelessWidget {
194:   const _KidsGamifiedListenAppBar({required this.onBack});
195: 
196:   final VoidCallback onBack;
197: 
198:   @override
199:   Widget build(BuildContext context) {
200:     return Padding(
201:       padding: const EdgeInsets.fromLTRB(
202:         AppSpacing.sm,
203:         AppSpacing.sm,
204:         AppSpacing.lg,
205:         AppSpacing.sm,
206:       ),
207:       child: Row(
208:         children: [
209:           IconButton(
210:             tooltip: MaterialLocalizations.of(context).backButtonTooltip,
211:             onPressed: onBack,
212:             icon: const Icon(Icons.arrow_back_ios_new_rounded),
213:             color: Colors.white,
214:           ),
215:           const SizedBox(width: AppSpacing.sm),
216:           Expanded(
217:             child: Text(
218:               context.l10n.kidsGamifiedListenAndRepeat,
219:               maxLines: 1,
220:               overflow: TextOverflow.ellipsis,
221:               style: AppTypography.titleLarge.copyWith(
222:                 color: Colors.white,
223:                 fontFamily: 'Amiri',
224:                 letterSpacing: 0,
225:               ),
226:             ),
227:           ),
228:         ],
229:       ),
230:     );
231:   }
232: }
233: 
234: class _KidsGamifiedLoopIndicator extends StatelessWidget {
235:   const _KidsGamifiedLoopIndicator({required this.state});
236: 
237:   final KidsModeLoaded state;
238: 
239:   @override
240:   Widget build(BuildContext context) {
241:     return Container(
242:       padding: const EdgeInsets.all(AppSpacing.lg),
243:       decoration: BoxDecoration(
244:         color: Colors.white.withValues(alpha: 0.08),
245:         borderRadius: KidsTheme.cardRadius,
246:         border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
247:       ),
248:       child: Column(
249:         children: [
250:           Text(
251:             context.l10n.kidsGamifiedRepeatStep,
252:             style: AppTypography.titleMedium.copyWith(
253:               color: Colors.white,
254:               fontFamily: 'Amiri',
255:               letterSpacing: 0,
256:             ),
257:           ),
258:           const SizedBox(height: AppSpacing.sm),
259:           Row(
260:             mainAxisAlignment: MainAxisAlignment.center,
261:             children: [
262:               for (var index = 0; index < state.maxLoops; index++)
263:                 AnimatedContainer(
264:                   duration: const Duration(milliseconds: 220),
265:                   margin: const EdgeInsets.symmetric(horizontal: 5),
266:                   width: index < state.currentLoop ? 30 : 14,
267:                   height: 14,
268:                   decoration: BoxDecoration(
269:                     color: index < state.currentLoop
270:                         ? KidsTheme.goldStar
271:                         : Colors.white.withValues(alpha: 0.22),
272:                     borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
273:                   ),
274:                 ),
275:               const SizedBox(width: AppSpacing.md),
276:               Text(
277:                 '${state.currentLoop}/${state.maxLoops}',
278:                 style: AppTypography.titleSmall.copyWith(
279:                   color: KidsTheme.goldStar,
280:                   letterSpacing: 0,
281:                 ),
282:               ),
283:             ],
284:           ),
285:         ],
286:       ),
287:     );
288:   }
289: }
290: 
291: class _KidsGamifiedAudioControls extends StatelessWidget {
292:   const _KidsGamifiedAudioControls({
293:     required this.state,
294:     required this.onPlayPause,
295:     required this.onRecordRecitation,
296:   });
297: 
298:   final KidsModeLoaded state;
299:   final VoidCallback onPlayPause;
300:   final VoidCallback onRecordRecitation;
301: 
302:   @override
303:   Widget build(BuildContext context) {
304:     final isRecording = state.isRecording;
305:     final micDisabled = state.isCompleted || isRecording;
306: 
307:     return Column(
308:       crossAxisAlignment: CrossAxisAlignment.stretch,
309:       children: [
310:         Center(
311:           child: FilledButton.tonalIcon(
312:             key: const ValueKey('kids-gamified-play-audio'),
313:             onPressed: state.isRecording ? null : onPlayPause,
314:             icon: Icon(
315:               state.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
316:             ),
317:             label: Text(context.l10n.kidsGamifiedListenAndRepeat),
318:             style: FilledButton.styleFrom(
319:               backgroundColor: KidsTheme.goldStar,
320:               foregroundColor: KidsTheme.nightSkyDark,
321:               minimumSize: const Size(220, 56),
322:               shape: const RoundedRectangleBorder(
323:                 borderRadius: KidsTheme.buttonRadius,
324:               ),
325:             ),
326:           ),
327:         ),
328:         const SizedBox(height: AppSpacing.md),
329:         // Mic button: shows a pulsing recording indicator while isRecording
330:         AnimatedSwitcher(
331:           duration: const Duration(milliseconds: 250),
332:           child: FilledButton.icon(
333:             key: ValueKey(
334:               isRecording
335:                   ? 'kids-gamified-record-recitation-recording'
336:                   : 'kids-gamified-record-recitation-idle',
337:             ),
338:             onPressed: micDisabled ? null : onRecordRecitation,
339:             icon: isRecording
340:                 ? const SizedBox(
341:                     width: 20,
342:                     height: 20,
343:                     child: CircularProgressIndicator(
344:                       strokeWidth: 2.5,
345:                       color: Colors.white,
346:                     ),
347:                   )
348:                 : const Icon(Icons.mic_rounded),
349:             label: Text(
350:               isRecording
351:                   ? context.l10n.kidsGamifiedRecordingInProgress
352:                   : context.l10n.kidsGamifiedRecordYourVoice,
353:             ),
354:             style: FilledButton.styleFrom(
355:               backgroundColor: isRecording
356:                   ? KidsTheme.forestGreen.withValues(alpha: 0.6)
357:                   : KidsTheme.forestGreen,
358:               foregroundColor: Colors.white,
359:               minimumSize: const Size.fromHeight(56),
360:               shape: const RoundedRectangleBorder(
361:                 borderRadius: KidsTheme.buttonRadius,
362:               ),
363:             ),
364:           ),
365:         ),
366:       ],
367:     );
368:   }
369: }

(End of file - total 369 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 9.8s)

_Thinking:_

Now let me look at the constants, the MemorizationPlusRepository implementation, and the kids journey/stage pages, and the smart_memorization_settings file.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\constants"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\constants</path>
<type>directory</type>
<entries>
app_constants.dart
app_spacing.dart
xp_constants.dart

(3 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data\\repositories\\memorization_plus_repository_impl.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\data\repositories\memorization_plus_repository_impl.dart</path>
<type>file</type>
<content>
1: import 'dart:convert';
2: import 'dart:math';
3: 
4: import 'package:crypto/crypto.dart';
5: import 'package:dartz/dartz.dart';
6: import 'package:shared_preferences/shared_preferences.dart';
7: import 'package:supabase_flutter/supabase_flutter.dart';
8: import '../../../../core/constants/app_constants.dart';
9: import '../../../../core/error/app_failure.dart';
10: import '../../../../features/quran/domain/repositories/quran_repository.dart';
11: import '../../../../features/quran/domain/entities/quran_entities.dart';
12: import '../../domain/entities/memorization_entities.dart';
13: import '../../domain/repositories/memorization_plus_repository.dart';
14: import '../../domain/usecases/memorization_plus_usecases.dart';
15: import '../datasources/memorization_plus_local_datasource.dart';
16: import '../models/memorization_models.dart';
17: 
18: class MemorizationPlusRepositoryImpl implements MemorizationPlusRepository {
19:   MemorizationPlusRepositoryImpl(this._datasource, this._quranRepository);
20: 
21:   final MemorizationPlusLocalDatasource _datasource;
22: 
23:   /// For surah ayah counts
24:   final QuranRepository _quranRepository;
25: 
26:   final _scheduler = const ScheduleNextReviewUsecase();
27: 
28:   /// Lazy Supabase getter — safe to reference but individual methods that call
29:   /// Supabase must still handle StateError / no-network gracefully via try-catch.
30:   /// All Supabase-using methods in this repo already have `catch (e)` blocks.
31:   SupabaseClient get _supabase => Supabase.instance.client;
32: 
33:   // ─── Identity profile ──────────────────────────────────────────────────────
34:   @override
35:   Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
36:     try {
37:       return Right(await _loadProfile());
38:     } catch (e) {
39:       return Left(CacheFailure(e.toString()));
40:     }
41:   }
42: 
43:   @override
44:   Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
45:     MemorizationPath path,
46:   ) async {
47:     try {
48:       final current = await _loadProfile();
49:       final selected = current.copyWith(
50:         selectedPath: path,
51:         guardianLinkStatus: GuardianLinkStatus.none,
52:         guardianOnboardingStatus: path == MemorizationPath.child
53:             ? GuardianOnboardingStatus.required
54:             : GuardianOnboardingStatus.completed,
55:         isParentGuardian: path == MemorizationPath.adult
56:             ? current.isParentGuardian
57:             : false,
58:         clearGuardianId: true,
59:         clearLinkedChildId: path == MemorizationPath.child,
60:       );
61:       final saved = await _saveProfile(selected);
62:       await _datasource.saveSelectedTrack(saved.legacyTrack!.name);
63:       if (path == MemorizationPath.child) {
64:         await _datasource.setIsParentMode(false);
65:       }
66:       return Right(saved);
67:     } catch (e) {
68:       return Left(CacheFailure(e.toString()));
69:     }
70:   }
71: 
72:   @override
73:   Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian() async {
74:     try {
75:       final profile = await _loadProfile();
76:       if (!profile.isChild) {
77:         return const Left(
78:           CacheFailure('Guardian linking is only for children'),
79:         );
80:       }
81:       final saved = await _saveProfile(
82:         profile.copyWith(
83:           guardianLinkStatus: GuardianLinkStatus.none,
84:           guardianOnboardingStatus: GuardianOnboardingStatus.skipped,
85:           clearGuardianId: true,
86:         ),
87:       );
88:       await _datasource.clearPairingSession();
89:       return Right(saved);
90:     } catch (e) {
91:       return Left(CacheFailure(e.toString()));
92:     }
93:   }
94: 
95:   @override
96:   Future<Either<Failure, PairingSession>> createGuardianPairingSession() async {
97:     try {
98:       final profile = await _loadProfile();
99:       if (!profile.isChild) {
100:         return const Left(
101:           CacheFailure('Guardian linking is only for children'),
102:         );
103:       }
104:       if (profile.isGuardianLinked) {
105:         return const Left(
106:           CacheFailure('Unlink the current guardian before linking another'),
107:         );
108:       }
109:       final tokenResult = await createChildLinkToken();
110:       return await tokenResult.fold((failure) async => Left(failure), (
111:         token,
112:       ) async {
113:         final now = DateTime.now();
114:         final session = PairingSession(
115:           id: now.microsecondsSinceEpoch.toString(),
116:           pairingCode: token,
117:           qrData: 'talia-kids-link:$token',
118:           createdAt: now,
119:           expiresAt: now.add(const Duration(minutes: 15)),
120:           status: PairingSessionStatus.pending,
121:           isUsed: false,
122:         );
123:         await _datasource.savePairingSession(
124:           PairingSessionModel.fromEntity(session),
125:         );
126:         await _saveProfile(
127:           profile.copyWith(
128:             guardianLinkStatus: GuardianLinkStatus.pending,
129:             guardianOnboardingStatus: GuardianOnboardingStatus.required,
130:           ),
131:         );
132:         return Right(session);
133:       });
134:     } catch (e) {
135:       return Left(CacheFailure(e.toString()));
136:     }
137:   }
138: 
139:   @override
140:   Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
141:     String codeOrQrData,
142:   ) async {
143:     try {
144:       final result = await acceptChildLinkToken(codeOrQrData);
145:       return await result.fold((failure) async => Left(failure), (_) async {
146:         final userId = _supabase.auth.currentUser?.id;
147:         final profile = await _loadProfile();
148:         final saved = await _saveProfile(
149:           profile.isChild
150:               ? profile.copyWith(
151:                   guardianLinkStatus: GuardianLinkStatus.linked,
152:                   guardianOnboardingStatus: GuardianOnboardingStatus.completed,
153:                   guardianId: userId ?? 'linked_guardian',
154:                 )
155:               : profile.copyWith(
156:                   isParentGuardian: true,
157:                   linkedChildId: profile.linkedChildId ?? 'linked_child',
158:                 ),
159:         );
160:         await _datasource.setIsParentMode(saved.isParentGuardian);
161:         final session = await _datasource.getPairingSession();
162:         if (session != null) {
163:           await _datasource.savePairingSession(
164:             PairingSessionModel.fromEntity(
165:               session.copyWith(
166:                 status: PairingSessionStatus.completed,
167:                 isUsed: true,
168:                 guardianId: userId,
169:               ),
170:             ),
171:           );
172:         }
173:         return Right(saved);
174:       });
175:     } catch (e) {
176:       return Left(NetworkFailure(e.toString()));
177:     }
178:   }
179: 
180:   @override
181:   Future<Either<Failure, PairingSession?>> refreshPairingSession() async {
182:     try {
183:       final session = await _datasource.getPairingSession();
184:       if (session == null) return const Right(null);
185:       if (session.status == PairingSessionStatus.pending &&
186:           DateTime.now().isAfter(session.expiresAt)) {
187:         final expired = session.copyWith(
188:           status: PairingSessionStatus.expired,
189:           failureReason: 'Code expired',
190:         );
191:         await _datasource.savePairingSession(
192:           PairingSessionModel.fromEntity(expired),
193:         );
194:         final profile = await _loadProfile();
195:         if (profile.guardianLinkStatus == GuardianLinkStatus.pending) {
196:           await _saveProfile(
197:             profile.copyWith(guardianLinkStatus: GuardianLinkStatus.none),
198:           );
199:         }
200:         return Right(expired);
201:       }
202:       return Right(session);
203:     } catch (e) {
204:       return Left(CacheFailure(e.toString()));
205:     }
206:   }
207: 
208:   @override
209:   Future<Either<Failure, MemorizationProfile>> unlinkGuardian() async {
210:     try {
211:       final profile = await _loadProfile();
212:       final saved = await _saveProfile(
213:         profile.copyWith(
214:           guardianLinkStatus: GuardianLinkStatus.none,
215:           guardianOnboardingStatus: GuardianOnboardingStatus.completed,
216:           clearGuardianId: true,
217:           clearLinkedChildId: true,
218:         ),
219:       );
220:       await _datasource.clearPairingSession();
221:       return Right(saved);
222:     } catch (e) {
223:       return Left(CacheFailure(e.toString()));
224:     }
225:   }
226: 
227:   @override
228:   Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
229:     bool value,
230:   ) async {
231:     try {
232:       final profile = await _loadProfile();
233:       if (value && profile.selectedPath != MemorizationPath.adult) {
234:         return const Left(
235:           CacheFailure('Parent guardian mode is only available for adults'),
236:         );
237:       }
238:       final saved = await _saveProfile(
239:         profile.copyWith(isParentGuardian: value, clearLinkedChildId: !value),
240:       );
241:       await _datasource.setIsParentMode(value);
242:       if (!value) {
243:         await _datasource.clearPairingSession();
244:       }
245:       return Right(saved);
246:     } catch (e) {
247:       return Left(CacheFailure(e.toString()));
248:     }
249:   }
250: 
251:   @override
252:   Future<Either<Failure, MemorizationProfile>>
253:   refreshChildGuardianLink() async {
254:     try {
255:       final profile = await _loadProfile();
256:       if (!profile.isChild || !profile.isGuardianLinked) return Right(profile);
257:       final user = _supabase.auth.currentUser;
258:       if (user == null) return Right(profile);
259: 
260:       final links = await _supabase
261:           .from('parent_child_links')
262:           .select('parent_user_id')
263:           .eq('child_user_id', user.id)
264:           .eq('status', 'active')
265:           .limit(1);
266:       if (links.isNotEmpty) return Right(profile);
267: 
268:       final saved = await _saveProfile(
269:         profile.copyWith(
270:           guardianLinkStatus: GuardianLinkStatus.none,
271:           guardianOnboardingStatus: GuardianOnboardingStatus.completed,
272:           clearGuardianId: true,
273:         ),
274:       );
275:       return Right(saved);
276:     } catch (_) {
277:       return Right(await _loadProfile());
278:     }
279:   }
280: 
281:   @override
282:   Future<Either<Failure, MemorizationProfile>>
283:   resetMemorizationIdentity() async {
284:     try {
285:       await _datasource.clearMemorizationProfile();
286:       await _datasource.clearPairingSession();
287:       await _datasource.clearSelectedTrack();
288:       await _datasource.clearIsParentMode();
289:       final prefs = await SharedPreferences.getInstance();
290:       await prefs.remove(AppConstants.kHifzPathMode);
291:       return Right(await _loadProfile());
292:     } catch (e) {
293:       return Left(CacheFailure(e.toString()));
294:     }
295:   }
296: 
297:   @override
298:   Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings() async {
299:     try {
300:       return Right(await _datasource.getSmartSettings());
301:     } catch (e) {
302:       return Left(CacheFailure(e.toString()));
303:     }
304:   }
305: 
306:   @override
307:   Future<Either<Failure, void>> saveSmartSettings(
308:     SmartMemorizationSettings settings,
309:   ) async {
310:     try {
311:       await _datasource.saveSmartSettings(
312:         SmartMemorizationSettingsModel.fromEntity(settings),
313:       );
314:       return const Right(null);
315:     } catch (e) {
316:       return Left(CacheFailure(e.toString()));
317:     }
318:   }
319: 
320:   Future<MemorizationProfile> _loadProfile() async {
321:     final stored = await _datasource.getMemorizationProfile();
322:     if (stored.hasSelectedPath) return stored;
323: 
324:     final legacyTrack = _datasource.getSelectedTrack();
325:     final isParent = _datasource.getIsParentMode();
326:     final prefs = await SharedPreferences.getInstance();
327:     final legacyHifzPath = prefs.getString(AppConstants.kHifzPathMode);
328:     MemorizationPath? migratedPath;
329:     if (legacyTrack == MemorizationTrack.adults.name) {
330:       migratedPath = MemorizationPath.adult;
331:     } else if (legacyTrack == MemorizationTrack.kids.name) {
332:       migratedPath = MemorizationPath.child;
333:     }
334: 
335:     if (migratedPath == null && legacyHifzPath != null) {
336:       migratedPath = legacyHifzPath == 'backward'
337:           ? MemorizationPath.child
338:           : MemorizationPath.adult;
339:     }
340: 
341:     if (migratedPath == null && isParent) {
342:       migratedPath = MemorizationPath.adult;
343:     }
344: 
345:     if (migratedPath == null) return stored;
346:     final migrated = stored.copyWith(
347:       selectedPath: migratedPath,
348:       guardianLinkStatus: GuardianLinkStatus.none,
349:       guardianOnboardingStatus: migratedPath == MemorizationPath.child
350:           ? GuardianOnboardingStatus.skipped
351:           : GuardianOnboardingStatus.completed,
352:       isParentGuardian: migratedPath == MemorizationPath.adult && isParent,
353:     );
354:     return _saveProfile(migrated);
355:   }
356: 
357:   Future<MemorizationProfile> _saveProfile(MemorizationProfile profile) async {
358:     final model = MemorizationProfileModel.fromEntity(
359:       // UTC: consistent with review scheduling and streak date policy.
360:       profile.copyWith(updatedAt: DateTime.now().toUtc()),
361:     );
362:     await _datasource.saveMemorizationProfile(model);
363:     return model;
364:   }
365: 
366:   // ─── Track ──────────────────────────────────────────────────────────────────
367:   @override
368:   Either<Failure, MemorizationTrack?> getSelectedTrack() {
369:     try {
370:       final raw = _datasource.getSelectedTrack();
371:       if (raw == null) return const Right(null);
372:       final track = MemorizationTrack.values.firstWhere(
373:         (t) => t.name == raw,
374:         orElse: () => MemorizationTrack.adults,
375:       );
376:       return Right(track);
377:     } catch (e) {
378:       return Left(CacheFailure(e.toString()));
379:     }
380:   }
381: 
382:   @override
383:   Future<Either<Failure, void>> saveSelectedTrack(
384:     MemorizationTrack track,
385:   ) async {
386:     try {
387:       final path = track == MemorizationTrack.kids
388:           ? MemorizationPath.child
389:           : MemorizationPath.adult;
390:       final result = await selectMemorizationPath(path);
391:       final failure = result.fold((failure) => failure, (_) => null);
392:       if (failure != null) return Left(failure);
393:       return const Right(null);
394:     } catch (e) {
395:       return Left(CacheFailure(e.toString()));
396:     }
397:   }
398: 
399:   // ─── Daily plan ─────────────────────────────────────────────────────────────
400:   @override
401:   Future<Either<Failure, DailyPlan>> generateDailyPlan({
402:     required int surahId,
403:     required int newAyahsPerDay,
404:   }) async {
405:     try {
406:       final allRecords = await _datasource.getAllReviewRecords();
407: 
408:       // BUG-7 FIX: Read custom plan settings and apply them
409:       final customPlan = await _datasource.getCustomPlan();
410:       final effectiveNewPerDay = customPlan?.newAyahsPerDay ?? newAyahsPerDay;
411:       final nearRevisionLimit = customPlan?.nearRevisionCount ?? 10;
412:       final farRevisionLimit = customPlan?.farRevisionCount ?? 5;
413:       // Respect the custom plan's endSurahId boundary
414:       final maxSurahId = customPlan?.endSurahId ?? 114;
415: 
416:       int currentSurahId = customPlan?.startSurahId ?? surahId;
417:       if (surahId > currentSurahId) {
418:         currentSurahId = surahId;
419:       }
420:       DailyPlan? bestPlan;
421: 
422:       while (currentSurahId <= maxSurahId) {
423:         final surahRecords = {
424:           for (final r in allRecords.where((r) => r.surahId == currentSurahId))
425:             r.ayahNumber: r,
426:         };
427: 
428:         int totalAyahs = 7; // fallback
429:         List<Ayah> ayahs = [];
430:         final surahResult = await _quranRepository.getSurahDetail(
431:           currentSurahId,
432:         );
433:         surahResult.fold((_) {}, (detail) {
434:           totalAyahs = detail.surah.ayahCount;
435:           ayahs = detail.ayahs;
436:         });
437: 
438:         final List<DailyPlanAyah> newAyahs = [];
439:         final List<DailyPlanAyah> nearRevision = [];
440:         final List<DailyPlanAyah> farRevision = [];
441: 
442:         final firstAyah =
443:             customPlan != null && currentSurahId == customPlan.startSurahId
444:             ? customPlan.startAyah.clamp(1, totalAyahs)
445:             : 1;
446: 
447:         for (int i = firstAyah; i <= totalAyahs; i++) {
448:           final record = surahRecords[i];
449: 
450:           String ayahText = 'النص غير متوفر';
451:           try {
452:             ayahText = ayahs.firstWhere((a) => a.numberInSurah == i).text;
453:           } catch (_) {}
454: 
455:           if (record == null || record.isNew) {
456:             if (newAyahs.length < effectiveNewPerDay) {
457:               newAyahs.add(
458:                 DailyPlanAyah(
459:                   surahId: currentSurahId,
460:                   ayahNumber: i,
461:                   ayahText: ayahText,
462:                   record: record,
463:                 ),
464:               );
465:             }
466:           } else if (record.isDue) {
467:             final planAyah = DailyPlanAyah(
468:               surahId: currentSurahId,
469:               ayahNumber: i,
470:               ayahText: ayahText,
471:               record: record,
472:             );
473:             // BUG-7 FIX: apply custom plan revision limits
474:             if (customPlan?.enableNearRevision != false &&
475:                 record.isNearRevision &&
476:                 nearRevision.length < nearRevisionLimit) {
477:               nearRevision.add(planAyah);
478:             } else if (customPlan?.enableFarRevision != false &&
479:                 record.isFarRevision &&
480:                 farRevision.length < farRevisionLimit) {
481:               farRevision.add(planAyah);
482:             }
483:           }
484:         }
485: 
486:         bestPlan = DailyPlan(
487:           // UTC so the same-day stale check in getCachedDailyPlan is timezone-safe.
488:           generatedAt: DateTime.now().toUtc(),
489:           surahId: currentSurahId,
490:           newAyahs: newAyahs,
491:           nearRevision: nearRevision,
492:           farRevision: farRevision,
493:           completedAyahNums: const [],
494:         );
495: 
496:         if (bestPlan.totalItems > 0) {
497:           break; // Found active items
498:         }
499: 
500:         currentSurahId++;
501:       }
502: 
503:       bestPlan ??= DailyPlan(
504:         generatedAt: DateTime.now().toUtc(),
505:         surahId: maxSurahId,
506:         newAyahs: const [],
507:         nearRevision: const [],
508:         farRevision: const [],
509:         completedAyahNums: const [],
510:       );
511: 
512:       // Cache the plan
513:       await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(bestPlan));
514: 
515:       return Right(bestPlan);
516:     } catch (e) {
517:       return Left(CacheFailure(e.toString()));
518:     }
519:   }
520: 
521:   @override
522:   Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
523:     try {
524:       final cached = await _datasource.getCachedDailyPlan();
525:       if (cached == null) return const Right(null);
526: 
527:       // Compare on UTC date components to avoid DST-ambiguous local midnight.
528:       // The cached plan's generatedAt is also stored in UTC (see generateDailyPlan).
529:       final today = DateTime.now().toUtc();
530:       final cachedDate = cached.generatedAt.toUtc();
531:       final sameDay =
532:           cachedDate.year == today.year &&
533:           cachedDate.month == today.month &&
534:           cachedDate.day == today.day;
535: 
536:       return Right(sameDay ? cached : null);
537:     } catch (e) {
538:       return Left(CacheFailure(e.toString()));
539:     }
540:   }
541: 
542:   @override
543:   Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
544:     try {
545:       await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
546:       return const Right(null);
547:     } catch (e) {
548:       return Left(CacheFailure(e.toString()));
549:     }
550:   }
551: 
552:   // ─── Review records ─────────────────────────────────────────────────────────
553:   @override
554:   Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
555:     int surahId,
556:     int ayahNumber,
557:   ) async {
558:     try {
559:       final record = await _datasource.getReviewRecord(surahId, ayahNumber);
560:       return Right(record);
561:     } catch (e) {
562:       return Left(CacheFailure(e.toString()));
563:     }
564:   }
565: 
566:   @override
567:   Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async {
568:     try {
569:       final records = await _datasource.getAllReviewRecords();
570:       return Right(records);
571:     } catch (e) {
572:       return Left(CacheFailure(e.toString()));
573:     }
574:   }
575: 
576:   @override
577:   Future<Either<Failure, void>> saveReviewRecord(
578:     AyahReviewRecord record,
579:   ) async {
580:     try {
581:       await _datasource.saveReviewRecord(
582:         AyahReviewRecordModel.fromEntity(record),
583:       );
584:       return const Right(null);
585:     } catch (e) {
586:       return Left(CacheFailure(e.toString()));
587:     }
588:   }
589: 
590:   // ─── Evaluation ─────────────────────────────────────────────────────────────
591:   @override
592:   Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
593:     required int surahId,
594:     required int ayahNumber,
595:     required PerformanceRating rating,
596:   }) async {
597:     try {
598:       final existing = await _datasource.getReviewRecord(surahId, ayahNumber);
599: 
600:       final current =
601:           existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);
602: 
603:       final updated = _scheduler.schedule(current, rating);
604:       await _datasource.saveReviewRecord(
605:         AyahReviewRecordModel.fromEntity(updated),
606:       );
607: 
608:       return Right(updated);
609:     } catch (e) {
610:       return Left(CacheFailure(e.toString()));
611:     }
612:   }
613: 
614:   @override
615:   Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
616:     required int surahId,
617:     required int ayahNumber,
618:   }) async {
619:     try {
620:       final existing = await _datasource.getReviewRecord(surahId, ayahNumber);
621:       final current =
622:           existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);
623:       // UTC: consistent with AyahReviewRecord scheduling in ScheduleNextReviewUsecase.
624:       final now = DateTime.now().toUtc();
625:       final intervalDays = current.intervalDays < 30
626:           ? 30
627:           : current.intervalDays;
628: 
629:       final updated = current.copyWith(
630:         strengthLevel: current.strengthLevel < 6 ? 6 : current.strengthLevel,
631:         intervalDays: intervalDays,
632:         lastReviewedAt: now,
633:         nextReviewDate: now.add(Duration(days: intervalDays)),
634:         totalReviews: current.totalReviews + 1,
635:         lastRating: PerformanceRating.excellent,
636:       );
637: 
638:       await _datasource.saveReviewRecord(
639:         AyahReviewRecordModel.fromEntity(updated),
640:       );
641:       return Right(updated);
642:     } catch (e) {
643:       return Left(CacheFailure(e.toString()));
644:     }
645:   }
646: 
647:   // ─── Kids progress ───────────────────────────────────────────────────────────
648:   @override
649:   Future<Either<Failure, KidsProgress>> getKidsProgress() async {
650:     try {
651:       final progress = await _datasource.getKidsProgress();
652:       return Right(progress);
653:     } catch (e) {
654:       return Left(CacheFailure(e.toString()));
655:     }
656:   }
657: 
658:   @override
659:   Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) async {
660:     try {
661:       await _datasource.saveKidsProgress(
662:         KidsProgressModel.fromEntity(progress),
663:       );
664:       return const Right(null);
665:     } catch (e) {
666:       return Left(CacheFailure(e.toString()));
667:     }
668:   }
669: 
670:   @override
671:   Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
672:     required int surahId,
673:   }) async {
674:     try {
675:       final logs = await _datasource.getKidsSessionLogs();
676:       final completed = logs
677:           .where((log) => log.surahId == surahId)
678:           .map((log) => log.ayahNumber)
679:           .toSet();
680: 
681:       var totalAyahs = 7;
682:       final detailResult = await _quranRepository.getSurahDetail(surahId);
683:       detailResult.fold(
684:         (_) {},
685:         (detail) => totalAyahs = detail.surah.ayahCount,
686:       );
687: 
688:       const stageSize = 5;
689:       final stages = <KidsJourneyStage>[];
690:       var foundCurrent = false;
691:       for (var start = 1; start <= totalAyahs; start += stageSize) {
692:         final end = min(start + stageSize - 1, totalAyahs);
693:         final ayahRange = List<int>.generate(end - start + 1, (i) => start + i);
694:         final stageCompleted = ayahRange
695:             .where((ayah) => completed.contains(ayah))
696:             .toList();
697: 
698:         KidsJourneyStageStatus status;
699:         if (stageCompleted.length == ayahRange.length) {
700:           status = KidsJourneyStageStatus.completed;
701:         } else if (!foundCurrent) {
702:           status = KidsJourneyStageStatus.current;
703:           foundCurrent = true;
704:         } else {
705:           status = KidsJourneyStageStatus.locked;
706:         }
707: 
708:         stages.add(
709:           KidsJourneyStage(
710:             stageNumber: stages.length + 1,
711:             surahId: surahId,
712:             startAyah: start,
713:             endAyah: end,
714:             completedAyahs: stageCompleted,
715:             status: status,
716:           ),
717:         );
718:       }
719:       return Right(stages);
720:     } catch (e) {
721:       return Left(CacheFailure(e.toString()));
722:     }
723:   }
724: 
725:   @override
726:   Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
727:     try {
728:       return Right(await _datasource.getKidsSessionLogs());
729:     } catch (e) {
730:       return Left(CacheFailure(e.toString()));
731:     }
732:   }
733: 
734:   @override
735:   Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
736:     required int surahId,
737:     required int ayahNumber,
738:     required int repeatsCompleted,
739:     required int pointsEarned,
740:   }) async {
741:     try {
742:       // UTC: consistent with all other review/session date fields.
743:       final now = DateTime.now().toUtc();
744:       final log = KidsSessionLogModel(
745:         id: '${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
746:         surahId: surahId,
747:         ayahNumber: ayahNumber,
748:         repeatsCompleted: repeatsCompleted,
749:         pointsEarned: pointsEarned,
750:         completedAt: now,
751:       );
752:       await _datasource.saveKidsSessionLog(log);
753:       await _unlockWeeklyRewardIfNeeded();
754:       await syncKidsProgressToCloud();
755:       return Right(log);
756:     } catch (e) {
757:       return Left(CacheFailure(e.toString()));
758:     }
759:   }
760: 
761:   @override
762:   Future<Either<Failure, ParentDashboard>> getParentDashboard({
763:     required int surahId,
764:   }) async {
765:     try {
766:       final progress = await _datasource.getKidsProgress();
767:       final logs = await _datasource.getKidsSessionLogs();
768:       final settings = await _datasource.getParentSettings();
769:       final rewards = await _datasource.getParentRewards();
770:       final journey = await getKidsJourney(surahId: surahId);
771:       return journey.fold(
772:         Left.new,
773:         (stages) => Right(
774:           ParentDashboard(
775:             progress: progress,
776:             stages: stages,
777:             logs: logs,
778:             rewards: rewards,
779:             settings: settings,
780:           ),
781:         ),
782:       );
783:     } catch (e) {
784:       return Left(CacheFailure(e.toString()));
785:     }
786:   }
787: 
788:   @override
789:   Future<Either<Failure, ParentSettings>> getParentSettings() async {
790:     try {
791:       return Right(await _datasource.getParentSettings());
792:     } catch (e) {
793:       return Left(CacheFailure(e.toString()));
794:     }
795:   }
796: 
797:   @override
798:   Future<Either<Failure, void>> saveParentSettings(
799:     ParentSettings settings,
800:   ) async {
801:     try {
802:       await _datasource.saveParentSettings(
803:         ParentSettingsModel.fromEntity(settings),
804:       );
805:       return const Right(null);
806:     } catch (e) {
807:       return Left(CacheFailure(e.toString()));
808:     }
809:   }
810: 
811:   @override
812:   Future<Either<Failure, bool>> verifyParentPin(String pin) async {
813:     try {
814:       final settings = await _datasource.getParentSettings();
815:       final stored = settings.pinHash;
816:       if (stored == _hashPin(pin)) {
817:         return const Right(true);
818:       }
819: 
820:       if (_isLegacyPlaintextPin(stored) && stored == pin) {
821:         await _datasource.saveParentSettings(
822:           ParentSettingsModel.fromEntity(
823:             settings.copyWith(pinHash: _hashPin(pin)),
824:           ),
825:         );
826:         return const Right(true);
827:       }
828: 
829:       return const Right(false);
830:     } catch (e) {
831:       return Left(CacheFailure(e.toString()));
832:     }
833:   }
834: 
835:   @override
836:   Future<Either<Failure, void>> setParentPin(String pin) async {
837:     try {
838:       final settings = await _datasource.getParentSettings();
839:       await _datasource.saveParentSettings(
840:         ParentSettingsModel.fromEntity(
841:           settings.copyWith(pinHash: _hashPin(pin)),
842:         ),
843:       );
844:       return const Right(null);
845:     } catch (e) {
846:       return Left(CacheFailure(e.toString()));
847:     }
848:   }
849: 
850:   @override
851:   Future<Either<Failure, void>> resetParentAccess() async {
852:     try {
853:       final settings = await _datasource.getParentSettings();
854:       await _datasource.saveParentSettings(
855:         ParentSettingsModel.fromEntity(
856:           settings.copyWith(clearPin: true, remoteLinkEnabled: false),
857:         ),
858:       );
859:       await _datasource.saveParentRewards(const []);
860:       return const Right(null);
861:     } catch (e) {
862:       return Left(CacheFailure(e.toString()));
863:     }
864:   }
865: 
866:   @override
867:   Future<Either<Failure, List<ParentReward>>> saveParentReward(
868:     String title,
869:   ) async {
870:     try {
871:       final trimmed = title.trim();
872:       if (trimmed.isEmpty) {
873:         return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
874:       }
875:       final rewards = await _datasource.getParentRewards();
876:       if (rewards.length >= 3) {
877:         return const Left(CacheFailure('يمكن إضافة 3 مكافآت فقط'));
878:       }
879:       final reward = ParentRewardModel(
880:         id: DateTime.now().microsecondsSinceEpoch.toString(),
881:         title: trimmed,
882:         status: ParentRewardStatus.locked,
883:         createdAt: DateTime.now(),
884:       );
885:       final next = [...rewards, reward];
886:       await _datasource.saveParentRewards(next);
887:       return Right(next);
888:     } catch (e) {
889:       return Left(CacheFailure(e.toString()));
890:     }
891:   }
892: 
893:   @override
894:   Future<Either<Failure, List<ParentReward>>> claimParentReward(
895:     String id,
896:   ) async {
897:     try {
898:       final rewards = await _datasource.getParentRewards();
899:       final next = rewards
900:           .map(
901:             (reward) => reward.id == id
902:                 ? ParentRewardModel.fromEntity(
903:                     reward.copyWith(
904:                       status: ParentRewardStatus.claimed,
905:                       claimedAt: DateTime.now(),
906:                     ),
907:                   )
908:                 : reward,
909:           )
910:           .toList();
911:       await _datasource.saveParentRewards(next);
912:       return Right(next);
913:     } catch (e) {
914:       return Left(CacheFailure(e.toString()));
915:     }
916:   }
917: 
918:   @override
919:   Future<Either<Failure, String>> createChildLinkToken() async {
920:     try {
921:       if (_supabase.auth.currentUser == null) {
922:         return const Left(NetworkFailure('سجّل الدخول أولاً على جهاز الطفل'));
923:       }
924: 
925:       // Generate random 12-char uppercase hex token (no pgcrypto needed)
926:       final rng = Random.secure();
927:       final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
928:       final token = bytes
929:           .map((b) => b.toRadixString(16).padLeft(2, '0'))
930:           .join()
931:           .substring(0, 12)
932:           .toUpperCase();
933: 
934:       // Hash the token with SHA-256 (matches what the DB used to do)
935:       final tokenHash = sha256.convert(utf8.encode(token)).toString();
936: 
937:       await _supabase.rpc(
938:         'create_child_link_request_with_hash',
939:         params: {'p_token_hash': tokenHash},
940:       );
941: 
942:       return Right(token);
943:     } catch (e) {
944:       return Left(NetworkFailure(e.toString()));
945:     }
946:   }
947: 
948:   @override
949:   Future<Either<Failure, void>> acceptChildLinkToken(String token) async {
950:     try {
951:       if (_supabase.auth.currentUser == null) {
952:         return const Left(
953:           NetworkFailure('سجّل الدخول أولاً على جهاز ولي الأمر'),
954:         );
955:       }
956:       // Hash the token client-side (no pgcrypto needed)
957:       final rawToken = _extractToken(token).toUpperCase().trim();
958:       final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
959:       await _supabase.rpc(
960:         'accept_child_link_token_with_hash',
961:         params: {'p_token_hash': tokenHash},
962:       );
963:       return const Right(null);
964:     } catch (e) {
965:       return Left(NetworkFailure(e.toString()));
966:     }
967:   }
968: 
969:   @override
970:   Future<Either<Failure, void>> syncKidsProgressToCloud() async {
971:     try {
972:       final user = _supabase.auth.currentUser;
973:       if (user == null) return const Right(null);
974: 
975:       final progress = await _datasource.getKidsProgress();
976:       await _supabase.rpc(
977:         'upsert_kids_progress_cloud',
978:         params: {
979:           'p_total_points': progress.totalPoints,
980:           'p_current_level': progress.currentLevel,
981:           'p_current_streak': progress.currentStreak,
982:           'p_stars_earned': progress.starsEarned,
983:           'p_ayahs_completed': progress.ayahsCompleted,
984:           'p_last_session_at': progress.lastSessionAt
985:               ?.toUtc()
986:               .toIso8601String(),
987:         },
988:       );
989: 
990:       final logs = await _datasource.getKidsSessionLogs();
991:       final synced = <KidsSessionLogModel>[];
992:       for (final log in logs) {
993:         if (log.isSynced) {
994:           synced.add(log);
995:           continue;
996:         }
997:         await _supabase.rpc(
998:           'insert_kids_session_log',
999:           params: {
1000:             'p_local_id': log.id,
1001:             'p_surah_id': log.surahId,
1002:             'p_ayah_number': log.ayahNumber,
1003:             'p_repeats_completed': log.repeatsCompleted,
1004:             'p_points_earned': log.pointsEarned,
1005:             'p_completed_at': log.completedAt.toUtc().toIso8601String(),
1006:           },
1007:         );
1008:         synced.add(
1009:           KidsSessionLogModel.fromEntity(
1010:             log.copyWith(syncedAt: DateTime.now()),
1011:           ),
1012:         );
1013:       }
1014:       await _datasource.saveKidsSessionLogs(synced);
1015:       return const Right(null);
1016:     } catch (e) {
1017:       return Left(NetworkFailure(e.toString()));
1018:     }
1019:   }
1020: 
1021:   @override
1022:   Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() async {
1023:     try {
1024:       final user = _supabase.auth.currentUser;
1025:       if (user == null) {
1026:         return const Left(NetworkFailure('سجّل الدخول أولاً'));
1027:       }
1028: 
1029:       final links = await _supabase
1030:           .from('parent_child_links')
1031:           .select('child_user_id')
1032:           .eq('parent_user_id', user.id)
1033:           .eq('status', 'active');
1034: 
1035:       final children = <RemoteChildSummary>[];
1036:       for (final link in links) {
1037:         final childId = link['child_user_id'] as String;
1038:         final profileRows = await _supabase
1039:             .from('profiles')
1040:             .select('display_name')
1041:             .eq('id', childId)
1042:             .limit(1);
1043:         final progressRows = await _supabase
1044:             .from('kids_progress_cloud')
1045:             .select()
1046:             .eq('child_user_id', childId)
1047:             .limit(1);
1048:         final logRows = await _supabase
1049:             .from('kids_session_logs')
1050:             .select()
1051:             .eq('child_user_id', childId)
1052:             .order('completed_at', ascending: false)
1053:             .limit(30);
1054:         final rewardRows = await _supabase
1055:             .from('parent_rewards')
1056:             .select()
1057:             .eq('child_user_id', childId)
1058:             .order('created_at', ascending: false);
1059: 
1060:         children.add(
1061:           RemoteChildSummary(
1062:             childUserId: childId,
1063:             displayName: profileRows.isEmpty
1064:                 ? 'طفل تالية'
1065:                 : profileRows.first['display_name'] as String? ?? 'طفل تالية',
1066:             progress: _progressFromCloud(
1067:               progressRows.isEmpty ? null : progressRows.first,
1068:             ),
1069:             logs: logRows.map(_logFromCloud).toList(),
1070:             rewards: rewardRows.map(_rewardFromCloud).toList(),
1071:           ),
1072:         );
1073:       }
1074:       return Right(children);
1075:     } catch (e) {
1076:       return Left(NetworkFailure(e.toString()));
1077:     }
1078:   }
1079: 
1080:   @override
1081:   Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
1082:     required String childUserId,
1083:     required String title,
1084:   }) async {
1085:     try {
1086:       final trimmed = title.trim();
1087:       if (trimmed.isEmpty) {
1088:         return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
1089:       }
1090:       final user = _supabase.auth.currentUser;
1091:       if (user == null) {
1092:         return const Left(NetworkFailure('سجّل الدخول أولاً'));
1093:       }
1094:       await _supabase.from('parent_rewards').insert({
1095:         'parent_user_id': user.id,
1096:         'child_user_id': childUserId,
1097:         'title': trimmed,
1098:       });
1099:       final rows = await _supabase
1100:           .from('parent_rewards')
1101:           .select()
1102:           .eq('child_user_id', childUserId)
1103:           .order('created_at', ascending: false);
1104:       return Right(rows.map(_rewardFromCloud).toList());
1105:     } catch (e) {
1106:       return Left(NetworkFailure(e.toString()));
1107:     }
1108:   }
1109: 
1110:   @override
1111:   Future<Either<Failure, KidsProgress>> awardKidsPoints({
1112:     required int surahId,
1113:     required int ayahNumber,
1114:     required int repeatsCompleted,
1115:   }) async {
1116:     try {
1117:       final current = await _datasource.getKidsProgress();
1118:       // Points: 10 base + 2 per extra repeat
1119:       final points = 10 + ((repeatsCompleted - 1) * 2).clamp(0, 20);
1120:       final updated = current.addPoints(points);
1121:       await _datasource.saveKidsProgress(KidsProgressModel.fromEntity(updated));
1122:       return Right(updated);
1123:     } catch (e) {
1124:       return Left(CacheFailure(e.toString()));
1125:     }
1126:   }
1127: 
1128:   String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
1129: 
1130:   bool _isLegacyPlaintextPin(String? value) {
1131:     return value != null && value.length == 4 && int.tryParse(value) != null;
1132:   }
1133: 
1134:   String _extractToken(String raw) {
1135:     const prefix = 'talia-kids-link:';
1136:     return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
1137:   }
1138: 
1139:   Future<void> _unlockWeeklyRewardIfNeeded() async {
1140:     final logs = await _datasource.getKidsSessionLogs();
1141:     final settings = await _datasource.getParentSettings();
1142:     final rewards = await _datasource.getParentRewards();
1143:     if (rewards.isEmpty ||
1144:         rewards.every((r) => r.status != ParentRewardStatus.locked)) {
1145:       return;
1146:     }
1147:     final now = DateTime.now();
1148:     final weekStart = DateTime(
1149:       now.year,
1150:       now.month,
1151:       now.day,
1152:     ).subtract(Duration(days: now.weekday - 1));
1153:     final sessionsThisWeek = logs
1154:         .where((log) => !log.completedAt.isBefore(weekStart))
1155:         .length;
1156:     if (sessionsThisWeek < settings.weeklyGoalSessions) return;
1157: 
1158:     var unlockedOne = false;
1159:     final next = rewards.map((reward) {
1160:       if (!unlockedOne && reward.status == ParentRewardStatus.locked) {
1161:         unlockedOne = true;
1162:         return ParentRewardModel.fromEntity(
1163:           reward.copyWith(
1164:             status: ParentRewardStatus.unlocked,
1165:             unlockedAt: DateTime.now(),
1166:           ),
1167:         );
1168:       }
1169:       return reward;
1170:     }).toList();
1171:     await _datasource.saveParentRewards(next);
1172:   }
1173: 
1174:   KidsProgress _progressFromCloud(Map<String, dynamic>? row) {
1175:     if (row == null) return const KidsProgress.initial();
1176:     return KidsProgress(
1177:       totalPoints: row['total_points'] as int? ?? 0,
1178:       currentLevel: row['current_level'] as int? ?? 1,
1179:       currentStreak: row['current_streak'] as int? ?? 0,
1180:       starsEarned: row['stars_earned'] as int? ?? 0,
1181:       ayahsCompleted: row['ayahs_completed'] as int? ?? 0,
1182:       lastSessionAt: row['last_session_at'] == null
1183:           ? null
1184:           : DateTime.parse(row['last_session_at'] as String),
1185:     );
1186:   }
1187: 
1188:   KidsSessionLog _logFromCloud(Map<String, dynamic> row) => KidsSessionLog(
1189:     id: row['local_id'] as String? ?? row['id'].toString(),
1190:     surahId: row['surah_id'] as int,
1191:     ayahNumber: row['ayah_number'] as int,
1192:     repeatsCompleted: row['repeats_completed'] as int? ?? 0,
1193:     pointsEarned: row['points_earned'] as int? ?? 0,
1194:     completedAt: DateTime.parse(row['completed_at'] as String),
1195:     syncedAt: DateTime.now(),
1196:   );
1197: 
1198:   ParentReward _rewardFromCloud(Map<String, dynamic> row) => ParentReward(
1199:     id: row['id'].toString(),
1200:     title: row['title'] as String,
1201:     status: ParentRewardStatus.values.firstWhere(
1202:       (status) => status.name == (row['status'] as String? ?? 'locked'),
1203:       orElse: () => ParentRewardStatus.locked,
1204:     ),
1205:     createdAt: DateTime.parse(row['created_at'] as String),
1206:     unlockedAt: row['unlocked_at'] == null
1207:         ? null
1208:         : DateTime.parse(row['unlocked_at'] as String),
1209:     claimedAt: row['claimed_at'] == null
1210:         ? null
1211:         : DateTime.parse(row['claimed_at'] as String),
1212:   );
1213: 
1214:   // ─── Custom memorization plan ──────────────────────────────────────────────
1215: 
1216:   @override
1217:   Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
1218:     try {
1219:       final plan = await _datasource.getCustomPlan();
1220:       return Right(plan);
1221:     } catch (e) {
1222:       return Left(CacheFailure(e.toString()));
1223:     }
1224:   }
1225: 
1226:   @override
1227:   Future<Either<Failure, void>> saveCustomPlan(
1228:     CustomMemorizationPlan plan,
1229:   ) async {
1230:     try {
1231:       await _datasource.saveCustomPlan(
1232:         CustomMemorizationPlanModel.fromEntity(plan),
1233:       );
1234:       return const Right(null);
1235:     } catch (e) {
1236:       return Left(CacheFailure(e.toString()));
1237:     }
1238:   }
1239: 
1240:   @override
1241:   Future<Either<Failure, void>> deleteCustomPlan() async {
1242:     try {
1243:       await _datasource.deleteCustomPlan();
1244:       return const Right(null);
1245:     } catch (e) {
1246:       return Left(CacheFailure(e.toString()));
1247:     }
1248:   }
1249: 
1250:   // ─── Parent mode toggle ──────────────────────────────────────────────────
1251:   // T015: Read through MemorizationProfile so the value is always the single
1252:   // source of truth, not the raw legacy SharedPreferences flag.
1253:   @override
1254:   Either<Failure, bool> getIsParentMode() {
1255:     try {
1256:       // Synchronous fast-path: check the cached datasource profile first.
1257:       // The profile is always written by _saveProfile which keeps the legacy
1258:       // flag in sync, so this is safe and avoids an async round-trip.
1259:       return Right(_datasource.getIsParentMode());
1260:     } catch (e) {
1261:       return Left(CacheFailure(e.toString()));
1262:     }
1263:   }
1264: 
1265:   /// Async variant that reads the authoritative MemorizationProfile.
1266:   /// Prefer this over [getIsParentMode] wherever async is acceptable.
1267:   Future<Either<Failure, bool>> getIsParentModeFromProfile() async {
1268:     try {
1269:       final profile = await _loadProfile();
1270:       return Right(profile.isParentGuardian);
1271:     } catch (e) {
1272:       return Left(CacheFailure(e.toString()));
1273:     }
1274:   }
1275: 
1276:   @override
1277:   Future<Either<Failure, void>> setIsParentMode(bool value) async {
1278:     try {
1279:       final result = await setParentGuardianMode(value);
1280:       return result.fold(Left.new, (_) => const Right(null));
1281:     } catch (e) {
1282:       return Left(CacheFailure(e.toString()));
1283:     }
1284:   }
1285: }

(End of file - total 1285 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 10.5s)

_Thinking:_

Now let me look at the app_constants and the kids gamified stage page, as well as the progress repository.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\core\\constants\\app_constants.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\core\constants\app_constants.dart</path>
<type>file</type>
<content>
1: abstract class AppConstants {
2:   // Quran
3:   static const int totalSurahs = 114;
4:   static const int totalAyahs = 6236;
5:   static const int totalJuz = 30;
6: 
7:   // Hifz spaced repetition intervals (days)
8:   static const List<int> spacedRepetitionIntervals = [1, 3, 7, 14, 30, 90];
9: 
10:   // Storage keys
11:   static const String kLastReadSurah = 'last_read_surah';
12:   static const String kLastReadAyah = 'last_read_ayah';
13:   static const String kStreakCount = 'streak_count';
14:   static const String kLastActiveDate = 'last_active_date';
15:   static const String kHifzProgress = 'hifz_progress';
16:   static const String kHifzCheckpointProgress = 'hifz_checkpoint_progress';
17:   static const String kHifzPathMode = 'hifz_path_mode';
18:   static const String kAzkarDone = 'azkar_done';
19:   static const String kFontSize = 'quran_font_size';
20:   static const String kReadPages = 'read_pages';
21: 
22:   // Audio base URL (EveryAyah CDN)
23:   static const String audioBaseUrl =
24:       'https://everyayah.com/data/Alafasy_128kbps/';
25: 
26:   // Hifz evaluation
27:   static const double kSimilarityThreshold = 0.85;
28: 
29:   // ARCH-001 FIX: Was pointing to 'quran_simple.json' (non-existent). Actual file is 'quran.json'.
30:   static const String quranDataAsset = 'assets/data/quran.json';
31:   static const String azkarDataAsset = 'assets/data/azkar.json';
32: 
33:   // Font sizes
34:   static const double fontSizeSmall = 18.0;
35:   static const double fontSizeMedium = 22.0;
36:   static const double fontSizeLarge = 26.0;
37:   static const double fontSizeXLarge = 30.0;
38: 
39:   // App Links
40:   static const String androidStoreUrl =
41:       'https://play.google.com/store/apps/details?id=com.sayed.talia_quran';
42: }

(End of file - total 42 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\presentation\\pages\\kids_gamified_stage_page.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\presentation\pages\kids_gamified_stage_page.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/material.dart';
2: import 'package:go_router/go_router.dart';
3: 
4: import '../../../../core/constants/app_spacing.dart';
5: import '../../../../core/extensions/context_extensions.dart';
6: import '../../../../core/router/app_router.dart';
7: import '../../../../core/theme/app_typography.dart';
8: import '../../domain/entities/memorization_entities.dart';
9: import '../theme/kids_theme.dart';
10: import '../widgets/kids_stage_details.dart';
11: 
12: class KidsGamifiedStagePage extends StatelessWidget {
13:   const KidsGamifiedStagePage({
14:     super.key,
15:     required this.stage,
16:     this.surahName,
17:     this.onStartMission,
18:   });
19: 
20:   final KidsJourneyStage stage;
21:   final String? surahName;
22:   final VoidCallback? onStartMission;
23: 
24:   @override
25:   Widget build(BuildContext context) {
26:     final resolvedSurahName =
27:         surahName ?? '${context.l10n.surah} ${stage.surahId}';
28:     return KidsGamifiedStageContent(
29:       stage: stage,
30:       surahName: resolvedSurahName,
31:       onBack: () => context.canPop() ? context.pop() : context.go('/'),
32:       onStartMission: onStartMission ?? () => _startMission(context, stage),
33:     );
34:   }
35: 
36:   void _startMission(BuildContext context, KidsJourneyStage stage) {
37:     final startAyah = stage.nextAyahToStart;
38:     context.push(
39:       '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}&ayahNumber=$startAyah',
40:     );
41:   }
42: }
43: 
44: @visibleForTesting
45: class KidsGamifiedStageContent extends StatelessWidget {
46:   const KidsGamifiedStageContent({
47:     super.key,
48:     required this.stage,
49:     required this.surahName,
50:     required this.onBack,
51:     required this.onStartMission,
52:   });
53: 
54:   final KidsJourneyStage stage;
55:   final String surahName;
56:   final VoidCallback onBack;
57:   final VoidCallback onStartMission;
58: 
59:   @override
60:   Widget build(BuildContext context) {
61:     return Container(
62:       decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
63:       child: Scaffold(
64:         backgroundColor: Colors.transparent,
65:         body: SafeArea(
66:           child: Column(
67:             children: [
68:               _KidsGamifiedStageAppBar(onBack: onBack),
69:               Expanded(
70:                 child: CustomScrollView(
71:                   key: const PageStorageKey<String>('kids-gamified-stage'),
72:                   physics: const AlwaysScrollableScrollPhysics(),
73:                   slivers: [
74:                     SliverPadding(
75:                       padding: const EdgeInsets.fromLTRB(
76:                         AppSpacing.lg,
77:                         AppSpacing.md,
78:                         AppSpacing.lg,
79:                         AppSpacing.xl,
80:                       ),
81:                       sliver: SliverList.list(
82:                         children: [
83:                           DecoratedBox(
84:                             decoration: BoxDecoration(
85:                               color: KidsTheme.creamParchment,
86:                               borderRadius: KidsTheme.cardRadius,
87:                               border: Border.all(
88:                                 color: KidsTheme.parchmentEdge,
89:                               ),
90:                               boxShadow: [
91:                                 BoxShadow(
92:                                   color: Colors.black.withValues(alpha: 0.14),
93:                                   blurRadius: 22,
94:                                   offset: const Offset(0, 10),
95:                                 ),
96:                               ],
97:                             ),
98:                             child: Padding(
99:                               padding: const EdgeInsets.all(AppSpacing.lg),
100:                               child: KidsStageDetails(
101:                                 stage: stage,
102:                                 surahName: surahName,
103:                                 onStartMission: onStartMission,
104:                               ),
105:                             ),
106:                           ),
107:                           const SizedBox(height: 96),
108:                         ],
109:                       ),
110:                     ),
111:                   ],
112:                 ),
113:               ),
114:             ],
115:           ),
116:         ),
117:       ),
118:     );
119:   }
120: }
121: 
122: class _KidsGamifiedStageAppBar extends StatelessWidget {
123:   const _KidsGamifiedStageAppBar({required this.onBack});
124: 
125:   final VoidCallback onBack;
126: 
127:   @override
128:   Widget build(BuildContext context) {
129:     return Padding(
130:       padding: const EdgeInsets.fromLTRB(
131:         AppSpacing.sm,
132:         AppSpacing.sm,
133:         AppSpacing.lg,
134:         AppSpacing.sm,
135:       ),
136:       child: Row(
137:         children: [
138:           IconButton(
139:             tooltip: MaterialLocalizations.of(context).backButtonTooltip,
140:             onPressed: onBack,
141:             icon: const Icon(Icons.arrow_back_ios_new_rounded),
142:             color: Colors.white,
143:           ),
144:           const SizedBox(width: AppSpacing.sm),
145:           Expanded(
146:             child: Text(
147:               context.l10n.kidsGamifiedMissions,
148:               maxLines: 1,
149:               overflow: TextOverflow.ellipsis,
150:               style: AppTypography.titleLarge.copyWith(
151:                 color: Colors.white,
152:                 fontFamily: 'Amiri',
153:                 letterSpacing: 0,
154:               ),
155:             ),
156:           ),
157:         ],
158:       ),
159:     );
160:   }
161: }

(End of file - total 161 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 10.5s)

_Thinking:_

Let me also look at the progress entities, hifz entities, and the HifzUnlockRules. I want to make sure I understand the entire structure before forming the audit.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\domain\\entities\\progress_entities.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\progress\domain\entities\progress_entities.dart</path>
<type>file</type>
<content>
1: import 'package:equatable/equatable.dart';
2: 
3: class OverallProgress extends Equatable {
4:   const OverallProgress({
5:     required this.memorizedAyahs,
6:     required this.totalAyahs,
7:     required this.memorizedSurahs,
8:     required this.totalSurahs,
9:     required this.memorizedJuz,
10:     required this.totalJuz,
11:     required this.readAyahs,
12:     required this.readSurahs,
13:     required this.readJuz,
14:     required this.streakDays,
15:     required this.lastActiveDate,
16:     required this.achievements,
17:     required this.readPagesCount,
18:     required this.totalQuranPages,
19:     required this.learningAyahs,
20:     required this.reviewAyahs,
21:     // Smart Memorization (MemorizationPlus) stats
22:     this.smartMemorizedAyahs = 0,
23:     this.smartReviewAyahs = 0,
24:     this.kidsPoints = 0,
25:     this.kidsStars = 0,
26:   });
27: 
28:   final int memorizedAyahs;
29:   final int totalAyahs;
30:   final int memorizedSurahs;
31:   final int totalSurahs;
32:   final int memorizedJuz;
33:   final int totalJuz;
34: 
35:   // Reading-only stats
36:   final int readAyahs;
37:   final int readSurahs;
38:   final int readJuz;
39: 
40:   // In-progress stats
41:   final int learningAyahs;
42:   final int reviewAyahs;
43: 
44:   // Smart Memorization stats
45:   final int smartMemorizedAyahs;
46:   final int smartReviewAyahs;
47:   final int kidsPoints;
48:   final int kidsStars;
49: 
50:   final int streakDays;
51:   final DateTime? lastActiveDate;
52:   final List<Achievement> achievements;
53:   final int readPagesCount;
54:   final int totalQuranPages;
55: 
56:   double get quranPercentage => totalQuranPages == 0
57:       ? 0
58:       : (readPagesCount / totalQuranPages).clamp(0.0, 1.0);
59: 
60:   double get surahPercentage =>
61:       totalSurahs == 0 ? 0 : (memorizedSurahs / totalSurahs).clamp(0.0, 1.0);
62: 
63:   double get memorizedAyahsPercentage =>
64:       totalAyahs == 0 ? 0 : (memorizedAyahs / totalAyahs).clamp(0.0, 1.0);
65: 
66:   double get memorizedJuzPercentage =>
67:       totalJuz == 0 ? 0 : (memorizedJuz / totalJuz).clamp(0.0, 1.0);
68: 
69:   int get unlockedAchievements =>
70:       achievements.where((a) => a.isUnlocked).length;
71: 
72:   @override
73:   List<Object?> get props => [
74:     memorizedAyahs,
75:     memorizedSurahs,
76:     memorizedJuz,
77:     readAyahs,
78:     readSurahs,
79:     readJuz,
80:     streakDays,
81:     achievements,
82:     readPagesCount,
83:     learningAyahs,
84:     reviewAyahs,
85:     smartMemorizedAyahs,
86:     smartReviewAyahs,
87:     kidsPoints,
88:     kidsStars,
89:   ];
90: }
91: 
92: enum AchievementCategory { reading, memorization, streak, milestone }
93: 
94: class Achievement extends Equatable {
95:   const Achievement({
96:     required this.id,
97:     required this.titleKey,
98:     required this.descriptionKey,
99:     required this.icon,
100:     required this.isUnlocked,
101:     required this.category,
102:     this.currentValue = 0,
103:     this.targetValue = 1,
104:   });
105: 
106:   final String id;
107:   final String titleKey;
108:   final String descriptionKey;
109:   final String icon;
110:   final bool isUnlocked;
111:   final AchievementCategory category;
112:   final int currentValue;
113:   final int targetValue;
114: 
115:   double get progressPercent =>
116:       targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);
117: 
118:   @override
119:   List<Object?> get props => [id, isUnlocked, currentValue];
120: }

(End of file - total 120 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\domain\\entities\\hifz_entities.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\domain\entities\hifz_entities.dart</path>
<type>file</type>
<content>
1: import 'package:equatable/equatable.dart';
2: 
3: enum AyahStatus { notStarted, learning, review, memorized }
4: 
5: class AyahProgress extends Equatable {
6:   const AyahProgress({
7:     required this.surahId,
8:     required this.ayahNumber,
9:     required this.status,
10:     required this.repetitions,
11:     required this.nextReviewDate,
12:     required this.lastReviewDate,
13:   });
14: 
15:   final int surahId;
16:   final int ayahNumber;
17:   final AyahStatus status;
18:   final int repetitions;
19:   final DateTime nextReviewDate;
20:   final DateTime lastReviewDate;
21: 
22:   bool get isDue => DateTime.now().toUtc().isAfter(nextReviewDate);
23: 
24:   AyahProgress copyWith({
25:     AyahStatus? status,
26:     int? repetitions,
27:     DateTime? nextReviewDate,
28:     DateTime? lastReviewDate,
29:   }) => AyahProgress(
30:     surahId: surahId,
31:     ayahNumber: ayahNumber,
32:     status: status ?? this.status,
33:     repetitions: repetitions ?? this.repetitions,
34:     nextReviewDate: nextReviewDate ?? this.nextReviewDate,
35:     lastReviewDate: lastReviewDate ?? this.lastReviewDate,
36:   );
37: 
38:   String get key => '${surahId}_$ayahNumber';
39: 
40:   @override
41:   List<Object?> get props => [surahId, ayahNumber, status, repetitions];
42: }
43: 
44: class SurahHifzProgress extends Equatable {
45:   const SurahHifzProgress({
46:     required this.surahId,
47:     required this.totalAyahs,
48:     required this.memorizedCount,
49:     required this.reviewCount,
50:     required this.learningCount,
51:   });
52: 
53:   final int surahId;
54:   final int totalAyahs;
55:   final int memorizedCount;
56:   final int reviewCount;
57:   final int learningCount;
58: 
59:   double get percentage => totalAyahs == 0 ? 0 : memorizedCount / totalAyahs;
60: 
61:   bool get isComplete => memorizedCount == totalAyahs;
62: 
63:   @override
64:   List<Object?> get props => [
65:     surahId,
66:     totalAyahs,
67:     memorizedCount,
68:     reviewCount,
69:     learningCount,
70:   ];
71: }
72: 
73: class HifzSegment extends Equatable {
74:   const HifzSegment({
75:     required this.surahId,
76:     required this.startAyah,
77:     required this.endAyah,
78:     required this.totalAyahs,
79:   });
80: 
81:   final int surahId;
82:   final int startAyah;
83:   final int endAyah;
84:   final int totalAyahs;
85: 
86:   bool get isFullSurah => startAyah == 1 && endAyah == totalAyahs;
87: 
88:   String get key => '${surahId}_${startAyah}_$endAyah';
89: 
90:   @override
91:   List<Object?> get props => [surahId, startAyah, endAyah, totalAyahs];
92: }

(End of file - total 92 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\domain\\hifz_unlock_rules.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\domain\hifz_unlock_rules.dart</path>
<type>file</type>
<content>
1: import '../../quran/domain/entities/quran_entities.dart';
2: import 'entities/hifz_entities.dart';
3: 
4: List<Surah> sortSurahsForHifzPath({
5:   required List<Surah> surahs,
6:   required String? path,
7: }) {
8:   final sortedSurahs = List<Surah>.from(surahs);
9:   if (path == 'backward') {
10:     sortedSurahs.sort((a, b) => b.id.compareTo(a.id));
11:   } else {
12:     sortedSurahs.sort((a, b) => a.id.compareTo(b.id));
13:   }
14:   return sortedSurahs;
15: }
16: 
17: Set<int> buildUnlockedSurahIds({
18:   required List<Surah> orderedSurahs,
19:   required Map<int, SurahHifzProgress> progressMap,
20: }) {
21:   final unlockedSurahIds = <int>{};
22:   var allPreviousSurahsComplete = true;
23: 
24:   for (var i = 0; i < orderedSurahs.length; i++) {
25:     final surah = orderedSurahs[i];
26:     if (i == 0 || allPreviousSurahsComplete) {
27:       unlockedSurahIds.add(surah.id);
28:     }
29: 
30:     final isCurrentSurahComplete = progressMap[surah.id]?.isComplete ?? false;
31:     allPreviousSurahsComplete =
32:         allPreviousSurahsComplete && isCurrentSurahComplete;
33:   }
34: 
35:   return unlockedSurahIds;
36: }
37: 
38: List<HifzSegment> generateHifzSegments({
39:   required int surahId,
40:   required int totalAyahs,
41: }) {
42:   if (totalAyahs <= 0) return const [];
43: 
44:   if (totalAyahs <= 20) {
45:     return [
46:       HifzSegment(
47:         surahId: surahId,
48:         startAyah: 1,
49:         endAyah: totalAyahs,
50:         totalAyahs: totalAyahs,
51:       ),
52:     ];
53:   }
54: 
55:   final segments = <HifzSegment>[];
56:   for (var start = 1; start <= totalAyahs; start += 10) {
57:     final end = start + 9 > totalAyahs ? totalAyahs : start + 9;
58:     segments.add(
59:       HifzSegment(
60:         surahId: surahId,
61:         startAyah: start,
62:         endAyah: end,
63:         totalAyahs: totalAyahs,
64:       ),
65:     );
66:   }
67:   return segments;
68: }
69: 
70: HifzSegment? getSegmentEndingAt({
71:   required List<HifzSegment> segments,
72:   required int ayahNumber,
73: }) {
74:   for (final segment in segments) {
75:     if (segment.endAyah == ayahNumber) return segment;
76:   }
77:   return null;
78: }
79: 
80: HifzSegment? getSegmentContaining({
81:   required List<HifzSegment> segments,
82:   required int ayahNumber,
83: }) {
84:   for (final segment in segments) {
85:     if (ayahNumber >= segment.startAyah && ayahNumber <= segment.endAyah) {
86:       return segment;
87:     }
88:   }
89:   return null;
90: }
91: 
92: bool canUnlockNextAyah({
93:   required int currentAyah,
94:   required int totalAyahs,
95:   required List<HifzSegment> segments,
96:   required Set<String> passedSegmentKeys,
97: }) {
98:   if (currentAyah >= totalAyahs) return false;
99: 
100:   final currentSegment = getSegmentContaining(
101:     segments: segments,
102:     ayahNumber: currentAyah,
103:   );
104:   final nextSegment = getSegmentContaining(
105:     segments: segments,
106:     ayahNumber: currentAyah + 1,
107:   );
108: 
109:   if (currentSegment == null || nextSegment == null) return false;
110:   if (currentSegment == nextSegment) return true;
111: 
112:   return passedSegmentKeys.contains(currentSegment.key);
113: }
114: 
115: HifzSegment? getNextRequiredCheckpoint({
116:   required List<HifzSegment> segments,
117:   required Set<String> passedSegmentKeys,
118:   required Map<int, AyahProgress> progressMap,
119: }) {
120:   for (final segment in segments) {
121:     if (passedSegmentKeys.contains(segment.key)) continue;
122:     final endProgress = progressMap[segment.endAyah];
123:     if (endProgress == null) continue;
124:     if (endProgress.status == AyahStatus.review ||
125:         endProgress.status == AyahStatus.memorized ||
126:         endProgress.repetitions > 0) {
127:       return segment;
128:     }
129:   }
130:   return null;
131: }

(End of file - total 131 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 12.0s)

_Thinking:_

Now let me look at the progress page to see how progress is shown and the data sources.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\data\\datasources\\progress_local_datasource.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\progress\data\datasources\progress_local_datasource.dart</path>
<type>file</type>
<content>
1: import 'dart:convert';
2: import 'package:shared_preferences/shared_preferences.dart';
3: import '../../../../core/constants/app_constants.dart';
4: 
5: abstract class ProgressLocalDatasource {
6:   int getStreakDays();
7:   DateTime? getLastActiveDate();
8:   Future<void> saveStreak(int days, DateTime date);
9:   List<int> getReadPages();
10:   Future<void> saveReadPage(int pageNumber);
11: }
12: 
13: class ProgressLocalDatasourceImpl implements ProgressLocalDatasource {
14:   ProgressLocalDatasourceImpl(this._prefs);
15:   final SharedPreferences _prefs;
16: 
17:   @override
18:   int getStreakDays() => _prefs.getInt(AppConstants.kStreakCount) ?? 0;
19: 
20:   @override
21:   DateTime? getLastActiveDate() {
22:     final raw = _prefs.getString(AppConstants.kLastActiveDate);
23:     if (raw == null) return null;
24:     return DateTime.tryParse(raw);
25:   }
26: 
27:   @override
28:   Future<void> saveStreak(int days, DateTime date) async {
29:     final savedDays = await _prefs.setInt(AppConstants.kStreakCount, days);
30:     final savedDate = await _prefs.setString(
31:       AppConstants.kLastActiveDate,
32:       date.toIso8601String(),
33:     );
34:     if (!savedDays || !savedDate) {
35:       throw StateError('Failed to save streak');
36:     }
37:   }
38: 
39:   @override
40:   List<int> getReadPages() {
41:     final raw = _prefs.getString(AppConstants.kReadPages);
42:     if (raw == null) return [];
43:     try {
44:       final list = jsonDecode(raw) as List<dynamic>;
45:       final pages = <int>[];
46:       for (final item in list) {
47:         if (item is int && item >= 1 && item <= 604 && !pages.contains(item)) {
48:           pages.add(item);
49:         }
50:       }
51:       return pages;
52:     } catch (_) {
53:       return [];
54:     }
55:   }
56: 
57:   @override
58:   Future<void> saveReadPage(int pageNumber) async {
59:     if (pageNumber < 1 || pageNumber > 604) {
60:       throw ArgumentError.value(pageNumber, 'pageNumber', 'Must be 1..604');
61:     }
62:     final pages = getReadPages();
63:     if (!pages.contains(pageNumber)) {
64:       pages.add(pageNumber);
65:       final saved = await _prefs.setString(
66:         AppConstants.kReadPages,
67:         jsonEncode(pages),
68:       );
69:       if (!saved) {
70:         throw StateError('Failed to save read page');
71:       }
72:     }
73:   }
74: }

(End of file - total 74 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\data\\repositories\\progress_repository_impl.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\progress\data\repositories\progress_repository_impl.dart</path>
<type>file</type>
<content>
1: import 'package:dartz/dartz.dart';
2: import '../../../../core/constants/app_constants.dart';
3: import '../../../../core/error/app_failure.dart';
4: import '../../../hifz/data/datasources/hifz_local_datasource.dart';
5: import '../../../hifz/domain/entities/hifz_entities.dart';
6: import '../../domain/entities/progress_entities.dart';
7: import '../../domain/repositories/progress_repository.dart';
8: import '../datasources/progress_local_datasource.dart';
9: 
10: import '../../../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
11: import '../../../quran/data/datasources/quran_local_datasource.dart';
12: 
13: class ProgressRepositoryImpl implements ProgressRepository {
14:   ProgressRepositoryImpl(
15:     this._progressDs,
16:     this._hifzDs,
17:     this._memPlusDs,
18:     this._quranDs,
19:   );
20:   final ProgressLocalDatasource _progressDs;
21:   final HifzLocalDatasource _hifzDs;
22:   final MemorizationPlusLocalDatasource _memPlusDs;
23:   final QuranLocalDatasource _quranDs;
24: 
25:   @override
26:   Future<Either<Failure, OverallProgress>> getOverallProgress() async {
27:     try {
28:       final allProgress = await _hifzDs.getAllProgress();
29: 
30:       // Memorized ayahs count
31:       final memorizedAyahs = allProgress
32:           .where((p) => p.status == AyahStatus.memorized)
33:           .length;
34: 
35:       // Learning ayahs
36:       final learningAyahs = allProgress
37:           .where((p) => p.status == AyahStatus.learning)
38:           .length;
39: 
40:       // Review ayahs
41:       final reviewAyahs = allProgress
42:           .where((p) => p.status == AyahStatus.review)
43:           .length;
44: 
45:       final surahs = await _quranDs.getSurahs();
46:       final surahAyahCounts = {
47:         for (final surah in surahs) surah.id: surah.ayahCount,
48:       };
49: 
50:       // Count memorized surahs only when every ayah in the surah is recorded as memorized.
51:       final bySurah = <int, List<dynamic>>{};
52:       for (final p in allProgress) {
53:         bySurah.putIfAbsent(p.surahId, () => []).add(p);
54:       }
55: 
56:       final memorizedSurahs = bySurah.entries.where((entry) {
57:         final totalAyahs = surahAyahCounts[entry.key];
58:         if (totalAyahs == null || entry.value.length < totalAyahs) {
59:           return false;
60:         }
61:         return entry.value.every((a) => a.status == AyahStatus.memorized);
62:       }).length;
63: 
64:       // Read pages & reading stats
65:       final readPages = _progressDs.getReadPages();
66:       final readPagesCount = readPages.length;
67: 
68:       // Calculate read-only stats: pages read means those ayahs were read
69:       // Reading juz = pages read / 20 (each juz ~20 pages)
70:       final readJuz = (readPagesCount / 20).floor().clamp(
71:         0,
72:         AppConstants.totalJuz,
73:       );
74: 
75:       // Reading stats are derived from pages explicitly confirmed as read.
76:       final readAyahKeys = <String>{};
77:       final readSurahIds = <int>{};
78: 
79:       for (final page in readPages) {
80:         try {
81:           final ayahs = await _quranDs.getAyahsByPage(page);
82:           for (final ayah in ayahs) {
83:             readAyahKeys.add('${ayah.surahId}_${ayah.numberInSurah}');
84:             readSurahIds.add(ayah.surahId);
85:           }
86:         } catch (_) {
87:           // Ignore a stale page entry rather than failing the whole progress page.
88:         }
89:       }
90: 
91:       final readSurahs = readSurahIds.length;
92:       final readAyahs = readAyahKeys.length;
93: 
94:       // BUG-6 FIX: Accurate memorizedJuz — check each juz individually
95:       // instead of dividing total memorized ayahs by average juz size.
96:       final memorizedKeys = allProgress
97:           .where((p) => p.status == AyahStatus.memorized)
98:           .map((p) => '${p.surahId}_${p.ayahNumber}')
99:           .toSet();
100: 
101:       int memorizedJuz = 0;
102:       try {
103:         final ayahsByJuz = await _quranDs.getAyahsGroupedByJuz();
104:         for (int juz = 1; juz <= AppConstants.totalJuz; juz++) {
105:           final juzAyahs = ayahsByJuz[juz];
106:           if (juzAyahs != null &&
107:               juzAyahs.isNotEmpty &&
108:               juzAyahs.every(
109:                 (a) =>
110:                     memorizedKeys.contains('${a.surahId}_${a.numberInSurah}'),
111:               )) {
112:             memorizedJuz++;
113:           }
114:         }
115:       } catch (_) {
116:         // Fallback to approximate calculation if juz data unavailable
117:         memorizedJuz =
118:             (memorizedAyahs / (AppConstants.totalAyahs / AppConstants.totalJuz))
119:                 .floor()
120:                 .clamp(0, AppConstants.totalJuz);
121:       }
122: 
123:       final streak = _progressDs.getStreakDays();
124:       final lastActive = _progressDs.getLastActiveDate();
125: 
126:       // Update streak using UTC-normalized today to avoid timezone boundary bugs.
127:       final today = DateTime.now().toUtc();
128:       final updatedStreak = _calculateStreak(streak, lastActive, today);
129:       if (updatedStreak != streak) {
130:         await _progressDs.saveStreak(updatedStreak, today);
131:       }
132: 
133:       final achievements = _buildAchievements(
134:         memorizedAyahs: memorizedAyahs,
135:         memorizedSurahs: memorizedSurahs,
136:         memorizedJuz: memorizedJuz,
137:         streak: updatedStreak,
138:         readPages: readPagesCount,
139:         readAyahs: readAyahs,
140:         learningAyahs: learningAyahs,
141:         reviewAyahs: reviewAyahs,
142:       );
143: 
144:       // Smart memorization system data
145:       final memPlusRecords = await _memPlusDs.getAllReviewRecords();
146:       final smartMemorizedAyahs = memPlusRecords
147:           .where((r) => r.strengthLevel >= 6)
148:           .length;
149:       final smartReviewAyahs = memPlusRecords
150:           .where((r) => r.strengthLevel < 6 && r.strengthLevel > 0)
151:           .length;
152: 
153:       final kidsProgress = await _memPlusDs.getKidsProgress();
154: 
155:       return Right(
156:         OverallProgress(
157:           memorizedAyahs: memorizedAyahs,
158:           totalAyahs: AppConstants.totalAyahs,
159:           memorizedSurahs: memorizedSurahs,
160:           totalSurahs: AppConstants.totalSurahs,
161:           memorizedJuz: memorizedJuz,
162:           totalJuz: AppConstants.totalJuz,
163:           readAyahs: readAyahs,
164:           readSurahs: readSurahs,
165:           readJuz: readJuz,
166:           learningAyahs: learningAyahs,
167:           reviewAyahs: reviewAyahs,
168:           streakDays: updatedStreak,
169:           lastActiveDate: lastActive,
170:           achievements: achievements,
171:           readPagesCount: readPagesCount,
172:           totalQuranPages: 604,
173:           smartMemorizedAyahs: smartMemorizedAyahs,
174:           smartReviewAyahs: smartReviewAyahs,
175:           kidsPoints: kidsProgress.totalPoints,
176:           kidsStars: kidsProgress.starsEarned,
177:         ),
178:       );
179:     } catch (e) {
180:       return Left(CacheFailure(e.toString()));
181:     }
182:   }
183: 
184:   @override
185:   Future<Either<Failure, void>> saveReadPage(int pageNumber) async {
186:     try {
187:       await _progressDs.saveReadPage(pageNumber);
188:       return const Right(null);
189:     } catch (e) {
190:       return Left(CacheFailure(e.toString()));
191:     }
192:   }
193: 
194:   @override
195:   Future<Either<Failure, void>> updateStreak() async {
196:     try {
197:       final streak = _progressDs.getStreakDays();
198:       final lastActive = _progressDs.getLastActiveDate();
199:       // UTC-normalized: consistent with getOverallProgress() and StreakService.
200:       final now = DateTime.now().toUtc();
201:       final updated = _calculateStreak(streak, lastActive, now);
202:       await _progressDs.saveStreak(updated, now);
203:       return const Right(null);
204:     } catch (e) {
205:       return Left(CacheFailure(e.toString()));
206:     }
207:   }
208: 
209:   int _calculateStreak(int current, DateTime? lastActive, DateTime now) {
210:     if (lastActive == null) return 1;
211:     // Compare on UTC date components to avoid DST-ambiguous local midnight.
212:     final lastDate = DateTime.utc(
213:       lastActive.toUtc().year,
214:       lastActive.toUtc().month,
215:       lastActive.toUtc().day,
216:     );
217:     final nowDate = DateTime.utc(now.year, now.month, now.day);
218:     final diff = nowDate.difference(lastDate).inDays;
219:     if (diff == 0) return current; // Same day
220:     if (diff == 1) return current + 1; // Consecutive day
221:     return 1; // Streak broken
222:   }
223: 
224:   List<Achievement> _buildAchievements({
225:     required int memorizedAyahs,
226:     required int memorizedSurahs,
227:     required int memorizedJuz,
228:     required int streak,
229:     required int readPages,
230:     required int readAyahs,
231:     required int learningAyahs,
232:     required int reviewAyahs,
233:   }) {
234:     return [
235:       // ─── Reading Achievements ───────────────────────────────────────
236:       Achievement(
237:         id: 'first_page',
238:         titleKey: 'الصفحة الأولى',
239:         descriptionKey: 'اقرأ أول صفحة من القرآن',
240:         icon: '📖',
241:         isUnlocked: readPages >= 1,
242:         category: AchievementCategory.reading,
243:         currentValue: readPages.clamp(0, 1),
244:         targetValue: 1,
245:       ),
246:       Achievement(
247:         id: 'ten_pages',
248:         titleKey: '١٠ صفحات',
249:         descriptionKey: 'اقرأ ١٠ صفحات من القرآن',
250:         icon: '📚',
251:         isUnlocked: readPages >= 10,
252:         category: AchievementCategory.reading,
253:         currentValue: readPages.clamp(0, 10),
254:         targetValue: 10,
255:       ),
256:       Achievement(
257:         id: 'fifty_pages',
258:         titleKey: '٥٠ صفحة',
259:         descriptionKey: 'اقرأ ٥٠ صفحة من القرآن',
260:         icon: '🌟',
261:         isUnlocked: readPages >= 50,
262:         category: AchievementCategory.reading,
263:         currentValue: readPages.clamp(0, 50),
264:         targetValue: 50,
265:       ),
266:       Achievement(
267:         id: 'juz_read',
268:         titleKey: 'جزء كامل',
269:         descriptionKey: 'اقرأ جزءاً كاملاً (٢٠ صفحة)',
270:         icon: '✨',
271:         isUnlocked: readPages >= 20,
272:         category: AchievementCategory.reading,
273:         currentValue: readPages.clamp(0, 20),
274:         targetValue: 20,
275:       ),
276:       Achievement(
277:         id: 'five_juz_read',
278:         titleKey: '٥ أجزاء',
279:         descriptionKey: 'اقرأ ٥ أجزاء من القرآن',
280:         icon: '🌙',
281:         isUnlocked: readPages >= 100,
282:         category: AchievementCategory.reading,
283:         currentValue: readPages.clamp(0, 100),
284:         targetValue: 100,
285:       ),
286:       Achievement(
287:         id: 'half_quran_read',
288:         titleKey: 'نصف القرآن',
289:         descriptionKey: 'اقرأ نصف القرآن الكريم',
290:         icon: '🏆',
291:         isUnlocked: readPages >= 302,
292:         category: AchievementCategory.reading,
293:         currentValue: readPages.clamp(0, 302),
294:         targetValue: 302,
295:       ),
296:       Achievement(
297:         id: 'full_quran_read',
298:         titleKey: 'ختم القرآن',
299:         descriptionKey: 'اقرأ القرآن الكريم كاملاً',
300:         icon: '👑',
301:         isUnlocked: readPages >= 604,
302:         category: AchievementCategory.reading,
303:         currentValue: readPages.clamp(0, 604),
304:         targetValue: 604,
305:       ),
306: 
307:       // ─── Memorization Achievements ──────────────────────────────────
308:       Achievement(
309:         id: 'first_ayah',
310:         titleKey: 'أول آية',
311:         descriptionKey: 'احفظ أول آية من القرآن',
312:         icon: '⭐',
313:         isUnlocked: memorizedAyahs >= 1,
314:         category: AchievementCategory.memorization,
315:         currentValue: memorizedAyahs.clamp(0, 1),
316:         targetValue: 1,
317:       ),
318:       Achievement(
319:         id: 'ten_ayahs',
320:         titleKey: '١٠ آيات',
321:         descriptionKey: 'احفظ ١٠ آيات',
322:         icon: '🌟',
323:         isUnlocked: memorizedAyahs >= 10,
324:         category: AchievementCategory.memorization,
325:         currentValue: memorizedAyahs.clamp(0, 10),
326:         targetValue: 10,
327:       ),
328:       Achievement(
329:         id: 'fifty_ayahs',
330:         titleKey: '٥٠ آية',
331:         descriptionKey: 'احفظ ٥٠ آية',
332:         icon: '💫',
333:         isUnlocked: memorizedAyahs >= 50,
334:         category: AchievementCategory.memorization,
335:         currentValue: memorizedAyahs.clamp(0, 50),
336:         targetValue: 50,
337:       ),
338:       Achievement(
339:         id: 'hundred_ayahs',
340:         titleKey: '١٠٠ آية',
341:         descriptionKey: 'احفظ ١٠٠ آية',
342:         icon: '🔥',
343:         isUnlocked: memorizedAyahs >= 100,
344:         category: AchievementCategory.memorization,
345:         currentValue: memorizedAyahs.clamp(0, 100),
346:         targetValue: 100,
347:       ),
348:       Achievement(
349:         id: 'first_surah',
350:         titleKey: 'أول سورة',
351:         descriptionKey: 'احفظ سورة كاملة',
352:         icon: '📜',
353:         isUnlocked: memorizedSurahs >= 1,
354:         category: AchievementCategory.memorization,
355:         currentValue: memorizedSurahs.clamp(0, 1),
356:         targetValue: 1,
357:       ),
358:       Achievement(
359:         id: 'five_surahs',
360:         titleKey: '٥ سور',
361:         descriptionKey: 'احفظ ٥ سور كاملة',
362:         icon: '🎯',
363:         isUnlocked: memorizedSurahs >= 5,
364:         category: AchievementCategory.memorization,
365:         currentValue: memorizedSurahs.clamp(0, 5),
366:         targetValue: 5,
367:       ),
368:       Achievement(
369:         id: 'ten_surahs',
370:         titleKey: '١٠ سور',
371:         descriptionKey: 'احفظ ١٠ سور كاملة',
372:         icon: '🏅',
373:         isUnlocked: memorizedSurahs >= 10,
374:         category: AchievementCategory.memorization,
375:         currentValue: memorizedSurahs.clamp(0, 10),
376:         targetValue: 10,
377:       ),
378:       Achievement(
379:         id: 'juz_amma',
380:         titleKey: 'جزء عمّ',
381:         descriptionKey: 'احفظ ٥٦٤ آية (جزء عمّ)',
382:         icon: '🌙',
383:         isUnlocked: memorizedAyahs >= 564,
384:         category: AchievementCategory.memorization,
385:         currentValue: memorizedAyahs.clamp(0, 564),
386:         targetValue: 564,
387:       ),
388:       Achievement(
389:         id: 'one_juz_memorized',
390:         titleKey: 'جزء محفوظ',
391:         descriptionKey: 'احفظ جزءاً كاملاً',
392:         icon: '📗',
393:         isUnlocked: memorizedJuz >= 1,
394:         category: AchievementCategory.memorization,
395:         currentValue: memorizedJuz.clamp(0, 1),
396:         targetValue: 1,
397:       ),
398:       Achievement(
399:         id: 'five_juz_memorized',
400:         titleKey: '٥ أجزاء محفوظة',
401:         descriptionKey: 'احفظ ٥ أجزاء من القرآن',
402:         icon: '💎',
403:         isUnlocked: memorizedJuz >= 5,
404:         category: AchievementCategory.memorization,
405:         currentValue: memorizedJuz.clamp(0, 5),
406:         targetValue: 5,
407:       ),
408:       Achievement(
409:         id: 'ten_juz_memorized',
410:         titleKey: '١٠ أجزاء',
411:         descriptionKey: 'احفظ ١٠ أجزاء من القرآن',
412:         icon: '🎖️',
413:         isUnlocked: memorizedJuz >= 10,
414:         category: AchievementCategory.memorization,
415:         currentValue: memorizedJuz.clamp(0, 10),
416:         targetValue: 10,
417:       ),
418:       Achievement(
419:         id: 'half_quran_memorized',
420:         titleKey: 'نصف القرآن',
421:         descriptionKey: 'احفظ نصف القرآن الكريم',
422:         icon: '🏆',
423:         isUnlocked: memorizedJuz >= 15,
424:         category: AchievementCategory.memorization,
425:         currentValue: memorizedJuz.clamp(0, 15),
426:         targetValue: 15,
427:       ),
428:       Achievement(
429:         id: 'full_quran_memorized',
430:         titleKey: 'حافظ القرآن',
431:         descriptionKey: 'احفظ القرآن الكريم كاملاً',
432:         icon: '👑',
433:         isUnlocked: memorizedAyahs >= AppConstants.totalAyahs,
434:         category: AchievementCategory.memorization,
435:         currentValue: memorizedAyahs.clamp(0, AppConstants.totalAyahs),
436:         targetValue: AppConstants.totalAyahs,
437:       ),
438: 
439:       // ─── Streak Achievements ────────────────────────────────────────
440:       Achievement(
441:         id: 'three_day_streak',
442:         titleKey: '٣ أيام متتالية',
443:         descriptionKey: 'حافظ على ٣ أيام متتالية',
444:         icon: '🔥',
445:         isUnlocked: streak >= 3,
446:         category: AchievementCategory.streak,
447:         currentValue: streak.clamp(0, 3),
448:         targetValue: 3,
449:       ),
450:       Achievement(
451:         id: 'week_streak',
452:         titleKey: 'أسبوع كامل',
453:         descriptionKey: 'حافظ على ٧ أيام متتالية',
454:         icon: '💪',
455:         isUnlocked: streak >= 7,
456:         category: AchievementCategory.streak,
457:         currentValue: streak.clamp(0, 7),
458:         targetValue: 7,
459:       ),
460:       Achievement(
461:         id: 'two_week_streak',
462:         titleKey: 'أسبوعان',
463:         descriptionKey: 'حافظ على ١٤ يوماً متتالية',
464:         icon: '⚡',
465:         isUnlocked: streak >= 14,
466:         category: AchievementCategory.streak,
467:         currentValue: streak.clamp(0, 14),
468:         targetValue: 14,
469:       ),
470:       Achievement(
471:         id: 'month_streak',
472:         titleKey: 'شهر كامل',
473:         descriptionKey: 'حافظ على ٣٠ يوماً متتالية',
474:         icon: '💎',
475:         isUnlocked: streak >= 30,
476:         category: AchievementCategory.streak,
477:         currentValue: streak.clamp(0, 30),
478:         targetValue: 30,
479:       ),
480:       Achievement(
481:         id: 'ninety_day_streak',
482:         titleKey: '٩٠ يوماً',
483:         descriptionKey: 'حافظ على ٩٠ يوماً متتالية',
484:         icon: '🌟',
485:         isUnlocked: streak >= 90,
486:         category: AchievementCategory.streak,
487:         currentValue: streak.clamp(0, 90),
488:         targetValue: 90,
489:       ),
490:       Achievement(
491:         id: 'year_streak',
492:         titleKey: 'سنة كاملة',
493:         descriptionKey: 'حافظ على ٣٦٥ يوماً متتالياً',
494:         icon: '👑',
495:         isUnlocked: streak >= 365,
496:         category: AchievementCategory.streak,
497:         currentValue: streak.clamp(0, 365),
498:         targetValue: 365,
499:       ),
500:     ];
501:   }
502: }

(End of file - total 502 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\hifz\\data\\datasources\\isar_hifz_local_datasource_impl.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\hifz\data\datasources\isar_hifz_local_datasource_impl.dart</path>
<type>file</type>
<content>
1: import 'dart:convert';
2: import 'package:isar/isar.dart';
3: import 'package:shared_preferences/shared_preferences.dart';
4: import '../../../../core/constants/app_constants.dart';
5: import '../models/ayah_progress_model.dart';
6: import '../models/isar_ayah_progress.dart';
7: import 'hifz_local_datasource.dart';
8: 
9: class IsarHifzLocalDatasourceImpl implements HifzLocalDatasource {
10:   IsarHifzLocalDatasourceImpl(this._isar, this._prefs);
11: 
12:   final Isar _isar;
13:   final SharedPreferences _prefs;
14: 
15:   static const _migrationKey = 'hifz_isar_migrated';
16: 
17:   /// Performs a one-time migration from SharedPreferences to Isar
18:   Future<void> migrateFromSharedPreferencesIfNeeded() async {
19:     final migrated = _prefs.getBool(_migrationKey) ?? false;
20:     if (migrated) return;
21: 
22:     final keys = _prefs
23:         .getKeys()
24:         .where((k) => k.startsWith(AppConstants.kHifzProgress))
25:         .toList();
26: 
27:     if (keys.isEmpty) {
28:       await _prefs.setBool(_migrationKey, true);
29:       return;
30:     }
31: 
32:     final modelsToMigrate = <AyahProgressModel>[];
33:     for (final k in keys) {
34:       final raw = _prefs.getString(k);
35:       if (raw != null) {
36:         try {
37:           modelsToMigrate.add(
38:             AyahProgressModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
39:           );
40:         } catch (_) {}
41:       }
42:     }
43: 
44:     if (modelsToMigrate.isNotEmpty) {
45:       final isarModels = modelsToMigrate
46:           .map(IsarAyahProgress.fromModel)
47:           .toList();
48:       await _isar.writeTxn(() async {
49:         await _isar.isarAyahProgress.putAll(isarModels);
50:       });
51:     }
52: 
53:     // Mark as migrated
54:     await _prefs.setBool(_migrationKey, true);
55:   }
56: 
57:   @override
58:   Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async {
59:     final results = await _isar.isarAyahProgress
60:         .filter()
61:         .surahIdEqualTo(surahId)
62:         .findAll();
63:     return results.map((e) => e.toModel()).toList();
64:   }
65: 
66:   @override
67:   Future<AyahProgressModel?> getAyahProgress(
68:     int surahId,
69:     int ayahNumber,
70:   ) async {
71:     final compositeKey = '${surahId}_$ayahNumber';
72:     final result = await _isar.isarAyahProgress
73:         .filter()
74:         .compositeKeyEqualTo(compositeKey)
75:         .findFirst();
76:     return result?.toModel();
77:   }
78: 
79:   @override
80:   Future<void> saveAyahProgress(AyahProgressModel progress) async {
81:     final isarModel = IsarAyahProgress.fromModel(progress);
82:     await _isar.writeTxn(() async {
83:       await _isar.isarAyahProgress.put(isarModel);
84:     });
85:   }
86: 
87:   @override
88:   Future<List<AyahProgressModel>> getAllProgress() async {
89:     final results = await _isar.isarAyahProgress.where().findAll();
90:     return results.map((e) => e.toModel()).toList();
91:   }
92: 
93:   String _checkpointKey(int surahId) =>
94:       '${AppConstants.kHifzCheckpointProgress}_$surahId';
95: 
96:   @override
97:   Future<Set<String>> getPassedCheckpointKeys(int surahId) async {
98:     return (_prefs.getStringList(_checkpointKey(surahId)) ?? const []).toSet();
99:   }
100: 
101:   @override
102:   Future<void> markCheckpointPassed(String checkpointKey) async {
103:     final parts = checkpointKey.split('_');
104:     if (parts.length < 3) {
105:       throw ArgumentError.value(
106:         checkpointKey,
107:         'checkpointKey',
108:         'Expected surah_start_end key',
109:       );
110:     }
111:     final surahId = int.parse(parts.first);
112:     final storageKey = _checkpointKey(surahId);
113:     final keys = (_prefs.getStringList(storageKey) ?? const []).toSet()
114:       ..add(checkpointKey);
115:     final saved = await _prefs.setStringList(storageKey, keys.toList()..sort());
116:     if (!saved) {
117:       throw StateError('Failed to save checkpoint progress for $checkpointKey');
118:     }
119:   }
120: 
121:   @override
122:   String? getHifzPath() {
123:     return _prefs.getString(AppConstants.kHifzPathMode);
124:   }
125: 
126:   @override
127:   Future<void> saveHifzPath(String path) async {
128:     if (path != 'forward' && path != 'backward') {
129:       throw ArgumentError.value(path, 'path', 'Unsupported hifz path');
130:     }
131:     final saved = await _prefs.setString(AppConstants.kHifzPathMode, path);
132:     if (!saved) {
133:       throw StateError('Failed to save hifz path');
134:     }
135:   }
136: }

(End of file - total 136 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 10.6s)

_Thinking:_

I have enough information now. Let me also look at the smart_memorization_settings entity and the memorization_models.dart.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\entities\\smart_memorization_settings.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\entities\smart_memorization_settings.dart</path>
<type>file</type>
<content>
1: import 'package:equatable/equatable.dart';
2: import 'memorization_entities.dart'; // For CustomMemorizationPlan
3: 
4: class SmartMemorizationSettings extends Equatable {
5:   const SmartMemorizationSettings({
6:     this.dailySchedule,
7:     this.reviewDays = const [],
8:     this.ayahIsolationEnabled = false,
9:     this.customPlan,
10:   });
11: 
12:   final String? dailySchedule;
13:   final List<int> reviewDays;
14:   final bool ayahIsolationEnabled;
15:   final CustomMemorizationPlan? customPlan;
16: 
17:   SmartMemorizationSettings copyWith({
18:     String? dailySchedule,
19:     bool clearDailySchedule = false,
20:     List<int>? reviewDays,
21:     bool? ayahIsolationEnabled,
22:     CustomMemorizationPlan? customPlan,
23:     bool clearCustomPlan = false,
24:   }) => SmartMemorizationSettings(
25:     dailySchedule: clearDailySchedule
26:         ? null
27:         : (dailySchedule ?? this.dailySchedule),
28:     reviewDays: reviewDays ?? this.reviewDays,
29:     ayahIsolationEnabled: ayahIsolationEnabled ?? this.ayahIsolationEnabled,
30:     customPlan: clearCustomPlan ? null : (customPlan ?? this.customPlan),
31:   );
32: 
33:   @override
34:   List<Object?> get props => [
35:     dailySchedule,
36:     reviewDays,
37:     ayahIsolationEnabled,
38:     customPlan,
39:   ];
40: }

(End of file - total 40 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\domain\\usecases\\memorization_plus_usecases.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\memorization_plus\domain\usecases\memorization_plus_usecases.dart</path>
<type>file</type>
<content>
1: import 'package:dartz/dartz.dart';
2: import '../../../../core/error/app_failure.dart';
3: import '../../../../core/utils/usecase.dart';
4: import '../entities/memorization_entities.dart';
5: import '../repositories/memorization_plus_repository.dart';
6: 
7: // ─── Memorization identity use-cases ─────────────────────────────────────────
8: 
9: class GetMemorizationProfileUsecase
10:     implements UseCaseNoParams<MemorizationProfile> {
11:   const GetMemorizationProfileUsecase(this._repository);
12:   final MemorizationPlusRepository _repository;
13: 
14:   @override
15:   Future<Either<Failure, MemorizationProfile>> call() =>
16:       _repository.getMemorizationProfile();
17: }
18: 
19: class SelectMemorizationPathUsecase
20:     implements UseCase<MemorizationProfile, MemorizationPath> {
21:   const SelectMemorizationPathUsecase(this._repository);
22:   final MemorizationPlusRepository _repository;
23: 
24:   @override
25:   Future<Either<Failure, MemorizationProfile>> call(MemorizationPath params) =>
26:       _repository.selectMemorizationPath(params);
27: }
28: 
29: class ContinueWithoutGuardianUsecase
30:     implements UseCaseNoParams<MemorizationProfile> {
31:   const ContinueWithoutGuardianUsecase(this._repository);
32:   final MemorizationPlusRepository _repository;
33: 
34:   @override
35:   Future<Either<Failure, MemorizationProfile>> call() =>
36:       _repository.continueWithoutGuardian();
37: }
38: 
39: class CreateGuardianPairingSessionUsecase
40:     implements UseCaseNoParams<PairingSession> {
41:   const CreateGuardianPairingSessionUsecase(this._repository);
42:   final MemorizationPlusRepository _repository;
43: 
44:   @override
45:   Future<Either<Failure, PairingSession>> call() =>
46:       _repository.createGuardianPairingSession();
47: }
48: 
49: class AcceptGuardianPairingCodeUsecase
50:     implements UseCase<MemorizationProfile, String> {
51:   const AcceptGuardianPairingCodeUsecase(this._repository);
52:   final MemorizationPlusRepository _repository;
53: 
54:   @override
55:   Future<Either<Failure, MemorizationProfile>> call(String params) =>
56:       _repository.acceptGuardianPairingCode(params);
57: }
58: 
59: class RefreshPairingSessionUsecase implements UseCaseNoParams<PairingSession?> {
60:   const RefreshPairingSessionUsecase(this._repository);
61:   final MemorizationPlusRepository _repository;
62: 
63:   @override
64:   Future<Either<Failure, PairingSession?>> call() =>
65:       _repository.refreshPairingSession();
66: }
67: 
68: class UnlinkGuardianUsecase implements UseCaseNoParams<MemorizationProfile> {
69:   const UnlinkGuardianUsecase(this._repository);
70:   final MemorizationPlusRepository _repository;
71: 
72:   @override
73:   Future<Either<Failure, MemorizationProfile>> call() =>
74:       _repository.unlinkGuardian();
75: }
76: 
77: class SetParentGuardianModeUsecase
78:     implements UseCase<MemorizationProfile, bool> {
79:   const SetParentGuardianModeUsecase(this._repository);
80:   final MemorizationPlusRepository _repository;
81: 
82:   @override
83:   Future<Either<Failure, MemorizationProfile>> call(bool params) =>
84:       _repository.setParentGuardianMode(params);
85: }
86: 
87: class RefreshChildGuardianLinkUsecase
88:     implements UseCaseNoParams<MemorizationProfile> {
89:   const RefreshChildGuardianLinkUsecase(this._repository);
90:   final MemorizationPlusRepository _repository;
91: 
92:   @override
93:   Future<Either<Failure, MemorizationProfile>> call() =>
94:       _repository.refreshChildGuardianLink();
95: }
96: 
97: class ResetMemorizationIdentityUsecase
98:     implements UseCaseNoParams<MemorizationProfile> {
99:   const ResetMemorizationIdentityUsecase(this._repository);
100:   final MemorizationPlusRepository _repository;
101: 
102:   @override
103:   Future<Either<Failure, MemorizationProfile>> call() =>
104:       _repository.resetMemorizationIdentity();
105: }
106: 
107: class GetSmartMemorizationSettingsUsecase
108:     implements UseCaseNoParams<SmartMemorizationSettings> {
109:   const GetSmartMemorizationSettingsUsecase(this._repository);
110:   final MemorizationPlusRepository _repository;
111: 
112:   @override
113:   Future<Either<Failure, SmartMemorizationSettings>> call() =>
114:       _repository.getSmartSettings();
115: }
116: 
117: class SaveSmartMemorizationSettingsUsecase
118:     implements UseCase<void, SmartMemorizationSettings> {
119:   const SaveSmartMemorizationSettingsUsecase(this._repository);
120:   final MemorizationPlusRepository _repository;
121: 
122:   @override
123:   Future<Either<Failure, void>> call(SmartMemorizationSettings params) =>
124:       _repository.saveSmartSettings(params);
125: }
126: 
127: // ─── GenerateDailyPlanUsecase ─────────────────────────────────────────────────
128: 
129: class GenerateDailyPlanParams {
130:   const GenerateDailyPlanParams({
131:     required this.surahId,
132:     this.newAyahsPerDay = 5,
133:   });
134:   final int surahId;
135:   final int newAyahsPerDay;
136: }
137: 
138: class GenerateDailyPlanUsecase
139:     implements UseCase<DailyPlan, GenerateDailyPlanParams> {
140:   const GenerateDailyPlanUsecase(this._repository);
141:   final MemorizationPlusRepository _repository;
142: 
143:   @override
144:   Future<Either<Failure, DailyPlan>> call(GenerateDailyPlanParams params) =>
145:       _repository.generateDailyPlan(
146:         surahId: params.surahId,
147:         newAyahsPerDay: params.newAyahsPerDay,
148:       );
149: }
150: 
151: // ─── EvaluateMemorizationUsecase ──────────────────────────────────────────────
152: 
153: class EvaluateMemorizationParams {
154:   const EvaluateMemorizationParams({
155:     required this.surahId,
156:     required this.ayahNumber,
157:     required this.rating,
158:   });
159:   final int surahId;
160:   final int ayahNumber;
161:   final PerformanceRating rating;
162: }
163: 
164: class EvaluateMemorizationUsecase
165:     implements UseCase<AyahReviewRecord, EvaluateMemorizationParams> {
166:   const EvaluateMemorizationUsecase(this._repository);
167:   final MemorizationPlusRepository _repository;
168: 
169:   @override
170:   Future<Either<Failure, AyahReviewRecord>> call(
171:     EvaluateMemorizationParams params,
172:   ) => _repository.evaluateAyah(
173:     surahId: params.surahId,
174:     ayahNumber: params.ayahNumber,
175:     rating: params.rating,
176:   );
177: }
178: 
179: // ─── MarkAyahMemorizedUsecase ────────────────────────────────────────────────
180: 
181: class MarkAyahMemorizedParams {
182:   const MarkAyahMemorizedParams({
183:     required this.surahId,
184:     required this.ayahNumber,
185:   });
186:   final int surahId;
187:   final int ayahNumber;
188: }
189: 
190: class MarkAyahMemorizedUsecase
191:     implements UseCase<AyahReviewRecord, MarkAyahMemorizedParams> {
192:   const MarkAyahMemorizedUsecase(this._repository);
193:   final MemorizationPlusRepository _repository;
194: 
195:   @override
196:   Future<Either<Failure, AyahReviewRecord>> call(
197:     MarkAyahMemorizedParams params,
198:   ) => _repository.markAyahMemorized(
199:     surahId: params.surahId,
200:     ayahNumber: params.ayahNumber,
201:   );
202: }
203: 
204: // ─── ScheduleNextReviewUsecase ────────────────────────────────────────────────
205: 
206: /// Standalone scheduling logic — usable independently for testing.
207: class ScheduleNextReviewUsecase {
208:   const ScheduleNextReviewUsecase();
209: 
210:   AyahReviewRecord schedule(AyahReviewRecord record, PerformanceRating rating) {
211:     // UTC: all SM-2 scheduling dates must be UTC for cross-timezone consistency.
212:     final now = DateTime.now().toUtc();
213:     final int newStrength;
214:     final int newInterval;
215: 
216:     switch (rating) {
217:       case PerformanceRating.excellent:
218:         newStrength = (record.strengthLevel + 1).clamp(0, 10);
219:         // Aggressively space out: current interval * 2.5 (min 1 day)
220:         newInterval = record.strengthLevel == 0
221:             ? 1
222:             : (record.intervalDays * 2.5).round().clamp(1, 180);
223:       case PerformanceRating.average:
224:         newStrength = record.strengthLevel; // no change
225:         // Moderate spacing: current interval * 1.5
226:         newInterval = record.strengthLevel == 0
227:             ? 1
228:             : (record.intervalDays * 1.5).round().clamp(1, 90);
229:       case PerformanceRating.weak:
230:         newStrength = (record.strengthLevel - 1).clamp(0, 10);
231:         // Reset to 1 day — review tomorrow
232:         newInterval = 1;
233:     }
234: 
235:     return record.copyWith(
236:       strengthLevel: newStrength,
237:       intervalDays: newInterval,
238:       lastReviewedAt: now,
239:       nextReviewDate: now.add(Duration(days: newInterval)),
240:       totalReviews: record.totalReviews + 1,
241:       lastRating: rating,
242:     );
243:   }
244: }
245: 
246: // ─── GetKidsProgressUsecase ───────────────────────────────────────────────────
247: 
248: class GetKidsProgressUsecase implements UseCaseNoParams<KidsProgress> {
249:   const GetKidsProgressUsecase(this._repository);
250:   final MemorizationPlusRepository _repository;
251: 
252:   @override
253:   Future<Either<Failure, KidsProgress>> call() => _repository.getKidsProgress();
254: }
255: 
256: // ─── AwardKidsPointsUsecase ───────────────────────────────────────────────────
257: 
258: class AwardKidsPointsParams {
259:   const AwardKidsPointsParams({
260:     required this.surahId,
261:     required this.ayahNumber,
262:     required this.repeatsCompleted,
263:   });
264:   final int surahId;
265:   final int ayahNumber;
266:   final int repeatsCompleted;
267: }
268: 
269: class AwardKidsPointsUsecase
270:     implements UseCase<KidsProgress, AwardKidsPointsParams> {
271:   const AwardKidsPointsUsecase(this._repository);
272:   final MemorizationPlusRepository _repository;
273: 
274:   @override
275:   Future<Either<Failure, KidsProgress>> call(AwardKidsPointsParams params) =>
276:       _repository.awardKidsPoints(
277:         surahId: params.surahId,
278:         ayahNumber: params.ayahNumber,
279:         repeatsCompleted: params.repeatsCompleted,
280:       );
281: }
282: 
283: class GetKidsJourneyParams {
284:   const GetKidsJourneyParams({required this.surahId});
285:   final int surahId;
286: }
287: 
288: class GetKidsJourneyUsecase
289:     implements UseCase<List<KidsJourneyStage>, GetKidsJourneyParams> {
290:   const GetKidsJourneyUsecase(this._repository);
291:   final MemorizationPlusRepository _repository;
292: 
293:   @override
294:   Future<Either<Failure, List<KidsJourneyStage>>> call(
295:     GetKidsJourneyParams params,
296:   ) => _repository.getKidsJourney(surahId: params.surahId);
297: }
298: 
299: class SaveKidsSessionLogParams {
300:   const SaveKidsSessionLogParams({
301:     required this.surahId,
302:     required this.ayahNumber,
303:     required this.repeatsCompleted,
304:     required this.pointsEarned,
305:   });
306:   final int surahId;
307:   final int ayahNumber;
308:   final int repeatsCompleted;
309:   final int pointsEarned;
310: }
311: 
312: class SaveKidsSessionLogUsecase
313:     implements UseCase<KidsSessionLog, SaveKidsSessionLogParams> {
314:   const SaveKidsSessionLogUsecase(this._repository);
315:   final MemorizationPlusRepository _repository;
316: 
317:   @override
318:   Future<Either<Failure, KidsSessionLog>> call(
319:     SaveKidsSessionLogParams params,
320:   ) => _repository.saveKidsSessionLog(
321:     surahId: params.surahId,
322:     ayahNumber: params.ayahNumber,
323:     repeatsCompleted: params.repeatsCompleted,
324:     pointsEarned: params.pointsEarned,
325:   );
326: }
327: 
328: class GetParentDashboardParams {
329:   const GetParentDashboardParams({required this.surahId});
330:   final int surahId;
331: }
332: 
333: class GetParentDashboardUsecase
334:     implements UseCase<ParentDashboard, GetParentDashboardParams> {
335:   const GetParentDashboardUsecase(this._repository);
336:   final MemorizationPlusRepository _repository;
337: 
338:   @override
339:   Future<Either<Failure, ParentDashboard>> call(
340:     GetParentDashboardParams params,
341:   ) => _repository.getParentDashboard(surahId: params.surahId);
342: }
343: 
344: class ParentAccessUsecase {
345:   const ParentAccessUsecase(this._repository);
346:   final MemorizationPlusRepository _repository;
347: 
348:   Future<Either<Failure, ParentSettings>> getSettings() =>
349:       _repository.getParentSettings();
350: 
351:   Future<Either<Failure, void>> saveSettings(ParentSettings settings) =>
352:       _repository.saveParentSettings(settings);
353: 
354:   Future<Either<Failure, bool>> verifyPin(String pin) =>
355:       _repository.verifyParentPin(pin);
356: 
357:   Future<Either<Failure, void>> setPin(String pin) =>
358:       _repository.setParentPin(pin);
359: 
360:   Future<Either<Failure, void>> reset() => _repository.resetParentAccess();
361: 
362:   Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
363:     bool value,
364:   ) => _repository.setParentGuardianMode(value);
365: 
366:   Future<Either<Failure, List<ParentReward>>> saveReward(String title) =>
367:       _repository.saveParentReward(title);
368: 
369:   Future<Either<Failure, List<ParentReward>>> claimReward(String id) =>
370:       _repository.claimParentReward(id);
371: }
372: 
373: class ParentRemoteLinkUsecase {
374:   const ParentRemoteLinkUsecase(this._repository);
375:   final MemorizationPlusRepository _repository;
376: 
377:   Future<Either<Failure, String>> createChildLinkToken() =>
378:       _repository.createChildLinkToken();
379: 
380:   Future<Either<Failure, void>> acceptChildLinkToken(String token) =>
381:       _repository.acceptChildLinkToken(token);
382: 
383:   Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
384:     String token,
385:   ) => _repository.acceptGuardianPairingCode(token);
386: 
387:   Future<Either<Failure, void>> syncKidsProgressToCloud() =>
388:       _repository.syncKidsProgressToCloud();
389: 
390:   Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() =>
391:       _repository.getRemoteChildren();
392: 
393:   Future<Either<Failure, List<ParentReward>>> saveRemoteReward({
394:     required String childUserId,
395:     required String title,
396:   }) => _repository.saveRemoteParentReward(
397:     childUserId: childUserId,
398:     title: title,
399:   );
400: }
401: 
402: class GetCachedDailyPlanUsecase implements UseCaseNoParams<DailyPlan?> {
403:   const GetCachedDailyPlanUsecase(this._repository);
404:   final MemorizationPlusRepository _repository;
405: 
406:   @override
407:   Future<Either<Failure, DailyPlan?>> call() =>
408:       _repository.getCachedDailyPlan();
409: }
410: 
411: // ─── GetCustomPlanUsecase ─────────────────────────────────────────────────────
412: 
413: class GetCustomPlanUsecase implements UseCaseNoParams<CustomMemorizationPlan?> {
414:   const GetCustomPlanUsecase(this._repository);
415:   final MemorizationPlusRepository _repository;
416: 
417:   @override
418:   Future<Either<Failure, CustomMemorizationPlan?>> call() =>
419:       _repository.getCustomPlan();
420: }
421: 
422: // ─── SaveDailyPlanUsecase ─────────────────────────────────────────────────────
423: 
424: class SaveDailyPlanUsecase implements UseCase<void, DailyPlan> {
425:   const SaveDailyPlanUsecase(this._repository);
426:   final MemorizationPlusRepository _repository;
427: 
428:   @override
429:   Future<Either<Failure, void>> call(DailyPlan plan) =>
430:       _repository.saveDailyPlan(plan);
431: }

(End of file - total 431 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 12.8s)

_Thinking:_

I have enough context to do the audit now. Let me also briefly look at the progress page and the parent_dashboard_page to complete the picture.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\presentation\\pages\\progress_page.dart",
  "limit": 120
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\progress\presentation\pages\progress_page.dart</path>
<type>file</type>
<content>
1: import 'package:flutter/material.dart';
2: import 'package:flutter_bloc/flutter_bloc.dart';
3: import 'package:percent_indicator/percent_indicator.dart';
4: import 'package:share_plus/share_plus.dart';
5: 
6: import '../../../../core/constants/app_spacing.dart';
7: import '../../../../core/di/injection.dart';
8: import '../../../../core/extensions/context_extensions.dart';
9: import '../../../../core/l10n/localization_helpers.dart';
10: import '../../../../core/theme/app_colors.dart';
11: import '../../../../core/theme/app_typography.dart';
12: import '../../../../core/widgets/section_header.dart';
13: import '../../../../core/widgets/state_widgets.dart';
14: import '../../../../core/services/achievement_service.dart';
15: import '../../../settings/presentation/cubits/profile_cubit.dart';
16: import '../../domain/entities/progress_entities.dart';
17: import '../cubits/progress_cubit.dart';
18: import 'package:go_router/go_router.dart';
19: 
20: part '../widgets/progress_stat_cards.dart';
21: part '../widgets/progress_detailed_card.dart';
22: part '../widgets/progress_achievements.dart';
23: part '../widgets/progress_smart_memorization.dart';
24: part '../widgets/progress_certificates.dart';
25: 
26: class ProgressPage extends StatelessWidget {
27:   const ProgressPage({super.key});
28: 
29:   @override
30:   Widget build(BuildContext context) {
31:     return BlocProvider(
32:       create: (_) => getIt<ProgressCubit>()..load(),
33:       child: const _ProgressView(),
34:     );
35:   }
36: }
37: 
38: class _ProgressView extends StatelessWidget {
39:   const _ProgressView();
40: 
41:   @override
42:   Widget build(BuildContext context) {
43:     final isDark = context.isDark;
44: 
45:     return Scaffold(
46:       backgroundColor: isDark
47:           ? AppColors.darkBackground
48:           : AppColors.lightBackground,
49:       body: BlocBuilder<ProgressCubit, ProgressState>(
50:         builder: (context, state) {
51:           return CustomScrollView(
52:             slivers: [
53:               _buildAppBar(context, isDark, state),
54:               if (state is ProgressLoading)
55:                 const SliverFillRemaining(child: LoadingWidget()),
56:               if (state is ProgressError)
57:                 SliverFillRemaining(
58:                   child: ErrorStateWidget(
59:                     message: state.message,
60:                     onRetry: () => context.read<ProgressCubit>().load(),
61:                   ),
62:                 ),
63:               if (state is ProgressLoaded) ...[
64:                 SliverToBoxAdapter(
65:                   child: _ProgressContent(
66:                     progress: state.progress,
67:                     isDark: isDark,
68:                   ),
69:                 ),
70:               ],
71:             ],
72:           );
73:         },
74:       ),
75:     );
76:   }
77: 
78:   SliverAppBar _buildAppBar(
79:     BuildContext context,
80:     bool isDark,
81:     ProgressState state,
82:   ) {
83:     return SliverAppBar(
84:       expandedHeight: 140,
85:       pinned: true,
86:       backgroundColor: isDark
87:           ? AppColors.darkBackground
88:           : AppColors.lightBackground,
89:       elevation: 0,
90:       scrolledUnderElevation: 0,
91:       actions: [
92:         if (state is ProgressLoaded)
93:           IconButton(
94:             icon: const Icon(Icons.share_rounded, color: Colors.white),
95:             tooltip: context.l10n.shareProgress,
96:             onPressed: () {
97:               final profileState = context.read<ProfileCubit>().state;
98:               final hasName =
99:                   profileState is ProfileLoaded && profileState.profile.hasName;
100:               final text = hasName
101:                   ? context.l10n.shareProgressWithName(
102:                       state.progress.memorizedAyahs,
103:                       profileState.profile.displayName,
104:                       state.progress.readPagesCount,
105:                       state.progress.streakDays,
106:                     )
107:                   : context.l10n.shareProgressText(
108:                       state.progress.memorizedAyahs,
109:                       state.progress.readPagesCount,
110:                       state.progress.streakDays,
111:                     );
112:               SharePlus.instance.share(ShareParams(text: text));
113:             },
114:           ),
115:       ],
116:       flexibleSpace: FlexibleSpaceBar(
117:         collapseMode: CollapseMode.pin,
118:         background: Container(
119:           decoration: BoxDecoration(
120:             gradient: isDark

(Showing lines 1-120 of 402. Use offset=121 to continue.)
</content>
```

**Tool: grep**

**Input:**
```json
{
  "pattern": "selectedPath|isChild|isAdult|MemorizationPath|kids|adults",
  "path": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\presentation",
  "include": "*.dart"
}
```

**Output:**
```
Found 7 matches
D:\Sayed\Flutter\talia_quran\lib\features\progress\presentation\widgets\progress_smart_memorization.dart:
  Line 51:                   context.l10n.adultsTrack,

  Line 108:             if (progress.kidsPoints > 0) const Divider(height: 32),

  Line 112:           if (progress.kidsPoints > 0) ...[

  Line 129:                   context.l10n.kidsTrack,

  Line 143:                     value: '${progress.kidsPoints}',

  Line 153:                     value: '${progress.kidsStars}',


D:\Sayed\Flutter\talia_quran\lib\features\progress\presentation\pages\progress_page.dart:
  Line 339:                   p.kidsPoints > 0) ...[

```

---

## Assistant (Build · MiniMax M3 Free · 10.6s)

_Thinking:_

Now I have a comprehensive view. Let me look at the progress smart memorization widget to see if it differentiates between paths.

**Tool: read**

**Input:**
```json
{
  "filePath": "D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\progress\\presentation\\widgets\\progress_smart_memorization.dart"
}
```

**Output:**
```
<path>D:\Sayed\Flutter\talia_quran\lib\features\progress\presentation\widgets\progress_smart_memorization.dart</path>
<type>file</type>
<content>
1: part of '../pages/progress_page.dart';
2: 
3: class _SmartMemorizationCard extends StatelessWidget {
4:   const _SmartMemorizationCard({required this.progress, required this.isDark});
5:   final OverallProgress progress;
6:   final bool isDark;
7: 
8:   @override
9:   Widget build(BuildContext context) {
10:     final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
11:     final primary = isDark ? AppColors.primaryLight : AppColors.primary;
12:     final textPrimary = isDark
13:         ? AppColors.darkTextPrimary
14:         : AppColors.lightTextPrimary;
15: 
16:     return Container(
17:       margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
18:       padding: const EdgeInsets.all(AppSpacing.lg),
19:       decoration: BoxDecoration(
20:         color: surface,
21:         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
22:         boxShadow: [
23:           BoxShadow(
24:             color: primary.withValues(alpha: 0.05),
25:             blurRadius: 10,
26:             offset: const Offset(0, 4),
27:           ),
28:         ],
29:       ),
30:       child: Column(
31:         children: [
32:           // Adult Track Stats
33:           if (progress.smartMemorizedAyahs > 0 ||
34:               progress.smartReviewAyahs > 0) ...[
35:             Row(
36:               children: [
37:                 Container(
38:                   padding: const EdgeInsets.all(10),
39:                   decoration: BoxDecoration(
40:                     color: primary.withValues(alpha: 0.1),
41:                     shape: BoxShape.circle,
42:                   ),
43:                   child: Icon(
44:                     Icons.psychology_rounded,
45:                     color: primary,
46:                     size: 24,
47:                   ),
48:                 ),
49:                 const SizedBox(width: AppSpacing.md),
50:                 Text(
51:                   context.l10n.adultsTrack,
52:                   style: AppTypography.titleMedium.copyWith(
53:                     color: textPrimary,
54:                     fontWeight: FontWeight.bold,
55:                   ),
56:                 ),
57:               ],
58:             ),
59:             const SizedBox(height: AppSpacing.md),
60:             Row(
61:               children: [
62:                 Expanded(
63:                   child: _ProgressBarRow(
64:                     row: _DetailRow(
65:                       label: context.l10n.memorizedTerm,
66:                       current: progress.smartMemorizedAyahs,
67:                       total: 6236,
68:                       color: const Color(0xFF2D8E4C),
69:                     ),
70:                     isDark: isDark,
71:                   ),
72:                 ),
73:                 const SizedBox(width: AppSpacing.lg),
74:                 Expanded(
75:                   child: Container(
76:                     padding: const EdgeInsets.symmetric(
77:                       vertical: AppSpacing.sm,
78:                       horizontal: AppSpacing.md,
79:                     ),
80:                     decoration: BoxDecoration(
81:                       color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
82:                       borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
83:                     ),
84:                     child: Row(
85:                       mainAxisAlignment: MainAxisAlignment.center,
86:                       children: [
87:                         Text(
88:                           context.l10n.reviewingPrefix,
89:                           style: AppTypography.labelSmall.copyWith(
90:                             color: isDark
91:                                 ? AppColors.darkTextSecondary
92:                                 : AppColors.lightTextSecondary,
93:                           ),
94:                         ),
95:                         Text(
96:                           '${progress.smartReviewAyahs}',
97:                           style: AppTypography.labelMedium.copyWith(
98:                             color: const Color(0xFFFF8C42),
99:                             fontWeight: FontWeight.w700,
100:                           ),
101:                         ),
102:                       ],
103:                     ),
104:                   ),
105:                 ),
106:               ],
107:             ),
108:             if (progress.kidsPoints > 0) const Divider(height: 32),
109:           ],
110: 
111:           // Kids Track Stats
112:           if (progress.kidsPoints > 0) ...[
113:             Row(
114:               children: [
115:                 Container(
116:                   padding: const EdgeInsets.all(10),
117:                   decoration: BoxDecoration(
118:                     color: AppColors.gold.withValues(alpha: 0.1),
119:                     shape: BoxShape.circle,
120:                   ),
121:                   child: const Icon(
122:                     Icons.star_rounded,
123:                     color: AppColors.gold,
124:                     size: 24,
125:                   ),
126:                 ),
127:                 const SizedBox(width: AppSpacing.md),
128:                 Text(
129:                   context.l10n.kidsTrack,
130:                   style: AppTypography.titleMedium.copyWith(
131:                     color: textPrimary,
132:                     fontWeight: FontWeight.bold,
133:                   ),
134:                 ),
135:               ],
136:             ),
137:             const SizedBox(height: AppSpacing.md),
138:             Row(
139:               children: [
140:                 Expanded(
141:                   child: _StatBox(
142:                     label: context.l10n.points,
143:                     value: '${progress.kidsPoints}',
144:                     icon: Icons.military_tech_rounded,
145:                     color: AppColors.primary,
146:                     isDark: isDark,
147:                   ),
148:                 ),
149:                 const SizedBox(width: AppSpacing.md),
150:                 Expanded(
151:                   child: _StatBox(
152:                     label: context.l10n.stars,
153:                     value: '${progress.kidsStars}',
154:                     icon: Icons.star_rounded,
155:                     color: AppColors.gold,
156:                     isDark: isDark,
157:                   ),
158:                 ),
159:               ],
160:             ),
161:           ],
162:         ],
163:       ),
164:     );
165:   }
166: }
167: 
168: class _StatBox extends StatelessWidget {
169:   const _StatBox({
170:     required this.label,
171:     required this.value,
172:     required this.icon,
173:     required this.color,
174:     required this.isDark,
175:   });
176:   final String label;
177:   final String value;
178:   final IconData icon;
179:   final Color color;
180:   final bool isDark;
181: 
182:   @override
183:   Widget build(BuildContext context) {
184:     return Container(
185:       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
186:       decoration: BoxDecoration(
187:         color: color.withValues(alpha: 0.08),
188:         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
189:       ),
190:       child: Column(
191:         children: [
192:           Icon(icon, color: color, size: 28),
193:           const SizedBox(height: 4),
194:           Text(
195:             value,
196:             style: AppTypography.titleLarge.copyWith(
197:               color: color,
198:               fontWeight: FontWeight.bold,
199:             ),
200:           ),
201:           Text(
202:             label,
203:             style: AppTypography.labelSmall.copyWith(
204:               color: isDark
205:                   ? AppColors.darkTextSecondary
206:                   : AppColors.lightTextSecondary,
207:             ),
208:           ),
209:         ],
210:       ),
211:     );
212:   }
213: }
214: 
215: // ─── Certificates Section ─────────────────────────────────────────────────────

(End of file - total 215 lines)
</content>
```

---

## Assistant (Build · MiniMax M3 Free · 13.1s)

_Thinking:_

Now I have a complete picture of the system. Let me update the todo list and produce the comprehensive audit report. Let me first finish exploring the home test to confirm understanding.

**Tool: bash**

**Input:**
```json
{
  "command": "Get-ChildItem -LiteralPath \"D:\\Sayed\\Flutter\\talia_quran\\lib\\features\\memorization_plus\\data\\models\" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name",
  "description": "List memorization models"
}
```

**Output:**
```
isar_ayah_review_record.dart
isar_ayah_review_record.g.dart
memorization_models.dart

```

**Tool: bash**

**Input:**
```json
{
  "command": "Get-ChildItem -LiteralPath \"D:\\Sayed\\Flutter\\talia_quran\\test\" -Recurse -Filter \"*.dart\" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName",
  "description": "List test files"
}
```

**Output:**
```
D:\Sayed\Flutter\talia_quran\test\widget_test.dart
D:\Sayed\Flutter\talia_quran\test\core\services\achievement_service_test.dart
D:\Sayed\Flutter\talia_quran\test\core\services\app_session_service_test.dart
D:\Sayed\Flutter\talia_quran\test\core\services\quran_audio_service_test.dart
D:\Sayed\Flutter\talia_quran\test\core\services\streak_service_test.dart
D:\Sayed\Flutter\talia_quran\test\core\services\xp_service_test.dart
D:\Sayed\Flutter\talia_quran\test\core\utils\arabic_normalizer_test.dart
D:\Sayed\Flutter\talia_quran\test\core\utils\quran_text_display_formatter_test.dart
D:\Sayed\Flutter\talia_quran\test\core\widgets\qcf_hifz_verse_view_test.dart
D:\Sayed\Flutter\talia_quran\test\features\auth\auth_cubit_lifecycle_test.dart
D:\Sayed\Flutter\talia_quran\test\features\auth\auth_cubit_lifecycle_test.mocks.dart
D:\Sayed\Flutter\talia_quran\test\features\auth\data\repositories\auth_repository_sync_test.dart
D:\Sayed\Flutter\talia_quran\test\features\auth\presentation\cubits\auth_cubit_test.dart
D:\Sayed\Flutter\talia_quran\test\features\auth\presentation\cubits\auth_cubit_test.mocks.dart
D:\Sayed\Flutter\talia_quran\test\features\hifz\ayah_progress_model_test.dart
D:\Sayed\Flutter\talia_quran\test\features\hifz\hifz_local_datasource_test.dart
D:\Sayed\Flutter\talia_quran\test\features\hifz\hifz_segments_test.dart
D:\Sayed\Flutter\talia_quran\test\features\hifz\hifz_unlock_rules_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\memorization_entities_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\memorization_plus_local_datasource_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\memorization_plus_repository_impl_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\schedule_next_review_usecase_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\cubits\guardian_linking_cubit_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\cubits\guardian_linking_cubit_test.mocks.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\cubits\memorization_identity_cubit_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\cubits\quiz_cubit_manual_rating_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_completion_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_home_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_journey_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_listen_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_rtl_narrow_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\kids_gamified_stage_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\pages\qcf_rendering_poc_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\memorization_plus\presentation\widgets\kids_house_card_test.dart
D:\Sayed\Flutter\talia_quran\test\features\progress\progress_local_datasource_test.dart
D:\Sayed\Flutter\talia_quran\test\features\progress\progress_repository_impl_test.dart
D:\Sayed\Flutter\talia_quran\test\features\quran\bookmark_service_test.dart
D:\Sayed\Flutter\talia_quran\test\features\quran\quran_repository_impl_test.dart
D:\Sayed\Flutter\talia_quran\test\features\settings\privacy_policy_page_test.dart
D:\Sayed\Flutter\talia_quran\test\features\settings\profile_cubit_test.dart

```

---

## Assistant (Build · MiniMax M3 Free · 17.3s)

_Thinking:_

Now I have a comprehensive understanding. Let me finalize the audit and produce the report. Let me update the todo list and complete the audit.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Explore project structure and architecture",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Identify all memorization screens/widgets",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Identify all Cubits/Bloc/providers related to memorization",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Identify repositories/services/storage keys",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Map all routes/navigation entry points",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Identify conflicts/duplications and risk levels",
      "status": "completed",
      "priority": "high"
    },
    {
      "content": "Produce safe fix plan and present for approval",
      "status": "in_progress",
      "priority": "high"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Explore project structure and architecture",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Identify all memorization screens/widgets",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Identify all Cubits/Bloc/providers related to memorization",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Identify repositories/services/storage keys",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Map all routes/navigation entry points",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Identify conflicts/duplications and risk levels",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Produce safe fix plan and present for approval",
    "status": "in_progress",
    "priority": "high"
  }
]
```

---

## Assistant (Build · MiniMax M3 Free · 254.2s)

Audit complete. **No code changes yet** as requested.

---

# Memorization System Audit — Talia Quran

## 1. Current Architecture Summary

Two memorization systems coexist in a single app, each with its own data model:

| System | Entry / Page | Storage | Cubit | Path-aware? |
|---|---|---|---|---|
| **Basic (legacy)** | `HifzPage` → `HifzSessionPage` (full-surah listen/record) | Isar `IsarAyahProgress` + `kHifzPathMode` (`forward`/`backward`) | `HifzCubit`, `HifzSessionCubit` | Partial (hifz-path only, not Kids/Adult identity) |
| **Smart (Adult)** | `/memorization-plus/daily-plan` → quiz | `mem_plus_review_*` (Isar `IsarAyahReviewRecord`) + `mem_plus_daily_plan` + `mem_plus_custom_plan` | `DailyPlanCubit`, `QuizCubit` | Reads `MemorizationProfile`, but UI is always adult-styled |
| **Kids Gamified** | `/memorization-plus/kids-home` → `kids-journey` → `kids` (listen) → `kids-completion` | `mem_plus_kids_progress` + `mem_plus_kids_session_logs` | `KidsJourneyCubit`, `KidsModeCubit` | Hard-isolated (route guard rejects adult profile) |
| **Identity** | `PathSelectionPage`, `GuardianLinkingPage`, `memorization_path_settings_sheet` | `mem_plus_profile` + `mem_plus_track` + `kHifzPathMode` + `mem_plus_is_parent_mode` | `MemorizationIdentityCubit`, `TrackSelectionCubit` | Single source for the path |

The router has decent guards (kids-routes redirect non-kids, hifz-session redirects kids to kids-listen, daily-plan/custom-plan redirect kids to kids-home). However, several UI surfaces and the home screen itself are still mixing/bypassing the path.

---

## 2. Memorization Screens & Widgets

- **lib/features/hifz/presentation/pages/hifz_page.dart** — Surah list, locked/unlocked, `_ProgressOverviewCard` (uses total `memorizedCount` across all paths). Banner pushes `/memorization-plus`.
- **lib/features/hifz/presentation/pages/hifz_session_page.dart** — Listen / record / checkpoint review (Basic flow).
- **lib/features/memorization_plus/presentation/pages/path_selection_page.dart** — Identity gate.
- **lib/features/memorization_plus/presentation/pages/daily_plan_page.dart** — Adult daily-plan Smart flow.
- **lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart** — Adult custom plan editor.
- **lib/features/memorization_plus/presentation/pages/quiz_page.dart** — Smart-quiz.
- **lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart** — Kids hub.
- **lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart** — Kids map of stages.
- **lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart** — Kids stage detail.
- **lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart** — Kids listen/record.
- **lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart** — Kids reward.
- **lib/features/memorization_plus/presentation/pages/parent_dashboard_page.dart** — Parent view (uses KidsProgress only).
- **lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart** — "Reset/Change path" sheet (called from Hifz and Kids-Home).
- **lib/features/home/presentation/pages/home_page.dart** + **home_page_widgets.dart** — `_NextBestActionCard`, `_ActiveCustomPlanCard`, `_MemorizationPlusCard`, `_ParentDashboardShortcutCard`, `_ResumeSessionCard`, `_DailyWirdCard`, `_ProgressSection`.

---

## 3. Cubits / Bloc Related to Memorization

| Cubit | Source of truth read | Notes |
|---|---|---|
| `HifzCubit` | `MemorizationProfile` (hifz-path) + legacy `kHifzPathMode` | Calls `selectMemorizationPath` after `savePath` → keeps both stores in sync (good) |
| `HifzSessionCubit` | `HifzRepository` (Isar) | No path awareness — same UI for adult & (if reached) kids |
| `DailyPlanCubit` | `MemorizationPlusRepository` (review records + plan) | Always adult UI |
| `KidsJourneyCubit` | `MemorizationPlusRepository` (KidsSessionLogs) | UI is hard-coded kids |
| `KidsModeCubit` | Same | Records via `awardKidsPoints` + `markAyahMemorized` + `saveKidsSessionLog` |
| `MemorizationIdentityCubit` | `MemorizationPlusRepository` | Authoritative path store |
| `TrackSelectionCubit` | Same | Reads `getMemorizationProfile`, emits `TrackSelection*` states |
| `HomeCubit` | `MemorizationPlusRepository` (`getSelectedTrack`, `getIsParentMode`) **synchronously** | See Issue H-2 — only sync getters; misses async profile state |
| `ParentDashboardCubit` | `MemorizationPlusRepository` | Kids-only data |

---

## 4. Repositories / Services / Storage Keys

**Storage (SharedPreferences)** — all under `MemorizationPlusLocalDatasource` unless noted:

| Key | Source | Purpose | Path-aware? |
|---|---|---|---|
| `mem_plus_profile` | `MemorizationProfileModel` | **Authoritative path store** (`MemorizationPath.adult` / `.child`) | Yes |
| `mem_plus_track` | legacy `MemorizationTrack.adults`/`.kids` | Mirrors profile.legacyTrack — **duplicate of profile.selectedPath** | Yes |
| `mem_plus_is_parent_mode` | bool | Mirrors `profile.isParentGuardian` — **duplicate** | Yes |
| `hifz_path_mode` (`AppConstants.kHifzPathMode`) | string `'forward'`/`'backward'` | Maps to path via `profile.hifzPathValue` — **3rd copy** | Yes |
| `mem_plus_review_*` / `IsarAyahReviewRecord` | per-ayah SM-2 | Adult Smart memorization progress | Path-independent today, **but mixed with Kids (see Issue P-1)** |
| `mem_plus_daily_plan` | `DailyPlanModel` | Adult daily plan cache | No |
| `mem_plus_custom_plan` | `CustomMemorizationPlanModel` | Adult custom plan | No |
| `mem_plus_kids_progress` | `KidsProgressModel` | Kids gamified progress | No |
| `mem_plus_kids_session_logs` | list of `KidsSessionLogModel` | Source for `KidsJourneyStage.completedAyahs` | No |
| `mem_plus_parent_settings`, `mem_plus_parent_rewards` | parent/guardian | Parent dashboard | No |
| `mem_plus_smart_settings` | `SmartMemorizationSettingsModel` | Carries `customPlan` (duplicated with `mem_plus_custom_plan`) | No |
| `kHifzProgress*` (Isar) | `IsarAyahProgress` | Basic hifz progress per ayah | No |
| `hifz_checkpoint_progress_*` | string list | Passed-checkpoint keys per surah | No |
| `kStreakCount`, `kLastActiveDate`, `kReadPages` | `ProgressLocalDatasource` | Shared by all paths | No |
| `sign_in_nudge_dismissed`, `first_action_completed`, `user_primary_goal` | UI prefs | Used by home `_NextBestActionCard` | No |

**Services:** `AudioCacheService`, `QuranAudioService`, `StreakService`, `XpService`, `AchievementService`, `HapticService`, `AppSessionService` (last restorable location).

**Quran / Hifz repositories:** `QuranRepository`, `HifzRepository` (uses `IsarHifzLocalDatasourceImpl`), `MemorizationPlusRepository`, `ProgressRepository` (aggregates Hifz + Mem+ + Quran + Progress).

---

## 5. Routes & Navigation Entry Points (memorization)

App router: `lib/core/router/app_router.dart`. Path-aware redirects already present:

- `/memorization-plus` → if `profile.isAdult` and no `CustomMemorizationPlan` → `/memorization-plus/custom-plan`; if `profile.isChild` → `/memorization-plus/kids-home`. Otherwise shows `PathSelectionPage`.
- `/memorization-plus/guardian-linking` → guard: only for child with `required` onboarding.
- `/memorization-plus/daily-plan` and `/memorization-plus/custom-plan` → redirect kids to `kids-home`.
- `/memorization-plus/kids-*` → redirect non-kids to `/memorization-plus`.
- `/hifz/session` → if `profile.isChild`, redirect to `kids` listen page.
- `/hifz` (shell) → if `profile.isChild` → redirect to `kids-home`; else show `HifzPage`.
- Home screen `_NextBestActionCard` / `_ActiveCustomPlanCard` / `_MemorizationPlusCard` all hard-code routes and do **not** read the selected path (see Issue H-1).
- `Bottom-nav Hifz tab` is shell-scoped (`StatefulShellBranch`) — the `HifzPage` rebuilds each visit and reads `HifzCubit` afresh, but `BlocProvider(create: …load())` is recreated per visit, so the path gate runs each time (good).

---

## 6. Identified Conflicts / Duplications

| ID | Issue | Evidence | Risk |
|---|---|---|---|
| **C-1** | **Three parallel "selected path" stores** (`mem_plus_profile.selectedPath`, `mem_plus_track`, `hifz_path_mode`) | `MemorizationProfile.hifzPathValue` returns `'backward'/'forward'`; `_loadProfile` migrates from legacy; `selectMemorizationPath` writes to all three | **Medium** — silent drift if one is missed; `HomeCubit` only reads the legacy `getSelectedTrack` synchronously |
| **C-2** | **Two parallel "is parent" stores** (`mem_plus_is_parent_mode` ↔ `profile.isParentGuardian`) | `setParentGuardianMode` writes both; `getIsParentMode` reads raw pref | **Low** — both written atomically, but two keys to maintain |
| **H-1** | **Home screen never reads the selected path** — `_NextBestActionCard`, `_MemorizationPlusCard`, `_ActiveCustomPlanCard`, `_ParentDashboardShortcutCard` all hard-code behaviour. After switching Kids↔Adult, home still shows adult-styled smart-memorization card, while hifz-tab now goes to kids-home (split-brain). | `home_page.dart:230, 234, 235, 832-895, 1175-1255`, `home_page_widgets.dart:1815-1854` | **High** — directly violates requirements 1, 2, 3, 4, 8 |
| **H-2** | `HomeCubit` uses **sync** `getSelectedTrack()` & `getIsParentMode()`; never reads the authoritative `MemorizationProfile` async | `home_cubit.dart:69-77` | **High** — relies on legacy data being in sync; if migration hasn't run or one store lags, home shows wrong card |
| **H-3** | Home progress section shows combined `memorizedAyahs/totalAyahs` (6236) for **everyone**, mixing Basic + Smart + Kids | `progress_repository_impl.dart:30-90`, `_ProgressSection` | **Medium** — Kids users see "0/6236 آية" even if they have points |
| **H-4** | `_NextBestActionCard` `action()` uses `customPlan != null` to decide "memorization" card; for kids it would still show the same `psychology_alt` icon (adult visual) and route to `/memorization-plus` (which the route then redirects to kids-home — but the label copy is adult-styled) | `home_page_widgets.dart:1815-1854` | **Medium** |
| **H-5** | `_ResumeSessionCard` describes `/hifz/session` as "incomplete Hifz session" even for kids, who don't have hifz sessions | `home_page_widgets.dart:1728-1733` | **Low** |
| **S-1** | `HifzCubit.selectPath` writes both `kHifzPathMode` and `selectMemorizationPath(adult/child)` — **double source-of-truth write**. | `hifz_cubit.dart:65-95` | **Medium** — could go out of sync if `selectMemorizationPath` fails after `savePath` |
| **S-2** | `HifzSessionCubit._validateSurahAccess` reads legacy `kHifzPathMode` and rebuilds unlock map, while the router guard already enforces kids → kids-listen. No direct conflict but it duplicates the same `unlockSurahIds` logic that `HifzCubit` does (DRY violation). | `hifz_session_cubit.dart:268-299`, `hifz_unlock_rules.dart:17-36` | **Low** |
| **U-1** | **`/memorization-plus` Smart memorization does NOT swap UI to Kids**. It always renders the adult `DailyPlanPage`. Route guards push kids to kids-home, but `PathSelectionPage`'s listener also pushes **child** to `guardian-linking` (fine) and **adult** to `custom-plan`. The path itself works, but the daily-plan page is never reachable for kids (good), and there's no shared "memorize screen" — kids always go through kids-home. This actually satisfies the requirement "smart memorization follows selected path" because **for kids the entry point IS the kids UI**. However: there is **no path-aware guard on the Smart memory entry** coming from the home `_MemorizationPlusCard` — the router's `redirect` on `/memorization-plus` only fires if `hasSelectedPath`. A new user with no profile lands on `PathSelectionPage` (good). | `app_router.dart:274-309`, `path_selection_page.dart:36-46` | **Low** (relies on redirect) |
| **U-2** | **Basic memorization** (`HifzPage` → `HifzSessionPage`) renders identical adult UI for adults AND for kids if kids-tab gets there. But the router **prevents** that via `HifzSessionPage` redirect to kids-listen. So Basic is "isolated" only by route guards, not by page logic. | `app_router.dart:215-247`, `hifz_session_page.dart:1-120` | **Medium** — adding a new entry to HifzSession would bypass the guard |
| **P-1** | **Progress duplication / cross-contamination**: `OverallProgress.memorizedAyahs` is counted from `IsarAyahProgress` (Basic only). `smartMemorizedAyahs` is from `AyahReviewRecord.strengthLevel >= 6` (Smart). `kidsPoints` from `KidsProgress`. They are three disjoint universes. Kids completed ayahs never increase `memorizedAyahs` (correct intent), but `OverallProgress` aggregates none of them as a "kids" ayah count, and a kids user with `kidsPoints>0` but no hifz records sees a "Hifz: 0 / 6236 آية" card on home (`_ProgressSection`). | `progress_repository_impl.dart:144-178`, `home_page_widgets.dart:540-575` | **High** — kids see misleading empty progress |
| **P-2** | `HifzCubit.selectPath` saves the hifz path but emits a `HifzLoaded` state with the new path; `HifzPage` doesn't refresh `profile` state for siblings (e.g. `HomeCubit` won't know the path changed). After selecting Kids path on `HifzPage`, user must go back to home to see the new `MemorizationPlusCard` / `ParentDashboardShortcutCard` decision. | `hifz_cubit.dart:65-97` | **Medium** |
| **P-3** | `DailyPlanCubit.evaluateAyah` increments streak & XP only on rating ≥ average. `HifzSessionCubit._evaluateRecitation` does the same. `KidsModeCubit.markCompleted` does the same. This is **correct** (not the issue) but three places need to stay aligned if behaviour changes. | `daily_plan_cubit.dart:119-126`, `hifz_session_cubit.dart:487-503`, `kids_mode_cubit.dart:222-228` | **Low** |
| **P-4** | `markAyahMemorized` writes to the same `AyahReviewRecord` (per-ayah) for both Smart **and** Kids — Kids calls it via `KidsModeCubit.markCompleted`, Smart via `DailyPlanCubit.evaluateAyah(excellent/average)`. The two paths share the record store but use different Cubits and different evaluation methods. There is **no collision** today because Kids only runs when the profile is child and adult Smart only runs when adult, but the data model has no path tag. | `kids_mode_cubit.dart:213-220`, `daily_plan_cubit.dart:100-117`, `memorization_plus_repository_impl.dart:615-645` | **Low** (correct behaviour today) |
| **P-5** | **"Open a memorization screen without completing anything" should not increase progress** — verified: `HifzSessionCubit._evaluateRecitation` only writes on `pass=true`; `KidsModeCubit.markCompleted` requires `_loopCount >= _maxLoops`; `DailyPlanCubit.evaluateAyah` only updates `plan.withCompleted(...)` for `rating != weak`. Scenario I passes for all three. | `hifz_session_cubit.dart:411-505`, `kids_mode_cubit.dart:186-197`, `daily_plan_cubit.dart:84-117` | **None** |
| **P-6** | `HifzCubit.selectPath` calls `selectMemorizationPath(adult)` for `'forward'` and `selectMemorizationPath(child)` for `'backward'`. So **selecting "backward" hifz = Kids path**. This is the path-binding; correct, but the dependency is non-obvious and could be re-interpreted wrong. | `hifz_cubit.dart:91-95` | **Low** |
| **R-1** | `MemorizationPlusRepository._loadProfile` migrates from legacy `mem_plus_track` AND `kHifzPathMode` if the new profile has no path. After migration it `_saveProfile` (writes back). This is **safe** (idempotent), but if `mem_plus_track` is `'kids'` and `kHifzPathMode` is `'forward'` (e.g. legacy data collision), the migration picks `mem_plus_track` first → Kids. The migration order matters but is currently only the order in the if-chain. | `memorization_plus_repository_impl.dart:320-355` | **Low** |
| **R-2** | `_loadProfile` is called inside an `async` Supabase-free path but `_saveProfile` writes a UTC `updatedAt`. The new profile is then returned but the `getMemorizationProfile()` caller doesn't always refresh. The router's redirect for `/memorization-plus` does, but `HifzCubit.load()` and `HomeCubit.load()` use the result synchronously after a `fold`. | `hifz_cubit.dart:34-40` | **Low** |
| **R-3** | **No `MemorizationPathRouterScreen`**. The audit doc requires a single central router. Today the routing decisions are spread across `app_router.dart` redirect callbacks (`_redirectKidsPathToKidsHome`, `_redirectNonKidsPathToMemorization`, `_isKidsPathSelected`) — these are well-factored, but no wrapper widget is reused. | `app_router.dart:599-624` | **Medium** — requirement #6 |
| **R-4** | `_redirectKidsPathToKidsHome` and `_redirectNonKidsPathToMemorization` are duplicated logic in 3+ routes. If a new memorization route is added, devs must remember to add the redirect. | `app_router.dart:345, 361, 377, 403, 419, 434, 480` | **Medium** |
| **R-5** | Hifz path is read in **two** places (router redirect for `/hifz`, `HifzSessionCubit._validateSurahAccess`) — both call the same `MemorizationPlusRepository.getMemorizationProfile` then `HifzRepository.getHifzPath`. The legacy `kHifzPathMode` may also be checked (HifzCubit does). | `app_router.dart:534-555`, `hifz_session_cubit.dart:269-271` | **Low** |
| **R-6** | Hifz tab (`StatefulShellBranch`) uses a `redirect` to gate by path. When the user **switches** from Kids back to Adult via the path settings sheet, the bottom-nav `Hifz` tab still sits at `HifzPage`'s Navigator stack. If the user navigated deep (e.g. to a kid stage page within a different stateful branch) and re-enters `Hifz` tab, the gate runs again. This is **correct**, but switching path while a deep Hifz stack is alive leaves the stale UI. | `app_router.dart:530-560` | **Low** |
| **D-1** | **No tests covering the kids/adult path-separation** for the home, daily-plan, kids, and hifz-session flow. Existing tests cover entities, repos, segments, and isolated widgets. | `test/features/...` | **Medium** — Scenario A–J cannot be regression-guarded |

---

## 7. Risk Roll-up

| Severity | Count | IDs |
|---|---|---|
| **High** | 3 | H-1, H-2, P-1 |
| **Medium** | 8 | C-1, H-3, H-4, P-2, R-3, R-4, S-1, U-2, D-1 |
| **Low** | 9 | C-2, H-5, P-3, P-4, P-6, R-1, R-2, R-5, R-6, S-2 |

---

## 8. Safe Fix Plan (no code changes yet — awaiting your go)

Ordered by risk-to-fix ratio. Every change keeps the same storage keys, never deletes a key, never touches Quran source files, and never resets user progress.

### Phase 0 — Single source of truth for the path (≤ 1 day)
1. Introduce a `MemorizationPathResolver` helper (`lib/core/memorization/memorization_path_resolver.dart`) that exposes:
   - `Future<MemorizationProfile> currentProfile()`
   - `bool isKids(MemorizationProfile)` / `bool isAdult(...)`
   - `Stream<void> changes` driven by an in-app `ValueNotifier` that is set whenever any cubit calls `selectMemorizationPath` / `resetMemorizationIdentity` / `setIsParentMode` / `saveHifzPath`.
2. Wire the cubits that mutate the path (`HifzCubit`, `MemorizationIdentityCubit`, `TrackSelectionCubit`, `MemorizationPathSettingsSheet`) to call `MemorizationPathResolver.instance.notifyChanged()` after a successful save.
3. Keep all three existing storage keys as writes (do not rename, do not delete). The helper just **adds a layer of observation** without changing persistence.

### Phase 1 — Home screen follows the selected path (≤ 1 day, low risk)
4. In `HomeCubit`, replace the two sync `getSelectedTrack()` / `getIsParentMode()` calls with a single `await _memorizationRepository.getMemorizationProfile()`. Derive both flags from the profile (`profile.legacyTrack`, `profile.isParentGuardian`). Existing `HomeLoaded` field types are unchanged.
5. In `_HomeContent`, branch the visible cards on `state.selectedTrack == MemorizationTrack.kids`:
   - When **kids**: hide `_MemorizationPlusCard` (adult smart entry), show a `_KidsHubCard` that opens `/memorization-plus/kids-home`. Hide `_ActiveCustomPlanCard` (it can never be non-null for kids — `getCustomPlan` is Adult-only — but defend against it). Show `_ParentDashboardShortcutCard` always for kids.
   - When **adult**: keep current behaviour.
6. In `_NextBestActionCard._action()`, when `state.selectedTrack == MemorizationTrack.kids`:
   - Replace the `psychology_alt` card with a kids-friendly copy and route to `/memorization-plus/kids-home`.
   - If `state.dailyWirdPageDetail != null` for a kids user, keep the reading card (Quran is path-independent).
7. In `_ProgressSection`, when kids: show a single "Kids Points" stat (already on `progress.kidsPoints`) and hide the "Hifz" mini-card (it will always read 0/6236 for kids). When adult: show as today.
8. In `_ResumeSessionCard._description`, when `uri.path == '/hifz/session'` and profile is kids, show the kids-session localized text instead of "incomplete Hifz session".
9. In `_StartHereStrip` "ابدأ الحفظ" chip, route kids to `/memorization-plus/kids-home` and adults to `/memorization-plus`.
10. Subscribe `HomeCubit` to `MemorizationPathResolver.changes` and call `load()` on change. This satisfies Scenario E and F (path switch immediately updates home).

### Phase 2 — Memoize the path decision in one helper used by the router (≤ 0.5 day, low risk)
11. Create `lib/core/router/memorization_path_router.dart` with `MemorizationPathRouterScreen` — a thin `StatelessWidget` that reads `MemorizationProfile` once and returns `KidsGamifiedHomeContent` for kids, `DailyPlanPage` (or `PathSelectionPage` if no path) for adults. Mark it as the **single source for "where to go from a memorization entry"**.
12. Update `app_router.dart` redirect helpers to delegate to the new screen where possible; keep all existing redirect callbacks working (do not break public behaviour). Add a unit test that exercises all redirects with each profile state.

### Phase 3 — Make Smart memorization route to the right UI by selected path (≤ 0.5 day)
13. The `/memorization-plus` route already redirects kids to kids-home — verify by widget test (Scenario B & C). If the redirect ever returns `null` because profile is null, render `MemorizationPathRouterScreen` as the page instead of `PathSelectionPage`. This guarantees UI-by-path, not entry-by-entry.
14. In `DailyPlanPage`, refuse to load if the profile is a child (defensive guard in the cubit). Currently unreachable thanks to router, but this is the explicit "Smart UI depends on path, not entry" safety net.

### Phase 4 — Basic memorization isolation (≤ 0.5 day)
15. `HifzSessionCubit` already validates surah unlock; add an early `isChild` check that returns the same message kids see from the listen page (so any direct deep-link with a kids profile fails gracefully instead of showing adult UI).
16. Keep `HifzPage` showing the `MemPlusBanner` only when the profile is adult (the banner is adult-styled).

### Phase 5 — De-duplicate stores (low priority, opt-in for this release)
17. Mark `mem_plus_track` and `mem_plus_is_parent_mode` as legacy keys (write-only) in code comments; leave them in place (do **not** delete) to preserve compatibility with installed apps. The new `MemorizationProfile` remains the only authoritative store.
18. Mark `mem_plus_smart_settings.customPlan` as derived from `mem_plus_custom_plan`; `getSmartSettings` already falls back to `getCustomPlan`, which is the correct behaviour.

### Phase 6 — Tests for Scenarios A–J
19. Add widget tests for `HomePage` with stubbed `MemorizationProfile` covering:
    - Scenario A: adult, daily plan card shown
    - Scenario B: kids, kids hub card shown; mem-plus card hidden
    - Scenario E/F: profile change → `HomeCubit.load()` called again; home rebuilds
20. Add widget tests for `MemorizationPathRouterScreen` covering both paths.
21. Add a regression test that asserts `HifzSessionPage` cannot be reached by a kids profile even with a manual deep link (router redirect test).
22. Add a test that `HifzSessionCubit._evaluateRecitation` and `DailyPlanCubit.evaluateAyah` do not write progress when the threshold is not met (Scenario I).

### What we will **NOT** change
- No Quran source files.
- No Isar schema migrations.
- No removal of `mem_plus_track`, `mem_plus_is_parent_mode`, `hifz_path_mode`, or any review/kids-progress keys.
- No reset of existing user data. `_loadProfile` migration stays exactly as-is.
- No rewrite of the `HifzSessionCubit` SM-2 logic or kids reward math.
- No change to `AchievementService` / certificate logic.

---

## 9. Files to be changed (when approved)

- `lib/core/memorization/memorization_path_resolver.dart` (new)
- `lib/core/router/memorization_path_router.dart` (new)
- `lib/core/router/app_router.dart` (refactor redirects to use the new router; default fallback to `MemorizationPathRouterScreen` on `/memorization-plus`)
- `lib/features/home/presentation/cubits/home_cubit.dart` (use profile async, subscribe to changes)
- `lib/features/home/presentation/pages/home_page.dart` + `home_page_widgets.dart` (path-aware cards; _ProgressSection; _NextBestActionCard; _ResumeSessionCard; _StartHereStrip)
- `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart` (defensive isChild guard)
- `lib/features/hifz/presentation/pages/hifz_page.dart` (gate `MemPlusBanner` on adult)
- `lib/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart` (notify resolver)
- `lib/features/memorization_plus/presentation/cubits/track_selection_cubit.dart` (notify resolver)
- `lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart` (notify resolver)
- New widget tests: `test/features/home/home_page_path_aware_test.dart`, `test/core/router/memorization_path_router_test.dart`, `test/features/hifz/hifz_session_kids_guard_test.dart`
- Comments-only updates in `memorization_plus_repository_impl.dart` to mark legacy keys.

---

**Awaiting your approval to proceed with Phase 0 + Phase 1 + Phase 6 (tests) as the first safe batch**, or to adjust the priority. No code will change until you say "proceed".

---

## User

Convert the approved audit and implementation plan into a formal Markdown document.

---

## Assistant (Build · MiniMax M3 Free · 35.6s)

_Thinking:_

The user wants me to convert the audit and implementation plan into a formal Markdown document. This should be a polished, self-contained document. I should write it to a sensible location. Since the user mentioned "docs/audit.md" earlier, I'll write to a new file like `docs/memorization_audit_plan.md` or update the existing audit file. Let me think about this.

The user said "Convert the approved audit and implementation plan into a formal Markdown document." They want a formal document. I'll create a new file: `docs/memorization_audit_plan.md`. This is a release-readiness document so it deserves its own file.

Let me make it formal and polished, with proper structure, tables, and clear sections. I'll use proper markdown formatting.

**Tool: write**

**Input:**
```json
{}
```

**Error:**
```
Tool execution aborted
```

---

## User

Convert the approved audit and implementation plan into a formal Markdown document.

Requirements:

Create a file:
docs/audits/memorization_system_release_audit.md
Preserve the entire approved plan.
Organize it into professional sections. 

---

## Assistant (Build · MiniMax M3 Free · 12.8s)

_Thinking:_

The user wants me to create a formal markdown document at `docs/audits/memorization_system_release_audit.md`. Let me make sure the parent directory exists first, then write the file.

**Tool: bash**

**Input:**
```json
{
  "command": "if (Test-Path -LiteralPath \"D:\\Sayed\\Flutter\\talia_quran\\docs\\audits\") { Write-Output \"exists\" } else { New-Item -ItemType Directory -Path \"D:\\Sayed\\Flutter\\talia_quran\\docs\\audits\" -Force | Out-Null; Write-Output \"created\" }",
  "description": "Ensure docs/audits directory exists"
}
```

**Output:**
```
created

```

---

## Assistant (Build · MiniMax M3 Free)

---

