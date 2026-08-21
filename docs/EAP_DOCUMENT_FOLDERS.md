# 전자결재 문서함 조회 규칙

전자결재(`eap001`) 목록은 **로그인한 사람 한 명 기준**으로 나눈다.  
한 문서는 그 사람에게 **문서함 하나**에만 들어간다.

API: `GET /api/eap/documents?folder={폴더}`  
호출자 ID는 로그인 토큰에서만 읽는다. 쿼리로 다른 사람을 지정할 수 없다.

---

## 1. 역할 우선순위

결재선에 있으면 그 역할이 기안자 ID보다 앞선다.

| 우선 | 조건 | 문서함 |
|------|------|--------|
| 1 | 내 라인이 **결재자(APPROVER)** 또는 **합의자(AGREE)** | 받은결재 |
| 2 | 내가 **기안자**이고, 결재·합의 라인이 없음 | 올린결재 |
| 3 | 내 라인이 **참조(CC)** 또는 **열람(VIEWER)** 이고, 결재·합의가 아님 | 수신참조 |

예시 (휴가 신청서 LOCAL-51)

- 기안자: 김민효
- 결재자: 손성배, **김깡이**
- 합의자: 최현준
- 참조: 홍한서, 강지윤, 김혜민
- 열람: 김재훈

| 로그인 | 보이는 곳 |
|--------|-----------|
| 김민효 | 올린결재 → 상신 문서 |
| 김깡이 | 받은결재 → 결재대기 문서 (아직 결재 전) |
| 홍한서 | 수신참조 |

김깡이 화면에 이 문서가 상신으로 나오면 안 된다.

---

## 2. 폴더별 조회

화면과 `folder` 값이 같다.

### 받은결재

| 화면 | folder | 문서 상태 | 내 결재·합의 라인 |
|------|--------|-----------|-------------------|
| 결재대기 문서 | `inbox-pending` | 진행중 (`INPROGRESS`, `DRAFT`, `WRITING`) | 아직 `DONE` / `REJECT` 아님 (`WAIT` 포함) |
| 진행문서 | `inbox-progress` | 진행중 | 내가 이미 `DONE` 이고, 남은 내 대기 라인 없음 |
| 결재완료 문서 | `inbox-complete` | `COMPLETE` | 결재자 또는 합의자 |
| 반려문서 | `inbox-rejected` | `RETURN` | 결재자 또는 합의자 |

결재 차례(앞사람 대기)와 무관하다. 내 라인이 끝나지 않았으면 결재대기다.  
**결재하기 버튼**만 현재 차례일 때 켜진다.

### 올린결재

내가 기안자고, 내 결재·합의 라인이 **없을 때만** 들어간다.

| 화면 | folder | 문서 상태 |
|------|--------|-----------|
| 상신 문서 | `sent-open` | `INPROGRESS`, `DRAFT`, `WRITING` |
| 결재완료 | `sent-complete` | `COMPLETE` |
| 반려 | `sent-rejected` | `RETURN` |
| 임시보관 | `sent-temp` | `TEMPSAVE` |

홈 요약의 「상신 문서」는 `sent` 목록에서 진행중만 다시 고른 값이다.  
`sent` = 상신·완료·반려·취소(`CANCEL`)를 한 번에 가져온다.

### 수신참조 · 전체

| 화면 | folder | 조건 |
|------|--------|------|
| 수신참조결재 | `cc` | 참조 또는 열람. 결재·합의 아님. 임시저장 제외 |
| 전체문서 | `all` | 기안자이거나 결재선에 있음 |

---

## 3. 사람을 어떻게 맞추는가

저장값은 로그인 ID(`user_id`)가 원칙이다. 예전에 이름이 들어간 건도 있어서 둘 다 본다.

호출자 키

1. 토큰의 `userId`
2. `user_mst` 의 같은 계정 `user_id`
3. 그 계정의 `user_name` (이름)

결재선 일치: 라인의 `user_id` 또는 `user_nm` 이 위 키와 같으면 (대소문자 무시) 그 사람이다.

기안자 일치: `erp_approval_mappings.draft_user_id` 가 위 키와 같으면 기안자다.  
목록의 「기안자」이름 표시는 `draft_user_id` = `user_mst.user_id` 로만 조인한다. 이름 조인은 쓰지 않는다.

---

## 4. 처리 흐름

```
기안 (INPROGRESS)
  → 기안자: 올린결재 / 상신
  → 결재·합의 (미결): 받은결재 / 결재대기
  → 참조·열람: 수신참조

결재자가 승인 (라인 DONE, 문서 아직 INPROGRESS)
  → 그 결재자: 받은결재 / 진행문서
  → 아직 안 한 결재자: 받은결재 / 결재대기
  → 기안자: 올린결재 / 상신

마지막 결재·합의까지 DONE → 문서 COMPLETE
  → 기안자: 올린결재 / 결재완료
  → 결재·합의: 받은결재 / 결재완료

반려 (문서 RETURN)
  → 기안자: 올린결재 / 반려
  → 결재·합의: 받은결재 / 반려
```

임시저장(`TEMPSAVE`)은 기안자의 올린결재 / 임시보관에만 있다.

---

## 5. 구현 위치

| 구분 | 파일 |
|------|------|
| 폴더 분류 (확정 규칙) | `backend/.../eap/service/EapFolderMatcher.java` |
| 목록 API | `GET /api/eap/documents` → `EapDocumentService.listByFolder` |
| SQL 1차 필터 | `backend/.../mapper/eap/EapApprovalMappingMapper.xml` |
| 결재선 | `eap_doc_line` (`role_cd`, `line_status`) |
| 본문·기안자 | `erp_approval_mappings` (`draft_user_id`, `status`) |
| 화면 | `eap001_home_view.dart`, `eap001_folder_views.dart` |

SQL이 넓게 가져와도 Java `EapFolderMatcher` 가 최종으로 걸러 낸다.  
백엔드는 `restart.enabled: false` 이라 XML·클래스를 바꾸면 **재시작**해야 한다.
