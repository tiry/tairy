#!/bin/bash

# --- Configuration ---
# Set the paths to your llama.cpp builds based on your setup
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build-rocm"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"
CUDA_BUILD_DIR="/home/tiry/llama.cpp/build-cuda" # New CUDA build path

# --- Defaults ---
DEFAULT_BACKEND="cuda" 
VALID_BACKENDS="cuda, rocm, vulkan"

# --- Helper Functions ---
print_usage() {
    echo "Usage: $0 -m <model_path> [-b <backend>] [-p <prompt>] [-i] [--benchmark] [--server] [--port <port>]"
    echo ""
    echo "Options:"
    echo "  -m <path>   (Required) Path to the .gguf model file."
    echo "  -b <type>   Backend to use: $VALID_BACKENDS. (Default: $DEFAULT_BACKEND)"
    echo "  -p \"<prompt>\" Provide a single prompt. This will override interactive mode."
    echo "  -i          Start in interactive mode. (This is the default if no -p is given)."
    echo "  --benchmark Run llama-bench to benchmark the model performance."
    echo "  --server    Start llama-server to serve the model over HTTP."
    echo "  --port <n>  Port for server mode (default: 8080)."
    echo "  -h          Show this help message."
    echo ""
    echo "Examples:"
    echo "  Interactive (CUDA):"
    echo "    $0 -m ./models/Llama-3-8B.gguf"
    echo ""
    echo "  Single Prompt (Vulkan):"
    echo "    $0 -m ./models/my-model.gguf -b vulkan -p \"What is the capital of France?\""
    echo ""
    echo "  Benchmark (ROCm):"
    echo "    $0 -m ./models/Llama-3-8B.gguf -b rocm --benchmark"
    echo ""
    echo "  Server Mode (CUDA):"
    echo "    $0 -m ./models/Llama-3-8B.gguf --server --port 8080"
}

# --- Script Main ---

# Set defaults for options
BACKEND=$DEFAULT_BACKEND
MODEL_PATH="/home/tiry/models/Llama-3-8B-Instruct.Q5_K_M.gguf"
PROMPT=""
INTERACTIVE=false
BENCHMARK_MODE=false
SERVER_MODE=false
SERVER_PORT=8080

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case $1 in
    # ... (Parsing logic remains the same)
    --benchmark)
      BENCHMARK_MODE=true
      shift
      ;;
    --server)
      SERVER_MODE=true
      shift
      ;;
    --port)
      SERVER_PORT="$2"
      shift 2
      ;;
    -b)
      BACKEND="$2"
      shift 2
      ;;
    -m)
      MODEL_PATH="$2"
      shift 2
      ;;
    -p)
      PROMPT="$2"
      shift 2
      ;;
    -i)
      INTERACTIVE=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -*)
      echo "Invalid option: $1" >&2
      print_usage
      exit 1
      ;;
    *)
      shift
      ;;
  esac
done

# --- Input Validation ---

# 1. Check if model path was provided
if [ -z "$MODEL_PATH" ]; then
    echo "Error: Model path is required."
    print_usage
    exit 1
fi

# 2. Check if the model file exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model file not found at: $MODEL_PATH"
    exit 1
fi

# 3. Validate that only one mode is selected
MODE_COUNT=0
[ "$BENCHMARK_MODE" = true ] && ((MODE_COUNT++))
[ "$SERVER_MODE" = true ] && ((MODE_COUNT++))

if [ $MODE_COUNT -gt 1 ]; then
    echo "Error: Cannot use --benchmark and --server together. Choose one mode."
    exit 1
fi

# 4. Determine build directory based on backend
BUILD_DIR=""
if [ "$BACKEND" = "cuda" ]; then
    BUILD_DIR="$CUDA_BUILD_DIR"
elif [ "$BACKEND" = "rocm" ]; then
    BUILD_DIR="$ROCM_BUILD_DIR"
