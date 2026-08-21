# 역전 F&C 내부 ERP — 프로젝트 상세 설명

> 이 문서는 **포트폴리오 작성·면접 준비·인수인계**를 위해 저장소(`internal-system`)를 기준으로 정리한 설명서입니다.  
> 개발 실행 방법은 루트 `README.md`, 배포는 `deploy/README.md`를 참고하세요.

---

## 1. 한 줄 요약

**(주)역전에프앤씨** 내부 직원(SV·본사 관리자 등)이 쓰는 **가맹·창업 개발·현장 활동·마스터·협업** 통합 ERP입니다.  
**Spring Boot REST API + Flutter 클라이언트(웹/Windows 우선)** 모노레포로 구성되어 있으며, 사내 전용(`publish_to: none`)입니다.

---

## 2. 배경과 목적

프랜차이즈 본사 업무는 보통 다음이 흩어져 있습니다.

| 업무 | 예시 |
|------|------|
| 가맹점 마스터 | 점포 정보, 계약/운영 상태, 문서, NFC 출입 태그 |
| 출점·개발 | 예비창업자, 후보 물건, 영업지역(지도) |
| 현장 활동 | 방문 기록, 체크리스트, 결재·지시 |
| 조직·권한 | 사원·부서·메뉴 권한 |
| 협업 | 게시판, 메신저 |
| 전자결재 | ERP 자체 기안·결재(기안하기/받은/올린/수신참조/전체문서) |

이 프로젝트는 위 업무를 **하나의 웹/데스크톱 ERP**로 모으고, 목록·검색·상세·권한·결재 흐름을 표준 UI로 통일하는 것이 목표입니다.

---

## 3. 기술 스택

### 3.1 백엔드 (`backend/`)

| 항목 | 내용 |
|------|------|
| 언어 | Java 17 |
| 프레임워크 | Spring Boot 3.2.x |
| DB | PostgreSQL |
| SQL | MyBatis 3 (복잡 목록·JOIN·집계) |
| ORM | Spring Data JPA (단건 CUD·엔티티) |
| API | REST JSON, 컨텍스트 경로 `/api` |
| 기본 포트 | **3001** |
| 빌드 | Maven |

### 3.2 프론트엔드 (`app_flutter/`)

| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter (Dart SDK ^3.11) |
| 상태관리 | `flutter_riverpod` (+ 인증은 `provider`의 `AuthProvider`) |
| 라우팅 | `go_router` + `ShellRoute`(좌측 사이드바 유지) |
| HTTP | `dio` |
| 직렬화 | `json_annotation` / `json_serializable` |
| UI | Material 3, Pretendard/Noto, 브랜드 컬러(`#BC1F26` 등) |
| 기타 | Quill(에디터), Kakao Map(웹), WebSocket(채팅), NFC, PDF 미리보기(`pdfx`) 등 |
| 플랫폼 | **Chrome 웹**, Windows 데스크톱 우선 (Android/iOS 설정도 존재) |

### 3.3 인프라·배포

- DB 스키마·시드·마이그레이션: `deploy/db/`
- 필드 서버 패키지(JAR + Flutter Web + Caddy 등): `deploy/package/field-server/`
- 테스트/운영 호스트 예: `test.yeokjeon.com` (환경에 따라 다름)

### 3.4 외부 연동

| 연동 | 용도 |
|------|------|
| **카카오 지도 JS API** | 영업지역·가맹점 위치 검색/편집 |
| (선택) NFC | 매장 출입 태그 등록·현장 앱 |

---

## 4. 저장소 구조

```
internal-system/
├── backend/                 # Spring Boot API
│   └── src/main/java/com/yeokjeon/erp/
│       ├── auth/            # 로그인·프로필
│       ├── franchise/       # 가맹점
│       ├── development/     # 창업자·물건·영업지역
│       ├── active/          # 활동·체크리스트·계획
│       ├── master/          # 사원·부서·권한·이용로그·점주계정
│       ├── board/           # 게시판
│       ├── chat/            # 메신저
│       ├── eap/             # 자체 전자결재
│       └── common/          # 공통코드 등
├── app_flutter/             # Flutter 클라이언트
│   └── lib/
│       ├── core/            # 레이아웃·라우터·테마·공통위젯·API·권한
│       └── pages/           # 메뉴 코드별 화면
├── docs/                    # 설계·양식 HTML·본 설명서
├── deploy/                  # DB·서버 패키지
└── README.md                # 실행·스택 요약
```

---

## 5. 아키텍처

### 5.1 전체 흐름

