
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1560_004D_DEBUG_MODE="${T1560_004D_DEBUG_MODE:-false}"
    export T1560_004D_TIMEOUT="${T1560_004D_TIMEOUT:-300}"
    export T1560_004D_FALLBACK_MODE="${T1560_004D_FALLBACK_MODE:-real}"
    export T1560_004D_OUTPUT_FORMAT="${T1560_004D_OUTPUT_FORMAT:-json}"
    export T1560_004D_POLICY_CHECK="${T1560_004D_POLICY_CHECK:-true}"
    export T1560_004D_MAX_FILES="${T1560_004D_MAX_FILES:-200}"
    export T1560_004D_MAX_FILE_SIZE="${T1560_004D_MAX_FILE_SIZE:-1048576}"
    export T1560_004D_SCAN_DEPTH="${T1560_004D_SCAN_DEPTH:-3}"
    export T1560_004D_EXCLUDE_CACHE="${T1560_004D_EXCLUDE_CACHE:-true}"
    export T1560_004D_CAPTURE_DURATION="${T1560_004D_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1560.004d - Archive Collected Data: Split Archives Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Create split archives of collected data ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat tar split; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1560_004D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

Load-EnvironmentVariables() {
    export T1560_004D_OUTPUT_BASE="${T1560_004D_OUTPUT_BASE:-./mitre_results}"
    export T1560_004D_TIMEOUT="${TT1560_004D_TIMEOUT:-300}"
    export T1560_004D_OUTPUT_MODE="${TT1560_004D_OUTPUT_MODE:-simple}"
    export T1560_004D_SILENT_MODE="${TT1560_004D_SILENT_MODE:-false}"
    export T1560_004D_MAX_ARCHIVES="${T1560_004D_MAX_ARCHIVES:-10}"
    
    export T1560_004D_SOURCE_PATHS="${T1560_004D_SOURCE_PATHS:-./mitre_results}"
    export T1560_004D_SPLIT_SIZE="${T1560_004D_SPLIT_SIZE:-50M}"
    export T1560_004D_ARCHIVE_NAME="${T1560_004D_ARCHIVE_NAME:-split_data}"
    export T1560_004D_COMPRESSION="${T1560_004D_COMPRESSION:-true}"
    export T1560_004D_PART_PREFIX="${T1560_004D_PART_PREFIX:-part}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1560_004D_OUTPUT_BASE" ]] && { [[ "${TT1560_004D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1560_004D_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1560_004D_OUTPUT_BASE")" ]] && { [[ "${TT1560_004D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1560_004D_OUTPUT_BASE/T1560_004d_split_archives_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{split_archives,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Create-SplitArchive() {
    local collection_dir="$1" source_path="$2" archive_num="$3"
    
    [[ ! -d "$source_path" ]] && return 1
    
    local archive_base="${T1560_004D_ARCHIVE_NAME}_${archive_num}_$(date +%s)"
    local archive_file="$collection_dir/split_archives/${archive_base}.tar"
    
    # Create archive
    local tar_args=("-cf" "$archive_file" "-C" "$(dirname "$source_path")" "$(basename "$source_path")")
    [[ "$T1560_004D_COMPRESSION" == "true" ]] && tar_args=("-czf" "${archive_file}.gz" "-C" "$(dirname "$source_path")" "$(basename "$source_path")")
    
    if tar "${tar_args[@]}" 2>/dev/null; then
        local created_file="$archive_file"
        [[ "$T1560_004D_COMPRESSION" == "true" ]] && created_file="${archive_file}.gz"
        
        # Split the archive
        local split_prefix="$collection_dir/split_archives/${archive_base}.${T1560_004D_PART_PREFIX}"
        
        if split -b "$T1560_004D_SPLIT_SIZE" "$created_file" "$split_prefix" 2>/dev/null; then
            rm -f "$created_file"
            
            # Calculate total size of all parts
            local total_size=0
            for part_file in "${split_prefix}"*; do
                [[ -f "$part_file" ]] && {
                    local part_size=$(stat -c%s "$part_file" 2>/dev/null || echo 0)
                    total_size=$((total_size + part_size))
                }
            done
            
            echo "${split_prefix}*:$total_size"
            [[ "$T1560_004D_SILENT_MODE" != "true" ]] && echo "  + Split: $source_path ($total_size bytes total)" >&2
            return 0
        fi
        
        rm -f "$created_file"
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "Split size: $T1560_004D_SPLIT_SIZE" > "$collection_dir/metadata/split_info.txt"
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1560_004D_SILENT_MODE is true
    [[ "$T1560_004D_SILENT_MODE" != "true" && "${TT1560_004D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "SPLIT ARCHIVES "
    echo "Archives: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1560.004d",
    "results": {
        "split_archives_created": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1560_004D_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Creating split archives..."
    
    IFS=',' read -ra source_paths <<< "$T1560_004D_SOURCE_PATHS"
    
    local archive_num=1
    for source_path in "${source_paths[@]}"; do
        source_path=$(echo "$source_path" | xargs)
        
        if result=$(Create-SplitArchive "$collection_dir" "$source_path" "$archive_num"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            ((archive_num++))
            [[ $file_count -ge ${T1560_004D_MAX_ARCHIVES:-10} ]] && break
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
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    local collection_dir results
    collection_dir=$(Get-Configuration) || exit 2
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected archives created"
    exit 0
}

Main "$@"