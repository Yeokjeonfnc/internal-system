import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/core/property_mst/property_mst_write_payload.dart';

/// 물건 API — 백엔드 `DevController` (`/properties`).

class PropertyApiService extends BaseRepository {
  Future<List<Property>> getAllProperties() async {
    try {
      return await getDataList(PropertyMstApiPaths.root, fromJson: Property.fromJson);
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
    return const [];
  }

  Future<Property?> getProperty(int propIdx) async {
    try {
      return await getDataOrNull(
        PropertyMstApiPaths.one(propIdx),
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching property: $e');
    }
    return null;
  }

  Future<Property?> createProperty(PropertyMstWritePayload body) async {
    try {
      return await postDataOrNull(
        PropertyMstApiPaths.root,
        data: body.toRequestBody(),
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error creating property: $e');
    }
    return null;
  }

  Future<Property?> updateProperty(
    int propIdx,
    PropertyMstWritePayload body,
  ) async {
    try {
      return await putDataOrNull(
        PropertyMstApiPaths.one(propIdx),
        data: body.toRequestBody(),
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating property: $e');
    }
    return null;
  }

  Future<bool> deleteProperty(int propIdx) =>
      deleteOk(PropertyMstApiPaths.one(propIdx));
}
