// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_v2_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarV2SessionCollection on Isar {
  IsarCollection<IsarV2Session> get isarV2Sessions => this.collection();
}

const IsarV2SessionSchema = CollectionSchema(
  name: r'IsarV2Session',
  id: 8022502978895585485,
  properties: {
    r'audienceIndex': PropertySchema(
      id: 0,
      name: r'audienceIndex',
      type: IsarType.long,
    ),
    r'blockAyahNumbersCsv': PropertySchema(
      id: 1,
      name: r'blockAyahNumbersCsv',
      type: IsarType.string,
    ),
    r'blockReviewRequired': PropertySchema(
      id: 2,
      name: r'blockReviewRequired',
      type: IsarType.bool,
    ),
    r'currentAyahIndex': PropertySchema(
      id: 3,
      name: r'currentAyahIndex',
      type: IsarType.long,
    ),
    r'failureCountsCsv': PropertySchema(
      id: 4,
      name: r'failureCountsCsv',
      type: IsarType.string,
    ),
    r'hintLevelsCsv': PropertySchema(
      id: 5,
      name: r'hintLevelsCsv',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(
      id: 6,
      name: r'ownerId',
      type: IsarType.string,
    ),
    r'passedAyahNumbersCsv': PropertySchema(
      id: 7,
      name: r'passedAyahNumbersCsv',
      type: IsarType.string,
    ),
    r'phaseIndex': PropertySchema(
      id: 8,
      name: r'phaseIndex',
      type: IsarType.long,
    ),
    r'savedAt': PropertySchema(
      id: 9,
      name: r'savedAt',
      type: IsarType.dateTime,
    ),
    r'sessionKey': PropertySchema(
      id: 10,
      name: r'sessionKey',
      type: IsarType.string,
    ),
    r'surahId': PropertySchema(
      id: 11,
      name: r'surahId',
      type: IsarType.long,
    )
  },
  estimateSize: _isarV2SessionEstimateSize,
  serialize: _isarV2SessionSerialize,
  deserialize: _isarV2SessionDeserialize,
  deserializeProp: _isarV2SessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionKey': IndexSchema(
      id: -4553619741042231539,
      name: r'sessionKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sessionKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'surahId': IndexSchema(
      id: -5113487006415954472,
      name: r'surahId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'surahId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarV2SessionGetId,
  getLinks: _isarV2SessionGetLinks,
  attach: _isarV2SessionAttach,
  version: '3.1.0+1',
);

int _isarV2SessionEstimateSize(
  IsarV2Session object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blockAyahNumbersCsv.length * 3;
  bytesCount += 3 + object.failureCountsCsv.length * 3;
  bytesCount += 3 + object.hintLevelsCsv.length * 3;
  {
    final value = object.ownerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.passedAyahNumbersCsv.length * 3;
  {
    final value = object.sessionKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarV2SessionSerialize(
  IsarV2Session object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.audienceIndex);
  writer.writeString(offsets[1], object.blockAyahNumbersCsv);
  writer.writeBool(offsets[2], object.blockReviewRequired);
  writer.writeLong(offsets[3], object.currentAyahIndex);
  writer.writeString(offsets[4], object.failureCountsCsv);
  writer.writeString(offsets[5], object.hintLevelsCsv);
  writer.writeString(offsets[6], object.ownerId);
  writer.writeString(offsets[7], object.passedAyahNumbersCsv);
  writer.writeLong(offsets[8], object.phaseIndex);
  writer.writeDateTime(offsets[9], object.savedAt);
  writer.writeString(offsets[10], object.sessionKey);
  writer.writeLong(offsets[11], object.surahId);
}

IsarV2Session _isarV2SessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarV2Session();
  object.audienceIndex = reader.readLong(offsets[0]);
  object.blockAyahNumbersCsv = reader.readString(offsets[1]);
  object.blockReviewRequired = reader.readBool(offsets[2]);
  object.currentAyahIndex = reader.readLong(offsets[3]);
  object.failureCountsCsv = reader.readString(offsets[4]);
  object.hintLevelsCsv = reader.readString(offsets[5]);
  object.id = id;
  object.ownerId = reader.readStringOrNull(offsets[6]);
  object.passedAyahNumbersCsv = reader.readString(offsets[7]);
  object.phaseIndex = reader.readLong(offsets[8]);
  object.savedAt = reader.readDateTime(offsets[9]);
  object.sessionKey = reader.readStringOrNull(offsets[10]);
  object.surahId = reader.readLong(offsets[11]);
  return object;
}

P _isarV2SessionDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarV2SessionGetId(IsarV2Session object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarV2SessionGetLinks(IsarV2Session object) {
  return [];
}

void _isarV2SessionAttach(
    IsarCollection<dynamic> col, Id id, IsarV2Session object) {
  object.id = id;
}

extension IsarV2SessionByIndex on IsarCollection<IsarV2Session> {
  Future<IsarV2Session?> getBySessionKey(String? sessionKey) {
    return getByIndex(r'sessionKey', [sessionKey]);
  }

  IsarV2Session? getBySessionKeySync(String? sessionKey) {
    return getByIndexSync(r'sessionKey', [sessionKey]);
  }

  Future<bool> deleteBySessionKey(String? sessionKey) {
    return deleteByIndex(r'sessionKey', [sessionKey]);
  }

  bool deleteBySessionKeySync(String? sessionKey) {
    return deleteByIndexSync(r'sessionKey', [sessionKey]);
  }

  Future<List<IsarV2Session?>> getAllBySessionKey(
      List<String?> sessionKeyValues) {
    final values = sessionKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionKey', values);
  }

  List<IsarV2Session?> getAllBySessionKeySync(List<String?> sessionKeyValues) {
    final values = sessionKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionKey', values);
  }

  Future<int> deleteAllBySessionKey(List<String?> sessionKeyValues) {
    final values = sessionKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionKey', values);
  }

  int deleteAllBySessionKeySync(List<String?> sessionKeyValues) {
    final values = sessionKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionKey', values);
  }

  Future<Id> putBySessionKey(IsarV2Session object) {
    return putByIndex(r'sessionKey', object);
  }

  Id putBySessionKeySync(IsarV2Session object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionKey(List<IsarV2Session> objects) {
    return putAllByIndex(r'sessionKey', objects);
  }

  List<Id> putAllBySessionKeySync(List<IsarV2Session> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sessionKey', objects, saveLinks: saveLinks);
  }
}

extension IsarV2SessionQueryWhereSort
    on QueryBuilder<IsarV2Session, IsarV2Session, QWhere> {
  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhere> anySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'surahId'),
      );
    });
  }
}

