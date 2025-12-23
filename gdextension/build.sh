#!/bin/bash

# Build script for OhMyDialogSystem GDExtension (Linux/macOS)
# Requires: clang/gcc, Python 3, SCons

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

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    PLATFORM="linux"
fi

# Default values
TARGET="template_debug"
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

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
        *)
            shift
            ;;
    esac
done

echo ""
echo "Building for $PLATFORM [$TARGET] with $JOBS jobs..."
echo ""

scons platform="$PLATFORM" target="$TARGET" -j"$JOBS"

echo ""
echo "[SUCCESS] Build completed!"
echo "Output: addons/ohmydialog/gdextension/"
