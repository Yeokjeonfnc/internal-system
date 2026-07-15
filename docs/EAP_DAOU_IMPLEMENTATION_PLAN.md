# 전자결재(EAP) — 다우오피스 연동 구현 계획

> **작성일:** 2026-07-14  
> **최종 갱신:** 2026-07-15 — Phase 1~2 구현 반영, 목업 데이터 제거  
> **참고:** `daou_erp_integration_guide.md`, 기존 `app_flutter/lib/pages/eap/`, `backend/.../eap/`

본 문서는 자사 ERP 내 **전자결재** 메뉴를 다우오피스 Open API(v4)와 연동하기 위한 **구현 범위·순서·DB·API·화면** 설계를 정리합니다.

---

## 1. 목표

| 항목 | 내용 |
|------|------|
| 사용자 | ERP에서 결재 문서 조회·기안·상태 확인 |
| 관리자 | 다우 연동 키·양식 코드(formCode) 등록 및 연결 테스트 |
| 시스템 | ERP 업무 전표 ↔ 다우 결재 문서(`documentId`) 매핑 및 상태 동기화 |

---

## 2. 현재 구현 상태 (As-Is / 2026-07-15)

### 2.1 Flutter (`app_flutter/lib/pages/eap/`)

| 구성 | 파일 | 상태 |
|------|------|------|
| 셸·네비 | `eap001_shell.dart`, `eap001_widgets.dart` | ✅ |
| 홈 | `eap001_home_view.dart` | ✅ API (`eapHomeSummaryProvider`) |
| 문서함 목록 | `eap001_list_view.dart` | ✅ API (`eapDocumentsProvider`) |
| 문서 상세 | `eap001_detail_view.dart` | ✅ API (`eapDocumentDetailProvider`) |
| 새 기안 | `eap001_new_draft_sheet.dart` | ✅ `POST /eap/draft` |
| Provider·API | `eap001_provider.dart`, `eap001_api.dart`, `eap001_model.dart` | ✅ |
| 연동 설정 | `eap001_settings_view.dart` + `EapSettingsPanel` | ✅ 연결 테스트 |
| 양식 코드 관리 | `eap001_form_config_panel.dart` | ✅ CRUD |
| 라우팅 | `shared/eap_routes.dart`, `app_router.dart` | ✅ `/eap/*` |
| 목업 | `mock_eap_documents.dart` | ✅ **삭제됨** (2026-07-15) — API만 사용 |

### 2.2 Backend (`backend/src/main/java/com/yeokjeon/erp/eap/`)

| API | 상태 |
|-----|------|
| `GET /api/eap/health` | ✅ |
| `GET /api/eap/connection-test` | ✅ |
| `GET /api/eap/forms` | ✅ |
| `POST /api/eap/forms` | ✅ |
| `PUT /api/eap/forms/{formCode}` | ✅ |
| `DELETE /api/eap/forms/{formCode}` | ✅ |
| `GET /api/eap/documents?folder=` | ✅ (`erp_approval_mappings` 기반) |
| `GET /api/eap/documents/{id}` | ✅ |
| `POST /api/eap/draft` | ✅ (다우 키 없으면 ERP 매핑만 저장) |
| `POST /api/eap/status` | ✅ 콜백 |
| 상태 polling 스케줄러 | ❌ 미구현 |
| 승인/반려 → ERP 전표 후처리 | ❌ 미구현 |

### 2.3 DB

| 항목 | 상태 |
|------|------|
| 마이그레이션 | ✅ `deploy/db/migrations/20260715_eap_daou_schema.sql` |
| 테이블 | `eap_form_config`, `erp_approval_mappings`, `daou_api_tokens`, `employee_daou_user_map` |
| COMMENT | ✅ 테이블·컬럼 COMMENT 포함 |
| 시드 | 기본 양식 3종 (`yeokjeon_eap01`~`03`) ON CONFLICT DO NOTHING |
| 적용 | 로컬/필드 DB에 **수동 적용 필요** (`psql -f …`) |

### 2.4 설정 (`application.yml`)

```yaml
daou:
  office:
    api-base-url: https://api.daouoffice.com
    client-id: ${DAOU_CLIENT_ID:}
    client-secret: ${DAOU_CLIENT_SECRET:}
    form-code: ${DAOU_FORM_CODE:yeokjeon_eap01}
    callback-url: ${DAOU_CALLBACK_URL:http://localhost:3001/api/eap/status}
```

