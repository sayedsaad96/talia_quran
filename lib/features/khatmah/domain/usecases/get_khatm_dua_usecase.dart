import '../../data/datasources/khatm_dua_datasource.dart';

class GetKhatmDuaUsecase {
  const GetKhatmDuaUsecase(this._datasource);

  final KhatmDuaDatasource _datasource;

  Future<KhatmDuaData> call() => _datasource.loadDua();
}
