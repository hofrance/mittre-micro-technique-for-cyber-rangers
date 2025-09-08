
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1018_002B_DEBUG_MODE="${T1018_002B_DEBUG_MODE:-false}"
    export T1018_002B_TIMEOUT="${T1018_002B_TIMEOUT:-300}"
    export T1018_002B_FALLBACK_MODE="${T1018_002B_FALLBACK_MODE:-simulate}"
    export T1018_002B_OUTPUT_FORMAT="${T1018_002B_OUTPUT_FORMAT:-json}"
    export T1018_002B_POLICY_CHECK="${T1018_002B_POLICY_CHECK:-true}"
    export T1018_002B_MAX_SERVICES="${T1018_002B_MAX_SERVICES:-200}"
    export T1018_002B_INCLUDE_SYSTEM="${T1018_002B_INCLUDE_SYSTEM:-true}"
    export T1018_002B_DETAIL_LEVEL="${T1018_002B_DETAIL_LEVEL:-standard}"
    export T1018_002B_RESOLVE_HOSTNAMES="${T1018_002B_RESOLVE_HOSTNAMES:-true}"
    export T1018_002B_MAX_PROCESSES="${T1018_002B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1018.002b - Remote System Discovery: Port Scanning
# MITRE ATT&CK Technique: T1018.002
# Description: Performs port scanning on remote systems to discover open ports and services

set -euo pipefail

# Default configuration
T1018_002B_OUTPUT_BASE="${T1018_002B_OUTPUT_BASE:-/tmp/mitre_results}"
T1018_002B_OUTPUT_MODE="${T1018_002B_OUTPUT_MODE:-simple}"
T1018_002B_SILENT_MODE="${T1018_002B_SILENT_MODE:-false}"
T1018_002B_TIMEOUT="${T1018_002B_TIMEOUT:-30}"

# Technique-specific configuration
T1018_002B_SCAN_TARGETS="${T1018_002B_SCAN_TARGETS:-127.0.0.1,localhost}"
T1018_002B_SCAN_PORTS="${T1018_002B_SCAN_PORTS:-22,80,443,8080,3306,5432}"
T1018_002B_SCAN_TYPE="${T1018_002B_SCAN_TYPE:-tcp}"
T1018_002B_INCLUDE_SERVICE_DETECTION="${T1018_002B_INCLUDE_SERVICE_DETECTION:-true}"
T1018_002B_INCLUDE_VERSION_DETECTION="${T1018_002B_INCLUDE_VERSION_DETECTION:-true}"
T1018_002B_SCAN_T1018_002B_TIMEOUT="${T1018_002B_SCAN_T1018_002B_TIMEOUT:-5}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1018_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1018_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1018_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "nc" "timeout" "cat" "grep" "awk" "cut" "tr" "ping")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install netcat-openbsd"
        log_info "  CentOS/RHEL/Fedora: sudo yum install nc"
        log_info "  Arch Linux: sudo pacman -S netcat"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1018_002B_INCLUDE_SERVICE_DETECTION" "T1018_002B_INCLUDE_VERSION_DETECTION")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
        fi
    done
    
    # Validate scan type
    if [[ "$T1018_002B_SCAN_TYPE" != "tcp" && "$T1018_002B_SCAN_TYPE" != "udp" ]]; then
        log_warning "Invalid scan type: '$T1018_002B_SCAN_TYPE'. Defaulting to 'tcp'"
        export T1018_002B_SCAN_TYPE="tcp"
    fi
    
    log_success "Environment variables loaded successfully"
}

# Step 3: Validate system preconditions
Validate-SystemPreconditions() {
    log_info "Validating system preconditions..."
    
    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "This technique is designed for Linux systems only"
        return 1
    fi
    
    # Check if targets are specified
    if [[ -z "$T1018_002B_SCAN_TARGETS" ]]; then
        log_error "No scan targets specified"
        return 1
    fi
    
    # Check if ports are specified
    if [[ -z "$T1018_002B_SCAN_PORTS" ]]; then
        log_error "No scan ports specified"
        return 1
    fi
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1018_002B_OUTPUT_BASE}/t1018.002b_port_scanning_${timestamp}"
    
    if mkdir -p "$discovery_dir"; then
        log_success "Output directory created: $discovery_dir"
        echo "$discovery_dir"
    else
        log_error "Failed to create output directory: $discovery_dir"
        return 1
    fi
}

