import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'custom_plan_state.dart';

class CustomPlanCubit extends Cubit<CustomPlanState> {
  CustomPlanCubit(this._repository) : super(const CustomPlanInitial());

  final MemorizationPlusRepository _repository;

  Future<void> load() async {
    emit(const CustomPlanLoading());
    final result = await _repository.getCustomPlan();
    result.fold((f) => emit(CustomPlanError(f.message)), (plan) {
      if (plan != null) {
        emit(CustomPlanLoaded(plan: plan));
      } else {
        emit(const CustomPlanEmpty());
      }
    });
  }

  Future<void> savePlan(CustomMemorizationPlan plan) async {
    emit(const CustomPlanLoading());
    final result = await _repository.saveCustomPlan(plan);
    result.fold(
      (f) => emit(CustomPlanError(f.message)),
      (_) => emit(CustomPlanSaved(plan: plan)),
    );
  }

  Future<void> deletePlan() async {
    emit(const CustomPlanLoading());
    final result = await _repository.deleteCustomPlan();
    result.fold(
      (f) => emit(CustomPlanError(f.message)),
      (_) => emit(const CustomPlanEmpty()),
    );
  }
}
