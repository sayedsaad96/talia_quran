// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetXpIsarCollection on Isar {
  IsarCollection<XpIsar> get xpIsars => this.collection();
}

const XpIsarSchema = CollectionSchema(
  name: r'XpIsar',
  id: 1185858158439432322,
  properties: {
    r'cloudDirty': PropertySchema(
      id: 0,
      name: r'cloudDirty',
      type: IsarType.bool,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 1,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'totalXp': PropertySchema(
      id: 2,
      name: r'totalXp',
      type: IsarType.long,
    )
  },
  estimateSize: _xpIsarEstimateSize,
  serialize: _xpIsarSerialize,
  deserialize: _xpIsarDeserialize,
  deserializeProp: _xpIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _xpIsarGetId,
  getLinks: _xpIsarGetLinks,
  attach: _xpIsarAttach,
  version: '3.1.0+1',
);

int _xpIsarEstimateSize(
  XpIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _xpIsarSerialize(
  XpIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.cloudDirty);
  writer.writeDateTime(offsets[1], object.lastSyncedAt);
  writer.writeLong(offsets[2], object.totalXp);
}

XpIsar _xpIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = XpIsar();
  object.cloudDirty = reader.readBoolOrNull(offsets[0]);
  object.id = id;
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[1]);
  object.totalXp = reader.readLong(offsets[2]);
  return object;
}

P _xpIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _xpIsarGetId(XpIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _xpIsarGetLinks(XpIsar object) {
  return [];
}

void _xpIsarAttach(IsarCollection<dynamic> col, Id id, XpIsar object) {
  object.id = id;
}

extension XpIsarQueryWhereSort on QueryBuilder<XpIsar, XpIsar, QWhere> {
  QueryBuilder<XpIsar, XpIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension XpIsarQueryWhere on QueryBuilder<XpIsar, XpIsar, QWhereClause> {
  QueryBuilder<XpIsar, XpIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<XpIsar, XpIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterWhereClause> idBetween(
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

extension XpIsarQueryFilter on QueryBuilder<XpIsar, XpIsar, QFilterCondition> {
  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> cloudDirtyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cloudDirty',
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> cloudDirtyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cloudDirty',
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> cloudDirtyEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudDirty',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> totalXpEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalXp',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> totalXpGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalXp',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> totalXpLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalXp',
        value: value,
      ));
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterFilterCondition> totalXpBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalXp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension XpIsarQueryObject on QueryBuilder<XpIsar, XpIsar, QFilterCondition> {}

extension XpIsarQueryLinks on QueryBuilder<XpIsar, XpIsar, QFilterCondition> {}

extension XpIsarQuerySortBy on QueryBuilder<XpIsar, XpIsar, QSortBy> {
  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByCloudDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.desc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> sortByTotalXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.desc);
    });
  }
}

extension XpIsarQuerySortThenBy on QueryBuilder<XpIsar, XpIsar, QSortThenBy> {
  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByCloudDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudDirty', Sort.desc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.asc);
    });
  }

  QueryBuilder<XpIsar, XpIsar, QAfterSortBy> thenByTotalXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.desc);
    });
  }
}

extension XpIsarQueryWhereDistinct on QueryBuilder<XpIsar, XpIsar, QDistinct> {
  QueryBuilder<XpIsar, XpIsar, QDistinct> distinctByCloudDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudDirty');
    });
  }

  QueryBuilder<XpIsar, XpIsar, QDistinct> distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<XpIsar, XpIsar, QDistinct> distinctByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalXp');
    });
  }
}

extension XpIsarQueryProperty on QueryBuilder<XpIsar, XpIsar, QQueryProperty> {
  QueryBuilder<XpIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<XpIsar, bool?, QQueryOperations> cloudDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudDirty');
    });
  }

  QueryBuilder<XpIsar, DateTime?, QQueryOperations> lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<XpIsar, int, QQueryOperations> totalXpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalXp');
    });
  }
}
