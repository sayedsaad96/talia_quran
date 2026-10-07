import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/icons/talia_icons.dart';
import 'tutorial_guide_definition.dart';
import 'widgets/tutorial_guide_section_card.dart';

class TutorialGuideMapper {
  const TutorialGuideMapper(this.l10n);

  final AppLocalizations l10n;

  List<TutorialGuideSection> mapAll() {
    return TutorialGuideDefinition.all.map(map).toList();
  }

  TutorialGuideSection map(TutorialGuideDefinition def) {
    switch (def) {
      case TutorialGuideDefinition.gettingStarted:
        return TutorialGuideSection(
          title: l10n.tutorialS1Title,
          category: l10n.tutorialS1Cat,
          icon: TaliaIcons.rocket,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS1Does,
          howToOpen: l10n.tutorialS1Open,
          steps: [
            l10n.tutorialS1Step1,
            l10n.tutorialS1Step2,
            l10n.tutorialS1Step3,
          ],
          tips: [l10n.tutorialS1Tip1, l10n.tutorialS1Tip2],
          notes: [l10n.tutorialS1Note1, l10n.tutorialS1Note2],
          whenUseful: l10n.tutorialS1Useful,
        );
      case TutorialGuideDefinition.homePage:
        return TutorialGuideSection(
          title: l10n.tutorialS2Title,
          category: l10n.tutorialS2Cat,
          icon: TaliaIcons.home,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS2Does,
          howToOpen: l10n.tutorialS2Open,
          steps: [
            l10n.tutorialS2Step1,
            l10n.tutorialS2Step2,
            l10n.tutorialS2Step3,
            l10n.tutorialS2Step4,
          ],
          tips: [l10n.tutorialS2Tip1, l10n.tutorialS2Tip2],
          notes: [l10n.tutorialS2Note1, l10n.tutorialS2Note2],
          whenUseful: l10n.tutorialS2Useful,
        );
      case TutorialGuideDefinition.quranReading:
        return TutorialGuideSection(
          title: l10n.tutorialS3Title,
          category: l10n.tutorialS3Cat,
          icon: TaliaIcons.mushaf,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS3Does,
          howToOpen: l10n.tutorialS3Open,
          steps: [
            l10n.tutorialS3Step1,
            l10n.tutorialS3Step2,
            l10n.tutorialS3Step3,
            l10n.tutorialS3Step4,
            l10n.tutorialS3Step5,
          ],
          tips: [l10n.tutorialS3Tip1, l10n.tutorialS3Tip2],
          notes: [l10n.tutorialS3Note1, l10n.tutorialS3Note2],
          whenUseful: l10n.tutorialS3Useful,
        );
      case TutorialGuideDefinition.searchBookmarks:
        return TutorialGuideSection(
          title: l10n.tutorialS4Title,
          category: l10n.tutorialS4Cat,
          icon: TaliaIcons.bookmarkFilled,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS4Does,
          howToOpen: l10n.tutorialS4Open,
          steps: [
            l10n.tutorialS4Step1,
            l10n.tutorialS4Step2,
            l10n.tutorialS4Step3,
            l10n.tutorialS4Step4,
          ],
          tips: [l10n.tutorialS4Tip1, l10n.tutorialS4Tip2],
          notes: [l10n.tutorialS4Note1, l10n.tutorialS4Note2],
          whenUseful: l10n.tutorialS4Useful,
        );
      case TutorialGuideDefinition.memorizationStepByStep:
        return TutorialGuideSection(
          title: l10n.tutorialS5Title,
          category: l10n.tutorialS5Cat,
          icon: TaliaIcons.reading,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS5Does,
          howToOpen: l10n.tutorialS5Open,
          steps: [
            l10n.tutorialS5Step1,
            l10n.tutorialS5Step2,
            l10n.tutorialS5Step3,
            l10n.tutorialS5Step4,
          ],
          tips: [l10n.tutorialS5Tip1, l10n.tutorialS5Tip2],
          notes: [l10n.tutorialS5Note1, l10n.tutorialS5Note2],
          whenUseful: l10n.tutorialS5Useful,
        );
      case TutorialGuideDefinition.dailyAzkar:
        return TutorialGuideSection(
          title: l10n.tutorialS6Title,
          category: l10n.tutorialS6Cat,
          icon: TaliaIcons.azkar,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS6Does,
          howToOpen: l10n.tutorialS6Open,
          steps: [
            l10n.tutorialS6Step1,
            l10n.tutorialS6Step2,
            l10n.tutorialS6Step3,
            l10n.tutorialS6Step4,
            l10n.tutorialS6Step5,
          ],
          tips: [l10n.tutorialS6Tip1, l10n.tutorialS6Tip2],
          notes: [l10n.tutorialS6Note1, l10n.tutorialS6Note2],
          whenUseful: l10n.tutorialS6Useful,
        );
      case TutorialGuideDefinition.smartCoach:
        return TutorialGuideSection(
          title: l10n.tutorialS7Title,
          category: l10n.tutorialS7Cat,
          icon: TaliaIcons.hifz,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS7Does,
          howToOpen: l10n.tutorialS7Open,
          steps: [
            l10n.tutorialS7Step1,
            l10n.tutorialS7Step2,
            l10n.tutorialS7Step3,
            l10n.tutorialS7Step4,
            l10n.tutorialS7Step5,
          ],
          tips: [l10n.tutorialS7Tip1, l10n.tutorialS7Tip2],
          notes: [l10n.tutorialS7Note1, l10n.tutorialS7Note2],
          whenUseful: l10n.tutorialS7Useful,
        );
      case TutorialGuideDefinition.customPlan:
        return TutorialGuideSection(
          title: l10n.tutorialS8Title,
          category: l10n.tutorialS8Cat,
          icon: TaliaIcons.dashboard,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS8Does,
          howToOpen: l10n.tutorialS8Open,
          steps: [
            l10n.tutorialS8Step1,
            l10n.tutorialS8Step2,
            l10n.tutorialS8Step3,
            l10n.tutorialS8Step4,
            l10n.tutorialS8Step5,
          ],
          tips: [l10n.tutorialS8Tip1, l10n.tutorialS8Tip2],
          notes: [l10n.tutorialS8Note1, l10n.tutorialS8Note2],
          whenUseful: l10n.tutorialS8Useful,
        );
      case TutorialGuideDefinition.kidsMode:
        return TutorialGuideSection(
          title: l10n.tutorialS9Title,
          category: l10n.tutorialS9Cat,
          icon: TaliaIcons.family,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS9Does,
          howToOpen: l10n.tutorialS9Open,
          steps: [
            l10n.tutorialS9Step1,
            l10n.tutorialS9Step2,
            l10n.tutorialS9Step3,
            l10n.tutorialS9Step4,
          ],
          tips: [l10n.tutorialS9Tip1, l10n.tutorialS9Tip2],
          notes: [l10n.tutorialS9Note1, l10n.tutorialS9Note2],
          whenUseful: l10n.tutorialS9Useful,
        );
      case TutorialGuideDefinition.progressAchievements:
        return TutorialGuideSection(
          title: l10n.tutorialS10Title,
          category: l10n.tutorialS10Cat,
          icon: TaliaIcons.chart,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS10Does,
          howToOpen: l10n.tutorialS10Open,
          steps: [
            l10n.tutorialS10Step1,
            l10n.tutorialS10Step2,
            l10n.tutorialS10Step3,
            l10n.tutorialS10Step4,
            l10n.tutorialS10Step5,
          ],
          tips: [l10n.tutorialS10Tip1, l10n.tutorialS10Tip2],
          notes: [l10n.tutorialS10Note1, l10n.tutorialS10Note2],
          whenUseful: l10n.tutorialS10Useful,
        );
      case TutorialGuideDefinition.settingsProfile:
        return TutorialGuideSection(
          title: l10n.tutorialS11Title,
          category: l10n.tutorialS11Cat,
          icon: TaliaIcons.settings,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS11Does,
          howToOpen: l10n.tutorialS11Open,
          steps: [
            l10n.tutorialS11Step1,
            l10n.tutorialS11Step2,
            l10n.tutorialS11Step3,
            l10n.tutorialS11Step4,
            l10n.tutorialS11Step5,
            l10n.tutorialS11Step6,
          ],
          tips: [l10n.tutorialS11Tip1, l10n.tutorialS11Tip2],
          notes: [l10n.tutorialS11Note1, l10n.tutorialS11Note2],
          whenUseful: l10n.tutorialS11Useful,
        );
      case TutorialGuideDefinition.offlineWork:
        return TutorialGuideSection(
          title: l10n.tutorialS12Title,
          category: l10n.tutorialS12Cat,
          icon: TaliaIcons.storage,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS12Does,
          howToOpen: l10n.tutorialS12Open,
          steps: [
            l10n.tutorialS12Step1,
            l10n.tutorialS12Step2,
            l10n.tutorialS12Step3,
          ],
          tips: [l10n.tutorialS12Tip1, l10n.tutorialS12Tip2],
          notes: [l10n.tutorialS12Note1, l10n.tutorialS12Note2],
          whenUseful: l10n.tutorialS12Useful,
        );
      case TutorialGuideDefinition.khatmah:
        return TutorialGuideSection(
          title: l10n.tutorialS13Title,
          category: l10n.tutorialS13Cat,
          icon: TaliaIcons.reading,
          accentColor: AppColors.primary,
          whatItDoes: l10n.tutorialS13Does,
          howToOpen: l10n.tutorialS13Open,
          steps: [
            l10n.tutorialS13Step1,
            l10n.tutorialS13Step2,
            l10n.tutorialS13Step3,
            l10n.tutorialS13Step4,
          ],
          tips: [l10n.tutorialS13Tip1, l10n.tutorialS13Tip2],
          notes: [l10n.tutorialS13Note1, l10n.tutorialS13Note2],
          whenUseful: l10n.tutorialS13Useful,
        );
      case TutorialGuideDefinition.prayerTimes:
        return TutorialGuideSection(
          title: l10n.tutorialS14Title,
          category: l10n.tutorialS14Cat,
          icon: TaliaIcons.clock,
          accentColor: AppColors.primaryLight,
          whatItDoes: l10n.tutorialS14Does,
          howToOpen: l10n.tutorialS14Open,
          steps: [
            l10n.tutorialS14Step1,
            l10n.tutorialS14Step2,
            l10n.tutorialS14Step3,
            l10n.tutorialS14Step4,
          ],
          tips: [l10n.tutorialS14Tip1, l10n.tutorialS14Tip2],
          notes: [l10n.tutorialS14Note1, l10n.tutorialS14Note2],
          whenUseful: l10n.tutorialS14Useful,
        );
    }
  }
}
