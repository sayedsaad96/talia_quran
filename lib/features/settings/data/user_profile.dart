import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    this.name = '',
    this.age,
  });

  final String name;
  final int? age;

  /// Whether a name has been set by the user.
  bool get hasName => name.trim().isNotEmpty;

  /// Display name: returns the user's name or a fallback empty string.
  String get displayName => name.trim();

  UserProfile copyWith({
    String? name,
    int? age,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      age: json['age'] as int?,
    );
  }

  @override
  List<Object?> get props => [name, age];
}
