// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_review_effect_outbox.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarReviewEffectOutboxCollection on Isar {
  IsarCollection<IsarReviewEffectOutbox> get isarReviewEffectOutboxs =>
      this.collection();
}

const IsarReviewEffectOutboxSchema = CollectionSchema(
  name: r'IsarReviewEffectOutbox',
  id: 53244479066559025,
  properties: {
    r'activityDelta': PropertySchema(
      id: 0,
      name: r'activityDelta',
      type: IsarType.long,
    ),
    r'attempts': PropertySchema(
      id: 1,
      name: r'attempts',
      type: IsarType.long,
    ),
    r'audience': PropertySchema(
      id: 2,
      name: r'audience',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'effectType': PropertySchema(
      id: 4,
      name: r'effectType',
      type: IsarType.string,
    ),
    r'eventId': PropertySchema(
      id: 5,
      name: r'eventId',
      type: IsarType.string,
    ),
    r'lastErrorCode': PropertySchema(
      id: 6,
      name: r'lastErrorCode',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(
      id: 7,
      name: r'ownerId',
      type: IsarType.string,
    ),
    r'processedAt': PropertySchema(
      id: 8,
      name: r'processedAt',
      type: IsarType.dateTime,
    ),
    r'receiptKey': PropertySchema(
      id: 9,
      name: r'receiptKey',
      type: IsarType.string,
    )
  },
  estimateSize: _isarReviewEffectOutboxEstimateSize,
  serialize: _isarReviewEffectOutboxSerialize,
  deserialize: _isarReviewEffectOutboxDeserialize,
  deserializeProp: _isarReviewEffectOutboxDeserializeProp,
  idName: r'id',
  indexes: {
    r'receiptKey': IndexSchema(
      id: 7980183524993110611,
      name: r'receiptKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'receiptKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'eventId': IndexSchema(
      id: -2707901133518603130,
      name: r'eventId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'ownerId': IndexSchema(
      id: -7594796109721319539,
      name: r'ownerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
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
    ),
    r'effectType': IndexSchema(
      id: -765793661038795580,
      name: r'effectType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'effectType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarReviewEffectOutboxGetId,
  getLinks: _isarReviewEffectOutboxGetLinks,
  attach: _isarReviewEffectOutboxAttach,
  version: '3.1.0+1',
);

int _isarReviewEffectOutboxEstimateSize(
  IsarReviewEffectOutbox object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.audience.length * 3;
  bytesCount += 3 + object.effectType.length * 3;
  bytesCount += 3 + object.eventId.length * 3;
  {
    final value = object.lastErrorCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerId.length * 3;
  bytesCount += 3 + object.receiptKey.length * 3;
  return bytesCount;
}

void _isarReviewEffectOutboxSerialize(
  IsarReviewEffectOutbox object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.activityDelta);
  writer.writeLong(offsets[1], object.attempts);
  writer.writeString(offsets[2], object.audience);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.effectType);
  writer.writeString(offsets[5], object.eventId);
  writer.writeString(offsets[6], object.lastErrorCode);
  writer.writeString(offsets[7], object.ownerId);
  writer.writeDateTime(offsets[8], object.processedAt);
  writer.writeString(offsets[9], object.receiptKey);
}

IsarReviewEffectOutbox _isarReviewEffectOutboxDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarReviewEffectOutbox();
  object.activityDelta = reader.readLongOrNull(offsets[0]);
  object.attempts = reader.readLong(offsets[1]);
  object.audience = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.effectType = reader.readString(offsets[4]);
  object.eventId = reader.readString(offsets[5]);
  object.id = id;
  object.lastErrorCode = reader.readStringOrNull(offsets[6]);
  object.ownerId = reader.readString(offsets[7]);
  object.processedAt = reader.readDateTimeOrNull(offsets[8]);
  object.receiptKey = reader.readString(offsets[9]);
  return object;
}

P _isarReviewEffectOutboxDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarReviewEffectOutboxGetId(IsarReviewEffectOutbox object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarReviewEffectOutboxGetLinks(
    IsarReviewEffectOutbox object) {
  return [];
}

void _isarReviewEffectOutboxAttach(
    IsarCollection<dynamic> col, Id id, IsarReviewEffectOutbox object) {
  object.id = id;
}

extension IsarReviewEffectOutboxByIndex
    on IsarCollection<IsarReviewEffectOutbox> {
  Future<IsarReviewEffectOutbox?> getByReceiptKey(String receiptKey) {
    return getByIndex(r'receiptKey', [receiptKey]);
  }

  IsarReviewEffectOutbox? getByReceiptKeySync(String receiptKey) {
    return getByIndexSync(r'receiptKey', [receiptKey]);
  }

  Future<bool> deleteByReceiptKey(String receiptKey) {
    return deleteByIndex(r'receiptKey', [receiptKey]);
  }

  bool deleteByReceiptKeySync(String receiptKey) {
    return deleteByIndexSync(r'receiptKey', [receiptKey]);
  }

  Future<List<IsarReviewEffectOutbox?>> getAllByReceiptKey(
      List<String> receiptKeyValues) {
    final values = receiptKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'receiptKey', values);
  }

  List<IsarReviewEffectOutbox?> getAllByReceiptKeySync(
      List<String> receiptKeyValues) {
    final values = receiptKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'receiptKey', values);
  }

  Future<int> deleteAllByReceiptKey(List<String> receiptKeyValues) {
    final values = receiptKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'receiptKey', values);
  }

  int deleteAllByReceiptKeySync(List<String> receiptKeyValues) {
    final values = receiptKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'receiptKey', values);
  }

  Future<Id> putByReceiptKey(IsarReviewEffectOutbox object) {
    return putByIndex(r'receiptKey', object);
  }

  Id putByReceiptKeySync(IsarReviewEffectOutbox object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'receiptKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByReceiptKey(List<IsarReviewEffectOutbox> objects) {
    return putAllByIndex(r'receiptKey', objects);
  }

  List<Id> putAllByReceiptKeySync(List<IsarReviewEffectOutbox> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'receiptKey', objects, saveLinks: saveLinks);
  }
}

