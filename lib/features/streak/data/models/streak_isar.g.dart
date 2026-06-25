// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStreakIsarCollection on Isar {
  IsarCollection<StreakIsar> get streakIsars => this.collection();
}

const StreakIsarSchema = CollectionSchema(
  name: r'StreakIsar',
  id: 1950774003816431419,
  properties: {
    r'currentStreak': PropertySchema(
      id: 0,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'freezesAvailable': PropertySchema(
      id: 1,
      name: r'freezesAvailable',
      type: IsarType.long,
    ),
    r'lastActivityDate': PropertySchema(
      id: 2,
      name: r'lastActivityDate',
      type: IsarType.dateTime,
    ),
    r'longestStreak': PropertySchema(
      id: 3,
      name: r'longestStreak',
      type: IsarType.long,
    )
  },
  estimateSize: _streakIsarEstimateSize,
  serialize: _streakIsarSerialize,
  deserialize: _streakIsarDeserialize,
  deserializeProp: _streakIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _streakIsarGetId,
  getLinks: _streakIsarGetLinks,
  attach: _streakIsarAttach,
  version: '3.1.0+1',
);

int _streakIsarEstimateSize(
  StreakIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _streakIsarSerialize(
  StreakIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentStreak);
  writer.writeLong(offsets[1], object.freezesAvailable);
  writer.writeDateTime(offsets[2], object.lastActivityDate);
  writer.writeLong(offsets[3], object.longestStreak);
}

StreakIsar _streakIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StreakIsar();
  object.currentStreak = reader.readLong(offsets[0]);
  object.freezesAvailable = reader.readLong(offsets[1]);
  object.id = id;
  object.lastActivityDate = reader.readDateTimeOrNull(offsets[2]);
  object.longestStreak = reader.readLong(offsets[3]);
  return object;
}

P _streakIsarDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _streakIsarGetId(StreakIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _streakIsarGetLinks(StreakIsar object) {
  return [];
}

void _streakIsarAttach(IsarCollection<dynamic> col, Id id, StreakIsar object) {
  object.id = id;
}

extension StreakIsarQueryWhereSort
    on QueryBuilder<StreakIsar, StreakIsar, QWhere> {
  QueryBuilder<StreakIsar, StreakIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StreakIsarQueryWhere
    on QueryBuilder<StreakIsar, StreakIsar, QWhereClause> {
  QueryBuilder<StreakIsar, StreakIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<StreakIsar, StreakIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterWhereClause> idBetween(
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
}

extension StreakIsarQueryFilter
    on QueryBuilder<StreakIsar, StreakIsar, QFilterCondition> {
  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      freezesAvailableEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freezesAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      freezesAvailableGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'freezesAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      freezesAvailableLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'freezesAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      freezesAvailableBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'freezesAvailable',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastActivityDate',
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastActivityDate',
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastActivityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastActivityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastActivityDate',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      lastActivityDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastActivityDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension StreakIsarQueryObject
    on QueryBuilder<StreakIsar, StreakIsar, QFilterCondition> {}

extension StreakIsarQueryLinks
    on QueryBuilder<StreakIsar, StreakIsar, QFilterCondition> {}

extension StreakIsarQuerySortBy
    on QueryBuilder<StreakIsar, StreakIsar, QSortBy> {
  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByFreezesAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freezesAvailable', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy>
      sortByFreezesAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freezesAvailable', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByLastActivityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActivityDate', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy>
      sortByLastActivityDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActivityDate', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }
}

extension StreakIsarQuerySortThenBy
    on QueryBuilder<StreakIsar, StreakIsar, QSortThenBy> {
  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByFreezesAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freezesAvailable', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy>
      thenByFreezesAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freezesAvailable', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByLastActivityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActivityDate', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy>
      thenByLastActivityDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActivityDate', Sort.desc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QAfterSortBy> thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }
}

extension StreakIsarQueryWhereDistinct
    on QueryBuilder<StreakIsar, StreakIsar, QDistinct> {
  QueryBuilder<StreakIsar, StreakIsar, QDistinct> distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QDistinct> distinctByFreezesAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freezesAvailable');
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QDistinct> distinctByLastActivityDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastActivityDate');
    });
  }

  QueryBuilder<StreakIsar, StreakIsar, QDistinct> distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }
}

extension StreakIsarQueryProperty
    on QueryBuilder<StreakIsar, StreakIsar, QQueryProperty> {
  QueryBuilder<StreakIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StreakIsar, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<StreakIsar, int, QQueryOperations> freezesAvailableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freezesAvailable');
    });
  }

  QueryBuilder<StreakIsar, DateTime?, QQueryOperations>
      lastActivityDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastActivityDate');
    });
  }

  QueryBuilder<StreakIsar, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }
}
