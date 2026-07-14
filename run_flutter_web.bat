@echo off
chcp 65001 >nul 2>&1
setlocal

set "PROJECT_DIR=%~dp0app_flutter"
set "PURO_BIN=%USERPROFILE%\.puro\bin\puro.bat"
set "PURO_FLUTTER=%USERPROFILE%\.puro\envs\v3_41_4\flutter\bin\flutter.bat"
set "PORT=3000"
set "USE_PURO=0"
set "FLUTTER_EXE="

if not exist "%PROJECT_DIR%" (
  echo [ERROR] app_flutter folder not found: %PROJECT_DIR%
  pause
  exit /b 1
)

if exist "%PURO_BIN%" (
  set "USE_PURO=1"
) else if exist "%PURO_FLUTTER%" (
  set "FLUTTER_EXE=%PURO_FLUTTER%"
) else (
  where flutter >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] flutter not found. Install Flutter or Puro.
    echo   Puro: %PURO_BIN%
    echo   Puro Flutter: %PURO_FLUTTER%
    pause
    exit /b 1
  )
  set "FLUTTER_EXE=flutter"
)

cd /d "%PROJECT_DIR%"
set "PORT_BUSY="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do set "PORT_BUSY=1"
if defined PORT_BUSY (
  echo [WARN] Port %PORT% is in use. Using 3001.
  set "PORT=3001"
)

set "DEFINE_FILE=%PROJECT_DIR%\dart_defines.local.json"
set "DEFINE_EXAMPLE=%PROJECT_DIR%\dart_defines.local.example.json"
if not exist "%DEFINE_FILE%" (
  if exist "%DEFINE_EXAMPLE%" (
    echo [INFO] Creating dart_defines.local.json from example.
    copy /Y "%DEFINE_EXAMPLE%" "%DEFINE_FILE%" >nul
  ) else (
    echo [WARN] dart_defines.local.json missing. Map may not load on /sales-areas/search.
  )
)

set "DEFINE_ARG="
if exist "%DEFINE_FILE%" set "DEFINE_ARG=--dart-define-from-file=%DEFINE_FILE%"

echo [INFO] Flutter Web (Chrome, port %PORT%)...
if "%USE_PURO%"=="1" (
  echo [INFO] Using Puro: %PURO_BIN%
  call "%PURO_BIN%" flutter run -d chrome --web-port %PORT% %DEFINE_ARG%
) else (
  echo [INFO] Using: %FLUTTER_EXE%
  call "%FLUTTER_EXE%" run -d chrome --web-port %PORT% %DEFINE_ARG%
)

endlocal
