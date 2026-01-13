@echo off
setlocal enabledelayedexpansion

REM Build script for llama.cpp library (Windows)
REM Supports multiple backends: CPU, CUDA, Vulkan
REM Supports dynamic backend loading (GGML_BACKEND_DL)

set SCRIPT_DIR=%~dp0
set LLAMA_DIR=%SCRIPT_DIR%..\thirdparty\llama.cpp
set BUILD_DIR=%LLAMA_DIR%\build

REM Default configuration
set BUILD_TYPE=Release
set BACKEND=vulkan
set FORCE_REBUILD=0
set JOBS=%NUMBER_OF_PROCESSORS%
set NATIVE=OFF
set AVX2=ON
set CLEAN_BUILD=0
set ALL_BACKENDS=0
set DYNAMIC_BACKENDS=0

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="--cpu" (
    set BACKEND=cpu
    shift
    goto :parse_args
)
if /i "%~1"=="--cuda" (
    echo [WARNING] CUDA support is not yet implemented. Falling back to Vulkan.
    echo           See GitHub issue for CUDA implementation status.
    set BACKEND=vulkan
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
if /i "%~1"=="--all-backends" (
    set ALL_BACKENDS=1
    shift
    goto :parse_args
)
if /i "%~1"=="--dynamic" (
    set DYNAMIC_BACKENDS=1
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
echo Backend Options:
echo   --vulkan       Build with Vulkan support (default, recommended for GPU)
echo   --cpu          Build with CPU backend only
echo   --all-backends Build ALL available backends (Vulkan + CPU)
echo   --dynamic      Enable dynamic backend loading (GGML_BACKEND_DL)
echo.
echo   Note: CUDA support is not yet implemented. See GitHub issue for status.
echo.
echo CPU Options:
echo   --native       Enable native CPU optimizations (faster, not portable)
echo   --no-native    Disable native CPU optimizations (default, portable)
echo   --avx2         Enable AVX2 (default: on)
echo   --no-avx2      Disable AVX2
echo.
echo Build Options:
echo   --debug        Build debug version
echo   --clean        Clean build directory before building
echo   --rebuild      Force rebuild even if already built
echo   -j N           Number of parallel jobs (default: auto)
echo   -h, --help     Show this help message
echo.
echo Examples:
echo   %~nx0                          # Vulkan build (default)
echo   %~nx0 --cpu                    # CPU-only build
echo   %~nx0 --all-backends --dynamic # All backends as dynamic libraries
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
echo Backend:         %BACKEND%
echo All Backends:    %ALL_BACKENDS%
echo Dynamic Loading: %DYNAMIC_BACKENDS%
echo Build Type:      %BUILD_TYPE%
echo Native:          %NATIVE%
echo AVX2:            %AVX2%
echo Jobs:            %JOBS%
echo.

REM Build CMake flags
set CMAKE_FLAGS=-DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF
set CMAKE_FLAGS=%CMAKE_FLAGS% -DLLAMA_CURL=OFF -DLLAMA_BUILD_TOOLS=OFF
set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_NATIVE=%NATIVE% -DGGML_AVX2=%AVX2%

REM Configure dynamic backend loading
if %DYNAMIC_BACKENDS%==1 (
    echo [INFO] Enabling dynamic backend loading ^(GGML_BACKEND_DL^)...
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DBUILD_SHARED_LIBS=ON -DGGML_BACKEND_DL=ON
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_CPU_ALL_VARIANTS=ON
) else (
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DBUILD_SHARED_LIBS=OFF
)

REM Use static CRT to match godot-cpp (/MT instead of /MD)
REM CMAKE_MSVC_RUNTIME_LIBRARY requires CMP0091=NEW which llama.cpp might not set
REM So we use the direct approach: override compiler flags
set CMAKE_FLAGS=!CMAKE_FLAGS! -DCMAKE_POLICY_DEFAULT_CMP0091=NEW
if /i "%BUILD_TYPE%"=="Release" (
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded
) else (
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebug
)

REM Configure backend-specific flags
if %ALL_BACKENDS%==1 (
    echo [INFO] Configuring ALL backends build...

    REM CPU is always enabled
    echo [INFO]   - CPU backend: enabled

    REM CUDA is not yet implemented
    echo [INFO]   - CUDA backend: skipped ^(not yet implemented^)
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_CUDA=OFF

    REM Check and enable Vulkan if available (check VULKAN_SDK env or glslc in PATH)
    set VULKAN_AVAILABLE=0
    if defined VULKAN_SDK (
        set VULKAN_AVAILABLE=1
    ) else (
        where glslc >nul 2>&1
        if not errorlevel 1 set VULKAN_AVAILABLE=1
    )
    if !VULKAN_AVAILABLE!==1 (
        echo [INFO]   - Vulkan backend: enabled
        set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_VULKAN=ON
    ) else (
        echo [INFO]   - Vulkan backend: skipped ^(Vulkan SDK not found^)
        set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_VULKAN=OFF
    )

    REM Disable SYCL by default (requires special setup)
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_SYCL=OFF
) else (
    if /i "%BACKEND%"=="cpu" (
        echo [INFO] Configuring CPU-only build...
        set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_CUDA=OFF -DGGML_VULKAN=OFF -DGGML_SYCL=OFF
    )
    if /i "%BACKEND%"=="vulkan" (
        echo [INFO] Configuring Vulkan build...
        REM Check if Vulkan SDK is available
        set VULKAN_AVAILABLE=0
        if defined VULKAN_SDK (
            set VULKAN_AVAILABLE=1
        ) else (
            where glslc >nul 2>&1
            if not errorlevel 1 set VULKAN_AVAILABLE=1
        )
        if !VULKAN_AVAILABLE!==1 (
            set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_VULKAN=ON
        ) else (
            echo [WARNING] Vulkan SDK not found. Falling back to CPU-only build.
            echo           Install Vulkan SDK for GPU acceleration.
            set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_VULKAN=OFF
        )
        set CMAKE_FLAGS=!CMAKE_FLAGS! -DGGML_CUDA=OFF -DGGML_SYCL=OFF
    )
)

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Check for Ninja (recommended for Vulkan builds to avoid long path issues)
set CMAKE_GENERATOR=
where ninja >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Using Ninja generator ^(faster, avoids long path issues^)
    set CMAKE_GENERATOR=-G Ninja
) else (
    echo [INFO] Ninja not found, using Visual Studio generator
    echo [INFO] Tip: Install Ninja for faster builds: winget install Ninja-build.Ninja
)

REM Configure with CMake
echo [INFO] Running CMake configure...
cmake -B "%BUILD_DIR%" -S "%LLAMA_DIR%" %CMAKE_GENERATOR% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% %CMAKE_FLAGS%
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
set BUILD_SUCCESS=0

REM Check for static library (Ninja puts files directly in build/src)
if exist "%BUILD_DIR%\src\llama.lib" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\src
)
REM Visual Studio generator paths
if exist "%BUILD_DIR%\%BUILD_TYPE%\llama.lib" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\%BUILD_TYPE%
)
if exist "%BUILD_DIR%\bin\%BUILD_TYPE%\llama.lib" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\bin\%BUILD_TYPE%
)

REM Check for dynamic library (when GGML_BACKEND_DL=ON)
if exist "%BUILD_DIR%\bin\llama.dll" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\bin
)
if exist "%BUILD_DIR%\bin\%BUILD_TYPE%\llama.dll" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\bin\%BUILD_TYPE%
)
if exist "%BUILD_DIR%\%BUILD_TYPE%\llama.dll" (
    set BUILD_SUCCESS=1
    set LIB_LOCATION=%BUILD_DIR%\%BUILD_TYPE%
)

if %BUILD_SUCCESS%==1 (
    echo.
    echo [SUCCESS] llama.cpp built successfully!
    echo Library location: %LIB_LOCATION%

    REM List generated backend DLLs if dynamic loading is enabled
    if %DYNAMIC_BACKENDS%==1 (
        echo.
        echo Backend libraries generated:
        for %%f in ("%LIB_LOCATION%\ggml-*.dll") do (
            echo   - %%~nxf
        )
    )
    exit /b 0
)

echo.
echo [WARNING] Build completed but library location may vary.
echo           Check %BUILD_DIR% for the output files.
exit /b 0