---

## 3. 다우오피스 양식 설정 vs ERP 화면

첨부 스크린샷은 **다우오피스 관리자 → 결재 양식 설정** 화면입니다. ERP에서 동일 UI를 만들지 않습니다.

```
[다우오피스 관리자]
  └─ 양식 설정
       ├─ 시스템 연동 ☑
       ├─ 연동 방식: 전자결재연동_v4
       └─ 코드: yeokjeon_eap01   ← ERP 기안 API의 formCode
```

| 구분 | 담당 | 설명 |
|------|------|------|
| 시스템 연동·v4·스크립트 | **다우 관리자** | 양식별 1회 설정 |
| formCode 등록·ERP 매핑 | **ERP 관리자 화면** | DB `eap_form_config`에 코드·표시명·연결 ERP 메뉴 저장 |
| 기안·조회 | **ERP 사용자 화면** | 기존 `eap001` 문서함 UI |

---

## 4. 연동 아키텍처

```
[ ERP Frontend ]                 [ ERP Backend ]             [ 다우오피스 API ]
       │                                │                             │
       │ 1. 결재 요청 / 조회 ───────────>│                             │
       │                                │ 2. Client ID/Secret 검증     │
       │                                │    (필요 시 토큰 재발급)     │
       │                                │ 3. API 대리 요청 ──────────>│
       │                                │ <────────── 4. 결과 반환 ───│
       │ <────────── 5. 데이터 가공 반환│                             │
       │                                │ 6. 콜백/배치 상태 동기화 <──│
       │                                │         ↕ DB                │
```

**원칙**

- 프론트는 다우 API를 **직접 호출하지 않음** (CORS·키 유출 방지)
- Client ID/Secret은 **백엔드 환경변수**만 사용
- v4 기안: `POST /public/v4/approval/document` (form-urlencoded)

---

## 5. DB 설계

SQL 파일 위치: `deploy/db/migrations/` (예: `20260714_eap_daou_schema.sql`)

**필수 규칙:** 테이블·컬럼 생성 시 **`COMMENT ON TABLE` / `COMMENT ON COLUMN` 을 항상 함께** 작성한다. (프로젝트 마이그레이션 관례와 동일)

### 5.1 `eap_form_config` — 양식 코드 레지스트리 (핵심)

다우 관리자에서 발급한 **코드**를 ERP에 등록합니다.

```sql
CREATE TABLE IF NOT EXISTS public.eap_form_config (
    form_code           VARCHAR(64)  PRIMARY KEY,
    form_name           VARCHAR(200) NOT NULL,
    integration_type    VARCHAR(16)  NOT NULL DEFAULT 'v4',
    erp_source_menu     VARCHAR(32),
    html_template_key   VARCHAR(64),
    use_email           BOOLEAN      NOT NULL DEFAULT FALSE,
    use_board           BOOLEAN      NOT NULL DEFAULT FALSE,
    enabled             BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order          INT          NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.eap_form_config IS '전자결재 — 다우오피스 양식 코드(formCode) 레지스트리';
COMMENT ON COLUMN public.eap_form_config.form_code IS '다우 양식 고유 코드(시스템 연동 v4 코드)';
COMMENT ON COLUMN public.eap_form_config.form_name IS 'ERP 화면 표시명(품의 기본, 지출결의서 등)';
COMMENT ON COLUMN public.eap_form_config.integration_type IS '연동 방식(현재 v4 고정)';
COMMENT ON COLUMN public.eap_form_config.erp_source_menu IS '기안 연결 ERP 메뉴 코드(str001, act002 등)';
COMMENT ON COLUMN public.eap_form_config.html_template_key IS '백엔드 HTML 본문 템플릿 키';
COMMENT ON COLUMN public.eap_form_config.use_email IS '다우 양식 메일 발송 기능 사용 여부(참고)';
COMMENT ON COLUMN public.eap_form_config.use_board IS '다우 양식 게시판 등록 기능 사용 여부(참고)';
COMMENT ON COLUMN public.eap_form_config.enabled IS 'ERP에서 기안 시 선택 가능 여부';
COMMENT ON COLUMN public.eap_form_config.sort_order IS '목록 정렬 순서';
COMMENT ON COLUMN public.eap_form_config.created_at IS '등록일시';
COMMENT ON COLUMN public.eap_form_config.updated_at IS '수정일시';
```

