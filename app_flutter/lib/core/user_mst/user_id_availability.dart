import 'package:app_flutter/core/user_mst/user_mst_api_json_keys.dart';

/// `GET /users/check-user-id` 응답 — 백엔드 `UserIdAvailabilityDto`.
class UserIdAvailability {
  static const String jsonKeyAvailable = UserMstApiJsonKeys.available;

  const UserIdAvailability({required this.available});

  final bool available;

  factory UserIdAvailability.fromJson(Map<String, dynamic> json) {
    return UserIdAvailability(
      available: json[jsonKeyAvailable] as bool? ?? false,
    );
  }
}
