import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/khatm_dua_datasource.dart';
import '../../domain/usecases/get_khatm_dua_usecase.dart';

sealed class KhatmDuaState extends Equatable {
  const KhatmDuaState();

  @override
  List<Object?> get props => [];
}

class KhatmDuaInitial extends KhatmDuaState {
  const KhatmDuaInitial();
}

class KhatmDuaLoading extends KhatmDuaState {
  const KhatmDuaLoading();
}

class KhatmDuaLoaded extends KhatmDuaState {
  const KhatmDuaLoaded({
    required this.data,
    this.fontScale = 1.0,
  });

  final KhatmDuaData data;
  final double fontScale;

  KhatmDuaLoaded copyWith({
    KhatmDuaData? data,
    double? fontScale,
  }) {
    return KhatmDuaLoaded(
      data: data ?? this.data,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  @override
  List<Object?> get props => [data, fontScale];
}

class KhatmDuaError extends KhatmDuaState {
  const KhatmDuaError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class KhatmDuaCubit extends Cubit<KhatmDuaState> {
  KhatmDuaCubit(this._getKhatmDua) : super(const KhatmDuaInitial());

  final GetKhatmDuaUsecase _getKhatmDua;

  static const double minFontScale = 1.0;
  static const double maxFontScale = 1.8;
  static const double fontScaleStep = 0.1;

  Future<void> load() async {
    emit(const KhatmDuaLoading());
    try {
      final data = await _getKhatmDua();
      emit(KhatmDuaLoaded(data: data));
    } catch (e) {
      emit(KhatmDuaError(e.toString()));
    }
  }

  void increaseFontSize() {
    final current = state;
    if (current is KhatmDuaLoaded) {
      final next = (current.fontScale + fontScaleStep).clamp(minFontScale, maxFontScale);
      emit(current.copyWith(fontScale: double.parse(next.toStringAsFixed(1))));
    }
  }

  void decreaseFontSize() {
    final current = state;
    if (current is KhatmDuaLoaded) {
      final next = (current.fontScale - fontScaleStep).clamp(minFontScale, maxFontScale);
      emit(current.copyWith(fontScale: double.parse(next.toStringAsFixed(1))));
    }
  }

  void resetFontSize() {
    final current = state;
    if (current is KhatmDuaLoaded) {
      emit(current.copyWith(fontScale: 1.0));
    }
  }

  void setFontScale(double scale) {
    final current = state;
    if (current is KhatmDuaLoaded) {
      final clamped = scale.clamp(minFontScale, maxFontScale);
      emit(current.copyWith(fontScale: clamped));
    }
  }
}
