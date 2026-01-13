#!/bin/bash

# Build script for OhMyDialogSystem GDExtension (Linux/macOS)
# Requires: clang/gcc, Python 3, SCons, CMake

set -e

echo "========================================"
echo " OhMyDialogSystem GDExtension Builder"
echo "========================================"

cd "$(dirname "$0")"

# Check if scons is available
if ! command -v scons &> /dev/null; then
    echo "[ERROR] SCons not found. Install with: pip install scons"
    exit 1
fi

# Check if cmake is available (needed for llama.cpp)
if ! command -v cmake &> /dev/null; then
    echo "[ERROR] CMake not found. Please install CMake."
    exit 1
fi

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    PLATFORM="linux"
fi

# Default values
TARGET="template_debug"
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# llama.cpp options
LLAMA_BACKEND="cpu"
LLAMA_NATIVE="yes"
LLAMA_AVX2="yes"
LLAMA_REBUILD="no"
LLAMA_ALL_BACKENDS="no"
LLAMA_DYNAMIC="no"

print_usage() {
    echo ""
    echo "Usage: $0 [TARGET] [OPTIONS]"
    echo ""
    echo "Targets:"
    echo "  debug         Build debug version (default)"
    echo "  release       Build release version"
    echo "  editor        Build editor version"
    echo ""
    echo "Options:"
    echo "  -j N          Number of parallel jobs (default: auto)"
    echo ""
    echo "llama.cpp Backend Options:"
    echo "  --cpu         Use CPU backend (default)"
    echo "  --cuda        Use CUDA backend (requires CUDA Toolkit)"
    echo "  --vulkan      Use Vulkan backend (requires Vulkan SDK)"
    echo "  --metal       Use Metal backend (macOS only)"
    echo "  --sycl        Use SYCL backend (requires Intel oneAPI)"
    echo "  --all-backends  Build ALL available backends"
    echo "  --dynamic     Enable dynamic backend loading (runtime detection)"
    echo ""
    echo "llama.cpp Build Options:"
    echo "  --no-native   Disable native CPU optimizations"
    echo "  --no-avx2     Disable AVX2 instructions"
    echo "  --rebuild-llama  Force rebuild of llama.cpp"
    echo ""
    echo "Examples:"
    echo "  $0 release                         # Release build, CPU backend"
    echo "  $0 debug --cuda -j 8               # Debug build, CUDA backend"
    echo "  $0 release --all-backends --dynamic  # All backends, runtime detection"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        debug)
            TARGET="template_debug"
            shift
            ;;
        release)
            TARGET="template_release"
            shift
            ;;
        editor)
            TARGET="editor"
            shift
            ;;
        -j)
            JOBS="$2"
            shift 2
            ;;
        --cpu)
            LLAMA_BACKEND="cpu"
            shift
            ;;
        --cuda)
            LLAMA_BACKEND="cuda"
            shift
            ;;
        --vulkan)
            LLAMA_BACKEND="vulkan"
            shift
            ;;
        --metal)
            LLAMA_BACKEND="metal"
            shift
            ;;
        --sycl)
            LLAMA_BACKEND="sycl"
            shift
            ;;
        --all-backends)
            LLAMA_ALL_BACKENDS="yes"
            shift
            ;;
        --dynamic)
            LLAMA_DYNAMIC="yes"
            shift
            ;;
        --no-native)
            LLAMA_NATIVE="no"
            shift
            ;;
        --no-avx2)
            LLAMA_AVX2="no"
            shift
            ;;
        --rebuild-llama)
            LLAMA_REBUILD="yes"
            shift
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

echo ""
echo "Platform:        $PLATFORM"
echo "Target:          $TARGET"
echo "Jobs:            $JOBS"
echo "llama backend:   $LLAMA_BACKEND"
echo "llama all:       $LLAMA_ALL_BACKENDS"
echo "llama dynamic:   $LLAMA_DYNAMIC"
echo "llama native:    $LLAMA_NATIVE"
echo "llama AVX2:      $LLAMA_AVX2"
echo ""

# Build llama.cpp first if needed
LLAMA_BUILD_DIR="thirdparty/llama.cpp/build"
if [ ! -d "$LLAMA_BUILD_DIR" ] || [ "$LLAMA_REBUILD" = "yes" ]; then
    echo "[INFO] Building llama.cpp..."
    LLAMA_ARGS=""
    if [ "$LLAMA_ALL_BACKENDS" = "yes" ]; then
        LLAMA_ARGS="$LLAMA_ARGS --all-backends"
    else
        LLAMA_ARGS="$LLAMA_ARGS --$LLAMA_BACKEND"
    fi
    [ "$LLAMA_DYNAMIC" = "yes" ] && LLAMA_ARGS="$LLAMA_ARGS --dynamic"
    [ "$LLAMA_NATIVE" = "no" ] && LLAMA_ARGS="$LLAMA_ARGS --no-native"
    [ "$LLAMA_AVX2" = "no" ] && LLAMA_ARGS="$LLAMA_ARGS --no-avx2"
    [ "$LLAMA_REBUILD" = "yes" ] && LLAMA_ARGS="$LLAMA_ARGS --rebuild"
    ./scripts/build_llama.sh $LLAMA_ARGS -j "$JOBS"
fi

echo "[INFO] Building GDExtension..."
SCONS_ARGS="platform=$PLATFORM target=$TARGET"
SCONS_ARGS="$SCONS_ARGS llama_backend=$LLAMA_BACKEND"
SCONS_ARGS="$SCONS_ARGS llama_native=$LLAMA_NATIVE"
SCONS_ARGS="$SCONS_ARGS llama_avx2=$LLAMA_AVX2"
SCONS_ARGS="$SCONS_ARGS llama_rebuild=$LLAMA_REBUILD"
[ "$LLAMA_ALL_BACKENDS" = "yes" ] && SCONS_ARGS="$SCONS_ARGS llama_all_backends=yes"
[ "$LLAMA_DYNAMIC" = "yes" ] && SCONS_ARGS="$SCONS_ARGS llama_dynamic=yes"
scons $SCONS_ARGS -j"$JOBS"

# Copy dynamic backend libraries if using dynamic loading
if [ "$LLAMA_DYNAMIC" = "yes" ]; then
    echo ""
    echo "[INFO] Copying dynamic backend libraries..."
    LLAMA_BIN_DIR="thirdparty/llama.cpp/build/bin"
    ADDON_DIR="../addons/ohmydialog/gdextension"

    if [ "$PLATFORM" = "macos" ]; then
        LIB_EXT="dylib"
    else
        LIB_EXT="so"
    fi

    if [ -d "$LLAMA_BIN_DIR" ]; then
        # Find and copy all backend libraries
        find "$LLAMA_BIN_DIR" -name "*.${LIB_EXT}" -exec cp -v {} "$ADDON_DIR/" \; 2>/dev/null || true
        echo "[INFO] Backend libraries copied to addon directory"
    else
        echo "[WARNING] Backend libraries not found in $LLAMA_BIN_DIR"
    fi
fi

echo ""
echo "[SUCCESS] Build completed!"
echo "Output: addons/ohmydialog/gdextension/"
