// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_transfer.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAccountTransferCollection on Isar {
  IsarCollection<AccountTransfer> get accountTransfers => this.collection();
}

const AccountTransferSchema = CollectionSchema(
  name: r'AccountTransfer',
  id: 6775231448998213424,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'fromFundUuid': PropertySchema(
      id: 1,
      name: r'fromFundUuid',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 2,
      name: r'note',
      type: IsarType.string,
    ),
    r'toFundUuid': PropertySchema(
      id: 3,
      name: r'toFundUuid',
      type: IsarType.string,
    ),
    r'transferAt': PropertySchema(
      id: 4,
      name: r'transferAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 5,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _accountTransferEstimateSize,
  serialize: _accountTransferSerialize,
  deserialize: _accountTransferDeserialize,
  deserializeProp: _accountTransferDeserializeProp,
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
    r'fromFundUuid': IndexSchema(
      id: -6816322471699612790,
      name: r'fromFundUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fromFundUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'toFundUuid': IndexSchema(
      id: -1322720344195790853,
      name: r'toFundUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'toFundUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'transferAt': IndexSchema(
      id: -6226012927020143011,
      name: r'transferAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'transferAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _accountTransferGetId,
  getLinks: _accountTransferGetLinks,
  attach: _accountTransferAttach,
  version: '3.1.0+1',
);

int _accountTransferEstimateSize(
  AccountTransfer object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fromFundUuid.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.toFundUuid.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _accountTransferSerialize(
  AccountTransfer object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeString(offsets[1], object.fromFundUuid);
  writer.writeString(offsets[2], object.note);
  writer.writeString(offsets[3], object.toFundUuid);
  writer.writeDateTime(offsets[4], object.transferAt);
  writer.writeString(offsets[5], object.uuid);
}

AccountTransfer _accountTransferDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AccountTransfer();
  object.amount = reader.readDouble(offsets[0]);
  object.fromFundUuid = reader.readString(offsets[1]);
  object.id = id;
  object.note = reader.readStringOrNull(offsets[2]);
  object.toFundUuid = reader.readString(offsets[3]);
  object.transferAt = reader.readDateTime(offsets[4]);
  object.uuid = reader.readString(offsets[5]);
  return object;
}

P _accountTransferDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _accountTransferGetId(AccountTransfer object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _accountTransferGetLinks(AccountTransfer object) {
  return [];
}

void _accountTransferAttach(
    IsarCollection<dynamic> col, Id id, AccountTransfer object) {
  object.id = id;
}

extension AccountTransferByIndex on IsarCollection<AccountTransfer> {
  Future<AccountTransfer?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  AccountTransfer? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<AccountTransfer?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<AccountTransfer?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(AccountTransfer object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(AccountTransfer object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<AccountTransfer> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<AccountTransfer> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension AccountTransferQueryWhereSort
    on QueryBuilder<AccountTransfer, AccountTransfer, QWhere> {
  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhere> anyTransferAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'transferAt'),
      );
    });
  }
}

extension AccountTransferQueryWhere
    on QueryBuilder<AccountTransfer, AccountTransfer, QWhereClause> {
  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause> idBetween(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      fromFundUuidEqualTo(String fromFundUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fromFundUuid',
        value: [fromFundUuid],
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      fromFundUuidNotEqualTo(String fromFundUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromFundUuid',
              lower: [],
              upper: [fromFundUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromFundUuid',
              lower: [fromFundUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromFundUuid',
              lower: [fromFundUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fromFundUuid',
              lower: [],
              upper: [fromFundUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      toFundUuidEqualTo(String toFundUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toFundUuid',
        value: [toFundUuid],
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      toFundUuidNotEqualTo(String toFundUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toFundUuid',
              lower: [],
              upper: [toFundUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toFundUuid',
              lower: [toFundUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toFundUuid',
              lower: [toFundUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toFundUuid',
              lower: [],
              upper: [toFundUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      transferAtEqualTo(DateTime transferAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'transferAt',
        value: [transferAt],
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      transferAtNotEqualTo(DateTime transferAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'transferAt',
              lower: [],
              upper: [transferAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'transferAt',
              lower: [transferAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'transferAt',
              lower: [transferAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'transferAt',
              lower: [],
              upper: [transferAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      transferAtGreaterThan(
    DateTime transferAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'transferAt',
        lower: [transferAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      transferAtLessThan(
    DateTime transferAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'transferAt',
        lower: [],
        upper: [transferAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterWhereClause>
      transferAtBetween(
    DateTime lowerTransferAt,
    DateTime upperTransferAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'transferAt',
        lower: [lowerTransferAt],
        includeLower: includeLower,
        upper: [upperTransferAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AccountTransferQueryFilter
    on QueryBuilder<AccountTransfer, AccountTransfer, QFilterCondition> {
  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromFundUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fromFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fromFundUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromFundUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      fromFundUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fromFundUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteEqualTo(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteGreaterThan(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteLessThan(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteBetween(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteStartsWith(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteEndsWith(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toFundUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toFundUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toFundUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toFundUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      toFundUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toFundUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      transferAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transferAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      transferAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transferAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      transferAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transferAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      transferAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transferAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidEqualTo(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidGreaterThan(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidLessThan(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidBetween(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidStartsWith(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidEndsWith(
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

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension AccountTransferQueryObject
    on QueryBuilder<AccountTransfer, AccountTransfer, QFilterCondition> {}

extension AccountTransferQueryLinks
    on QueryBuilder<AccountTransfer, AccountTransfer, QFilterCondition> {}

extension AccountTransferQuerySortBy
    on QueryBuilder<AccountTransfer, AccountTransfer, QSortBy> {
  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByFromFundUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromFundUuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByFromFundUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromFundUuid', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByToFundUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toFundUuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByToFundUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toFundUuid', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByTransferAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferAt', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByTransferAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferAt', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension AccountTransferQuerySortThenBy
    on QueryBuilder<AccountTransfer, AccountTransfer, QSortThenBy> {
  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByFromFundUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromFundUuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByFromFundUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromFundUuid', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByToFundUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toFundUuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByToFundUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toFundUuid', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByTransferAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferAt', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByTransferAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferAt', Sort.desc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension AccountTransferQueryWhereDistinct
    on QueryBuilder<AccountTransfer, AccountTransfer, QDistinct> {
  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct>
      distinctByFromFundUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromFundUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct>
      distinctByToFundUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toFundUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct>
      distinctByTransferAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transferAt');
    });
  }

  QueryBuilder<AccountTransfer, AccountTransfer, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension AccountTransferQueryProperty
    on QueryBuilder<AccountTransfer, AccountTransfer, QQueryProperty> {
  QueryBuilder<AccountTransfer, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AccountTransfer, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<AccountTransfer, String, QQueryOperations>
      fromFundUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromFundUuid');
    });
  }

  QueryBuilder<AccountTransfer, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<AccountTransfer, String, QQueryOperations> toFundUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toFundUuid');
    });
  }

  QueryBuilder<AccountTransfer, DateTime, QQueryOperations>
      transferAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transferAt');
    });
  }

  QueryBuilder<AccountTransfer, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
