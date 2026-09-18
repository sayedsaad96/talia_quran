import re

with open('test/features/home/presentation/responsive_home_widgets_test.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure essential imports exist
essential_imports = [
    "import 'package:talia_quran/features/home/presentation/widgets/home_contextual_slot.dart';",
    "import 'package:talia_quran/features/home/presentation/widgets/home_continue_card.dart';",
    "import 'package:talia_quran/features/home/presentation/widgets/home_first_run.dart';",
    "import 'package:talia_quran/features/home/presentation/widgets/resume_session_card.dart';",
    "import 'package:talia_quran/features/home/presentation/widgets/next_best_action_card.dart';",
    "import 'package:talia_quran/features/home/presentation/widgets/home_unified_progress.dart';"
]
for imp in essential_imports:
    if imp not in content:
        content = imp + '\n' + content

# Fix remaining broken expect() calls for deleted widgets
content = re.sub(r'expect\(find\.byType\(HomeMomentumStrip\), findsOneWidget\);', '', content)
content = re.sub(r'expect\(find\.byType\(HomeQuickAccess\), findsOneWidget\);', '', content)
content = re.sub(r'expect\(find\.byType\(HomeActionTiles\), findsOneWidget\);', '', content)
content = re.sub(r'expect\(find\.byType\(HomeDailyChallengeCard\), findsOneWidget\);', '', content)
content = re.sub(r'expect\(find\.byType\(HomeJourneyRingCard\), findsOneWidget\);', '', content)

# Fix remaining constructor issues
content = content.replace('HomeFirstRun(isDark: brightness == Brightness.dark)', 'HomeFirstRun(skin: skin)')
content = content.replace('ResumeSessionCard(recitation: state.continueRecitation!, isDark: brightness == Brightness.dark)', 'ResumeSessionCard(recitation: state.continueRecitation!, skin: skin)')
content = content.replace('NextBestActionCard(action: state.heroAction!, isDark: brightness == Brightness.dark, isKids: false)', 'NextBestActionCard(action: state.heroAction!, skin: skin)')

with open('test/features/home/presentation/responsive_home_widgets_test.dart', 'w', encoding='utf-8') as f:
    f.write(content)
