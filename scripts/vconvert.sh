#!/usr/bin/env bash

# Bash Script for Batch Video Conversion
#
# This script will:
# 1. Find all video files in a specified folder.
# 2. Re-encode them using a specified codec and mode (GPU/CPU).
# 3. Log the time taken and percentage size gain for each file.
# 4. Rename the original file to "[filename]_src.[ext]".
# 5. Rename the new AV1 file to "[filename].mkv".
#
# Features:
# - Configurable Mode: --mode <gpu|cpu>
# - Configurable Codec: --codec <av1|h265>
# - Configurable Quality: --qp (GPU) or --crf (CPU)
# - Configurable Speed: --preset (CPU)
# - Dry-run mode (--dry-run)
# - Detailed logging to conversion.log

# --- Safety Net ---
# set -e: Exit immediately if a command exits with a non-zero status.
# set -u: Treat unset variables as an error.
# set -o pipefail: The return value of a pipeline is the status of the last command
#                  to exit with a non-zero status, or zero if no command failed.
set -euo pipefail

# --- Easy Configuration ---
# Set your defaults here
DEFAULT_ENCODER_MODE="gpu"  # "gpu" or "cpu"
DEFAULT_VIDEO_CODEC="av1"   # "av1" or "h265"
DEFAULT_GPU_QP="30"         # GPU Quality (lower is better)
DEFAULT_CPU_CRF="30"        # CPU Quality (lower is better)
DEFAULT_CPU_PRESET="8"      # CPU Speed (CPU AV1: 0-13, fast: 8-10. CPU H.265: ultrafast, superfast, fast, medium, slow)
DEFAULT_KEYFRAME_INTERVAL="240"  # Keyframe interval in frames (240 = ~4-8 seconds at 30-60fps)

# --- Internal Variables ---
DRY_RUN=false
BACKGROUND=false
STATUS_ONLY=false
STOP_PROCESS=false
REENCODE_AUDIO=false
FOLDER_PATH=""
# Set runtime values from defaults
ENCODER_MODE=$DEFAULT_ENCODER_MODE
VIDEO_CODEC=$DEFAULT_VIDEO_CODEC
GPU_QP=$DEFAULT_GPU_QP
CPU_CRF=$DEFAULT_CPU_CRF
CPU_PRESET=$DEFAULT_CPU_PRESET
KEYFRAME_INTERVAL=$DEFAULT_KEYFRAME_INTERVAL

# --- Terminal Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Help Function ---
print_usage() {
    echo -e "${CYAN}Usage: $0 [options] <folder_path>${NC}"
    echo ""
    echo "This script batch re-encodes video files in <folder_path>."
    echo ""
    echo -e "${YELLOW}Shortcut Modes:${NC}"
    echo "  --best            Alias for: --mode cpu --codec h265 --crf 28 --preset slow"
    echo "  --medium          Alias for: --mode cpu --codec av1 --crf 28 --preset 8"
    echo "  --fast            Alias for: --mode gpu --codec av1 --qp 30"
    echo ""
    echo -e "${YELLOW}Manual Options:${NC}"
    echo "  --mode <gpu|cpu>    Encoder mode (default: $DEFAULT_ENCODER_MODE)"
    echo "  --codec <av1|h265>  Video codec (default: $DEFAULT_VIDEO_CODEC)"
    echo "  --qp <value>        GPU Quantization Parameter (default: $DEFAULT_GPU_QP). Lower is higher quality."
    echo "  --crf <value>       CPU Constant Rate Factor (default: $DEFAULT_CPU_CRF). Lower is higher quality."
    echo "  --preset <value>    CPU speed preset (default: $DEFAULT_CPU_PRESET). Higher is faster for AV1."
    echo "  --keyframe <value>  Keyframe interval in frames (default: $DEFAULT_KEYFRAME_INTERVAL). Lower = more seekable, larger file."
    echo "  --dry-run           Show what actions would be taken without encoding or moving files."
    echo ""
    echo -e "${YELLOW}Background Options:${NC}"
    echo "  --background        Run in background (detached). Creates a PID file for monitoring."
    echo "  --status            Display current conversion status and progress."
    echo "  --stop              Stop a running background conversion process."
    echo ""
    echo -e "${YELLOW}Other:${NC}"
    echo "  -h, --help          Show this help message."
}

