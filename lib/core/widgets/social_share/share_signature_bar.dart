import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'share_card_palette.dart';
import 'social_share_copy.dart';
import 'talia_share_tokens.dart';

/// The only brand block on a card: official logo, wordmark, a gentle
/// invitation and a QR code to the landing page.
class ShareSignatureBar extends StatelessWidget {
  const ShareSignatureBar({
    super.key,
    required this.palette,
    required this.metrics,
    required this.copy,
    required this.invitation,
    required this.qrData,
  });

  static const String logoAsset = 'assets/images/logo_new_padded.png';

  final SharePalette palette;
  final TaliaShareMetrics metrics;
  final SocialShareCopy copy;
  final String invitation;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final inset = (metrics.signatureHeight - metrics.qrSize) / 2;
    return Container(
      key: const ValueKey('share-signature-bar'),
      height: metrics.signatureHeight,
      padding: EdgeInsets.symmetric(horizontal: inset + 2, vertical: inset),
      decoration: BoxDecoration(
        color: palette.signatureSurface,
        borderRadius: BorderRadius.circular(TaliaShareMetrics.signatureRadius),
        border: Border.all(color: palette.signatureBorder, width: 0.8),
      ),
      child: Row(
        children: [
          _ShareLogo(size: metrics.logoSize, fallbackColor: palette.wordmark),
          SizedBox(width: metrics.gap + 2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.wordmark,
                  maxLines: 1,
                  style: TaliaShareTypography.display(
                    color: palette.wordmark,
                    fontSize: metrics.wordmarkSize,
                    height: 1.2,
                  ),
                ),
                Text(
                  invitation,
                  key: const ValueKey('share-invitation'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TaliaShareTypography.body(
                    color: palette.signatureText,
                    fontSize: metrics.invitationSize,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.gap),
          ShareQrCode(
            data: qrData,
            size: metrics.qrSize,
            foreground: palette.qrForeground,
            background: palette.qrBackground,
          ),
        ],
      ),
    );
  }
}

class _ShareLogo extends StatelessWidget {
  const _ShareLogo({required this.size, required this.fallbackColor});

  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    // The padded logo has a transparent margin; scaling inside the circle
    // lets the emblem, not the padding, fill the mark.
    const emblemScale = 1.35;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Transform.scale(
          scale: emblemScale,
          child: Image.asset(
            ShareSignatureBar.logoAsset,
            key: const ValueKey('share-logo'),
            fit: BoxFit.cover,
            cacheWidth: (size * 3 * emblemScale).round(),
            errorBuilder: (_, _, _) =>
                Icon(Icons.auto_awesome_rounded, color: fallbackColor),
          ),
        ),
      ),
    );
  }
}

/// QR with a light quiet zone so it scans after social-media compression.
class ShareQrCode extends StatelessWidget {
  const ShareQrCode({
    super.key,
    required this.data,
    required this.size,
    required this.foreground,
    required this.background,
  });

  final String data;
  final double size;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('share-qr'),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.07),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TaliaShareMetrics.qrRadius),
      ),
      child: QrImageView(
        data: data,
        padding: EdgeInsets.zero,
        backgroundColor: background,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foreground),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foreground,
        ),
      ),
    );
  }
}
