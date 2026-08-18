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

  void selectDailyCommitment(int minutes) {
    emit(state.copyWith(dailyCommitmentMinutes: minutes));
  }

  Future<void> continueAsGuest() => complete(OnboardingAuthIntent.guest);

  Future<void> signInOrCreateAccount() => complete(OnboardingAuthIntent.signIn);

  Future<void> skip() async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    try {
      await _persistBase(skipped: true);
      await _prefs.setString(goalKey, OnboardingGoal.reading.storageValue);
      await _prefs.setString(userTypeKey, OnboardingUserType.adult.storageValue);
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
    if (intent == OnboardingAuthIntent.signIn) {
      if (state.selectedUserType == OnboardingUserType.child) {
        await _selectPath(MemorizationPath.child);
      }
      return AppRoutes.login;
    }

    if (state.selectedUserType == OnboardingUserType.child) {
      await _selectPath(MemorizationPath.child);
      return await MemorizationNavigationResolver(
        _memorizationRepository,
      ).childOnboardingLocation();
    }

    // Adult guest flow: enter Talia Home directly
    return AppRoutes.home;
  }

  Future<void> _selectPath(MemorizationPath path) async {
    final result = await _memorizationRepository.selectMemorizationPath(path);
    result.fold((failure) => throw StateError(failure.message), (_) {
      _pathResolver.notifyChanged();
    });
  }
}
