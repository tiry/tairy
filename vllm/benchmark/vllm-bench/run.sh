#!/bin/bash

# vllm-bench automation script
# Note: set -e is NOT used to allow better error handling

# This script automates the process of running vllm benchmarks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_LOG_DIR="${LOG_DIR}/${TIMESTAMP}"
SERVER_LOG="${RUN_LOG_DIR}/vllm_server.log"
BENCH_LOG="${RUN_LOG_DIR}/benchmark.log"

# Default values
MAX_CONCURRENCY=1
NUM_PROMPTS=3
TEMPERATURE=0.3
TOP_P=0.75
REQUEST_RATE=inf
DATASET_PATH="prompts.jsonl"
MAX_MODEL_LEN=4096
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <model_name>

Options:
    -c, --config FILE       Configuration file (default: config.yaml)
    -h, --help              Show this help message
    --dry-run               Show what would be executed without running it
    --max-concurrency NUM   Maximum concurrency (default: 1)
    --num-prompts NUM       Number of prompts (default: 3)
    --temperature NUM       Temperature (default: 0.3)
    --top-p NUM             Top-p value (default: 0.75)
    --request-rate NUM      Request rate (default: inf)
    --max-model-len NUM     Maximum model context length (default: 4096)

Examples:
    $0 mistralai/Mistral-Nemo-Instruct-2407
    $0 --dry-run google/gemma-3-4b-it
    $0 --max-concurrency 2 --num-prompts 5 meta-llama/Llama-2-7b-hf
EOF
    exit 1
}

# Function to parse YAML config for benchmark settings
parse_benchmark_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_warn "Config file not found: $CONFIG_FILE"
        return
    fi

    # Parse benchmark settings from YAML
    local max_conc=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "max_concurrency:" | awk '{print $2}' || echo "")
    local num_pr=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "num_prompts:" | awk '{print $2}' || echo "")
    local temp=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "temperature:" | awk '{print $2}' || echo "")
    local top=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "top_p:" | awk '{print $2}' || echo "")
    local rate=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "request_rate:" | awk '{print $2}' || echo "")
    local dataset=$(grep -A 10 "^benchmark:" "$CONFIG_FILE" | grep "dataset_path:" | awk '{print $2}' || echo "")

    [[ -n "$max_conc" ]] && MAX_CONCURRENCY="$max_conc"
    [[ -n "$num_pr" ]] && NUM_PROMPTS="$num_pr"
    [[ -n "$temp" ]] && TEMPERATURE="$temp"
    [[ -n "$top" ]] && TOP_P="$top"
    [[ -n "$rate" ]] && REQUEST_RATE="$rate"
    [[ -n "$dataset" ]] && DATASET_PATH="$dataset"
}

# Function to extract model-specific vllm arguments from config
get_model_args() {
    local model_name="$1"
    local args=""

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo ""
        return
    fi

    # Extract vllm_args for the specific model
    # This is a simple parser - for more complex YAML, consider using yq
    local in_model_section=0
    local in_vllm_args=0
    
    while IFS= read -r line; do
        # Check if we're entering the model section
        if [[ "$line" =~ ^[[:space:]]*\"${model_name}\":[[:space:]]*$ ]] || \
           [[ "$line" =~ ^[[:space:]]*.${model_name}.:[[:space:]]*$ ]]; then
            in_model_section=1
            continue
        fi
        
        # If we're in the model section, look for vllm_args
        if [[ $in_model_section -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*vllm_args:[[:space:]]*$ ]]; then
                in_vllm_args=1
                continue
            fi
            
            # If we hit another model, stop
            if [[ "$line" =~ ^[[:space:]]*\".*\":[[:space:]]*$ ]] || \
               [[ "$line" =~ ^[[:space:]]*\'.*\':[[:space:]]*$ ]]; then
                break
            fi
            
            # Extract arguments
            if [[ $in_vllm_args -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
                    args="$args ${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\'(.*)\'[[:space:]]*$ ]]; then
                    args="$args ${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+)[[:space:]]*$ ]]; then
                    args="$args ${BASH_REMATCH[1]}"
                fi
                
                # If we hit a new section, stop
                if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_]+:[[:space:]]*$ ]] && \
                   [[ ! "$line" =~ vllm_args ]]; then
                    break
                fi
            fi
        fi
    done < "$CONFIG_FILE"
    
    echo "$args"
}

# Function to cleanup on exit
cleanup() {
    print_info "Cleaning up..."
    if [[ -n "$VLLM_PID" ]] && kill -0 "$VLLM_PID" 2>/dev/null; then
        print_info "Stopping vLLM server (PID: $VLLM_PID)"
        kill "$VLLM_PID" 2>/dev/null || true
        wait "$VLLM_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

# Parse command line arguments - track which were explicitly set
MODEL_NAME=""
CLI_MAX_CONCURRENCY=""
CLI_NUM_PROMPTS=""
CLI_TEMPERATURE=""
CLI_TOP_P=""
CLI_REQUEST_RATE=""
CLI_MAX_MODEL_LEN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --max-concurrency)
            CLI_MAX_CONCURRENCY="$2"
            shift 2
            ;;
        --num-prompts)
            CLI_NUM_PROMPTS="$2"
            shift 2
            ;;
        --temperature)
            CLI_TEMPERATURE="$2"
            shift 2
            ;;
        --top-p)
            CLI_TOP_P="$2"
            shift 2
            ;;
        --request-rate)
            CLI_REQUEST_RATE="$2"
            shift 2
            ;;
        --max-model-len)
            CLI_MAX_MODEL_LEN="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            MODEL_NAME="$1"
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$MODEL_NAME" ]]; then
    print_error "Model name is required"
    usage
