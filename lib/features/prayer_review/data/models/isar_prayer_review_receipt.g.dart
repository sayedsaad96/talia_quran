// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_prayer_review_receipt.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPrayerReviewReceiptCollection on Isar {
  IsarCollection<IsarPrayerReviewReceipt> get isarPrayerReviewReceipts =>
      this.collection();
}

const IsarPrayerReviewReceiptSchema = CollectionSchema(
  name: r'IsarPrayerReviewReceipt',
  id: 3464301536217036426,
  properties: {
    r'audience': PropertySchema(
      id: 0,
      name: r'audience',
      type: IsarType.string,
    ),
    r'committedAt': PropertySchema(
      id: 1,
      name: r'committedAt',
      type: IsarType.dateTime,
    ),
    r'endAyah': PropertySchema(id: 2, name: r'endAyah', type: IsarType.long),
    r'eventIds': PropertySchema(
      id: 3,
      name: r'eventIds',
      type: IsarType.stringList,
    ),
    r'gradeIndex': PropertySchema(
      id: 4,
      name: r'gradeIndex',
      type: IsarType.long,
    ),
    r'localDayKey': PropertySchema(
      id: 5,
      name: r'localDayKey',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(id: 6, name: r'ownerId', type: IsarType.string),
    r'receiptKey': PropertySchema(
      id: 7,
      name: r'receiptKey',
      type: IsarType.string,
    ),
    r'startAyah': PropertySchema(
      id: 8,
      name: r'startAyah',
      type: IsarType.long,
    ),
    r'surahId': PropertySchema(id: 9, name: r'surahId', type: IsarType.long),
  },

  estimateSize: _isarPrayerReviewReceiptEstimateSize,
  serialize: _isarPrayerReviewReceiptSerialize,
  deserialize: _isarPrayerReviewReceiptDeserialize,
  deserializeProp: _isarPrayerReviewReceiptDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerId_receiptKey': IndexSchema(
      id: -7406685705852859651,
      name: r'ownerId_receiptKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'receiptKey',
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

  getId: _isarPrayerReviewReceiptGetId,
  getLinks: _isarPrayerReviewReceiptGetLinks,
  attach: _isarPrayerReviewReceiptAttach,
  version: '3.3.2',
);

int _isarPrayerReviewReceiptEstimateSize(
  IsarPrayerReviewReceipt object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.audience.length * 3;
  bytesCount += 3 + object.eventIds.length * 3;
  {
    for (var i = 0; i < object.eventIds.length; i++) {
      final value = object.eventIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.localDayKey.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  bytesCount += 3 + object.receiptKey.length * 3;
  return bytesCount;
}

void _isarPrayerReviewReceiptSerialize(
  IsarPrayerReviewReceipt object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audience);
  writer.writeDateTime(offsets[1], object.committedAt);
  writer.writeLong(offsets[2], object.endAyah);
  writer.writeStringList(offsets[3], object.eventIds);
  writer.writeLong(offsets[4], object.gradeIndex);
  writer.writeString(offsets[5], object.localDayKey);
  writer.writeString(offsets[6], object.ownerId);
  writer.writeString(offsets[7], object.receiptKey);
  writer.writeLong(offsets[8], object.startAyah);
  writer.writeLong(offsets[9], object.surahId);
}

IsarPrayerReviewReceipt _isarPrayerReviewReceiptDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPrayerReviewReceipt();
  object.audience = reader.readString(offsets[0]);
  object.committedAt = reader.readDateTime(offsets[1]);
  object.endAyah = reader.readLong(offsets[2]);
  object.eventIds = reader.readStringList(offsets[3]) ?? [];
  object.gradeIndex = reader.readLong(offsets[4]);
  object.id = id;
  object.localDayKey = reader.readString(offsets[5]);
  object.ownerId = reader.readString(offsets[6]);
  object.receiptKey = reader.readString(offsets[7]);
  object.startAyah = reader.readLong(offsets[8]);
  object.surahId = reader.readLong(offsets[9]);
  return object;
}

P _isarPrayerReviewReceiptDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPrayerReviewReceiptGetId(IsarPrayerReviewReceipt object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPrayerReviewReceiptGetLinks(
  IsarPrayerReviewReceipt object,
) {
  return [];
}

void _isarPrayerReviewReceiptAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPrayerReviewReceipt object,
) {
  object.id = id;
}

extension IsarPrayerReviewReceiptByIndex
    on IsarCollection<IsarPrayerReviewReceipt> {
  Future<IsarPrayerReviewReceipt?> getByOwnerIdReceiptKey(
    String ownerId,
    String receiptKey,
  ) {
    return getByIndex(r'ownerId_receiptKey', [ownerId, receiptKey]);
  }

  IsarPrayerReviewReceipt? getByOwnerIdReceiptKeySync(
    String ownerId,
    String receiptKey,
  ) {
    return getByIndexSync(r'ownerId_receiptKey', [ownerId, receiptKey]);
  }

  Future<bool> deleteByOwnerIdReceiptKey(String ownerId, String receiptKey) {
    return deleteByIndex(r'ownerId_receiptKey', [ownerId, receiptKey]);
  }

  bool deleteByOwnerIdReceiptKeySync(String ownerId, String receiptKey) {
    return deleteByIndexSync(r'ownerId_receiptKey', [ownerId, receiptKey]);
  }

  Future<List<IsarPrayerReviewReceipt?>> getAllByOwnerIdReceiptKey(
    List<String> ownerIdValues,
    List<String> receiptKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      receiptKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], receiptKeyValues[i]]);
    }

    return getAllByIndex(r'ownerId_receiptKey', values);
  }

  List<IsarPrayerReviewReceipt?> getAllByOwnerIdReceiptKeySync(
    List<String> ownerIdValues,
    List<String> receiptKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      receiptKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], receiptKeyValues[i]]);
    }

    return getAllByIndexSync(r'ownerId_receiptKey', values);
  }

  Future<int> deleteAllByOwnerIdReceiptKey(
    List<String> ownerIdValues,
    List<String> receiptKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      receiptKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], receiptKeyValues[i]]);
    }

    return deleteAllByIndex(r'ownerId_receiptKey', values);
  }

  int deleteAllByOwnerIdReceiptKeySync(
    List<String> ownerIdValues,
    List<String> receiptKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      receiptKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], receiptKeyValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerId_receiptKey', values);
  }

  Future<Id> putByOwnerIdReceiptKey(IsarPrayerReviewReceipt object) {
    return putByIndex(r'ownerId_receiptKey', object);
  }

  Id putByOwnerIdReceiptKeySync(
    IsarPrayerReviewReceipt object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'ownerId_receiptKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerIdReceiptKey(
    List<IsarPrayerReviewReceipt> objects,
  ) {
    return putAllByIndex(r'ownerId_receiptKey', objects);
  }

  List<Id> putAllByOwnerIdReceiptKeySync(
    List<IsarPrayerReviewReceipt> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerId_receiptKey',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension IsarPrayerReviewReceiptQueryWhereSort
    on QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QWhere> {
  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPrayerReviewReceiptQueryWhere
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QWhereClause
        > {
  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterWhereClause
  >
  ownerIdEqualToAnyReceiptKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_receiptKey',
          value: [ownerId],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterWhereClause
  >
  ownerIdNotEqualToAnyReceiptKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterWhereClause
  >
  ownerIdReceiptKeyEqualTo(String ownerId, String receiptKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_receiptKey',
          value: [ownerId, receiptKey],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterWhereClause
  >
  ownerIdEqualToReceiptKeyNotEqualTo(String ownerId, String receiptKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId],
                upper: [ownerId, receiptKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId, receiptKey],
                includeLower: false,
                upper: [ownerId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId, receiptKey],
                includeLower: false,
                upper: [ownerId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_receiptKey',
                lower: [ownerId],
                upper: [ownerId, receiptKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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

extension IsarPrayerReviewReceiptQueryFilter
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QFilterCondition
        > {
  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  committedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'committedAt', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  committedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'committedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  committedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'committedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  committedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'committedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventIds',
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventIds', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventIds', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eventIds', length, true, length, true);
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eventIds', 0, true, 0, true);
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eventIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eventIds', 0, true, length, include);
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eventIds', length, include, 999999, true);
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  eventIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eventIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  gradeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gradeIndex', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  gradeIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gradeIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  gradeIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gradeIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  gradeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gradeIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'receiptKey',
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'receiptKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'receiptKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'receiptKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
    QAfterFilterCondition
  >
  receiptKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'receiptKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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
    IsarPrayerReviewReceipt,
    IsarPrayerReviewReceipt,
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

extension IsarPrayerReviewReceiptQueryObject
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QFilterCondition
        > {}

extension IsarPrayerReviewReceiptQueryLinks
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QFilterCondition
        > {}

extension IsarPrayerReviewReceiptQuerySortBy
    on QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QSortBy> {
  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByCommittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByGradeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gradeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByGradeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gradeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByReceiptKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByReceiptKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarPrayerReviewReceiptQuerySortThenBy
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QSortThenBy
        > {
  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByCommittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'committedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByGradeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gradeIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByGradeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gradeIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByLocalDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByLocalDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByReceiptKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByReceiptKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptKey', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QAfterSortBy>
  thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarPrayerReviewReceiptQueryWhereDistinct
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QDistinct
        > {
  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByCommittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'committedAt');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByEventIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventIds');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByGradeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gradeIndex');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByLocalDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localDayKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByReceiptKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, IsarPrayerReviewReceipt, QDistinct>
  distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }
}

extension IsarPrayerReviewReceiptQueryProperty
    on
        QueryBuilder<
          IsarPrayerReviewReceipt,
          IsarPrayerReviewReceipt,
          QQueryProperty
        > {
  QueryBuilder<IsarPrayerReviewReceipt, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, String, QQueryOperations>
  audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, DateTime, QQueryOperations>
  committedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'committedAt');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, int, QQueryOperations>
  endAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, List<String>, QQueryOperations>
  eventIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventIds');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, int, QQueryOperations>
  gradeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gradeIndex');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, String, QQueryOperations>
  localDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDayKey');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, String, QQueryOperations>
  ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, String, QQueryOperations>
  receiptKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptKey');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, int, QQueryOperations>
  startAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAyah');
    });
  }

  QueryBuilder<IsarPrayerReviewReceipt, int, QQueryOperations>
  surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }
}
