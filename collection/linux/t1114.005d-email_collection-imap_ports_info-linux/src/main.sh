
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1114_005D_DEBUG_MODE="${T1114_005D_DEBUG_MODE:-false}"
    export T1114_005D_TIMEOUT="${T1114_005D_TIMEOUT:-300}"
    export T1114_005D_FALLBACK_MODE="${T1114_005D_FALLBACK_MODE:-real}"
    export T1114_005D_OUTPUT_FORMAT="${T1114_005D_OUTPUT_FORMAT:-json}"
    export T1114_005D_POLICY_CHECK="${T1114_005D_POLICY_CHECK:-true}"
    export T1114_005D_MAX_FILES="${T1114_005D_MAX_FILES:-200}"
    export T1114_005D_MAX_FILE_SIZE="${T1114_005D_MAX_FILE_SIZE:-1048576}"
    export T1114_005D_SCAN_DEPTH="${T1114_005D_SCAN_DEPTH:-3}"
    export T1114_005D_EXCLUDE_CACHE="${T1114_005D_EXCLUDE_CACHE:-true}"
    export T1114_005D_CAPTURE_DURATION="${T1114_005D_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1114.005d - Email Collection: IMAP Ports Info Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Collect IMAP port and service information ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat netstat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1114_005D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export TT1114_005D_OUTPUT_BASE="${TT1114_005D_OUTPUT_BASE:-./mitre_results}"
    export TT1114_005D_TIMEOUT="${TT1114_005D_TIMEOUT:-300}"
    export TT1114_005D_OUTPUT_MODE="${TT1114_005D_OUTPUT_MODE:-simple}"
    export TT1114_005D_SILENT_MODE="${TT1114_005D_SILENT_MODE:-false}"
    export T1114_005D_MAX_ENTRIES="${T1114_005D_MAX_ENTRIES:-100}"
    
    export T1114_005D_IMAP_PORTS="${T1114_005D_IMAP_PORTS:-143,993,110,995}"
    export T1114_005D_SCAN_LOCALHOST="${T1114_005D_SCAN_LOCALHOST:-true}"
    export T1114_005D_SCAN_NETWORK="${T1114_005D_SCAN_NETWORK:-false}"
    export T1114_005D_NETWORK_RANGE="${T1114_005D_NETWORK_RANGE:-192.168.1_0/24}"
    export T1114_005D_INCLUDE_PROCESSES="${T1114_005D_INCLUDE_PROCESSES:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$TT1114_005D_OUTPUT_BASE" ]] && { [[ "${TT1114_005D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1114_005D_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$TT1114_005D_OUTPUT_BASE")" ]] && { [[ "${TT1114_005D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$TT1114_005D_OUTPUT_BASE/T1114_005d_imap_ports_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{port_info,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# IMAP port information collection
Collect-IMAPPortInfo() {
    local collection_dir="$1"
    
    local port_info_file="$collection_dir/port_info/imap_ports_$(date +%s).txt"
    local info_count=0
    
    {
        echo "IMAP PORT INFORMATION "
        echo "Timestamp: $(date)"
        echo ""
        
        # Listening ports
        echo "--- LISTENING IMAP PORTS ---"
        IFS=',' read -ra ports <<< "$T1114_005D_IMAP_PORTS"
        for port in "${ports[@]}"; do
            port=$(echo "$port" | xargs)
            if netstat -tlnp 2>/dev/null | grep ":$port "; then
                ((info_count++))
            fi
        done
        echo ""
        
        # Active connections
        echo "--- ACTIVE IMAP CONNECTIONS ---"
        for port in "${ports[@]}"; do
            port=$(echo "$port" | xargs)
            netstat -tnp 2>/dev/null | grep ":$port " | head -10
        done
        echo ""
        
        # Process information
        if [[ "$T1114_005D_INCLUDE_PROCESSES" == "true" ]]; then
            echo "--- IMAP RELATED PROCESSES ---"
            ps aux | grep -E "(imap|dovecot|courier)" | grep -v grep
        fi
        
    } > "$port_info_file"
    
    if [[ -f "$port_info_file" && -s "$port_info_file" ]]; then
        local file_size=$(stat -c%s "$port_info_file" 2>/dev/null || echo 0)
        echo "$port_info_file:$file_size"
        [[ "$TT1114_005D_SILENT_MODE" != "true" && "${TT1114_005D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: IMAP port info ($file_size bytes)" >&2
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
    netstat -tlnp > "$collection_dir/metadata/all_listening_ports.txt" 2>/dev/null
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1114_005D_SILENT_MODE is true
    [[ "$TT1114_005D_SILENT_MODE" != "true" && "${TT1114_005D_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "IMAP PORTS INFO "
    echo "Info files: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1114.005d",
    "results": {
        "info_files_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$TT1114_005D_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Collecting IMAP port information..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    if result=$(Collect-IMAPPortInfo "$collection_dir"); then
        IFS=':' read -r file_path file_size <<< "$result"
        collected_files+=("$file_path")
        total_size=$((total_size + file_size))
        ((file_count++))
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected info files collected"
    exit 0
}

# Execute
Main "$@"