### 5.2 `erp_approval_mappings` — ERP ↔ 다우 문서 매핑

```sql
CREATE TABLE IF NOT EXISTS public.erp_approval_mappings (
    id                  BIGSERIAL    PRIMARY KEY,
    erp_menu_id         VARCHAR(32)  NOT NULL,
    erp_source_id       VARCHAR(64)  NOT NULL,
    daou_document_id    VARCHAR(128),
    daou_form_code      VARCHAR(64)  NOT NULL REFERENCES public.eap_form_config(form_code),
    status              VARCHAR(32)  NOT NULL DEFAULT 'DRAFT',
    draft_user_id       VARCHAR(64),
    title               VARCHAR(500),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (erp_menu_id, erp_source_id, daou_form_code)
);

CREATE INDEX IF NOT EXISTS idx_erp_approval_mappings_status
    ON public.erp_approval_mappings(status);
CREATE INDEX IF NOT EXISTS idx_erp_approval_mappings_daou_doc
    ON public.erp_approval_mappings(daou_document_id);

COMMENT ON TABLE public.erp_approval_mappings IS '전자결재 — ERP 전표/업무와 다우 결재 문서 매핑';
COMMENT ON COLUMN public.erp_approval_mappings.id IS '매핑 PK';
COMMENT ON COLUMN public.erp_approval_mappings.erp_menu_id IS 'ERP 메뉴 코드(출처 업무 구분)';
COMMENT ON COLUMN public.erp_approval_mappings.erp_source_id IS 'ERP 전표·업무 고유번호';
COMMENT ON COLUMN public.erp_approval_mappings.daou_document_id IS '다우오피스 결재 문서 ID';
COMMENT ON COLUMN public.erp_approval_mappings.daou_form_code IS '기안 시 사용한 다우 양식 코드';
COMMENT ON COLUMN public.erp_approval_mappings.status IS '결재 상태(DRAFT|INPROGRESS|COMPLETE|RETURN|CANCEL|TEMPSAVE)';
COMMENT ON COLUMN public.erp_approval_mappings.draft_user_id IS '기안자 ERP 사용자 ID';
COMMENT ON COLUMN public.erp_approval_mappings.title IS '결재 문서 제목';
COMMENT ON COLUMN public.erp_approval_mappings.created_at IS '매핑 생성일시';
COMMENT ON COLUMN public.erp_approval_mappings.updated_at IS '상태 동기화·수정일시';
```

**status 값:** `DRAFT`, `INPROGRESS`, `COMPLETE`, `RETURN`, `CANCEL`, `TEMPSAVE`

### 5.3 `daou_api_tokens` — 토큰 관리 (선택·확장)

v4 public API는 현재 Client ID/Secret 직접 전송. 향후 Bearer 토큰 방식 대비.

```sql
CREATE TABLE IF NOT EXISTS public.daou_api_tokens (
    id                  SERIAL       PRIMARY KEY,
    client_id           VARCHAR(128) NOT NULL,
    access_token        TEXT,
    refresh_token       TEXT,
    expires_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.daou_api_tokens IS '전자결재 — 다우오피스 API Access/Refresh 토큰 보관';
COMMENT ON COLUMN public.daou_api_tokens.id IS '토큰 레코드 PK';
COMMENT ON COLUMN public.daou_api_tokens.client_id IS '다우 Open API Client ID';
COMMENT ON COLUMN public.daou_api_tokens.access_token IS 'Access Token(민감 — 애플리케이션만 접근)';
COMMENT ON COLUMN public.daou_api_tokens.refresh_token IS 'Refresh Token(민감 — 애플리케이션만 접근)';
COMMENT ON COLUMN public.daou_api_tokens.expires_at IS 'Access Token 만료 시각';
COMMENT ON COLUMN public.daou_api_tokens.updated_at IS '토큰 갱신일시';
```

### 5.4 `employee_daou_user_map` — 사원 ↔ 다우 사용자 (선행 확인)

```sql
CREATE TABLE IF NOT EXISTS public.employee_daou_user_map (
    emp_no              VARCHAR(32)  PRIMARY KEY,
    daou_user_id        VARCHAR(128) NOT NULL,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.employee_daou_user_map IS '전자결재 — ERP 사번과 다우오피스 사용자 ID 매핑';
COMMENT ON COLUMN public.employee_daou_user_map.emp_no IS 'ERP 사원번호';
COMMENT ON COLUMN public.employee_daou_user_map.daou_user_id IS '다우오피스 시스템 내부 사용자 식별자';
COMMENT ON COLUMN public.employee_daou_user_map.updated_at IS '매핑 수정일시';
```

