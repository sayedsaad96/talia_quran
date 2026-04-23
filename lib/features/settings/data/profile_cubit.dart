import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

// ─── State ───────────────────────────────────────────────────────────────────

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

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._prefs) : super(const ProfileInitial());

  final SharedPreferences _prefs;
  static const _key = 'user_profile';

  void loadProfile() {
    final json = _prefs.getString(_key);
    if (json != null) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      emit(ProfileLoaded(UserProfile.fromJson(map)));
    } else {
      emit(const ProfileLoaded(UserProfile()));
    }
  }

  Future<void> updateProfile({String? name, int? age}) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : const UserProfile();
    final updated = current.copyWith(name: name, age: age);
    final encoded = jsonEncode(updated.toJson());
    await _prefs.setString(_key, encoded);
    emit(ProfileLoaded(updated));
  }
}
