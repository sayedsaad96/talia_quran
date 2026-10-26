import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_local_datasource.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/seasons/data/season_dua_loader.dart';

class _Throwing implements AzkarLocalDatasource {
  @override
  Future<List<ZikrModel>> getAzkar(AzkarCategory category) async =>
      throw StateError('no asset');
}

class _Fixed implements AzkarLocalDatasource {
  _Fixed(this.records);
  final List<ZikrModel> records;
  @override
  Future<List<ZikrModel>> getAzkar(AzkarCategory category) async => records;
}

class _Pending extends ZikrModel {
  const _Pending()
    : super(
        id: 'dp4',
        text: 'T',
        transliteration: '',
        translation: '',
        totalCount: 1,
        category: AzkarCategory.duas,
        citation: 'C',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every allowed id loads verbatim from the bundled release file',
    () async {
      final ds = AzkarLocalDatasourceImpl();
      final records = await ds.getAzkar(AzkarCategory.duas);
      for (final id in SeasonLineIds.all) {
        final line = await loadApprovedSeasonLine(id, ds);
        expect(line, isNotNull, reason: id);
        final source = records.firstWhere((r) => r.id == id);
        expect(line!.text, source.text);
        expect(line.citation, isNotEmpty);
      }
    },
  );

  test('an id outside the allowed set is refused even if it exists', () async {
    final ds = AzkarLocalDatasourceImpl();
    final records = await ds.getAzkar(AzkarCategory.duas);
    final other = records.firstWhere((r) => !SeasonLineIds.all.contains(r.id));
    expect(await loadApprovedSeasonLine(other.id, ds), isNull);
    expect(await loadApprovedSeasonLine('missing', ds), isNull);
  });

  test('loading failure and unapproved records give no line', () async {
    expect(await loadApprovedSeasonLine('dp4', _Throwing()), isNull);
    expect(
      await loadApprovedSeasonLine('dp4', _Fixed([const _Pending()])),
      isNull,
    );
    expect(await loadApprovedSeasonLine('dp4', _Fixed(const [])), isNull);
  });
}
