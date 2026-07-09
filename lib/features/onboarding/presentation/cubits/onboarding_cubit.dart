import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required SharedPreferences prefs,
    required MemorizationPlusRepository memorizationRepository,
    required MemorizationPathResolver pathResolver,
  }) : _prefs = prefs,
       _memorizationRepository = memorizationRepository,
       _pathResolver = pathResolver,
       super(const OnboardingState());

  static const firstOpenKey = 'isFirstTimeAppOpen';
  static const skippedKey = 'onboarding_skipped';
  static const goalKey = 'user_primary_goal';
  static const userTypeKey = 'onboarding_user_type';
  static const completedAtKey = 'onboarding_completed_at';

  final SharedPreferences _prefs;
  final MemorizationPlusRepository _memorizationRepository;
  final MemorizationPathResolver _pathResolver;

  void goToStep(int step) {
    emit(
      state.copyWith(currentStep: step.clamp(0, OnboardingState.stepCount - 1)),
    );
  }

  void nextStep() {
    if (state.currentStep < OnboardingState.stepCount - 1) {
      goToStep(state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      goToStep(state.currentStep - 1);
    }
  }

  void selectUserType(OnboardingUserType userType) {
    final defaultGoal = userType == OnboardingUserType.child
        ? OnboardingGoal.childJourney
        : OnboardingGoal.reading;
    emit(state.copyWith(selectedUserType: userType, selectedGoal: defaultGoal));
  }

  void selectGoal(OnboardingGoal goal) {
    emit(state.copyWith(selectedGoal: goal));
  }

  Future<void> continueAsGuest() => complete(OnboardingAuthIntent.guest);

  Future<void> signInOrCreateAccount() => complete(OnboardingAuthIntent.signIn);

  Future<void> skip() async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    try {
      await _persistBase(skipped: true);
      emit(
        state.copyWith(
          authIntent: OnboardingAuthIntent.guest,
          status: OnboardingStatus.completed,
          completedRoute: AppRoutes.home,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OnboardingStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> complete(OnboardingAuthIntent intent) async {
    emit(state.copyWith(status: OnboardingStatus.loading, authIntent: intent));
    try {
      await _persistBase(skipped: false);
      await _prefs.setString(goalKey, state.selectedGoal.storageValue);
      await _prefs.setString(userTypeKey, state.selectedUserType.storageValue);
      await _prefs.setString(
        completedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      final route = await _routeAfterOnboarding(intent);
      emit(
        state.copyWith(
          status: OnboardingStatus.completed,
          completedRoute: route,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OnboardingStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _persistBase({required bool skipped}) async {
    await _prefs.setBool(firstOpenKey, false);
    await _prefs.setBool(skippedKey, skipped);
    await _prefs.setString(
      completedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<String> _routeAfterOnboarding(OnboardingAuthIntent intent) async {
    if (state.selectedUserType == OnboardingUserType.child) {
      await _selectPath(MemorizationPath.child);
      return intent == OnboardingAuthIntent.signIn
          ? AppRoutes.login
          : AppRoutes.childOnboarding;
    }

    if (intent == OnboardingAuthIntent.signIn) {
      if (state.selectedGoal == OnboardingGoal.memorization ||
          state.selectedGoal == OnboardingGoal.smartReview) {
        await _selectPath(MemorizationPath.adult);
      }
      return AppRoutes.login;
    }

    return switch (state.selectedGoal) {
      OnboardingGoal.reading => AppRoutes.quran,
      OnboardingGoal.azkar => AppRoutes.azkar,
      OnboardingGoal.memorization => _adultMemorizationEntry(),
      OnboardingGoal.smartReview => _adultSmartReviewEntry(),
      OnboardingGoal.childJourney => _childFromAdultFallback(intent),
    };
  }

  Future<String> _adultMemorizationEntry() async {
    await _selectPath(MemorizationPath.adult);
    return MemorizationNavigationResolver(
      _memorizationRepository,
    ).adultEntryLocation();
  }

  Future<String> _adultSmartReviewEntry() async {
    await _selectPath(MemorizationPath.adult);
    return AppRoutes.memorizationPlusCustomPlan;
  }

  Future<String> _childFromAdultFallback(OnboardingAuthIntent intent) async {
    await _selectPath(MemorizationPath.child);
    return intent == OnboardingAuthIntent.signIn
        ? AppRoutes.login
        : AppRoutes.childOnboarding;
  }

  Future<void> _selectPath(MemorizationPath path) async {
    final result = await _memorizationRepository.selectMemorizationPath(path);
    result.fold((failure) => throw StateError(failure.message), (_) {
      _pathResolver.notifyChanged();
    });
  }
}
