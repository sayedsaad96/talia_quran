import 'package:flutter/widgets.dart';

import '../../domain/services/quran_spread_policy.dart';

/// Displays one visual Mushaf spread with a stable physical page order.
final class QuranSpreadView extends StatelessWidget {
  const QuranSpreadView({
    super.key,
    required this.spread,
    required this.pageBuilder,
  });

  final QuranSpread spread;
  final Widget Function(int canonicalPage) pageBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(child: _pageOrEmpty(spread.leftPage)),
        Expanded(child: _pageOrEmpty(spread.rightPage)),
      ],
    );
  }

  Widget _pageOrEmpty(int? canonicalPage) {
    return canonicalPage == null
        ? const SizedBox.shrink()
        : pageBuilder(canonicalPage);
  }
}
