import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/share_good/domain/entities/good_impact.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';

void main() {
  test('participation status only moves forward', () {
    expect(
      InviteParticipationStatus.opened.canAdvanceTo(
        InviteParticipationStatus.started,
      ),
      isTrue,
    );
    expect(
      InviteParticipationStatus.started.canAdvanceTo(
        InviteParticipationStatus.opened,
      ),
      isFalse,
    );
    expect(
      InviteParticipationStatus.completedPrivate.canAdvanceTo(
        InviteParticipationStatus.completedSharedIdentity,
      ),
      isTrue,
    );
    expect(
      InviteParticipationStatus.completedSharedIdentity.canAdvanceTo(
        InviteParticipationStatus.completedPrivate,
      ),
      isFalse,
    );
    expect(
      InviteParticipationStatus.completedPrivate.canAdvanceTo(
        InviteParticipationStatus.continuedAsNewInvite,
      ),
      isTrue,
    );
  });
  test('anonymous identity carries no name', () {
    expect(
      () =>
          InviterIdentity(mode: InviteIdentityMode.anonymous, visibleName: 'x'),
      throwsA(anything),
    );
  });
  test('invite diagnostics redact bearer tokens and names', () {
    const token = 'private-token';
    const name = 'private-name';
    const target = QuranPageInviteTarget(42);
    const identity = InviterIdentity(
      mode: InviteIdentityMode.firstName,
      visibleName: name,
    );
    const context = InviteContext(
      target: target,
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.personal,
      identity: identity,
    );
    final timestamp = DateTime.utc(2026);
    final resolved = ResolvedInvite(
      token: token,
      target: target,
      moment: context.moment,
      mode: context.mode,
      inviter: identity,
      status: InviteLifecycleStatus.active,
      expiresAt: timestamp,
    );
    final records = [
      context,
      CreatedInvite(
        token: token,
        shareUrl: Uri.https('example.com', '/i/$token'),
        context: context,
        createdAt: timestamp,
        expiresAt: timestamp,
      ),
      resolved,
      InviteSession(token: token, snapshot: resolved),
      NamedAcknowledgement(
        target: target,
        visibleName: name,
        completedAt: timestamp,
      ),
    ];
    for (final record in records) {
      expect(record.toString(), isNot(contains(token)));
      expect(record.toString(), isNot(contains(name)));
    }
  });
}
