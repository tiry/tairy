#!/bin/bash

# --- Configuration ---
# Set the paths to your llama.cpp directory and build folders
LLAMA_DIR="/home/tiry/llama.cpp"
ROCM_BUILD_DIR="build"
VULKAN_BUILD_DIR="build-vulkan"

# --- Script Logic ---

# Exit immediately if any command fails
set -e

# 1. Navigate to the llama.cpp directory
echo "=== Navigating to $LLAMA_DIR ==="
cd "$LLAMA_DIR"

# 2. Check out the main branch (or 'master', if 'main' fails)
echo "=== Checking out main branch... ==="
git checkout main || git checkout master

# 3. Pull updates from Git
echo "=== Pulling latest updates from Git... ==="
PULL_OUTPUT=$(git pull)

# 4. Check if a rebuild is needed
if echo "$PULL_OUTPUT" | grep -q "Already up to date."; then
    echo "Llama.cpp is already up to date. No rebuild necessary."
    exit 0
else
    echo "=== Updates found. Starting rebuild... ==="
    
    # --- Rebuild 1: ROCm (High-Performance) ---
    echo "--- Rebuilding ROCm version in '$ROCM_BUILD_DIR'... ---"
    
    # This command is run from the root directory
    HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B "$ROCM_BUILD_DIR" -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1151 -DCMAKE_BUILD_TYPE=Release
    
    cmake --build "$ROCM_BUILD_DIR" --config Release -- -j 16
    
    echo "--- ROCm build complete. ---"
    
    
    # --- Rebuild 2: Vulkan (Compatibility) ---
    echo "--- Rebuilding Vulkan version in '$VULKAN_BUILD_DIR'... ---"
    
    # This build process runs from *inside* the build directory
    # We create it if it doesn't exist, and cd into it
    mkdir -p "$VULKAN_BUILD_DIR"
    cd "$VULKAN_BUILD_DIR"
    
    cmake .. -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
    
    cmake --build . --config Release -- -j 16
    
    cd .. # Go back to the root llama.cpp directory
    echo "--- Vulkan build complete. ---"
    
    echo "=== All builds are up to date! ==="
fi
