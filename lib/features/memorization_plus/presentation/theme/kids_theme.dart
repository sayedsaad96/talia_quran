import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

abstract final class KidsTheme {
  static const Color nightSkyDark = Color(0xFF021210); // Matches darkBackground
  static const Color nightSkyMid = Color(0xFF041D1A);  // Matches darkSurface
  static const Color nightSkyLight = Color(0xFF0A2925);
  static const Color forestGreen = Color(0xFF0D5C53);  // Matches primary Royal Teal
  static const Color ribbonGreen = Color(0xFF148275);  // Matches primaryLight
  static const Color mintGlow = Color(0xFF1ABC9C);
  static const Color goldStar = Color(0xFFF59E0B);
  static const Color goldWarm = AppColors.gold;
  static const Color goldLight = AppColors.goldLight;
  static const Color creamParchment = Color(0xFFFFF8E7);
  static const Color parchmentEdge = Color(0xFFEED9A6);
  static const Color houseBrown = Color(0xFF8B6914);
  static const Color houseRoof = Color(0xFFC65A32);
  static const Color lockedGrey = Color(0xFF6B7280);
  static const Color lockedSurface = Color(0xFF3D4656);
  static const Color reviewPurple = Color(0xFF7C3AED);
  static const Color successGreen = AppColors.success;
  static const Color errorRed = AppColors.error;

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [nightSkyDark, nightSkyMid],
  );

  static const LinearGradient currentHouseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ribbonGreen, forestGreen],
  );

  static const LinearGradient completedHouseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldWarm],
  );

  static const LinearGradient parchmentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [creamParchment, Color(0xFFFFEFC2)],
  );

  static const List<BoxShadow> softGlow = [
    BoxShadow(
      color: Color(0x550D5C53),
      blurRadius: 22,
      spreadRadius: 2,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x66F59E0B),
      blurRadius: 24,
      spreadRadius: 2,
      offset: Offset(0, 8),
    ),
  ];

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const String kidAvatarAsset = 'assets/images/kids/kid_avatar.png';
  static const String houseCompletedAsset =
      'assets/images/kids/house_completed.png';
  static const String houseCurrentAsset =
      'assets/images/kids/house_current.png';
  static const String houseLockedAsset = 'assets/images/kids/house_locked.png';
  static const String houseReviewAsset = 'assets/images/kids/house_review.png';
  static const String pathDecorationAsset =
      'assets/images/kids/path_decoration.png';
  static const String ribbonBannerAsset =
      'assets/images/kids/ribbon_banner.png';
  static const String starRewardAsset = 'assets/images/kids/star_reward.png';
}
