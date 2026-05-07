// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev002_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
  propIdx: (json['propIdx'] as num).toInt(),
  surveyDate: erpFormatYmdFromJson(json['surveyDt']),
  registrationDate: erpFormatYmdFromJson(json['createDt']),
  name: _stringAny(json['propNm']),
  region: _stringAny(json['region']),
  status: _propertyStatusFromJson(json['propStatus']),
  ownership: _propertyOwnershipFromJson(json['propType']),
  areaSqm: _doubleAny(json['contArea']),
  keyMoney: _intAny(json['premiumFee']),
  deposit: _intAny(json['rentDeposit']),
  rent: _intAny(json['monthlyRent']),
  franchiseFlag:
      $enumDecodeNullable(_$FranchiseFlagEnumMap, json['franchiseFlag']) ??
      FranchiseFlag.nonFranchised,
  address: _stringAny(json['address']),
  surveyor: _stringAny(json['surveyor']),
  location: json['location'] as String? ?? '-',
  floor: _stringAny(json['floor']),
  actualAreaSqm: _doubleAny(json['realArea']),
  notes: json['propNotes'] as String? ?? '',
  managementFee: _intAny(json['maintFee']),
  postalCode: json['zipCd'] as String? ?? '',
  addressDetail: json['addressDetail'] as String? ?? '',
  latitude: json['latitude'] as String?,
  longitude: json['longitude'] as String?,
  addressScope:
      $enumDecodeNullable(_$AddressScopeEnumMap, json['addressScope']) ??
      AddressScope.domestic,
);

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
  'propIdx': instance.propIdx,
  'surveyDt': instance.surveyDate,
  'createDt': instance.registrationDate,
  'propNm': instance.name,
  'region': instance.region,
  'propStatus': _$PropertyStatusEnumMap[instance.status]!,
  'propType': _$PropertyOwnershipEnumMap[instance.ownership]!,
  'contArea': instance.areaSqm,
  'realArea': instance.actualAreaSqm,
  'premiumFee': instance.keyMoney,
  'rentDeposit': instance.deposit,
  'monthlyRent': instance.rent,
  'maintFee': instance.managementFee,
  'franchiseFlag': _$FranchiseFlagEnumMap[instance.franchiseFlag]!,
  'address': instance.address,
  'surveyor': instance.surveyor,
  'location': instance.location,
  'floor': instance.floor,
  'propNotes': instance.notes,
  'zipCd': instance.postalCode,
  'addressDetail': instance.addressDetail,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'addressScope': _$AddressScopeEnumMap[instance.addressScope]!,
};

const _$FranchiseFlagEnumMap = {
  FranchiseFlag.franchised: 'franchised',
  FranchiseFlag.nonFranchised: 'nonFranchised',
};

const _$AddressScopeEnumMap = {
  AddressScope.domestic: 'domestic',
  AddressScope.overseas: 'overseas',
};

const _$PropertyStatusEnumMap = {
  PropertyStatus.contracted: 'contracted',
  PropertyStatus.pending: 'pending',
  PropertyStatus.unsuitable: 'unsuitable',
};

const _$PropertyOwnershipEnumMap = {
  PropertyOwnership.owned: 'owned',
  PropertyOwnership.leased: 'leased',
};
