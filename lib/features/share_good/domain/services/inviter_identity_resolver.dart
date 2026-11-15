import '../entities/invite_types.dart';

final class InviterIdentityResolver {
  const InviterIdentityResolver();

  InviterIdentity resolve(
    InviteIdentityMode mode, {
    String? profileName,
    String? authDisplayName,
  }) {
    if (mode == InviteIdentityMode.anonymous) return _anonymous;
    final profile = _realName(profileName);
    final display = _realName(authDisplayName);
    final name = mode == InviteIdentityMode.displayName
        ? display ?? profile
        : profile ?? display;
    if (name == null) return _anonymous;
    final selected = mode == InviteIdentityMode.firstName
        ? name.split(RegExp(r'\s+')).first
        : name;
    return InviterIdentity(
      mode: mode,
      visibleName: String.fromCharCodes(selected.runes.take(40)).trimRight(),
    );
  }

  static const _anonymous = InviterIdentity(mode: InviteIdentityMode.anonymous);

  String? _realName(String? name) {
    final value = name?.trim();
    if (value == null ||
        value.isEmpty ||
        value == 'مستخدم' ||
        value == 'مستخدم تالية' ||
        value.toLowerCase() == 'talia user') {
      return null;
    }
    return value;
  }
}