extension IsarReviewEffectOutboxQueryWhereSort
    on QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QWhere> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarReviewEffectOutboxQueryWhere on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QWhereClause> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> receiptKeyEqualTo(String receiptKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'receiptKey',
        value: [receiptKey],
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> receiptKeyNotEqualTo(String receiptKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiptKey',
              lower: [],
              upper: [receiptKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiptKey',
              lower: [receiptKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiptKey',
              lower: [receiptKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receiptKey',
              lower: [],
              upper: [receiptKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventId',
        value: [eventId],
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> eventIdNotEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventId',
              lower: [],
              upper: [eventId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventId',
              lower: [eventId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventId',
              lower: [eventId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventId',
              lower: [],
              upper: [eventId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> ownerIdEqualTo(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerId',
        value: [ownerId],
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> ownerIdNotEqualTo(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerId',
              lower: [],
              upper: [ownerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerId',
              lower: [ownerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerId',
              lower: [ownerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerId',
              lower: [],
              upper: [ownerId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> audienceEqualTo(String audience) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'audience',
        value: [audience],
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> audienceNotEqualTo(String audience) {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> effectTypeEqualTo(String effectType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'effectType',
        value: [effectType],
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterWhereClause> effectTypeNotEqualTo(String effectType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'effectType',
              lower: [],
              upper: [effectType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'effectType',
              lower: [effectType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'effectType',
              lower: [effectType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'effectType',
              lower: [],
              upper: [effectType],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarReviewEffectOutboxQueryFilter on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QFilterCondition> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'activityDelta',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'activityDelta',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityDelta',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityDelta',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityDelta',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> activityDeltaBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityDelta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> attemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> attemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceEqualTo(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceGreaterThan(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceLessThan(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audience',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> audienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audience',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      effectTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'effectType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      effectTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'effectType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> effectTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'effectType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      eventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      eventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastErrorCode',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastErrorCode',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastErrorCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      lastErrorCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastErrorCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      lastErrorCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastErrorCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastErrorCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> lastErrorCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastErrorCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdEqualTo(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdGreaterThan(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdLessThan(
    String value, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdStartsWith(
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdEndsWith(
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

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      ownerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      ownerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> processedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      receiptKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
          QAfterFilterCondition>
      receiptKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox,
      QAfterFilterCondition> receiptKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptKey',
        value: '',
      ));
    });
  }
}

extension IsarReviewEffectOutboxQueryObject on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QFilterCondition> {}

extension IsarReviewEffectOutboxQueryLinks on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QFilterCondition> {}

extension IsarReviewEffectOutboxQuerySortBy
    on QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QSortBy> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByActivityDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityDelta', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByActivityDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityDelta', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByEffectType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectType', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByEffectTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectType', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByLastErrorCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastErrorCode', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByLastErrorCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastErrorCode', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByReceiptKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      sortByReceiptKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.desc);
    });
  }
}

extension IsarReviewEffectOutboxQuerySortThenBy on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QSortThenBy> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByActivityDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityDelta', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByActivityDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityDelta', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByEffectType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectType', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByEffectTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectType', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByLastErrorCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastErrorCode', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByLastErrorCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastErrorCode', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByReceiptKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QAfterSortBy>
      thenByReceiptKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.desc);
    });
  }
}

extension IsarReviewEffectOutboxQueryWhereDistinct
    on QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct> {
  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByActivityDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityDelta');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByEffectType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByLastErrorCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastErrorCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processedAt');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, IsarReviewEffectOutbox, QDistinct>
      distinctByReceiptKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptKey', caseSensitive: caseSensitive);
    });
  }
}

extension IsarReviewEffectOutboxQueryProperty on QueryBuilder<
    IsarReviewEffectOutbox, IsarReviewEffectOutbox, QQueryProperty> {
  QueryBuilder<IsarReviewEffectOutbox, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, int?, QQueryOperations>
      activityDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityDelta');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, int, QQueryOperations>
      attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String, QQueryOperations>
      audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String, QQueryOperations>
      effectTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectType');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String, QQueryOperations>
      eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String?, QQueryOperations>
      lastErrorCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastErrorCode');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String, QQueryOperations>
      ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, DateTime?, QQueryOperations>
      processedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processedAt');
    });
  }

  QueryBuilder<IsarReviewEffectOutbox, String, QQueryOperations>
      receiptKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptKey');
    });
  }
}
