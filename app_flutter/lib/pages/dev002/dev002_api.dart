import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/dev002/dev002_model.dart';

class PropertyApiService extends BaseRepository {
  Future<List<Property>> getAllProperties() async {
    try {
      return await getDataList('/properties', fromJson: Property.fromJson);
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
    return const [];
  }

  Future<Property?> getProperty(int propIdx) async {
    try {
      return await getDataOrNull(
        '/properties/$propIdx',
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching property: $e');
    }
    return null;
  }

  Future<Property?> createProperty(Map<String, dynamic> data) async {
    try {
      return await postDataOrNull(
        '/properties',
        data: data,
        fromJson: Property.fromJson,
      );
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
      return await putDataOrNull(
        '/properties/$propIdx',
        data: data,
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating property: $e');
    }
    return null;
  }

  Future<bool> deleteProperty(int propIdx) =>
      deleteOk('/properties/$propIdx');
}
