
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1046_001A_DEBUG_MODE="${T1046_001A_DEBUG_MODE:-false}"
    export T1046_001A_TIMEOUT="${T1046_001A_TIMEOUT:-300}"
    export T1046_001A_FALLBACK_MODE="${T1046_001A_FALLBACK_MODE:-simulate}"
    export T1046_001A_OUTPUT_FORMAT="${T1046_001A_OUTPUT_FORMAT:-json}"
    export T1046_001A_POLICY_CHECK="${T1046_001A_POLICY_CHECK:-true}"
    export T1046_001A_MAX_SERVICES="${T1046_001A_MAX_SERVICES:-200}"
    export T1046_001A_INCLUDE_SYSTEM="${T1046_001A_INCLUDE_SYSTEM:-true}"
    export T1046_001A_DETAIL_LEVEL="${T1046_001A_DETAIL_LEVEL:-standard}"
    export T1046_001A_RESOLVE_HOSTNAMES="${T1046_001A_RESOLVE_HOSTNAMES:-true}"
    export T1046_001A_MAX_PROCESSES="${T1046_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1046.001a - Network Service Discovery: Port Scanning
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover network services by port scanning ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "nc" "timeout" "cat" "awk")
    
    [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  x Missing: $dep"
        done
        echo ""
        echo "INSTALLATION COMMANDS:"
        echo "Ubuntu/Debian: sudo apt-get install -y ${missing_deps[*]}"
        echo "CentOS/RHEL:   sudo dnf install -y ${missing_deps[*]}"
        echo "Arch Linux:    sudo pacman -S ${missing_deps[*]}"
        echo ""
        exit 1
    fi
    
    [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1046_001A_OUTPUT_BASE="${T1046_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1046_001A_TIMEOUT="${T1046_001A_TIMEOUT:-300}"
    export T1046_001A_OUTPUT_MODE="${T1046_001A_OUTPUT_MODE:-simple}"
    export T1046_001A_SILENT_MODE="${T1046_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1046_001A_SCAN_TARGETS="${T1046_001A_SCAN_TARGETS:-127.0.0.1,localhost}"
    export T1046_001A_SCAN_PORTS="${T1046_001A_SCAN_PORTS:-21,22,23,25,53,80,110,143,443,993,995,8080,8443}"
    export T1046_001A_TIMEOUT="${T1046_001A_TIMEOUT:-2}"
    export T1046_001A_SCAN_TYPE="${T1046_001A_SCAN_TYPE:-tcp}"
    export T1046_001A_INCLUDE_SERVICE_DETECTION="${T1046_001A_INCLUDE_SERVICE_DETECTION:-true}"
    export T1046_001A_INCLUDE_BANNER_GRABBING="${T1046_001A_INCLUDE_BANNER_GRABBING:-false}"
    export T1046_001A_MAX_TARGETS="${T1046_001A_MAX_TARGETS:-10}"
    export T1046_001A_MAX_PORTS="${T1046_001A_MAX_PORTS:-100}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1046_001A_OUTPUT_BASE" ]] && { [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1046_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1046_001A_OUTPUT_BASE")" ]] && { [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1046_001A_OUTPUT_BASE/T1046_001a_port_scanning_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{scan_results,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Scan a single port
Scan-Port() {
    local target="$1"
    local port="$2"
    local timeout="$3"
    
    if timeout "$timeout" bash -c "echo >/dev/tcp/$/tmp/mitre_results/$port" 2>/dev/null; then
        echo "open"
    else
        echo "closed"
    fi
}

# Get service name for port
Get-ServiceName() {
    local port="$1"
    local service=""
    
    case "$port" in
        21) service="ftp" ;;
        22) service="ssh" ;;
        23) service="telnet" ;;
        25) service="smtp" ;;
        53) service="dns" ;;
        80) service="http" ;;
        110) service="pop3" ;;
        143) service="imap" ;;
        443) service="https" ;;
        993) service="imaps" ;;
        995) service="pop3s" ;;
        8080) service="http-proxy" ;;
        8443) service="https-alt" ;;
        *) service="unknown" ;;
    esac
    
    echo "$service"
}