# --- Helper Function for Parsing Quality/Preset ---
parse_numeric_arg() {
    local arg_name="$1"
    local arg_value="$2"
    if [[ -z "$arg_value" || "$arg_value" == -* ]]; then
        echo -e "${RED}Error: $arg_name option requires a numeric value.${NC}" >&2
        exit 1
    fi
    if ! [[ "$arg_value" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: $arg_name value must be an integer.${NC}" >&2
        exit 1
    fi
}

# --- Parameter Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        # --- Shortcut Flags ---
        --best)
            ENCODER_MODE="cpu"
            VIDEO_CODEC="h265"
            CPU_CRF="28"
            CPU_PRESET="slow"
            shift
            ;;
        --medium)
            ENCODER_MODE="cpu"
            VIDEO_CODEC="av1"
            CPU_CRF="28"
            CPU_PRESET="8"
            shift
            ;;
        --fast)
            ENCODER_MODE="gpu"
            VIDEO_CODEC="av1"
            GPU_QP="30"
            shift
            ;;
        
        # --- Manual Flags ---
        --mode)
            if [[ "$2" != "gpu" && "$2" != "cpu" ]]; then
                echo -e "${RED}Error: --mode must be 'gpu' or 'cpu'.${NC}" >&2
                exit 1
            fi
            ENCODER_MODE="$2"
            shift 2
            ;;
        --codec)
            if [[ "$2" != "av1" && "$2" != "h265" ]]; then
                echo -e "${RED}Error: --codec must be 'av1' or 'h265'.${NC}" >&2
                exit 1
            fi
            VIDEO_CODEC="$2"
            shift 2
            ;;
        --qp)
            parse_numeric_arg "--qp" "$2"
            GPU_QP="$2"
            shift 2
            ;;
        --crf)
            parse_numeric_arg "--crf" "$2"
            CPU_CRF="$2"
            shift 2
            ;;
        --preset)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo -e "${RED}Error: --preset option requires a value (e.g., '8' or 'slow').${NC}" >&2
                exit 1
            fi
            CPU_PRESET="$2"
            shift 2
            ;;
        --keyframe)
            parse_numeric_arg "--keyframe" "$2"
            KEYFRAME_INTERVAL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --background)
            BACKGROUND=true
            shift
            ;;
        --status)
            STATUS_ONLY=true
            shift
            ;;
        --stop)
            STOP_PROCESS=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            print_usage
            exit 1
            ;;
        *)
            if [[ -n "$FOLDER_PATH" ]]; then
                echo -e "${RED}Error: Only one folder path can be specified.${NC}" >&2
                print_usage
                exit 1
            fi
            FOLDER_PATH="$1"
            shift
            ;;
    esac
done

# --- Validation ---
if [[ -z "$FOLDER_PATH" ]]; then
    echo -e "${RED}Error: No folder path provided.${NC}" >&2
    print_usage
    exit 1
fi
if [[ ! -d "$FOLDER_PATH" ]]; then
    echo -e "${RED}Error: Folder not found: $FOLDER_PATH${NC}" >&2
    exit 1
fi
FOLDER_PATH=$(realpath "$FOLDER_PATH")
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: ffmpeg is not installed or not in your PATH.${NC}" >&2
    exit 1
fi

# --- Define Status and Control Files ---
PID_FILE="$FOLDER_PATH/.vconvert.pid"
STATUS_FILE="$FOLDER_PATH/.vconvert.status"
OUTPUT_LOG="$FOLDER_PATH/vconvert_output.log"

# --- Setup Config String ---
CONFIG_STRING="Mode: $ENCODER_MODE | Codec: $VIDEO_CODEC"
if [ "$ENCODER_MODE" = "gpu" ]; then
    CONFIG_STRING+=" | Quality (QP): $GPU_QP"
else
    CONFIG_STRING+=" | Quality (CRF): $CPU_CRF | Preset: $CPU_PRESET"
fi

# --- Handle Stop Request ---
if [ "$STOP_PROCESS" = true ]; then
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}No conversion process is currently running for: $FOLDER_PATH${NC}"
        exit 0
    fi
    
    PID=$(cat "$PID_FILE")
    if ! kill -0 "$PID" 2>/dev/null; then
        echo -e "${YELLOW}Process $PID is not running (stale PID file).${NC}"
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo -e "${YELLOW}Stopping conversion process (PID: $PID)...${NC}"
    if kill "$PID" 2>/dev/null; then
        echo -e "${GREEN}Process stopped successfully.${NC}"
        # Give it a moment to clean up
        sleep 1
        # Clean up PID file if process is gone
        if ! kill -0 "$PID" 2>/dev/null; then
            rm -f "$PID_FILE" "$STATUS_FILE"
        fi
    else
        echo -e "${RED}Failed to stop process $PID${NC}"
        exit 1
    fi
    exit 0
