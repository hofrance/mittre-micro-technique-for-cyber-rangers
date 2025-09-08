
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1119_005A_DEBUG_MODE="${T1119_005A_DEBUG_MODE:-false}"
    export T1119_005A_TIMEOUT="${T1119_005A_TIMEOUT:-300}"
    export T1119_005A_FALLBACK_MODE="${T1119_005A_FALLBACK_MODE:-real}"
    export T1119_005A_OUTPUT_FORMAT="${T1119_005A_OUTPUT_FORMAT:-json}"
    export T1119_005A_POLICY_CHECK="${T1119_005A_POLICY_CHECK:-true}"
    export T1119_005A_MAX_FILES="${T1119_005A_MAX_FILES:-200}"
    export T1119_005A_MAX_FILE_SIZE="${T1119_005A_MAX_FILE_SIZE:-1048576}"
    export T1119_005A_SCAN_DEPTH="${T1119_005A_SCAN_DEPTH:-3}"
    export T1119_005A_EXCLUDE_CACHE="${T1119_005A_EXCLUDE_CACHE:-true}"
    export T1119_005A_CAPTURE_DURATION="${T1119_005A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1119.005a - Automated Collection: Filesystem Enumeration Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Automatically enumerate filesystem structure ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1119_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1119_005A_OUTPUT_BASE="${T1119_005A_OUTPUT_BASE:-./mitre_results}"
    export T1119_005A_TIMEOUT="${T1119_005A_TIMEOUT:-300}"
    export T1119_005A_OUTPUT_MODE="${T1119_005A_OUTPUT_MODE:-simple}"
    export T1119_005A_SILENT_MODE="${T1119_005A_SILENT_MODE:-false}"
    export T1119_005A_MAX_ENTRIES="${T1119_005A_MAX_ENTRIES:-10000}"
    
    export T1119_005A_ENUM_PATHS="${T1119_005A_ENUM_PATHS:-/home,/etc,/var,/opt}"
    export T1119_005A_SCAN_DEPTH="${T1119_005A_SCAN_DEPTH:-3}"
    export T1119_005A_INCLUDE_HIDDEN="${T1119_005A_INCLUDE_HIDDEN:-false}"
    export T1119_005A_INCLUDE_PERMISSIONS="${T1119_005A_INCLUDE_PERMISSIONS:-true}"
    export T1119_005A_EXCLUDE_PROC="${T1119_005A_EXCLUDE_PROC:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1119_005A_OUTPUT_BASE" ]] && { [[ "${T1119_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1119_005A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1119_005A_OUTPUT_BASE")" ]] && { [[ "${T1119_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1119_005A_OUTPUT_BASE/T1119_005a_filesystem_enum_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{filesystem_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Filesystem enumeration
Enumerate-Filesystem() {
    local collection_dir="$1" enum_path="$2"
    
    [[ ! -d "$enum_path" || ! -r "$enum_path" ]] && return 1
    
    local enum_file="$collection_dir/filesystem_data/enum_$(basename "$enum_path")_$(date +%s).txt"
    local entry_count=0
    
    local find_args=("-maxdepth" "$T1119_005A_SCAN_DEPTH")
    [[ "$T1119_005A_INCLUDE_HIDDEN" == "false" ]] && find_args+=("!" "-name" ".*")
    
    {
        echo "FILESYSTEM ENUMERATION: $enum_path "
        echo "Timestamp: $(date)"
        echo ""
        
        if [[ "$T1119_005A_INCLUDE_PERMISSIONS" == "true" ]]; then
            find "$enum_path" "${find_args[@]}" -ls 2>/dev/null | head -${T1119_005A_MAX_ENTRIES:-10000}
        else
            find "$enum_path" "${find_args[@]}" 2>/dev/null | head -${T1119_005A_MAX_ENTRIES:-10000}
        fi
        
    } > "$enum_file"
    
    if [[ -f "$enum_file" && -s "$enum_file" ]]; then
        entry_count=$(wc -l < "$enum_file" 2>/dev/null || echo 0)
        local file_size=$(stat -c%s "$enum_file" 2>/dev/null || echo 0)
        echo "$enum_file:$file_size"
        [[ "$T1119_005A_SILENT_MODE" != "true" ]] && echo "  + Enumerated: $enum_path ($entry_count entries, $file_size bytes)" >&2
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
    mount > "$collection_dir/metadata/mount_points.txt"
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1119_005A_SILENT_MODE is true
    [[ "$T1119_005A_SILENT_MODE" != "true" && "${T1119_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "FILESYSTEM ENUMERATION "
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
    "technique": "T1119.005a",
    "results": {
        "enum_files_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1119_005A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting filesystem enumeration..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    IFS=',' read -ra enum_paths <<< "$T1119_005A_ENUM_PATHS"
    
    for enum_path in "${enum_paths[@]}"; do
        enum_path=$(echo "$enum_path" | xargs)
        
        if result=$(Enumerate-Filesystem "$collection_dir" "$enum_path"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected enum files collected"
    exit 0
}

# Execute
Main "$@"