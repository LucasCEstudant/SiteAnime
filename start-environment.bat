@echo off
setlocal

set "SCRIPT=%~dp0start-environment.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] Script not found: %SCRIPT%
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% neq 0 (
  echo.
  echo [ERROR] Failed to start environment. Exit code: %EXIT_CODE%
  exit /b %EXIT_CODE%
)

echo.
echo [OK] Environment started.
exit /b 0
