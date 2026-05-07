// 라우트 이동과 공통 액션 버튼에서 화면 데이터 캐시를 일괄 무효화한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/dsh001/dsh001_view_model.dart';
import 'package:app_flutter/pages/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/dev003/dev003_controller.dart';
import 'package:app_flutter/pages/str001/str001_controller.dart';

void refreshAllScreenData(WidgetRef ref) {
  ref.invalidate(dashboardViewModelProvider);
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
  ref.invalidate(employeeDataProvider);
  ref.invalidate(employeeProvider);
  ref.invalidate(dev003DataProvider);
  ref.invalidate(salesAreaProvider);
}
