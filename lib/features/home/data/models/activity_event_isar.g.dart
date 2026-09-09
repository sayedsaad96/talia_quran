// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_event_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActivityEventIsarCollection on Isar {
  IsarCollection<ActivityEventIsar> get activityEventIsars => this.collection();
}

const ActivityEventIsarSchema = CollectionSchema(
  name: r'ActivityEventIsar',
  id: 424492633121375811,
  properties: {
    r'endAyah': PropertySchema(
      id: 0,
      name: r'endAyah',
      type: IsarType.long,
    ),
    r'idempotencyKey': PropertySchema(
      id: 1,
      name: r'idempotencyKey',
      type: IsarType.string,
    ),
    r'kindIndex': PropertySchema(
      id: 2,
      name: r'kindIndex',
      type: IsarType.long,
    ),
    r'occurredAt': PropertySchema(
      id: 3,
      name: r'occurredAt',
      type: IsarType.dateTime,
    ),
    r'pageNumber': PropertySchema(
      id: 4,
      name: r'pageNumber',
      type: IsarType.long,
    ),
    r'startAyah': PropertySchema(
      id: 5,
      name: r'startAyah',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(
      id: 6,
      name: r'surahId',
      type: IsarType.long,
    )
  },
  estimateSize: _activityEventIsarEstimateSize,
  serialize: _activityEventIsarSerialize,
  deserialize: _activityEventIsarDeserialize,
  deserializeProp: _activityEventIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'occurredAt': IndexSchema(
      id: 1229694562040044173,
      name: r'occurredAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurredAt',
          type: IndexType.value,
          caseSensitive: false,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _activityEventIsarGetId,
  getLinks: _activityEventIsarGetLinks,
  attach: _activityEventIsarAttach,
  version: '3.1.0+1',
);

int _activityEventIsarEstimateSize(
  ActivityEventIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.idempotencyKey.length * 3;
  return bytesCount;
}

void _activityEventIsarSerialize(
  ActivityEventIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endAyah);
  writer.writeString(offsets[1], object.idempotencyKey);
  writer.writeLong(offsets[2], object.kindIndex);
  writer.writeDateTime(offsets[3], object.occurredAt);
  writer.writeLong(offsets[4], object.pageNumber);
  writer.writeLong(offsets[5], object.startAyah);
  writer.writeLong(offsets[6], object.surahId);
}

ActivityEventIsar _activityEventIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActivityEventIsar();
  object.endAyah = reader.readLongOrNull(offsets[0]);
  object.id = id;
  object.idempotencyKey = reader.readString(offsets[1]);
  object.kindIndex = reader.readLong(offsets[2]);
  object.occurredAt = reader.readDateTime(offsets[3]);
  object.pageNumber = reader.readLongOrNull(offsets[4]);
  object.startAyah = reader.readLongOrNull(offsets[5]);
  object.surahId = reader.readLongOrNull(offsets[6]);
  return object;
}

P _activityEventIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _activityEventIsarGetId(ActivityEventIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _activityEventIsarGetLinks(
    ActivityEventIsar object) {
  return [];
}

void _activityEventIsarAttach(
    IsarCollection<dynamic> col, Id id, ActivityEventIsar object) {
  object.id = id;
}

extension ActivityEventIsarByIndex on IsarCollection<ActivityEventIsar> {
  Future<ActivityEventIsar?> getByIdempotencyKey(String idempotencyKey) {
    return getByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  ActivityEventIsar? getByIdempotencyKeySync(String idempotencyKey) {
    return getByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<bool> deleteByIdempotencyKey(String idempotencyKey) {
    return deleteByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  bool deleteByIdempotencyKeySync(String idempotencyKey) {
    return deleteByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<List<ActivityEventIsar?>> getAllByIdempotencyKey(
      List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'idempotencyKey', values);
  }

  List<ActivityEventIsar?> getAllByIdempotencyKeySync(
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

  Future<Id> putByIdempotencyKey(ActivityEventIsar object) {
    return putByIndex(r'idempotencyKey', object);
  }

  Id putByIdempotencyKeySync(ActivityEventIsar object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'idempotencyKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdempotencyKey(List<ActivityEventIsar> objects) {
    return putAllByIndex(r'idempotencyKey', objects);
  }

  List<Id> putAllByIdempotencyKeySync(List<ActivityEventIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'idempotencyKey', objects, saveLinks: saveLinks);
  }
}

extension ActivityEventIsarQueryWhereSort
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QWhere> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhere>
      anyOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'occurredAt'),
      );
    });
  }
}

