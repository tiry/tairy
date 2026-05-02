#!/bin/bash

# --- Build directories ---
ROCM_BUILD_DIR="/home/tiry/llama.cpp/build-rocm"
VULKAN_BUILD_DIR="/home/tiry/llama.cpp/build-vulkan"
CUDA_BUILD_DIR="/home/tiry/llama.cpp/build-cuda"

# --- Defaults ---
DEFAULT_BACKEND="rocm"
MODEL_PATH="/home/tiry/models/Qwen3-Coder-Next-UD-Q8_K_XL/UD-Q8_K_XL/Qwen3-Coder-Next-UD-Q8_K_XL-00001-of-00003.gguf"
BACKEND="$DEFAULT_BACKEND"
PROMPT=""
INTERACTIVE=false
SERVER_MODE=false
TEST_MODE=false
CHECK_CTX=""
SERVER_PORT=8080

# APU-optimized defaults
USE_MMAP=false
KV_TYPE="q8_0"
CTX_SIZE=262144

# Test mode: VRAM to leave for OS / compositor / other apps.
MARGIN_MIB=2048

# Two probe sizes for linear extrapolation of KV cache cost per token.
# Both must comfortably fit on any reasonable model.
PROBE_A_CTX=2048
PROBE_B_CTX=32768

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Backend / model:
  -b <cuda|rocm|vulkan>    backend build to use (default: $DEFAULT_BACKEND)
  -m <path>                model path (default: $MODEL_PATH)

Mode (pick one; default is interactive):
  --server                 run llama-server
  --port <n>               server port (default: $SERVER_PORT)
  -i                       force interactive (conversation) mode
  -p "<prompt>"            single-shot prompt
  -t [<ctx>]               test mode: compute the maximum context that
                           fits in (total VRAM - margin) for the current
                           KV quantization. If <ctx> is given, also check
                           whether that specific size fits.

Tuning:
  -c <ctx>                 context size (default: $CTX_SIZE)
  --mmap                   enable mmap (default: off)
  --f16-kv                 use f16 KV cache (default: $KV_TYPE)
  --margin <MiB>           VRAM to reserve in test mode (default: $MARGIN_MIB)

  -h, --help               show this help
EOF
}

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --server)   SERVER_MODE=true; shift ;;
    --port)     SERVER_PORT="$2"; shift 2 ;;
    -b)         BACKEND="$2"; shift 2 ;;
    -m)         MODEL_PATH="$2"; shift 2 ;;
    -p)         PROMPT="$2"; shift 2 ;;
    -i)         INTERACTIVE=true; shift ;;
    -c)         CTX_SIZE="$2"; shift 2 ;;
    -t)
                TEST_MODE=true
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    CHECK_CTX="$2"
                    shift 2
                else
                    shift
                fi
                ;;
    --mmap)     USE_MMAP=true; shift ;;
    --f16-kv)   KV_TYPE="f16"; shift ;;
    --margin)   MARGIN_MIB="$2"; shift 2 ;;
    -h|--help)  print_usage; exit 0 ;;
    *)          echo "Unknown argument: $1" >&2; print_usage; exit 1 ;;
  esac
done

# --- Resolve build dir ---
case "$BACKEND" in
    cuda)   BUILD_DIR="$CUDA_BUILD_DIR" ;;
    rocm)   BUILD_DIR="$ROCM_BUILD_DIR" ;;
    vulkan) BUILD_DIR="$VULKAN_BUILD_DIR" ;;
    *)      echo "Error: invalid backend '$BACKEND' (use cuda, rocm, or vulkan)" >&2; exit 1 ;;
esac

resolve_bin() {
    local name="$1"
    if   [ -x "${BUILD_DIR}/bin/${name}" ]; then echo "${BUILD_DIR}/bin/${name}"
    elif [ -x "${BUILD_DIR}/${name}"     ]; then echo "${BUILD_DIR}/${name}"
    else echo ""
    fi
}

# --- Validate model ---
if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: model file not found: $MODEL_PATH" >&2
    exit 1
fi

