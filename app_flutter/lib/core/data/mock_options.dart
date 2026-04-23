// API 연동 전, 목록·필터·폼에서 쓰는 고정 드롭다운 문자열(개발용 mock).

/// 지역(시·도). 첫 값은 "전체".
const List<String> kMockRegionOptions = [
  '전체',
  '서울',
  '부산',
  '대구',
  '인천',
  '광주',
  '대전',
  '울산',
  '세종',
  '경기',
  '강원',
  '충북',
  '충남',
  '전북',
  '전남',
  '경북',
  '경남',
  '제주',
  '국외',
];

/// 가맹점 구분(가맹 / 직영). 첫 값은 "전체".
const List<String> kMockStoreCategoryOptions = [
  '전체',
  '가맹',
  '직영',
];

/// 창업자 목록 구분(예비창업자 / 가맹점사업자). 첫 값은 "전체".
const List<String> kMockFounderStatusOptions = [
  '전체',
  '예비창업자',
  '가맹점사업자',
];
