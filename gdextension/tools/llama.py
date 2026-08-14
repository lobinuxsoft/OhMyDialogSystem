"""
SCons tool for llama.cpp integration
Handles detection, building, and linking of llama.cpp library
"""

import os
import subprocess
import sys
from SCons.Script import *


def options(opts):
    """Add llama.cpp build options to SCons."""
    opts.Add(
        EnumVariable(
            key="llama_backend",
            help="llama.cpp compute backend (vulkan recommended for GPU)",
            default="vulkan",
            allowed_values=("cpu", "vulkan", "metal", "sycl"),
        )
    )
    opts.Add(
        BoolVariable(
            key="llama_native",
            help="Enable native CPU optimizations for llama.cpp (not portable)",
            default=False,
        )
    )
    opts.Add(
        BoolVariable(
            key="llama_avx2",
            help="Enable AVX2 for llama.cpp (x86_64 only)",
            default=True,
        )
    )
    opts.Add(
        BoolVariable(
            key="llama_rebuild",
            help="Force rebuild of llama.cpp",
            default=False,
        )
    )
    opts.Add(
        BoolVariable(
            key="llama_all_backends",
            help="Build all available backends (CPU, CUDA, Vulkan)",
            default=False,
        )
    )
    opts.Add(
        BoolVariable(
            key="llama_dynamic",
            help="Enable dynamic backend loading (runtime detection)",
            default=False,
        )
    )


def exists(env):
    """Check if llama.cpp source exists."""
    llama_dir = _get_llama_dir(env)
    return os.path.isdir(llama_dir)


def generate(env):
    """Configure environment for llama.cpp."""
    llama_dir = _get_llama_dir(env)
    build_dir = os.path.join(llama_dir, "build")

    if not os.path.isdir(llama_dir):
        print("[llama.py] ERROR: llama.cpp not found at:", llama_dir)
        print("           Run: git submodule update --init --recursive")
        Exit(1)

    # Check if we need to build llama.cpp
    lib_built = _check_library_exists(build_dir, env)

    if not lib_built or env.get("llama_rebuild", False):
        _build_llama(env, llama_dir, build_dir)

    # Configure include paths
    env.Append(
        CPPPATH=[
            os.path.join(llama_dir, "include"),
            os.path.join(llama_dir, "ggml", "include"),
            os.path.join(llama_dir, "common"),
        ]
    )

    # Configure library paths and libraries
    _configure_linking(env, build_dir)

    # Note: Do NOT define LLAMA_SHARED - we want static linking
    # The headers use #ifdef LLAMA_SHARED, not #if LLAMA_SHARED
    # So leaving it undefined gives us the static LLAMA_API (empty macro)

    backend = env.get("llama_backend", "cpu")
    if backend == "cuda":
        env.Append(CPPDEFINES=["GGML_USE_CUDA"])
    elif backend == "vulkan":
        env.Append(CPPDEFINES=["GGML_USE_VULKAN"])
    elif backend == "metal":
        env.Append(CPPDEFINES=["GGML_USE_METAL"])
    elif backend == "sycl":
        env.Append(CPPDEFINES=["GGML_USE_SYCL"])


def _get_llama_dir(env):
    """Get the llama.cpp directory path."""
    # Relative to the gdextension directory
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(script_dir, "thirdparty", "llama.cpp")


def _check_library_exists(build_dir, env):
    """Check if llama.cpp library has been built."""
    platform = env.get("platform", sys.platform)

    if platform == "windows":
        # Check for Windows library
        # Ninja puts files directly in build/src, VS generator uses build/Release etc.
        lib_paths = [
            os.path.join(build_dir, "src", "llama.lib"),  # Ninja generator
            os.path.join(build_dir, "Release", "llama.lib"),
            os.path.join(build_dir, "Debug", "llama.lib"),
            os.path.join(build_dir, "bin", "Release", "llama.lib"),
            os.path.join(build_dir, "src", "Release", "llama.lib"),
        ]
    else:
        # Check for Unix library
        lib_paths = [
            os.path.join(build_dir, "libllama.a"),
            os.path.join(build_dir, "src", "libllama.a"),
            os.path.join(build_dir, "lib", "libllama.a"),
        ]

    for path in lib_paths:
        if os.path.isfile(path):
            return True
    return False


