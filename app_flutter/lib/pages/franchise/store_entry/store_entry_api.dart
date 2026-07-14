import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/store_mst/store_mst_write_request.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_model.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_nfc_uid.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';

abstract final class StoreEntryApiPaths {
  static const String tag = '/usage-logs/tag';
  static const String lookupByNfc = '${StoreMstApiPaths.root}/by-nfc-tag';
}

class StoreEntryApiService extends BaseRepository {
  static const int maxEntryDistanceM = 200;
  static const int nearbyRadiusM = 1000;
  static const int nearbyLimit = 20;

  Future<StoreNfcTagLookup> lookupByTagUid(String tagUid) async {
    try {
      final r = await client.get(
        StoreEntryApiPaths.lookupByNfc,
        queryParameters: {'tagUid': tagUid},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (r.statusCode == 404) {
        throw StateError(
          readEnvelopeMessage(r.data) ??
              '등록된 NFC 태그가 아닙니다.\n가맹점 상세에서 태그를 먼저 등록해 주세요.',
        );
      }
      if (!isHttpSuccess(r.statusCode) || !envelopeSuccess(r.data)) {
        throw StateError(
          readEnvelopeMessage(r.data) ?? '가맹점 정보를 불러오지 못했습니다.',
        );
      }
      final data = parseDataMapOrNull(r.data);
      if (data == null) {
        throw StateError('가맹점 정보를 불러오지 못했습니다.');
      }
      return StoreNfcTagLookup.fromJson(data);
    } on DioException catch (e) {
      throw StateError(
        dioErrorMessage(e, fallback: '가맹점 정보를 불러오지 못했습니다.'),
      );
    }
  }

  /// 클라이언트 거리 검증 — [maxEntryDistanceM] 초과 시 예외.
  int distanceToStoreM({
    required double userLat,
    required double userLng,
    required double storeLat,
    required double storeLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      storeLat,
      storeLng,
    ).round();
  }

  void ensureWithinEntryRange(
    int distanceM, {
    String? storeNm,
  }) {
    if (distanceM > maxEntryDistanceM) {
      final name = (storeNm ?? '').trim();
      final prefix = name.isEmpty ? '' : '[$name] ';
      throw StateError(
        '$prefix매장 등록 좌표와 현재 위치가 ${distanceM}m 떨어져 있습니다.\n'
        '200m 이내에서 태그하거나, 가맹점 상세에서 위·경도를 실제 매장 위치로 수정해 주세요.',
      );
    }
  }

  /// [store_mst] 위·경도 기준 [nearbyRadiusM] 이내 가맹점.
  Future<List<NearbyStoreRow>> nearbyStores({
    required double latitude,
    required double longitude,
  }) async {
    final stores = await StoreApiService().getAllStores();
    final hits = <NearbyStoreRow>[];
    for (final store in stores) {
      final lat = _parseCoord(store.latitude);
      final lng = _parseCoord(store.longitude);
      if (lat == null || lng == null) continue;
      final name = store.storeNm.trim();
      if (name.isEmpty) continue;
      final dist = Geolocator.distanceBetween(
        latitude,
        longitude,
        lat,
        lng,
      ).round();
      if (dist > nearbyRadiusM) continue;
      hits.add(
        NearbyStoreRow(
          storeIdx: store.storeIdx,
          storeNm: name,
          brandLabel: store.brandNm.trim(),
          distanceM: dist,
          lat: lat,
          lng: lng,
        ),
      );
    }
    hits.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    if (hits.length <= nearbyLimit) return hits;
    return hits.sublist(0, nearbyLimit);
  }

  static double? _parseCoord(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim());
  }

  Future<void> recordTag({
    required String userId,
    required String userNm,
    String? deptNm,
    String? positionNm,
    required String svYn,
    required int storeIdx,
    required String storeNm,
    required String address,
    required String tagUid,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await client.post(
        StoreEntryApiPaths.tag,
        data: <String, dynamic>{
          'userId': userId,
          'userNm': userNm,
          'deptNm': ?deptNm,
          'positionNm': ?positionNm,
          'svYn': svYn,
          'storeIdx': storeIdx,
          'storeNm': storeNm,
          'address': address,
          'tagUid': tagUid,
          'lat': latitude,
          'lng': longitude,
        },
      );
    } on DioException catch (e) {
      throw StateError(
        dioErrorMessage(e, fallback: '출입 태그 등록에 실패했습니다.'),
      );
    }
  }
}

/// 가맹점 NFC 태그 UID 등록 API.
class StoreNfcTagApiService extends BaseRepository {
  Future<StoreNfcTagRegistration?> fetchByStore(int storeIdx) async {
    return getDataOrNull(
      StoreMstApiPaths.nfcTag(storeIdx),
      fromJson: StoreNfcTagRegistration.fromJson,
    );
  }

  static const String _nfcFallback = 'NFC 태그 저장에 실패했습니다.';

  Future<StoreNfcTagRegistration> register({
    required int storeIdx,
    required String tagUid,
    String? registeredBy,
  }) async {
    final normalizedUid = normalizeNfcTagUid(tagUid);
    if (normalizedUid.isEmpty) {
      throw StateError('NFC 태그 UID를 입력해 주세요.');
    }
    if (normalizedUid.length < 8) {
      throw StateError('NFC 태그 UID 형식이 올바르지 않습니다.');
    }
    try {
      final r = await client.put(
        StoreMstApiPaths.nfcTag(storeIdx),
        data: <String, dynamic>{
          'tagUid': normalizedUid,
          if (registeredBy != null && registeredBy.isNotEmpty)
            'registeredBy': registeredBy,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final msg = envelopeMessage(r.data);
      if (!isHttpSuccess(r.statusCode)) {
        throw StateError(msg ?? _nfcFallback);
      }
      if (!envelopeSuccess(r.data)) {
        throw StateError(msg ?? _nfcFallback);
      }
      final data = parseDataMapOrNull(r.data);
      if (data != null) {
        return StoreNfcTagRegistration.fromJson(data);
      }
      return StoreNfcTagRegistration(
        storeIdx: storeIdx,
        tagUid: normalizedUid,
      );
    } on DioException catch (e) {
      throw StateError(dioErrorMessage(e, fallback: _nfcFallback));
    }
  }

  Future<void> remove(int storeIdx) async {
    const fallback = 'NFC 태그 해제에 실패했습니다.';
    try {
      final r = await client.delete(
        StoreMstApiPaths.nfcTag(storeIdx),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (!isHttpSuccess(r.statusCode)) {
        throw StateError(envelopeMessage(r.data) ?? fallback);
      }
      if (!envelopeSuccess(r.data)) {
        throw StateError(envelopeMessage(r.data) ?? fallback);
      }
    } on DioException catch (e) {
      throw StateError(dioErrorMessage(e, fallback: fallback));
    }
  }
}
