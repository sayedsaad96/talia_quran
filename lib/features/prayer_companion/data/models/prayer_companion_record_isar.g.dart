// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_companion_record_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrayerCompanionRecordIsarCollection on Isar {
  IsarCollection<PrayerCompanionRecordIsar> get prayerCompanionRecordIsars =>
      this.collection();
}

const PrayerCompanionRecordIsarSchema = CollectionSchema(
  name: r'PrayerCompanionRecordIsar',
  id: 8556106318516769141,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'followUpAt': PropertySchema(
      id: 1,
      name: r'followUpAt',
      type: IsarType.dateTime,
    ),
    r'followUpCount': PropertySchema(
      id: 2,
      name: r'followUpCount',
      type: IsarType.long,
    ),
    r'localDayKey': PropertySchema(
      id: 3,
      name: r'localDayKey',
      type: IsarType.long,
    ),
    r'occurrenceKey': PropertySchema(
      id: 4,
      name: r'occurrenceKey',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(id: 5, name: r'ownerId', type: IsarType.string),
    r'prayerKeyIndex': PropertySchema(
      id: 6,
      name: r'prayerKeyIndex',
      type: IsarType.long,
    ),
    r'scheduledAt': PropertySchema(
      id: 7,
      name: r'scheduledAt',
      type: IsarType.dateTime,
    ),
    r'statusIndex': PropertySchema(
      id: 8,
      name: r'statusIndex',
      type: IsarType.long,
    ),
    r'statusUpdatedAt': PropertySchema(
      id: 9,
      name: r'statusUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _prayerCompanionRecordIsarEstimateSize,
  serialize: _prayerCompanionRecordIsarSerialize,
  deserialize: _prayerCompanionRecordIsarDeserialize,
  deserializeProp: _prayerCompanionRecordIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'occurrenceKey': IndexSchema(
      id: 1905454298359628696,
      name: r'occurrenceKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'occurrenceKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
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
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _prayerCompanionRecordIsarGetId,
  getLinks: _prayerCompanionRecordIsarGetLinks,
  attach: _prayerCompanionRecordIsarAttach,
  version: '3.1.0+1',
);

int _prayerCompanionRecordIsarEstimateSize(
  PrayerCompanionRecordIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.occurrenceKey.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  return bytesCount;
}

void _prayerCompanionRecordIsarSerialize(
  PrayerCompanionRecordIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.followUpAt);
  writer.writeLong(offsets[2], object.followUpCount);
  writer.writeLong(offsets[3], object.localDayKey);
  writer.writeString(offsets[4], object.occurrenceKey);
  writer.writeString(offsets[5], object.ownerId);
  writer.writeLong(offsets[6], object.prayerKeyIndex);
  writer.writeDateTime(offsets[7], object.scheduledAt);
  writer.writeLong(offsets[8], object.statusIndex);
  writer.writeDateTime(offsets[9], object.statusUpdatedAt);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

PrayerCompanionRecordIsar _prayerCompanionRecordIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrayerCompanionRecordIsar();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.followUpAt = reader.readDateTimeOrNull(offsets[1]);
  object.followUpCount = reader.readLong(offsets[2]);
  object.id = id;
  object.localDayKey = reader.readLong(offsets[3]);
  object.occurrenceKey = reader.readString(offsets[4]);
  object.ownerId = reader.readString(offsets[5]);
  object.prayerKeyIndex = reader.readLong(offsets[6]);
  object.scheduledAt = reader.readDateTime(offsets[7]);
  object.statusIndex = reader.readLong(offsets[8]);
  object.statusUpdatedAt = reader.readDateTime(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  return object;
}

P _prayerCompanionRecordIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _prayerCompanionRecordIsarGetId(PrayerCompanionRecordIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _prayerCompanionRecordIsarGetLinks(
  PrayerCompanionRecordIsar object,
) {
  return [];
}

void _prayerCompanionRecordIsarAttach(
  IsarCollection<dynamic> col,
  Id id,
  PrayerCompanionRecordIsar object,
) {
  object.id = id;
}

extension PrayerCompanionRecordIsarByIndex
    on IsarCollection<PrayerCompanionRecordIsar> {
  Future<PrayerCompanionRecordIsar?> getByOccurrenceKey(String occurrenceKey) {
    return getByIndex(r'occurrenceKey', [occurrenceKey]);
  }

  PrayerCompanionRecordIsar? getByOccurrenceKeySync(String occurrenceKey) {
    return getByIndexSync(r'occurrenceKey', [occurrenceKey]);
  }

  Future<bool> deleteByOccurrenceKey(String occurrenceKey) {
    return deleteByIndex(r'occurrenceKey', [occurrenceKey]);
  }

  bool deleteByOccurrenceKeySync(String occurrenceKey) {
    return deleteByIndexSync(r'occurrenceKey', [occurrenceKey]);
  }

  Future<List<PrayerCompanionRecordIsar?>> getAllByOccurrenceKey(
    List<String> occurrenceKeyValues,
  ) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'occurrenceKey', values);
  }

  List<PrayerCompanionRecordIsar?> getAllByOccurrenceKeySync(
    List<String> occurrenceKeyValues,
  ) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'occurrenceKey', values);
  }

  Future<int> deleteAllByOccurrenceKey(List<String> occurrenceKeyValues) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'occurrenceKey', values);
  }

  int deleteAllByOccurrenceKeySync(List<String> occurrenceKeyValues) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'occurrenceKey', values);
  }

  Future<Id> putByOccurrenceKey(PrayerCompanionRecordIsar object) {
    return putByIndex(r'occurrenceKey', object);
  }

  Id putByOccurrenceKeySync(
    PrayerCompanionRecordIsar object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'occurrenceKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOccurrenceKey(
    List<PrayerCompanionRecordIsar> objects,
  ) {
    return putAllByIndex(r'occurrenceKey', objects);
  }

  List<Id> putAllByOccurrenceKeySync(
    List<PrayerCompanionRecordIsar> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'occurrenceKey', objects, saveLinks: saveLinks);
  }
}

