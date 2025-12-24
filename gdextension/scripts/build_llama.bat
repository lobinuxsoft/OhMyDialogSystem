@echo off
setlocal enabledelayedexpansion

REM Build script for llama.cpp static library (Windows)
REM Supports multiple backends: CPU, CUDA, Vulkan

set SCRIPT_DIR=%~dp0
set LLAMA_DIR=%SCRIPT_DIR%..\thirdparty\llama.cpp
set BUILD_DIR=%LLAMA_DIR%\build

REM Default configuration
set BUILD_TYPE=Release
set BACKEND=cpu
set FORCE_REBUILD=0
set JOBS=%NUMBER_OF_PROCESSORS%
set NATIVE=ON
set AVX2=ON
set CLEAN_BUILD=0

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="--cpu" (
    set BACKEND=cpu
    shift
    goto :parse_args
)
if /i "%~1"=="--cuda" (
    set BACKEND=cuda
    shift
    goto :parse_args
)
if /i "%~1"=="--vulkan" (
    set BACKEND=vulkan
    shift
    goto :parse_args
)
if /i "%~1"=="--sycl" (
    set BACKEND=sycl
    shift
    goto :parse_args
)
if /i "%~1"=="--native" (
    set NATIVE=ON
    shift
    goto :parse_args
)
if /i "%~1"=="--no-native" (
    set NATIVE=OFF
    shift
    goto :parse_args
)
if /i "%~1"=="--avx2" (
    set AVX2=ON
    shift
    goto :parse_args
)
if /i "%~1"=="--no-avx2" (
    set AVX2=OFF
    shift
    goto :parse_args
)
if /i "%~1"=="--debug" (
    set BUILD_TYPE=Debug
    shift
    goto :parse_args
)
if /i "%~1"=="--clean" (
    set CLEAN_BUILD=1
    shift
    goto :parse_args
)
if /i "%~1"=="--rebuild" (
    set FORCE_REBUILD=1
    shift
    goto :parse_args
)
if /i "%~1"=="-j" (
    set JOBS=%~2
    shift
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
echo Options:
echo   --cpu          Build with CPU backend only (default)
echo   --cuda         Build with CUDA support (requires CUDA Toolkit)
echo   --vulkan       Build with Vulkan support (requires Vulkan SDK)
echo   --sycl         Build with SYCL support (requires Intel oneAPI)
echo   --native       Enable native CPU optimizations (default: on)
echo   --no-native    Disable native CPU optimizations
echo   --avx2         Enable AVX2 (default: on)
echo   --no-avx2      Disable AVX2
echo   --debug        Build debug version
echo   --clean        Clean build directory before building
echo   --rebuild      Force rebuild even if already built
echo   -j N           Number of parallel jobs (default: auto)
echo   -h, --help     Show this help message
echo.
echo Examples:
echo   %~nx0 --cpu                    # CPU-only build
echo   %~nx0 --cuda -j 8              # CUDA build with 8 jobs
echo   %~nx0 --vulkan --no-native     # Vulkan without native opts
exit /b 0

:done_parsing

REM Check if llama.cpp exists
if not exist "%LLAMA_DIR%" (
    echo [ERROR] llama.cpp not found at: %LLAMA_DIR%
    echo         Run: git submodule update --init --recursive
    exit /b 1
)

REM Clean if requested
if %CLEAN_BUILD%==1 (
    echo [INFO] Cleaning build directory...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
)

REM Check if already built (unless forcing rebuild)
if exist "%BUILD_DIR%\Release\llama.lib" (
    if %FORCE_REBUILD%==0 (
        echo [INFO] llama.cpp already built. Use --rebuild to force rebuild.
        exit /b 0
    )
)
if exist "%BUILD_DIR%\Debug\llama.lib" (
    if %FORCE_REBUILD%==0 (
        echo [INFO] llama.cpp already built. Use --rebuild to force rebuild.
        exit /b 0
    )
)

REM Check for cmake
where cmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] CMake not found. Please install CMake.
    exit /b 1
)

echo ========================================
echo  Building llama.cpp
echo ========================================
echo.
echo Backend:    %BACKEND%
echo Build Type: %BUILD_TYPE%
echo Native:     %NATIVE%
echo AVX2:       %AVX2%
echo Jobs:       %JOBS%
echo.

REM Build CMake flags
set CMAKE_FLAGS=-DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF
set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_NATIVE=%NATIVE% -DGGML_AVX2=%AVX2%

REM Configure backend-specific flags
if /i "%BACKEND%"=="cpu" (
    echo [INFO] Configuring CPU-only build...
    set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_CUDA=OFF -DGGML_VULKAN=OFF -DGGML_SYCL=OFF
)
if /i "%BACKEND%"=="cuda" (
    echo [INFO] Configuring CUDA build...
    where nvcc >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] CUDA Toolkit not found. Please install CUDA Toolkit.
        exit /b 1
    )
    set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=75;80;86;89
)
if /i "%BACKEND%"=="vulkan" (
    echo [INFO] Configuring Vulkan build...
    set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_VULKAN=ON
)
if /i "%BACKEND%"=="sycl" (
    echo [INFO] Configuring SYCL build...
    if not defined ONEAPI_ROOT (
        echo [WARNING] Intel oneAPI not detected. SYCL build may fail.
    )
    set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_SYCL=ON
)

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Configure with CMake
echo [INFO] Running CMake configure...
cmake -B "%BUILD_DIR%" -S "%LLAMA_DIR%" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% %CMAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] CMake configure failed.
    exit /b 1
)

REM Build
echo [INFO] Building llama.cpp...
cmake --build "%BUILD_DIR%" --config %BUILD_TYPE% -j %JOBS%
if errorlevel 1 (
    echo [ERROR] Build failed.
    exit /b 1
)

REM Verify build
if exist "%BUILD_DIR%\%BUILD_TYPE%\llama.lib" (
    echo.
    echo [SUCCESS] llama.cpp built successfully!
    echo Library location: %BUILD_DIR%\%BUILD_TYPE%
    exit /b 0
)
if exist "%BUILD_DIR%\bin\%BUILD_TYPE%\llama.lib" (
    echo.
    echo [SUCCESS] llama.cpp built successfully!
    echo Library location: %BUILD_DIR%\bin\%BUILD_TYPE%
    exit /b 0
)

echo.
echo [WARNING] Build completed but library location may vary.
echo           Check %BUILD_DIR% for the output files.
exit /b 0
