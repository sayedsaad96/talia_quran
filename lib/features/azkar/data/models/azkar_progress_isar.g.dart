// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'azkar_progress_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAzkarProgressIsarCollection on Isar {
  IsarCollection<AzkarProgressIsar> get azkarProgressIsars => this.collection();
}

const AzkarProgressIsarSchema = CollectionSchema(
  name: r'AzkarProgressIsar',
  id: 7103836301839193057,
  properties: {
    r'dateKey': PropertySchema(id: 0, name: r'dateKey', type: IsarType.string),
    r'progressJson': PropertySchema(
      id: 1,
      name: r'progressJson',
      type: IsarType.string,
    ),
  },
  estimateSize: _azkarProgressIsarEstimateSize,
  serialize: _azkarProgressIsarSerialize,
  deserialize: _azkarProgressIsarDeserialize,
  deserializeProp: _azkarProgressIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _azkarProgressIsarGetId,
  getLinks: _azkarProgressIsarGetLinks,
  attach: _azkarProgressIsarAttach,
  version: '3.1.0+1',
);

int _azkarProgressIsarEstimateSize(
  AzkarProgressIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.progressJson.length * 3;
  return bytesCount;
}

void _azkarProgressIsarSerialize(
  AzkarProgressIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dateKey);
  writer.writeString(offsets[1], object.progressJson);
}

AzkarProgressIsar _azkarProgressIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AzkarProgressIsar();
  object.dateKey = reader.readString(offsets[0]);
  object.id = id;
  object.progressJson = reader.readString(offsets[1]);
  return object;
}

P _azkarProgressIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _azkarProgressIsarGetId(AzkarProgressIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _azkarProgressIsarGetLinks(
  AzkarProgressIsar object,
) {
  return [];
}

void _azkarProgressIsarAttach(
  IsarCollection<dynamic> col,
  Id id,
  AzkarProgressIsar object,
) {
  object.id = id;
}

extension AzkarProgressIsarByIndex on IsarCollection<AzkarProgressIsar> {
  Future<AzkarProgressIsar?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  AzkarProgressIsar? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<AzkarProgressIsar?>> getAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<AzkarProgressIsar?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(AzkarProgressIsar object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(AzkarProgressIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<AzkarProgressIsar> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(
    List<AzkarProgressIsar> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension AzkarProgressIsarQueryWhereSort
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QWhere> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AzkarProgressIsarQueryWhere
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QWhereClause> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
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

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateKey', value: [dateKey]),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterWhereClause>
  dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension AzkarProgressIsarQueryFilter
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QFilterCondition> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'progressJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'progressJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'progressJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'progressJson', value: ''),
      );
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterFilterCondition>
  progressJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'progressJson', value: ''),
      );
    });
  }
}

extension AzkarProgressIsarQueryObject
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QFilterCondition> {}

extension AzkarProgressIsarQueryLinks
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QFilterCondition> {}

extension AzkarProgressIsarQuerySortBy
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QSortBy> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  sortByProgressJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.asc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  sortByProgressJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.desc);
    });
  }
}

extension AzkarProgressIsarQuerySortThenBy
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QSortThenBy> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  thenByProgressJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.asc);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QAfterSortBy>
  thenByProgressJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progressJson', Sort.desc);
    });
  }
}

extension AzkarProgressIsarQueryWhereDistinct
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QDistinct> {
  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QDistinct>
  distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QDistinct>
  distinctByProgressJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progressJson', caseSensitive: caseSensitive);
    });
  }
}

extension AzkarProgressIsarQueryProperty
    on QueryBuilder<AzkarProgressIsar, AzkarProgressIsar, QQueryProperty> {
  QueryBuilder<AzkarProgressIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AzkarProgressIsar, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<AzkarProgressIsar, String, QQueryOperations>
  progressJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progressJson');
    });
  }
}
