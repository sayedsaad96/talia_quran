// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ayah_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAyahProgressCollection on Isar {
  IsarCollection<IsarAyahProgress> get isarAyahProgress => this.collection();
}

const IsarAyahProgressSchema = CollectionSchema(
  name: r'IsarAyahProgress',
  id: 4132211703475714551,
  properties: {
    r'ayahNumber': PropertySchema(
      id: 0,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'compositeKey': PropertySchema(
      id: 1,
      name: r'compositeKey',
      type: IsarType.string,
    ),
    r'lastReviewDate': PropertySchema(
      id: 2,
      name: r'lastReviewDate',
      type: IsarType.dateTime,
    ),
    r'nextReviewDate': PropertySchema(
      id: 3,
      name: r'nextReviewDate',
      type: IsarType.dateTime,
    ),
    r'repetitions': PropertySchema(
      id: 4,
      name: r'repetitions',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.byte,
      enumMap: _IsarAyahProgressstatusEnumValueMap,
    ),
    r'surahId': PropertySchema(id: 6, name: r'surahId', type: IsarType.long),
  },
  estimateSize: _isarAyahProgressEstimateSize,
  serialize: _isarAyahProgressSerialize,
  deserialize: _isarAyahProgressDeserialize,
  deserializeProp: _isarAyahProgressDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAyahProgressGetId,
  getLinks: _isarAyahProgressGetLinks,
  attach: _isarAyahProgressAttach,
  version: '3.1.0+1',
);

int _isarAyahProgressEstimateSize(
  IsarAyahProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.compositeKey.length * 3;
  return bytesCount;
}

void _isarAyahProgressSerialize(
  IsarAyahProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayahNumber);
  writer.writeString(offsets[1], object.compositeKey);
  writer.writeDateTime(offsets[2], object.lastReviewDate);
  writer.writeDateTime(offsets[3], object.nextReviewDate);
  writer.writeLong(offsets[4], object.repetitions);
  writer.writeByte(offsets[5], object.status.index);
  writer.writeLong(offsets[6], object.surahId);
}

IsarAyahProgress _isarAyahProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAyahProgress();
  object.ayahNumber = reader.readLong(offsets[0]);
  object.compositeKey = reader.readString(offsets[1]);
  object.id = id;
  object.lastReviewDate = reader.readDateTime(offsets[2]);
  object.nextReviewDate = reader.readDateTime(offsets[3]);
  object.repetitions = reader.readLong(offsets[4]);
  object.status =
      _IsarAyahProgressstatusValueEnumMap[reader.readByteOrNull(offsets[5])] ??
      AyahStatus.notStarted;
  object.surahId = reader.readLong(offsets[6]);
  return object;
}

P _isarAyahProgressDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_IsarAyahProgressstatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              AyahStatus.notStarted)
          as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarAyahProgressstatusEnumValueMap = {
  'notStarted': 0,
  'learning': 1,
  'review': 2,
  'memorized': 3,
};
const _IsarAyahProgressstatusValueEnumMap = {
  0: AyahStatus.notStarted,
  1: AyahStatus.learning,
  2: AyahStatus.review,
  3: AyahStatus.memorized,
};

Id _isarAyahProgressGetId(IsarAyahProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAyahProgressGetLinks(IsarAyahProgress object) {
  return [];
}

void _isarAyahProgressAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarAyahProgress object,
) {
  object.id = id;
}

extension IsarAyahProgressByIndex on IsarCollection<IsarAyahProgress> {
  Future<IsarAyahProgress?> getByCompositeKey(String compositeKey) {
    return getByIndex(r'compositeKey', [compositeKey]);
  }

  IsarAyahProgress? getByCompositeKeySync(String compositeKey) {
    return getByIndexSync(r'compositeKey', [compositeKey]);
  }

  Future<bool> deleteByCompositeKey(String compositeKey) {
    return deleteByIndex(r'compositeKey', [compositeKey]);
  }

