
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1119_004A_DEBUG_MODE="${T1119_004A_DEBUG_MODE:-false}"
    export T1119_004A_TIMEOUT="${T1119_004A_TIMEOUT:-300}"
    export T1119_004A_FALLBACK_MODE="${T1119_004A_FALLBACK_MODE:-real}"
    export T1119_004A_OUTPUT_FORMAT="${T1119_004A_OUTPUT_FORMAT:-json}"
    export T1119_004A_POLICY_CHECK="${T1119_004A_POLICY_CHECK:-true}"
    export T1119_004A_MAX_FILES="${T1119_004A_MAX_FILES:-200}"
    export T1119_004A_MAX_FILE_SIZE="${T1119_004A_MAX_FILE_SIZE:-1048576}"
    export T1119_004A_SCAN_DEPTH="${T1119_004A_SCAN_DEPTH:-3}"
    export T1119_004A_EXCLUDE_CACHE="${T1119_004A_EXCLUDE_CACHE:-true}"
    export T1119_004A_CAPTURE_DURATION="${T1119_004A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1119.004a - Automated Collection: Running Processes Dump Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Automatically dump running process information ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat ps; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1119_004A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

Load-EnvironmentVariables() {
    export T1119_004A_OUTPUT_BASE="${T1119_004A_OUTPUT_BASE:-./mitre_results}"
    export T1119_004A_TIMEOUT="${T1119_004A_TIMEOUT:-300}"
    export T1119_004A_OUTPUT_MODE="${T1119_004A_OUTPUT_MODE:-simple}"
    export T1119_004A_SILENT_MODE="${T1119_004A_SILENT_MODE:-false}"
    export T1119_004A_MAX_PROCESSES="${T1119_004A_MAX_PROCESSES:-500}"
    
    export T1119_004A_PROCESS_FILTERS="${T1119_004A_PROCESS_FILTERS:-all}"
    export T1119_004A_INCLUDE_THREADS="${T1119_004A_INCLUDE_THREADS:-false}"
    export T1119_004A_INCLUDE_ENVIRONMENT="${T1119_004A_INCLUDE_ENVIRONMENT:-false}"
    export T1119_004A_INCLUDE_CMDLINE="${T1119_004A_INCLUDE_CMDLINE:-true}"
    export T1119_004A_OUTPUT_FORMAT="${T1119_004A_OUTPUT_FORMAT:-text}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1119_004A_OUTPUT_BASE" ]] && { [[ "${T1119_004A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1119_004A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1119_004A_OUTPUT_BASE")" ]] && { [[ "${T1119_004A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1119_004A_OUTPUT_BASE/T1119_004a_process_dump_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{process_dumps,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Dump-RunningProcesses() {
    local collection_dir="$1"
    
    local dump_file="$collection_dir/process_dumps/processes_dump_$(date +%s).txt"
    
    {
        echo "RUNNING PROCESSES DUMP "
        echo "Timestamp: $(date)"
        echo ""
        
        echo "--- PROCESS LIST ---"
        if [[ "$T1119_004A_INCLUDE_CMDLINE" == "true" ]]; then
            ps aux | head -${T1119_004A_MAX_PROCESSES:-500}
        else
            ps -eo pid,ppid,user,comm,state | head -${T1119_004A_MAX_PROCESSES:-500}
        fi
        echo ""
        
        if [[ "$T1119_004A_INCLUDE_THREADS" == "true" ]]; then
            echo "--- THREADS ---"
            ps -eLf | head -100
            echo ""
        fi
        
        echo "--- PROCESS TREE ---"
        pstree -p 2>/dev/null || ps f
        echo ""
        
        echo "--- SYSTEM LOAD ---"
        uptime
        cat /proc/loadavg
        
    } > "$dump_file"
    
    if [[ -f "$dump_file" && -s "$dump_file" ]]; then
        local file_size=$(stat -c%s "$dump_file" 2>/dev/null || echo 0)
        echo "$dump_file:$file_size"
        [[ "$T1119_004A_SILENT_MODE" != "true" ]] && echo "  + Dumped: Process information ($file_size bytes)" >&2
        return 0
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1119_004A_SILENT_MODE is true
    [[ "$T1119_004A_SILENT_MODE" != "true" && "${T1119_004A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "PROCESS DUMP "
    echo "Dumps: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1119.004a",
    "results": {
        "dumps_collected": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1119_004A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Dumping running processes..."
    
    if result=$(Dump-RunningProcesses "$collection_dir"); then
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected dumps collected"
    exit 0
}

Main "$@"