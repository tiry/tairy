
Scripts for managing and running llama.cpp with various backends (ROCm, Vulkan, CUDA).

## `run-llamacpp.sh`

Unified interface to run llama.cpp with support for multiple backends and operational modes.

**📖 Detailed Documentation:** [README-llamacpp.md](README-llamacpp.md)

**Quick Start:**
```bash
# Interactive mode (default)
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf

# Single prompt
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf -p "Explain quantum computing"

# Benchmark mode
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --benchmark

# Server mode (HTTP API)
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --server --port 8080
```

**Features:**
- ✅ CLI Mode (interactive or single prompt)
- ✅ Benchmark Mode (performance testing)
- ✅ Server Mode (OpenAI-compatible HTTP API)
- ✅ Multiple backends: ROCm (AMD), Vulkan (compatibility), CUDA (NVIDIA)
- ✅ GPU layer offloading
- ✅ Configurable ports and parameters

**Options:**
- `-m <path>` - Model file path (required)
- `-b <type>` - Backend: 'rocm', 'vulkan', or 'cuda' (default: rocm)
- `-p "<prompt>"` - Single prompt mode
- `-i` - Interactive mode (default)
- `--benchmark` - Run performance benchmark
- `--server` - Start HTTP server
- `--port <n>` - Server port (default: 8080)

---

## `update-llamacpp.sh`

Updates and rebuilds llama.cpp from the upstream repository with support for multiple GPU backends.

**Usage:**
```bash
# Update and build all backends (ROCm, Vulkan, CUDA)
./scripts/update-llamacpp.sh

# Build only specific backend
./scripts/update-llamacpp.sh rocm
./scripts/update-llamacpp.sh vulkan
./scripts/update-llamacpp.sh cuda
```

**Features:**
- ✅ Automatic git pull and version check
- ✅ Skips rebuild if already up to date
- ✅ Selective architecture building
- ✅ Parallel compilation (`-j 16`)
- ✅ Optimized builds (Release mode)

**Supported Backends:**
- **ROCm**: AMD GPU high-performance backend (gfx1151 target)
- **Vulkan**: Cross-platform compatibility backend
- **CUDA**: NVIDIA GPU backend

**Configuration:**
- Llama.cpp directory: `/home/tiry/llama.cpp`
- Build directories:
  - ROCm: `build-rocm`
  - Vulkan: `build-vulkan`
  - CUDA: `build-cuda`

---