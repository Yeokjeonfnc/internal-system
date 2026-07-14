@echo off
chcp 65001 >nul 2>&1
setlocal

rem 로컬 개발용 실행 스크립트 - flutter build web 으로 빌드 후 로컬 서버로 서빙
rem dart-define 은 파일이 아니라 커맨드라인으로 직접 넘겨 동기화 충돌을 피함

set "PROJECT_DIR=%~dp0app_flutter"
set "PURO_FLUTTER=%USERPROFILE%\.puro\envs\v3_41_4\flutter\bin\flutter.bat"
set "PORT=3050"
set "FLUTTER_EXE="
set "PYTHON_EXE="

set "API_BASE_URL=https://test.yeokjeon.com/api"
set "KAKAO_MAP_JAVASCRIPT_KEY=3649c96a39bc8cff269119d8cffbe4e0"

if not exist "%PROJECT_DIR%" (
  echo [ERROR] app_flutter folder not found: %PROJECT_DIR%
  pause
  exit /b 1
)

rem 이 프로젝트는 Flutter v3.41.4 로 고정 - Puro 기본 환경이 아닌 이 경로를 직접 사용
if exist "%PURO_FLUTTER%" (
  set "FLUTTER_EXE=%PURO_FLUTTER%"
) else (
  where flutter >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] flutter not found. Install Flutter or Puro.
    echo   Expected: %PURO_FLUTTER%
    pause
    exit /b 1
  )
  echo [WARN] 고정 버전^(v3_41_4^)을 못 찾아 PATH의 flutter를 씁니다 — 버전이 다르면 빌드가 실패할 수 있습니다.
  set "FLUTTER_EXE=flutter"
)

where python >nul 2>&1
if errorlevel 1 (
  where py >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] python not found. Install Python ^(python.org^) — 빌드된 파일을 로컬에 서빙하는 데 필요합니다.
    pause
    exit /b 1
  )
  set "PYTHON_EXE=py"
) else (
  set "PYTHON_EXE=python"
)

cd /d "%PROJECT_DIR%"

echo [INFO] Using: %FLUTTER_EXE%
echo [INFO] 로컬 백엔드(%API_BASE_URL%)를 바라보도록 웹 빌드 중... (약 1분 소요)
rem flutter.bat 을 call 로 직접 부르면 스크립트가 같이 죽는 문제가 있어 격리 실행
cmd /c ""%FLUTTER_EXE%" build web --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=%KAKAO_MAP_JAVASCRIPT_KEY%"
if errorlevel 1 (
  echo [ERROR] 빌드 실패. 위 에러 메시지를 확인하세요.
  pause
  exit /b 1
)

set "PORT_BUSY="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do set "PORT_BUSY=1"
if defined PORT_BUSY (
  echo [WARN] Port %PORT% is in use. Using 3051.
  set "PORT=3051"
)

echo.
echo [INFO] 로컬 백엔드가 %API_BASE_URL% 에서 켜져 있어야 로그인 후 데이터가 보입니다.
echo [INFO] http://localhost:%PORT% 에서 서빙합니다. 이 창을 닫으면 서버가 멈춥니다.
echo [INFO] 코드 수정 후엔 이 파일을 다시 실행하세요(재빌드 후 새로고침).
echo.

cd build\web
%PYTHON_EXE% -m http.server %PORT%

endlocal
