#!/bin/bash

# Run benchmarks for all models listed in models2benchmark file
# Format: model_name [concurrency] [num_prompts]
# Note: We don't use 'set -e' here because we handle errors manually

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_FILE="${SCRIPT_DIR}/models2benchmark"
RUN_SCRIPT="${SCRIPT_DIR}/run.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

This script runs benchmarks for all models listed in the models2benchmark file.

Options:
    -h, --help              Show this help message
    -f, --file FILE         Models file (default: models2benchmark)
    --dry-run               Pass --dry-run to each benchmark
    --continue-on-error     Continue to next model even if one fails
    Additional options are passed to run.sh for each model

Examples:
    $0                                      # Run all models with default settings
    $0 --dry-run                            # Dry run for all models
    $0 --num-prompts 10                     # Run all with 10 prompts each
    $0 --continue-on-error --num-prompts 5  # Continue even if models fail
EOF
    exit 1
}

# Parse arguments
CONTINUE_ON_ERROR=false
RUN_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -f|--file)
            MODELS_FILE="$2"
            shift 2
            ;;
        --continue-on-error)
            CONTINUE_ON_ERROR=true
            shift
            ;;
        *)
            # Pass through to run.sh
            RUN_ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if models file exists
if [[ ! -f "$MODELS_FILE" ]]; then
    print_error "Models file not found: $MODELS_FILE"
    print_info "Create a file with one model name per line"
    exit 1
fi

# Check if run.sh exists
if [[ ! -x "$RUN_SCRIPT" ]]; then
    print_error "run.sh not found or not executable: $RUN_SCRIPT"
    exit 1
fi

# Read models file and count
# Format: model_name [concurrency] [num_prompts]
# Example: google/gemma-3-4b-it 16 48
MODELS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Trim whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -n "$line" ]] && MODELS+=("$line")
done < "$MODELS_FILE"

TOTAL_MODELS=${#MODELS[@]}

if [[ $TOTAL_MODELS -eq 0 ]]; then
    print_error "No models found in $MODELS_FILE"
    exit 1
fi

print_section "vLLM Batch Benchmark Runner"
print_info "Models file: $MODELS_FILE"
print_info "Total models: $TOTAL_MODELS"
if [[ ${#RUN_ARGS[@]} -gt 0 ]]; then
    print_info "Additional arguments: ${RUN_ARGS[*]}"
fi
if [[ "$CONTINUE_ON_ERROR" == true ]]; then
    print_warn "Continue-on-error mode enabled"
fi
echo ""

# Track results
SUCCESSFUL=0
FAILED=0
FAILED_MODELS=()

# Run benchmarks
for i in "${!MODELS[@]}"; do
    MODEL_LINE="${MODELS[$i]}"
    MODEL_NUM=$((i + 1))
    
    # Parse the line: model_name [concurrency] [num_prompts]
    read -r MODEL_NAME CONCURRENCY NUM_PROMPTS <<< "$MODEL_LINE"
    
    print_section "Model $MODEL_NUM/$TOTAL_MODELS: $MODEL_NAME"
    
    # Build command with optional parameters
    CMD_ARGS=("${RUN_ARGS[@]}")
    
    # Add concurrency if specified in the file
    if [[ -n "$CONCURRENCY" ]]; then
        CMD_ARGS+=("--max-concurrency" "$CONCURRENCY")
        print_info "Concurrency: $CONCURRENCY"
    fi
    
    # Add num_prompts if specified in the file
    if [[ -n "$NUM_PROMPTS" ]]; then
        CMD_ARGS+=("--num-prompts" "$NUM_PROMPTS")
        print_info "Num prompts: $NUM_PROMPTS"
    fi
    
    # Run benchmark
    if "${RUN_SCRIPT}" "${CMD_ARGS[@]}" "$MODEL_NAME"; then
        ((SUCCESSFUL++))
        print_info "✅ Success: $MODEL_NAME"
    else
        EXIT_CODE=$?
        ((FAILED++))
        FAILED_MODELS+=("$MODEL_NAME")
        print_error "❌ Failed: $MODEL_NAME (exit code: $EXIT_CODE)"
        
        if [[ "$CONTINUE_ON_ERROR" == false ]]; then
            print_error "Stopping due to error. Use --continue-on-error to proceed."
            exit $EXIT_CODE
        fi
    fi
    
    echo ""
    
    # Add a small delay between models to ensure cleanup
    if [[ $MODEL_NUM -lt $TOTAL_MODELS ]]; then
        sleep 2
    fi
done

# Print summary
print_section "Benchmark Summary"
print_info "Total models: $TOTAL_MODELS"
print_info "Successful: $SUCCESSFUL"
if [[ $FAILED -gt 0 ]]; then
    print_error "Failed: $FAILED"
    print_error "Failed models:"
    for model in "${FAILED_MODELS[@]}"; do
        echo "  - $model"
    done
else
    print_info "Failed: 0"
fi

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

print_info "All benchmarks completed successfully! ✅"
exit 0
