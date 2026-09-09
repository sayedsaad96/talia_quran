import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/usecases/search_quran_usecase.dart';

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  QuranSearchResult _result = const QuranSearchResult.empty();
  bool _loading = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_search(value));
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _query = query.trim();
      _loading = _query.isNotEmpty;
    });
    if (_query.isEmpty) {
      setState(() => _result = const QuranSearchResult.empty());
      return;
    }
    final result = await getIt<SearchQuranUsecase>().call(_query);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loading = false;
        _result = const QuranSearchResult.empty();
      }),
      (data) => setState(() {
        _loading = false;
        _result = data;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.homeSearchTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchSurah,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_query.isEmpty) return const SizedBox.shrink();
    if (!_loading && _result.surahs.isEmpty && _result.ayahs.isEmpty) {
      return Center(child: Text(context.l10n.homeSearchNoResults));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        for (final surah in _result.surahs)
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(context.isArabic ? surah.nameAr : surah.nameEn),
            subtitle: Text(context.l10n.surah),
            onTap: () => context.push('/quran/surah/${surah.id}'),
          ),
        for (final ayah in _result.ayahs.take(40))
          ListTile(
            leading: const Icon(Icons.format_quote_rounded),
            title: Text(
              ayah.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: AppTypography.bodyMedium.copyWith(fontFamily: 'Amiri'),
            ),
            subtitle: Text(
              context.l10n.surahAyahFormat(
                context.isArabic
                    ? SurahNames.nameAr(ayah.surahId)
                    : SurahNames.nameEn(ayah.surahId),
                ayah.numberInSurah,
              ),
            ),
            onTap: () {
              final page = ayah.page;
              if (page != null) {
                context.push('/quran/page/$page');
              } else {
                context.push('/quran/surah/${ayah.surahId}');
              }
            },
          ),
      ],
    );
  }
}
