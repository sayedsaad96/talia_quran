// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_confusion_pair.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarConfusionPairCollection on Isar {
  IsarCollection<IsarConfusionPair> get isarConfusionPairs => this.collection();
}

const IsarConfusionPairSchema = CollectionSchema(
  name: r'IsarConfusionPair',
  id: 373188776772298883,
  properties: {
    r'audience': PropertySchema(
      id: 0,
      name: r'audience',
      type: IsarType.string,
    ),
    r'count': PropertySchema(id: 1, name: r'count', type: IsarType.long),
    r'firstAt': PropertySchema(
      id: 2,
      name: r'firstAt',
      type: IsarType.dateTime,
    ),
    r'lastAt': PropertySchema(id: 3, name: r'lastAt', type: IsarType.dateTime),
    r'otherKey': PropertySchema(
      id: 4,
      name: r'otherKey',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(id: 5, name: r'ownerId', type: IsarType.string),
    r'targetKey': PropertySchema(
      id: 6,
      name: r'targetKey',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarConfusionPairEstimateSize,
  serialize: _isarConfusionPairSerialize,
  deserialize: _isarConfusionPairDeserialize,
  deserializeProp: _isarConfusionPairDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerId_targetKey_otherKey': IndexSchema(
      id: -3377972684568397103,
      name: r'ownerId_targetKey_otherKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'targetKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'otherKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarConfusionPairGetId,
  getLinks: _isarConfusionPairGetLinks,
  attach: _isarConfusionPairAttach,
  version: '3.3.2',
);

int _isarConfusionPairEstimateSize(
  IsarConfusionPair object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.audience.length * 3;
  bytesCount += 3 + object.otherKey.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  bytesCount += 3 + object.targetKey.length * 3;
  return bytesCount;
}

void _isarConfusionPairSerialize(
  IsarConfusionPair object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audience);
  writer.writeLong(offsets[1], object.count);
  writer.writeDateTime(offsets[2], object.firstAt);
  writer.writeDateTime(offsets[3], object.lastAt);
  writer.writeString(offsets[4], object.otherKey);
  writer.writeString(offsets[5], object.ownerId);
  writer.writeString(offsets[6], object.targetKey);
}

IsarConfusionPair _isarConfusionPairDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarConfusionPair();
  object.audience = reader.readString(offsets[0]);
  object.count = reader.readLong(offsets[1]);
  object.firstAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.lastAt = reader.readDateTime(offsets[3]);
  object.otherKey = reader.readString(offsets[4]);
  object.ownerId = reader.readString(offsets[5]);
  object.targetKey = reader.readString(offsets[6]);
  return object;
}

P _isarConfusionPairDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarConfusionPairGetId(IsarConfusionPair object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarConfusionPairGetLinks(
  IsarConfusionPair object,
) {
  return [];
}

void _isarConfusionPairAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarConfusionPair object,
) {
  object.id = id;
}

extension IsarConfusionPairByIndex on IsarCollection<IsarConfusionPair> {
  Future<IsarConfusionPair?> getByOwnerIdTargetKeyOtherKey(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return getByIndex(r'ownerId_targetKey_otherKey', [
      ownerId,
      targetKey,
      otherKey,
    ]);
  }

  IsarConfusionPair? getByOwnerIdTargetKeyOtherKeySync(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return getByIndexSync(r'ownerId_targetKey_otherKey', [
      ownerId,
      targetKey,
      otherKey,
    ]);
  }

  Future<bool> deleteByOwnerIdTargetKeyOtherKey(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return deleteByIndex(r'ownerId_targetKey_otherKey', [
      ownerId,
      targetKey,
      otherKey,
    ]);
  }

  bool deleteByOwnerIdTargetKeyOtherKeySync(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return deleteByIndexSync(r'ownerId_targetKey_otherKey', [
      ownerId,
      targetKey,
      otherKey,
    ]);
  }

  Future<List<IsarConfusionPair?>> getAllByOwnerIdTargetKeyOtherKey(
    List<String> ownerIdValues,
    List<String> targetKeyValues,
    List<String> otherKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      targetKeyValues.length == len && otherKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], targetKeyValues[i], otherKeyValues[i]]);
    }

    return getAllByIndex(r'ownerId_targetKey_otherKey', values);
  }

  List<IsarConfusionPair?> getAllByOwnerIdTargetKeyOtherKeySync(
    List<String> ownerIdValues,
    List<String> targetKeyValues,
    List<String> otherKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      targetKeyValues.length == len && otherKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], targetKeyValues[i], otherKeyValues[i]]);
    }

    return getAllByIndexSync(r'ownerId_targetKey_otherKey', values);
  }

  Future<int> deleteAllByOwnerIdTargetKeyOtherKey(
    List<String> ownerIdValues,
    List<String> targetKeyValues,
    List<String> otherKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      targetKeyValues.length == len && otherKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], targetKeyValues[i], otherKeyValues[i]]);
    }

    return deleteAllByIndex(r'ownerId_targetKey_otherKey', values);
  }

  int deleteAllByOwnerIdTargetKeyOtherKeySync(
    List<String> ownerIdValues,
    List<String> targetKeyValues,
    List<String> otherKeyValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      targetKeyValues.length == len && otherKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], targetKeyValues[i], otherKeyValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerId_targetKey_otherKey', values);
  }

  Future<Id> putByOwnerIdTargetKeyOtherKey(IsarConfusionPair object) {
    return putByIndex(r'ownerId_targetKey_otherKey', object);
  }

  Id putByOwnerIdTargetKeyOtherKeySync(
    IsarConfusionPair object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'ownerId_targetKey_otherKey',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByOwnerIdTargetKeyOtherKey(
    List<IsarConfusionPair> objects,
  ) {
    return putAllByIndex(r'ownerId_targetKey_otherKey', objects);
  }

  List<Id> putAllByOwnerIdTargetKeyOtherKeySync(
    List<IsarConfusionPair> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerId_targetKey_otherKey',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension IsarConfusionPairQueryWhereSort
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QWhere> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarConfusionPairQueryWhere
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QWhereClause> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdEqualToAnyTargetKeyOtherKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_targetKey_otherKey',
          value: [ownerId],
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdNotEqualToAnyTargetKeyOtherKey(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdTargetKeyEqualToAnyOtherKey(String ownerId, String targetKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_targetKey_otherKey',
          value: [ownerId, targetKey],
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdEqualToTargetKeyNotEqualToAnyOtherKey(
    String ownerId,
    String targetKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId],
                upper: [ownerId, targetKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey],
                includeLower: false,
                upper: [ownerId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey],
                includeLower: false,
                upper: [ownerId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId],
                upper: [ownerId, targetKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdTargetKeyOtherKeyEqualTo(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_targetKey_otherKey',
          value: [ownerId, targetKey, otherKey],
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterWhereClause>
  ownerIdTargetKeyEqualToOtherKeyNotEqualTo(
    String ownerId,
    String targetKey,
    String otherKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey],
                upper: [ownerId, targetKey, otherKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey, otherKey],
                includeLower: false,
                upper: [ownerId, targetKey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey, otherKey],
                includeLower: false,
                upper: [ownerId, targetKey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_targetKey_otherKey',
                lower: [ownerId, targetKey],
                upper: [ownerId, targetKey, otherKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarConfusionPairQueryFilter
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QFilterCondition> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  audienceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'audience', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  audienceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'audience', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  countEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'count', value: value),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  countGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'count',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  countLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'count',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  countBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'count',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  firstAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firstAt', value: value),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  firstAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firstAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  firstAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firstAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  firstAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firstAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  lastAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastAt', value: value),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  lastAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  lastAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  lastAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'otherKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'otherKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'otherKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  otherKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'otherKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
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

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'targetKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'targetKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'targetKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'targetKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterFilterCondition>
  targetKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'targetKey', value: ''),
      );
    });
  }
}

