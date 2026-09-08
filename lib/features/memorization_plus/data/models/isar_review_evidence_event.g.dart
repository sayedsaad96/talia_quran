// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_review_evidence_event.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarReviewEvidenceEventCollection on Isar {
  IsarCollection<IsarReviewEvidenceEvent> get isarReviewEvidenceEvents =>
      this.collection();
}

const IsarReviewEvidenceEventSchema = CollectionSchema(
  name: r'IsarReviewEvidenceEvent',
  id: -5282177055901081271,
  properties: {
    r'assessmentIndex': PropertySchema(
      id: 0,
      name: r'assessmentIndex',
      type: IsarType.long,
    ),
    r'attemptCount': PropertySchema(
      id: 1,
      name: r'attemptCount',
      type: IsarType.long,
    ),
    r'audience': PropertySchema(
      id: 2,
      name: r'audience',
      type: IsarType.string,
    ),
    r'ayahNumber': PropertySchema(
      id: 3,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'committedAt': PropertySchema(
      id: 4,
      name: r'committedAt',
      type: IsarType.dateTime,
    ),
    r'eventId': PropertySchema(
      id: 5,
      name: r'eventId',
      type: IsarType.string,
    ),
    r'eventTypeIndex': PropertySchema(
      id: 6,
      name: r'eventTypeIndex',
      type: IsarType.long,
    ),
    r'failureCount': PropertySchema(
      id: 7,
      name: r'failureCount',
      type: IsarType.long,
    ),
    r'hintLevelIndex': PropertySchema(
      id: 8,
      name: r'hintLevelIndex',
      type: IsarType.long,
    ),
    r'idempotencyKey': PropertySchema(
      id: 9,
      name: r'idempotencyKey',
      type: IsarType.string,
    ),
    r'occurredAt': PropertySchema(
      id: 10,
      name: r'occurredAt',
      type: IsarType.dateTime,
    ),
    r'outcomeIndex': PropertySchema(
      id: 11,
      name: r'outcomeIndex',
      type: IsarType.long,
    ),
    r'ownerId': PropertySchema(
      id: 12,
      name: r'ownerId',
      type: IsarType.string,
    ),
    r'ratingIndex': PropertySchema(
      id: 13,
      name: r'ratingIndex',
      type: IsarType.long,
    ),
    r'sessionId': PropertySchema(
      id: 14,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'similarityScore': PropertySchema(
      id: 15,
      name: r'similarityScore',
      type: IsarType.double,
    ),
    r'studyDayKey': PropertySchema(
      id: 16,
      name: r'studyDayKey',
      type: IsarType.string,
    ),
    r'surahId': PropertySchema(
      id: 17,
      name: r'surahId',
      type: IsarType.long,
    ),
    r'taskId': PropertySchema(
      id: 18,
      name: r'taskId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarReviewEvidenceEventEstimateSize,
  serialize: _isarReviewEvidenceEventSerialize,
  deserialize: _isarReviewEvidenceEventDeserialize,
  deserializeProp: _isarReviewEvidenceEventDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventId': IndexSchema(
      id: -2707901133518603130,
      name: r'eventId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'idempotencyKey': IndexSchema(
      id: 6522471565226449816,
      name: r'idempotencyKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'idempotencyKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarReviewEvidenceEventGetId,
  getLinks: _isarReviewEvidenceEventGetLinks,
  attach: _isarReviewEvidenceEventAttach,
  version: '3.1.0+1',
);

int _isarReviewEvidenceEventEstimateSize(
  IsarReviewEvidenceEvent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.audience.length * 3;
  bytesCount += 3 + object.eventId.length * 3;
  bytesCount += 3 + object.idempotencyKey.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  bytesCount += 3 + object.studyDayKey.length * 3;
  bytesCount += 3 + object.taskId.length * 3;
  return bytesCount;
}

void _isarReviewEvidenceEventSerialize(
  IsarReviewEvidenceEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.assessmentIndex);
  writer.writeLong(offsets[1], object.attemptCount);
  writer.writeString(offsets[2], object.audience);
  writer.writeLong(offsets[3], object.ayahNumber);
  writer.writeDateTime(offsets[4], object.committedAt);
  writer.writeString(offsets[5], object.eventId);
  writer.writeLong(offsets[6], object.eventTypeIndex);
  writer.writeLong(offsets[7], object.failureCount);
  writer.writeLong(offsets[8], object.hintLevelIndex);
  writer.writeString(offsets[9], object.idempotencyKey);
  writer.writeDateTime(offsets[10], object.occurredAt);
  writer.writeLong(offsets[11], object.outcomeIndex);
  writer.writeString(offsets[12], object.ownerId);
  writer.writeLong(offsets[13], object.ratingIndex);
  writer.writeString(offsets[14], object.sessionId);
  writer.writeDouble(offsets[15], object.similarityScore);
  writer.writeString(offsets[16], object.studyDayKey);
  writer.writeLong(offsets[17], object.surahId);
  writer.writeString(offsets[18], object.taskId);
}

IsarReviewEvidenceEvent _isarReviewEvidenceEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarReviewEvidenceEvent();
  object.assessmentIndex = reader.readLong(offsets[0]);
  object.attemptCount = reader.readLong(offsets[1]);
  object.audience = reader.readString(offsets[2]);
  object.ayahNumber = reader.readLong(offsets[3]);
  object.committedAt = reader.readDateTime(offsets[4]);
  object.eventId = reader.readString(offsets[5]);
  object.eventTypeIndex = reader.readLong(offsets[6]);
  object.failureCount = reader.readLong(offsets[7]);
  object.hintLevelIndex = reader.readLong(offsets[8]);
  object.id = id;
  object.idempotencyKey = reader.readString(offsets[9]);
  object.occurredAt = reader.readDateTime(offsets[10]);
  object.outcomeIndex = reader.readLong(offsets[11]);
  object.ownerId = reader.readString(offsets[12]);
  object.ratingIndex = reader.readLongOrNull(offsets[13]);
  object.sessionId = reader.readString(offsets[14]);
  object.similarityScore = reader.readDoubleOrNull(offsets[15]);
  object.studyDayKey = reader.readString(offsets[16]);
  object.surahId = reader.readLong(offsets[17]);
  object.taskId = reader.readString(offsets[18]);
  return object;
}

P _isarReviewEvidenceEventDeserializeProp<P>(
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
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarReviewEvidenceEventGetId(IsarReviewEvidenceEvent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarReviewEvidenceEventGetLinks(
    IsarReviewEvidenceEvent object) {
  return [];
}

void _isarReviewEvidenceEventAttach(
    IsarCollection<dynamic> col, Id id, IsarReviewEvidenceEvent object) {
  object.id = id;
}

extension IsarReviewEvidenceEventByIndex
    on IsarCollection<IsarReviewEvidenceEvent> {
  Future<IsarReviewEvidenceEvent?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  IsarReviewEvidenceEvent? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<IsarReviewEvidenceEvent?>> getAllByEventId(
      List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<IsarReviewEvidenceEvent?> getAllByEventIdSync(
      List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventId', values);
  }

  Future<int> deleteAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventId', values);
  }

  int deleteAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventId', values);
  }

  Future<Id> putByEventId(IsarReviewEvidenceEvent object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(IsarReviewEvidenceEvent object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<IsarReviewEvidenceEvent> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(List<IsarReviewEvidenceEvent> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }

  Future<IsarReviewEvidenceEvent?> getByIdempotencyKey(String idempotencyKey) {
    return getByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  IsarReviewEvidenceEvent? getByIdempotencyKeySync(String idempotencyKey) {
    return getByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<bool> deleteByIdempotencyKey(String idempotencyKey) {
    return deleteByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  bool deleteByIdempotencyKeySync(String idempotencyKey) {
    return deleteByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<List<IsarReviewEvidenceEvent?>> getAllByIdempotencyKey(
      List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'idempotencyKey', values);
  }

  List<IsarReviewEvidenceEvent?> getAllByIdempotencyKeySync(
      List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'idempotencyKey', values);
  }

  Future<int> deleteAllByIdempotencyKey(List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'idempotencyKey', values);
  }

  int deleteAllByIdempotencyKeySync(List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'idempotencyKey', values);
  }

  Future<Id> putByIdempotencyKey(IsarReviewEvidenceEvent object) {
    return putByIndex(r'idempotencyKey', object);
  }

  Id putByIdempotencyKeySync(IsarReviewEvidenceEvent object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'idempotencyKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdempotencyKey(
      List<IsarReviewEvidenceEvent> objects) {
    return putAllByIndex(r'idempotencyKey', objects);
  }

  List<Id> putAllByIdempotencyKeySync(List<IsarReviewEvidenceEvent> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'idempotencyKey', objects, saveLinks: saveLinks);
  }
}

extension IsarReviewEvidenceEventQueryWhereSort
    on QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QWhere> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarReviewEvidenceEventQueryWhere on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QWhereClause> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventId',
        value: [eventId],
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> idempotencyKeyEqualTo(String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'idempotencyKey',
        value: [idempotencyKey],
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> idempotencyKeyNotEqualTo(String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [],
              upper: [idempotencyKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [idempotencyKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [idempotencyKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [],
              upper: [idempotencyKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> ownerIdEqualTo(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerId',
        value: [ownerId],
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterWhereClause> audienceEqualTo(String audience) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'audience',
        value: [audience],
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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
}

extension IsarReviewEvidenceEventQueryFilter on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QFilterCondition> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> assessmentIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assessmentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> assessmentIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assessmentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> assessmentIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assessmentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> assessmentIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assessmentIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> attemptCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> attemptCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> attemptCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> attemptCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> audienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audience',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> audienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audience',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> committedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'committedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> committedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'committedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> committedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'committedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> committedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'committedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventTypeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventTypeIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventTypeIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> eventTypeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventTypeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> failureCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> failureCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> failureCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failureCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> failureCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failureCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> hintLevelIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hintLevelIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> hintLevelIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hintLevelIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> hintLevelIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hintLevelIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> hintLevelIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hintLevelIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idempotencyKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      idempotencyKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      idempotencyKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idempotencyKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> idempotencyKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> occurredAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occurredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> occurredAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'occurredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> occurredAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'occurredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> occurredAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'occurredAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> outcomeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outcomeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> outcomeIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outcomeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> outcomeIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outcomeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> outcomeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outcomeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ratingIndex',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ratingIndex',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ratingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ratingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ratingIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> ratingIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ratingIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'similarityScore',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'similarityScore',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'similarityScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'similarityScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'similarityScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> similarityScoreBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'similarityScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studyDayKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      studyDayKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studyDayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      studyDayKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studyDayKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studyDayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> studyDayKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studyDayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
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

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      taskIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
          QAfterFilterCondition>
      taskIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taskId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent,
      QAfterFilterCondition> taskIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taskId',
        value: '',
      ));
    });
  }
}

extension IsarReviewEvidenceEventQueryObject on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QFilterCondition> {}

extension IsarReviewEvidenceEventQueryLinks on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QFilterCondition> {}

extension IsarReviewEvidenceEventQuerySortBy
    on QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QSortBy> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAssessmentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessmentIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAssessmentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessmentIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByCommittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByEventTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByEventTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventTypeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByHintLevelIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByHintLevelIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOutcomeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outcomeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOutcomeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outcomeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByRatingIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarityScore', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySimilarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarityScore', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByStudyDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studyDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByStudyDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studyDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      sortByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }
}

extension IsarReviewEvidenceEventQuerySortThenBy on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QSortThenBy> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAssessmentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessmentIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAssessmentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessmentIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByCommittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByEventTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByEventTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventTypeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByFailureCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureCount', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByHintLevelIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByHintLevelIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hintLevelIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOutcomeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outcomeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOutcomeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outcomeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByRatingIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ratingIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarityScore', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySimilarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarityScore', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByStudyDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studyDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByStudyDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studyDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QAfterSortBy>
      thenByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }
}

