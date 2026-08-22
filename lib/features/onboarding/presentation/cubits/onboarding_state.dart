part of 'onboarding_cubit.dart';

enum OnboardingUserType {
  adult('adult'),
  child('child');

  const OnboardingUserType(this.storageValue);
  final String storageValue;
}

enum OnboardingGoal {
  reading('reading'),
  memorization('memorization'),
  smartReview('smart_review'),
  azkar('azkar'),
  childJourney('child_journey');

  const OnboardingGoal(this.storageValue);
  final String storageValue;
}

enum OnboardingAuthIntent {
  guest('guest'),
  signIn('sign_in');

  const OnboardingAuthIntent(this.storageValue);
  final String storageValue;
}

enum OnboardingStatus { editing, loading, completed, error }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.selectedUserType = OnboardingUserType.adult,
    this.selectedGoal = OnboardingGoal.reading,
    this.authIntent = OnboardingAuthIntent.guest,
    this.currentStep = 0,
    this.status = OnboardingStatus.editing,
    this.completedRoute,
    this.errorMessage,
  });

  static const stepCount = 2;

  final OnboardingUserType selectedUserType;
  final OnboardingGoal selectedGoal;
  final OnboardingAuthIntent authIntent;
  final int currentStep;
  final OnboardingStatus status;
  final String? completedRoute;
  final String? errorMessage;

  bool get isChild => selectedUserType == OnboardingUserType.child;
  bool get isLoading => status == OnboardingStatus.loading;

  OnboardingState copyWith({
    OnboardingUserType? selectedUserType,
    OnboardingGoal? selectedGoal,
    OnboardingAuthIntent? authIntent,
    int? currentStep,
    OnboardingStatus? status,
    String? completedRoute,
    String? errorMessage,
  }) {
    return OnboardingState(
      selectedUserType: selectedUserType ?? this.selectedUserType,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      authIntent: authIntent ?? this.authIntent,
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      completedRoute: completedRoute ?? this.completedRoute,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedUserType,
    selectedGoal,
    authIntent,
    currentStep,
    status,
    completedRoute,
    errorMessage,
  ];
}