# Perform port scanning
Perform-PortScan() {
    local output_dir="$1"
    local scan_file="$output_dir/scan_results/port_scan_results.json"
    
    local scan_results=()
    local total_targets=0
    local total_ports=0
    local total_open_ports=0
    
    # Parse scan targets
    IFS=',' read -ra TARGET_ARRAY <<< "$T1046_001A_SCAN_TARGETS"
    
    # Parse scan ports
    IFS=',' read -ra PORT_ARRAY <<< "$T1046_001A_SCAN_PORTS"
    
    for target in "${TARGET_ARRAY[@]}"; do
        target=$(echo "$target" | xargs)  # Trim whitespace
        [[ -z "$target" ]] && continue
        [[ $total_targets -ge $T1046_001A_MAX_TARGETS ]] && break
        
        [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Scanning target: $target" >&2
        
        local target_results=()
        local target_open_ports=0
        
        for port in "${PORT_ARRAY[@]}"; do
            port=$(echo "$port" | xargs)  # Trim whitespace
            [[ -z "$port" ]] && continue
            [[ $total_ports -ge $T1046_001A_MAX_PORTS ]] && break
            
            local port_status=$(Scan-Port "$target" "$port" "$T1046_001A_TIMEOUT")
            local service_name=$(Get-ServiceName "$port")
            
            local port_result=$(cat <<EOF
{
  "port": $port,
  "status": "$port_status",
  "service": "$service_name",
  "protocol": "$T1046_001A_SCAN_TYPE"
}
EOF
)
            target_results+=("$port_result")
            ((total_ports++))
            
            if [[ "$port_status" == "open" ]]; then
                ((target_open_ports++))
                ((total_open_ports++))
            fi
            
            [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Port $port ($service_name): $port_status" >&2
        done
        
        local target_result=$(cat <<EOF
{
  "target": "$target",
  "open_ports": $target_open_ports,
  "total_ports_scanned": ${#PORT_ARRAY[@]},
  "ports": [$(IFS=','; echo "${target_results[*]}")]
}
EOF
)
        scan_results+=("$target_result")
        ((total_targets++))
    done
    
    local scan_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_configuration": {
    "targets": "$T1046_001A_SCAN_TARGETS",
    "ports": "$T1046_001A_SCAN_PORTS",
    "timeout": $T1046_001A_TIMEOUT,
    "scan_type": "$T1046_001A_SCAN_TYPE"
  },
  "scan_summary": {
    "total_targets": $total_targets,
    "total_ports_scanned": $total_ports,
    "total_open_ports": $total_open_ports
  },
  "scan_results": [$(IFS=','; echo "${scan_results[*]}")]
}
EOF
)
    
    echo "$scan_data" > "$scan_file" 2>/dev/null && {
        [[ "$T1046_001A_SILENT_MODE" != "true" && "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Port scan completed: $total_open_ports open ports found" >&2
        echo "$total_open_ports"
    }
}

# Discover listening ports on local system
Discover-LocalListeningPorts() {
    local output_dir="$1"
    local local_ports_file="$output_dir/scan_results/local_listening_ports.json"
    
    local listening_ports=()
    local total_listening=0
    
    # Get listening ports using netstat or ss
    if command -v ss >/dev/null 2>&1; then
        while IFS=' ' read -r proto recv_q send_q local_addr foreign_addr state pid_program; do
            [[ "$proto" == "Netid" ]] && continue
            [[ -z "$proto" ]] && continue
            [[ "$state" != "LISTEN" ]] && continue
            
            local port=$(echo "$local_addr" | grep -o ':[0-9]*' | sed 's/://' || echo "")
            [[ -z "$port" ]] && continue
            
            local service_name=$(Get-ServiceName "$port")
            
            local port_info=$(cat <<EOF
{
  "protocol": "$proto",
  "port": "$port",
  "service": "$service_name",
  "local_address": "$local_addr",
  "state": "$state",
  "pid_program": "$pid_program"
}
EOF
)
            listening_ports+=("$port_info")
            ((total_listening++))
            
            [[ $total_listening -ge 50 ]] && break
        done < <(ss -tuln 2>/dev/null | grep LISTEN)
    fi
    
    local local_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_listening_ports": $total_listening,
  "listening_ports": [$(IFS=','; echo "${listening_ports[*]}")]
}
EOF
)
    
    echo "$local_data" > "$local_ports_file" 2>/dev/null && {
        [[ "$T1046_001A_SILENT_MODE" != "true" && "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_listening local listening ports" >&2
        echo "$total_listening"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_open_ports=0
    local total_listening_ports=0
    
    [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting network service discovery..." >&2
    
    # Perform port scanning
    local open_ports_count=$(Perform-PortScan "$discovery_dir")
    [[ -n "$open_ports_count" ]] && total_open_ports=$open_ports_count
    
    # Discover local listening ports
    local listening_count=$(Discover-LocalListeningPorts "$discovery_dir")
    [[ -n "$listening_count" ]] && total_listening_ports=$listening_count
    
    # Create summary file
    local summary_file="$discovery_dir/scan_results/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1046.001a",
  "technique_name": "Network Service Discovery: Port Scanning",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_open_ports": $total_open_ports,
  "total_listening_ports": $total_listening_ports,
  "configuration": {
    "scan_targets": "$T1046_001A_SCAN_TARGETS",
    "scan_ports": "$T1046_001A_SCAN_PORTS",
    "scan_timeout": $T1046_001A_TIMEOUT,
    "scan_type": "$T1046_001A_SCAN_TYPE",
    "include_service_detection": $T1046_001A_INCLUDE_SERVICE_DETECTION,
    "include_banner_grabbing": $T1046_001A_INCLUDE_BANNER_GRABBING,
    "max_targets": $T1046_001A_MAX_TARGETS,
    "max_ports": $T1046_001A_MAX_PORTS
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1046_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_open_ports open ports and $total_listening_ports listening ports." >&2
    
    return 0
}

# Results processing and output
Process-Results() {
    local discovery_dir="$1"
    
    # Create metadata
    local metadata_file="$discovery_dir/metadata/execution_metadata.json"
    local metadata=$(cat <<EOF
{
  "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "technique_id": "T1046.001a",
  "technique_name": "Network Service Discovery: Port Scanning",
  "output_mode": "${T1046_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1046_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "scan_targets": "$T1046_001A_SCAN_TARGETS",
    "scan_ports": "$T1046_001A_SCAN_PORTS",
    "scan_timeout": $T1046_001A_TIMEOUT,
    "max_targets": $T1046_001A_MAX_TARGETS
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${T1046_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Network service discovery completed" >&2
            echo "[INFO] Results saved to: $discovery_dir" >&2
            ;;
        "stealth")
            # Minimal output for stealth mode
            ;;
        "none")
            # No output
            ;;
    esac
    
    return 0
}

# Main execution flow
main() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    local discovery_dir=$(Initialize-OutputStructure) || exit 1
    Perform-Discovery "$discovery_dir" || exit 1
    Process-Results "$discovery_dir"
}

main "$@"
