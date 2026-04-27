// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hifz_progress_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHifzProgressIsarCollection on Isar {
  IsarCollection<HifzProgressIsar> get hifzProgressIsars => this.collection();
}

const HifzProgressIsarSchema = CollectionSchema(
  name: r'HifzProgressIsar',
  id: 2481604704199951433,
  properties: {
    r'ayahNumber': PropertySchema(
      id: 0,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'lastReviewDate': PropertySchema(
      id: 1,
      name: r'lastReviewDate',
      type: IsarType.dateTime,
    ),
    r'nextReviewDate': PropertySchema(
      id: 2,
      name: r'nextReviewDate',
      type: IsarType.dateTime,
    ),
    r'repetitions': PropertySchema(
      id: 3,
      name: r'repetitions',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 4,
      name: r'status',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(
      id: 5,
      name: r'surahId',
      type: IsarType.long,
    ),
    r'uniqueKey': PropertySchema(
      id: 6,
      name: r'uniqueKey',
      type: IsarType.string,
    )
  },
  estimateSize: _hifzProgressIsarEstimateSize,
  serialize: _hifzProgressIsarSerialize,
  deserialize: _hifzProgressIsarDeserialize,
  deserializeProp: _hifzProgressIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'uniqueKey': IndexSchema(
      id: -866995956150369819,
      name: r'uniqueKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hifzProgressIsarGetId,
  getLinks: _hifzProgressIsarGetLinks,
  attach: _hifzProgressIsarAttach,
  version: '3.1.0+1',
);

int _hifzProgressIsarEstimateSize(
  HifzProgressIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _hifzProgressIsarSerialize(
  HifzProgressIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayahNumber);
  writer.writeDateTime(offsets[1], object.lastReviewDate);
  writer.writeDateTime(offsets[2], object.nextReviewDate);
  writer.writeLong(offsets[3], object.repetitions);
  writer.writeLong(offsets[4], object.status);
  writer.writeLong(offsets[5], object.surahId);
  writer.writeString(offsets[6], object.uniqueKey);
}

HifzProgressIsar _hifzProgressIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HifzProgressIsar();
  object.ayahNumber = reader.readLong(offsets[0]);
  object.id = id;
  object.lastReviewDate = reader.readDateTime(offsets[1]);
  object.nextReviewDate = reader.readDateTime(offsets[2]);
  object.repetitions = reader.readLong(offsets[3]);
  object.status = reader.readLong(offsets[4]);
  object.surahId = reader.readLong(offsets[5]);
  object.uniqueKey = reader.readString(offsets[6]);
  return object;
}

P _hifzProgressIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hifzProgressIsarGetId(HifzProgressIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hifzProgressIsarGetLinks(HifzProgressIsar object) {
  return [];
}

void _hifzProgressIsarAttach(
    IsarCollection<dynamic> col, Id id, HifzProgressIsar object) {
  object.id = id;
}

extension HifzProgressIsarByIndex on IsarCollection<HifzProgressIsar> {
  Future<HifzProgressIsar?> getByUniqueKey(String uniqueKey) {
    return getByIndex(r'uniqueKey', [uniqueKey]);
  }

  HifzProgressIsar? getByUniqueKeySync(String uniqueKey) {
    return getByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<bool> deleteByUniqueKey(String uniqueKey) {
    return deleteByIndex(r'uniqueKey', [uniqueKey]);
  }

  bool deleteByUniqueKeySync(String uniqueKey) {
    return deleteByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<List<HifzProgressIsar?>> getAllByUniqueKey(
      List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'uniqueKey', values);
  }

  List<HifzProgressIsar?> getAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uniqueKey', values);
  }

  Future<int> deleteAllByUniqueKey(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uniqueKey', values);
  }

  int deleteAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uniqueKey', values);
  }

  Future<Id> putByUniqueKey(HifzProgressIsar object) {
    return putByIndex(r'uniqueKey', object);
  }

  Id putByUniqueKeySync(HifzProgressIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKey(List<HifzProgressIsar> objects) {
    return putAllByIndex(r'uniqueKey', objects);
  }

  List<Id> putAllByUniqueKeySync(List<HifzProgressIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uniqueKey', objects, saveLinks: saveLinks);
  }
}

extension HifzProgressIsarQueryWhereSort
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QWhere> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HifzProgressIsarQueryWhere
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QWhereClause> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause>
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

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause>
      uniqueKeyEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uniqueKey',
        value: [uniqueKey],
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterWhereClause>
      uniqueKeyNotEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey',
              lower: [],
              upper: [uniqueKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey',
              lower: [uniqueKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey',
              lower: [uniqueKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uniqueKey',
              lower: [],
              upper: [uniqueKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension HifzProgressIsarQueryFilter
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QFilterCondition> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      ayahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      ayahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      ayahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ayahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
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

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
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

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
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

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      lastReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      lastReviewDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      lastReviewDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      lastReviewDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReviewDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      nextReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      nextReviewDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      nextReviewDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      nextReviewDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextReviewDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      repetitionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      repetitionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      repetitionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      repetitionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repetitions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      statusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      statusGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      statusLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      statusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      surahIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      surahIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      surahIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surahId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uniqueKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uniqueKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uniqueKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterFilterCondition>
      uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uniqueKey',
        value: '',
      ));
    });
  }
}

extension HifzProgressIsarQueryObject
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QFilterCondition> {}

extension HifzProgressIsarQueryLinks
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QFilterCondition> {}

extension HifzProgressIsarQuerySortBy
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QSortBy> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByLastReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension HifzProgressIsarQuerySortThenBy
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QSortThenBy> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByLastReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QAfterSortBy>
      thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension HifzProgressIsarQueryWhereDistinct
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct> {
  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReviewDate');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repetitions');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }

  QueryBuilder<HifzProgressIsar, HifzProgressIsar, QDistinct>
      distinctByUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }
}

extension HifzProgressIsarQueryProperty
    on QueryBuilder<HifzProgressIsar, HifzProgressIsar, QQueryProperty> {
  QueryBuilder<HifzProgressIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HifzProgressIsar, int, QQueryOperations> ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<HifzProgressIsar, DateTime, QQueryOperations>
      lastReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReviewDate');
    });
  }

  QueryBuilder<HifzProgressIsar, DateTime, QQueryOperations>
      nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<HifzProgressIsar, int, QQueryOperations> repetitionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repetitions');
    });
  }

  QueryBuilder<HifzProgressIsar, int, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<HifzProgressIsar, int, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }

  QueryBuilder<HifzProgressIsar, String, QQueryOperations> uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }
}
