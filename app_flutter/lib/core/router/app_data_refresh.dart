// 라우트 이동과 공통 액션 버튼에서 화면 데이터 캐시를 일괄 무효화한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/pages/dashboard/dsh001/dsh001_screen.dart'
    show dashboardHomeDataProvider;

import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/development/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/development/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/development/dev003/dev003_controller.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';

import 'package:app_flutter/pages/master/mst006/mst006_controller.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';

void refreshAllScreenData(WidgetRef ref) {
  SessionListCache.clearAll();
  ref.invalidate(dashboardHomeDataProvider);
  ref.invalidate(storeDataProvider);
  ref.invalidate(regionNamesProvider);
  ref.invalidate(brandNamesProvider);
  ref.invalidate(codeOptionsProvider(10));
  ref.invalidate(codeOptionsProvider(20));
  ref.invalidate(codeOptionsProvider(30));
  ref.invalidate(codeOptionsProvider(40));
  ref.invalidate(storeProvider);
  ref.invalidate(partnerDataProvider);
  ref.invalidate(partnerCodeOptionsProvider(20));
  ref.invalidate(partnerProvider);
  ref.invalidate(propertyDataProvider);
  ref.invalidate(propertyCodeOptionsProvider(20));
  ref.invalidate(propertyProvider);
  ref.invalidate(userDataProvider);
  ref.invalidate(userProvider);
  ref.invalidate(dev003DataProvider);
  ref.invalidate(salesAreaProvider);
  ref.invalidate(ownerUserDataProvider);
  ref.invalidate(eapDocumentsProvider);
  ref.invalidate(eapDocumentDetailProvider);
  ref.invalidate(eapFormsProvider);
  ref.invalidate(eapEnabledFormsProvider);
  ref.invalidate(eapFormDetailProvider);
}
