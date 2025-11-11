
# Llama.cpp Installation Guide: Arch Linux & AMD Strix Halo (gfx1151)

This guide summarizes the operations needed to install and compile `llama.cpp` on a minimal Arch Linux system with an AMD AI 395+ (Strix Halo) APU.

It includes steps for compiling two separate backends:

1.  **ROCm:** For high-performance, native GPU acceleration.
2.  **Vulkan:** For a cross-platform, compatible GPU acceleration.

## 1\. System-Wide Prerequisites

Before compiling, the system needs all the necessary build tools, kernel modules, and GPU drivers.

### 1.1. Install Standard Kernel

A minimal kernel may not include the `overlay` or `iptable_nat` modules (required by Docker and other tools). Installing the standard `linux` package ensures all necessary modules are present.

```bash
sudo pacman -Syu linux
```

*A reboot is required after installation to load the new kernel.*

### 1.2. Install Build Tools & GPU Dependencies

This single command installs all packages needed for both the ROCm and Vulkan builds:

```bash
sudo pacman -Syu git cmake base-devel \
rocm-hip-sdk rocminfo amd-smi \
vulkan-tools shaderc vulkan-headers \
numactl
```

  * **Build Tools:** `git`, `cmake`, `base-devel`
  * **ROCm:** `rocm-hip-sdk`, `rocminfo`, `amd-smi`
  * **Vulkan:** `vulkan-tools`, `shaderc`, `vulkan-headers`
  * **Utility:** `numactl` (for performance testing)

## 2\. Important: BIOS Performance Tuning

Your system has a unique performance profile. Based on our tests:

  * **Fastest Load Times:** Set the UMA/VRAM allocation in the BIOS to **"Auto"** or a balanced value like 64 GB.
  * **Slow Load Times:** Forcibly setting the VRAM to its maximum (96 GB) makes the system *significantly* slower when first loading models from disk.

For the best all-around performance, it's recommended to **leave the BIOS memory setting on "Auto"**.

## 3\. Checkout the Repository

The official `llama.cpp` repository is hosted on the `ggml-org` GitHub organization.

```bash
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
```

## 4\. Compile Backend 1: ROCm (High-Performance)

This build will be placed in the `/home/tiry/llama.cpp/build` directory and is optimized for your GPU.

Run this command from the root of the `llama.cpp` directory:

```bash
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
cmake -S . -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1151 -DCMAKE_BUILD_TYPE=Release \
&& cmake --build build --config Release -- -j 16
```

  * `DGGML_HIP=ON`: Enables the ROCm backend.
  * `DAMDGPU_TARGETS=gfx1151`: Specifically targets the Strix Halo architecture.

## 5\. Compile Backend 2: Vulkan (Compatibility)

This build will be placed in a separate `/home/tiry/llama.cpp/build-vulkan` directory.

```bash
# Create the new directory
mkdir build-vulkan
cd build-vulkan

# Configure the build
cmake .. -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release

# Compile the build
cmake --build . --config Release -- -j 16
```

  * `DGGML_VULKAN=ON`: Enables the Vulkan backend.
  * `cmake ..`: This syntax points to the source code in the parent directory.

## 6\. Download a GGUF Model

`llama.cpp` requires models in the GGUF format. You can create a `models` directory and download one.

```bash
mkdir ./models
wget -O ./models/Llama-3-8B-Instruct.Q5_K_M.gguf "https://huggingface.co/QuantFactory/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct.Q5_K_M.gguf?download=true"
```

## 7\. How to Run

You can now run either build by pointing to the correct executable.

### 7.1. Running the ROCm Build

```bash
./build/bin/llama-cli \
  -m ./models/Llama-3-8B-Instruct.Q5_K_M.gguf \
  -p "Building a spaceship is easy. First," \
  -n 128 \
  -ngl 999
```

### 7.2. Running the Vulkan Build

```bash
./build-vulkan/bin/llama-cli \
  -m ./models/Llama-3-8B-Instruct.Q5_K_M.gguf \
  -p "Building a spaceship is easy. First," \
  -n 128 \
  -ngl 999
```

  * **`-m`**: Specifies the model file.
  * **`-ngl 999`**: The most important flag. It tells `llama.cpp` to offload all possible layers to the GPU.

