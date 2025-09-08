
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1119_007A_DEBUG_MODE="${T1119_007A_DEBUG_MODE:-false}"
    export T1119_007A_TIMEOUT="${T1119_007A_TIMEOUT:-300}"
    export T1119_007A_FALLBACK_MODE="${T1119_007A_FALLBACK_MODE:-real}"
    export T1119_007A_OUTPUT_FORMAT="${T1119_007A_OUTPUT_FORMAT:-json}"
    export T1119_007A_POLICY_CHECK="${T1119_007A_POLICY_CHECK:-true}"
    export T1119_007A_MAX_FILES="${T1119_007A_MAX_FILES:-200}"
    export T1119_007A_MAX_FILE_SIZE="${T1119_007A_MAX_FILE_SIZE:-1048576}"
    export T1119_007A_SCAN_DEPTH="${T1119_007A_SCAN_DEPTH:-3}"
    export T1119_007A_EXCLUDE_CACHE="${T1119_007A_EXCLUDE_CACHE:-true}"
    export T1119_007A_CAPTURE_DURATION="${T1119_007A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1119.007a - Automated Collection: Service Enumeration Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Automatically enumerate system services ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1119_007A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1119_007A_OUTPUT_BASE="${T1119_007A_OUTPUT_BASE:-./mitre_results}"
    export T1119_007A_TIMEOUT="${T1119_007A_TIMEOUT:-300}"
    export T1119_007A_OUTPUT_MODE="${T1119_007A_OUTPUT_MODE:-simple}"
    export T1119_007A_SILENT_MODE="${T1119_007A_SILENT_MODE:-false}"
    export T1119_007A_MAX_SERVICES="${T1119_007A_MAX_SERVICES:-500}"
    
    export T1119_007A_SERVICE_TYPES="${T1119_007A_SERVICE_TYPES:-systemd,init,running}"
    export T1119_007A_INCLUDE_DISABLED="${T1119_007A_INCLUDE_DISABLED:-false}"
    export T1119_007A_INCLUDE_FAILED="${T1119_007A_INCLUDE_FAILED:-true}"
    export T1119_007A_INCLUDE_CONFIG="${T1119_007A_INCLUDE_CONFIG:-true}"
    export T1119_007A_FILTER_SYSTEM="${T1119_007A_FILTER_SYSTEM:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1119_007A_OUTPUT_BASE" ]] && { [[ "${T1119_007A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1119_007A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1119_007A_OUTPUT_BASE")" ]] && { [[ "${T1119_007A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1119_007A_OUTPUT_BASE/T1119_007a_service_enum_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{service_data,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Service enumeration
Enumerate-Services() {
    local collection_dir="$1" service_type="$2"
    
    local service_file="$collection_dir/service_data/${service_type}_services_$(date +%s).txt"
    local service_count=0
    
    case "$service_type" in
        "systemd")
            {
                echo "SYSTEMD SERVICES "
                echo "Timestamp: $(date)"
                echo ""
                
                echo "--- RUNNING SERVICES ---"
                systemctl list-units --type=service --state=running --no-pager | head -${T1119_007A_MAX_SERVICES:-500}
                echo ""
                
                if [[ "$T1119_007A_INCLUDE_FAILED" == "true" ]]; then
                    echo "--- FAILED SERVICES ---"
                    systemctl list-units --type=service --state=failed --no-pager | head -50
                    echo ""
                fi
                
                if [[ "$T1119_007A_INCLUDE_DISABLED" == "true" ]]; then
                    echo "--- DISABLED SERVICES ---"
                    systemctl list-unit-files --type=service --state=disabled --no-pager | head -100
                fi
                
            } > "$service_file"
            ;;
        "init")
            {
                echo "INIT SERVICES "
                echo "Timestamp: $(date)"
                echo ""
                
                ls -la /etc/init.d/ 2>/dev/null
                echo ""
                service --status-all 2>/dev/null | head -100
                
            } > "$service_file"
            ;;
        "running")
            {
                echo "RUNNING PROCESSES "
                echo "Timestamp: $(date)"
                echo ""
                
                ps aux | head -${T1119_007A_MAX_SERVICES:-500}
                echo ""
                
                echo "--- LISTENING PORTS ---"
                netstat -tlnp | head -100
                
            } > "$service_file"
            ;;
    esac
    
    if [[ -f "$service_file" && -s "$service_file" ]]; then
        service_count=$(wc -l < "$service_file" 2>/dev/null || echo 0)
        local file_size=$(stat -c%s "$service_file" 2>/dev/null || echo 0)
        echo "$service_file:$file_size"
        [[ "$T1119_007A_SILENT_MODE" != "true" ]] && echo "  + Enumerated: $service_type services ($service_count entries, $file_size bytes)" >&2
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
    # Silent in stealth mode or when T1119_007A_SILENT_MODE is true
    [[ "$T1119_007A_SILENT_MODE" != "true" && "${T1119_007A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "SERVICE ENUMERATION "
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
    "technique": "T1119.007a",
    "results": {
        "service_files_collected": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1119_007A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Starting service enumeration..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    IFS=',' read -ra service_types <<< "$T1119_007A_SERVICE_TYPES"
    
    for service_type in "${service_types[@]}"; do
        service_type=$(echo "$service_type" | xargs)
        
        if result=$(Enumerate-Services "$collection_dir" "$service_type"); then
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected files collected"
    exit 0
}

# Execute
Main "$@"