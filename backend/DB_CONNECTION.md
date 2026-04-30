# 데이터베이스 접속 정보

## PostgreSQL 연결 설정

- **Host**: localhost
- **Port**: 5432
- **Database**: yeokjeon_db
- **Username**: postgres
- **Password**: yeokjeon123

## 데이터베이스 생성 방법

### Windows PowerShell/CMD
```bash
# PostgreSQL 접속
psql -U postgres -h localhost

# 비밀번호 입력: yeokjeon123

# 데이터베이스 생성
CREATE DATABASE yeokjeon_db;

# 데이터베이스 목록 확인
\l

# yeokjeon_db 접속
\c yeokjeon_db

# 종료
\q
```

### 초기 데이터 삽입
```bash
# backend 폴더로 이동
cd backend

# SQL 스크립트 실행
psql -U postgres -h localhost -d yeokjeon_db -f scripts\init_db.sql
```

## 연결 테스트

```bash
# PostgreSQL 연결 테스트
psql -U postgres -h localhost -d yeokjeon_db -c "SELECT version();"
```

## Spring Boot 설정 확인

`backend/src/main/resources/application.yml` 파일의 데이터베이스 설정:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/yeokjeon_db
    username: postgres
    password: yeokjeon123
```

## 트러블슈팅

### 연결 실패 시
1. PostgreSQL 서비스가 실행 중인지 확인
2. 포트 5432가 사용 가능한지 확인
3. 방화벽 설정 확인
4. 데이터베이스가 생성되었는지 확인: `\l` 명령어로 확인

### 비밀번호 오류 시
```bash
# PostgreSQL 비밀번호 변경
psql -U postgres -h localhost
ALTER USER postgres PASSWORD 'yeokjeon123';
```
