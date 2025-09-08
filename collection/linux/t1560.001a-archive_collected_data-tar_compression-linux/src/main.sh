
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1560_001A_DEBUG_MODE="${T1560_001A_DEBUG_MODE:-false}"
    export T1560_001A_TIMEOUT="${T1560_001A_TIMEOUT:-300}"
    export T1560_001A_FALLBACK_MODE="${T1560_001A_FALLBACK_MODE:-real}"
    export T1560_001A_OUTPUT_FORMAT="${T1560_001A_OUTPUT_FORMAT:-json}"
    export T1560_001A_POLICY_CHECK="${T1560_001A_POLICY_CHECK:-true}"
    export T1560_001A_MAX_FILES="${T1560_001A_MAX_FILES:-200}"
    export T1560_001A_MAX_FILE_SIZE="${T1560_001A_MAX_FILE_SIZE:-1048576}"
    export T1560_001A_SCAN_DEPTH="${T1560_001A_SCAN_DEPTH:-3}"
    export T1560_001A_EXCLUDE_CACHE="${T1560_001A_EXCLUDE_CACHE:-true}"
    export T1560_001A_CAPTURE_DURATION="${T1560_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1560.001a - Archive Collected Data: Tar Compression Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Archive collected data using tar compression ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat tar; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1560_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

Load-EnvironmentVariables() {
    export T1560_001A_OUTPUT_BASE="${T1560_001A_OUTPUT_BASE:-./mitre_results}"
    export T1560_001A_TIMEOUT="${T1560_001A_TIMEOUT:-300}"
    export T1560_001A_OUTPUT_MODE="${T1560_001A_OUTPUT_MODE:-simple}"
    export T1560_001A_SILENT_MODE="${T1560_001A_SILENT_MODE:-false}"
    export T1560_001A_MAX_ARCHIVES="${T1560_001A_MAX_ARCHIVES:-10}"
    
    export T1560_001A_SOURCE_PATHS="${T1560_001A_SOURCE_PATHS:-./mitre_results}"
    export T1560_001A_ARCHIVE_NAME="${T1560_001A_ARCHIVE_NAME:-collected_data}"
    export T1560_001A_COMPRESSION_LEVEL="${T1560_001A_COMPRESSION_LEVEL:-6}"
    export T1560_001A_SPLIT_SIZE="${T1560_001A_SPLIT_SIZE:-100M}"
    export T1560_001A_INCLUDE_METADATA="${T1560_001A_INCLUDE_METADATA:-true}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1560_001A_OUTPUT_BASE" ]] && { [[ "${T1560_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1560_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1560_001A_OUTPUT_BASE")" ]] && { [[ "${T1560_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1560_001A_OUTPUT_BASE/T1560_001a_tar_archives_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{archives,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Create-TarArchive() {
    local collection_dir="$1" source_path="$2" archive_num="$3"
    
    [[ ! -d "$source_path" ]] && return 1
    
    local archive_name="${T1560_001A_ARCHIVE_NAME}_${archive_num}_$(date +%s).tar.gz"
    local archive_file="$collection_dir/archives/$archive_name"
    
    local tar_args=("-czf" "$archive_file" "-C" "$(dirname "$source_path")" "$(basename "$source_path")")
    
    if tar "${tar_args[@]}" 2>/dev/null; then
        local file_size=$(stat -c%s "$archive_file" 2>/dev/null || echo 0)
        
        # Split if too large
        if [[ -n "$T1560_001A_SPLIT_SIZE" && "$T1560_001A_SPLIT_SIZE" != "0" ]]; then
            if command -v split >/dev/null; then
                split -b "$T1560_001A_SPLIT_SIZE" "$archive_file" "${archive_file}.part"
                rm -f "$archive_file"
                archive_file="${archive_file}.part*"
                file_size=$(du -cb ${archive_file} 2>/dev/null | tail -1 | awk '{print $1}')
            fi
        fi
        
        echo "$archive_file:$file_size"
        [[ "$T1560_001A_SILENT_MODE" != "true" ]] && echo "  + Archived: $source_path ($file_size bytes)" >&2
        return 0
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    tar --version > "$collection_dir/metadata/tar_version.txt" 2>/dev/null
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1560_001A_SILENT_MODE is true
    [[ "$T1560_001A_SILENT_MODE" != "true" && "${T1560_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "TAR COMPRESSION "
    echo "Archives: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1560.001a",
    "results": {
        "archives_created": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1560_001A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Creating tar archives..."
    
    IFS=',' read -ra source_paths <<< "$T1560_001A_SOURCE_PATHS"
    
    local archive_num=1
    for source_path in "${source_paths[@]}"; do
        source_path=$(echo "$source_path" | xargs)
        
        if result=$(Create-TarArchive "$collection_dir" "$source_path" "$archive_num"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            ((archive_num++))
            [[ $file_count -ge ${T1560_001A_MAX_ARCHIVES:-10} ]] && break
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