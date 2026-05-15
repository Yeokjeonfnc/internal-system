import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/property_mst/property_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

part 'dev002_model.g.dart';

// /// 물건 구분 (자가/임대차).
enum Ownership { owned, lease }

String ownershipLabelKo(Ownership s) => switch (s) {
  Ownership.owned => '자가',
  Ownership.lease => '임대차',
};

Ownership _ownershipFromJson(Object? v) =>
    v?.toString() == 'OWNED' ? Ownership.owned : Ownership.lease;

/// 물건 상태 (체결/보류/부적합).
enum PropStatus { contracted, pending, unsuitable }

String propStatusLabelKo(PropStatus s) => switch (s) {
  PropStatus.contracted => '체결물건',
  PropStatus.pending => '보류물건',
  PropStatus.unsuitable => '부적합물건',
};

PropStatus _propStatusFromJson(Object? v) => v?.toString() == 'CONTRACTED'
    ? PropStatus.contracted
    : v?.toString() == 'PENDING'
    ? PropStatus.pending
    : PropStatus.unsuitable;

/// 가맹 여부 (가맹/비가맹).
enum FranchiseFlag { franchised, nonFranchised }

/// 주소 구분 (국내/국외).
enum AddressScope { domestic, overseas }

/// API가 위도·경도를 문자열 또는 숫자로 줄 수 있음 — `as String?` 캐스트는 런타임 오류로 목록 전체 파싱이 실패한다.
String? _coordStringFromJson(Object? v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}

/// 물건 모델.
@JsonSerializable()
class Property {
  const Property({
    required this.propIdx,
    required this.surveyDate,
    required this.registrationDate,
    required this.name,
    required this.region,
    required this.propStatus,
    required this.ownership,
    required this.areaSqm,
    required this.parkingCount,
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

  @JsonKey(name: PropertyMstApiJsonKeys.propIdx)
  final int propIdx;

  int get no => propIdx;

  @JsonKey(
    name: PropertyMstApiJsonKeys.surveyDt,
    fromJson: erpFormatYmdFromJson,
  )
  final String surveyDate;

  @JsonKey(
    name: PropertyMstApiJsonKeys.createDt,
    fromJson: erpFormatYmdFromJson,
  )
  final String registrationDate;

  @JsonKey(name: PropertyMstApiJsonKeys.propNm, fromJson: _stringAny)
  final String name;

  @JsonKey(name: PropertyMstApiJsonKeys.region, fromJson: _stringAny)
  final String region;

  @JsonKey(
    name: PropertyMstApiJsonKeys.propStatus,
    fromJson: _propStatusFromJson,
  )
  final PropStatus propStatus;

  @JsonKey(name: PropertyMstApiJsonKeys.propType, fromJson: _ownershipFromJson)
  final Ownership ownership;

  @JsonKey(name: PropertyMstApiJsonKeys.contArea, fromJson: _doubleAny)
  final double areaSqm;

  @JsonKey(name: PropertyMstApiJsonKeys.realArea, fromJson: _doubleAny)
  final double actualAreaSqm;

  @JsonKey(name: PropertyMstApiJsonKeys.premiumFee, fromJson: _intAny)
  final int keyMoney;

  @JsonKey(name: PropertyMstApiJsonKeys.rentDeposit, fromJson: _intAny)
  final int deposit;

  @JsonKey(name: PropertyMstApiJsonKeys.monthlyRent, fromJson: _intAny)
  final int rent;

  @JsonKey(name: PropertyMstApiJsonKeys.maintFee, fromJson: _intAny)
  final int managementFee;

  @JsonKey(
    name: PropertyMstApiJsonKeys.franchiseFlag,
    defaultValue: FranchiseFlag.nonFranchised,
  )
  final FranchiseFlag franchiseFlag;

  @JsonKey(name: PropertyMstApiJsonKeys.address, fromJson: _stringAny)
  final String address;

  @JsonKey(name: PropertyMstApiJsonKeys.surveyor, fromJson: _stringAny)
  final String surveyor;

  @JsonKey(name: PropertyMstApiJsonKeys.location, defaultValue: '-')
  final String location;

  @JsonKey(name: PropertyMstApiJsonKeys.floor, fromJson: _stringAny)
  final String floor;

  @JsonKey(name: PropertyMstApiJsonKeys.parkingCount, fromJson: _stringAny)
  final String parkingCount;

  @JsonKey(name: PropertyMstApiJsonKeys.propNotes, defaultValue: '')
  final String notes;

  @JsonKey(name: PropertyMstApiJsonKeys.zipCd, defaultValue: '')
  final String postalCode;

  @JsonKey(name: PropertyMstApiJsonKeys.addressDetail, defaultValue: '')
  final String addressDetail;

  @JsonKey(
    name: PropertyMstApiJsonKeys.latitude,
    fromJson: _coordStringFromJson,
  )
  final String? latitude;

  @JsonKey(
    name: PropertyMstApiJsonKeys.longitude,
    fromJson: _coordStringFromJson,
  )
  final String? longitude;

  @JsonKey(
    name: PropertyMstApiJsonKeys.addressScope,
    defaultValue: AddressScope.domestic,
  )
  final AddressScope addressScope;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

int _intAny(Object? e) => e.asJsonInt();

double _doubleAny(Object? e) => e.asJsonDouble();

String _stringAny(Object? e) => e?.toString() ?? '';
