// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_activity_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyActivityIsarCollection on Isar {
  IsarCollection<DailyActivityIsar> get dailyActivityIsars => this.collection();
}

const DailyActivityIsarSchema = CollectionSchema(
  name: r'DailyActivityIsar',
  id: -8167946893276352156,
  properties: {
    r'activityCount': PropertySchema(
      id: 0,
      name: r'activityCount',
      type: IsarType.long,
    ),
    r'dayKey': PropertySchema(
      id: 1,
      name: r'dayKey',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyActivityIsarEstimateSize,
  serialize: _dailyActivityIsarSerialize,
  deserialize: _dailyActivityIsarDeserialize,
  deserializeProp: _dailyActivityIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'dayKey': IndexSchema(
      id: -3264092797330672150,
      name: r'dayKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dayKey',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyActivityIsarGetId,
  getLinks: _dailyActivityIsarGetLinks,
  attach: _dailyActivityIsarAttach,
  version: '3.1.0+1',
);

int _dailyActivityIsarEstimateSize(
  DailyActivityIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _dailyActivityIsarSerialize(
  DailyActivityIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.activityCount);
  writer.writeLong(offsets[1], object.dayKey);
}

DailyActivityIsar _dailyActivityIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyActivityIsar();
  object.activityCount = reader.readLong(offsets[0]);
  object.dayKey = reader.readLong(offsets[1]);
  object.id = id;
  return object;
}

P _dailyActivityIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyActivityIsarGetId(DailyActivityIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyActivityIsarGetLinks(
    DailyActivityIsar object) {
  return [];
}

void _dailyActivityIsarAttach(
    IsarCollection<dynamic> col, Id id, DailyActivityIsar object) {
  object.id = id;
}

extension DailyActivityIsarByIndex on IsarCollection<DailyActivityIsar> {
  Future<DailyActivityIsar?> getByDayKey(int dayKey) {
    return getByIndex(r'dayKey', [dayKey]);
  }

  DailyActivityIsar? getByDayKeySync(int dayKey) {
    return getByIndexSync(r'dayKey', [dayKey]);
  }

  Future<bool> deleteByDayKey(int dayKey) {
    return deleteByIndex(r'dayKey', [dayKey]);
  }

  bool deleteByDayKeySync(int dayKey) {
    return deleteByIndexSync(r'dayKey', [dayKey]);
  }

  Future<List<DailyActivityIsar?>> getAllByDayKey(List<int> dayKeyValues) {
    final values = dayKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dayKey', values);
  }

  List<DailyActivityIsar?> getAllByDayKeySync(List<int> dayKeyValues) {
    final values = dayKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dayKey', values);
  }

  Future<int> deleteAllByDayKey(List<int> dayKeyValues) {
    final values = dayKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dayKey', values);
  }

  int deleteAllByDayKeySync(List<int> dayKeyValues) {
    final values = dayKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dayKey', values);
  }

  Future<Id> putByDayKey(DailyActivityIsar object) {
    return putByIndex(r'dayKey', object);
  }

  Id putByDayKeySync(DailyActivityIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'dayKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDayKey(List<DailyActivityIsar> objects) {
    return putAllByIndex(r'dayKey', objects);
  }

  List<Id> putAllByDayKeySync(List<DailyActivityIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dayKey', objects, saveLinks: saveLinks);
  }
}

extension DailyActivityIsarQueryWhereSort
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QWhere> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhere> anyDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dayKey'),
      );
    });
  }
}

extension DailyActivityIsarQueryWhere
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QWhereClause> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      dayKeyEqualTo(int dayKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dayKey',
        value: [dayKey],
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      dayKeyNotEqualTo(int dayKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [],
              upper: [dayKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [dayKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [dayKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [],
              upper: [dayKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      dayKeyGreaterThan(
    int dayKey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayKey',
        lower: [dayKey],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      dayKeyLessThan(
    int dayKey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayKey',
        lower: [],
        upper: [dayKey],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterWhereClause>
      dayKeyBetween(
    int lowerDayKey,
    int upperDayKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dayKey',
        lower: [lowerDayKey],
        includeLower: includeLower,
        upper: [upperDayKey],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityIsarQueryFilter
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QFilterCondition> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      activityCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      activityCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      activityCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      activityCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      dayKeyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayKey',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      dayKeyGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayKey',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      dayKeyLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayKey',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      dayKeyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityIsarQueryObject
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QFilterCondition> {}

extension DailyActivityIsarQueryLinks
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QFilterCondition> {}

extension DailyActivityIsarQuerySortBy
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QSortBy> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      sortByActivityCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityCount', Sort.asc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      sortByActivityCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityCount', Sort.desc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      sortByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      sortByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }
}

extension DailyActivityIsarQuerySortThenBy
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QSortThenBy> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      thenByActivityCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityCount', Sort.asc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      thenByActivityCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityCount', Sort.desc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      thenByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      thenByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension DailyActivityIsarQueryWhereDistinct
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QDistinct> {
  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QDistinct>
      distinctByActivityCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityCount');
    });
  }

  QueryBuilder<DailyActivityIsar, DailyActivityIsar, QDistinct>
      distinctByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayKey');
    });
  }
}

extension DailyActivityIsarQueryProperty
    on QueryBuilder<DailyActivityIsar, DailyActivityIsar, QQueryProperty> {
  QueryBuilder<DailyActivityIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyActivityIsar, int, QQueryOperations>
      activityCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityCount');
    });
  }

  QueryBuilder<DailyActivityIsar, int, QQueryOperations> dayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayKey');
    });
  }
}
