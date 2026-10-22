// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ayah_note.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAyahNoteCollection on Isar {
  IsarCollection<IsarAyahNote> get isarAyahNotes => this.collection();
}

const IsarAyahNoteSchema = CollectionSchema(
  name: r'IsarAyahNote',
  id: -6500558859216568879,
  properties: {
    r'ayahNumber': PropertySchema(
      id: 0,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'body': PropertySchema(id: 1, name: r'body', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'ownerId': PropertySchema(id: 3, name: r'ownerId', type: IsarType.string),
    r'surahId': PropertySchema(id: 4, name: r'surahId', type: IsarType.long),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _isarAyahNoteEstimateSize,
  serialize: _isarAyahNoteSerialize,
  deserialize: _isarAyahNoteDeserialize,
  deserializeProp: _isarAyahNoteDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerId_surahId_ayahNumber': IndexSchema(
      id: -6088039176045060535,
      name: r'ownerId_surahId_ayahNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'surahId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'ayahNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarAyahNoteGetId,
  getLinks: _isarAyahNoteGetLinks,
  attach: _isarAyahNoteAttach,
  version: '3.3.2',
);

int _isarAyahNoteEstimateSize(
  IsarAyahNote object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.body.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  return bytesCount;
}

void _isarAyahNoteSerialize(
  IsarAyahNote object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayahNumber);
  writer.writeString(offsets[1], object.body);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.ownerId);
  writer.writeLong(offsets[4], object.surahId);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

IsarAyahNote _isarAyahNoteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAyahNote();
  object.ayahNumber = reader.readLong(offsets[0]);
  object.body = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.ownerId = reader.readString(offsets[3]);
  object.surahId = reader.readLong(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _isarAyahNoteDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAyahNoteGetId(IsarAyahNote object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAyahNoteGetLinks(IsarAyahNote object) {
  return [];
}

void _isarAyahNoteAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarAyahNote object,
) {
  object.id = id;
}

extension IsarAyahNoteByIndex on IsarCollection<IsarAyahNote> {
  Future<IsarAyahNote?> getByOwnerIdSurahIdAyahNumber(
    String ownerId,
    int surahId,
    int ayahNumber,
  ) {
    return getByIndex(r'ownerId_surahId_ayahNumber', [
      ownerId,
      surahId,
      ayahNumber,
    ]);
  }

  IsarAyahNote? getByOwnerIdSurahIdAyahNumberSync(
    String ownerId,
    int surahId,
    int ayahNumber,
  ) {
    return getByIndexSync(r'ownerId_surahId_ayahNumber', [
      ownerId,
      surahId,
      ayahNumber,
    ]);
  }

  Future<bool> deleteByOwnerIdSurahIdAyahNumber(
    String ownerId,
    int surahId,
    int ayahNumber,
  ) {
    return deleteByIndex(r'ownerId_surahId_ayahNumber', [
      ownerId,
      surahId,
      ayahNumber,
    ]);
  }

  bool deleteByOwnerIdSurahIdAyahNumberSync(
    String ownerId,
    int surahId,
    int ayahNumber,
  ) {
    return deleteByIndexSync(r'ownerId_surahId_ayahNumber', [
      ownerId,
      surahId,
      ayahNumber,
    ]);
  }

  Future<List<IsarAyahNote?>> getAllByOwnerIdSurahIdAyahNumber(
    List<String> ownerIdValues,
    List<int> surahIdValues,
    List<int> ayahNumberValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      surahIdValues.length == len && ayahNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], surahIdValues[i], ayahNumberValues[i]]);
    }

    return getAllByIndex(r'ownerId_surahId_ayahNumber', values);
  }

  List<IsarAyahNote?> getAllByOwnerIdSurahIdAyahNumberSync(
    List<String> ownerIdValues,
    List<int> surahIdValues,
    List<int> ayahNumberValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      surahIdValues.length == len && ayahNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], surahIdValues[i], ayahNumberValues[i]]);
    }

    return getAllByIndexSync(r'ownerId_surahId_ayahNumber', values);
  }

  Future<int> deleteAllByOwnerIdSurahIdAyahNumber(
    List<String> ownerIdValues,
    List<int> surahIdValues,
    List<int> ayahNumberValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      surahIdValues.length == len && ayahNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], surahIdValues[i], ayahNumberValues[i]]);
    }

    return deleteAllByIndex(r'ownerId_surahId_ayahNumber', values);
  }

  int deleteAllByOwnerIdSurahIdAyahNumberSync(
    List<String> ownerIdValues,
    List<int> surahIdValues,
    List<int> ayahNumberValues,
  ) {
    final len = ownerIdValues.length;
    assert(
      surahIdValues.length == len && ayahNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerIdValues[i], surahIdValues[i], ayahNumberValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerId_surahId_ayahNumber', values);
  }

  Future<Id> putByOwnerIdSurahIdAyahNumber(IsarAyahNote object) {
    return putByIndex(r'ownerId_surahId_ayahNumber', object);
  }

  Id putByOwnerIdSurahIdAyahNumberSync(
    IsarAyahNote object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'ownerId_surahId_ayahNumber',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByOwnerIdSurahIdAyahNumber(
    List<IsarAyahNote> objects,
  ) {
    return putAllByIndex(r'ownerId_surahId_ayahNumber', objects);
  }

  List<Id> putAllByOwnerIdSurahIdAyahNumberSync(
    List<IsarAyahNote> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerId_surahId_ayahNumber',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension IsarAyahNoteQueryWhereSort
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QWhere> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarAyahNoteQueryWhere
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QWhereClause> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdEqualToAnySurahIdAyahNumber(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_surahId_ayahNumber',
          value: [ownerId],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdNotEqualToAnySurahIdAyahNumber(String ownerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [],
                upper: [ownerId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdEqualToAnyAyahNumber(String ownerId, int surahId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_surahId_ayahNumber',
          value: [ownerId, surahId],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdEqualToSurahIdNotEqualToAnyAyahNumber(String ownerId, int surahId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId],
                upper: [ownerId, surahId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId],
                includeLower: false,
                upper: [ownerId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId],
                includeLower: false,
                upper: [ownerId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId],
                upper: [ownerId, surahId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdEqualToSurahIdGreaterThanAnyAyahNumber(
    String ownerId,
    int surahId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId, surahId],
          includeLower: include,
          upper: [ownerId],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdEqualToSurahIdLessThanAnyAyahNumber(
    String ownerId,
    int surahId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId],
          upper: [ownerId, surahId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdEqualToSurahIdBetweenAnyAyahNumber(
    String ownerId,
    int lowerSurahId,
    int upperSurahId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId, lowerSurahId],
          includeLower: includeLower,
          upper: [ownerId, upperSurahId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdAyahNumberEqualTo(String ownerId, int surahId, int ayahNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerId_surahId_ayahNumber',
          value: [ownerId, surahId, ayahNumber],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdEqualToAyahNumberNotEqualTo(
    String ownerId,
    int surahId,
    int ayahNumber,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId],
                upper: [ownerId, surahId, ayahNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId, ayahNumber],
                includeLower: false,
                upper: [ownerId, surahId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId, ayahNumber],
                includeLower: false,
                upper: [ownerId, surahId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerId_surahId_ayahNumber',
                lower: [ownerId, surahId],
                upper: [ownerId, surahId, ayahNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdEqualToAyahNumberGreaterThan(
    String ownerId,
    int surahId,
    int ayahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId, surahId, ayahNumber],
          includeLower: include,
          upper: [ownerId, surahId],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdEqualToAyahNumberLessThan(
    String ownerId,
    int surahId,
    int ayahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId, surahId],
          upper: [ownerId, surahId, ayahNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterWhereClause>
  ownerIdSurahIdEqualToAyahNumberBetween(
    String ownerId,
    int surahId,
    int lowerAyahNumber,
    int upperAyahNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'ownerId_surahId_ayahNumber',
          lower: [ownerId, surahId, lowerAyahNumber],
          includeLower: includeLower,
          upper: [ownerId, surahId, upperAyahNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarAyahNoteQueryFilter
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QFilterCondition> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ayahNumber', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ayahNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ayahNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ayahNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ayahNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ayahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ayahNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  bodyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'body',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  bodyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> bodyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'body',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'body', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'body', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerId', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surahId', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterFilterCondition>
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

extension IsarAyahNoteQueryObject
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QFilterCondition> {}

extension IsarAyahNoteQueryLinks
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QFilterCondition> {}

extension IsarAyahNoteQuerySortBy
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QSortBy> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy>
  sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarAyahNoteQuerySortThenBy
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QSortThenBy> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy>
  thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarAyahNoteQueryWhereDistinct
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> {
  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctByBody({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctByOwnerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }

  QueryBuilder<IsarAyahNote, IsarAyahNote, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarAyahNoteQueryProperty
    on QueryBuilder<IsarAyahNote, IsarAyahNote, QQueryProperty> {
  QueryBuilder<IsarAyahNote, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAyahNote, int, QQueryOperations> ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahNote, String, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<IsarAyahNote, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarAyahNote, String, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<IsarAyahNote, int, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }

  QueryBuilder<IsarAyahNote, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
