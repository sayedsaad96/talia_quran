import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  factory AppUser.fromSupabase(Map<String, dynamic> data) => AppUser(
    id: data['id'] as String,
    email: data['email'] as String? ?? '',
    displayName: data['display_name'] as String? ?? 'مستخدم',
    avatarUrl: data['avatar_url'] as String?,
  );

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