fi

# --- Handle Status Request ---
if [ "$STATUS_ONLY" = true ]; then
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}No conversion process is currently running for: $FOLDER_PATH${NC}"
        exit 0
    fi
    
    PID=$(cat "$PID_FILE")
    if ! kill -0 "$PID" 2>/dev/null; then
        echo -e "${YELLOW}Process $PID is not running (stale PID file).${NC}"
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo -e "${CYAN}=== Conversion Status ===${NC}"
    echo -e "Process ID: ${GREEN}$PID${NC} (running)"
    echo -e "Folder: $FOLDER_PATH"
    echo ""
    
    if [ -f "$STATUS_FILE" ]; then
        echo -e "${CYAN}Current Progress:${NC}"
        cat "$STATUS_FILE"
    else
        echo -e "${YELLOW}No status file found yet.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Recent output (last 20 lines):${NC}"
    if [ -f "$OUTPUT_LOG" ]; then
        tail -n 20 "$OUTPUT_LOG"
    else
        echo -e "${YELLOW}No output log found yet.${NC}"
    fi
    
    echo ""
    echo -e "To stop: ${YELLOW}$0 --stop $FOLDER_PATH${NC}"
    echo -e "Full log: ${YELLOW}tail -f $OUTPUT_LOG${NC}"
    exit 0
fi

# --- Handle Background Mode ---
if [ "$BACKGROUND" = true ]; then
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo -e "${RED}Error: A conversion is already running for this folder (PID: $OLD_PID)${NC}"
            echo -e "Use ${YELLOW}$0 --status $FOLDER_PATH${NC} to check progress"
            echo -e "Or ${YELLOW}kill $OLD_PID${NC} to stop it"
            exit 1
        else
            echo -e "${YELLOW}Removing stale PID file...${NC}"
            rm -f "$PID_FILE"
        fi
    fi
    
    echo -e "${GREEN}Starting conversion in background...${NC}"
    echo -e "Folder: $FOLDER_PATH"
    echo -e "Config: $CONFIG_STRING"
    echo ""
    
    # Run this script again without --background flag
    ARGS=()
    if [ "$ENCODER_MODE" != "$DEFAULT_ENCODER_MODE" ]; then
        ARGS+=("--mode" "$ENCODER_MODE")
    fi
    if [ "$VIDEO_CODEC" != "$DEFAULT_VIDEO_CODEC" ]; then
        ARGS+=("--codec" "$VIDEO_CODEC")
    fi
    if [ "$ENCODER_MODE" = "gpu" ] && [ "$GPU_QP" != "$DEFAULT_GPU_QP" ]; then
        ARGS+=("--qp" "$GPU_QP")
    fi
    if [ "$ENCODER_MODE" = "cpu" ]; then
        if [ "$CPU_CRF" != "$DEFAULT_CPU_CRF" ]; then
            ARGS+=("--crf" "$CPU_CRF")
        fi
        if [ "$CPU_PRESET" != "$DEFAULT_CPU_PRESET" ]; then
            ARGS+=("--preset" "$CPU_PRESET")
        fi
    fi
    ARGS+=("$FOLDER_PATH")
    
    nohup "$0" "${ARGS[@]}" > "$OUTPUT_LOG" 2>&1 &
    BG_PID=$!
    echo "$BG_PID" > "$PID_FILE"
    
    echo -e "${GREEN}Background process started with PID: $BG_PID${NC}"
    echo -e "Check status: ${YELLOW}$0 --status $FOLDER_PATH${NC}"
    echo -e "View output: ${YELLOW}tail -f $OUTPUT_LOG${NC}"
    echo -e "Stop process: ${YELLOW}kill $BG_PID${NC}"
    exit 0
fi

# --- Foreground Execution: Write PID for monitoring ---
echo $$ > "$PID_FILE"
trap "rm -f $PID_FILE $STATUS_FILE" EXIT

# --- Setup Log File & Info ---
LOG_FILE="$FOLDER_PATH/conversion.log"

