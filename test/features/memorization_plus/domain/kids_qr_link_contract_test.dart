import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_qr_link_contract.dart';

void main() {
  group('KidsQrLinkContract', () {
    test('qrData builds the child payload from the shared prefix', () {
      expect(KidsQrLinkContract.qrData('ABC123'), 'talia-kids-link:ABC123');
    });

    test('recognizes the shared and legacy prefixes in any casing', () {
      expect(
        KidsQrLinkContract.isLinkPayload('talia-kids-link:ABC123'),
        isTrue,
      );
      expect(
        KidsQrLinkContract.isLinkPayload('TALIA-KIDS-LINK:ABC123'),
        isTrue,
      );
      expect(KidsQrLinkContract.isLinkPayload('talia_link:OLD123'), isTrue);
      expect(KidsQrLinkContract.isLinkPayload('  talia_link:OLD123  '), isTrue);
    });

    test('rejects foreign QR payloads', () {
      expect(KidsQrLinkContract.isLinkPayload('https://example.com'), isFalse);
      expect(KidsQrLinkContract.isLinkPayload('other-app:token'), isFalse);
      expect(KidsQrLinkContract.isLinkPayload(''), isFalse);
    });

    test('extracts the token from every accepted payload shape', () {
      expect(
        KidsQrLinkContract.extractToken('talia-kids-link:ABC123'),
        'ABC123',
      );
      expect(KidsQrLinkContract.extractToken('talia_link:OLD123'), 'OLD123');
      expect(KidsQrLinkContract.extractToken('TALIA_LINK:old123'), 'old123');
      expect(KidsQrLinkContract.extractToken('BARE123'), 'BARE123');
      expect(
        KidsQrLinkContract.extractToken('  talia-kids-link: PAD  '),
        'PAD',
      );
    });

    test('pairing QR data round-trips through the parent-side extractor', () {
      // The full cross-device contract: the child service generates the QR
      // payload and the parent device scans it and recovers the token.
      const token = 'ABCDEF123456';
      final qrData = KidsQrLinkContract.qrData(token);
      expect(KidsQrLinkContract.isLinkPayload(qrData), isTrue);
      expect(KidsQrLinkContract.extractToken(qrData), token);
    });

    test(
      'child-side manual entry extractor matches the scanner contract',
      () {
        // The parent can either scan the QR or paste/type the payload; both
        // paths must resolve to the same token.
        const payload = 'talia-kids-link:ABC123';
        final viaScanner = KidsQrLinkContract.extractToken(payload);
        final viaManualEntry = MemorizationParentAccessService.extractLinkToken(
          payload,
        );
        expect(viaManualEntry, viaScanner);
        expect(viaManualEntry, 'ABC123');
      },
    );
  });
}
