import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/settings/domain/entities/data_protection_status.dart';
import 'package:talia_quran/features/settings/presentation/cubits/data_protection_cubit.dart';

void main() {
  test(
    'a delayed old-account result cannot overwrite a refreshed account status',
    () async {
      final changes = StreamController<void>.broadcast(sync: true);
      final old = Completer<DataProtectionStatus>();
      var reads = 0;
      final cubit = DataProtectionCubit(() {
        if (reads++ == 0) return old.future;
        return Future.value(DataProtectionStatus(signedIn: false, domains: {}));
      }, accountChanges: changes.stream);
      final first = cubit.refresh();
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
      old.complete(
        DataProtectionStatus(
          signedIn: true,
          domains: {
            ProtectionDomain.progress: const ProtectionDomainStatus(
              ProtectionState.synced,
            ),
          },
        ),
      );
      await first;
      expect(cubit.state.status!.signedIn, isFalse);
      expect(
        cubit.state.status!.forDomain(ProtectionDomain.progress).state,
        ProtectionState.localOnly,
      );
      await cubit.close();
      await changes.close();
    },
  );
  test(
    'reports each domain independently without manufacturing success timestamps',
    () async {
      final success = DateTime.utc(2026, 1, 1);
      final cubit = DataProtectionCubit(
        () async => DataProtectionStatus(
          signedIn: true,
          domains: {
            ProtectionDomain.progress: ProtectionDomainStatus(
              ProtectionState.synced,
              lastSuccess: success,
            ),
            ProtectionDomain.bookmarks: const ProtectionDomainStatus(
              ProtectionState.failed,
            ),
          },
        ),
      );
      await cubit.refresh();
      expect(
        cubit.state.status!.forDomain(ProtectionDomain.progress).lastSuccess,
        success,
      );
      expect(
        cubit.state.status!.forDomain(ProtectionDomain.bookmarks).state,
        ProtectionState.failed,
      );
      expect(
        cubit.state.status!.forDomain(ProtectionDomain.bookmarks).lastSuccess,
        isNull,
      );
      expect(
        cubit.state.status!.forDomain(ProtectionDomain.review).state,
        ProtectionState.unknown,
      );
      await cubit.close();
    },
  );
  test('signed-out status is on-device even if cloud data is supplied', () {
    final status = DataProtectionStatus(
      signedIn: false,
      domains: {
        ProtectionDomain.progress: const ProtectionDomainStatus(
          ProtectionState.synced,
        ),
      },
    );
    expect(
      status.forDomain(ProtectionDomain.progress).state,
      ProtectionState.localOnly,
    );
  });
}
