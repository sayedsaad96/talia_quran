import 'package:flutter/material.dart';

import 'share_card_backdrop.dart';
import 'share_card_links.dart';
import 'share_card_palette.dart';
import 'share_signature_bar.dart';
import 'social_share_copy.dart';
import 'social_share_model.dart';
import 'social_share_presentation.dart';
import 'talia_share_tokens.dart';

/// The Dawn card frame: backdrop, content-type eyebrow, the hero [child],
/// an optional personal line and the signature bar.
class ShareCardShell extends StatelessWidget {
  const ShareCardShell({
    super.key,
    required this.data,
    required this.palette,
    required this.format,
    required this.copy,
    required this.child,
  });

  final SocialShareData data;
  final SharePalette palette;
  final SocialShareFormat format;
  final SocialShareCopy copy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = TaliaShareMetrics.of(format);
    final showCharacter =
        SocialSharePresentation.characterTreatmentFor(data, format) ==
        SocialShareCharacterTreatment.prominent;
    final characterLane = showCharacter ? metrics.characterHeight * 0.55 : 0.0;
    final name = data.userName?.trim();

    // Cards are exported offscreen where ambient Directionality is not
    // guaranteed; pin it to the copy so preview and PNG match.
    return Directionality(
      textDirection: copy.direction,
      child: AspectRatio(
        aspectRatio: TaliaShareDimensions.aspectRatioFor(format),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TaliaShareMetrics.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShareCardBackdrop(
                palette: palette,
                metrics: metrics,
                watermark: copy.watermark(data),
              ),
              Padding(
                padding: metrics.padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.eyebrow(data),
                      key: const ValueKey('share-eyebrow'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TaliaShareTypography.display(
                        color: palette.eyebrow,
                        fontSize: metrics.eyebrowSize,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          metrics.heroInset,
                          metrics.gap,
                          metrics.heroInset + characterLane,
                          metrics.gap,
                        ),
                        child: Center(child: child),
                      ),
                    ),
                    if (name != null && name.isNotEmpty) ...[
                      // On the same glass as the signature bar so the line
                      // stays readable over the mushaf light.
                      Center(
                        child: Container(
                          key: const ValueKey('share-personal-pill'),
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.gap * 1.5,
                            vertical: metrics.gap / 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.signatureSurface,
                            borderRadius: BorderRadius.circular(
                              TaliaShareMetrics.signatureRadius,
                            ),
                          ),
                          child: Text(
                            copy.journeyFor(name),
                            key: const ValueKey('share-personal-line'),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TaliaShareTypography.body(
                              color: palette.signatureText,
                              fontSize: metrics.personalLineSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.gap),
                    ],
                    ShareSignatureBar(
                      palette: palette,
                      metrics: metrics,
                      copy: copy,
                      invitation: copy.invitation(data),
                      qrData: ShareCardLinks.forCategory(data.category),
                    ),
                  ],
                ),
              ),
              if (showCharacter)
                PositionedDirectional(
                  end: metrics.padding.right - metrics.gap,
                  bottom:
                      metrics.padding.bottom +
                      metrics.signatureHeight +
                      metrics.gap,
                  child: TaliaCharacterHero(
                    assetPath: data.effectiveCharacterAssetPath,
                    height: metrics.characterHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The official companion art for kids cards.
class TaliaCharacterHero extends StatelessWidget {
  const TaliaCharacterHero({
    super.key,
    required this.assetPath,
    required this.height,
  });

  final String assetPath;
  final double height;

  /// The exact image painted for a character of [height] logical px; the
  /// share sheet precaches this same provider (see `logoProvider`).
  static ImageProvider imageProvider(String assetPath, double height) =>
      ResizeImage(AssetImage(assetPath), width: (height * 3).round());

  @override
  Widget build(BuildContext context) {
    // Both axes are pinned so offscreen exports lay out correctly before
    // the codec reports intrinsic dimensions.
    return Image(
      image: imageProvider(assetPath, height),
      key: const ValueKey('share-hero-character'),
      width: height,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox.square(dimension: height),
    );
  }
}