---

## 6. 백엔드 API 설계

패키지: `com.yeokjeon.erp.eap`

| Method | Path | 설명 |
|--------|------|------|
| GET | `/eap/health` | 헬스체크 ✅ |
| GET | `/eap/connection-test` | 연동 테스트 ✅ |
| GET | `/eap/documents` | 문서함 목록 (`?folder=pending\|drafted\|approved\|...`) |
| GET | `/eap/documents/{documentId}` | 본문·결재선·첨부 |
| POST | `/eap/draft` | ERP 데이터 → HTML → 다우 기안 |
| POST | `/eap/status` | 다우 콜백 수신 |
| GET | `/eap/forms` | 양식 코드 목록 |
| POST | `/eap/forms` | 양식 코드 등록 |
| PUT | `/eap/forms/{formCode}` | 양식 코드 수정 |

### 6.1 기안 파이프라인 (`POST /eap/draft`)

**Request (예시)**

```json
{
  "formCode": "yeokjeon_eap01",
  "erpMenuId": "act002",
  "erpSourceId": "ACT-2026-00123",
  "title": "3월 활동비 지출결의",
  "draftUserId": "E001"
}
```

**처리 순서**

1. `eap_form_config`에서 formCode·템플릿 조회
2. ERP 업무 데이터 조회 → HTML 본문 생성
3. 다우 `/public/v4/approval/document` 호출
4. 응답 `documentId` → `erp_approval_mappings` INSERT
5. 프론트에 documentId·상태 반환 (또는 다우 리다이렉트 URL)

### 6.2 상태 동기화

| 방식 | 설명 |
|------|------|
| 콜백 | `callbackUrl` → `POST /eap/status` → 매핑 status UPDATE |
| 배치 | 5~10분 간격, `INPROGRESS` 문서 polling → 다우 본문 조회 API |
| 후처리 | `COMPLETE` → ERP 전표 승인 / `RETURN` → ERP 전표 반려 |

---

## 7. Flutter 화면 구현 계획

폴더: `app_flutter/lib/pages/eap/eap001/`

### 7.1 화면 구조 (기존 유지 + API 연동)

```
/eap/home          → 홈 (대기·진행·완료 요약)
/eap/pending       → 결재 대기
/eap/drafted       → 기안 문서함
/eap/approved      → 결재 완료
/eap/doc/:docId    → 문서 상세
/eap/settings      → 연동 설정 (관리자)
```

### 7.2 파일 현황

| 파일 | 상태 |
|------|------|
| `eap001_provider.dart` | ✅ API 전용 (목업 fallback 없음) |
| `eap001_api.dart` | ✅ documents / draft / forms / connection-test |
| `eap001_model.dart` | ✅ Document, FormConfig, DraftRequest/Result |
| `eap001_list_view.dart` | ✅ provider 연동 |
| `eap001_home_view.dart` | ✅ provider 연동 |
| `eap001_detail_view.dart` | ✅ provider 연동 |
| `eap001_new_draft_sheet.dart` | ✅ `POST /eap/draft` |
| `eap001_settings_view.dart` | ✅ |
| `eap001_form_config_panel.dart` | ✅ formCode CRUD |
| ~~`mock_eap_documents.dart`~~ | 🗑️ **삭제** (2026-07-15) |

### 7.3 UI 규칙

- 목록: `ErpDataTable` + `EapStatusBadge` (기존 위젯 재사용)
- 상세: `DetailScreenScrollBody` (기존 `eap001_detail_view` 패턴)
- 설정: `EapSettingsPanel` 확장 — 연결 테스트 + 양식 코드 테이블
- 공통 토큰: `.cursor/rules/flutter-erp-ui-consistency.mdc` 준수

---

## 8. 구현 단계 (로드맵)

### Phase 1 — 화면 + API 스켈레톤 (1주)

