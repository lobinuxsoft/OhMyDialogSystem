@echo off
setlocal enabledelayedexpansion

REM Build script for OhMyDialogSystem GDExtension (Windows)
REM Requires: Visual Studio Build Tools, Python 3, SCons, CMake

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

REM Check if cmake is available
where cmake >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake not found. Please install CMake.
    exit /b 1
)

REM Default values
set TARGET=template_debug
set PLATFORM=windows
set JOBS=%NUMBER_OF_PROCESSORS%

REM llama.cpp options
set LLAMA_BACKEND=cpu
set LLAMA_NATIVE=yes
set LLAMA_AVX2=yes
set LLAMA_REBUILD=no

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="debug" (
    set TARGET=template_debug
    shift
    goto :parse_args
)
if /i "%~1"=="release" (
    set TARGET=template_release
    shift
    goto :parse_args
)
if /i "%~1"=="editor" (
    set TARGET=editor
    shift
    goto :parse_args
)
if /i "%~1"=="-j" (
    set JOBS=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--cpu" (
    set LLAMA_BACKEND=cpu
    shift
    goto :parse_args
)
if /i "%~1"=="--cuda" (
    set LLAMA_BACKEND=cuda
    shift
    goto :parse_args
)
if /i "%~1"=="--vulkan" (
    set LLAMA_BACKEND=vulkan
    shift
    goto :parse_args
)
if /i "%~1"=="--sycl" (
    set LLAMA_BACKEND=sycl
    shift
    goto :parse_args
)
if /i "%~1"=="--no-native" (
    set LLAMA_NATIVE=no
    shift
    goto :parse_args
)
if /i "%~1"=="--no-avx2" (
    set LLAMA_AVX2=no
    shift
    goto :parse_args
)
if /i "%~1"=="--rebuild-llama" (
    set LLAMA_REBUILD=yes
    shift
    goto :parse_args
)
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
echo [WARNING] Unknown option: %~1
shift
goto :parse_args

:show_help
echo.
echo Usage: %~nx0 [TARGET] [OPTIONS]
echo.
echo Targets:
echo   debug         Build debug version (default)
echo   release       Build release version
echo   editor        Build editor version
echo.
echo Options:
echo   -j N          Number of parallel jobs (default: auto)
echo.
echo llama.cpp Backend Options:
echo   --cpu         Use CPU backend (default)
echo   --cuda        Use CUDA backend (requires CUDA Toolkit)
echo   --vulkan      Use Vulkan backend (requires Vulkan SDK)
echo   --sycl        Use SYCL backend (requires Intel oneAPI)
echo.
echo llama.cpp Build Options:
echo   --no-native   Disable native CPU optimizations
echo   --no-avx2     Disable AVX2 instructions
echo   --rebuild-llama  Force rebuild of llama.cpp
echo.
echo Examples:
echo   %~nx0 release                    # Release build, CPU backend
echo   %~nx0 debug --cuda -j 8          # Debug build, CUDA backend
echo   %~nx0 release --vulkan           # Release build, Vulkan backend
exit /b 0

:done_parsing
echo.
echo Platform:       %PLATFORM%
echo Target:         %TARGET%
echo Jobs:           %JOBS%
echo llama backend:  %LLAMA_BACKEND%
echo llama native:   %LLAMA_NATIVE%
echo llama AVX2:     %LLAMA_AVX2%
echo.

REM Build llama.cpp first if needed
set LLAMA_BUILD_DIR=thirdparty\llama.cpp\build
if not exist "%LLAMA_BUILD_DIR%" set NEED_LLAMA_BUILD=1
if "%LLAMA_REBUILD%"=="yes" set NEED_LLAMA_BUILD=1

if defined NEED_LLAMA_BUILD (
    echo [INFO] Building llama.cpp...
    set LLAMA_ARGS=--%LLAMA_BACKEND%
    if "%LLAMA_NATIVE%"=="no" set LLAMA_ARGS=!LLAMA_ARGS! --no-native
    if "%LLAMA_AVX2%"=="no" set LLAMA_ARGS=!LLAMA_ARGS! --no-avx2
    if "%LLAMA_REBUILD%"=="yes" set LLAMA_ARGS=!LLAMA_ARGS! --rebuild
    call scripts\build_llama.bat !LLAMA_ARGS! -j %JOBS%
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] llama.cpp build failed!
        exit /b 1
    )
)

echo [INFO] Building GDExtension...
scons platform=%PLATFORM% target=%TARGET% llama_backend=%LLAMA_BACKEND% llama_native=%LLAMA_NATIVE% llama_avx2=%LLAMA_AVX2% llama_rebuild=%LLAMA_REBUILD% -j%JOBS%

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo [SUCCESS] Build completed!
echo Output: addons/ohmydialog/gdextension/
