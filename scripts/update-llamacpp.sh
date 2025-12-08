#!/bin/bash

# --- Configuration ---
# Set the paths to your llama.cpp directory and build folders
LLAMA_DIR="/home/tiry/llama.cpp"
ROCM_BUILD_DIR="build-rocm" # Renamed for clarity
VULKAN_BUILD_DIR="build-vulkan"
CUDA_BUILD_DIR="build-cuda" # New build folder for CUDA

# --- Script Logic ---

# Check for a specific architecture argument
# Default to 'all' if no argument is provided
TARGET_ARCH=${1:-all}
# Convert argument to lowercase for easier checking
TARGET_ARCH=$(echo "$TARGET_ARCH" | tr '[:upper:]' '[:lower:]')

# Function to check if a specific architecture is requested
should_build() {
    [[ "$TARGET_ARCH" == "all" || "$TARGET_ARCH" == "$1" ]]
}

# Exit immediately if any command fails
set -e

# 1. Navigate to the llama.cpp directory
echo "=== Navigating to $LLAMA_DIR ==="
cd "$LLAMA_DIR"

# 2. Check out the main branch
echo "=== Checking out main branch... ==="
# Attempt to checkout 'main', fall back to 'master'
git checkout main 2>/dev/null || git checkout master

# 3. Pull updates from Git
echo "=== Pulling latest updates from Git... ==="
PULL_OUTPUT=$(git pull)

# 4. Check if a rebuild is needed (Only skip if targeting 'all' and already up to date)
if [[ "$TARGET_ARCH" == "all" ]] && echo "$PULL_OUTPUT" | grep -q "Already up to date."; then
    echo "Llama.cpp is already up to date. No rebuild necessary."
    exit 0
else
    if [[ "$TARGET_ARCH" != "all" ]]; then
        echo "=== Building ONLY the '$TARGET_ARCH' architecture... ==="
    else
        echo "=== Updates found or building all architectures. Starting rebuild... ==="
    fi

    # --- Rebuild 1: CUDA (NVIDIA) ---
    if should_build "cuda"; then
        echo "--- Rebuilding CUDA version in '$CUDA_BUILD_DIR'... ---"

        # Note: CUDA version often requires an older build method or just 'make'
        # but using 'cmake' with DGGML_CUDA=ON is the standard approach now.
        # We use CMAKE_BUILD_TYPE=Release for optimization.
        cmake -S . -B "$CUDA_BUILD_DIR" -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
        cmake --build "$CUDA_BUILD_DIR" --config Release -- -j 16

        echo "--- CUDA build complete. ---"

        # 5. Simple Test Run for CUDA (Ensure you have a model like 'ggml-model-q4_0.bin' for this to work)
        if [ -f "$CUDA_BUILD_DIR/bin/main" ] && [ -f "./models/ggml-model-q4_0.bin" ]; then
            echo "--- Running a quick test with CUDA version... ---"
            # This is a very minimal inference command
            "$CUDA_BUILD_DIR/bin/main" -m ./models/ggml-model-q4_0.bin -n 10 --n-gpu-layers 999 -p "Hello" --silent-prompt
            echo "--- CUDA test run finished. ---"
        elif [ -f "$CUDA_BUILD_DIR/bin/main" ]; then
            echo "--- CUDA build successful. Skipping test run: Model not found at ./models/ggml-model-q4_0.bin ---"
        fi
    fi

    # --- Rebuild 2: ROCm (AMD High-Performance) ---
    if should_build "rocm"; then
        echo "--- Rebuilding ROCm version in '$ROCM_BUILD_DIR'... ---"

        # Existing ROCm build logic
        HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
        cmake -S . -B "$ROCM_BUILD_DIR" -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1151 -DCMAKE_BUILD_TYPE=Release
        cmake --build "$ROCM_BUILD_DIR" --config Release -- -j 16

        echo "--- ROCm build complete. ---"
    fi

    # --- Rebuild 3: Vulkan (Compatibility) ---
    if should_build "vulkan"; then
        echo "--- Rebuilding Vulkan version in '$VULKAN_BUILD_DIR'... ---"

        # The Vulkan build logic needs to be simplified to run from the root, like the others
        cmake -S . -B "$VULKAN_BUILD_DIR" -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
        cmake --build "$VULKAN_BUILD_DIR" --config Release -- -j 16

        echo "--- Vulkan build complete. ---"
    fi

    echo "=== Build process finished for target architecture(s): $TARGET_ARCH ==="
fi