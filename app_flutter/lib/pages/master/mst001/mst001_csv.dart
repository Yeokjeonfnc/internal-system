// 사원관리 목록 — CSV 일괄 다운로드/업로드.
//
// 업로드는 토큰번호(시스템 내부 고유 식별자)로 기존 사원을 찾아 이름·부서·
// 직급·휴대전화·로그인ID·이메일·태그사용여부를 갱신한다. 비밀번호가 필요한
// 신규 계정 생성은 CSV로 하지 않는다(평문 비밀번호가 파일에 남는 것을 피하기
// 위해) — 신규 등록은 기존 등록 화면을 쓴다.
//
// 토큰번호를 매칭 키로 쓰는 이유: 예전에는 로그인ID로 기존 사원을 찾았는데,
// 그러면 "로그인ID 자체를 바꾸는" 일괄 업로드(예: 이름 기반 ID → 이메일
// 주소로 전환)가 구조적으로 불가능했다 — CSV의 새 값이 기존 사원 누구의
// 로그인ID와도 일치하지 않으니 매칭이 항상 실패해 "(못 찾음)"으로 떴다.
// 토큰번호는 절대 바뀌지 않는 값이라 로그인ID를 마음껏 바꿔도 매칭이 유지된다.
//
// 회사가 실제로 관리하는 "사번"(HR 사원번호)은 이 토큰번호와 다른 개념이라
// CSV 매칭에는 쓰지 않는다 — 사원 상세 화면에서 선택적으로 입력·관리한다.

import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

const List<String> kUserCsvHeaders = [
  '토큰번호(수정 금지)',
  '이름',
  '부서',
  '직급',
  '휴대전화',
  '로그인ID',
  '이메일 주소',
  '태그사용여부',
];

/// 토큰번호 컬럼이 없던 예전 형식(다운로드 후 편집만 하고 재업로드하는
/// 용도로는 여전히 동작해야 한다). 새로 받은 파일인지 구분하는 데 쓴다.
const int kLegacyUserCsvColumnCount = 7;
const int kUserCsvColumnCount = 8;

