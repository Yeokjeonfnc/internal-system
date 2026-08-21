import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';

abstract final class UsageLogApiPaths {
  static const String root = '/usage-logs';
  static const String menu = '$root/menu';
  static const String entryTags = '$root/entry-tags';
}

class UsageLogApiService extends BaseRepository {
  Future<bool> recordMenu({
    required String userId,
    required String userNm,
    String? deptNm,
    String? positionNm,
    String? svYn,
    String? menuCd,
    required String menuLabel,
  }) async {
    try {
      await client.post(
        UsageLogApiPaths.menu,
        data: <String, dynamic>{
          'userId': userId,
          'userNm': userNm,
          'deptNm': ?deptNm,
          'positionNm': ?positionNm,
          'svYn': ?svYn,
          'menuCd': ?menuCd,
          'menuLabel': menuLabel,
        },
        options: Options(extra: const {'quiet': true}),
      );
      return true;
    } catch (_) {
      // 백엔드 재시작 중 연결 실패는 업무에 영향 없는 부가 기록이라 콘솔에 남기지 않는다.
      return false;
    }
  }

  Future<List<UsageLogRow>> fetchList({
    String? userNm,
    String? useType,
    String tab = 'ALL',
    DateTime? startDt,
    DateTime? endDt,
  }) async {
    final qp = <String, dynamic>{
      'tab': tab,
      if (userNm != null && userNm.isNotEmpty) 'userNm': userNm,
      if (useType != null && useType.isNotEmpty) 'useType': useType,
      if (startDt != null) 'startDt': _fmtDate(startDt),
      if (endDt != null) 'endDt': _fmtDate(endDt),
    };
    try {
      final r = await client.get(UsageLogApiPaths.root, queryParameters: qp);
      if (r.statusCode != 200 || r.data == null) {
        return const [];
      }
      return parseDataList(r.data, UsageLogRow.fromJson);
    } catch (e, st) {
      debugPrint('fetchUsageLogs failed: $e\n$st');
      rethrow;
    }
  }

  Future<List<UsageLogRow>> fetchEntryTagsForActivity({
    required String userId,
    required int storeIdx,
    bool unlinkedOnly = true,
  }) async {
    return getDataList(
      UsageLogApiPaths.entryTags,
      queryParameters: {
        'userId': userId,
        'storeIdx': storeIdx,
        'unlinkedOnly': unlinkedOnly,
      },
      fromJson: UsageLogRow.fromJson,
    );
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class UsageLogRow {
  const UsageLogRow({
    required this.logIdx,
    required this.userId,
    required this.userNm,
    this.deptNm,
    this.positionNm,
    required this.useType,
    required this.useTypeNm,
    required this.useDetail,
    required this.usedAt,
    this.storeIdx,
    this.storeNm,
    this.tagUid,
    this.distanceM,
  });

  final int logIdx;
  final String userId;
  final String userNm;
  final String? deptNm;
  final String? positionNm;
  final String useType;
  final String useTypeNm;
  final String useDetail;
  final DateTime usedAt;
  final int? storeIdx;
  final String? storeNm;
  final String? tagUid;
  final int? distanceM;

  factory UsageLogRow.fromJson(Map<String, dynamic> json) {
    final usedRaw = json['usedAt']?.toString() ?? '';
    return UsageLogRow(
      logIdx: (json['logIdx'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      userNm: json['userNm']?.toString() ?? '',
      deptNm: json['deptNm']?.toString(),
      positionNm: json['positionNm']?.toString(),
      useType: json['useType']?.toString() ?? '',
      useTypeNm: json['useTypeNm']?.toString() ?? '',
      useDetail: json['useDetail']?.toString() ?? '',
      usedAt: DateTime.tryParse(usedRaw) ?? DateTime.now(),
      storeIdx: (json['storeIdx'] as num?)?.toInt(),
      storeNm: json['storeNm']?.toString(),
      tagUid: json['tagUid']?.toString(),
      distanceM: (json['distanceM'] as num?)?.toInt(),
    );
  }

  String get usedAtLabel {
    final local = usedAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
