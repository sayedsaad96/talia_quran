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
    r'audience': PropertySchema(
      id: 0,
      name: r'audience',
      type: IsarType.string,
    ),
    r'ayahNumber': PropertySchema(
      id: 1,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'cloudDirty': PropertySchema(
      id: 2,
      name: r'cloudDirty',
      type: IsarType.bool,
    ),
    r'compositeKey': PropertySchema(
      id: 3,
      name: r'compositeKey',
      type: IsarType.string,
    ),
    r'createdByModeIndex': PropertySchema(
      id: 4,
      name: r'createdByModeIndex',
      type: IsarType.long,
    ),
    r'difficulty': PropertySchema(
      id: 5,
      name: r'difficulty',
      type: IsarType.double,
    ),
    r'easeFactor': PropertySchema(
      id: 6,
      name: r'easeFactor',
      type: IsarType.double,
    ),
    r'intervalDays': PropertySchema(
      id: 7,
      name: r'intervalDays',
      type: IsarType.long,
    ),
    r'lapses': PropertySchema(
      id: 8,
      name: r'lapses',
      type: IsarType.long,
    ),
    r'lastRatingIndex': PropertySchema(
      id: 9,
      name: r'lastRatingIndex',
      type: IsarType.long,
    ),
    r'lastReviewedAt': PropertySchema(
      id: 10,
      name: r'lastReviewedAt',
      type: IsarType.dateTime,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 11,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'nextReviewDate': PropertySchema(
      id: 12,
      name: r'nextReviewDate',
      type: IsarType.dateTime,
    ),
    r'ownerUserId': PropertySchema(
      id: 13,
      name: r'ownerUserId',
      type: IsarType.string,
    ),
    r'predictedFsrsDueDate': PropertySchema(
      id: 14,
      name: r'predictedFsrsDueDate',
      type: IsarType.dateTime,
    ),
    r'predictedFsrsIntervalDays': PropertySchema(
      id: 15,
      name: r'predictedFsrsIntervalDays',
      type: IsarType.long,
    ),
    r'predictedRecallProbability': PropertySchema(
      id: 16,
      name: r'predictedRecallProbability',
      type: IsarType.double,
    ),
    r'predictedRetrievability': PropertySchema(
      id: 17,
      name: r'predictedRetrievability',
      type: IsarType.double,
    ),
    r'reviewStateIndex': PropertySchema(
      id: 18,
      name: r'reviewStateIndex',
      type: IsarType.long,
    ),
    r'schedulerEarlierThanFsrs': PropertySchema(
      id: 19,
      name: r'schedulerEarlierThanFsrs',
      type: IsarType.bool,
    ),
    r'schedulerVsFsrsGapDays': PropertySchema(
      id: 20,
      name: r'schedulerVsFsrsGapDays',
      type: IsarType.long,
    ),
    r'schedulerVsFsrsRatio': PropertySchema(
      id: 21,
      name: r'schedulerVsFsrsRatio',
      type: IsarType.double,
    ),
    r'stability': PropertySchema(
      id: 22,
      name: r'stability',
      type: IsarType.double,
    ),
    r'strengthLevel': PropertySchema(
      id: 23,
      name: r'strengthLevel',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(
      id: 24,
      name: r'surahId',
      type: IsarType.long,
    ),
    r'totalReviews': PropertySchema(
      id: 25,
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
    ),
    r'ownerUserId': IndexSchema(
      id: 1631799950038639233,
      name: r'ownerUserId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUserId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'audience': IndexSchema(
      id: -6290508362283539773,
      name: r'audience',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'audience',
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
  {
    final value = object.audience;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.compositeKey.length * 3;
  {
    final value = object.ownerUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarAyahReviewRecordSerialize(
  IsarAyahReviewRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audience);
  writer.writeLong(offsets[1], object.ayahNumber);
  writer.writeBool(offsets[2], object.cloudDirty);
  writer.writeString(offsets[3], object.compositeKey);
  writer.writeLong(offsets[4], object.createdByModeIndex);
  writer.writeDouble(offsets[5], object.difficulty);
  writer.writeDouble(offsets[6], object.easeFactor);
  writer.writeLong(offsets[7], object.intervalDays);
  writer.writeLong(offsets[8], object.lapses);
  writer.writeLong(offsets[9], object.lastRatingIndex);
  writer.writeDateTime(offsets[10], object.lastReviewedAt);
  writer.writeDateTime(offsets[11], object.lastSyncedAt);
  writer.writeDateTime(offsets[12], object.nextReviewDate);
  writer.writeString(offsets[13], object.ownerUserId);
  writer.writeDateTime(offsets[14], object.predictedFsrsDueDate);
  writer.writeLong(offsets[15], object.predictedFsrsIntervalDays);
  writer.writeDouble(offsets[16], object.predictedRecallProbability);
  writer.writeDouble(offsets[17], object.predictedRetrievability);
  writer.writeLong(offsets[18], object.reviewStateIndex);
  writer.writeBool(offsets[19], object.schedulerEarlierThanFsrs);
  writer.writeLong(offsets[20], object.schedulerVsFsrsGapDays);
  writer.writeDouble(offsets[21], object.schedulerVsFsrsRatio);
  writer.writeDouble(offsets[22], object.stability);
  writer.writeLong(offsets[23], object.strengthLevel);
  writer.writeLong(offsets[24], object.surahId);
  writer.writeLong(offsets[25], object.totalReviews);
}

IsarAyahReviewRecord _isarAyahReviewRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAyahReviewRecord();
  object.audience = reader.readStringOrNull(offsets[0]);
  object.ayahNumber = reader.readLong(offsets[1]);
  object.cloudDirty = reader.readBoolOrNull(offsets[2]);
  object.compositeKey = reader.readString(offsets[3]);
  object.createdByModeIndex = reader.readLongOrNull(offsets[4]);
  object.difficulty = reader.readDoubleOrNull(offsets[5]);
  object.easeFactor = reader.readDoubleOrNull(offsets[6]);
  object.id = id;
  object.intervalDays = reader.readLong(offsets[7]);
  object.lapses = reader.readLongOrNull(offsets[8]);
  object.lastRatingIndex = reader.readLongOrNull(offsets[9]);
  object.lastReviewedAt = reader.readDateTime(offsets[10]);
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[11]);
  object.nextReviewDate = reader.readDateTime(offsets[12]);
  object.ownerUserId = reader.readStringOrNull(offsets[13]);
  object.predictedFsrsDueDate = reader.readDateTimeOrNull(offsets[14]);
  object.predictedFsrsIntervalDays = reader.readLongOrNull(offsets[15]);
  object.predictedRecallProbability = reader.readDoubleOrNull(offsets[16]);
  object.predictedRetrievability = reader.readDoubleOrNull(offsets[17]);
  object.reviewStateIndex = reader.readLongOrNull(offsets[18]);
  object.schedulerEarlierThanFsrs = reader.readBoolOrNull(offsets[19]);
  object.schedulerVsFsrsGapDays = reader.readLongOrNull(offsets[20]);
  object.schedulerVsFsrsRatio = reader.readDoubleOrNull(offsets[21]);
  object.stability = reader.readDoubleOrNull(offsets[22]);
  object.strengthLevel = reader.readLong(offsets[23]);
  object.surahId = reader.readLong(offsets[24]);
  object.totalReviews = reader.readLong(offsets[25]);
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
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    case 19:
      return (reader.readBoolOrNull(offset)) as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readDoubleOrNull(offset)) as P;
    case 23:
      return (reader.readLong(offset)) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
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

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      ownerUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUserId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      ownerUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ownerUserId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      ownerUserIdEqualTo(String? ownerUserId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUserId',
        value: [ownerUserId],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      ownerUserIdNotEqualTo(String? ownerUserId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [],
              upper: [ownerUserId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [ownerUserId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [ownerUserId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUserId',
              lower: [],
              upper: [ownerUserId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      audienceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'audience',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      audienceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'audience',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      audienceEqualTo(String? audience) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'audience',
        value: [audience],
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterWhereClause>
      audienceNotEqualTo(String? audience) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'audience',
              lower: [],
              upper: [audience],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'audience',
              lower: [audience],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'audience',
              lower: [audience],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'audience',
              lower: [],
              upper: [audience],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarAyahReviewRecordQueryFilter on QueryBuilder<IsarAyahReviewRecord,
    IsarAyahReviewRecord, QFilterCondition> {
  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audience',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audience',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audience',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      audienceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audience',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      audienceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audience',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audience',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> audienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audience',
        value: '',
      ));
    });
  }

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
      QAfterFilterCondition> cloudDirtyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cloudDirty',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> cloudDirtyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cloudDirty',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> cloudDirtyEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudDirty',
        value: value,
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
      QAfterFilterCondition> difficultyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'difficulty',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> difficultyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'difficulty',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> difficultyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'difficulty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> difficultyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'difficulty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> difficultyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'difficulty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> difficultyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'difficulty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'easeFactor',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'easeFactor',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'easeFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> easeFactorBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'easeFactor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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
      QAfterFilterCondition> lapsesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lapses',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lapsesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lapses',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lapsesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lapsesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lapsesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lapses',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lapsesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lapses',
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
      QAfterFilterCondition> lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
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
      QAfterFilterCondition> ownerUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownerUserId',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownerUserId',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      ownerUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
          QAfterFilterCondition>
      ownerUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> ownerUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedFsrsDueDate',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedFsrsDueDate',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedFsrsDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedFsrsDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedFsrsDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsDueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedFsrsDueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedFsrsIntervalDays',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedFsrsIntervalDays',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedFsrsIntervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedFsrsIntervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedFsrsIntervalDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedFsrsIntervalDaysBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedFsrsIntervalDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedRecallProbability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedRecallProbability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedRecallProbability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedRecallProbability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedRecallProbability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRecallProbabilityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedRecallProbability',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'predictedRetrievability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'predictedRetrievability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'predictedRetrievability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'predictedRetrievability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'predictedRetrievability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> predictedRetrievabilityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'predictedRetrievability',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reviewStateIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reviewStateIndex',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reviewStateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reviewStateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reviewStateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> reviewStateIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reviewStateIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerEarlierThanFsrsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'schedulerEarlierThanFsrs',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerEarlierThanFsrsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'schedulerEarlierThanFsrs',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerEarlierThanFsrsEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schedulerEarlierThanFsrs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'schedulerVsFsrsGapDays',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'schedulerVsFsrsGapDays',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schedulerVsFsrsGapDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schedulerVsFsrsGapDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schedulerVsFsrsGapDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsGapDaysBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schedulerVsFsrsGapDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'schedulerVsFsrsRatio',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'schedulerVsFsrsRatio',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schedulerVsFsrsRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schedulerVsFsrsRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schedulerVsFsrsRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> schedulerVsFsrsRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schedulerVsFsrsRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stability',
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stability',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord,
      QAfterFilterCondition> stabilityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stability',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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
      sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

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
      sortByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByCloudDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.desc);
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
      sortByDifficulty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficulty', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByDifficultyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficulty', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByEaseFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.desc);
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
      sortByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLapsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.desc);
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
      sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
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
      sortByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedFsrsDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsDueDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedFsrsDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsDueDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedFsrsIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsIntervalDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedFsrsIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsIntervalDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedRecallProbability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRecallProbability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedRecallProbabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRecallProbability', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedRetrievability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRetrievability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByPredictedRetrievabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRetrievability', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByReviewStateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewStateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByReviewStateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewStateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerEarlierThanFsrs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerEarlierThanFsrs', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerEarlierThanFsrsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerEarlierThanFsrs', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerVsFsrsGapDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsGapDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerVsFsrsGapDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsGapDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerVsFsrsRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsRatio', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortBySchedulerVsFsrsRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsRatio', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByStability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      sortByStabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stability', Sort.desc);
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
      thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

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
      thenByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByCloudDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.desc);
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
      thenByDifficulty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficulty', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByDifficultyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difficulty', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByEaseFactorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'easeFactor', Sort.desc);
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
      thenByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLapsesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lapses', Sort.desc);
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
      thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
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
      thenByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedFsrsDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsDueDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedFsrsDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsDueDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedFsrsIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsIntervalDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedFsrsIntervalDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedFsrsIntervalDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedRecallProbability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRecallProbability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedRecallProbabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRecallProbability', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedRetrievability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRetrievability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByPredictedRetrievabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'predictedRetrievability', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByReviewStateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewStateIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByReviewStateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewStateIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerEarlierThanFsrs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerEarlierThanFsrs', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerEarlierThanFsrsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerEarlierThanFsrs', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerVsFsrsGapDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsGapDays', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerVsFsrsGapDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsGapDays', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerVsFsrsRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsRatio', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenBySchedulerVsFsrsRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schedulerVsFsrsRatio', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByStability() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stability', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QAfterSortBy>
      thenByStabilityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stability', Sort.desc);
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
      distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudDirty');
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
      distinctByDifficulty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'difficulty');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByEaseFactor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'easeFactor');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByLapses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lapses');
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
      distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByOwnerUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByPredictedFsrsDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedFsrsDueDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByPredictedFsrsIntervalDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedFsrsIntervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByPredictedRecallProbability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedRecallProbability');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByPredictedRetrievability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'predictedRetrievability');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByReviewStateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reviewStateIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctBySchedulerEarlierThanFsrs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schedulerEarlierThanFsrs');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctBySchedulerVsFsrsGapDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schedulerVsFsrsGapDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctBySchedulerVsFsrsRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schedulerVsFsrsRatio');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, IsarAyahReviewRecord, QDistinct>
      distinctByStability() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stability');
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

  QueryBuilder<IsarAyahReviewRecord, String?, QQueryOperations>
      audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, bool?, QQueryOperations>
      cloudDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudDirty');
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

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      difficultyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'difficulty');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      easeFactorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'easeFactor');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int, QQueryOperations>
      intervalDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations> lapsesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lapses');
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

  QueryBuilder<IsarAyahReviewRecord, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, DateTime, QQueryOperations>
      nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, String?, QQueryOperations>
      ownerUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUserId');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, DateTime?, QQueryOperations>
      predictedFsrsDueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedFsrsDueDate');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations>
      predictedFsrsIntervalDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedFsrsIntervalDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      predictedRecallProbabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedRecallProbability');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      predictedRetrievabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'predictedRetrievability');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations>
      reviewStateIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reviewStateIndex');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, bool?, QQueryOperations>
      schedulerEarlierThanFsrsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schedulerEarlierThanFsrs');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, int?, QQueryOperations>
      schedulerVsFsrsGapDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schedulerVsFsrsGapDays');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      schedulerVsFsrsRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schedulerVsFsrsRatio');
    });
  }

  QueryBuilder<IsarAyahReviewRecord, double?, QQueryOperations>
      stabilityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stability');
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
