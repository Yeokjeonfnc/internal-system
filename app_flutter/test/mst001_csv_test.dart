// 사원관리 CSV 다운로드 → 업로드 왕복 검증.
//
// "일괄 업로드 후 목록에 반영되지 않는다"는 현상의 원인을 좁히기 위한 테스트.
// 내려받은 CSV 를 그대로 다시 파싱했을 때 로그인ID 가 보존되어야 기존 사원과
// 매칭되고, 매칭되지 않으면 저장 대상에서 통째로 빠진다.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/pages/master/mst001/mst001_csv.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

User _user({
  required int idx,
  required String name,
  required String userId,
  String dept = '역전F&C',
  String position = '사원',
  String phone = '01012345678',
  String email = 'a@b.com',
  SvYn sv = SvYn.no,
}) {
  return User(
    userIdx: idx,
    name: name,
    department: dept,
    positionNm: position,
    mobilePhone: phone,
    email: email,
    joinDt: '2026-01-01',
    svYn: sv,
    userId: userId,
  );
}

void main() {
  group('CSV 왕복', () {
    test('내려받은 CSV 를 그대로 파싱하면 값이 보존된다', () {
      final users = [
        _user(idx: 1, name: '홍길동', userId: 'hong'),
        _user(idx: 2, name: '김철수', userId: 'kim', sv: SvYn.yes),
      ];

      final csv = buildUsersCsv(users);
      final parsed = parseUsersCsv(csv);

      expect(parsed.length, 2);
      expect(parsed[0].userId, 'hong');
      expect(parsed[0].name, '홍길동');
      expect(parsed[0].svYn, isFalse);
      expect(parsed[1].userId, 'kim');
      expect(parsed[1].svYn, isTrue);
    });

    test('엑셀이 붙이는 UTF-8 BOM 이 있어도 첫 행 로그인ID 가 깨지지 않는다', () {
      final users = [_user(idx: 1, name: '홍길동', userId: 'hong')];
      final csv = buildUsersCsv(users);

      // buildUsersCsv 는 엑셀 한글 깨짐 방지를 위해 BOM 을 붙인다.
      expect(csv.codeUnitAt(0), 0xFEFF, reason: 'BOM 이 선두에 있어야 한다');

      final parsed = parseUsersCsv(csv);
      expect(parsed.single.userId, 'hong');
    });

    test('쉼표·따옴표가 들어간 값도 왕복에서 보존된다', () {
      final users = [
        _user(idx: 1, name: '홍길동, 대리', userId: 'hong', dept: '영업"1"팀'),
      ];
      final parsed = parseUsersCsv(buildUsersCsv(users));
      expect(parsed.single.name, '홍길동, 대리');
      expect(parsed.single.department, '영업"1"팀');
      expect(parsed.single.userId, 'hong');
    });

    test('CRLF(엑셀 저장 형식) 로 바뀌어도 파싱된다', () {
      final users = [_user(idx: 1, name: '홍길동', userId: 'hong')];
      final excelStyle = buildUsersCsv(users).replaceAll('\n', '\r\n');
      final parsed = parseUsersCsv(excelStyle);
      expect(parsed.single.userId, 'hong');
      expect(parsed.single.name, '홍길동');
    });

    test('로그인ID 가 없는 사원은 왕복 후에도 빈 값이라 매칭 대상에서 빠진다', () {
      final users = [_user(idx: 1, name: '아이디없음', userId: '')];
      final parsed = parseUsersCsv(buildUsersCsv(users));
      expect(parsed.single.userId, isEmpty);
    });

    test('사번이 왕복에서 보존된다(로그인ID 자체를 바꾸는 업로드의 매칭 키)', () {
      final users = [_user(idx: 42, name: '홍길동', userId: 'hong')];
      final parsed = parseUsersCsv(buildUsersCsv(users));
      expect(parsed.single.userIdx, 42);
    });

    test('사번 컬럼이 없는 예전 형식 파일도 여전히 파싱된다(하위호환)', () {
      // 예전에 내려받아 둔 파일을 흉내낸다 — 첫 컬럼(사번)이 아예 없다.
      const legacyCsv =
          '이름,부서,직급,휴대전화,로그인ID,이메일 주소,태그사용여부\n'
          '홍길동,영업1팀,사원,01012345678,hong,hong@a.com,Y\n';
      final parsed = parseUsersCsv(legacyCsv);
      expect(parsed.single.userIdx, isNull);
      expect(parsed.single.userId, 'hong');
      expect(parsed.single.name, '홍길동');
    });
  });

  group('업로드 내용 확인 — 변경 여부 판정', () {
    // 전체 목록을 그대로 재업로드하면 대부분 행이 기존과 동일하다. "업로드내용
    // 확인 화면이 사원관리 목록을 그대로 다시 보여주는 것과 다를 게 없다"는
    // 신고를 재현·검증하기 위한 테스트.

    ParsedUserCsvRow _rowFrom(User u) => ParsedUserCsvRow(
          name: u.name,
          department: u.department,
          positionNm: u.positionNm,
          mobilePhone: u.mobilePhone,
          userId: u.userId,
          email: u.email,
          svYn: u.svYn == SvYn.yes,
        );

    test('CSV 를 그대로 재업로드하면(무변경) 변경 없음으로 판정한다', () {
      final existing = _user(idx: 1, name: '홍길동', userId: 'hong');
      final diff = diffUserCsvRow(_rowFrom(existing), existing);
      expect(diff.hasAnyChange, isFalse);
    });

    test('부서만 바뀌면 부서만 변경으로 표시되고 다른 필드는 아니다', () {
      final existing = _user(idx: 1, name: '홍길동', userId: 'hong');
      final row = _rowFrom(existing);
      final changedRow = ParsedUserCsvRow(
        name: row.name,
        department: '영업2팀',
        positionNm: row.positionNm,
        mobilePhone: row.mobilePhone,
        userId: row.userId,
        email: row.email,
        svYn: row.svYn,
      );
      final diff = diffUserCsvRow(changedRow, existing);
      expect(diff.departmentChanged, isTrue);
      expect(diff.hasAnyChange, isTrue);
      expect(diff.nameChanged, isFalse);
      expect(diff.positionChanged, isFalse);
      expect(diff.phoneChanged, isFalse);
      expect(diff.emailChanged, isFalse);
      expect(diff.svYnChanged, isFalse);
    });

    test('태그사용여부(Y/N)만 바뀌어도 감지된다', () {
      final existing = _user(idx: 1, name: '홍길동', userId: 'hong', sv: SvYn.no);
      final row = _rowFrom(existing);
      final changedRow = ParsedUserCsvRow(
        name: row.name,
        department: row.department,
        positionNm: row.positionNm,
        mobilePhone: row.mobilePhone,
        userId: row.userId,
        email: row.email,
        svYn: true,
      );
      final diff = diffUserCsvRow(changedRow, existing);
      expect(diff.svYnChanged, isTrue);
      expect(diff.hasAnyChange, isTrue);
    });

    test('여러 필드가 동시에 바뀌면 전부 감지된다', () {
      final existing = _user(idx: 1, name: '홍길동', userId: 'hong');
      final changedRow = ParsedUserCsvRow(
        name: '홍길동',
        department: existing.department,
        positionNm: '과장',
        mobilePhone: '01099998888',
        userId: existing.userId,
        email: existing.email,
        svYn: existing.svYn == SvYn.yes,
      );
      final diff = diffUserCsvRow(changedRow, existing);
      expect(diff.positionChanged, isTrue);
      expect(diff.phoneChanged, isTrue);
      expect(diff.nameChanged, isFalse);
      expect(diff.hasAnyChange, isTrue);
    });

    test('로그인ID 자체가 바뀌면 감지된다(이름 기반 ID → 이메일로 전환)', () {
      final existing = _user(idx: 1, name: '홍길동', userId: 'hong');
      final row = _rowFrom(existing);
      final changedRow = ParsedUserCsvRow(
        userIdx: row.userIdx,
        name: row.name,
        department: row.department,
        positionNm: row.positionNm,
        mobilePhone: row.mobilePhone,
        userId: 'hong@yeokjeon.com',
        email: row.email,
        svYn: row.svYn,
      );
      final diff = diffUserCsvRow(changedRow, existing);
      expect(diff.userIdChanged, isTrue);
      expect(diff.hasAnyChange, isTrue);
    });
  });

  group('사번 기반 매칭 — 로그인ID를 통째로 바꾸는 업로드', () {
    // 신고 내용: "로그인ID가 대부분 이름으로 되어 있어 이메일 주소로 바꾸려고
    // 일괄 업로드를 했는데 (못 찾음)이 뜬다." 예전에는 로그인ID로 기존 사원을
    // 찾았는데, 그러면 CSV의 새 로그인ID가 기존 누구와도 일치하지 않아
    // 매칭이 구조적으로 항상 실패했다. 사번으로 찾으면 이 문제가 없다.

    test('로그인ID가 완전히 다른 값으로 바뀌어도 사번으로 매칭된다', () {
      final existing = _user(idx: 7, name: '홍길동', userId: 'hong');
      final row = ParsedUserCsvRow(
        userIdx: existing.userIdx, // CSV의 사번 컬럼 — 절대 안 바뀜
        name: existing.name,
        department: existing.department,
        positionNm: existing.positionNm,
        mobilePhone: existing.mobilePhone,
        userId: 'hong@yeokjeon.com', // 사람이 이메일로 바꿔 적은 값
        email: existing.email,
        svYn: existing.svYn == SvYn.yes,
      );

      // mst001_view.dart 의 매칭 로직과 동일한 우선순위(사번 우선, 로그인ID
      // 폴백)를 재현한다 — 뷰의 private 헬퍼는 직접 임포트할 수 없으므로.
      final byUserIdx = {existing.userIdx: existing};
      final byUserId = {existing.userId: existing};
      User? findExisting(ParsedUserCsvRow r) =>
          (r.userIdx != null ? byUserIdx[r.userIdx] : null) ??
          byUserId[r.userId];

      expect(findExisting(row), same(existing));
    });

    test('사번 컬럼이 없는 예전 파일에서는 여전히 로그인ID로만 매칭된다', () {
      final existing = _user(idx: 7, name: '홍길동', userId: 'hong');
      final row = ParsedUserCsvRow(
        userIdx: null, // 예전 형식
        name: existing.name,
        department: existing.department,
        positionNm: existing.positionNm,
        mobilePhone: existing.mobilePhone,
        userId: 'hong', // 그대로면 매칭됨
        email: existing.email,
        svYn: existing.svYn == SvYn.yes,
      );
      final byUserIdx = {existing.userIdx: existing};
      final byUserId = {existing.userId: existing};
      User? findExisting(ParsedUserCsvRow r) =>
          (r.userIdx != null ? byUserIdx[r.userIdx] : null) ??
          byUserId[r.userId];

      expect(findExisting(row), same(existing));
    });
  });

  group('업로드 내용 확인 — 로그인ID 중복 지정 경고', () {
    test('같은 로그인ID를 목표로 하는 행이 없으면 중복 없음', () {
      final dup = findDuplicateTargetUserIds(['a@b.com', 'c@d.com']);
      expect(dup, isEmpty);
    });

    test('두 사원이 같은 로그인ID를 목표로 하면 중복으로 감지된다', () {
      final dup = findDuplicateTargetUserIds([
        'a@b.com',
        'c@d.com',
        'a@b.com',
      ]);
      expect(dup, {'a@b.com'});
    });

    test('빈 값·공백은 중복 판정에서 제외된다', () {
      final dup = findDuplicateTargetUserIds(['', ' ', '', 'a@b.com']);
      expect(dup, isEmpty);
    });
  });
}
