# Scripts Directory

This directory contains utility scripts for various tasks including LLM operations, video conversion, GPU management, and AI agent memory inspection.

## 📚 Table of Contents

- [LLM Tools](#llm-tools)
- [Video Processing](#video-processing)
- [GPU Management (eGPU)](#gpu-management-egpu)
- [AI Agent Tools](#ai-agent-tools)

---

## 🤖 LLM Tools

Scripts for managing and running llama.cpp with various backends (ROCm, Vulkan, CUDA).

### `run-llamacpp.sh`

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

### `update-llamacpp.sh`

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

## 🎬 Video Processing

Batch video conversion tools using FFmpeg with GPU/CPU encoding support.

### `vconvert.sh`

Batch video conversion with GPU acceleration, background processing, and smart file management.

**📖 Detailed Documentation:** [README-vconvert.md](README-vconvert.md)

**Quick Start:**
```bash
# Fast GPU conversion (AV1, QP 30)
./scripts/vconvert.sh --fast ~/Videos/

# Balanced CPU conversion (AV1, CRF 28)
./scripts/vconvert.sh --medium ~/Videos/

# High quality conversion (H.265, CRF 28)
./scripts/vconvert.sh --best ~/Videos/

# Background processing
./scripts/vconvert.sh --background --medium ~/Videos/
./scripts/vconvert.sh --status ~/Videos/        # Check progress
./scripts/vconvert.sh --stop ~/Videos/          # Stop conversion
```

**Features:**
- ✅ Batch processing with automatic file discovery
- ✅ GPU (VAAPI) and CPU encoding modes
- ✅ Multiple codecs: AV1 and H.265 (HEVC)
- ✅ Background processing with progress tracking
- ✅ Smart file management (preserves originals with `_src` suffix)
- ✅ Auto-organization (moves completed files to `done/` subdirectory)
- ✅ Size validation (only replaces if smaller)
- ✅ Detailed conversion summaries with statistics
- ✅ Audio re-encoding fallback for problematic streams

**Preset Modes:**
- `--fast`: GPU, AV1, QP 30 (quickest)
- `--medium`: CPU, AV1, CRF 28, preset 8 (balanced)
- `--best`: CPU, H.265, CRF 28, slow preset (highest quality)

**Advanced Options:**
- `--mode <gpu|cpu>` - Encoding mode
- `--codec <av1|h265>` - Video codec
- `--qp <value>` - GPU quality parameter
- `--crf <value>` - CPU quality parameter
- `--preset <value>` - CPU encoding speed
- `--dry-run` - Preview without converting
- `--background` - Run in background
- `--status` - Check background progress
- `--stop` - Stop background process

---

## 🎮 GPU Management (eGPU)

Utilities for managing external GPU setups, particularly for AMD eGPU configurations.

### Quick Overview

| Script | Purpose |
|--------|---------|
| `list_gpu.sh` | List all detected GPUs with driver info |
| `check_link.sh` | Check PCIe link status and speed |
| `check_desktop_rendering.sh` | Verify which GPU is rendering the desktop |
| `monitor_tx.sh` | Monitor GPU data transfer in real-time |
| `egpu_cleanup.sh` | Clean up eGPU drivers and reset |
| `nv_cleanup.sh` | Clean up NVIDIA drivers |

### Usage Examples

```bash
# List all GPUs
./scripts/egpu/list_gpu.sh

# Check PCIe link status
./scripts/egpu/check_link.sh

# Check which GPU is rendering desktop
./scripts/egpu/check_desktop_rendering.sh

# Monitor GPU data transfer
./scripts/egpu/monitor_tx.sh

# Clean up eGPU setup
./scripts/egpu/egpu_cleanup.sh

# Clean up NVIDIA drivers
./scripts/egpu/nv_cleanup.sh
```

**Common Use Cases:**
- 🔍 Diagnostics: Check GPU detection and link status
- 🖥️ Rendering verification: Ensure correct GPU is being used
- 📊 Performance monitoring: Track data transfer rates
- 🧹 Troubleshooting: Clean up driver installations

---

## 🤖 AI Agent Tools

Scripts for inspecting and managing AI agent memory and knowledge bases.

### `dump_chunks.py` + `dump_chunks.sh`

Inspect and view document chunks from Agent Zero's vector store memory.

**Purpose:**
View the contents of indexed documents stored in Agent Zero's memory system to understand what knowledge the agent has access to.

**Usage:**
```bash
# Run the viewer (automatically sets up virtual environment)
./scripts/dump_chunks.sh
```

**Features:**
- ✅ Automatic virtual environment setup
- ✅ Loads pickled document store from Agent Zero
- ✅ Displays document IDs and content previews
- ✅ Truncates long text for readability (500 chars)

**What It Does:**
1. Creates/activates a Python virtual environment
2. Installs `langchain-community` dependency
3. Loads the index.pkl file from Agent Zero's data directory
4. Displays all document chunks with IDs and content previews

**Default Data Path:**
`/home/tiry/a0_data_dir/memory/default/index.pkl`

**Output Format:**
```
Total chunks: 42

Doc ID: abc123
Content preview:
[First 500 characters of the document content...]
----------------------------------------
Doc ID: def456
Content preview:
[First 500 characters of the document content...]
----------------------------------------
```

**Use Cases:**
- 🔍 Debug what documents the agent has indexed
- 📚 Review knowledge base contents
- 🧹 Identify outdated or incorrect information
- 📊 Understand agent's context and knowledge scope

---

## 🔧 General Script Requirements

### System Dependencies

**For LLM Tools:**
- CMake, Git
- ROCm, Vulkan, or CUDA drivers (depending on backend)
- llama.cpp repository cloned to `/home/tiry/llama.cpp`

**For Video Processing:**
- FFmpeg with codec support (libx264, libx265, AV1)
- VAAPI drivers (for GPU encoding)
- Standard Unix utilities: `find`, `stat`, `awk`, `numfmt`

**For AI Agent Tools:**
- Python 3.7+
- Virtual environment support (`python3-venv`)

**For eGPU Tools:**
- Linux kernel with DRM support
- AMD or NVIDIA drivers (depending on GPU)
- PCIe device access

---

## 📁 File Structure

```
scripts/
├── ReadMe.md                    # This file
├── README-llamacpp.md           # Detailed llama.cpp documentation
├── README-vconvert.md           # Detailed video conversion documentation
├── run-llamacpp.sh              # Run llama.cpp (CLI/Benchmark/Server)
├── update-llamacpp.sh           # Update and build llama.cpp
├── vconvert.sh                  # Video conversion utility
├── dump_chunks.py               # Agent Zero memory inspector
├── dump_chunks.sh               # Agent Zero memory inspector wrapper
└── egpu/                        # eGPU management utilities
    ├── check_desktop_rendering.sh
    ├── check_link.sh
    ├── egpu_cleanup.sh
    ├── list_gpu.sh
    ├── monitor_tx.sh
    └── nv_cleanup.sh
```

---

## 🚀 Quick Reference

### Most Common Tasks

| Task | Command |
|------|---------|
| Run LLM interactively | `./scripts/run-llamacpp.sh -m <model>` |
| Start LLM server | `./scripts/run-llamacpp.sh -m <model> --server` |
| Update llama.cpp | `./scripts/update-llamacpp.sh` |
| Convert videos (background) | `./scripts/vconvert.sh --background --medium <dir>` |
| Check conversion progress | `./scripts/vconvert.sh --status <dir>` |
| List GPUs | `./scripts/egpu/list_gpu.sh` |
| View agent memory | `./scripts/dump_chunks.sh` |

---

## 🛠️ Troubleshooting

### Script Won't Execute
```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x scripts/egpu/*.sh
```

### Wrong Backend/GPU
- Check driver installation: `rocm-smi`, `vulkaninfo`, `nvidia-smi`
- Verify build directories exist
- Run update script for your backend

### Video Conversion Issues
- Check FFmpeg installation: `ffmpeg -version`
- Verify codec support: `ffmpeg -codecs | grep av1`
- For GPU encoding, check VAAPI: `vainfo`

### Agent Memory Not Found
- Ensure Agent Zero has been run and indexed documents
- Check the path in `dump_chunks.py` matches your setup
- Verify pickle file exists: `ls -lh /home/tiry/a0_data_dir/memory/default/index.pkl`

---

## 📝 Contributing

When adding new scripts to this directory:

1. Make scripts executable: `chmod +x <script>`
2. Add shebang line: `#!/bin/bash` or `#!/usr/bin/env python3`
3. Include help text (`--help` option)
4. Update this ReadMe.md with the new script
5. Create detailed documentation if the script is complex

---

## 📄 License

These scripts are part of the Tairy project. Refer to the main project license for details.

---

## 🔗 Related Documentation

- [Main Project README](../README.md)
- [Installation Guide](../install/Install.md)
- [llama.cpp Install Guide](../install/llamacpp_install.md)
- [Services Documentation](../install/services/ReadMe.md)
- [FFmpeg Installation](../install/ffmpeg.md)
