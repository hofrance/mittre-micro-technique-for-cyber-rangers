
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1560_002B_DEBUG_MODE="${T1560_002B_DEBUG_MODE:-false}"
    export T1560_002B_TIMEOUT="${T1560_002B_TIMEOUT:-300}"
    export T1560_002B_FALLBACK_MODE="${T1560_002B_FALLBACK_MODE:-real}"
    export T1560_002B_OUTPUT_FORMAT="${T1560_002B_OUTPUT_FORMAT:-json}"
    export T1560_002B_POLICY_CHECK="${T1560_002B_POLICY_CHECK:-true}"
    export T1560_002B_MAX_FILES="${T1560_002B_MAX_FILES:-200}"
    export T1560_002B_MAX_FILE_SIZE="${T1560_002B_MAX_FILE_SIZE:-1048576}"
    export T1560_002B_SCAN_DEPTH="${T1560_002B_SCAN_DEPTH:-3}"
    export T1560_002B_EXCLUDE_CACHE="${T1560_002B_EXCLUDE_CACHE:-true}"
    export T1560_002B_CAPTURE_DURATION="${T1560_002B_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1560.002b - Archive Collected Data: Gzip Compression Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Compress collected data using gzip ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat gzip; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1560_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

Load-EnvironmentVariables() {
    export T1560_002B_OUTPUT_BASE="${T1560_002B_OUTPUT_BASE:-./mitre_results}"
    export T1560_002B_TIMEOUT="${TT1560_002B_TIMEOUT:-300}"
    export T1560_002B_OUTPUT_MODE="${TT1560_002B_OUTPUT_MODE:-simple}"
    export T1560_002B_SILENT_MODE="${TT1560_002B_SILENT_MODE:-false}"
    export T1560_002B_MAX_FILES="${T1560_002B_MAX_FILES:-1000}"
    
    export T1560_002B_SOURCE_PATHS="${T1560_002B_SOURCE_PATHS:-./mitre_results}"
    export T1560_002B_COMPRESSION_LEVEL="${T1560_002B_COMPRESSION_LEVEL:-6}"
    export T1560_002B_PRESERVE_ORIGINAL="${T1560_002B_PRESERVE_ORIGINAL:-false}"
    export T1560_002B_FILE_PATTERNS="${T1560_002B_FILE_PATTERNS:-*}"
    export T1560_002B_MIN_FILE_SIZE="${T1560_002B_MIN_FILE_SIZE:-1024}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1560_002B_OUTPUT_BASE" ]] && { [[ "${TT1560_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1560_002B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1560_002B_OUTPUT_BASE")" ]] && { [[ "${TT1560_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1560_002B_OUTPUT_BASE/T1560_002b_gzip_compression_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{compressed_files,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Compress-FileGzip() {
    local source_file="$1" collection_dir="$2"
    
    [[ ! -f "$source_file" || ! -r "$source_file" ]] && return 1
    
    local file_size=$(stat -c%s "$source_file" 2>/dev/null || echo 0)
    [[ $file_size -lt ${T1560_002B_MIN_FILE_SIZE:-1024} ]] && return 1
    
    local filename=$(basename "$source_file")
    local compressed_file="$collection_dir/compressed_files/${filename}_$(date +%s).gz"
    
    if gzip -c -"$T1560_002B_COMPRESSION_LEVEL" "$source_file" > "$compressed_file" 2>/dev/null; then
        local compressed_size=$(stat -c%s "$compressed_file" 2>/dev/null || echo 0)
        echo "$compressed_file:$compressed_size"
        [[ "$T1560_002B_SILENT_MODE" != "true" ]] && echo "  + Compressed: $source_file ($compressed_size bytes)" >&2
        return 0
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    gzip --version > "$collection_dir/metadata/gzip_version.txt" 2>/dev/null
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1560_002B_SILENT_MODE is true
    [[ "$T1560_002B_SILENT_MODE" != "true" && "${TT1560_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "GZIP COMPRESSION "
    echo "Files: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1560.002b",
    "results": {
        "files_compressed": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1560_002B_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting gzip compression..."
    
    IFS=',' read -ra source_paths <<< "$T1560_002B_SOURCE_PATHS"
    IFS=',' read -ra patterns <<< "$T1560_002B_FILE_PATTERNS"
    
    for source_path in "${source_paths[@]}"; do
        source_path=$(echo "$source_path" | xargs)
        [[ ! -d "$source_path" ]] && continue
        
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs)
            
            while IFS= read -r -d '' source_file; do
                if result=$(Compress-FileGzip "$source_file" "$collection_dir"); then
                    IFS=':' read -r file_path file_size <<< "$result"
                    collected_files+=("$file_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))
                    [[ $file_count -ge ${T1560_002B_MAX_FILES:-1000} ]] && break 2
                fi
            done < <(find "$source_path" -name "$pattern" -type f -print0 2>/dev/null)
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files compressed"
    exit 0
}

Main "$@"