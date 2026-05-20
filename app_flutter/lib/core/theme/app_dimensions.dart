/// 화면/테이블/폼 등 반복 사용되는 레이아웃 치수 상수 모음.
///
/// - 매직 넘버를 한 곳에 모아 디자인 시스템 변경 시 단일 지점만 수정하도록 한다.
/// - 화면별로 `1680`, `1300`, `1400` 처럼 흩어져 있던 수치들을 여기로 통합한다.
class AppDimensions {
  AppDimensions._();

  /// 본문 컨테이너(카드) 최대 너비. 너무 넓은 모니터에서도 가독성 유지.
  static const double contentMaxWidth = 1680;

  /// 이보다 좁으면 사이드바를 Drawer 로 숨기고 본문 전체 폭을 쓴다.
  static const double shellCompactMaxWidth = 840;

  /// 관리 리스트 화면 바깥 여백.
  static const double listScreenHPadding = 18;
  static const double listScreenBottomPadding = 20;

  /// 관리 리스트 카드 내부 여백.
  static const double listCardPadding = 12;

  /// 테이블이 가질 최소 너비. 화면 폭이 좁을 때 가로 스크롤 기준이 된다.
  /// 화면별로 다른 데이터 밀도를 반영한다.
  static const double tableMinWidthCompact = 1300;
  static const double tableMinWidthDefault = 1400;

  /// 상세/등록 화면에서 TabBarView 의 고정 높이.
  static const double detailPanelHeight = 640;

  /// 카드/테이블 모서리 둥글기.
  static const double cardRadius = 10;
  static const double tableRadius = 8;

  /// ERP 목록 테이블 셀 안쪽 여백.
  static const double tableCellPaddingH = 5;
  static const double tableCellPaddingV = 6;
}