fi

# Load configuration from file (this sets defaults)
parse_benchmark_config

# Override with command-line arguments (these take precedence)
[[ -n "$CLI_MAX_CONCURRENCY" ]] && MAX_CONCURRENCY="$CLI_MAX_CONCURRENCY"
[[ -n "$CLI_NUM_PROMPTS" ]] && NUM_PROMPTS="$CLI_NUM_PROMPTS"
[[ -n "$CLI_TEMPERATURE" ]] && TEMPERATURE="$CLI_TEMPERATURE"
[[ -n "$CLI_TOP_P" ]] && TOP_P="$CLI_TOP_P"
[[ -n "$CLI_REQUEST_RATE" ]] && REQUEST_RATE="$CLI_REQUEST_RATE"
[[ -n "$CLI_MAX_MODEL_LEN" ]] && MAX_MODEL_LEN="$CLI_MAX_MODEL_LEN"

# Create log directory structure
mkdir -p "$RUN_LOG_DIR"

# Save the actual parameters used (including command-line overrides) to a simple key-value file
cat > "${RUN_LOG_DIR}/run_params.txt" << EOF
model_name=$MODEL_NAME
max_concurrency=$MAX_CONCURRENCY
num_prompts=$NUM_PROMPTS
temperature=$TEMPERATURE
top_p=$TOP_P
request_rate=$REQUEST_RATE
max_model_len=$MAX_MODEL_LEN
dataset_path=$DATASET_PATH
timestamp=$TIMESTAMP
config_file=$CONFIG_FILE
EOF

print_info "Run parameters saved to: ${RUN_LOG_DIR}/run_params.txt"

# Also copy configuration file to logs directory for reference
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "${RUN_LOG_DIR}/config_${TIMESTAMP}.yaml"
fi

# Get model-specific arguments
MODEL_ARGS=$(get_model_args "$MODEL_NAME")