extension IsarReviewEvidenceEventQueryWhereDistinct on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct> {
  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByAssessmentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assessmentIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptCount');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'committedAt');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByEventTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventTypeIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByFailureCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failureCount');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByHintLevelIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hintLevelIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByIdempotencyKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idempotencyKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurredAt');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByOutcomeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outcomeIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByRatingIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ratingIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctBySessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'similarityScore');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByStudyDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studyDayKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QDistinct>
      distinctByTaskId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskId', caseSensitive: caseSensitive);
    });
  }
}

extension IsarReviewEvidenceEventQueryProperty on QueryBuilder<
    IsarReviewEvidenceEvent, IsarReviewEvidenceEvent, QQueryProperty> {
  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      assessmentIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assessmentIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      attemptCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptCount');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, DateTime, QQueryOperations>
      committedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'committedAt');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      eventTypeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventTypeIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      failureCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failureCount');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      hintLevelIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hintLevelIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      idempotencyKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idempotencyKey');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, DateTime, QQueryOperations>
      occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurredAt');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      outcomeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outcomeIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int?, QQueryOperations>
      ratingIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ratingIndex');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, double?, QQueryOperations>
      similarityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'similarityScore');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      studyDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studyDayKey');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, int, QQueryOperations>
      surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }

  QueryBuilder<IsarReviewEvidenceEvent, String, QQueryOperations>
      taskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskId');
    });
  }
}
