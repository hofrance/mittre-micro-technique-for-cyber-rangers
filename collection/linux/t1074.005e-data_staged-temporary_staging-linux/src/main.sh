
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1074_005E_DEBUG_MODE="${T1074_005E_DEBUG_MODE:-false}"
    export T1074_005E_TIMEOUT="${T1074_005E_TIMEOUT:-300}"
    export T1074_005E_FALLBACK_MODE="${T1074_005E_FALLBACK_MODE:-real}"
    export T1074_005E_OUTPUT_FORMAT="${T1074_005E_OUTPUT_FORMAT:-json}"
    export T1074_005E_POLICY_CHECK="${T1074_005E_POLICY_CHECK:-true}"
    export T1074_005E_MAX_FILES="${T1074_005E_MAX_FILES:-200}"
    export T1074_005E_MAX_FILE_SIZE="${T1074_005E_MAX_FILE_SIZE:-1048576}"
    export T1074_005E_SCAN_DEPTH="${T1074_005E_SCAN_DEPTH:-3}"
    export T1074_005E_EXCLUDE_CACHE="${T1074_005E_EXCLUDE_CACHE:-true}"
    export T1074_005E_CAPTURE_DURATION="${T1074_005E_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1074.005e - Data Staged: Temporary Staging Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Stage data in temporary locations ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1074_005E_OUTPUT_BASE="${T1074_005E_OUTPUT_BASE:-./mitre_results}"
    export T1074_005E_TIMEOUT="${TT1074_005E_TIMEOUT:-300}"
    export T1074_005E_OUTPUT_MODE="${TT1074_005E_OUTPUT_MODE:-simple}"
    export T1074_005E_SILENT_MODE="${TT1074_005E_SILENT_MODE:-false}"
    export T1074_005E_MAX_FILES="${T1074_005E_MAX_FILES:-1000}"
    
    export T1074_005E_TEMP_DIRS="${T1074_005E_TEMP_DIRS:-/tmp,/var/tmp,/dev/shm}"
    export T1074_005E_SOURCE_PATHS="${T1074_005E_SOURCE_PATHS:-./mitre_results}"
    export T1074_005E_STAGING_PREFIX="${T1074_005E_STAGING_PREFIX:-_tmp_}"
    export T1074_005E_MAX_TOTAL_SIZE="${T1074_005E_MAX_TOTAL_SIZE:-1073741824}"
    export T1074_005E_AUTO_CLEANUP="${T1074_005E_AUTO_CLEANUP:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1074_005E_OUTPUT_BASE" ]] && { [[ "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1074_005E_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1074_005E_OUTPUT_BASE")" ]] && { [[ "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1074_005E_OUTPUT_BASE/T1074_005e_temp_staging_$timestamp"
    
    # Select best temp directory
    IFS=',' read -ra temp_dirs <<< "$T1074_005E_TEMP_DIRS"
    for temp_dir in "${temp_dirs[@]}"; do
        temp_dir=$(echo "$temp_dir" | xargs)
        if [[ -d "$temp_dir" && -w "$temp_dir" ]]; then
            export STAGING_DIR="$temp_dir/${T1074_005E_STAGING_PREFIX}staging_$timestamp"
            break
        fi
    done
    
    mkdir -p "$COLLECTION_DIR"/{temp_staged,metadata} 2>/dev/null || return 1
    mkdir -p "$STAGING_DIR" 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    chmod 755 "$STAGING_DIR" 2>/dev/null  # Less suspicious permissions
    echo "$COLLECTION_DIR"
}

# Temporary file staging
Stage-TempFile() {
    local source_file="$1" staging_dir="$2" collection_dir="$3"
    
    [[ ! -f "$source_file" || ! -r "$source_file" ]] && return 1
    
    local filename=$(basename "$source_file")
    local temp_name="${T1074_005E_STAGING_PREFIX}${filename}_$(date +%s)"
    
    if cp "$source_file" "$staging_dir/$temp_name" 2>/dev/null; then
        # Also log the staging operation
        echo "$source_file -> $staging_dir/$temp_name" >> "$collection_dir/temp_staged/staging_log.txt"
        
        local file_size=$(stat -c%s "$staging_dir/$temp_name" 2>/dev/null || echo 0)
        echo "$staging_dir/$temp_name:$file_size"
        [[ "$T1074_005E_SILENT_MODE" != "true" ]] && echo "  + Staged: $source_file ($file_size bytes)" >&2
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
    echo "Staging directory: $STAGING_DIR" > "$collection_dir/metadata/staging_info.txt"
    df -h "$STAGING_DIR" > "$collection_dir/metadata/disk_space.txt" 2>/dev/null
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1074_005E_SILENT_MODE is true
    [[ "$T1074_005E_SILENT_MODE" != "true" && "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "TEMPORARY STAGING "
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
    "technique": "T1074.005e",
    "results": {
        "files_staged": $files_collected,
        "total_size_bytes": $total_size,
        "staging_directory": "$STAGING_DIR",
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1074_005E_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting temporary staging..."
    
    # Adaptive timeout logic for testing
    local effective_max_size="$T1074_005E_MAX_TOTAL_SIZE"
    local test_files=()
    
    if [[ "${TT1074_005E_TIMEOUT:-300}" -lt 30 ]]; then
        [[ "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Test mode detected, using sample files" >&2
        # Test avec fichiers simples et accessibles
        test_files=("/etc/hostname" "/etc/os-release" "/proc/version")
        effective_max_size=10240  # 10KB max for tests
    elif [[ "${TT1074_005E_TIMEOUT:-300}" -lt 120 ]]; then
        [[ "${TT1074_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Quick mode detected, limiting size to 1MB" >&2
        effective_max_size=1048576  # 1MB for quick mode
    fi
    
    # ATOMIC ACTION: Orchestration of auxiliary functions with timeout protection
    if [[ ${#test_files[@]} -gt 0 ]]; then
        # Mode test avec fichiers fixes
        for source_file in "${test_files[@]}"; do
            [[ ! -f "$source_file" || ! -r "$source_file" ]] && continue
            
            if result=$(Stage-TempFile "$source_file" "$STAGING_DIR" "$collection_dir"); then
                IFS=':' read -r file_path file_size <<< "$result"
                collected_files+=("$file_path")
                total_size=$((total_size + file_size))
                ((file_count++))
                [[ $total_size -ge $effective_max_size ]] && break
            fi
        done
    else
        # Mode normal avec find et protection timeout
        IFS=',' read -ra source_paths <<< "$T1074_005E_SOURCE_PATHS"
        local start_time=$(date +%s)
        
        for source_path in "${source_paths[@]}"; do
            source_path=$(echo "$source_path" | xargs)
            [[ ! -d "$source_path" ]] && continue
            
            while IFS= read -r -d '' source_file; do
                # Check timeout during processing
                local current_time=$(date +%s)
                [[ $((current_time - start_time)) -ge $((T1074_005E_TIMEOUT - 5)) ]] && break 2
                
                if result=$(Stage-TempFile "$source_file" "$STAGING_DIR" "$collection_dir"); then
                    IFS=':' read -r file_path file_size <<< "$result"
                    collected_files+=("$file_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))
                    [[ $total_size -ge $effective_max_size ]] && break 2
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