#!/bin/bash

# --- Configuration ---
LLAMA_DIR="/home/tiry/llama.cpp"
ROCM_BUILD_DIR="build-rocm"
VULKAN_BUILD_DIR="build-vulkan"
CUDA_BUILD_DIR="build-cuda"

# --- Defaults ---
FORCE_REBUILD=false
CLEAN_REBUILD=false
TARGET_ARCH="all"

# --- Functions ---

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS] [ARCHITECTURE]"
    echo ""
    echo "Architectures:"
    echo "  all (default), cuda, rocm, vulkan"
    echo ""
    echo "Options:"
    echo "  -f    Force rebuild even if Git is up to date"
    echo "  -c    Clean build (removes build directories first)"
    echo "  -h    Display this help message"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") -f -c cuda"
    exit 0
}

should_build() {
    [[ "$TARGET_ARCH" == "all" || "$TARGET_ARCH" == "$1" ]]
}

run_build() {
    local dir=$1
    local cmake_args=$2
    
    if [ "$CLEAN_REBUILD" = true ]; then
        echo "--- Cleaning $dir... ---"
        rm -rf "$dir"
    fi

    echo "--- Building in '$dir'... ---"
    cmake -S . -B "$dir" $cmake_args -DCMAKE_BUILD_TYPE=Release
    cmake --build "$dir" --config Release -- -j $(nproc)
}

# --- Parse Flags ---

while getopts "fch" opt; do
    case "$opt" in
        f) FORCE_REBUILD=true ;;
        c) CLEAN_REBUILD=true ;;
        h) show_help ;;
        *) show_help ;;
    esac
done

# Shift off the options to get the positional architecture argument
shift $((OPTIND-1))
TARGET_ARCH=${1:-all}
TARGET_ARCH=$(echo "$TARGET_ARCH" | tr '[:upper:]' '[:lower:]')

# --- Logic ---

set -e
cd "$LLAMA_DIR"

# Git Management
echo "=== Checking Git Status ==="
git checkout main 2>/dev/null || git checkout master
PULL_OUTPUT=$(git pull)

# Determine if we proceed
if [[ "$PULL_OUTPUT" == *"Already up to date."* ]] && [ "$FORCE_REBUILD" = false ]; then
    echo "Llama.cpp is already up to date. Use -f to force rebuild."
    exit 0
fi

# --- Execution ---

# CUDA
if should_build "cuda"; then
    run_build "$CUDA_BUILD_DIR" "-DGGML_CUDA=ON"
    
    # Quick Test
    if [ -f "$CUDA_BUILD_DIR/bin/llama-cli" ] && [ -f "./models/ggml-model-q4_0.bin" ]; then
        echo "--- Running CUDA test... ---"
        "$CUDA_BUILD_DIR/bin/llama-cli" -m ./models/ggml-model-q4_0.bin -n 10 --n-gpu-layers 999 -p "Hello" --silent-prompt
    fi
fi

# ROCm
if should_build "rocm"; then
    # Passing environment variables inline for ROCm
    HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    run_build "$ROCM_BUILD_DIR" "-DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1151"
fi

# Vulkan
if should_build "vulkan"; then
    run_build "$VULKAN_BUILD_DIR" "-DGGML_VULKAN=ON"
fi

echo "=== Build process finished for: $TARGET_ARCH ==="