extension IsarV2SessionQueryWhere
    on QueryBuilder<IsarV2Session, IsarV2Session, QWhereClause> {
  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      sessionKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      sessionKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sessionKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      sessionKeyEqualTo(String? sessionKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionKey',
        value: [sessionKey],
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      sessionKeyNotEqualTo(String? sessionKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [sessionKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionKey',
              lower: [],
              upper: [sessionKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> surahIdEqualTo(
      int surahId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surahId',
        value: [surahId],
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      surahIdNotEqualTo(int surahId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahId',
              lower: [],
              upper: [surahId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahId',
              lower: [surahId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahId',
              lower: [surahId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahId',
              lower: [],
              upper: [surahId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause>
      surahIdGreaterThan(
    int surahId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahId',
        lower: [surahId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> surahIdLessThan(
    int surahId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahId',
        lower: [],
        upper: [surahId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterWhereClause> surahIdBetween(
    int lowerSurahId,
    int upperSurahId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahId',
        lower: [lowerSurahId],
        includeLower: includeLower,
        upper: [upperSurahId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarV2SessionQueryFilter
    on QueryBuilder<IsarV2Session, IsarV2Session, QFilterCondition> {
  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      audienceIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audienceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      audienceIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audienceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      audienceIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audienceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      audienceIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audienceIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockAyahNumbersCsv',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockAyahNumbersCsv',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockAyahNumbersCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockAyahNumbersCsvIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockAyahNumbersCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      blockReviewRequiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockReviewRequired',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      currentAyahIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentAyahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      currentAyahIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentAyahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      currentAyahIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentAyahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      currentAyahIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentAyahIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failureCountsCsv',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'failureCountsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'failureCountsCsv',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failureCountsCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      failureCountsCsvIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'failureCountsCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hintLevelsCsv',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hintLevelsCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hintLevelsCsv',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hintLevelsCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      hintLevelsCsvIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hintLevelsCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownerId',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownerId',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'passedAyahNumbersCsv',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'passedAyahNumbersCsv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'passedAyahNumbersCsv',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passedAyahNumbersCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      passedAyahNumbersCsvIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'passedAyahNumbersCsv',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      phaseIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phaseIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      phaseIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phaseIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      phaseIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phaseIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      phaseIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phaseIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      savedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      savedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      savedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      savedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sessionKey',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sessionKey',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      sessionKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
      surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
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

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterFilterCondition>
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
}

extension IsarV2SessionQueryObject
    on QueryBuilder<IsarV2Session, IsarV2Session, QFilterCondition> {}

extension IsarV2SessionQueryLinks
    on QueryBuilder<IsarV2Session, IsarV2Session, QFilterCondition> {}

extension IsarV2SessionQuerySortBy
    on QueryBuilder<IsarV2Session, IsarV2Session, QSortBy> {
  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByAudienceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audienceIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByAudienceIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audienceIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByBlockAyahNumbersCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockAyahNumbersCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByBlockAyahNumbersCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockAyahNumbersCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByBlockReviewRequired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockReviewRequired', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByBlockReviewRequiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockReviewRequired', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByCurrentAyahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAyahIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByCurrentAyahIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAyahIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByFailureCountsCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCountsCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByFailureCountsCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCountsCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByHintLevelsCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelsCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByHintLevelsCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelsCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByPassedAyahNumbersCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passedAyahNumbersCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByPassedAyahNumbersCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passedAyahNumbersCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortByPhaseIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortByPhaseIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      sortBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarV2SessionQuerySortThenBy
    on QueryBuilder<IsarV2Session, IsarV2Session, QSortThenBy> {
  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByAudienceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audienceIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByAudienceIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audienceIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByBlockAyahNumbersCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockAyahNumbersCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByBlockAyahNumbersCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockAyahNumbersCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByBlockReviewRequired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockReviewRequired', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByBlockReviewRequiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockReviewRequired', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByCurrentAyahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAyahIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByCurrentAyahIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAyahIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByFailureCountsCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCountsCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByFailureCountsCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCountsCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByHintLevelsCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelsCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByHintLevelsCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelsCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByPassedAyahNumbersCsv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passedAyahNumbersCsv', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByPassedAyahNumbersCsvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passedAyahNumbersCsv', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenByPhaseIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenByPhaseIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phaseIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenBySessionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy>
      thenBySessionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionKey', Sort.desc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QAfterSortBy> thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarV2SessionQueryWhereDistinct
    on QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> {
  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByAudienceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audienceIndex');
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByBlockAyahNumbersCsv({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockAyahNumbersCsv',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByBlockReviewRequired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockReviewRequired');
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByCurrentAyahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentAyahIndex');
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByFailureCountsCsv({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failureCountsCsv',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctByHintLevelsCsv(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hintLevelsCsv',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctByOwnerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct>
      distinctByPassedAyahNumbersCsv({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'passedAyahNumbersCsv',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctByPhaseIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phaseIndex');
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedAt');
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctBySessionKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarV2Session, IsarV2Session, QDistinct> distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }
}

extension IsarV2SessionQueryProperty
    on QueryBuilder<IsarV2Session, IsarV2Session, QQueryProperty> {
  QueryBuilder<IsarV2Session, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarV2Session, int, QQueryOperations> audienceIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audienceIndex');
    });
  }

  QueryBuilder<IsarV2Session, String, QQueryOperations>
      blockAyahNumbersCsvProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockAyahNumbersCsv');
    });
  }

  QueryBuilder<IsarV2Session, bool, QQueryOperations>
      blockReviewRequiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockReviewRequired');
    });
  }

  QueryBuilder<IsarV2Session, int, QQueryOperations>
      currentAyahIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentAyahIndex');
    });
  }

  QueryBuilder<IsarV2Session, String, QQueryOperations>
      failureCountsCsvProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failureCountsCsv');
    });
  }

  QueryBuilder<IsarV2Session, String, QQueryOperations>
      hintLevelsCsvProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hintLevelsCsv');
    });
  }

  QueryBuilder<IsarV2Session, String?, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarV2Session, String, QQueryOperations>
      passedAyahNumbersCsvProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'passedAyahNumbersCsv');
    });
  }

  QueryBuilder<IsarV2Session, int, QQueryOperations> phaseIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phaseIndex');
    });
  }

  QueryBuilder<IsarV2Session, DateTime, QQueryOperations> savedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedAt');
    });
  }

  QueryBuilder<IsarV2Session, String?, QQueryOperations> sessionKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionKey');
    });
  }

  QueryBuilder<IsarV2Session, int, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }
}