# =================================================================
# TEST MODE: solve for max ctx via two probes + linear extrapolation
# =================================================================
# llama-fit-params prints "projected to use N MiB of device memory"
# for any (-c, -ctk, -ctv, -ngl) combo without loading the model.
# Memory is linear in ctx:    proj(ctx) = baseline + per_token * ctx
# Two probes are enough to solve for both terms, then:
#   max_ctx = (TotalVRAM - margin - baseline) / per_token
# This sidesteps llama-fit-params' built-in fit logic entirely, which
# compares against *free* memory — wrong on shared-RAM APUs.
# =================================================================
if [ "$TEST_MODE" = true ]; then
    FIT_EXE=$(resolve_bin "llama-fit-params")
    if [ -z "$FIT_EXE" ]; then
        echo "Error: llama-fit-params not found in $BUILD_DIR" >&2
        exit 1
    fi

    echo "=== Memory Capacity Analysis ==="
    echo "  Backend:  $BACKEND  ($BUILD_DIR)"
    echo "  Model:    $MODEL_PATH"
    echo "  KV type:  $KV_TYPE"
    echo "  Margin:   $MARGIN_MIB MiB"
    echo "-----------------------------------"

    run_probe() {
        local ctx="$1"
        local log
        log=$(mktemp)
        "$FIT_EXE" \
            -m   "$MODEL_PATH" \
            -ngl 999 \
            -c   "$ctx" \
            -ctk "$KV_TYPE" \
            -ctv "$KV_TYPE" \
            --fit off > "$log" 2>&1 || true
        local proj total
        proj=$( grep -oP 'projected to use\s+\K\d+' "$log" | head -n1)
        total=$(grep -oP 'Total VRAM:\s+\K\d+'      "$log" | head -n1)
        rm -f "$log"
        [ -z "$proj" ] && return 1
        echo "$proj ${total:-0}"
    }

    echo "Probing memory footprint at two context sizes..."
    READ_A=$(run_probe "$PROBE_A_CTX") || { echo "Error: probe at ctx=$PROBE_A_CTX failed" >&2; exit 2; }
    READ_B=$(run_probe "$PROBE_B_CTX") || { echo "Error: probe at ctx=$PROBE_B_CTX failed" >&2; exit 2; }
    read PROJ_A TOTAL_VRAM <<< "$READ_A"
    read PROJ_B _          <<< "$READ_B"

    if ! [[ "$PROJ_A" =~ ^[0-9]+$ ]] || ! [[ "$PROJ_B" =~ ^[0-9]+$ ]] || ! [[ "$TOTAL_VRAM" =~ ^[0-9]+$ ]]; then
        echo "Error: could not parse memory values from llama-fit-params output" >&2
        exit 2
    fi

    printf "  ctx=%-7d -> %d MiB projected\n" "$PROBE_A_CTX" "$PROJ_A"
    printf "  ctx=%-7d -> %d MiB projected\n" "$PROBE_B_CTX" "$PROJ_B"
    echo "-----------------------------------"

    # Linear model: proj = baseline + per_token_mib * ctx
    PER_TOKEN_MIB=$(awk "BEGIN { printf \"%.8f\", ($PROJ_B - $PROJ_A) / ($PROBE_B_CTX - $PROBE_A_CTX) }")
    BASELINE_MIB=$( awk "BEGIN { printf \"%.2f\", $PROJ_A - $PER_TOKEN_MIB * $PROBE_A_CTX }")
    PER_TOKEN_KIB=$(awk "BEGIN { printf \"%.2f\", $PER_TOKEN_MIB * 1024 }")

    USABLE=$(( TOTAL_VRAM - MARGIN_MIB ))
    MAX_CTX=$(awk "BEGIN { printf \"%d\", ($USABLE - $BASELINE_MIB) / $PER_TOKEN_MIB }")

    printf "  Total device VRAM:        %6d MiB\n" "$TOTAL_VRAM"
    printf "  Reserved margin:          %6d MiB\n" "$MARGIN_MIB"
    printf "  Usable VRAM:              %6d MiB\n" "$USABLE"
    echo "-----------------------------------"
    printf "  Model + compute (fixed):  %s MiB\n" "$BASELINE_MIB"
    printf "  KV cache per token:       %s KiB  (%s)\n" "$PER_TOKEN_KIB" "$KV_TYPE"
    echo "-----------------------------------"
    printf "  ==> Max context size:     %d tokens\n" "$MAX_CTX"

    EXIT_CODE=0
    if [ -n "$CHECK_CTX" ]; then
        echo "-----------------------------------"
        PROJ_CHECK=$(awk "BEGIN { printf \"%.0f\", $BASELINE_MIB + $PER_TOKEN_MIB * $CHECK_CTX }")
        HEADROOM=$(( USABLE - PROJ_CHECK ))
        printf "  Requested ctx:            %d tokens\n" "$CHECK_CTX"
        printf "  Projected use at ctx:     %d MiB\n"     "$PROJ_CHECK"
        if [ "$HEADROOM" -ge 0 ]; then
            printf "  Headroom:                 %d MiB\n" "$HEADROOM"
            echo "  RESULT: [PASS]"
        else
            printf "  Over by:                  %d MiB\n" $(( -HEADROOM ))
            echo "  RESULT: [FAIL]"
            EXIT_CODE=1
        fi
    fi

    exit $EXIT_CODE
fi

# =================================================================
# RUN MODE: server / prompt / interactive
# =================================================================
if [ "$SERVER_MODE" = true ]; then
    EXE_NAME="llama-server"
else
    EXE_NAME="llama-cli"
fi

EXE_PATH=$(resolve_bin "$EXE_NAME")
if [ -z "$EXE_PATH" ]; then
    echo "Error: $EXE_NAME not found in $BUILD_DIR" >&2
    exit 1
fi

CMD_ARGS=(
    -m "$MODEL_PATH"
    -ngl 999
    --ctx-size "$CTX_SIZE"
    -ctk "$KV_TYPE"
    -ctv "$KV_TYPE"
)
[ "$USE_MMAP" = false ] && CMD_ARGS+=("--no-mmap")

if [ "$SERVER_MODE" = true ]; then
    CMD_ARGS+=(--host 0.0.0.0 --port "$SERVER_PORT" --jinja)
elif [ "$INTERACTIVE" = true ] || [ -z "$PROMPT" ]; then
    CMD_ARGS+=(-cnv)
else
    CMD_ARGS+=(-p "$PROMPT")
fi

echo "Backend: $BACKEND"
echo "Running: $EXE_PATH ${CMD_ARGS[*]}"
echo
exec "$EXE_PATH" "${CMD_ARGS[@]}"