# Ensure dataset path is absolute or relative to script directory (for validation)
DATASET_PATH_FULL="$DATASET_PATH"
if [[ ! "$DATASET_PATH" = /* ]]; then
    DATASET_PATH_FULL="${SCRIPT_DIR}/${DATASET_PATH}"
fi

print_info "================================================"
print_info "vLLM Benchmark Run"
if [[ "$DRY_RUN" == true ]]; then
    print_warn "DRY RUN MODE - No commands will be executed"
fi
print_info "================================================"
print_info "Model: $MODEL_NAME"
print_info "Config file: $CONFIG_FILE"
print_info "Timestamp: $TIMESTAMP"
print_info "Log directory: $RUN_LOG_DIR"
print_info "Dataset path: $DATASET_PATH_FULL"
print_info "Max concurrency: $MAX_CONCURRENCY"
print_info "Number of prompts: $NUM_PROMPTS"
print_info "Temperature: $TEMPERATURE"
print_info "Top-p: $TOP_P"
print_info "Request rate: $REQUEST_RATE"
print_info "Max model length: $MAX_MODEL_LEN"
if [[ -n "$MODEL_ARGS" ]]; then
    print_info "Model-specific args: $MODEL_ARGS"
else
    print_info "Model-specific args: (none)"
fi
print_info "================================================"

# Validate dataset file exists
if [[ ! -f "$DATASET_PATH_FULL" ]]; then
    print_error "Dataset file not found: $DATASET_PATH_FULL"
    exit 1
fi

# DRY RUN MODE - Show commands and exit
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    print_info "Commands that would be executed:"
    echo ""
    echo -e "${YELLOW}# 1. Start vLLM server:${NC}"
    echo "vllm serve \"$MODEL_NAME\" --max-model-len $MAX_MODEL_LEN $MODEL_ARGS > \"$SERVER_LOG\" 2>&1 &"
    echo ""
    echo -e "${YELLOW}# 2. Monitor for server startup (checking for 'Application startup complete')${NC}"
    echo ""
    echo -e "${YELLOW}# 3. Extract model information:${NC}"
    echo "grep \"Loading model weights\" \"$SERVER_LOG\" > \"${RUN_LOG_DIR}/model_weights.txt\""
    echo "grep -A 5 \"ModelConfig\" \"$SERVER_LOG\" > \"${RUN_LOG_DIR}/model_config.txt\""
    echo ""
    echo -e "${YELLOW}# 4. Run benchmark:${NC}"
    echo "vllm bench serve \\"
    echo "    --save-result \\"
    echo "    --save-detailed \\"
    echo "    --backend vllm \\"
    echo "    --model \"$MODEL_NAME\" \\"
    echo "    --endpoint /v1/completions \\"
    echo "    --dataset-name custom \\"
    echo "    --dataset-path \"$DATASET_PATH_FULL\" \\"
    echo "    --num-prompts $NUM_PROMPTS \\"
    echo "    --max-concurrency $MAX_CONCURRENCY \\"
    echo "    --temperature=$TEMPERATURE \\"
    echo "    --top-p=$TOP_P \\"
    echo "    --result-dir \"$RUN_LOG_DIR\" \\"
    echo "    --request-rate $REQUEST_RATE"
    echo ""
    print_info "================================================"
    print_info "Dry run complete. Use without --dry-run to execute."
    print_info "================================================"
    exit 0
fi

# Check if vllm is installed
if ! command -v vllm &> /dev/null; then
    print_error "vllm command not found. Is vLLM installed?"
    print_info "Install vLLM with: pip install vllm"
    exit 1
fi

# Start vLLM server
print_info "Starting vLLM server..."
print_info "Command: vllm serve \"$MODEL_NAME\" --max-model-len $MAX_MODEL_LEN $MODEL_ARGS"

# Run vllm serve directly (not through bash -c) with nohup for proper daemonization
if [[ -n "$MODEL_ARGS" ]]; then
    # With model args - need to use eval to properly expand
    eval "nohup vllm serve \"$MODEL_NAME\" --max-model-len $MAX_MODEL_LEN $MODEL_ARGS > \"$SERVER_LOG\" 2>&1 &"
else
    # Without model args
    nohup vllm serve "$MODEL_NAME" --max-model-len $MAX_MODEL_LEN > "$SERVER_LOG" 2>&1 &
fi
VLLM_PID=$!

print_info "vLLM server process started (PID: $VLLM_PID)"

# Give it a moment to start and check periodically
for i in {1..10}; do
    sleep 1
    if ! kill -0 "$VLLM_PID" 2>/dev/null; then
        print_error "vLLM server failed to start (process exited after $i seconds)"
        print_error "Server log location: $SERVER_LOG"
        echo ""
        if [[ -f "$SERVER_LOG" && -s "$SERVER_LOG" ]]; then
            print_error "Server log content:"
            echo "----------------------------------------"
            cat "$SERVER_LOG"
            echo "----------------------------------------"
        else
            print_error "Server log is empty. The vllm command may not be working correctly."
            print_info "Try running manually: vllm serve \"$MODEL_NAME\" $MODEL_ARGS"
        fi
        exit 1
    fi
    
    # Show progress
    if [[ $i -eq 3 || $i -eq 6 ]]; then
        print_info "Server process still running (${i}s)..."
    fi
done

print_info "vLLM server started successfully (PID: $VLLM_PID)"
print_info "Server logs: $SERVER_LOG"

# Monitor server startup
print_info "Waiting for server to start..."
TIMEOUT=300  # 5 minutes timeout
ELAPSED=0

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    if ! kill -0 "$VLLM_PID" 2>/dev/null; then
        print_error "vLLM server process died unexpectedly"
        print_error "Server log location: $SERVER_LOG"
        echo ""
        if [[ -f "$SERVER_LOG" ]]; then
            print_error "Last 30 lines of server log:"
            echo "----------------------------------------"
            tail -n 30 "$SERVER_LOG"
            echo "----------------------------------------"
        fi
        exit 1
    fi
    
    # Check for startup completion
    if grep -q "Application startup complete" "$SERVER_LOG" 2>/dev/null; then
        print_info "Server started successfully!"
        break
    fi
    
    # Check for model loading
    if grep -q "Loading model weights" "$SERVER_LOG" 2>/dev/null && [[ $ELAPSED -eq 5 ]]; then
        print_info "Loading model weights..."
    fi
    
    sleep 1
    ((ELAPSED++))
done

if [[ $ELAPSED -ge $TIMEOUT ]]; then
    print_error "Server startup timeout"
    print_error "Check logs at: $SERVER_LOG"
    exit 1
fi

# Extract and save model information
print_info "Extracting model information..."

# Extract model memory usage
{
    echo "=== Model Memory Usage ===" 
    grep "Model loading took.*GiB memory" "$SERVER_LOG" 2>/dev/null || echo "Memory info not found"
    echo ""
    echo "=== KV Cache Info ==="
    grep "GPU KV cache size" "$SERVER_LOG" 2>/dev/null || echo "KV cache info not found"
    grep "Available KV cache memory" "$SERVER_LOG" 2>/dev/null || echo "KV cache memory not found"
    echo ""
    echo "=== Graph Capturing ==="
    grep "Graph capturing finished" "$SERVER_LOG" 2>/dev/null || echo "Graph info not found"
} > "${RUN_LOG_DIR}/model_memory_info.txt"

# Extract model configuration
{
    echo "=== Model Architecture ===" 
    grep "Resolved architecture" "$SERVER_LOG" 2>/dev/null || echo "Architecture not found"
    echo ""
    echo "=== Model Config ==="
    grep "max_seq_len" "$SERVER_LOG" 2>/dev/null | head -1 || echo "Max seq len not found"
    echo ""
    echo "=== Loading Time ==="
    grep "Loading weights took" "$SERVER_LOG" 2>/dev/null || echo "Loading time not found"
    grep "init engine.*took.*seconds" "$SERVER_LOG" 2>/dev/null || echo "Engine init time not found"
} > "${RUN_LOG_DIR}/model_config.txt"

if [[ -s "${RUN_LOG_DIR}/model_memory_info.txt" ]]; then
    print_info "Model memory info saved"
fi
if [[ -s "${RUN_LOG_DIR}/model_config.txt" ]]; then
    print_info "Model config saved"
fi

# Give server a moment to fully initialize
sleep 3

# Run benchmark
print_info "Starting benchmark..."
print_info "Running with $NUM_PROMPTS prompts at concurrency $MAX_CONCURRENCY"

# Ensure dataset path is absolute or relative to script directory
if [[ ! "$DATASET_PATH" = /* ]]; then
    DATASET_PATH="${SCRIPT_DIR}/${DATASET_PATH}"
fi

if [[ ! -f "$DATASET_PATH" ]]; then
    print_error "Dataset file not found: $DATASET_PATH"
    exit 1
fi

vllm bench serve \
    --save-result \
    --save-detailed \
    --backend vllm \
    --model "$MODEL_NAME" \
    --endpoint /v1/completions \
    --dataset-name custom \
    --dataset-path "$DATASET_PATH" \
    --num-prompts "$NUM_PROMPTS" \
    --max-concurrency "$MAX_CONCURRENCY" \
    --temperature="$TEMPERATURE" \
    --top-p="$TOP_P" \
    --result-dir "$RUN_LOG_DIR" \
    --request-rate "$REQUEST_RATE" 2>&1 | tee "$BENCH_LOG"

BENCH_EXIT_CODE=${PIPESTATUS[0]}

if [[ $BENCH_EXIT_CODE -eq 0 ]]; then
    print_info "Benchmark completed successfully!"
else
    print_error "Benchmark failed with exit code: $BENCH_EXIT_CODE"
fi

print_info "================================================"
print_info "Results saved in: $RUN_LOG_DIR"
print_info "================================================"

# List result files
print_info "Result files:"
ls -lh "$RUN_LOG_DIR"

exit $BENCH_EXIT_CODE
