import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/utils/locale_numeric_input_formatter.dart';
import '../../data/tarawih_log_store.dart';

/// Local date of [now] as `yyyy-mm-dd`.
String tarawihNightKey(DateTime now) {
  final d = now.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Local hour before which a log belongs to the previous evening's night.
const kTarawihNightEndHour = 4;

/// Key of the night [now] falls in: before [kTarawihNightEndHour] local time
/// it is the previous civil date (the night that began that evening).
String tarawihNightKeyAt(DateTime now) {
  final d = now.toLocal();
  return tarawihNightKey(
    d.hour < kTarawihNightEndHour ? DateTime(d.year, d.month, d.day - 1) : d,
  );
}

/// Opens the tonight's-tarawih entry sheet. Self-log only; never feeds the
/// khatmah. [now] is injectable for tests.
Future<void> showTarawihLogSheet(
  BuildContext context,
  TarawihLogStore store, {
  DateTime Function()? now,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => TarawihLogSheet(store: store, now: now ?? DateTime.now),
  );
}

class TarawihLogSheet extends StatefulWidget {
  const TarawihLogSheet({super.key, required this.store, required this.now});

  final TarawihLogStore store;
  final DateTime Function() now;

  @override
  State<TarawihLogSheet> createState() => _TarawihLogSheetState();
}

class _TarawihLogSheetState extends State<TarawihLogSheet> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  late final String _night = tarawihNightKeyAt(widget.now());
  bool _hasEntry = false;
  bool _invalid = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await widget.store.entries();
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    for (final e in entries) {
      if (e.nightKey == _night) {
        _from.text = LocaleNumberFormatter.number(e.fromPage, lang);
        _to.text = LocaleNumberFormatter.number(e.toPage, lang);
        _hasEntry = true;
      }
    }
    setState(() => _loaded = true);
  }

  int? _parse(String text) => int.tryParse(LocaleNumberFormatter.western(text));

  Future<void> _save() async {
    final from = _parse(_from.text);
    final to = _parse(_to.text);
    final entry = (from == null || to == null)
        ? null
        : TarawihEntry(nightKey: _night, fromPage: from, toPage: to);
    if (entry == null || !entry.isValid) {
      setState(() => _invalid = true);
      return;
    }
    await widget.store.upsert(entry);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.store.remove(_night);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(Key key, TextEditingController c, String label, String lang) {
    return TextField(
      key: key,
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
        LengthLimitingTextInputFormatter(3),
        LocaleNumericInputFormatter(lang),
      ],
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tarawihTitle,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              const ValueKey('tarawih_from'),
              _from,
              l10n.tarawihFromPage,
              lang,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(const ValueKey('tarawih_to'), _to, l10n.tarawihToPage, lang),
            if (_invalid) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.tarawihInvalidRange,
                key: const ValueKey('tarawih_invalid'),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const ValueKey('tarawih_save'),
              onPressed: _loaded ? _save : null,
              child: Text(l10n.save),
            ),
            if (_hasEntry)
              TextButton(
                key: const ValueKey('tarawih_delete'),
                onPressed: _delete,
                child: Text(l10n.delete),
              ),
          ],
        ),
      ),
    );
  }
}
