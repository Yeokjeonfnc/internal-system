import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/features/properties/property_model.dart';

class PropertyApiService {
  final ApiClient _client = ApiClient();

  Future<List<Property>> getAllProperties() async {
    try {
      final response = await _client.get('/properties');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rows = data['data'] as List<dynamic>? ?? const [];
        return rows
            .map((json) => _mapToProperty(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
    return [];
  }

  Future<Property?> getProperty(int propIdx) async {
    try {
      final response = await _client.get('/properties/$propIdx');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final json = data['data'];
        if (json != null) return _mapToProperty(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching property: $e');
    }
    return null;
  }

  Future<Property?> createProperty(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/properties', data: data);
      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final json = responseData['data'];
        if (json != null) return _mapToProperty(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error creating property: $e');
    }
    return null;
  }

  Future<Property?> updateProperty(
    int propIdx,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put('/properties/$propIdx', data: data);
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final json = responseData['data'];
        if (json != null) return _mapToProperty(json as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error updating property: $e');
    }
    return null;
  }

  Future<bool> deleteProperty(int propIdx) async {
    try {
      final response = await _client.delete('/properties/$propIdx');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting property: $e');
    }
    return false;
  }

  Property _mapToProperty(Map<String, dynamic> json) {
    final propIdx = _intValue(json['propIdx']);
    return Property(
      no: propIdx,
      propIdx: propIdx,
      surveyDate: _formatYmd(json['surveyDt']?.toString() ?? ''),
      registrationDate: _formatYmd(json['createDt']?.toString() ?? ''),
      name: json['propNm']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      status: _statusFromApi(json['propStatus']?.toString()),
      ownership: _ownershipFromApi(json['propType']?.toString()),
      areaSqm: _doubleValue(json['contArea']),
      actualAreaSqm: _doubleValue(json['realArea']),
      keyMoney: _intValue(json['premiumFee']),
      deposit: _intValue(json['rentDeposit']),
      rent: _intValue(json['monthlyRent']),
      managementFee: _intValue(json['maintFee']),
      franchiseFlag: FranchiseFlag.nonFranchised,
      address: json['address']?.toString() ?? '',
      surveyor: json['surveyor']?.toString() ?? '',
      postalCode: json['zipCd']?.toString() ?? '',
      addressDetail: json['addressDetail']?.toString() ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      floor: json['floor']?.toString() ?? '',
      notes: json['propNotes']?.toString() ?? '',
    );
  }

  PropertyStatus _statusFromApi(String? value) {
    return switch (value) {
      'CONTRACTED' => PropertyStatus.contracted,
      'UNSUITABLE' => PropertyStatus.unsuitable,
      _ => PropertyStatus.pending,
    };
  }

  PropertyOwnership _ownershipFromApi(String? value) {
    return value == 'OWNED'
        ? PropertyOwnership.owned
        : PropertyOwnership.leased;
  }

  int _intValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatYmd(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.split('T').first;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
  }
}
