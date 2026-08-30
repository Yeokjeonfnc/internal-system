// 라우트 이동과 공통 액션 버튼에서 화면 데이터 캐시를 무효화한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';
import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/pages/dashboard/dsh001/dsh001_screen.dart'
    show dashboardHomeDataProvider;

import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/development/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/development/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/development/dev003/dev003_controller.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_provider.dart';

/// 저장·삭제 등 쓰기 작업 후 전체 무효화.
///
/// 쓰기는 어느 화면의 목록에 영향을 줄지 알 수 없으므로 여기서만 전부 비운다.
void refreshAllScreenData(WidgetRef ref) {
  SessionListCache.clearAll();
  _invalidateDashboard(ref);
  _invalidateStores(ref);
  _invalidatePartners(ref);
  _invalidateProperties(ref);
  _invalidateSalesAreas(ref);
  _invalidateUsers(ref);
  _invalidateEap(ref);
  _invalidateMail(ref);
}

/// 화면 이동 시 무효화 — 방금 들어간 화면의 목록만 갱신한다.
///
/// 이동할 때마다 [refreshAllScreenData] 를 부르면 stale-while-revalidate 용도인
/// SessionListCache 까지 매번 비워져 캐시 적중률이 구조적으로 0 이 되고(그 캐시는
/// 쓰기 작업 후 무효화가 전제다), 관계없는 화면의 대용량 목록까지 통째로 다시
/// 내려받는다. 무효화 범위를 들어간 화면으로 좁혀 재진입 시 스피너 없이
/// 이전 데이터를 먼저 그리게 한다.
void refreshRouteScreenData(WidgetRef ref, String path) {
  final menuCd = menuCdForPath(path);
  if (menuCd == kMenuDsh001) {
    _invalidateDashboard(ref);
  } else if (menuCd == kMenuStr001) {
    _invalidateStores(ref);
  } else if (menuCd == kMenuDev001) {
    _invalidatePartners(ref);
  } else if (menuCd == kMenuDev002) {
    _invalidateProperties(ref);
  } else if (menuCd == kMenuDev003) {
    _invalidateSalesAreas(ref);
  } else if (menuCd == kMenuMst001) {
    _invalidateUsers(ref);
  } else if (menuCd == kMenuEap001 || menuCd == kMenuMst007) {
    _invalidateEap(ref);
  } else if (menuCd == kMenuMal001) {
    _invalidateMail(ref);
  }
}

void _invalidateDashboard(WidgetRef ref) {
  ref.invalidate(dashboardHomeDataProvider);
}

void _invalidateStores(WidgetRef ref) {
  ref.invalidate(storeDataProvider);
  ref.invalidate(storeListPageProvider);
  ref.invalidate(regionNamesProvider);
  ref.invalidate(brandNamesProvider);
  ref.invalidate(codeOptionsProvider(10));
  ref.invalidate(codeOptionsProvider(20));
  ref.invalidate(codeOptionsProvider(30));
  ref.invalidate(codeOptionsProvider(40));
  ref.invalidate(storeProvider);
}

void _invalidatePartners(WidgetRef ref) {
  ref.invalidate(partnerDataProvider);
  ref.invalidate(partnerCodeOptionsProvider(20));
  ref.invalidate(partnerProvider);
}

void _invalidateProperties(WidgetRef ref) {
  ref.invalidate(propertyDataProvider);
  ref.invalidate(propertyCodeOptionsProvider(20));
  ref.invalidate(propertyProvider);
}

void _invalidateSalesAreas(WidgetRef ref) {
  ref.invalidate(dev003DataProvider);
  ref.invalidate(salesAreaProvider);
}

void _invalidateUsers(WidgetRef ref) {
  ref.invalidate(userDataProvider);
  ref.invalidate(userProvider);
}

/// 전자결재 — 문서함·서식 목록. 결재 진행은 다른 사람이 만드는 변화라
/// 화면에 들어올 때마다 다시 읽는다.
void _invalidateEap(WidgetRef ref) {
  ref.invalidate(eapDocumentsProvider);
  ref.invalidate(eapDocumentDetailProvider);
  ref.invalidate(eapFormsProvider);
  ref.invalidate(eapEnabledFormsProvider);
  ref.invalidate(eapFormDetailProvider);
}

/// 메일 — 메일함·건수·상세·스레드.
///
/// 메일은 **남이 보내는 변화**다. 우리 쪽에서 아무 조작을 하지 않아도 새 메일이
/// 들어오고 발송 상태(전달·반송)가 바뀌므로, 캐시를 믿지 않고 화면에 들어올 때마다
/// 다시 읽는다. 특히 안 읽음 건수는 캐시가 남으면 사용자가 이미 읽은 메일을
/// 계속 "안 읽음" 으로 보게 되어 신뢰를 잃는다.
void _invalidateMail(WidgetRef ref) {
  ref.invalidate(mailListProvider);
  ref.invalidate(mailDetailProvider);
  ref.invalidate(mailCountsProvider);
  ref.invalidate(mailThreadProvider);
}