  bool deleteByCompositeKeySync(String compositeKey) {
    return deleteByIndexSync(r'compositeKey', [compositeKey]);
  }

  Future<List<IsarAyahProgress?>> getAllByCompositeKey(
    List<String> compositeKeyValues,
  ) {
    final values = compositeKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'compositeKey', values);
  }

  List<IsarAyahProgress?> getAllByCompositeKeySync(
    List<String> compositeKeyValues,
  ) {
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

  Future<Id> putByCompositeKey(IsarAyahProgress object) {
    return putByIndex(r'compositeKey', object);
  }

  Id putByCompositeKeySync(IsarAyahProgress object, {bool saveLinks = true}) {
    return putByIndexSync(r'compositeKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCompositeKey(List<IsarAyahProgress> objects) {
    return putAllByIndex(r'compositeKey', objects);
  }

  List<Id> putAllByCompositeKeySync(
    List<IsarAyahProgress> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'compositeKey', objects, saveLinks: saveLinks);
  }
}

extension IsarAyahProgressQueryWhereSort
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QWhere> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarAyahProgressQueryWhere
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QWhereClause> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause>
  compositeKeyEqualTo(String compositeKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'compositeKey',
          value: [compositeKey],
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterWhereClause>
  compositeKeyNotEqualTo(String compositeKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'compositeKey',
                lower: [],
                upper: [compositeKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'compositeKey',
                lower: [compositeKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'compositeKey',
                lower: [compositeKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'compositeKey',
                lower: [],
                upper: [compositeKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarAyahProgressQueryFilter
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QFilterCondition> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ayahNumber', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'compositeKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'compositeKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'compositeKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'compositeKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  compositeKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'compositeKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  lastReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastReviewDate', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  lastReviewDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastReviewDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  lastReviewDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastReviewDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  lastReviewDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastReviewDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  nextReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextReviewDate', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  nextReviewDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextReviewDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  nextReviewDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextReviewDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  nextReviewDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextReviewDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  repetitionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repetitions', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  repetitionsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repetitions',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  repetitionsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repetitions',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  repetitionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repetitions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  statusEqualTo(AyahStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  statusGreaterThan(AyahStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  statusLessThan(AyahStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  statusBetween(
    AyahStatus lower,
    AyahStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
  surahIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surahId', value: value),
      );
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterFilterCondition>
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

extension IsarAyahProgressQueryObject
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QFilterCondition> {}

extension IsarAyahProgressQueryLinks
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QFilterCondition> {}

extension IsarAyahProgressQuerySortBy
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QSortBy> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByCompositeKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByCompositeKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByLastReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  sortBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarAyahProgressQuerySortThenBy
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QSortThenBy> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByCompositeKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByCompositeKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compositeKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByLastReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repetitions', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.asc);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QAfterSortBy>
  thenBySurahIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahId', Sort.desc);
    });
  }
}

extension IsarAyahProgressQueryWhereDistinct
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct> {
  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByCompositeKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'compositeKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByLastReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReviewDate');
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repetitions');
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<IsarAyahProgress, IsarAyahProgress, QDistinct>
  distinctBySurahId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahId');
    });
  }
}

extension IsarAyahProgressQueryProperty
    on QueryBuilder<IsarAyahProgress, IsarAyahProgress, QQueryProperty> {
  QueryBuilder<IsarAyahProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAyahProgress, int, QQueryOperations> ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<IsarAyahProgress, String, QQueryOperations>
  compositeKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'compositeKey');
    });
  }

  QueryBuilder<IsarAyahProgress, DateTime, QQueryOperations>
  lastReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReviewDate');
    });
  }

  QueryBuilder<IsarAyahProgress, DateTime, QQueryOperations>
  nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<IsarAyahProgress, int, QQueryOperations> repetitionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repetitions');
    });
  }

  QueryBuilder<IsarAyahProgress, AyahStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarAyahProgress, int, QQueryOperations> surahIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahId');
    });
  }
}