```
[ Flutter Web / Windows ]
        │  Dio (JSON, camelCase)
        ▼
[ Spring Boot /api ]  ──►  PostgreSQL
        │
        ├── MyBatis (목록·집계)
        ├── JPA (단건 저장)
        └── 외부 API (카카오 지도 등)
```

### 5.2 백엔드 역할 분리

| 계층 | 역할 |
|------|------|
| `*Controller` | HTTP, DTO 입출력 |
| `*Service` | 비즈니스 규칙, 트랜잭션 |
| MyBatis `*Mapper.xml` | 복잡 SELECT / JOIN / 집계 |
| JPA Repository + Entity | 단건 조회·INSERT/UPDATE/DELETE |

### 5.3 Flutter 화면 패턴

메뉴마다 보통 다음 파일 세트를 둡니다.

| 파일 | 역할 |
|------|------|
| `*_view.dart` | UI만 |
| `*_api.dart` | REST 호출 |
| `*_model.dart` | 도메인 모델 |
| `*_provider.dart` / `*_controller.dart` | Riverpod 상태·필터·목록 |
| `*_filter.dart` | 목록 필터 상태 |

폴더명은 **메뉴 코드**와 일치합니다. 예: `pages/franchise/str001/`, `pages/development/dev001/`.

### 5.4 앱 셸(공통 레이아웃)

- 좌측 **사이드바** + 상단 **멀티 탭** + 본문: `lib/core/layout/main_frame_layout.dart`
- 상세 화면 골격(제목·빨간 탭바): `detail_screen_scaffold.dart`
- 라우트 등록: `lib/core/router/app_router.dart`의 `appRouteDefs`
- 메뉴 권한: `lib/core/menu/menu_codes.dart` + `menu_route_access.dart` + 마스터 권한 API

### 5.5 목록 UI 표준

가맹점·활동·물건·창업자 등 관리 목록은 공통 컴포넌트를 재사용합니다.

- `ListPageTemplate`
- 인라인 검색: `SearchFilterStackedItems` + Filter 슬롯
- 테이블: `ErpDataTable` (빨간 헤더)
- 필터 규칙: `RuleListNotifier` (`base_list_provider.dart`) — 규칙 목록만 정의하면 AND 필터

---

## 6. 주요 기능 (메뉴별)

사이드바·라우트·DB 메뉴는 `menu_codes.dart`의 코드로 맞춥니다.

### 6.1 대시보드 (`dsh001`)

- 홈 화면: 알림·가맹 지표·결재 대기·캘린더 등 요약
- 여러 API를 **병렬 호출**하고, 세션 캐시로 재진입 시 즉시 표시하도록 튜닝된 이력이 있음

### 6.2 가맹점 관리 (`str001`)

- 가맹점 목록·검색·등록·상세(탭)
- 브랜드·지역·운영상태 등 공통코드 연동
- 점포 문서/PDF 미리보기, NFC 태그 패널
- 모바일/현장용 **출입 관리**(NFC) 화면과 연계 가능

### 6.3 개발 관리

| 코드 | 화면 | 내용 |
|------|------|------|
| `dev001` | 예비창업자 | 창업 희망자 정보·진행 관리 |
| `dev002` | 물건 | 출점 후보 부동산/점포 물건 |
| `dev003` | 영업지역 | 지도 기반 영업권역(카카오맵) |

### 6.4 활동관리

| 코드 | 화면 | 내용 |
|------|------|------|
| `act001` | 활동현황 | 담당자·가맹점별 방문/활동 집계 |
| `act002` | 활동관리 | 방문 등록·이력·체크리스트·임시보관 |
| `act003` | 활동관리결재 | 결재 대기/승인, 알림·지시 |
| `act004` | 활동 계획 캘린더 | 일정 계획 |

공유 경로·허브: `pages/active/shared/` (`activity_routes.dart` 등).

### 6.5 마스터 관리

| 코드 | 화면 |
|------|------|
| `mst001` | 사원 |
| `mst002` | 부서 |
| `mst003` | 메뉴 권한 (팀/사용자별 조회·등록 권한) |
| `mst004` | 체크리스트 마스터 |
| `mst005` | 이용 로그 |
| `mst006` | 점주(가맹점주) 계정 |

권한에 따라 사이드바 메뉴가 보이거나 숨겨집니다.

### 6.6 협업

| 코드 | 화면 | 비고 |
|------|------|------|
| `bbs001` | 게시판 | 폴더·게시글 |
| `msg001` | 메신저 | WebSocket 기반 채팅방 |

### 6.7 전자결재 (`eap001`) — ERP 자체 결재

