#!/bin/bash

# Build script for llama.cpp static library
# Supports multiple backends: CPU, CUDA, Vulkan, Metal, SYCL

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LLAMA_DIR="$SCRIPT_DIR/../thirdparty/llama.cpp"
BUILD_DIR="$LLAMA_DIR/build"

# Default configuration
BUILD_TYPE="Release"
BACKEND="cpu"
FORCE_REBUILD=false
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

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
    echo "Options:"
    echo "  --cpu          Build with CPU backend only (default)"
    echo "  --cuda         Build with CUDA support (requires CUDA Toolkit)"
    echo "  --vulkan       Build with Vulkan support (requires Vulkan SDK)"
    echo "  --metal        Build with Metal support (macOS only)"
    echo "  --sycl         Build with SYCL support (requires Intel oneAPI)"
    echo "  --native       Enable native CPU optimizations (default: on)"
    echo "  --no-native    Disable native CPU optimizations"
    echo "  --avx2         Enable AVX2 (default: on)"
    echo "  --no-avx2      Disable AVX2"
    echo "  --debug        Build debug version"
    echo "  --clean        Clean build directory before building"
    echo "  --rebuild      Force rebuild even if already built"
    echo "  -j N           Number of parallel jobs (default: auto)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --cpu                    # CPU-only build"
    echo "  $0 --cuda -j 8              # CUDA build with 8 jobs"
    echo "  $0 --vulkan --no-native     # Vulkan without native opts"
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
echo "Backend:    $BACKEND"
echo "Build Type: $BUILD_TYPE"
echo "Native:     $NATIVE"
echo "AVX2:       $AVX2"
echo "Jobs:       $JOBS"
echo ""

# Add CPU optimization flags
CMAKE_FLAGS+=(-DGGML_NATIVE=$NATIVE)
CMAKE_FLAGS+=(-DGGML_AVX2=$AVX2)

# Configure backend-specific flags
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
        # Auto-detect CUDA architectures or use common ones
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
if [ -f "$BUILD_DIR/libllama.a" ] || [ -f "$BUILD_DIR/src/libllama.a" ]; then
    echo ""
    echo "[SUCCESS] llama.cpp built successfully!"
    echo "Library location: $BUILD_DIR"
else
    echo ""
    echo "[ERROR] Build completed but library not found."
    echo "Check the build output for errors."
    exit 1
fi
