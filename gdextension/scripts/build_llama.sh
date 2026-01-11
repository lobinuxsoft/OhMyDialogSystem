#!/bin/bash

# Build script for llama.cpp library
# Supports multiple backends: CPU, CUDA, Vulkan, Metal, SYCL
# Supports dynamic backend loading (GGML_BACKEND_DL)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LLAMA_DIR="$SCRIPT_DIR/../thirdparty/llama.cpp"
BUILD_DIR="$LLAMA_DIR/build"

# Default configuration
BUILD_TYPE="Release"
BACKEND="cpu"
FORCE_REBUILD=false
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
ALL_BACKENDS=false
DYNAMIC_BACKENDS=false

# CMake flags
CMAKE_FLAGS=(
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DLLAMA_BUILD_TESTS=OFF
    -DLLAMA_BUILD_EXAMPLES=OFF
    -DLLAMA_BUILD_SERVER=OFF
    -DLLAMA_BUILD_TOOLS=OFF
    -DLLAMA_CURL=OFF
)

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Backend Options:"
    echo "  --cpu          Build with CPU backend only (default)"
    echo "  --cuda         Build with CUDA support (requires CUDA Toolkit)"
    echo "  --vulkan       Build with Vulkan support (requires Vulkan SDK)"
    echo "  --metal        Build with Metal support (macOS only)"
    echo "  --sycl         Build with SYCL support (requires Intel oneAPI)"
    echo "  --all-backends Build ALL available backends"
    echo "  --dynamic      Enable dynamic backend loading (GGML_BACKEND_DL)"
    echo ""
    echo "CPU Options:"
    echo "  --native       Enable native CPU optimizations (default: on)"
    echo "  --no-native    Disable native CPU optimizations"
    echo "  --avx2         Enable AVX2 (default: on)"
    echo "  --no-avx2      Disable AVX2"
    echo ""
    echo "Build Options:"
    echo "  --debug        Build debug version"
    echo "  --clean        Clean build directory before building"
    echo "  --rebuild      Force rebuild even if already built"
    echo "  -j N           Number of parallel jobs (default: auto)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --cpu                    # CPU-only build (static)"
    echo "  $0 --cuda -j 8              # CUDA build with 8 jobs"
    echo "  $0 --all-backends --dynamic # All backends as dynamic libraries"
}

# Parse arguments
NATIVE=ON
AVX2=ON

while [[ $# -gt 0 ]]; do
    case $1 in
        --cpu)
            BACKEND="cpu"
            shift
            ;;
        --cuda)
            BACKEND="cuda"
            shift
            ;;
        --vulkan)
            BACKEND="vulkan"
            shift
            ;;
        --metal)
            BACKEND="metal"
            shift
            ;;
        --sycl)
            BACKEND="sycl"
            shift
            ;;
        --all-backends)
            ALL_BACKENDS=true
            shift
            ;;
        --dynamic)
            DYNAMIC_BACKENDS=true
            shift
            ;;
        --native)
            NATIVE=ON
            shift
            ;;
        --no-native)
            NATIVE=OFF
            shift
            ;;
        --avx2)
            AVX2=ON
            shift
            ;;
        --no-avx2)
            AVX2=OFF
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --clean)
            echo "[INFO] Cleaning build directory..."
            rm -rf "$BUILD_DIR"
            shift
            ;;
        --rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        -j)
            JOBS="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "[WARNING] Unknown option: $1"
            shift
            ;;
    esac
done

# Check if llama.cpp exists
if [ ! -d "$LLAMA_DIR" ]; then
    echo "[ERROR] llama.cpp not found at: $LLAMA_DIR"
    echo "       Run: git submodule update --init --recursive"
    exit 1
fi

# Check if already built (unless forcing rebuild)
if [ -f "$BUILD_DIR/libllama.a" ] || [ -f "$BUILD_DIR/libllama.so" ]; then
    if [ "$FORCE_REBUILD" = false ]; then
        echo "[INFO] llama.cpp already built. Use --rebuild to force rebuild."
        exit 0
    fi
fi

# Check for cmake
if ! command -v cmake &> /dev/null; then
    echo "[ERROR] CMake not found. Please install CMake."
    exit 1
fi

echo "========================================"
echo " Building llama.cpp"
echo "========================================"
echo ""
echo "Backend:         $BACKEND"
echo "All Backends:    $ALL_BACKENDS"
echo "Dynamic Loading: $DYNAMIC_BACKENDS"
echo "Build Type:      $BUILD_TYPE"
echo "Native:          $NATIVE"
echo "AVX2:            $AVX2"
echo "Jobs:            $JOBS"
echo ""

# Add CPU optimization flags
CMAKE_FLAGS+=(-DGGML_NATIVE=$NATIVE)
CMAKE_FLAGS+=(-DGGML_AVX2=$AVX2)

# Configure dynamic backend loading
if [ "$DYNAMIC_BACKENDS" = true ]; then
    echo "[INFO] Enabling dynamic backend loading (GGML_BACKEND_DL)..."
    # Remove the default BUILD_SHARED_LIBS=OFF and add the dynamic flags
    CMAKE_FLAGS=("${CMAKE_FLAGS[@]/-DBUILD_SHARED_LIBS=OFF/}")
    CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
    CMAKE_FLAGS+=(-DGGML_BACKEND_DL=ON)
    CMAKE_FLAGS+=(-DGGML_CPU_ALL_VARIANTS=ON)
