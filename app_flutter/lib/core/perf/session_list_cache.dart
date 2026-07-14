// 세션(메모리) 목록 캐시 — 화면 재진입 시 이전 데이터를 즉시 그리고 배경에서 갱신한다.
//
// 모든 API 호출에 ~0.7초의 왕복 지연이 있어(터널 RTT), 재방문 화면이 매번
// 스피너로 비는 것이 체감 저하의 주원인이었다. 이 캐시는 "마지막으로 성공한
// 목록"만 기억하는 단순한 stale-while-revalidate 용도로, 데이터의 원본은
// 항상 서버이며 화면 진입 시 배경 재조회가 함께 돈다.

/// 키 규칙: `'<화면>:<식별자>'` (예: `'act002:myDrafts:admin'`).
class SessionListCache {
  SessionListCache._();

  static final Map<String, List<Object?>> _store = {};

  static List<T>? get<T>(String key) {
    final v = _store[key];
    if (v is List<T>) return v;
    return null;
  }

  static void put<T>(String key, List<T> value) {
    _store[key] = value;
  }

  /// 저장·삭제 등 쓰기 작업 후 전체 무효화 (app_data_refresh 와 함께 호출).
  static void clearAll() => _store.clear();
}