def _build_llama(env, llama_dir, build_dir):
    """Build llama.cpp using the appropriate script."""
    print("[llama.py] Building llama.cpp...")

    platform = env.get("platform", sys.platform)
    backend = env.get("llama_backend", "vulkan")  # Default to Vulkan for GPU acceleration
    native = env.get("llama_native", False)  # Default to portable builds
    avx2 = env.get("llama_avx2", True)
    all_backends = env.get("llama_all_backends", False)
    dynamic = env.get("llama_dynamic", False)

    # Determine script to run
    script_dir = os.path.join(os.path.dirname(llama_dir), "..", "scripts")

    if platform == "windows":
        script = os.path.join(script_dir, "build_llama.bat")
    else:
        script = os.path.join(script_dir, "build_llama.sh")

    if not os.path.isfile(script):
        print(f"[llama.py] ERROR: Build script not found: {script}")
        Exit(1)

    # Build command arguments
    args = [script]

    # Backend selection
    if all_backends:
        args.append("--all-backends")
    else:
        args.append(f"--{backend}")

    # Dynamic backend loading
    if dynamic:
        args.append("--dynamic")

    if native:
        args.append("--native")
    else:
        args.append("--no-native")

    if avx2:
        args.append("--avx2")
    else:
        args.append("--no-avx2")

    # Only add --rebuild if explicitly requested via llama_rebuild=yes
    # The function _build_llama is only called when library doesn't exist
    # or when llama_rebuild=yes was passed

    # Run build script
    print(f"[llama.py] Running: {' '.join(args)}")

    try:
        result = subprocess.run(
            args,
            cwd=os.path.dirname(script),
            check=True,
            capture_output=False,
        )
    except subprocess.CalledProcessError as e:
        print(f"[llama.py] ERROR: llama.cpp build failed with code {e.returncode}")
        Exit(1)
    except FileNotFoundError:
        print(f"[llama.py] ERROR: Could not execute build script: {script}")
        Exit(1)

    print("[llama.py] llama.cpp built successfully!")


def _configure_linking(env, build_dir):
    """Configure library linking for llama.cpp."""
    platform = env.get("platform", sys.platform)
    backend = env.get("llama_backend", "cpu")
    dynamic = env.get("llama_dynamic", False)
    all_backends = env.get("llama_all_backends", False)

    # Add all library directories
    lib_dirs = _find_all_library_dirs(build_dir, platform)
    print(f"[llama.py] Library directories found: {lib_dirs}")
    for lib_dir in lib_dirs:
        env.Append(LIBPATH=[lib_dir])

    # When using dynamic backend loading (GGML_BACKEND_DL), backends are loaded
    # at runtime via ggml_backend_load_all(), so we only link core libraries
    if dynamic:
        print("[llama.py] Dynamic backend loading enabled - linking core libs only")
        # ggml contains backend registry functions (ggml_backend_load_all, etc.)
        # ggml-base contains base tensor operations
        core_libs = ["llama", "common", "ggml", "ggml-base"]
        env.Append(LIBS=core_libs)
    else:
        # Static linking: Core libraries (order matters for static linking)
        core_libs = ["llama", "common", "ggml", "ggml-cpu", "ggml-base"]
        env.Append(LIBS=core_libs)

        # All backends mode: link all available backend libraries
        if all_backends:
            print("[llama.py] All backends mode - linking all available backends")
            # Vulkan backend (Linux/Windows)
            if platform != "macos":
                env.Append(LIBS=["ggml-vulkan"])
                if platform == "windows":
                    env.Append(LIBS=["vulkan-1"])
                    vulkan_sdk = os.environ.get("VULKAN_SDK", "")
                    if vulkan_sdk:
                        env.Append(LIBPATH=[os.path.join(vulkan_sdk, "Lib")])
                else:
                    env.Append(LIBS=["vulkan"])
            # Metal backend (macOS)
            if platform == "macos":
                env.Append(LIBS=["ggml-metal"])
                env.Append(FRAMEWORKS=["Metal", "Foundation", "MetalPerformanceShaders"])
        else:
            # Single backend mode
            if backend == "cuda":
                if platform == "windows":
                    env.Append(LIBS=["ggml-cuda", "cudart", "cublas", "cublasLt"])
                else:
                    env.Append(LIBS=["ggml-cuda", "cudart", "cublas", "cublasLt"])

            elif backend == "vulkan":
                env.Append(LIBS=["ggml-vulkan"])
                if platform == "windows":
                    env.Append(LIBS=["vulkan-1"])
                    # Add Vulkan SDK library path
                    vulkan_sdk = os.environ.get("VULKAN_SDK", "")
                    if vulkan_sdk:
                        env.Append(LIBPATH=[os.path.join(vulkan_sdk, "Lib")])
                else:
                    env.Append(LIBS=["vulkan"])

            elif backend == "metal":
                env.Append(LIBS=["ggml-metal"])
                env.Append(FRAMEWORKS=["Metal", "Foundation", "MetalPerformanceShaders"])

            elif backend == "sycl":
                env.Append(LIBS=["ggml-sycl", "sycl"])

    # Platform-specific system libraries (always needed)
    if platform == "linux":
        env.Append(LIBS=["pthread", "dl", "m", "gomp"])
        env.Append(CCFLAGS=["-fopenmp"])
        env.Append(LINKFLAGS=["-fopenmp"])
    elif platform == "macos":
        env.Append(LIBS=["pthread"])
        env.Append(FRAMEWORKS=["Accelerate"])
    elif platform == "windows":
        # advapi32: Windows Registry API (used by ggml-cpu for CPU detection)
        env.Append(LIBS=["advapi32"])


