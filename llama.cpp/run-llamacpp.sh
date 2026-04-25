#!/bin/bash

# --- Configuration ---
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build-rocm"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"
CUDA_BUILD_DIR="/home/tiry/llama.cpp/build-cuda"

# --- Defaults ---
DEFAULT_BACKEND="rocm" 
VALID_BACKENDS="cuda, rocm, vulkan"
MODEL_PATH="/home/tiry/models/Qwen3-Coder-Next-UD-Q8_K_XL/UD-Q8_K_XL/Qwen3-Coder-Next-UD-Q8_K_XL-00001-of-00003.gguf"
BACKEND=$DEFAULT_BACKEND
PROMPT=""
INTERACTIVE=false
BENCHMARK_MODE=false
SERVER_MODE=false
SERVER_PORT=8080

# --- APU Performance Defaults (Strix Halo Optimized) ---
USE_MMAP=false     # Default to false to avoid kernel thrashing with <32GB OS RAM
KV_TYPE="q8_0"     # Default to Q8 quantization for Key/Value cache
# CTX_SIZE=8192      # Default safe context window for ~80GB models in 96GB VRAM
CTX_SIZE=196608

# --- Helper Functions ---
print_usage() {
    echo "Usage: $0 -m <model_path> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m <path>   Path to .gguf model file."
    echo "  -b <type>   Backend: $VALID_BACKENDS. (Default: $DEFAULT_BACKEND)"
    echo "  -p \"<txt>\"  Single prompt mode."
    echo "  -i          Interactive conversation mode (-cnv)."
    echo "  -c <num>    Context size (Default: $CTX_SIZE)."
    echo "  --mmap      Enable memory-mapping (Not recommended for models > RAM)."
    echo "  --f16-kv    Use F16 KV cache (Higher quality, double memory usage)."
    echo "  --benchmark Run llama-bench."
    echo "  --server    Start llama-server."
    echo "  --port <n>  Server port (Default: 8080)."
    echo "  -h          Show this help."
    exit 0
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --benchmark) BENCHMARK_MODE=true; shift ;;
    --server)    SERVER_MODE=true; shift ;;
    --port)      SERVER_PORT="$2"; shift 2 ;;
    -b)          BACKEND="$2"; shift 2 ;;
    -m)          MODEL_PATH="$2"; shift 2 ;;
    -p)          PROMPT="$2"; shift 2 ;;
    -i)          INTERACTIVE=true; shift ;;
    -c)          CTX_SIZE="$2"; shift 2 ;;
    --mmap)      USE_MMAP=true; shift ;;
    --f16-kv)    KV_TYPE="f16"; shift ;;
    -h|--help)   print_usage ;;
    *)           echo "Invalid option: $1" >&2; print_usage; exit 1 ;;
  esac
done

# --- Validation & Path Resolution ---
if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model file not found at: $MODEL_PATH"; exit 1
fi

case $BACKEND in
    cuda)   BUILD_DIR="$CUDA_BUILD_DIR" ;;
    rocm)   BUILD_DIR="$ROCM_BUILD_DIR" ;;
    vulkan) BUILD_DIR="$VULKAN_BUILD_DIR" ;;
    *)      echo "Error: Invalid backend '$BACKEND'."; exit 1 ;;
esac

# 1. Determine Binary Name (Prioritize llama-cli over main)
if [ "$BENCHMARK_MODE" = true ]; then
    EXE_NAME="llama-bench"
elif [ "$SERVER_MODE" = true ]; then
    EXE_NAME="llama-server"
else
    if [ -f "${BUILD_DIR}/bin/llama-cli" ] || [ -f "${BUILD_DIR}/llama-cli" ]; then
        EXE_NAME="llama-cli"
    else
        EXE_NAME="main"
    fi
fi

# 2. Resolve Full Path (bin/ vs root/)
if [ -x "${BUILD_DIR}/bin/${EXE_NAME}" ]; then
    EXE_PATH="${BUILD_DIR}/bin/${EXE_NAME}"
elif [ -x "${BUILD_DIR}/${EXE_NAME}" ]; then
    EXE_PATH="${BUILD_DIR}/${EXE_NAME}"
else
    echo "Error: Executable '$EXE_NAME' not found in ${BUILD_DIR}/bin/ or ${BUILD_DIR}/"; exit 1
fi

# --- Command Assembly ---
GPU_LAYERS_FLAG=""
[ "$BACKEND" != "cuda" ] && GPU_LAYERS_FLAG="-ngl 999"

# Core Arguments
CMD_ARGS=(
    "-m" "$MODEL_PATH"
    $GPU_LAYERS_FLAG
    "--ctx-size" "$CTX_SIZE"
    "-ctk" "$KV_TYPE"
    "-ctv" "$KV_TYPE"
)

# Handle MMAP Toggle
if [ "$USE_MMAP" = false ]; then
    CMD_ARGS+=("--no-mmap")
fi

# Mode Selection
if [ "$BENCHMARK_MODE" = true ]; then
    echo "=== Starting Benchmark (Backend: $BACKEND) ==="
elif [ "$SERVER_MODE" = true ]; then
    echo "=== Starting Server (Backend: $BACKEND, Port: $SERVER_PORT) ==="
    CMD_ARGS+=("--host" "0.0.0.0" "--port" "$SERVER_PORT" "--jinja")
else
    echo "=== Starting CLI (Backend: $BACKEND, EXE: $EXE_NAME) ==="
    if [ -n "$PROMPT" ]; then
        CMD_ARGS+=("-p" "$PROMPT")
    else
        CMD_ARGS+=("-cnv") # Conversation mode is standard for llama-cli
    fi
fi

# --- Execution ---
echo "Running: $EXE_PATH ${CMD_ARGS[@]}"
echo "------------------------------------------------"
"$EXE_PATH" "${CMD_ARGS[@]}"