extension PrayerCompanionRecordIsarQueryWhereSort
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QWhere
        > {
  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhere
  >
  anyLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'localDayKey'),
      );
    });
  }
}

extension PrayerCompanionRecordIsarQueryWhere
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QWhereClause
        > {
  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  occurrenceKeyEqualTo(String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'occurrenceKey',
          value: [occurrenceKey],
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  occurrenceKeyNotEqualTo(String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [],
                upper: [occurrenceKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [occurrenceKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [occurrenceKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [],
                upper: [occurrenceKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  ownerIdEqualTo(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'ownerId', value: [ownerId]),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  ownerIdNotEqualTo(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  localDayKeyEqualTo(int localDayKey) {
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  localDayKeyNotEqualTo(int localDayKey) {
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

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  localDayKeyGreaterThan(int localDayKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDayKey',
          lower: [localDayKey],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  localDayKeyLessThan(int localDayKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDayKey',
          lower: [],
          upper: [localDayKey],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterWhereClause
  >
  localDayKeyBetween(
    int lowerLocalDayKey,
    int upperLocalDayKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDayKey',
          lower: [lowerLocalDayKey],
          includeLower: includeLower,
          upper: [upperLocalDayKey],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PrayerCompanionRecordIsarQueryFilter
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QFilterCondition
        > {
  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'followUpAt'),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'followUpAt'),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'followUpAt', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'followUpAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'followUpAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'followUpAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'followUpCount', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'followUpCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'followUpCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  followUpCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'followUpCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  localDayKeyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localDayKey', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  localDayKeyGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localDayKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  localDayKeyLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localDayKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  localDayKeyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localDayKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
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
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'statusIndex', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'statusIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'statusIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'statusIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusUpdatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'statusUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusUpdatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'statusUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusUpdatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'statusUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  statusUpdatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'statusUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PrayerCompanionRecordIsarQueryObject
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QFilterCondition
        > {}

extension PrayerCompanionRecordIsarQueryLinks
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QFilterCondition
        > {}

extension PrayerCompanionRecordIsarQuerySortBy
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QSortBy
        > {
  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByFollowUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByFollowUpCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpCount', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByFollowUpCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpCount', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByPrayerKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByStatusIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByStatusUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PrayerCompanionRecordIsarQuerySortThenBy
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QSortThenBy
        > {
  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByFollowUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByFollowUpCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpCount', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByFollowUpCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpCount', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByPrayerKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayerKeyIndex', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByStatusIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusIndex', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByStatusUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    PrayerCompanionRecordIsar,
    PrayerCompanionRecordIsar,
    QAfterSortBy
  >
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PrayerCompanionRecordIsarQueryWhereDistinct
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QDistinct
        > {
  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByFollowUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followUpAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByFollowUpCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followUpCount');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localDayKey');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByOccurrenceKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'occurrenceKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByPrayerKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prayerKeyIndex');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByStatusIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusIndex');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusUpdatedAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, PrayerCompanionRecordIsar, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension PrayerCompanionRecordIsarQueryProperty
    on
        QueryBuilder<
          PrayerCompanionRecordIsar,
          PrayerCompanionRecordIsar,
          QQueryProperty
        > {
  QueryBuilder<PrayerCompanionRecordIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, DateTime?, QQueryOperations>
  followUpAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followUpAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, int, QQueryOperations>
  followUpCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followUpCount');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, int, QQueryOperations>
  localDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDayKey');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, String, QQueryOperations>
  occurrenceKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurrenceKey');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, String, QQueryOperations>
  ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, int, QQueryOperations>
  prayerKeyIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prayerKeyIndex');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, DateTime, QQueryOperations>
  scheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, int, QQueryOperations>
  statusIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusIndex');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, DateTime, QQueryOperations>
  statusUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusUpdatedAt');
    });
  }

  QueryBuilder<PrayerCompanionRecordIsar, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
