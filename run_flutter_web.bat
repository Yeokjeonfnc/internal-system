@echo off
setlocal

set "PROJECT_DIR=C:\Users\minhyo\yeokjeon\app_flutter"
set "PURO_BIN=C:\Users\minhyo\.puro\bin\puro.bat"
set "FLUTTER_ROOT=C:\Users\minhyo\.puro\envs\stable\flutter"
set "PORT=3000"

if not exist "%PROJECT_DIR%" (
  echo [ERROR] app_flutter 폴더를 찾을 수 없습니다.
  pause
  exit /b 1
)

if not exist "%PURO_BIN%" (
  echo [ERROR] Puro 실행 파일을 찾을 수 없습니다.
  echo 경로: %PURO_BIN%
  pause
  exit /b 1
)

cd /d "%PROJECT_DIR%"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do set "PORT_BUSY=1"
if defined PORT_BUSY (
  echo [WARN] %PORT% 포트가 사용 중입니다. 3001 포트로 실행합니다.
  set "PORT=3001"
)

echo [INFO] Flutter Web 실행 시작 (Chrome, port %PORT%)...
call "%PURO_BIN%" flutter run -d chrome --web-port %PORT%

endlocal
