#!/bin/bash

# --- Configuration ---
LOG_FILE="/tmp/gpu_kill_script.log"
DRY_RUN=false

# --- Argument Parsing ---
if [[ "$1" == "--dry-run" || "$1" == "-d" ]]; then
    DRY_RUN=true
    echo "--- DRY RUN ACTIVE: No processes will be killed ---"
fi

echo "Checking NVIDIA GPU usage with nvidia-smi..."
echo "--- $(date) ---" >> $LOG_FILE

# Use nvidia-smi to get process information and filter for PIDs
# We look for lines containing 'G ' (indicating a Graphics/Compute process)
# and use awk to extract the PID (column 1 in the query format).
PIDS=$(nvidia-smi --query-compute-apps=pid,gpu_name --format=csv,noheader | awk -F', ' '{print $1}')

if [ -z "$PIDS" ]; then
    echo "✅ No active GPU processes found."
    exit 0
fi

echo "---"

# Prepare the list for display
echo "Found the following processes using the NVIDIA GPU:"
echo "PID | GPU Name | Process Name"
echo "--------------------------------------------------------"

# Loop through each PID to get the process name and GPU name
PROCESS_LIST=""
for pid in $PIDS; do
    # Get the process name
    proc_name=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '[:space:]')
    # Get the GPU name
    gpu_name=$(nvidia-smi --query-compute-apps=pid,gpu_name --format=csv,noheader | grep "$pid" | awk -F', ' '{print $2}')
    
    if [ ! -z "$proc_name" ]; then
        PROCESS_LIST+="$pid $gpu_name $proc_name"$'\n'
        printf "%s | %s | %s\n" "$pid" "$gpu_name" "$proc_name"
    fi
done

if [ -z "$PROCESS_LIST" ]; then
    echo "✅ No running processes found to kill (PIDs were internal/fleeting)."
    exit 0
fi

echo "---"

# --- Kill or Dry-Run Execution ---

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN COMPLETE: The above processes WOULD HAVE BEEN KILLED."
    echo "Run the script without '-d' to perform the actual kill operation."
else
    # Confirmation step for actual execution
    read -r -p "Do you want to forcefully kill these processes? (y/N): " response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Attempting to kill processes..."
        # Loop through PIDs to kill them
        for pid in $PIDS; do
            if kill -9 "$pid"; then
                echo "Killed PID: $pid"
                echo "KILLED: PID $pid" >> $LOG_FILE
            else
                echo "Failed to kill PID: $pid (requires sudo or process already exited)."
                echo "FAIL: PID $pid" >> $LOG_FILE
            fi
        done
        echo "Cleanup complete."
    else
        echo "Operation cancelled by user."
    fi
fi
