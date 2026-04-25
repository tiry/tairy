#!/bin/bash

# --- Configuration ---
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build-rocm"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"
CUDA_BUILD_DIR="/home/tiry/llama.cpp/build-cuda"

# --- Defaults ---
DEFAULT_BACKEND="cuda" 
VALID_BACKENDS="cuda, rocm, vulkan"
MODEL_PATH="/home/tiry/models/Llama-3-8B-Instruct.Q5_K_M.gguf"
BACKEND=$DEFAULT_BACKEND
PROMPT=""
INTERACTIVE=false
BENCHMARK_MODE=false
SERVER_MODE=false
SERVER_PORT=8080

# --- Helper Functions ---
print_usage() {
    echo "Usage: $0 -m <model_path> [-b <backend>] [-p <prompt>] [-i] [--benchmark] [--server] [--port <port>]"
    echo ""
    echo "Options:"
    echo "  -m <path>   Path to the .gguf model file."
    echo "  -b <type>   Backend to use: $VALID_BACKENDS. (Default: $DEFAULT_BACKEND)"
    echo "  -p \"<prompt>\" Provide a single prompt."
    echo "  -i          Start in interactive conversation mode."
    echo "  --benchmark Run llama-bench."
    echo "  --server    Start llama-server."
    echo "  --port <n>  Port for server mode (Default: 8080)."
    echo "  -h          Show this help message."
    exit 0
}

# --- Script Logic: Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --benchmark) BENCHMARK_MODE=true; shift ;;
    --server)    SERVER_MODE=true; shift ;;
    --port)      SERVER_PORT="$2"; shift 2 ;;
    -b)          BACKEND="$2"; shift 2 ;;
    -m)          MODEL_PATH="$2"; shift 2 ;;
    -p)          PROMPT="$2"; shift 2 ;;
    -i)          INTERACTIVE=true; shift ;;
    -h|--help)   print_usage ;;
    *)           echo "Invalid option: $1" >&2; print_usage; exit 1 ;;
  esac
done

# --- Validation & Setup ---

if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model file not found at: $MODEL_PATH"
    exit 1
fi

case $BACKEND in
    cuda)   BUILD_DIR="$CUDA_BUILD_DIR" ;;
    rocm)   BUILD_DIR="$ROCM_BUILD_DIR" ;;
    vulkan) BUILD_DIR="$VULKAN_BUILD_DIR" ;;
    *)      echo "Error: Invalid backend '$BACKEND'. Choose $VALID_BACKENDS."; exit 1 ;;
esac

# 1. Determine Binary Name
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

# 2. Resolve Path
if [ -x "${BUILD_DIR}/bin/${EXE_NAME}" ]; then
    EXE_PATH="${BUILD_DIR}/bin/${EXE_NAME}"
elif [ -x "${BUILD_DIR}/${EXE_NAME}" ]; then
    EXE_PATH="${BUILD_DIR}/${EXE_NAME}"
else
    echo "Error: Executable '$EXE_NAME' not found."
    exit 1
fi

# --- Command Assembly ---

GPU_LAYERS_FLAG=""
if [ "$BACKEND" != "cuda" ]; then
    GPU_LAYERS_FLAG="-ngl 999"
fi

CMD_ARGS=("-m" "$MODEL_PATH" $GPU_LAYERS_FLAG)

if [ "$BENCHMARK_MODE" = true ]; then
    echo "=== Starting Benchmark (Backend: $BACKEND) ==="
elif [ "$SERVER_MODE" = true ]; then
    echo "=== Starting Server (Backend: $BACKEND, Port: $SERVER_PORT) ==="
    CMD_ARGS+=("--host" "0.0.0.0" "--port" "$SERVER_PORT" "--ctx-size" "4096" "--jinja")
else
    echo "=== Starting CLI (Backend: $BACKEND, EXE: $EXE_NAME) ==="
    CMD_ARGS+=("--ctx-size" "4096")
    
    if [ -n "$PROMPT" ]; then
        CMD_ARGS+=("-p" "$PROMPT")
    else
        # FIXED: Use -cnv (Conversation Mode) which is the modern interactive standard
        CMD_ARGS+=("-cnv")
    fi
fi

# --- Final Execution ---
echo "Running: $EXE_PATH ${CMD_ARGS[@]}"
echo "------------------------------------------------"
"$EXE_PATH" "${CMD_ARGS[@]}"