@echo off
setlocal

REM Build script for OhMyDialogSystem GDExtension (Windows)
REM Requires: Visual Studio Build Tools, Python 3, SCons

echo ========================================
echo  OhMyDialogSystem GDExtension Builder
echo ========================================

cd /d "%~dp0"

REM Check if scons is available
where scons >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] SCons not found. Install with: pip install scons
    exit /b 1
)

REM Default values
set TARGET=template_debug
set PLATFORM=windows
set JOBS=%NUMBER_OF_PROCESSORS%

REM Parse arguments
:parse_args
if "%~1"=="" goto build
if /i "%~1"=="debug" set TARGET=template_debug
if /i "%~1"=="release" set TARGET=template_release
if /i "%~1"=="editor" set TARGET=editor
if /i "%~1"=="-j" (
    set JOBS=%~2
    shift
)
shift
goto parse_args

:build
echo.
echo Building for %PLATFORM% [%TARGET%] with %JOBS% jobs...
echo.

scons platform=%PLATFORM% target=%TARGET% -j%JOBS%

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo [SUCCESS] Build completed!
echo Output: addons/ohmydialog/gdextension/