사이드바: 기안하기 / 받은결재 / 올린결재 / 수신참조결재 / 전체문서. 서식 관리는 기안하기 화면의 버튼으로 연다.

| 구성 | 설명 |
|------|------|
| Flutter | 서식 선택 → 결재라인(결재/합의/참조/열람) → 제목·본문 → 저장(`INPROGRESS`) / 임시저장(`TEMPSAVE`) |
| Backend | `erp_approval_mappings` + `eap_doc_line`에 저장. 폴더 목록은 로그인 사용자 기준. 결재/반려 API |
| 상태 | 임시저장 → 진행중 → 완료 / 반려 |

---

## 7. UX·브랜드

- 좌측 다크 사이드바(`#212529`), 액센트 빨강(`#BC1F26`)
- 목록: 빨간 테이블 헤더, 통일된 검색 필터
- 상세: 공통 스캐폴드로 가맹점·물건·창업자 상세 UI 일관성 유지
- 반응형: 컴팩트 폭(대략 840px 미만) 분기 존재 — PC웹·모바일웹 동시 고려

---

## 8. 성능·품질에서 다룬 이슈 (포트폴리오용 하이라이트)

실제 점검 로그(`수정사항.md` 등)에 기록된 유형의 개선 예:

1. **체감 속도**  
   - 대시보드 API 직렬 호출 → 병렬화  
   - 세션 메모리 목록 캐시(stale-while-revalidate)로 재진입 시 스피너 제거  
   - 서버 gzip 압축 설정

2. **안정성**  
   - async 이후 `mounted` 가드  
   - Flutter 정적 분석 클린업  
   - Windows 플러그인 캐시 손상으로 인한 데스크톱 기능 누락 복구

3. **아키텍처 일관성**  
   - 메뉴 코드 = 폴더 = 라우트  
   - 공통 목록/필터/테이블 위젯으로 화면 복붙 최소화  
   - MyBatis(조회) / JPA(저장) 역할 분리

4. **외부 시스템 연동**  
   - 카카오맵: dart-define으로 API 키 주입

---

## 9. 데이터·보안

- 운영 DB: PostgreSQL (`yeokjeon_db` 등)
- 스키마/시드: `deploy/db/` (`001_schema.sql`, migrations 등)
- **주의**: `application.yml`에 DB 비밀번호가 있을 수 있음 → 포트폴리오·공개 저장소에는 **마스킹·환경변수화** 권장
- 로그인: `POST /api/auth/login` → 이후 메뉴 권한에 따라 화면 접근

---

## 10. 로컬 실행 요약

1. PostgreSQL 기동 및 DB 준비  
2. `cd backend` → `mvn spring-boot:run` (포트 3001)  
3. `cd app_flutter` → `flutter pub get` → `flutter run -d chrome` (웹 포트 3000 권장)  
4. 카카오맵 화면은 `dart_defines.local.json`에 `KAKAO_MAP_JAVASCRIPT_KEY` 필요

자세한 명령은 루트 `README.md` 참고.

---

## 11. 포트폴리오에 쓸 때 추천 포인트

### 한 줄 소개 예시

> Flutter + Spring Boot 기반 프랜차이즈 본사 ERP. 가맹점·창업자·물건·현장활동·권한·메신저·자체 전자결재를 통합하고, 목록 UX·성능 최적화를 담당.

### 깊게 쓸 에피소드 후보 (2~3개만)

1. **공통 ERP UI 프레임** — ShellRoute, 목록 템플릿, RuleListNotifier, 메뉴 권한  
2. **성능** — 병렬 API + 세션 캐시로 홈/목록 체감 지연 축소  
3. **자체 전자결재** — 기안·결재라인·폴더함(받은/올린/수신참조/전체)·결재/반려 흐름

### 주의

- 사내 시스템이라 **실데이터·실서버 URL·계정은 비공개**
- 스크린샷은 더미/마스킹
- GitHub public 시 시크릿·고객사명 노출 점검

---

## 12. 관련 문서 인덱스

| 문서 | 내용 |
|------|------|
| `README.md` | 실행, 스택, 메뉴 표, API 개요 |
| `docs/ERP_PROJECT_GUIDE.md` | 개발 규칙·매핑·테이블 색인 |
| `deploy/README.md` | DB·필드 서버 배포 |
| `.cursorrules` | Flutter ERP UI/폴더 규칙 |
| `수정사항.md` | 점검·버그픽스·성능 개선 로그 |

---

*작성 기준: 저장소 `internal-system` 구조 및 README·메뉴 코드·도메인 패키지 (2026년 시점).*
