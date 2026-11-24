@echo off
REM =========================================================================
REM Environment setter script for Mobile-Language-App
REM Prepends the isolated .tools\flutter\bin directory to process PATH
REM =========================================================================

set "PROJECT_ROOT=%~dp0"
set "FLUTTER_BIN=%PROJECT_ROOT%.tools\flutter\bin"

if not exist "%FLUTTER_BIN%\flutter.bat" (
    echo [ERROR] Flutter SDK binary not found at: %FLUTTER_BIN%\flutter.bat
    exit /b 1
)

echo [LOCAL FLUTTER BRIDGE] Prepending isolated Flutter SDK to PATH:
echo   %FLUTTER_BIN%
set "PATH=%FLUTTER_BIN%;%PATH%"

echo.
echo Active Flutter environment:
call "%FLUTTER_BIN%\flutter.bat" --version

if not "%~1"=="" (
    echo.
    echo Running requested command: flutter %*
    call "%FLUTTER_BIN%\flutter.bat" %*
)
