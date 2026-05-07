import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';

part 'dev002_model.g.dart';

/// 물건 구분 (자가/임대차).
enum PropertyOwnership { owned, leased }

/// 물건 상태 (체결/보류/부적합).
enum PropertyStatus { contracted, pending, unsuitable }

/// 가맹 여부 (가맹/비가맹).
enum FranchiseFlag { franchised, nonFranchised }

/// 주소 구분 (국내/국외).
enum AddressScope { domestic, overseas }

PropertyStatus _propertyStatusFromJson(Object? v) {
  return switch (v?.toString()) {
    'CONTRACTED' => PropertyStatus.contracted,
    'UNSUITABLE' => PropertyStatus.unsuitable,
    _ => PropertyStatus.pending,
  };
}

PropertyOwnership _propertyOwnershipFromJson(Object? v) =>
    v?.toString() == 'OWNED'
        ? PropertyOwnership.owned
        : PropertyOwnership.leased;

/// 물건 모델.
@JsonSerializable()
class Property {
  const Property({
    required this.propIdx,
    required this.surveyDate,
    required this.registrationDate,
    required this.name,
    required this.region,
    required this.status,
    required this.ownership,
    required this.areaSqm,
    required this.keyMoney,
    required this.deposit,
    required this.rent,
    required this.franchiseFlag,
    required this.address,
    required this.surveyor,
    required this.location,
    required this.floor,
    required this.actualAreaSqm,
    required this.notes,
    required this.managementFee,
    required this.postalCode,
    required this.addressDetail,
    this.latitude,
    this.longitude,
    required this.addressScope,
  });

  @JsonKey(name: 'propIdx')
  final int propIdx;

  int get no => propIdx;

  @JsonKey(name: 'surveyDt', fromJson: erpFormatYmdFromJson)
  final String surveyDate;

  @JsonKey(name: 'createDt', fromJson: erpFormatYmdFromJson)
  final String registrationDate;

  @JsonKey(name: 'propNm', fromJson: _stringAny)
  final String name;

  @JsonKey(fromJson: _stringAny)
  final String region;

  @JsonKey(name: 'propStatus', fromJson: _propertyStatusFromJson)
  final PropertyStatus status;

  @JsonKey(name: 'propType', fromJson: _propertyOwnershipFromJson)
  final PropertyOwnership ownership;

  @JsonKey(name: 'contArea', fromJson: _doubleAny)
  final double areaSqm;

  @JsonKey(name: 'realArea', fromJson: _doubleAny)
  final double actualAreaSqm;

  @JsonKey(name: 'premiumFee', fromJson: _intAny)
  final int keyMoney;

  @JsonKey(name: 'rentDeposit', fromJson: _intAny)
  final int deposit;

  @JsonKey(name: 'monthlyRent', fromJson: _intAny)
  final int rent;

  @JsonKey(name: 'maintFee', fromJson: _intAny)
  final int managementFee;

  @JsonKey(defaultValue: FranchiseFlag.nonFranchised)
  final FranchiseFlag franchiseFlag;

  @JsonKey(fromJson: _stringAny)
  final String address;

  @JsonKey(fromJson: _stringAny)
  final String surveyor;

  @JsonKey(defaultValue: '-')
  final String location;

  @JsonKey(fromJson: _stringAny)
  final String floor;

  @JsonKey(name: 'propNotes', defaultValue: '')
  final String notes;

  @JsonKey(name: 'zipCd', defaultValue: '')
  final String postalCode;

  @JsonKey(name: 'addressDetail', defaultValue: '')
  final String addressDetail;

  final String? latitude;

  final String? longitude;

  @JsonKey(defaultValue: AddressScope.domestic)
  final AddressScope addressScope;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

int _intAny(Object? e) => e.asJsonInt();

double _doubleAny(Object? e) => e.asJsonDouble();

String _stringAny(Object? e) => e?.toString() ?? '';
