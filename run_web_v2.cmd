@echo off
setlocal enabledelayedexpansion
set "PROJECT_DIR=%~dp0"

for /L %%i in (1,1,10) do (
  cd /d "%PROJECT_DIR%"
  if exist "%PROJECT_DIR%pubspec.yaml" goto :found
  timeout /t 1 /nobreak >nul
)

:found
cd /d "%PROJECT_DIR%"
call "C:\Users\nriccio\flutter\bin\flutter.bat" run -d chrome --web-port 5050 --dart-define-from-file=api_football.json
