// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ayah_review_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAyahReviewRecordCollection on Isar {
  IsarCollection<IsarAyahReviewRecord> get isarAyahReviewRecords =>
      this.collection();
}

const IsarAyahReviewRecordSchema = CollectionSchema(
  name: r'IsarAyahReviewRecord',
  id: 2628122786368261413,
  properties: {
    r'ayahNumber': PropertySchema(
      id: 0,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'compositeKey': PropertySchema(
      id: 1,
      name: r'compositeKey',
      type: IsarType.string,
    ),
    r'createdByModeIndex': PropertySchema(
      id: 2,
      name: r'createdByModeIndex',
      type: IsarType.long,
    ),
    r'intervalDays': PropertySchema(
      id: 3,
      name: r'intervalDays',
      type: IsarType.long,
    ),
    r'lastRatingIndex': PropertySchema(
      id: 4,
      name: r'lastRatingIndex',
      type: IsarType.long,
    ),
    r'lastReviewedAt': PropertySchema(
      id: 5,
      name: r'lastReviewedAt',
      type: IsarType.dateTime,
    ),
    r'nextReviewDate': PropertySchema(
      id: 6,
      name: r'nextReviewDate',
      type: IsarType.dateTime,
    ),
    r'strengthLevel': PropertySchema(
      id: 7,
      name: r'strengthLevel',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(
      id: 8,
      name: r'surahId',
      type: IsarType.long,
    ),
    r'totalReviews': PropertySchema(
      id: 9,
      name: r'totalReviews',
      type: IsarType.long,
    )
  },
  estimateSize: _isarAyahReviewRecordEstimateSize,
  serialize: _isarAyahReviewRecordSerialize,
  deserialize: _isarAyahReviewRecordDeserialize,
  deserializeProp: _isarAyahReviewRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'compositeKey': IndexSchema(
      id: -66619599277560115,
      name: r'compositeKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'compositeKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAyahReviewRecordGetId,
  getLinks: _isarAyahReviewRecordGetLinks,
  attach: _isarAyahReviewRecordAttach,
  version: '3.1.0+1',
);

int _isarAyahReviewRecordEstimateSize(
  IsarAyahReviewRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.compositeKey.length * 3;
  return bytesCount;
}

void _isarAyahReviewRecordSerialize(
  IsarAyahReviewRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayahNumber);
  writer.writeString(offsets[1], object.compositeKey);
  writer.writeLong(offsets[2], object.createdByModeIndex);
  writer.writeLong(offsets[3], object.intervalDays);
  writer.writeLong(offsets[4], object.lastRatingIndex);
  writer.writeDateTime(offsets[5], object.lastReviewedAt);
  writer.writeDateTime(offsets[6], object.nextReviewDate);
  writer.writeLong(offsets[7], object.strengthLevel);
  writer.writeLong(offsets[8], object.surahId);
  writer.writeLong(offsets[9], object.totalReviews);
}

IsarAyahReviewRecord _isarAyahReviewRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAyahReviewRecord();
  object.ayahNumber = reader.readLong(offsets[0]);
  object.compositeKey = reader.readString(offsets[1]);
  object.createdByModeIndex = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.intervalDays = reader.readLong(offsets[3]);
  object.lastRatingIndex = reader.readLongOrNull(offsets[4]);
  object.lastReviewedAt = reader.readDateTime(offsets[5]);
  object.nextReviewDate = reader.readDateTime(offsets[6]);
  object.strengthLevel = reader.readLong(offsets[7]);
  object.surahId = reader.readLong(offsets[8]);
  object.totalReviews = reader.readLong(offsets[9]);
  return object;
}

P _isarAyahReviewRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAyahReviewRecordGetId(IsarAyahReviewRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAyahReviewRecordGetLinks(
    IsarAyahReviewRecord object) {
  return [];
}

void _isarAyahReviewRecordAttach(
    IsarCollection<dynamic> col, Id id, IsarAyahReviewRecord object) {
  object.id = id;
}

extension IsarAyahReviewRecordByIndex on IsarCollection<IsarAyahReviewRecord> {
  Future<IsarAyahReviewRecord?> getByCompositeKey(String compositeKey) {
    return getByIndex(r'compositeKey', [compositeKey]);
  }

  IsarAyahReviewRecord? getByCompositeKeySync(String compositeKey) {
    return getByIndexSync(r'compositeKey', [compositeKey]);
  }

  Future<bool> deleteByCompositeKey(String compositeKey) {
    return deleteByIndex(r'compositeKey', [compositeKey]);
  }

  bool deleteByCompositeKeySync(String compositeKey) {
    return deleteByIndexSync(r'compositeKey', [compositeKey]);
  }

  Future<List<IsarAyahReviewRecord?>> getAllByCompositeKey(
      List<String> compositeKeyValues) {
    final values = compositeKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'compositeKey', values);
  }

  List<IsarAyahReviewRecord?> getAllByCompositeKeySync(
      List<String> compositeKeyValues) {
    final values = compositeKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'compositeKey', values);
  }

  Future<int> deleteAllByCompositeKey(List<String> compositeKeyValues) {
    final values = compositeKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'compositeKey', values);
  }

  int deleteAllByCompositeKeySync(List<String> compositeKeyValues) {
    final values = compositeKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'compositeKey', values);
  }

  Future<Id> putByCompositeKey(IsarAyahReviewRecord object) {
    return putByIndex(r'compositeKey', object);
  }

  Id putByCompositeKeySync(IsarAyahReviewRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'compositeKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCompositeKey(List<IsarAyahReviewRecord> objects) {
    return putAllByIndex(r'compositeKey', objects);
  }

  List<Id> putAllByCompositeKeySync(List<IsarAyahReviewRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'compositeKey', objects, saveLinks: saveLinks);
  }
}