String _csvField(String raw) {
  final v = raw;
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

/// 목록을 CSV 텍스트로 인코딩한다. 엑셀에서 한글이 깨지지 않도록 UTF-8 BOM을 붙인다.
String buildUsersCsv(List<User> users) {
  final buffer = StringBuffer('﻿');
  buffer.writeln(kUserCsvHeaders.map(_csvField).join(','));
  for (final u in users) {
    final cells = [
      u.userIdx.toString(),
      u.name,
      u.department,
      u.positionNm,
      u.mobilePhone,
      u.userId,
      u.email,
      u.svYn == SvYn.yes ? 'Y' : 'N',
    ];
    buffer.writeln(cells.map(_csvField).join(','));
  }
  return buffer.toString();
}

/// 한 줄을 CSV 셀 목록으로 분해한다(따옴표로 감싼 콤마·줄바꿈 지원).
List<List<String>> _parseCsvRows(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  final s = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  while (i < s.length) {
    final c = s[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(c);
      i++;
      continue;
    }
    if (c == '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (c == ',') {
      row.add(field.toString());
      field.clear();
      i++;
      continue;
    }
    if (c == '\n') {
      row.add(field.toString());
      field.clear();
      if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
      i++;
      continue;
    }
    field.write(c);
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
  }
  return rows;
}

class ParsedUserCsvRow {
  const ParsedUserCsvRow({
    this.userIdx,
    required this.name,
    required this.department,
    required this.positionNm,
    required this.mobilePhone,
    required this.userId,
    required this.email,
    required this.svYn,
  });

  /// 토큰번호 — 있으면 이 값으로 기존 사원을 찾는다(로그인ID가 바뀌어도 안전).
  /// 예전 형식(토큰번호 컬럼 없음)으로 업로드하면 null 이고, 그때만 로그인ID로
  /// 매칭한다(기존 동작 그대로 — 로그인ID 자체를 바꾸는 용도로는 못 쓴다).
  final int? userIdx;
  final String name;
  final String department;
  final String positionNm;
  final String mobilePhone;
  final String userId;
  final String email;
  final bool svYn;
}

/// 업로드한 CSV 텍스트를 파싱한다.
///
/// 토큰번호 컬럼이 있는 새 형식([kUserCsvHeaders], 8열)과, 그 컬럼이 없던
/// 예전 형식(7열, 로그인ID가 첫 데이터 컬럼)을 헤더의 첫 셀로 구분해 둘 다
/// 받아들인다 — 이미 내려받아 둔 예전 파일도 계속 동작해야 하기 때문이다.
List<ParsedUserCsvRow> parseUsersCsv(String text) {
  final rows = _parseCsvRows(text);
  if (rows.isEmpty) return const [];

  final header = rows.first;
  final hasUserIdx =
      header.isNotEmpty && header.first.trim() == kUserCsvHeaders.first;
  final minColumns = hasUserIdx
      ? kUserCsvColumnCount
      : kLegacyUserCsvColumnCount;
  final offset = hasUserIdx ? 1 : 0;

  final out = <ParsedUserCsvRow>[];
  // 첫 줄은 헤더로 간주하고 건너뛴다.
  for (final r in rows.skip(1)) {
    if (r.length < minColumns) continue;
    final svRaw = r[offset + 6].trim().toUpperCase();
    out.add(
      ParsedUserCsvRow(
        userIdx: hasUserIdx ? int.tryParse(r[0].trim()) : null,
        name: r[offset + 0].trim(),
        department: r[offset + 1].trim(),
        positionNm: r[offset + 2].trim(),
        mobilePhone: r[offset + 3].trim(),
        userId: r[offset + 4].trim(),
        email: r[offset + 5].trim(),
        svYn: svRaw == 'Y' || svRaw == '사용' || svRaw == 'TRUE',
      ),
    );
  }
  return out;
}

/// CSV 한 행이 기존 사원 값과 실제로 다른 필드가 무엇인지.
///
/// 전체 목록을 그대로 재업로드하면 대부분 행이 기존과 동일하다 — 실제로
/// 바뀌는 값만 구분해 보여주지 않으면 업로드 내용 확인 화면이 사원관리
/// 목록을 그대로 다시 보여주는 것과 구분되지 않는다.
class UserCsvRowDiff {
  const UserCsvRowDiff({
    required this.userIdChanged,
    required this.nameChanged,
    required this.departmentChanged,
    required this.positionChanged,
    required this.phoneChanged,
    required this.emailChanged,
    required this.svYnChanged,
  });

  final bool userIdChanged;
  final bool nameChanged;
  final bool departmentChanged;
  final bool positionChanged;
  final bool phoneChanged;
  final bool emailChanged;
  final bool svYnChanged;

  bool get hasAnyChange =>
      userIdChanged ||
      nameChanged ||
      departmentChanged ||
      positionChanged ||
      phoneChanged ||
      emailChanged ||
      svYnChanged;
}

UserCsvRowDiff diffUserCsvRow(ParsedUserCsvRow row, User existing) {
  return UserCsvRowDiff(
    userIdChanged: row.userId != existing.userId,
    nameChanged: row.name != existing.name,
    departmentChanged: row.department != existing.department,
    positionChanged: row.positionNm != existing.positionNm,
    phoneChanged: row.mobilePhone != existing.mobilePhone,
    emailChanged: row.email != existing.email,
    svYnChanged: row.svYn != (existing.svYn == SvYn.yes),
  );
}

/// 로그인ID로 두 번 이상 지정된 값을 돌려준다.
///
/// 서버에서 로그인ID는 유일해야 하므로, 같은 값을 목표로 하는 행이 여럿이면
/// 하나만 저장되고 나머지는 실패한다(예: 이름 기반 ID를 이메일로 옮기다가
/// 두 사원에게 같은 이메일을 잘못 적는 실수). 저장을 누르기 전에 미리 알려준다.
Set<String> findDuplicateTargetUserIds(Iterable<String> targetUserIds) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final raw in targetUserIds) {
    final id = raw.trim();
    if (id.isEmpty) continue;
    if (!seen.add(id)) duplicates.add(id);
  }
  return duplicates;
}
