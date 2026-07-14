import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/owner_user/owner_user_write_request.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

/// 가맹점주 — `OwnerUserMstDto`.
class OwnerUser {
  const OwnerUser({
    required this.userIdx,
    required this.ownerName,
    required this.storeNm,
    this.storeIdx,
    required this.userId,
    required this.email,
    required this.mobilePhone,
  });

  final int userIdx;
  final String ownerName;
  final String storeNm;
  final int? storeIdx;
  final String userId;
  final String email;
  final String mobilePhone;

  factory OwnerUser.fromJson(Map<String, dynamic> json) {
    return OwnerUser(
      userIdx: asJsonIntOpt(json[OwnerUserApiJsonKeys.userIdx]) ?? 0,
      ownerName: json.jsonString(OwnerUserApiJsonKeys.userName),
      storeNm: json.jsonString(OwnerUserApiJsonKeys.storeNm),
      storeIdx: asJsonIntOpt(json[OwnerUserApiJsonKeys.storeIdx]),
      userId: json.jsonString(OwnerUserApiJsonKeys.userId),
      email: json.jsonString(OwnerUserApiJsonKeys.userEmail),
      mobilePhone: json.jsonString(OwnerUserApiJsonKeys.userPhone),
    );
  }

  static OwnerUserWriteRequest buildCreateRequest({
    required String ownerName,
    required String userPassword,
    required String userId,
    required int storeIdx,
    String mobilePhone = '',
    String email = '',
  }) {
    return OwnerUserWriteRequest.fromMap({
      OwnerUserApiJsonKeys.userName: ownerName.trim(),
      OwnerUserApiJsonKeys.userPassword: userPassword,
      OwnerUserApiJsonKeys.userId: userId.trim(),
      OwnerUserApiJsonKeys.storeIdx: storeIdx,
      OwnerUserApiJsonKeys.userPhone: formatKoreanPhoneDisplay(mobilePhone),
      OwnerUserApiJsonKeys.userEmail: email.trim(),
    });
  }

  static OwnerUserWriteRequest buildUpdateRequest({
    String? ownerName,
    String? userPassword,
    String? userId,
    int? storeIdx,
    String? mobilePhone,
    String? email,
  }) {
    final m = <String, dynamic>{};
    if (ownerName != null) {
      m[OwnerUserApiJsonKeys.userName] = ownerName.trim();
    }
    if (userPassword != null && userPassword.isNotEmpty) {
      m[OwnerUserApiJsonKeys.userPassword] = userPassword;
    }
    if (userId != null) {
      m[OwnerUserApiJsonKeys.userId] = userId.trim();
    }
    if (storeIdx != null) {
      m[OwnerUserApiJsonKeys.storeIdx] = storeIdx;
    }
    if (mobilePhone != null) {
      m[OwnerUserApiJsonKeys.userPhone] = formatKoreanPhoneDisplay(mobilePhone);
    }
    if (email != null) {
      m[OwnerUserApiJsonKeys.userEmail] = email.trim();
    }
    return OwnerUserWriteRequest.fromMap(m);
  }
}
