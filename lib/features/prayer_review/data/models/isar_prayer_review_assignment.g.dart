// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_prayer_review_assignment.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPrayerReviewAssignmentCollection on Isar {
  IsarCollection<IsarPrayerReviewAssignment> get isarPrayerReviewAssignments =>
      this.collection();
}

const IsarPrayerReviewAssignmentSchema = CollectionSchema(
  name: r'IsarPrayerReviewAssignment',
  id: 4043523637021582748,
  properties: {
    r'audience': PropertySchema(
      id: 0,
      name: r'audience',
      type: IsarType.string,
    ),
    r'endAyah': PropertySchema(id: 1, name: r'endAyah', type: IsarType.long),
    r'localDayKey': PropertySchema(
      id: 2,
      name: r'localDayKey',
      type: IsarType.string,
    ),
    r'occurrenceKey': PropertySchema(
      id: 3,
      name: r'occurrenceKey',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(id: 4, name: r'ownerId', type: IsarType.string),
    r'prayerKeyIndex': PropertySchema(
      id: 5,
      name: r'prayerKeyIndex',
      type: IsarType.long,
    ),
    r'promptConsumed': PropertySchema(
      id: 6,
      name: r'promptConsumed',
      type: IsarType.bool,
    ),
    r'scheduledAt': PropertySchema(
      id: 7,
      name: r'scheduledAt',
      type: IsarType.dateTime,
    ),
    r'selectedAt': PropertySchema(
      id: 8,
      name: r'selectedAt',
      type: IsarType.dateTime,
    ),
    r'selectionVersion': PropertySchema(
      id: 9,
      name: r'selectionVersion',
      type: IsarType.long,
    ),
    r'startAyah': PropertySchema(
      id: 10,
      name: r'startAyah',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(id: 11, name: r'surahId', type: IsarType.long),
  },

  estimateSize: _isarPrayerReviewAssignmentEstimateSize,
  serialize: _isarPrayerReviewAssignmentSerialize,
  deserialize: _isarPrayerReviewAssignmentDeserialize,
  deserializeProp: _isarPrayerReviewAssignmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerId_occurrenceKey': IndexSchema(
      id: -6298808498855172859,
      name: r'ownerId_occurrenceKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'occurrenceKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'localDayKey': IndexSchema(
      id: 7084490156530576704,
      name: r'localDayKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'localDayKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPrayerReviewAssignmentGetId,
  getLinks: _isarPrayerReviewAssignmentGetLinks,
  attach: _isarPrayerReviewAssignmentAttach,
  version: '3.3.2',
);

int _isarPrayerReviewAssignmentEstimateSize(
  IsarPrayerReviewAssignment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.audience.length * 3;
  bytesCount += 3 + object.localDayKey.length * 3;
  bytesCount += 3 + object.occurrenceKey.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  return bytesCount;
}

void _isarPrayerReviewAssignmentSerialize(
  IsarPrayerReviewAssignment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audience);
  writer.writeLong(offsets[1], object.endAyah);
  writer.writeString(offsets[2], object.localDayKey);
  writer.writeString(offsets[3], object.occurrenceKey);
  writer.writeString(offsets[4], object.ownerId);
  writer.writeLong(offsets[5], object.prayerKeyIndex);
  writer.writeBool(offsets[6], object.promptConsumed);
  writer.writeDateTime(offsets[7], object.scheduledAt);
  writer.writeDateTime(offsets[8], object.selectedAt);
  writer.writeLong(offsets[9], object.selectionVersion);
  writer.writeLong(offsets[10], object.startAyah);
  writer.writeLong(offsets[11], object.surahId);
}

IsarPrayerReviewAssignment _isarPrayerReviewAssignmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPrayerReviewAssignment();
  object.audience = reader.readString(offsets[0]);
  object.endAyah = reader.readLong(offsets[1]);
  object.id = id;
  object.localDayKey = reader.readString(offsets[2]);
  object.occurrenceKey = reader.readString(offsets[3]);
  object.ownerId = reader.readString(offsets[4]);
  object.prayerKeyIndex = reader.readLong(offsets[5]);
  object.promptConsumed = reader.readBool(offsets[6]);
  object.scheduledAt = reader.readDateTime(offsets[7]);
  object.selectedAt = reader.readDateTime(offsets[8]);
  object.selectionVersion = reader.readLong(offsets[9]);
  object.startAyah = reader.readLong(offsets[10]);
  object.surahId = reader.readLong(offsets[11]);
  return object;
}

P _isarPrayerReviewAssignmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPrayerReviewAssignmentGetId(IsarPrayerReviewAssignment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPrayerReviewAssignmentGetLinks(
  IsarPrayerReviewAssignment object,
) {
  return [];
}

void _isarPrayerReviewAssignmentAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPrayerReviewAssignment object,
) {
  object.id = id;
}

extension IsarPrayerReviewAssignmentByIndex
    on IsarCollection<IsarPrayerReviewAssignment> {
  Future<IsarPrayerReviewAssignment?> getByOwnerIdOccurrenceKey(
    String ownerId,
    String occurrenceKey,
  ) {
    return getByIndex(r'ownerId_occurrenceKey', [ownerId, occurrenceKey]);
  }

  IsarPrayerReviewAssignment? getByOwnerIdOccurrenceKeySync(
    String ownerId,
    String occurrenceKey,
  ) {
    return getByIndexSync(r'ownerId_occurrenceKey', [ownerId, occurrenceKey]);
  }

  Future<bool> deleteByOwnerIdOccurrenceKey(
    String ownerId,
    String occurrenceKey,
  ) {
    return deleteByIndex(r'ownerId_occurrenceKey', [ownerId, occurrenceKey]);
  }

  bool deleteByOwnerIdOccurrenceKeySync(String ownerId, String occurrenceKey) {
    return deleteByIndexSync(r'ownerId_occurrenceKey', [
      ownerId,
      occurrenceKey,
    ]);
  }

  Future<List<IsarPrayerReviewAssignment?>> getAllByOwnerIdOccurrenceKey(
    List<String> ownerIdValues,
    List<String> occurrenceKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      occurrenceKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], occurrenceKeyValues[i]]);
    }

    return getAllByIndex(r'ownerId_occurrenceKey', values);
  }

  List<IsarPrayerReviewAssignment?> getAllByOwnerIdOccurrenceKeySync(
    List<String> ownerIdValues,
    List<String> occurrenceKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      occurrenceKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], occurrenceKeyValues[i]]);
    }

    return getAllByIndexSync(r'ownerId_occurrenceKey', values);
  }

  Future<int> deleteAllByOwnerIdOccurrenceKey(
    List<String> ownerIdValues,
    List<String> occurrenceKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      occurrenceKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], occurrenceKeyValues[i]]);
    }

    return deleteAllByIndex(r'ownerId_occurrenceKey', values);
  }

  int deleteAllByOwnerIdOccurrenceKeySync(
    List<String> ownerIdValues,
    List<String> occurrenceKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      occurrenceKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], occurrenceKeyValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerId_occurrenceKey', values);
  }

  Future<Id> putByOwnerIdOccurrenceKey(IsarPrayerReviewAssignment object) {
    return putByIndex(r'ownerId_occurrenceKey', object);
  }

  Id putByOwnerIdOccurrenceKeySync(
    IsarPrayerReviewAssignment object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'ownerId_occurrenceKey',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByOwnerIdOccurrenceKey(
    List<IsarPrayerReviewAssignment> objects,
  ) {
    return putAllByIndex(r'ownerId_occurrenceKey', objects);
  }

  List<Id> putAllByOwnerIdOccurrenceKeySync(
    List<IsarPrayerReviewAssignment> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerId_occurrenceKey',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension IsarPrayerReviewAssignmentQueryWhereSort
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QWhere
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPrayerReviewAssignmentQueryWhere
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QWhereClause
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  ownerIdEqualToAnyOccurrenceKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_occurrenceKey',
          value: [ownerId],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  ownerIdNotEqualToAnyOccurrenceKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  ownerIdOccurrenceKeyEqualTo(String ownerId, String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_occurrenceKey',
          value: [ownerId, occurrenceKey],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  ownerIdEqualToOccurrenceKeyNotEqualTo(String ownerId, String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId],
                upper: [ownerId, occurrenceKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId, occurrenceKey],
                includeLower: false,
                upper: [ownerId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId, occurrenceKey],
                includeLower: false,
                upper: [ownerId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_occurrenceKey',
                lower: [ownerId],
                upper: [ownerId, occurrenceKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  localDayKeyEqualTo(String localDayKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'localDayKey',
          value: [localDayKey],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterWhereClause
  >
  localDayKeyNotEqualTo(String localDayKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDayKey',
                lower: [],
                upper: [localDayKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDayKey',
                lower: [localDayKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDayKey',
                lower: [localDayKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDayKey',
                lower: [],
                upper: [localDayKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarPrayerReviewAssignmentQueryFilter
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QFilterCondition
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'audience',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'audience',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'audience',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'audience', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  audienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'audience', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  endAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endAyah', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  endAyahGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  endAyahLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  endAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endAyah',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localDayKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localDayKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localDayKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  localDayKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localDayKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurrenceKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'occurrenceKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurrenceKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  occurrenceKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'occurrenceKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  prayerKeyIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'prayerKeyIndex', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  prayerKeyIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'prayerKeyIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  prayerKeyIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'prayerKeyIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  prayerKeyIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'prayerKeyIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  promptConsumedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'promptConsumed', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  scheduledAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scheduledAt', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  scheduledAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scheduledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  scheduledAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scheduledAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  scheduledAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scheduledAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectedAt', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectionVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectionVersion', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectionVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectionVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectionVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectionVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  selectionVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectionVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  startAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startAyah', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  startAyahGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  startAyahLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  startAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startAyah',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surahId', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  surahIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'surahId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  surahIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'surahId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterFilterCondition
  >
  surahIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'surahId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarPrayerReviewAssignmentQueryObject
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QFilterCondition
        > {}

extension IsarPrayerReviewAssignmentQueryLinks
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QFilterCondition
        > {}

extension IsarPrayerReviewAssignmentQuerySortBy
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QSortBy
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByPrayerKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByPromptConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptConsumed', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByPromptConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptConsumed', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySelectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAt', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySelectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAt', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySelectionVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionVersion', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySelectionVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionVersion', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarPrayerReviewAssignmentQuerySortThenBy
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QSortThenBy
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByPrayerKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByPromptConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptConsumed', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByPromptConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptConsumed', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySelectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAt', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySelectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedAt', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySelectionVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionVersion', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySelectionVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionVersion', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QAfterSortBy
  >
  thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarPrayerReviewAssignmentQueryWhereDistinct
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QDistinct
        > {
  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAyah');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByLocalDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localDayKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByOccurrenceKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'occurrenceKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prayerKeyIndex');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByPromptConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptConsumed');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAt');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctBySelectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedAt');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctBySelectionVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectionVersion');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAyah');
    });
  }

  QueryBuilder<
    IsarPrayerReviewAssignment,
    IsarPrayerReviewAssignment,
    QDistinct
  >
  distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }
}

extension IsarPrayerReviewAssignmentQueryProperty
    on
        QueryBuilder<
          IsarPrayerReviewAssignment,
          IsarPrayerReviewAssignment,
          QQueryProperty
        > {
  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, String, QQueryOperations>
  audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations>
  endAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, String, QQueryOperations>
  localDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDayKey');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, String, QQueryOperations>
  occurrenceKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurrenceKey');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, String, QQueryOperations>
  ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations>
  prayerKeyIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prayerKeyIndex');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, bool, QQueryOperations>
  promptConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptConsumed');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, DateTime, QQueryOperations>
  scheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAt');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, DateTime, QQueryOperations>
  selectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedAt');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations>
  selectionVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectionVersion');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations>
  startAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewAssignment, int, QQueryOperations>
  surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }
}
