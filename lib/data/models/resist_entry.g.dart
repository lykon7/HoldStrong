// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resist_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetResistEntryCollection on Isar {
  IsarCollection<ResistEntry> get resistEntrys => this.collection();
}

const ResistEntrySchema = CollectionSchema(
  name: r'ResistEntry',
  id: -4941501428613639488,
  properties: {
    r'amountLkr': PropertySchema(
      id: 0,
      name: r'amountLkr',
      type: IsarType.double,
    ),
    r'caloriesAvoided': PropertySchema(
      id: 1,
      name: r'caloriesAvoided',
      type: IsarType.long,
    ),
    r'goalUuid': PropertySchema(
      id: 2,
      name: r'goalUuid',
      type: IsarType.string,
    ),
    r'label': PropertySchema(
      id: 3,
      name: r'label',
      type: IsarType.string,
    ),
    r'loggedAt': PropertySchema(
      id: 4,
      name: r'loggedAt',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 5,
      name: r'note',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 6,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _resistEntryEstimateSize,
  serialize: _resistEntrySerialize,
  deserialize: _resistEntryDeserialize,
  deserializeProp: _resistEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'goalUuid': IndexSchema(
      id: -4424641851989767232,
      name: r'goalUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'goalUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'loggedAt': IndexSchema(
      id: 1838198766103160564,
      name: r'loggedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'loggedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _resistEntryGetId,
  getLinks: _resistEntryGetLinks,
  attach: _resistEntryAttach,
  version: '3.1.0+1',
);

int _resistEntryEstimateSize(
  ResistEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.goalUuid.length * 3;
  {
    final value = object.label;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _resistEntrySerialize(
  ResistEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amountLkr);
  writer.writeLong(offsets[1], object.caloriesAvoided);
  writer.writeString(offsets[2], object.goalUuid);
  writer.writeString(offsets[3], object.label);
  writer.writeDateTime(offsets[4], object.loggedAt);
  writer.writeString(offsets[5], object.note);
  writer.writeString(offsets[6], object.uuid);
}

ResistEntry _resistEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ResistEntry();
  object.amountLkr = reader.readDouble(offsets[0]);
  object.caloriesAvoided = reader.readLongOrNull(offsets[1]);
  object.goalUuid = reader.readString(offsets[2]);
  object.id = id;
  object.label = reader.readStringOrNull(offsets[3]);
  object.loggedAt = reader.readDateTime(offsets[4]);
  object.note = reader.readStringOrNull(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  return object;
}

P _resistEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _resistEntryGetId(ResistEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _resistEntryGetLinks(ResistEntry object) {
  return [];
}

void _resistEntryAttach(
    IsarCollection<dynamic> col, Id id, ResistEntry object) {
  object.id = id;
}

extension ResistEntryByIndex on IsarCollection<ResistEntry> {
  Future<ResistEntry?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  ResistEntry? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<ResistEntry?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<ResistEntry?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(ResistEntry object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(ResistEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<ResistEntry> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<ResistEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension ResistEntryQueryWhereSort
    on QueryBuilder<ResistEntry, ResistEntry, QWhere> {
  QueryBuilder<ResistEntry, ResistEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhere> anyLoggedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'loggedAt'),
      );
    });
  }
}

extension ResistEntryQueryWhere
    on QueryBuilder<ResistEntry, ResistEntry, QWhereClause> {
  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> uuidNotEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> goalUuidEqualTo(
      String goalUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'goalUuid',
        value: [goalUuid],
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> goalUuidNotEqualTo(
      String goalUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalUuid',
              lower: [],
              upper: [goalUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalUuid',
              lower: [goalUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalUuid',
              lower: [goalUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalUuid',
              lower: [],
              upper: [goalUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> loggedAtEqualTo(
      DateTime loggedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'loggedAt',
        value: [loggedAt],
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> loggedAtNotEqualTo(
      DateTime loggedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loggedAt',
              lower: [],
              upper: [loggedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loggedAt',
              lower: [loggedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loggedAt',
              lower: [loggedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loggedAt',
              lower: [],
              upper: [loggedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> loggedAtGreaterThan(
    DateTime loggedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loggedAt',
        lower: [loggedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> loggedAtLessThan(
    DateTime loggedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loggedAt',
        lower: [],
        upper: [loggedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterWhereClause> loggedAtBetween(
    DateTime lowerLoggedAt,
    DateTime upperLoggedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'loggedAt',
        lower: [lowerLoggedAt],
        includeLower: includeLower,
        upper: [upperLoggedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ResistEntryQueryFilter
    on QueryBuilder<ResistEntry, ResistEntry, QFilterCondition> {
  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      amountLkrEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountLkr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      amountLkrGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountLkr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      amountLkrLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountLkr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      amountLkrBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountLkr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caloriesAvoided',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caloriesAvoided',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesAvoided',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesAvoided',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesAvoided',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      caloriesAvoidedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesAvoided',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> goalUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> goalUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'goalUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> goalUuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'goalUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      goalUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'goalUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      labelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> loggedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loggedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      loggedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loggedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      loggedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loggedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> loggedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loggedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension ResistEntryQueryObject
    on QueryBuilder<ResistEntry, ResistEntry, QFilterCondition> {}

extension ResistEntryQueryLinks
    on QueryBuilder<ResistEntry, ResistEntry, QFilterCondition> {}

extension ResistEntryQuerySortBy
    on QueryBuilder<ResistEntry, ResistEntry, QSortBy> {
  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByAmountLkr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountLkr', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByAmountLkrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountLkr', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByCaloriesAvoided() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesAvoided', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy>
      sortByCaloriesAvoidedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesAvoided', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByGoalUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalUuid', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByGoalUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalUuid', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByLoggedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedAt', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByLoggedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedAt', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ResistEntryQuerySortThenBy
    on QueryBuilder<ResistEntry, ResistEntry, QSortThenBy> {
  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByAmountLkr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountLkr', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByAmountLkrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountLkr', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByCaloriesAvoided() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesAvoided', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy>
      thenByCaloriesAvoidedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesAvoided', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByGoalUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalUuid', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByGoalUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalUuid', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByLoggedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedAt', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByLoggedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loggedAt', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension ResistEntryQueryWhereDistinct
    on QueryBuilder<ResistEntry, ResistEntry, QDistinct> {
  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByAmountLkr() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountLkr');
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct>
      distinctByCaloriesAvoided() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesAvoided');
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByGoalUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByLoggedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loggedAt');
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ResistEntry, ResistEntry, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension ResistEntryQueryProperty
    on QueryBuilder<ResistEntry, ResistEntry, QQueryProperty> {
  QueryBuilder<ResistEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ResistEntry, double, QQueryOperations> amountLkrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountLkr');
    });
  }

  QueryBuilder<ResistEntry, int?, QQueryOperations> caloriesAvoidedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesAvoided');
    });
  }

  QueryBuilder<ResistEntry, String, QQueryOperations> goalUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalUuid');
    });
  }

  QueryBuilder<ResistEntry, String?, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<ResistEntry, DateTime, QQueryOperations> loggedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loggedAt');
    });
  }

  QueryBuilder<ResistEntry, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<ResistEntry, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