def _find_all_library_dirs(build_dir, platform):
    """Find all directories containing llama.cpp libraries."""
    lib_dirs = set()

    if platform == "windows":
        # Windows library locations
        candidates = {
            "llama.lib": [
                os.path.join(build_dir, "Release"),
                os.path.join(build_dir, "Debug"),
                os.path.join(build_dir, "src", "Release"),
                os.path.join(build_dir, "src"),
            ],
            "ggml.lib": [
                os.path.join(build_dir, "ggml", "src", "Release"),
                os.path.join(build_dir, "ggml", "src"),
            ],
            "ggml-base.lib": [
                os.path.join(build_dir, "bin", "Release"),
                os.path.join(build_dir, "bin"),
                os.path.join(build_dir, "ggml", "src", "Release"),
            ],
            "common.lib": [
                os.path.join(build_dir, "common", "Release"),
                os.path.join(build_dir, "common"),
            ],
            # Backend-specific libraries
            "ggml-vulkan.lib": [
                os.path.join(build_dir, "ggml", "src", "ggml-vulkan"),
                os.path.join(build_dir, "ggml", "src", "ggml-vulkan", "Release"),
            ],
            "ggml-cuda.lib": [
                os.path.join(build_dir, "ggml", "src", "ggml-cuda"),
                os.path.join(build_dir, "ggml", "src", "ggml-cuda", "Release"),
            ],
        }
    else:
        # Unix library locations
        candidates = {
            "libllama.a": [
                os.path.join(build_dir, "src"),
                build_dir,
            ],
            "libggml.a": [
                os.path.join(build_dir, "ggml", "src"),
                os.path.join(build_dir, "ggml"),
            ],
            "libggml-base.a": [
                os.path.join(build_dir, "bin"),
                os.path.join(build_dir, "ggml", "src"),
            ],
            "libcommon.a": [
                os.path.join(build_dir, "common"),
            ],
            # Backend-specific libraries
            "libggml-vulkan.a": [
                os.path.join(build_dir, "ggml", "src", "ggml-vulkan"),
            ],
            "libggml-cuda.a": [
                os.path.join(build_dir, "ggml", "src", "ggml-cuda"),
            ],
        }

    for lib_name, paths in candidates.items():
        for path in paths:
            if os.path.isfile(os.path.join(path, lib_name)):
                lib_dirs.add(path)
                break

    return list(lib_dirs)
