-- 메뉴 권한 일괄 부여 — 서버측 권한 검사를 켜기 위한 기준선 데이터.
--
-- 배경
--   지금까지 가맹점·활동·개발·게시판·메신저의 쓰기 API 에는 서버측 권한 검사가
--   전혀 없었다(로그인만 하면 누구나 실행). 이를 막는 MenuAccessGuard 를 붙이는데,
--   실 DB 를 확인해 보니 사원 69명 중 66명은 can_view 조차 전부 'N' 이었다.
--   (프론트가 "권한이 하나도 없으면 전부 허용"으로 폴백해서 지금까지 문제가
--    드러나지 않았다.) 이 상태로 가드만 켜면 66명이 즉시 업무 불가가 된다.
--
-- 이 스크립트가 하는 일
--   **현재 실제로 쓰이고 있는 접근 범위를 데이터로 옮겨 적는다.** 즉 이 스크립트
--   자체는 사용자가 체감하는 동작을 바꾸지 않는다. 목적은 "권한이 코드가 아니라
--   데이터로 결정되는 상태"를 만들어, 이후 관리자가 메뉴권한 관리(mst003) 화면에서
--   사람별로 좁혀 나갈 수 있게 하는 것이다.
--
--   - can_view    : 전 메뉴 'Y'  → 사이드바 구성이 지금과 똑같이 유지된다(변화 없음)
--   - 업무 메뉴 쓰기: 'Y'         → 지금 다들 하고 있는 등록·수정·삭제가 계속 된다
--   - 관리 메뉴 쓰기: 'N'         → 사원/메뉴권한/사용기록/가맹점주 관리는 관리자만
--                                  (이미 서버가 그렇게 막고 있어 실질 변화 없음)
--   - admin_yn='Y' 계정은 코드에서 무조건 통과하므로 이 표와 무관하다.
--
-- 안전성
--   기존 행은 UPDATE, 없는 행은 INSERT 만 한다. 계정·비밀번호는 건드리지 않는다.
--   되돌리려면 맨 아래 롤백 쿼리를 쓰면 된다.
--
-- 실행
--   psql -h localhost -p 5433 -U postgres -d yj_db_test -f 20260812_user_menu_auth_baseline_grant.sql
--   (한글 오류 시 먼저:  $env:PGCLIENTENCODING="UTF8" )

BEGIN;

-- 1) 모든 사용자 × 모든 메뉴 조합이 존재하도록 보강(없는 것만 생성).
--    그룹 메뉴(menu_type='G')는 폴더라 권한 대상이 아니므로 제외한다.
INSERT INTO user_menu_auth (user_idx, menu_cd, can_view, can_create, can_update, can_delete)
SELECT u.user_idx, m.menu_cd, 'N', 'N', 'N', 'N'
FROM user_mst u
         CROSS JOIN menu_mst m
WHERE m.use_yn = 'Y'
  AND m.menu_type <> 'G'
  AND NOT EXISTS (SELECT 1
                  FROM user_menu_auth a
                  WHERE a.user_idx = u.user_idx
                    AND a.menu_cd = m.menu_cd);

-- 2) 조회 권한: 전 메뉴 허용 — 지금 보이는 사이드바를 그대로 유지하기 위함.
--    (여기서 좁히면 메뉴가 사라져 사용자가 놀란다. 축소는 화면에서 개별로 할 것.)
UPDATE user_menu_auth
SET can_view = 'Y', updated_at = now()
WHERE can_view <> 'Y';

-- 3) 업무 메뉴 쓰기 권한: 현재 다들 하고 있는 작업이므로 그대로 허용.
UPDATE user_menu_auth
SET can_create = 'Y', can_update = 'Y', can_delete = 'Y', updated_at = now()
WHERE menu_cd IN (
    'dsh001',  -- 홈
    'str001',  -- 가맹점 관리
    'dev001',  -- 예비창업자 관리
    'dev002',  -- 물건 관리
    'dev003',  -- 영업지역 관리
    'act001',  -- 활동현황
    'act002',  -- 활동관리(등록)
    'act003',  -- 활동관리결재
    'act004',  -- 활동 계획
    'bbs001',  -- 게시판
    'msg001',  -- 메신저
    'mst002',  -- 부서관리
    'mst004'   -- 체크리스트 관리
);

-- 4) 관리 메뉴 쓰기 권한: 관리자(admin_yn='Y')에게만.
--    일반 사원은 이미 서버에서 막히고 있으므로 실질 변화가 없다.
UPDATE user_menu_auth a
SET can_create = 'N', can_update = 'N', can_delete = 'N', updated_at = now()
WHERE a.menu_cd IN ('mst001', 'mst003', 'mst005', 'mst006')
  AND NOT EXISTS (SELECT 1
                  FROM user_mst u
                  WHERE u.user_idx = a.user_idx
                    AND u.admin_yn = 'Y');

UPDATE user_menu_auth a
SET can_create = 'Y', can_update = 'Y', can_delete = 'Y', updated_at = now()
WHERE a.menu_cd IN ('mst001', 'mst003', 'mst005', 'mst006')
  AND EXISTS (SELECT 1
              FROM user_mst u
              WHERE u.user_idx = a.user_idx
                AND u.admin_yn = 'Y');

-- 5) 적용 결과 확인 — 쓰기 가능 메뉴 수별 인원 분포가 나온다.
--    기대: 일반 사원은 13개(업무 메뉴), 관리자는 17개.
SELECT write_menus AS "쓰기가능 메뉴수", COUNT(*) AS "인원"
FROM (SELECT a.user_idx,
             COUNT(*) FILTER (WHERE a.can_create = 'Y'
                 OR a.can_update = 'Y'
                 OR a.can_delete = 'Y') AS write_menus
      FROM user_menu_auth a
      GROUP BY a.user_idx) t
GROUP BY write_menus
ORDER BY write_menus;

COMMIT;

-- ============================================================
-- 되돌리기 (권한 검사를 다시 끄고 싶을 때)
--   프론트·백엔드 모두 "권한 행이 전부 N 이면 제한 없음"으로 폴백하므로,
--   아래를 실행하면 이 스크립트 이전 상태로 돌아간다.
--
--   UPDATE user_menu_auth
--   SET can_view='N', can_create='N', can_update='N', can_delete='N', updated_at=now()
--   WHERE user_idx NOT IN (SELECT user_idx FROM user_mst WHERE admin_yn='Y');
-- ============================================================
