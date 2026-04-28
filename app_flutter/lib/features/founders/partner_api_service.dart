import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/features/founders/partner_model.dart';

class PartnerApiService {
  final ApiClient _client = ApiClient();

  Future<List<Partner>> getAllPartners() async {
    try {
      final response = await _client.get('/partners');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rows = data['data'] as List<dynamic>? ?? const [];
        return rows
            .map((json) => _mapToPartner(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching partners: $e');
    }
    return [];
  }

  Future<Partner?> getPartner(int partnerIdx) async {
    try {
      final response = await _client.get('/partners/$partnerIdx');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final json = data['data'];
        if (json != null) return _mapToPartner(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching partner: $e');
    }
    return null;
  }

  Future<Partner?> createPartner(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/partners', data: data);
      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final json = responseData['data'];
        if (json != null) return _mapToPartner(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error creating partner: $e');
    }
    return null;
  }

  Future<Partner?> updatePartner(
    int partnerIdx,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put('/partners/$partnerIdx', data: data);
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final json = responseData['data'];
        if (json != null) return _mapToPartner(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error updating partner: $e');
    }
    return null;
  }

  Partner _mapToPartner(Map<String, dynamic> json) {
    final status = _statusFromApi(json['partnerStatus']?.toString());
    return Partner(
      partnerIdx: json['partnerIdx'] ?? 0,
      createDt: _formatYmd(json['createDt']?.toString() ?? ''),
      partnerNm: json['partnerNm']?.toString() ?? '',
      partnerTel: json['partnerTel']?.toString() ?? '',
      partnerEmail: json['partnerEmail']?.toString() ?? '',
      gender: _genderFromApi(json['gender']?.toString()),
      partnerBirth: _formatYmd(json['partnerBirth']?.toString() ?? ''),
      pZipCd: _jsonString(json, 'pZipCd'),
      pAddress: _jsonString(json, 'pAddress'),
      pAddressDetail: _jsonString(json, 'pAddressDetail'),
      evaluationStatus: EvaluationStatus.pending,
      evaluationScore: null,
      pRegion: _jsonString(json, 'pRegion'),
      partnerStatus: status,
    );
  }

  String _jsonString(Map<String, dynamic> json, String key) {
    return json[key]?.toString() ??
        json[_upperFirst(key)]?.toString() ??
        json[_camelToSnake(key)]?.toString() ??
        '';
  }

  String _upperFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _camelToSnake(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper && i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  PartnerStatus _statusFromApi(String? value) {
    return value == '가맹점사업자'
        ? PartnerStatus.franchisee
        : PartnerStatus.prospect;
  }

  Gender _genderFromApi(String? value) {
    return value == 'F' || value == '여' ? Gender.female : Gender.male;
  }

  String _formatYmd(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.split('T').first;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
  }
}