extension IsarConfusionPairQueryObject
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QFilterCondition> {}

extension IsarConfusionPairQueryLinks
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QFilterCondition> {}

extension IsarConfusionPairQuerySortBy
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QSortBy> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByFirstAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstAt', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByFirstAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstAt', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByLastAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAt', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByLastAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAt', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByOtherKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherKey', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByOtherKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherKey', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByTargetKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetKey', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  sortByTargetKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetKey', Sort.desc);
    });
  }
}

extension IsarConfusionPairQuerySortThenBy
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QSortThenBy> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByAudience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByAudienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audience', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'count', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByFirstAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstAt', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByFirstAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstAt', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByLastAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAt', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByLastAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAt', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByOtherKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherKey', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByOtherKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherKey', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByTargetKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetKey', Sort.asc);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QAfterSortBy>
  thenByTargetKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetKey', Sort.desc);
    });
  }
}

extension IsarConfusionPairQueryWhereDistinct
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct> {
  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByAudience({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audience', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'count');
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByFirstAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstAt');
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByLastAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastAt');
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByOtherKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByOwnerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarConfusionPair, IsarConfusionPair, QDistinct>
  distinctByTargetKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetKey', caseSensitive: caseSensitive);
    });
  }
}

extension IsarConfusionPairQueryProperty
    on QueryBuilder<IsarConfusionPair, IsarConfusionPair, QQueryProperty> {
  QueryBuilder<IsarConfusionPair, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarConfusionPair, String, QQueryOperations> audienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audience');
    });
  }

  QueryBuilder<IsarConfusionPair, int, QQueryOperations> countProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'count');
    });
  }

  QueryBuilder<IsarConfusionPair, DateTime, QQueryOperations>
  firstAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstAt');
    });
  }

  QueryBuilder<IsarConfusionPair, DateTime, QQueryOperations> lastAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastAt');
    });
  }

  QueryBuilder<IsarConfusionPair, String, QQueryOperations> otherKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherKey');
    });
  }

  QueryBuilder<IsarConfusionPair, String, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarConfusionPair, String, QQueryOperations>
  targetKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetKey');
    });
  }
}