# Step 5: Perform discovery
Perform-Discovery() {
    local discovery_dir="$1"
    log_info "Performing port scanning..."
    
    # Parse targets and ports
    IFS=',' read -ra TARGETS <<< "$T1018_002B_SCAN_TARGETS"
    IFS=',' read -ra PORTS <<< "$T1018_002B_SCAN_PORTS"
    
    # Perform port scanning
    Scan-Ports "$discovery_dir" "${TARGETS[@]}" "${PORTS[@]}"
    
    # Perform service detection if enabled
    if [[ "$T1018_002B_INCLUDE_SERVICE_DETECTION" == "true" ]]; then
        Detect-Services "$discovery_dir" "${TARGETS[@]}" "${PORTS[@]}"
    fi
    
    # Perform version detection if enabled
    if [[ "$T1018_002B_INCLUDE_VERSION_DETECTION" == "true" ]]; then
        Detect-Versions "$discovery_dir" "${TARGETS[@]}" "${PORTS[@]}"
    fi
    
    log_success "Port scanning completed"
}

# Scan ports
Scan-Ports() {
    local discovery_dir="$1"
    shift
    local targets=("$@")
    shift ${#targets[@]}
    local ports=("$@")
    
    log_info "Scanning ports..."
    
    local scan_file="${discovery_dir}/port_scan_results.json"
    local scan_results=()
    
    for target in "${targets[@]}"; do
        log_info "Scanning target: $target"
        
        # Check if target is reachable
        if ping -c 1 -W 2 "$target" &> /dev/null; then
            log_info "Target $target is reachable"
            
            for port in "${ports[@]}"; do
                log_info "Scanning port $port on $target"
                
                # Perform port scan
                local scan_result=""
                if timeout "$T1018_002B_SCAN_T1018_002B_TIMEOUT" nc -z -w "$T1018_002B_SCAN_T1018_002B_TIMEOUT" "$target" "$port" 2>/dev/null; then
                    scan_result="open"
                    log_success "Port $port on $target is open"
                else
                    scan_result="closed"
                    log_info "Port $port on $target is closed"
                fi
                
                local port_info=$(cat <<EOF
{
  "target": "$target",
  "port": "$port",
  "protocol": "$T1018_002B_SCAN_TYPE",
  "status": "$scan_result",
  "scan_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
                scan_results+=("$port_info")
            done
        else
            log_warning "Target $target is not reachable"
            
            # Add unreachable target info
            for port in "${ports[@]}"; do
                local port_info=$(cat <<EOF
{
  "target": "$target",
  "port": "$port",
  "protocol": "$T1018_002B_SCAN_TYPE",
  "status": "unreachable",
  "scan_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
                scan_results+=("$port_info")
            done
        fi
    done
    
    # Create JSON output
    local scan_results_json=$(printf '%s\n' "${scan_results[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1018.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "port_scan": {
    "scan_type": "$T1018_002B_SCAN_TYPE",
    "targets": $(printf '%s\n' "${targets[@]}" | jq -R . | jq -s .),
    "ports": $(printf '%s\n' "${ports[@]}" | jq -R . | jq -s .),
    "timeout": "$T1018_002B_SCAN_T1018_002B_TIMEOUT",
    "results": $scan_results_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$scan_file"
    log_success "Port scan results saved to: $scan_file"
}

# Detect services
Detect-Services() {
    local discovery_dir="$1"
    shift
    local targets=("$@")
    shift ${#targets[@]}
    local ports=("$@")
    
    log_info "Detecting services..."
    
    local services_file="${discovery_dir}/service_detection.json"
    local service_results=()
    
    for target in "${targets[@]}"; do
        if ping -c 1 -W 2 "$target" &> /dev/null; then
            for port in "${ports[@]}"; do
                # Check if port is open first
                if timeout "$T1018_002B_SCAN_T1018_002B_TIMEOUT" nc -z -w "$T1018_002B_SCAN_T1018_002B_TIMEOUT" "$target" "$port" 2>/dev/null; then
                    log_info "Detecting service on $target:$port"
                    
                    # Try to get service banner
                    local banner=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -5 | tr '\n' ' ' | jq -R . || echo "null")
                    
                    # Determine service based on port
                    local service="unknown"
                    case "$port" in
                        22) service="ssh" ;;
                        80) service="http" ;;
                        443) service="https" ;;
                        8080) service="http-proxy" ;;
                        3306) service="mysql" ;;
                        5432) service="postgresql" ;;
                        21) service="ftp" ;;
                        23) service="telnet" ;;
                        25) service="smtp" ;;
                        110) service="pop3" ;;
                        143) service="imap" ;;
                        993) service="imaps" ;;
                        995) service="pop3s" ;;
                        *) service="unknown" ;;
                    esac
                    
                    local service_info=$(cat <<EOF
{
  "target": "$target",
  "port": "$port",
  "service": "$service",
  "banner": $banner,
  "detection_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
                    service_results+=("$service_info")
                fi
            done
        fi
    done
    
    # Create JSON output
    local service_results_json=$(printf '%s\n' "${service_results[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1018.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "service_detection": {
    "services": $service_results_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$services_file"
    log_success "Service detection saved to: $services_file"
}

# Detect versions
Detect-Versions() {
    local discovery_dir="$1"
    shift
    local targets=("$@")
    shift ${#targets[@]}
    local ports=("$@")
    
    log_info "Detecting versions..."
    
    local versions_file="${discovery_dir}/version_detection.json"
    local version_results=()
    
    for target in "${targets[@]}"; do
        if ping -c 1 -W 2 "$target" &> /dev/null; then
            for port in "${ports[@]}"; do
                # Check if port is open first
                if timeout "$T1018_002B_SCAN_T1018_002B_TIMEOUT" nc -z -w "$T1018_002B_SCAN_T1018_002B_TIMEOUT" "$target" "$port" 2>/dev/null; then
                    log_info "Detecting version on $target:$port"
                    
                    # Try to get version information
                    local version_info="unknown"
                    local version_data="null"
                    
                    case "$port" in
                        22)
                            # SSH version detection
                            version_data=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -1 | jq -R . || echo "null")
                            ;;
                        80|443|8080)
                            # HTTP version detection
                            version_data=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -1 | jq -R . || echo "null")
                            ;;
                        3306)
                            # MySQL version detection
                            version_data=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -1 | jq -R . || echo "null")
                            ;;
                        5432)
                            # PostgreSQL version detection
                            version_data=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -1 | jq -R . || echo "null")
                            ;;
                        *)
                            # Generic version detection
                            version_data=$(timeout 3 nc -w 3 "$target" "$port" 2>/dev/null | head -1 | jq -R . || echo "null")
                            ;;
                    esac
                    
                    local version_result=$(cat <<EOF
{
  "target": "$target",
  "port": "$port",
  "version": "$version_info",
  "version_data": $version_data,
  "detection_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
                    version_results+=("$version_result")
                fi
            done
        fi
    done
    
    # Create JSON output
    local version_results_json=$(printf '%s\n' "${version_results[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1018.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version_detection": {
    "versions": $version_results_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$versions_file"
    log_success "Version detection saved to: $versions_file"
}

# Step 6: Process results
Process-Results() {
    local discovery_dir="$1"
    log_info "Processing discovery results..."
    
    # Create summary file
    local summary_file="${discovery_dir}/summary.json"
    
    # Count files and create summary
    local file_count=$(find "$discovery_dir" -name "*.json" | wc -l)
    
    # Count open ports
    local open_ports=$(jq -r '.port_scan.results[] | select(.status == "open") | .port' "$discovery_dir/port_scan_results.json" 2>/dev/null | wc -l || echo "0")
    
    local summary=$(cat <<EOF
{
  "technique": "T1018.002b",
  "name": "Remote System Discovery: Port Scanning",
  "description": "Performs port scanning on remote systems to discover open ports and services",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "port_scan_results.json",
    "service_detection.json",
    "version_detection.json"
  ],
  "scan_summary": {
    "targets": "$T1018_002B_SCAN_TARGETS",
    "ports": "$T1018_002B_SCAN_PORTS",
    "scan_type": "$T1018_002B_SCAN_TYPE",
    "open_ports_found": $open_ports,
    "timeout": "$T1018_002B_SCAN_T1018_002B_TIMEOUT"
  },
  "configuration": {
    "include_service_detection": $T1018_002B_INCLUDE_SERVICE_DETECTION,
    "include_version_detection": $T1018_002B_INCLUDE_VERSION_DETECTION
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Port scanning completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Open ports found: $open_ports"
            ;;
        "debug")
            log_success "Port scanning completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Open ports found: $open_ports"
            echo "Summary:"
            echo "$summary" | jq .
            ;;
        "stealth")
            # Minimal output
            ;;
        "none")
            # No output
            ;;
        *)
            log_success "Port scanning completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Open ports found: $open_ports"
            ;;
    esac
}

# Main function
main() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    local discovery_dir=$(Initialize-OutputStructure) || exit 1
    Perform-Discovery "$discovery_dir" || exit 1
    Process-Results "$discovery_dir"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

