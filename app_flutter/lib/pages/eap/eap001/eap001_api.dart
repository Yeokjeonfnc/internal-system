// 전자결재(다우오피스) API.

import 'package:app_flutter/core/api/base_repository.dart';

class EapConnectionTestResult {
  const EapConnectionTestResult({
    required this.erpApiOk,
    required this.daouConfigured,
    required this.daouReachable,
    required this.daouAuthOk,
    required this.daouMessage,
    required this.erpApiBaseUrl,
    required this.daouApiBaseUrl,
    required this.callbackUrl,
    required this.formCode,
  });

  factory EapConnectionTestResult.fromJson(Map<String, dynamic> json) {
    return EapConnectionTestResult(
      erpApiOk: json['erpApiOk'] == true,
      daouConfigured: json['daouConfigured'] == true,
      daouReachable: json['daouReachable'] == true,
      daouAuthOk: json['daouAuthOk'] == true,
      daouMessage: json['daouMessage']?.toString() ?? '',
      erpApiBaseUrl: json['erpApiBaseUrl']?.toString() ?? '',
      daouApiBaseUrl: json['daouApiBaseUrl']?.toString() ?? '',
      callbackUrl: json['callbackUrl']?.toString() ?? '',
      formCode: json['formCode']?.toString() ?? '',
    );
  }

  final bool erpApiOk;
  final bool daouConfigured;
  final bool daouReachable;
  final bool daouAuthOk;
  final String daouMessage;
  final String erpApiBaseUrl;
  final String daouApiBaseUrl;
  final String callbackUrl;
  final String formCode;
}

class EapApiService extends BaseRepository {
  static const String healthPath = '/eap/health';
  static const String connectionTestPath = '/eap/connection-test';

  Future<bool> health() async {
    final map = await getDataMapOrNull(healthPath);
    return map?['status'] == 'UP';
  }

  Future<EapConnectionTestResult?> connectionTest() async {
    final map = await getDataMapOrNull(connectionTestPath);
    if (map == null) return null;
    return EapConnectionTestResult.fromJson(map);
  }
}