fi

# Configure backend-specific flags
if [ "$ALL_BACKENDS" = true ]; then
    echo "[INFO] Configuring ALL backends build..."

    # CPU is always enabled
    echo "[INFO]   - CPU backend: enabled"

    # Check and enable CUDA if available
    if command -v nvcc &> /dev/null; then
        echo "[INFO]   - CUDA backend: enabled"
        CMAKE_FLAGS+=(-DGGML_CUDA=ON)
        CMAKE_FLAGS+=(-DCMAKE_CUDA_ARCHITECTURES="75;80;86;89")
    else
        echo "[INFO]   - CUDA backend: skipped (nvcc not found)"
        CMAKE_FLAGS+=(-DGGML_CUDA=OFF)
    fi

    # Enable Vulkan on Linux
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "[INFO]   - Vulkan backend: enabled"
        CMAKE_FLAGS+=(-DGGML_VULKAN=ON)
    else
        CMAKE_FLAGS+=(-DGGML_VULKAN=OFF)
    fi

    # Enable Metal on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "[INFO]   - Metal backend: enabled"
        CMAKE_FLAGS+=(-DGGML_METAL=ON)
    else
        CMAKE_FLAGS+=(-DGGML_METAL=OFF)
    fi

    # Disable SYCL by default
    CMAKE_FLAGS+=(-DGGML_SYCL=OFF)
else
    case $BACKEND in
        cpu)
            echo "[INFO] Configuring CPU-only build..."
            CMAKE_FLAGS+=(-DGGML_CUDA=OFF)
            CMAKE_FLAGS+=(-DGGML_VULKAN=OFF)
            CMAKE_FLAGS+=(-DGGML_METAL=OFF)
            CMAKE_FLAGS+=(-DGGML_SYCL=OFF)
            ;;
        cuda)
            echo "[INFO] Configuring CUDA build..."
            if ! command -v nvcc &> /dev/null; then
                echo "[ERROR] CUDA Toolkit not found. Please install CUDA Toolkit."
                exit 1
            fi
            CMAKE_FLAGS+=(-DGGML_CUDA=ON)
            CMAKE_FLAGS+=(-DCMAKE_CUDA_ARCHITECTURES="75;80;86;89")
            ;;
        vulkan)
            echo "[INFO] Configuring Vulkan build..."
            CMAKE_FLAGS+=(-DGGML_VULKAN=ON)
            ;;
        metal)
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo "[ERROR] Metal backend is only available on macOS."
                exit 1
            fi
            echo "[INFO] Configuring Metal build..."
            CMAKE_FLAGS+=(-DGGML_METAL=ON)
            ;;
        sycl)
            echo "[INFO] Configuring SYCL build..."
            if [ -z "$ONEAPI_ROOT" ]; then
                echo "[WARNING] Intel oneAPI not detected. SYCL build may fail."
            fi
            CMAKE_FLAGS+=(-DGGML_SYCL=ON)
            ;;
    esac
fi

# Create build directory
mkdir -p "$BUILD_DIR"

# Configure with CMake
echo "[INFO] Running CMake configure..."
cmake -B "$BUILD_DIR" -S "$LLAMA_DIR" \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    "${CMAKE_FLAGS[@]}"

# Build
echo "[INFO] Building llama.cpp..."
cmake --build "$BUILD_DIR" --config $BUILD_TYPE -j "$JOBS"

# Verify build
BUILD_SUCCESS=false
LIB_LOCATION=""

# Check for static library
if [ -f "$BUILD_DIR/libllama.a" ] || [ -f "$BUILD_DIR/src/libllama.a" ]; then
    BUILD_SUCCESS=true
    LIB_LOCATION="$BUILD_DIR"
fi

# Check for dynamic library (when GGML_BACKEND_DL=ON)
if [ -f "$BUILD_DIR/bin/libllama.so" ] || [ -f "$BUILD_DIR/bin/libllama.dylib" ]; then
    BUILD_SUCCESS=true
    LIB_LOCATION="$BUILD_DIR/bin"
fi
if [ -f "$BUILD_DIR/libllama.so" ] || [ -f "$BUILD_DIR/libllama.dylib" ]; then
    BUILD_SUCCESS=true
    LIB_LOCATION="$BUILD_DIR"
fi

if [ "$BUILD_SUCCESS" = true ]; then
    echo ""
    echo "[SUCCESS] llama.cpp built successfully!"
    echo "Library location: $LIB_LOCATION"

    # List generated backend libraries if dynamic loading is enabled
    if [ "$DYNAMIC_BACKENDS" = true ]; then
        echo ""
        echo "Backend libraries generated:"
        for lib in "$LIB_LOCATION"/libggml-*.so "$LIB_LOCATION"/libggml-*.dylib 2>/dev/null; do
            if [ -f "$lib" ]; then
                echo "  - $(basename "$lib")"
            fi
        done
    fi
else
    echo ""
    echo "[ERROR] Build completed but library not found."
    echo "Check the build output for errors."
    exit 1
fi