- [x] DB DDL 작성 (`deploy/db/migrations/20260715_eap_daou_schema.sql`) — **테이블·컬럼 COMMENT 필수**
- [x] Backend: `EapFormConfig` MyBatis Mapper + Service
- [x] Backend: `GET/POST/PUT/DELETE /eap/forms` CRUD
- [x] Flutter: `eap001_settings_view` — 양식 코드 관리 UI
- [x] Flutter: `eap001_provider` + API 클라이언트
- [x] 목록/상세 API 연동
- [x] 목업 제거 (`mock_eap_documents.dart` 삭제)

### Phase 2 — 기안·매핑 (1주)

- [x] Backend: `POST /eap/draft` + 기본 HTML 템플릿
- [x] Backend: `erp_approval_mappings` INSERT/UPDATE
- [x] Flutter: 새 기안 시트 → draft API 연동
- [x] Flutter: 기안 문서함(`/eap/drafted`) API 표시

### Phase 3 — 조회·동기화 (잔여)

- [x] Backend: `GET /eap/documents`, `GET /eap/documents/{id}` (매핑 기반)
- [x] Backend: `POST /eap/status` 콜백
- [ ] Backend: 스케줄러 — 진행중 문서 상태 polling
- [x] Flutter: 문서 상세 결재선·본문 (간단 HTML 텍스트)
- [ ] 승인/반려 시 ERP 전표 후처리 훅
- [ ] 다우 본문 조회 API로 상세 HTML·결재선 실데이터 표시

### Phase 4 — 운영·검증

- [ ] DB 마이그레이션을 로컬/필드에 적용
- [ ] 다우 실환경 Client ID/Secret 설정
- [ ] formCode 실제 등록 및 connection-test 통과
- [ ] 사원 ↔ 다우 사용자 ID 매핑 검증
- [ ] `flutter analyze` / 백엔드 테스트
- [ ] 필드 서버 배포 (`deploy/package/field-server`)

---

## 9. 다우오피스 사전 준비 (코드 외)

- [ ] 다우 관리자: 결재 양식 생성 → **시스템 연동 v4** + **코드** 발급
- [ ] Open API Client ID / Secret 발급
- [ ] ERP 사원번호 ↔ 다우 사용자 ID 매핑 확인
- [ ] ERP 서버 → 다우 API HTTPS(443) 방화벽 허용
- [ ] `callbackUrl` 공인 URL 등록 (필드: `https://test.yeokjeon.com/api/eap/status`)

---

## 10. 환경 변수

| 변수 | 설명 |
|------|------|
| `DAOU_CLIENT_ID` | 다우 Open API Client ID |
| `DAOU_CLIENT_SECRET` | 다우 Open API Client Secret |
| `DAOU_FORM_CODE` | 기본 양식 코드 (fallback) |
| `DAOU_CALLBACK_URL` | 상태 콜백 URL |

---

## 11. 관련 파일·문서

| 경로 | 설명 |
|------|------|
| `app_flutter/lib/pages/eap/` | Flutter 전자결재 모듈 |
| `backend/src/main/java/com/yeokjeon/erp/eap/` | Spring EAP 패키지 |
| `backend/src/main/resources/mapper/eap/` | MyBatis XML |
| `deploy/db/migrations/20260715_eap_daou_schema.sql` | EAP DDL + COMMENT |
| `docs/ERP_PROJECT_GUIDE.md` | 프로젝트 공통 규칙 |
| `daou_erp_integration_guide.md` | 연동 가이드 원본 |

---

## 12. 리스크·주의사항

| 항목 | 내용 |
|------|------|
| 조직도 매핑 | 기안자·결재자 ID는 다우 내부 사용자 ID — ERP 사번과 불일치 시 기안 실패 |
| formCode 불일치 | 다우 관리자 "코드"와 ERP DB `form_code`가 다르면 955 오류 |
| 콜백 URL | 로컬 개발 시 ngrok 등 터널 필요, 운영은 공인 도메인 필수 |
| v4 vs 토큰 | 현재 draft/connection-test는 form POST 방식 — `daou_api_tokens`는 필요 시 활성화 |
| 빈 문서함 | 목업 제거 후 API·DB에 매핑이 없으면 목록은 빈 화면(정상) |

---

## 13. 다음 작업

1. 로컬/필드 DB에 `20260715_eap_daou_schema.sql` 적용
2. 다우 Client ID/Secret·실제 formCode 설정 후 connection-test
3. Phase 3 잔여: 상태 polling 스케줄러, ERP 전표 승인/반려 훅
4. 다우 본문 조회 API로 상세 화면 고도화