extension ActivityEventIsarQueryWhere
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QWhereClause> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      occurredAtEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'occurredAt',
        value: [occurredAt],
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      occurredAtNotEqualTo(DateTime occurredAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'occurredAt',
              lower: [],
              upper: [occurredAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'occurredAt',
              lower: [occurredAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'occurredAt',
              lower: [occurredAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'occurredAt',
              lower: [],
              upper: [occurredAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      occurredAtGreaterThan(
    DateTime occurredAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'occurredAt',
        lower: [occurredAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      occurredAtLessThan(
    DateTime occurredAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'occurredAt',
        lower: [],
        upper: [occurredAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      occurredAtBetween(
    DateTime lowerOccurredAt,
    DateTime upperOccurredAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'occurredAt',
        lower: [lowerOccurredAt],
        includeLower: includeLower,
        upper: [upperOccurredAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      idempotencyKeyEqualTo(String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'idempotencyKey',
        value: [idempotencyKey],
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterWhereClause>
      idempotencyKeyNotEqualTo(String idempotencyKey) {
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
}

extension ActivityEventIsarQueryFilter
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QFilterCondition> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endAyah',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endAyah',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      endAyahBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endAyah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyEqualTo(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyGreaterThan(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyLessThan(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyBetween(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyStartsWith(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyEndsWith(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idempotencyKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      idempotencyKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      kindIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kindIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      kindIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kindIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      kindIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kindIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      kindIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kindIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      occurredAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occurredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      occurredAtGreaterThan(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      occurredAtLessThan(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      occurredAtBetween(
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pageNumber',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pageNumber',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      pageNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pageNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startAyah',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startAyah',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      startAyahBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startAyah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'surahId',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'surahId',
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahId',
        value: value,
      ));
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdGreaterThan(
    int? value, {
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdLessThan(
    int? value, {
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

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterFilterCondition>
      surahIdBetween(
    int? lower,
    int? upper, {
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

extension ActivityEventIsarQueryObject
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QFilterCondition> {}

extension ActivityEventIsarQueryLinks
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QFilterCondition> {}

extension ActivityEventIsarQuerySortBy
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QSortBy> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindIndex', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByKindIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindIndex', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByPageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension ActivityEventIsarQuerySortThenBy
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QSortThenBy> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindIndex', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByKindIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindIndex', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByPageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QAfterSortBy>
      thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension ActivityEventIsarQueryWhereDistinct
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct> {
  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAyah');
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByIdempotencyKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idempotencyKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kindIndex');
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurredAt');
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageNumber');
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAyah');
    });
  }

  QueryBuilder<ActivityEventIsar, ActivityEventIsar, QDistinct>
      distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }
}

extension ActivityEventIsarQueryProperty
    on QueryBuilder<ActivityEventIsar, ActivityEventIsar, QQueryProperty> {
  QueryBuilder<ActivityEventIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActivityEventIsar, int?, QQueryOperations> endAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAyah');
    });
  }

  QueryBuilder<ActivityEventIsar, String, QQueryOperations>
      idempotencyKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idempotencyKey');
    });
  }

  QueryBuilder<ActivityEventIsar, int, QQueryOperations> kindIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kindIndex');
    });
  }

  QueryBuilder<ActivityEventIsar, DateTime, QQueryOperations>
      occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurredAt');
    });
  }

  QueryBuilder<ActivityEventIsar, int?, QQueryOperations> pageNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageNumber');
    });
  }

  QueryBuilder<ActivityEventIsar, int?, QQueryOperations> startAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAyah');
    });
  }

  QueryBuilder<ActivityEventIsar, int?, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }
}