extension IsarAyahReviewRecordQueryWhereSort
    on QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QWhere> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarAyahReviewRecordQueryWhere
    on QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QWhereClause> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      compositeKeyEqualTo(String compositeKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'compositeKey',
        value: [compositeKey],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      compositeKeyNotEqualTo(String compositeKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'compositeKey',
              lower: [],
              upper: [compositeKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'compositeKey',
              lower: [compositeKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'compositeKey',
              lower: [compositeKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'compositeKey',
              lower: [],
              upper: [compositeKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarAyahReviewRecordQueryFilter on QueryBuilder<IsarAyahReviewRecord,
    IsarAyahReviewRecord, QFilterCondition> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ayahNumberGreaterThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ayahNumberLessThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ayahNumberBetween(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'compositeKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      compositeKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'compositeKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      compositeKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'compositeKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compositeKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> compositeKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'compositeKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdByModeIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdByModeIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdByModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdByModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdByModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> createdByModeIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdByModeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> intervalDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> intervalDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> intervalDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> intervalDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intervalDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRatingIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRatingIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRatingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRatingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRatingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastRatingIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRatingIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastReviewedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastReviewedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastReviewedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReviewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastReviewedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReviewedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> nextReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> nextReviewDateGreaterThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> nextReviewDateLessThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> nextReviewDateBetween(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> strengthLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'strengthLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> strengthLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'strengthLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> strengthLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'strengthLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> strengthLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'strengthLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> surahIdGreaterThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> surahIdLessThan(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> surahIdBetween(
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> totalReviewsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalReviews',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> totalReviewsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalReviews',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> totalReviewsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalReviews',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> totalReviewsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalReviews',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAyahReviewRecordQueryObject on QueryBuilder<IsarAyahReviewRecord,
    IsarAyahReviewRecord, QFilterCondition> {}

extension IsarAyahReviewRecordQueryLinks on QueryBuilder<IsarAyahReviewRecord,
    IsarAyahReviewRecord, QFilterCondition> {}

extension IsarAyahReviewRecordQuerySortBy
    on QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QSortBy> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByCompositeKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByCompositeKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByCreatedByModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByModeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByCreatedByModeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByModeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLastRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRatingIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLastRatingIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRatingIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLastReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLastReviewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByStrengthLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strengthLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByStrengthLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strengthLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByTotalReviews() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReviews', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByTotalReviewsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReviews', Sort.desc);
    });
  }
}

extension IsarAyahReviewRecordQuerySortThenBy
    on QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QSortThenBy> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByCompositeKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByCompositeKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByCreatedByModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByModeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByCreatedByModeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByModeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intervalDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLastRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRatingIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLastRatingIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRatingIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLastReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLastReviewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByStrengthLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strengthLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByStrengthLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strengthLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByTotalReviews() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReviews', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByTotalReviewsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalReviews', Sort.desc);
    });
  }
}

extension IsarAyahReviewRecordQueryWhereDistinct
    on QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByCompositeKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'compositeKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByCreatedByModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdByModeIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByLastRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRatingIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByLastReviewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReviewedAt');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByStrengthLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'strengthLevel');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByTotalReviews() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalReviews');
    });
  }
}

extension IsarAyahReviewRecordQueryProperty on QueryBuilder<
    IsarAyahReviewRecord, IsarAyahReviewRecord, QQueryProperty> {
  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, String, QQueryOperations>
      compositeKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'compositeKey');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations>
      createdByModeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdByModeIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      intervalDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations>
      lastRatingIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRatingIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, DateTime, QQueryOperations>
      lastReviewedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReviewedAt');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, DateTime, QQueryOperations>
      nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      strengthLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'strengthLevel');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      totalReviewsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalReviews');
    });
  }
}
