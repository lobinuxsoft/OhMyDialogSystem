#!/bin/bash

# Build all configurations for OhMyDialogSystem GDExtension (Linux/macOS)
# Builds: editor, template_release, template_debug

set -e

echo "========================================"
echo " OhMyDialogSystem - Build All Targets"
echo "========================================"
echo ""

cd "$(dirname "$0")"

# Default options
LLAMA_ARGS=""
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
FAILED=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -j)
            JOBS="$2"
            shift 2
            ;;
        --cpu)
            LLAMA_ARGS="$LLAMA_ARGS --cpu"
            shift
            ;;
        --vulkan)
            LLAMA_ARGS="$LLAMA_ARGS --vulkan"
            shift
            ;;
        --native)
            LLAMA_ARGS="$LLAMA_ARGS --native"
            shift
            ;;
        --all-backends)
            LLAMA_ARGS="$LLAMA_ARGS --all-backends"
            shift
            ;;
        --dynamic)
            LLAMA_ARGS="$LLAMA_ARGS --dynamic"
            shift
            ;;
        --rebuild-llama)
            LLAMA_ARGS="$LLAMA_ARGS --rebuild-llama"
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Builds all three targets: editor, release, and debug"
            echo ""
            echo "Options:"
            echo "  -j N              Number of parallel jobs (default: auto)"
            echo "  --cpu             Use CPU backend instead of Vulkan"
            echo "  --vulkan          Use Vulkan backend (default)"
            echo "  --native          Enable native CPU optimizations"
            echo "  --all-backends    Build ALL available backends (CPU, Vulkan)"
            echo "  --dynamic         Enable dynamic backend loading (runtime detection)"
            echo "  --rebuild-llama   Force rebuild of llama.cpp"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $(basename "$0")                              # Build all with Vulkan (default)"
            echo "  $(basename "$0") --cpu -j 8                   # Build all with CPU backend, 8 jobs"
            echo "  $(basename "$0") --all-backends --dynamic     # All backends with runtime detection"
            echo "  $(basename "$0") --rebuild-llama              # Rebuild llama.cpp and all targets"
            exit 0
            ;;
        *)
            echo "[WARNING] Unknown option: $1"
            shift
            ;;
    esac
done

echo "Building with $JOBS parallel jobs"
echo "llama.cpp args:$LLAMA_ARGS"
echo ""

# Detect platform for output messages
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    EXT="dylib"
else
    PLATFORM="linux"
    EXT="so"
fi

# ========================================
# Build Editor
# ========================================
echo "[1/3] Building EDITOR..."
echo "----------------------------------------"
set +e
./build.sh editor $LLAMA_ARGS -j "$JOBS"
if [[ $? -ne 0 ]]; then
    echo "[FAILED] Editor build failed!"
    FAILED=1
else
    echo "[OK] Editor build completed"
fi
set -e
echo ""

# ========================================
# Build Release
# ========================================
echo "[2/3] Building RELEASE..."
echo "----------------------------------------"
set +e
./build.sh release $LLAMA_ARGS -j "$JOBS"
if [[ $? -ne 0 ]]; then
    echo "[FAILED] Release build failed!"
    FAILED=1
else
    echo "[OK] Release build completed"
fi
set -e
echo ""

# ========================================
# Build Debug
# ========================================
echo "[3/3] Building DEBUG..."
echo "----------------------------------------"
set +e
./build.sh debug $LLAMA_ARGS -j "$JOBS"
if [[ $? -ne 0 ]]; then
    echo "[FAILED] Debug build failed!"
    FAILED=1
else
    echo "[OK] Debug build completed"
fi
set -e
echo ""

# ========================================
# Summary
# ========================================
echo "========================================"
echo " Build Summary"
echo "========================================"
if [[ $FAILED -eq 0 ]]; then
    echo "[SUCCESS] All builds completed successfully!"
    echo ""
    echo "Output files:"
    echo "  - libohmydialog.${PLATFORM}.editor.x86_64.${EXT}"
    echo "  - libohmydialog.${PLATFORM}.template_release.x86_64.${EXT}"
    echo "  - libohmydialog.${PLATFORM}.template_debug.x86_64.${EXT}"
    echo ""
    echo "Location: addons/ohmydialog/gdextension/"
else
    echo "[ERROR] Some builds failed! Check the output above."
    exit 1
fi
