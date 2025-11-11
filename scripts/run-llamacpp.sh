#!/bin/bash

# --- Configuration ---
# Set the paths to your llama.cpp builds based on your setup
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"

# --- Defaults ---
DEFAULT_BACKEND="rocm" # "rocm" or "vulkan"

# --- Helper Functions ---
print_usage() {
    echo "Usage: $0 -m <model_path> [-b <backend>] [-p <prompt>] [-i]"
    echo ""
    echo "Options:"
    echo "  -m <path>   (Required) Path to the .gguf model file."
    echo "  -b <type>   Backend to use: 'rocm' or 'vulkan'. (Default: $DEFAULT_BACKEND)"
    echo "  -p \"<prompt>\" Provide a single prompt. This will override interactive mode."
    echo "  -i          Start in interactive mode. (This is the default if no -p is given)."
    echo "  -h          Show this help message."
    echo ""
    echo "Example (ROCm, Interactive):"
    echo "  $0 -m ./models/Llama-3-8B.gguf"
    echo ""
    echo "Example (Vulkan, Single Prompt):"
    echo "  $0 -m ./models/my-model.gguf -b vulkan -p \"What is the capital of France?\""
}

# --- Script Main ---

# Set defaults for options
BACKEND=$DEFAULT_BACKEND
MODEL_PATH="/home/tiry/models/Llama-3-8B-Instruct.Q5_K_M.gguf"
PROMPT=""
INTERACTIVE=false # This is just a placeholder, the logic prioritizes the prompt.

# Parse command-line options
while getopts ":b:m:p:ih" opt; do
  case $opt in
    b)
      BACKEND="$OPTARG"
      ;;
    m)
      MODEL_PATH="$OPTARG"
      ;;
    p)
      PROMPT="$OPTARG"
      ;;
    i)
      INTERACTIVE=true # User can still pass -i for clarity
      ;;
    h)
      print_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      print_usage
      exit 1
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

# 3. Select the executable based on the chosen backend
EXE_PATH=""
if [ "$BACKEND" = "rocm" ]; then
    EXE_PATH="${ROCM_BUILD_DIR}/bin/llama-cli"
elif [ "$BACKEND" = "vulkan" ]; then
    EXE_PATH="${VULKAN_BUILD_DIR}/bin/llama-cli"
else
    echo "Error: Invalid backend '$BACKEND'. Choose 'rocm' or 'vulkan'."
    exit 1
fi

# 4. Check if the executable file exists
if [ ! -x "$EXE_PATH" ]; then
    echo "Error: Executable not found or not executable at: $EXE_PATH"
    echo "Please double-check your build directories."
    exit 1
fi

# --- Build and Run Command ---

# We use a Bash array to safely build the command arguments
# This handles spaces in paths and prompts correctly
CMD_ARGS=("-m" "$MODEL_PATH" "-ngl" "999" "--color")

# *** UPDATED LOGIC ***
# If a prompt is provided, use it. Otherwise, default to interactive.
if [ -n "$PROMPT" ]; then
    # A prompt was provided. This takes priority.
    CMD_ARGS+=("-p" "$PROMPT")
else
    # No prompt was provided, default to interactive mode.
    # The -i flag is now just for explicit clarity, but this is the default.
    CMD_ARGS+=("-i")
fi

# Add any other flags you always want (e.g., context size)
CMD_ARGS+=("-c" "4096")

# --- Final Execution ---
echo "--- Starting llama.cpp ---"
echo "Backend:   $BACKEND"
echo "Executable: $EXE_PATH"
echo "Model:     $MODEL_PATH"
echo "--------------------------"

# Use "$@" to expand the array properly, preserving quotes
"$EXE_PATH" "${CMD_ARGS[@]}"