elif [ "$BACKEND" = "vulkan" ]; then
    BUILD_DIR="$VULKAN_BUILD_DIR"
else
    echo "Error: Invalid backend '$BACKEND'. Choose $VALID_BACKENDS."
    exit 1
fi

# 5. Select the executable based on the mode
EXE_NAME=""
if [ "$BENCHMARK_MODE" = true ]; then
    EXE_NAME="llama-bench"
elif [ "$SERVER_MODE" = true ]; then
    EXE_NAME="llama-server"
else
    EXE_NAME="main"
fi

EXE_PATH="${BUILD_DIR}/bin/${EXE_NAME}"

# 6. Check if the executable file exists
if [ ! -x "$EXE_PATH" ]; then
    echo "Error: Executable not found or not executable at: $EXE_PATH"
    echo "Expected path: $EXE_PATH"
    echo "Please ensure the '$BACKEND' version of llama.cpp has been successfully built."
    exit 1
fi

# --- Build Offload Flag Conditionally ---
# The -ngl flag is used to explicitly tell llama.cpp to offload layers.
# For CUDA, the offload is automatic and highly optimized, so we omit -ngl 999.
GPU_LAYERS_FLAG=""
if [ "$BACKEND" = "rocm" ] || [ "$BACKEND" = "vulkan" ]; then
    # We explicitly offload all possible layers for non-CUDA backends
    GPU_LAYERS_FLAG="-ngl 999"
    echo "Note: Using explicit GPU layer offload flag: $GPU_LAYERS_FLAG for $BACKEND."
fi

# --- Build and Run Command ---

# We use a Bash array to safely build the command arguments
CMD_ARGS=()

if [ "$BENCHMARK_MODE" = true ]; then
    # Benchmark mode: use llama-bench
    echo "--- Starting llama-bench (Benchmark Mode) ---"
    echo "Backend:    $BACKEND"
    echo "Executable: $EXE_PATH"
    echo "Model:      $MODEL_PATH"
    echo "---------------------------------------------"
    
    # llama-bench arguments. Note the use of the conditional flag.
    CMD_ARGS=("-m" "$MODEL_PATH" $GPU_LAYERS_FLAG)
    
elif [ "$SERVER_MODE" = true ]; then
    # Server mode: use llama-server
    echo "--- Starting llama-server (HTTP Server Mode) ---"
    echo "Backend:    $BACKEND"
    echo "Executable: $EXE_PATH"
    echo "Model:      $MODEL_PATH"
    echo "Host:       0.0.0.0"
    echo "Port:       $SERVER_PORT"
    echo "------------------------------------------------"
    echo ""
    echo "Server will be accessible at:"
    echo "  Local:     http://localhost:$SERVER_PORT"
    echo "------------------------------------------------"
    
    # llama-server arguments. Note the use of the conditional flag.
    CMD_ARGS=("-m" "$MODEL_PATH" $GPU_LAYERS_FLAG "--host" "0.0.0.0" "--port" "$SERVER_PORT" "-c" "4096" "--jinja")
    
else
    # CLI mode (default): use main
    echo "--- Starting main (CLI Mode) ---"
    echo "Backend:    $BACKEND"
    echo "Executable: $EXE_PATH"
    echo "Model:      $MODEL_PATH"
    echo "-------------------------------------"
    
    # CLI arguments. Note the use of the conditional flag.
    CMD_ARGS=("-m" "$MODEL_PATH" $GPU_LAYERS_FLAG "--color")
    
    # If a prompt is provided, use it. Otherwise, default to interactive.
    if [ -n "$PROMPT" ]; then
        CMD_ARGS+=("-p" "$PROMPT")
    else
        CMD_ARGS+=("-i")
    fi
    
    # Add context size
    CMD_ARGS+=("-c" "4096")
fi

# --- Final Execution ---
echo "Running Command: $EXE_PATH ${CMD_ARGS[@]}"
echo "-------------------------------------"
# Execute the final command
"$EXE_PATH" "${CMD_ARGS[@]}"