if [ "$DRY_RUN" = false ]; then
    echo "--- Video Conversion Log ---" > "$LOG_FILE"
    echo "Run started: $(date)" >> "$LOG_FILE"
    echo "Using config: $CONFIG_STRING" >> "$LOG_FILE"
    echo "--------------------------" >> "$LOG_FILE"
    
    # Create summary file header
    SUMMARY_FILE="$FOLDER_PATH/conversion_summary.log"
    echo "=== Video Conversion Summary ===" > "$SUMMARY_FILE"
    echo "Run started: $(date)" >> "$SUMMARY_FILE"
    echo "Config: $CONFIG_STRING" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    printf "%-50s | %-10s | %10s | %15s -> %-15s | %8s\n" "File" "Status" "Duration" "Size Before" "Size After" "Delta %" >> "$SUMMARY_FILE"
    printf "%.s-" {1..130} >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
else
    echo -e "${YELLOW}--- DRY RUN MODE ENABLED ---${NC}"
    echo "No files will be changed. Log will not be written."
    echo "Target Folder: $FOLDER_PATH"
    echo "Using config: $CONFIG_STRING"
    echo "-------------------------------------"
fi

# --- Main Processing Loop ---
# Define video file extensions to process (single source of truth)
VIDEO_EXTENSIONS=(-iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.vid")

# Create 'done' subdirectory if it doesn't exist
DONE_DIR="$FOLDER_PATH/done"
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$DONE_DIR"
fi

# Count total files to process
TOTAL_FILES=$(find "$FOLDER_PATH" -maxdepth 1 -type f \( "${VIDEO_EXTENSIONS[@]}" \) ! -name "*_src.*" ! -name "*_av1.*" | wc -l)

PROCESSED=0
SUCCEEDED=0
FAILED=0

echo "Found $TOTAL_FILES video(s) to process."

# Find common video files in the specified folder, but not in subfolders (-maxdepth 1).
# Using -print0 and read -d '' to safely handle filenames with spaces.
find "$FOLDER_PATH" -maxdepth 1 -type f \( "${VIDEO_EXTENSIONS[@]}" \) -print0 | while IFS= read -r -d '' source_file; do

    # Extract file components
    base_name=$(basename "$source_file")
    dir_name=$(dirname "$source_file")
    filename_no_ext="${base_name%.*}"
    extension="${base_name##*.}"

    # Skip files that are already processed (e.g., "_src" or "_av1")
    if [[ "$filename_no_ext" == *_src || "$filename_no_ext" == *_av1 ]]; then
        echo -e "${BLUE}Skipping already processed file: $base_name${NC}"
        continue
    fi
    
    # Check if a _src version of this file already exists (means it was already processed)
    potential_src_file="${dir_name}/${filename_no_ext}_src.${extension}"
    if [ -f "$potential_src_file" ]; then
        echo -e "${YELLOW}Skipping $base_name - already processed (found ${filename_no_ext}_src.${extension})${NC}"
        continue
    fi
    
    # Increment processed counter
    PROCESSED=$((PROCESSED + 1))
    
    # Update status file
    {
        echo "Progress: $PROCESSED / $TOTAL_FILES files"
        echo "Succeeded: $SUCCEEDED"
        echo "Failed: $FAILED"
        echo "Current: $base_name"
        echo "Last updated: $(date)"
    } > "$STATUS_FILE"
    
    # Define output file names
    # We use _av1.mkv as a temp name during encoding for simplicity.
    temp_output_name="${dir_name}/${filename_no_ext}_av1.mkv"
    # Final output uses the same extension as the source file
    final_output_name="${dir_name}/${filename_no_ext}.${extension}"
    final_source_name="${dir_name}/${filename_no_ext}_src.${extension}"

    echo -e "\n${CYAN}Processing: $base_name${NC}"
    echo -e "  Config: ($CONFIG_STRING)"

    # --- Build FFmpeg Command Dynamically ---
    ffmpeg_command=("ffmpeg" "-y" "-nostdin") # Use an array for safe arg handling, -y and -nostdin must be before input

    if [ "$ENCODER_MODE" = "gpu" ]; then
        ffmpeg_command+=("-hwaccel" "vaapi" "-hwaccel_output_format" "vaapi")
        ffmpeg_command+=("-i" "$source_file")
        if [ "$VIDEO_CODEC" = "av1" ]; then
            ffmpeg_command+=("-c:v" "av1_vaapi" "-qp" "$GPU_QP")
        else # h265
            ffmpeg_command+=("-c:v" "hevc_vaapi" "-qp" "$GPU_QP")
        fi
    else # cpu
        ffmpeg_command+=("-i" "$source_file")
        if [ "$VIDEO_CODEC" = "av1" ]; then
            ffmpeg_command+=("-c:v" "libsvtav1" "-crf" "$CPU_CRF" "-preset" "$CPU_PRESET")
        else # h265
            ffmpeg_command+=("-c:v" "libx265" "-crf" "$CPU_CRF" "-preset" "$CPU_PRESET")
        fi
    fi
    
    # Add keyframe interval for better seeking (requires full frame every N frames)
    ffmpeg_command+=("-g" "$KEYFRAME_INTERVAL")
    
    # Force 8-bit color for maximum compatibility with players and hardware decoders
    ffmpeg_command+=("-pix_fmt" "yuv420p")
    
    # Add audio copy and output flags
    ffmpeg_command+=("-c:a" "copy" "-loglevel" "error" "$temp_output_name")

    # --- Dry Run Logic ---
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would run: ${ffmpeg_command[*]}"
        echo "  [DRY RUN] Would rename source to: $final_source_name"
        echo "  [DRY RUN] Would rename output to: $final_output_name"
        continue
    fi

    # --- Real Run Logic ---
    echo "  Encoding..."
    start_time=$(date +%s)
    original_size_bytes=$(stat -c%s "$source_file")
    
    # Log the ffmpeg command
    echo "[$(date)] COMMAND: ${ffmpeg_command[*]}" >> "$LOG_FILE"
    
    # Try with audio copy first
    if ! "${ffmpeg_command[@]}" 2>/dev/null; then
        echo -e "${YELLOW}  Audio copy failed, retrying with audio re-encoding...${NC}"
        rm -f "$temp_output_name" # Clean up partial file
        
        # Rebuild command with audio re-encoding instead of copy
        ffmpeg_command_reencode=("${ffmpeg_command[@]}")
        # Find and replace -c:a copy with -c:a aac -b:a 192k
        for i in "${!ffmpeg_command_reencode[@]}"; do
            if [[ "${ffmpeg_command_reencode[$i]}" == "-c:a" ]]; then
                ffmpeg_command_reencode[$((i+1))]="aac"
                # Insert audio bitrate after aac
                ffmpeg_command_reencode=("${ffmpeg_command_reencode[@]:0:$((i+2))}" "-b:a" "192k" "${ffmpeg_command_reencode[@]:$((i+2))}")
                break
            fi
        done
        
        # Log the retry command with audio re-encoding
        echo "[$(date)] RETRY COMMAND (with audio re-encode): ${ffmpeg_command_reencode[*]}" >> "$LOG_FILE"
        
        if ! "${ffmpeg_command_reencode[@]}"; then
            echo -e "${RED}  ERROR: FFmpeg failed to encode $base_name (even with audio re-encoding).${NC}"
            echo "[$(date)] ERROR: FFmpeg failed on $base_name ($CONFIG_STRING)" >> "$LOG_FILE"
            
            # Add to summary file
            original_size_hr=$(numfmt --to=iec --suffix=B $original_size_bytes)
            printf "%-50s | %-10s | %10s | %15s -> %-15s | %7s\n" \
                "${base_name:0:50}" "FAILED" "-" "$original_size_hr" "-" "-" >> "$SUMMARY_FILE"
            
            FAILED=$((FAILED + 1))
            rm -f "$temp_output_name" # Clean up partial file
            continue
        fi
        echo -e "${YELLOW}  Note: Audio was re-encoded due to stream compatibility issues${NC}"
    fi

    # FFmpeg succeeded, gather stats
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Check if new file was created and has size
    if [ ! -f "$temp_output_name" ] || [ ! -s "$temp_output_name" ]; then
        echo -e "${RED}  ERROR: FFmpeg reported success but output file is missing or empty: $temp_output_name${NC}"
        echo "[$(date)] ERROR: FFmpeg reported success but output file is missing or empty $base_name" >> "$LOG_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    new_size_bytes=$(stat -c%s "$temp_output_name")

    # Calculate size gain
    size_gain_percent="0.00"
    if [ "$original_size_bytes" -gt 0 ]; then
        size_gain_percent=$(awk "BEGIN {printf \"%.2f\", (1 - $new_size_bytes / $original_size_bytes) * 100}")
    fi
    
    original_size_hr=$(numfmt --to=iec --suffix=B $original_size_bytes)
    new_size_hr=$(numfmt --to=iec --suffix=B $new_size_bytes)

    # Check if new file is actually smaller than original
    if [ "$new_size_bytes" -ge "$original_size_bytes" ]; then
        echo -e "${YELLOW}  WARNING: Encoded file is NOT smaller than original!${NC}"
        echo -e "${YELLOW}  Original: $original_size_hr | Encoded: $new_size_hr${NC}"
        echo -e "${YELLOW}  Keeping original file, removing encoded version.${NC}"
        
        # Log the issue
        echo "[$(date)] SKIPPED: $base_name | Time: ${duration}s | Size: ${original_size_bytes}B -> ${new_size_bytes}B | No size reduction" >> "$LOG_FILE"
        
        # Add to summary file as SKIPPED
        printf "%-50s | %-10s | %10s | %15s -> %-15s | %7s%%\n" \
            "${base_name:0:50}" "SKIPPED" "${duration}s" "$original_size_hr" "$new_size_hr" "$size_gain_percent" >> "$SUMMARY_FILE"
        
        # Remove the encoded file since it's not beneficial
        rm -f "$temp_output_name"
        
        # Don't increment SUCCEEDED, but don't count as FAILED either
        continue
    fi
    
    echo -e "${GREEN}  Success!${NC} Time: ${duration}s. Size: $original_size_hr -> $new_size_hr (${size_gain_percent}% gain)"

    # Log to file
    echo "[$(date)] SUCCESS: $base_name | Time: ${duration}s | Size: ${original_size_bytes}B -> ${new_size_bytes}B | Gain: ${size_gain_percent}%" >> "$LOG_FILE"
    
    # Add to summary file
    printf "%-50s | %-10s | %10s | %15s -> %-15s | %7s%%\n" \
        "${base_name:0:50}" "SUCCESS" "${duration}s" "$original_size_hr" "$new_size_hr" "$size_gain_percent" >> "$SUMMARY_FILE"
    
    # Increment success counter
    SUCCEEDED=$((SUCCEEDED + 1))

    # --- The File "Dance" ---
    # 1. Rename the original source file
    echo "  Renaming source to: $final_source_name"
    mv "$source_file" "$final_source_name"

    # 2. Rename the new AV1 file to its final name
    echo "  Renaming output to: $final_output_name"
    mv "$temp_output_name" "$final_output_name"
    
    # 3. Move both files to done directory
    echo "  Moving files to done/"
    mv "$final_source_name" "$DONE_DIR/"
    mv "$final_output_name" "$DONE_DIR/"

done

echo -e "\n${GREEN}--- All tasks complete. ---${NC}"
if [ "$DRY_RUN" = false ]; then
    echo "Log file written to: $LOG_FILE"
    
    # Add final summary to summary file
    echo "" >> "$SUMMARY_FILE"
    printf "%.s-" {1..130} >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "=== Final Summary ===" >> "$SUMMARY_FILE"
    echo "Run completed: $(date)" >> "$SUMMARY_FILE"
    echo "Total files processed: $PROCESSED" >> "$SUMMARY_FILE"
    echo "Successful conversions: $SUCCEEDED" >> "$SUMMARY_FILE"
    echo "Failed conversions: $FAILED" >> "$SUMMARY_FILE"
    
    echo ""
    echo -e "${CYAN}Summary table written to: $SUMMARY_FILE${NC}"
    
    # Handle summary file in done directory
    DONE_SUMMARY="$DONE_DIR/conversion_summary.log"
    if [ -f "$DONE_SUMMARY" ]; then
        # Append to existing summary in done/
        echo "" >> "$DONE_SUMMARY"
        echo "" >> "$DONE_SUMMARY"
        echo "========================================" >> "$DONE_SUMMARY"
        echo "" >> "$DONE_SUMMARY"
        cat "$SUMMARY_FILE" >> "$DONE_SUMMARY"
        echo -e "${CYAN}Summary appended to: $DONE_SUMMARY${NC}"
    else
        # Copy summary to done/ for the first time
        cp "$SUMMARY_FILE" "$DONE_SUMMARY"
        echo -e "${CYAN}Summary copied to: $DONE_SUMMARY${NC}"
    fi
fi
