@echo off
setlocal enabledelayedexpansion

REM Build all configurations for OhMyDialogSystem GDExtension (Windows)
REM Builds: editor, template_release, template_debug

echo ========================================
echo  OhMyDialogSystem - Build All Targets
echo ========================================
echo.

cd /d "%~dp0"

REM Default options
set LLAMA_ARGS=
set JOBS=%NUMBER_OF_PROCESSORS%
set FAILED=0

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="-j" (
    set JOBS=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--cpu" (
    set LLAMA_ARGS=!LLAMA_ARGS! --cpu
    shift
    goto :parse_args
)
if /i "%~1"=="--vulkan" (
    set LLAMA_ARGS=!LLAMA_ARGS! --vulkan
    shift
    goto :parse_args
)
if /i "%~1"=="--native" (
    set LLAMA_ARGS=!LLAMA_ARGS! --native
    shift
    goto :parse_args
)
if /i "%~1"=="--rebuild-llama" (
    set LLAMA_ARGS=!LLAMA_ARGS! --rebuild-llama
    shift
    goto :parse_args
)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
echo [WARNING] Unknown option: %~1
shift
goto :parse_args

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Builds all three targets: editor, release, and debug
echo.
echo Options:
echo   -j N              Number of parallel jobs (default: auto)
echo   --cpu             Use CPU backend instead of Vulkan
echo   --vulkan          Use Vulkan backend (default)
echo   --native          Enable native CPU optimizations
echo   --rebuild-llama   Force rebuild of llama.cpp
echo   -h, --help        Show this help message
echo.
echo Examples:
echo   %~nx0                    # Build all with Vulkan (default)
echo   %~nx0 --cpu -j 8         # Build all with CPU backend, 8 jobs
echo   %~nx0 --rebuild-llama    # Rebuild llama.cpp and all targets
exit /b 0

:done_parsing

echo Building with %JOBS% parallel jobs
echo llama.cpp args: %LLAMA_ARGS%
echo.

REM ========================================
REM Build Editor
REM ========================================
echo [1/3] Building EDITOR...
echo ----------------------------------------
call "%~dp0build.bat" editor %LLAMA_ARGS% -j %JOBS%
if %ERRORLEVEL% neq 0 (
    echo [FAILED] Editor build failed!
    set FAILED=1
) else (
    echo [OK] Editor build completed
)
echo.

REM ========================================
REM Build Release
REM ========================================
echo [2/3] Building RELEASE...
echo ----------------------------------------
call "%~dp0build.bat" release %LLAMA_ARGS% -j %JOBS%
if %ERRORLEVEL% neq 0 (
    echo [FAILED] Release build failed!
    set FAILED=1
) else (
    echo [OK] Release build completed
)
echo.

REM ========================================
REM Build Debug
REM ========================================
echo [3/3] Building DEBUG...
echo ----------------------------------------
call "%~dp0build.bat" debug %LLAMA_ARGS% -j %JOBS%
if %ERRORLEVEL% neq 0 (
    echo [FAILED] Debug build failed!
    set FAILED=1
) else (
    echo [OK] Debug build completed
)
echo.

REM ========================================
REM Summary
REM ========================================
echo ========================================
echo  Build Summary
echo ========================================
if %FAILED%==0 (
    echo [SUCCESS] All builds completed successfully!
    echo.
    echo Output files:
    echo   - libohmydialog.windows.editor.x86_64.dll
    echo   - libohmydialog.windows.template_release.x86_64.dll
    echo   - libohmydialog.windows.template_debug.x86_64.dll
    echo.
    echo Location: addons\ohmydialog\gdextension\
) else (
    echo [ERROR] Some builds failed! Check the output above.
    exit /b 1
)
