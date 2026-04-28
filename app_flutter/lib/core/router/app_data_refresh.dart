// 라우트 이동과 공통 액션 버튼에서 화면 데이터 캐시를 일괄 무효화한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:app_flutter/features/founders/partner_controller.dart';
import 'package:app_flutter/features/master/employee_controller.dart';
import 'package:app_flutter/features/properties/property_controller.dart';
import 'package:app_flutter/features/sales_area/sales_area_controller.dart';
import 'package:app_flutter/features/stores/store_controller.dart';

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
  ref.invalidate(employeeProvider);
  ref.invalidate(salesAreaProvider);
}
