import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/user_profile.dart';

// ─── State ───────────────────────────────────────────────────────────────────

@immutable
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);
  final UserProfile profile;
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._prefs) : super(const ProfileInitial());

  final SharedPreferences _prefs;
  static const _key = 'user_profile';

  void loadProfile() {
    try {
      final json = _prefs.getString(_key);
      if (json == null) {
        emit(const ProfileLoaded(UserProfile()));
        return;
      }

      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        emit(const ProfileLoaded(UserProfile()));
        return;
      }

      emit(ProfileLoaded(UserProfile.fromJson(decoded)));
    } catch (_) {
      emit(const ProfileLoaded(UserProfile()));
    }
  }

  Future<bool> updateProfile({String? name, int? age}) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : const UserProfile();
    final updated = current.copyWith(name: name, age: age);
    final encoded = jsonEncode(updated.toJson());
    final saved = await _prefs.setString(_key, encoded);
    if (!saved) {
      emit(const ProfileError('Failed to save profile'));
      return false;
    }
    emit(ProfileLoaded(updated));
    return true;
  }
}
