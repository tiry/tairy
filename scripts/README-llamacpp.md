# llama.cpp Script Usage Guide

## Overview

The `run-llamacpp.sh` script provides a unified interface to run llama.cpp with support for multiple backends (ROCm/Vulkan) and three operational modes:
- **CLI Mode** (default): Interactive or single-prompt inference
- **Benchmark Mode**: Performance testing using `llama-bench`
- **Server Mode**: HTTP API server using `llama-server`

## Recent Updates (November 2025)

### New Features
1. **Benchmark Mode** (`--benchmark`): Run performance benchmarks on your model
2. **Server Mode** (`--server`): Launch an OpenAI-compatible HTTP API server
3. **Port Configuration** (`--port`): Customize the server port (default: 8080)
4. **Improved Argument Parsing**: Support for long options (e.g., `--benchmark`)

### Updated Knowledge
The script has been updated based on the latest llama.cpp documentation from the official repository, including:
- Support for `llama-bench` for comprehensive benchmarking
- Support for `llama-server` for HTTP API serving
- OpenAI-compatible API endpoints
- Modern command-line interface patterns

## Usage

### Basic Syntax

```bash
./scripts/run-llamacpp.sh -m <model_path> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-m <path>` | Path to the .gguf model file (required) | - |
| `-b <type>` | Backend to use: 'rocm' or 'vulkan' | rocm |
| `-p "<prompt>"` | Single prompt (overrides interactive mode) | - |
| `-i` | Start in interactive mode | default if no -p |
| `--benchmark` | Run performance benchmark | - |
| `--server` | Start HTTP server mode | - |
| `--port <n>` | Server port number | 8080 |
| `-h, --help` | Show help message | - |

## Mode Examples

### 1. CLI Mode (Interactive)

Default mode for chatting with the model:

```bash
# Using default backend (ROCm)
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf

# Using Vulkan backend
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf -b vulkan

# Explicit interactive flag
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf -i
```

### 2. CLI Mode (Single Prompt)

Run a single prompt without interactive mode:

```bash
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf \
  -p "Explain quantum computing in simple terms"
```

### 3. Benchmark Mode

Test model performance with llama-bench:

```bash
# ROCm backend
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --benchmark

# Vulkan backend
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf -b vulkan --benchmark
```

**Expected Output:**
```
| model               |       size |     params | backend    | threads |          test |                  t/s |
| ------------------- | ---------: | ---------: | ---------- | ------: | ------------: | -------------------: |
| llama 8B Q5_K_M     | 5.73 GiB   |     8.03 B | ROCm       |      16 |         pp512 |      2341.23 ± 15.42 |
| llama 8B Q5_K_M     | 5.73 GiB   |     8.03 B | ROCm       |      16 |         tg128 |        89.45 ± 0.67  |
```

### 4. Server Mode

Start an HTTP API server:

```bash
# Default port (8080)
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --server

# Custom port
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --server --port 8000

# With Vulkan backend
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf -b vulkan --server --port 8000
```

**Server Endpoints:**
- Web UI: `http://localhost:8080`
- Chat Completion API: `http://localhost:8080/v1/chat/completions`
- Completions API: `http://localhost:8080/v1/completions`
- Embeddings API: `http://localhost:8080/v1/embeddings`

**Example API Request:**
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

## Configuration

### Build Directories

The script uses these default build directories (configurable in the script):

```bash
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"
```

### Default Model

Default model path (when -m is not specified):

```bash
MODEL_PATH="/home/tiry/models/Llama-3-8B-Instruct.Q5_K_M.gguf"
```

## Common Parameters

The script automatically sets these parameters:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `-ngl` | 999 | GPU layer offloading (use GPU for all layers) |
| `-c` | 4096 | Context size (CLI/Server modes) |
| `--color` | enabled | Colored output (CLI mode only) |

## Troubleshooting

### Executable Not Found

If you see: `Error: Executable not found or not executable`

1. Check that llama.cpp is built in the configured directories
2. Verify the build includes the required executables:
   - `llama-cli` for CLI mode
   - `llama-bench` for benchmark mode
   - `llama-server` for server mode

### Model Not Found

If you see: `Error: Model file not found`

1. Verify the model path is correct
2. Ensure the model file exists and is accessible
3. Check that you have read permissions for the model file

### Port Already in Use

If the server fails to start with "port already in use":

1. Use a different port: `--port 8081`
2. Or stop the process using the port:
   ```bash
   lsof -i :8080
   kill <PID>
   ```

## Performance Tips

1. **GPU Offloading**: The script uses `-ngl 999` to offload all layers to GPU
2. **Context Size**: Default 4096 tokens; adjust if needed for longer conversations
3. **Backend Choice**: ROCm for AMD GPUs, Vulkan for broader compatibility

## Integration Examples

### Using with curl (Server Mode)

```bash
# Start server
./scripts/run-llamacpp.sh -m ~/models/Llama-3-8B.gguf --server &

# Make requests
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Scripting Multiple Tests

```bash
#!/bin/bash
# Benchmark multiple models
for model in ~/models/*.gguf; do
  echo "Benchmarking: $model"
  ./scripts/run-llamacpp.sh -m "$model" --benchmark
done
```

## Related Resources

- [llama.cpp Official Repository](https://github.com/ggml-org/llama.cpp)
- [llama.cpp Documentation](https://github.com/ggml-org/llama.cpp/tree/master/docs)
- [GGUF Model Format](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md)
- [OpenAI API Specification](https://platform.openai.com/docs/api-reference)

## License

This script is part of the tairy project. See main repository for license information.
