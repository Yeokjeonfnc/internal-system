import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/dev001/dev001_model.dart';

class PartnerApiService extends BaseRepository {
  Future<List<Partner>> getAllPartners() async {
    try {
      return await getDataList('/partners', fromJson: Partner.fromJson);
    } catch (e) {
      debugPrint('Error fetching partners: $e');
    }
    return const [];
  }

  Future<Partner?> getPartner(int partnerIdx) async {
    try {
      return await getDataOrNull(
        '/partners/$partnerIdx',
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching partner: $e');
    }
    return null;
  }

  Future<Partner?> createPartner(Map<String, dynamic> data) async {
    try {
      return await postDataOrNull(
        '/partners',
        data: data,
        fromJson: Partner.fromJson,
      );
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
      return await putDataOrNull(
        '/partners/$partnerIdx',
        data: data,
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating partner: $e');
    }
    return null;
  }
}
