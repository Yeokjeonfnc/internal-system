# 역전 F&C ERP 백엔드

PostgreSQL + Java Spring Boot 기반 ERP 백엔드 시스템

## 기술 스택

- **Java**: 17
- **Spring Boot**: 3.2.5
- **PostgreSQL**: 15+
- **JPA/Hibernate**: ORM
- **Maven**: 빌드 도구
- **Lombok**: 코드 간소화

## 사전 요구사항

1. **JDK 17** 설치
   - [Oracle JDK 17](https://www.oracle.com/java/technologies/downloads/#java17) 또는
   - [OpenJDK 17](https://adoptium.net/)

2. **PostgreSQL 15+** 설치
   - [PostgreSQL 다운로드](https://www.postgresql.org/download/)

3. **Maven** 설치 (선택사항 - IDE에 내장됨)
   - [Maven 다운로드](https://maven.apache.org/download.cgi)

## 데이터베이스 설정

### 연결 정보

- **Host**: localhost
- **Port**: 5432
- **Database**: yeokjeon_db
- **Username**: postgres
- **Password**: yeokjeon123

### 1. PostgreSQL 데이터베이스 생성

```sql
-- PostgreSQL 접속
psql -U postgres -h localhost

-- 데이터베이스 생성
CREATE DATABASE yeokjeon_db;

-- 데이터베이스 확인
\l

-- yeokjeon_db 접속
\c yeokjeon_db
```

### 2. 데이터베이스 설정 확인

`src/main/resources/application.yml` 파일의 데이터베이스 설정:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/yeokjeon_db
    username: postgres
    password: yeokjeon123
```

## 프로젝트 실행

### IDE에서 실행 (IntelliJ IDEA 또는 Eclipse)

1. 프로젝트 import (Maven 프로젝트로)
2. `YeokjeonErpApplication.java` 파일을 열고 실행

### 커맨드 라인에서 실행

```bash
# backend 폴더로 이동
cd backend

# Maven으로 빌드 및 실행
mvn spring-boot:run

# 또는 JAR 파일 빌드 후 실행
mvn clean package
java -jar target/erp-backend-1.0.0.jar
```

## API 테스트

서버가 실행되면 `http://localhost:8080/api` 에서 접근 가능합니다.

### 가맹점 API 예시

```bash
# 모든 가맹점 조회
curl http://localhost:8080/api/stores

# 가맹점 생성
curl -X POST http://localhost:8080/api/stores \
  -H "Content-Type: application/json" \
  -d '{
    "storeCode": "STORE001",
    "storeName": "역전할머니맥주 강남점",
    "brand": "역전할머니맥주",
    "businessNumber": "123-45-67890",
    "storeArea": "서울",
    "contractStatus": "NEW_CONTRACT",
    "openingDate": "2024-01-15",
    "address": "서울시 강남구",
    "contact": "02-1234-5678"
  }'

# 가맹점 상세 조회
curl http://localhost:8080/api/stores/STORE001

# 가맹점 수정
curl -X PUT http://localhost:8080/api/stores/STORE001 \
  -H "Content-Type: application/json" \
  -d '{
    "storeCode": "STORE001",
    "storeName": "역전할머니맥주 강남점(수정)",
    "brand": "역전할머니맥주",
    "contact": "02-9999-9999"
  }'

# 가맹점 삭제
curl -X DELETE http://localhost:8080/api/stores/STORE001

# 가맹점 검색
curl "http://localhost:8080/api/stores/search?storeName=강남"
```

## 프로젝트 구조

```
backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/yeokjeon/erp/
│   │   │       ├── YeokjeonErpApplication.java
│   │   │       ├── common/          # 공통 클래스
│   │   │       │   ├── ApiResponse.java
│   │   │       │   └── BaseEntity.java
│   │   │       ├── config/          # 설정 클래스
│   │   │       │   └── WebConfig.java
│   │   │       ├── exception/       # 예외 처리
│   │   │       │   ├── GlobalExceptionHandler.java
│   │   │       │   └── ResourceNotFoundException.java
│   │   │       └── store/           # 가맹점 모듈
│   │   │           ├── controller/
│   │   │           ├── service/
│   │   │           ├── repository/
│   │   │           ├── entity/
│   │   │           └── dto/
│   │   └── resources/
│   │       └── application.yml
│   └── test/
│       └── java/
└── pom.xml
```

## 주요 기능

- ✅ RESTful API
- ✅ JPA/Hibernate ORM
- ✅ PostgreSQL 연동
- ✅ CORS 설정 (Flutter 연동용)
- ✅ 전역 예외 처리
- ✅ Request/Response DTO 패턴
- ✅ 공통 응답 형식
- ✅ 엔티티 자동 생성/수정 시간 기록
- ✅ Validation 검증

## 개발 환경 설정

### 프로파일

- **dev**: 개발 환경 (테이블 자동 생성)
- **prod**: 운영 환경 (테이블 검증만)

```bash
# 개발 환경으로 실행
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 운영 환경으로 실행
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

## 다음 단계

1. **엔티티 추가**: 창업자, 물건, 부서, 사원 등
2. **인증/인가**: Spring Security + JWT
3. **파일 업로드**: 문서 관리
4. **페이징/정렬**: 목록 조회 개선
5. **검색 기능**: 복잡한 검색 조건
6. **통계/리포트**: 대시보드 데이터

## 문제 해결

### 포트가 이미 사용 중인 경우

`application.yml`에서 포트 변경:
```yaml
server:
  port: 8081  # 원하는 포트로 변경
```

### 데이터베이스 연결 실패

1. PostgreSQL이 실행 중인지 확인
2. 데이터베이스 이름, 사용자명, 비밀번호 확인
3. PostgreSQL 포트 확인 (기본: 5432)

## 라이선스

Proprietary - 역전 F&C
