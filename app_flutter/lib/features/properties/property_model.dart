/// 물건 구분 (자가/임대차).
enum PropertyOwnership { owned, leased }

/// 물건 상태 (체결/보류/부적합).
enum PropertyStatus { contracted, pending, unsuitable }

/// 가맹 여부 (가맹/비가맹).
enum FranchiseFlag { franchised, nonFranchised }

/// 주소 구분 (국내/국외).
enum AddressScope { domestic, overseas }

/// 물건 모델.
class Property {
  const Property({
    required this.no,
    required this.propIdx,
    required this.surveyDate,
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
    this.registrationDate = '-',
    this.surveyor = '-',
    this.location = '-',
    this.floor = '-',
    this.actualAreaSqm = 0,
    this.notes = '',
    this.managementFee = 0,
    this.postalCode = '',
    this.addressDetail = '',
    this.latitude,
    this.longitude,
    this.addressScope = AddressScope.domestic,
  });

  final int no;
  final int propIdx;
  final String surveyDate;
  final String name;
  final String region;
  final PropertyStatus status;
  final PropertyOwnership ownership;
  final double areaSqm;
  final int keyMoney;
  final int deposit;
  final int rent;
  final FranchiseFlag franchiseFlag;
  final String address;
  final String registrationDate;
  final String surveyor;
  final String location;
  final String floor;
  final double actualAreaSqm;
  final String notes;
  final int managementFee;
  final String postalCode;
  final String addressDetail;
  final String? latitude;
  final String? longitude;
  final AddressScope addressScope;
}
