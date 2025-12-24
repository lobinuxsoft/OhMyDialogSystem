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
    echo ""
    echo "llama.cpp Build Options:"
    echo "  --no-native   Disable native CPU optimizations"
    echo "  --no-avx2     Disable AVX2 instructions"
    echo "  --rebuild-llama  Force rebuild of llama.cpp"
    echo ""
    echo "Examples:"
    echo "  $0 release                    # Release build, CPU backend"
    echo "  $0 debug --cuda -j 8          # Debug build, CUDA backend"
    echo "  $0 release --vulkan           # Release build, Vulkan backend"
    echo "  $0 editor --rebuild-llama     # Editor build, force llama.cpp rebuild"
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
echo "Platform:       $PLATFORM"
echo "Target:         $TARGET"
echo "Jobs:           $JOBS"
echo "llama backend:  $LLAMA_BACKEND"
echo "llama native:   $LLAMA_NATIVE"
echo "llama AVX2:     $LLAMA_AVX2"
echo ""

# Build llama.cpp first if needed
LLAMA_BUILD_DIR="thirdparty/llama.cpp/build"
if [ ! -d "$LLAMA_BUILD_DIR" ] || [ "$LLAMA_REBUILD" = "yes" ]; then
    echo "[INFO] Building llama.cpp..."
    LLAMA_ARGS="--$LLAMA_BACKEND"
    [ "$LLAMA_NATIVE" = "no" ] && LLAMA_ARGS="$LLAMA_ARGS --no-native"
    [ "$LLAMA_AVX2" = "no" ] && LLAMA_ARGS="$LLAMA_ARGS --no-avx2"
    [ "$LLAMA_REBUILD" = "yes" ] && LLAMA_ARGS="$LLAMA_ARGS --rebuild"
    ./scripts/build_llama.sh $LLAMA_ARGS -j "$JOBS"
fi

echo "[INFO] Building GDExtension..."
scons platform="$PLATFORM" target="$TARGET" \
    llama_backend="$LLAMA_BACKEND" \
    llama_native="$LLAMA_NATIVE" \
    llama_avx2="$LLAMA_AVX2" \
    llama_rebuild="$LLAMA_REBUILD" \
    -j"$JOBS"

echo ""
echo "[SUCCESS] Build completed!"
echo "Output: addons/ohmydialog/gdextension/"
