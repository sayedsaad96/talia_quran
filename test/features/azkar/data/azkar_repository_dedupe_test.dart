import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_alias_registry.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_local_datasource.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

ZikrModel _model(String id, String text) => ZikrModel(
  id: id,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.duas,
);

class _Datasource implements AzkarLocalDatasource {
  const _Datasource(this.models);
  final List<ZikrModel> models;

  @override
  Future<List<ZikrModel>> getAzkar(AzkarCategory category) async => models;
}

void main() {
  test('hides duplicates, records aliases and keeps dataset order', () async {
    final registry = AzkarAliasRegistry();
    final repository = AzkarRepositoryImpl(
      _Datasource([
        _model('a', 'دعاء أول'),
        _model('b', 'دعاء ثان'),
        _model('c', 'دعاء أول'),
      ]),
      aliasRegistry: registry,
    );

    final result = await repository.getAzkar(AzkarCategory.duas);

    final items = result.fold((_) => <Zikr>[], (list) => list);
    expect(items.map((z) => z.id), ['a', 'b']);
    expect(registry.aliasesOf('a'), {'c'});
  });

  test('works without a registry', () async {
    final repository = AzkarRepositoryImpl(
      _Datasource([_model('a', 'x'), _model('b', 'x')]),
    );

    final result = await repository.getAzkar(AzkarCategory.duas);

    expect(result.fold((_) => 0, (list) => list.length), 1);
  });

  test('getAllAzkar returns deduplicated categories', () async {
    final repository = AzkarRepositoryImpl(
      _Datasource([_model('a', 'x'), _model('b', 'x')]),
    );

    final result = await repository.getAllAzkar();

    final corpus = result.getOrElse(() => {});
    expect(corpus[AzkarCategory.duas]!.length, 1);
    expect(corpus[AzkarCategory.morning]!.length, 1);
  });
}
