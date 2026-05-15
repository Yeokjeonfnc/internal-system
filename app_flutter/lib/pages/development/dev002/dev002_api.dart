import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/core/property_mst/property_mst_write_request.dart';

/// 물건 API — 백엔드 `DevController` (`/properties`).

class PropertyApiService extends BaseRepository {
  Future<List<Property>> getAllProperties() async {
    try {
      return await getDataList(
        PropertyMstApiPaths.root,
        fromJson: Property.fromJson,
      );
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

  /// 성공 시 `(property, null)`, 실패 시 `(null, 서버 message 또는 안내 문구)`.
  Future<(Property?, String?)> createProperty(
    PropertyMstWriteRequest body,
  ) async {
    try {
      final r = await client.post(
        PropertyMstApiPaths.root,
        data: body.toRequestBody(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      if (!envelopeSuccess(r.data)) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      final p = parseDataOrNull(r.data, Property.fromJson);
      if (p == null) {
        return (null, '저장에 실패했습니다.');
      }
      return (p, null);
    } on DioException catch (e) {
      debugPrint('Error creating property: $e');
      final msg = envelopeMessage(e.response?.data);
      return (null, (msg != null && msg.isNotEmpty) ? msg : '저장에 실패했습니다.');
    } catch (e) {
      debugPrint('Error creating property: $e');
      return (null, '저장에 실패했습니다.');
    }
  }

  /// 성공 시 `(property, null)`, 실패 시 `(null, 서버 message 또는 안내 문구)`.
  Future<(Property?, String?)> updateProperty(
    int propIdx,
    PropertyMstWriteRequest body,
  ) async {
    try {
      final r = await client.put(
        PropertyMstApiPaths.one(propIdx),
        data: body.toRequestBody(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      if (!envelopeSuccess(r.data)) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      final p = parseDataOrNull(r.data, Property.fromJson);
      if (p == null) {
        return (null, '저장에 실패했습니다.');
      }
      return (p, null);
    } on DioException catch (e) {
      debugPrint('Error updating property: $e');
      final msg = envelopeMessage(e.response?.data);
      return (null, (msg != null && msg.isNotEmpty) ? msg : '저장에 실패했습니다.');
    } catch (e) {
      debugPrint('Error updating property: $e');
      return (null, '저장에 실패했습니다.');
    }
  }

  Future<bool> deleteProperty(int propIdx) =>
      deleteOk(PropertyMstApiPaths.one(propIdx));
}
