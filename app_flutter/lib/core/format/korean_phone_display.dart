// 휴대전화 등 숫자 기반 번호의 목록·상세 표시용 포맷.

/// 비숫자를 제거한 뒤 국내 휴대전화 형태에 맞춰 `010-1234-5678` 식으로 보이게 한다.
///
/// - 11자리 초과 시 앞 11자리만 사용한다.
/// - 숫자가 없으면 빈 문자열을 반환한다.
String formatKoreanPhoneDisplay(String? phone) {
  if (phone == null || phone.isEmpty) return '';

  final text = phone.replaceAll(RegExp(r'[^0-9]'), '');

  if (text.isEmpty) return '';

  if (text.length <= 3) {
    return text;
  }
  if (text.length <= 7) {
    return '${text.substring(0, 3)}-${text.substring(3)}';
  }
  if (text.length <= 11) {
    return '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7)}';
  }
  return '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
}
