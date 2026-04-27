import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';

class CodeOption {
  const CodeOption({required this.codeCd, required this.codeNm});

  final String codeCd;
  final String codeNm;

  factory CodeOption.fromJson(Map<String, dynamic> json) {
    return CodeOption(
      codeCd: json['codeCd']?.toString() ?? '',
      codeNm: json['codeNm']?.toString() ?? '',
    );
  }
}

class CommonCodeApiService {
  final ApiClient _client = ApiClient();

  Future<List<CodeOption>> getCodes(int grpCd) async {
    try {
      final response = await _client.get(
        '/codes',
        queryParameters: {'grpCd': grpCd},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> jsonList = data['data'] ?? [];
        return jsonList
            .map((json) => CodeOption.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching common codes: $e');
    }
    return [];
  }
}
