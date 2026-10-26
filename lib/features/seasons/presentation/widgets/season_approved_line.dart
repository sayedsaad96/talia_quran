import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../azkar/data/datasources/azkar_local_datasource.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../data/season_dua_loader.dart';

/// One approved release record shown verbatim with its citation under it.
/// Shows nothing while loading and when the record cannot be loaded or is not
/// approved: no placeholder and no substitute text.
class SeasonApprovedLine extends StatefulWidget {
  const SeasonApprovedLine({
    super.key,
    required this.id,
    required this.skin,
    this.loader,
  });

  final String id;
  final HomeSkin skin;

  /// Replaces the default datasource-backed loader (tests).
  final SeasonLineLoader? loader;

  @override
  State<SeasonApprovedLine> createState() => _SeasonApprovedLineState();
}

class _SeasonApprovedLineState extends State<SeasonApprovedLine> {
  ApprovedSeasonLine? _line;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SeasonApprovedLine old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _line = null;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.id;
    ApprovedSeasonLine? line;
    try {
      final custom = widget.loader;
      if (custom != null) {
        line = await custom(id);
      } else if (getIt.isRegistered<AzkarLocalDatasource>()) {
        line = await loadApprovedSeasonLine(id, getIt<AzkarLocalDatasource>());
      }
    } catch (_) {
      line = null;
    }
    if (!mounted || widget.id != id) return;
    setState(() => _line = line);
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line == null) return const SizedBox.shrink();
    final skin = widget.skin;
    return Padding(
      key: ValueKey('season_line_${line.id}'),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.text,
            style: AppTypography.bodyMedium.copyWith(
              color: skin.textOnHero,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            line.citation,
            style: AppTypography.labelSmall.copyWith(
              color: skin.textOnHeroMuted,
            ),
          ),
        ],
      ),
    );
  }
}
