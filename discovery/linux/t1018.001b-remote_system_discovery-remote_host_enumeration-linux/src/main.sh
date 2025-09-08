
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1018_001B_DEBUG_MODE="${T1018_001B_DEBUG_MODE:-false}"
    export T1018_001B_TIMEOUT="${T1018_001B_TIMEOUT:-300}"
    export T1018_001B_FALLBACK_MODE="${T1018_001B_FALLBACK_MODE:-simulate}"
    export T1018_001B_OUTPUT_FORMAT="${T1018_001B_OUTPUT_FORMAT:-json}"
    export T1018_001B_POLICY_CHECK="${T1018_001B_POLICY_CHECK:-true}"
    export T1018_001B_MAX_SERVICES="${T1018_001B_MAX_SERVICES:-200}"
    export T1018_001B_INCLUDE_SYSTEM="${T1018_001B_INCLUDE_SYSTEM:-true}"
    export T1018_001B_DETAIL_LEVEL="${T1018_001B_DETAIL_LEVEL:-standard}"
    export T1018_001B_RESOLVE_HOSTNAMES="${T1018_001B_RESOLVE_HOSTNAMES:-true}"
    export T1018_001B_MAX_PROCESSES="${T1018_001B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1018.001a - Remote System Discovery: Remote Host Enumeration
# MITRE ATT&CK Technique: T1018.001
# Description: Discovers remote systems and hosts on the network, including host discovery, port scanning, and service enumeration

set -euo pipefail

# Default configuration
T1018_001B_OUTPUT_BASE="${T1018_001B_OUTPUT_BASE:-/tmp/mitre_results}"
T1018_001B_OUTPUT_MODE="${T1018_001B_OUTPUT_MODE:-simple}"
T1018_001B_SILENT_MODE="${T1018_001B_SILENT_MODE:-false}"
T1018_001B_TIMEOUT="${T1018_001B_TIMEOUT:-30}"

# Technique-specific configuration
T1018_001B_INCLUDE_HOST_DISCOVERY="${T1018_001B_INCLUDE_HOST_DISCOVERY:-true}"
T1018_001B_INCLUDE_PORT_SCANNING="${T1018_001B_INCLUDE_PORT_SCANNING:-true}"
T1018_001B_INCLUDE_SERVICE_DISCOVERY="${T1018_001B_INCLUDE_SERVICE_DISCOVERY:-true}"
T1018_001B_INCLUDE_NETWORK_SCANNING="${T1018_001B_INCLUDE_NETWORK_SCANNING:-true}"
T1018_001B_INCLUDE_DNS_ENUMERATION="${T1018_001B_INCLUDE_DNS_ENUMERATION:-true}"
T1018_001B_INCLUDE_REVERSE_DNS="${T1018_001B_INCLUDE_REVERSE_DNS:-true}"
T1018_001A_SCAN_TARGETS="${T1018_001A_SCAN_TARGETS:-localhost,127.0.0.1}"
T1018_001B_SCAN_PORTS="${T1018_001B_SCAN_PORTS:-22,80,443,8080}"
T1018_001B_SCAN_T1018_001B_TIMEOUT="${T1018_001B_SCAN_T1018_001B_TIMEOUT:-5}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1018_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1018_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1018_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "ping" "nc" "hostname" "dig" "nslookup" "host" "grep" "head" "tail" "awk" "cut" "tr" "sort" "uniq" "wc")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install jq netcat-openbsd dnsutils"
        log_info "  CentOS/RHEL/Fedora: sudo yum install jq nc bind-utils"
        log_info "  Arch Linux: sudo pacman -S jq netcat bind-tools"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1018_001B_INCLUDE_HOST_DISCOVERY" "T1018_001B_INCLUDE_PORT_SCANNING" 
                     "T1018_001B_INCLUDE_SERVICE_DISCOVERY" "T1018_001B_INCLUDE_NETWORK_SCANNING"
                     "T1018_001B_INCLUDE_DNS_ENUMERATION" "T1018_001B_INCLUDE_REVERSE_DNS")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
        fi
    done
    
    # Validate numeric environment variables
    local num_vars=("T1018_001B_SCAN_T1018_001B_TIMEOUT")
    
    for var in "${num_vars[@]}"; do
        local value="${!var}"
        if ! [[ "$value" =~ ^[0-9]+$ ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to '5'"
            export "$var=5"
        fi
    done
    
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
    
    # Check if we have network access
    if ! command -v ping &> /dev/null; then
        log_error "Cannot access 'ping' command - insufficient permissions"
        return 1
    fi
    
    # Check if jq is working
    if ! echo '{"test": "value"}' | jq -e . >/dev/null 2>&1; then
        log_error "jq is not working properly"
        return 1
    fi
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1018_001B_OUTPUT_BASE}/t1018.001b_remote_system_discovery_${timestamp}"
    
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
    log_info "Performing remote system discovery..."
    
    # Discover local network information
    Discover-LocalNetworkInfo "$discovery_dir"
    
    # Discover hosts
    if [[ "$T1018_001B_INCLUDE_HOST_DISCOVERY" == "true" ]]; then
        Discover-Hosts "$discovery_dir"
    fi
    
    # Scan ports
    if [[ "$T1018_001B_INCLUDE_PORT_SCANNING" == "true" ]]; then
        Discover-PortScanning "$discovery_dir"
    fi
    
    # Discover services
    if [[ "$T1018_001B_INCLUDE_SERVICE_DISCOVERY" == "true" ]]; then
        Discover-Services "$discovery_dir"
    fi
    
    # Scan network
    if [[ "$T1018_001B_INCLUDE_NETWORK_SCANNING" == "true" ]]; then
        Discover-NetworkScanning "$discovery_dir"
    fi
    
    # Enumerate DNS
    if [[ "$T1018_001B_INCLUDE_DNS_ENUMERATION" == "true" ]]; then
        Discover-DNSEnumeration "$discovery_dir"
    fi
    
    # Reverse DNS lookup
    if [[ "$T1018_001B_INCLUDE_REVERSE_DNS" == "true" ]]; then
        Discover-ReverseDNS "$discovery_dir"
    fi
    
    log_success "Remote system discovery completed"
}

# Discover local network information
Discover-LocalNetworkInfo() {
    local discovery_dir="$1"
    log_info "Discovering local network information..."
    
    local network_file="${discovery_dir}/local_network_info.json"
    
    # Get local network information
    local local_ip=$(hostname -I | awk '{print $1}' || echo "Unknown")
    local hostname=$(hostname || echo "Unknown")
    local domain=$(hostname -d 2>/dev/null || echo "Unknown")
    
    # Get network interfaces
    local interfaces=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -1 || echo "Unknown")
    
    # Get default gateway
    local gateway=$(ip route show default 2>/dev/null | awk '/default/ {print $3}' | head -1 || echo "Unknown")
    
    local network_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "local_network_info": {
    "local_ip": "$local_ip",
    "hostname": "$hostname",
    "domain": "$domain",
    "interface": "$interfaces",
    "gateway": "$gateway",
    "scan_targets": "$T1018_001A_SCAN_TARGETS",
    "scan_ports": "$T1018_001B_SCAN_PORTS"
  }
}
EOF
)
    
    echo "$network_info" | jq . > "$network_file"
    log_success "Local network information saved to: $network_file"
}

# Discover hosts
Discover-Hosts() {
    local discovery_dir="$1"
    log_info "Discovering hosts..."
    
    local hosts_file="${discovery_dir}/host_discovery.json"
    
    # Parse scan targets
    IFS=',' read -ra TARGETS <<< "$T1018_001A_SCAN_TARGETS"
    local host_info_array=()
    
    for target in "${TARGETS[@]}"; do
        local target=$(echo "$target" | tr -d ' ')
        if [[ -n "$target" ]]; then
            # Ping the target
            local ping_result=$(ping -c 1 -W "$T1018_001B_SCAN_T1018_001B_TIMEOUT" "$target" 2>/dev/null | grep -E "time=|unreachable|timeout" || echo "No response")
            local is_reachable=$([[ "$ping_result" == *"time="* ]] && echo "true" || echo "false")
            
            # Get hostname if possible
            local hostname=$(hostname 2>/dev/null || echo "Unknown")
            
            host_info_array+=("{\"target\":\"$target\",\"is_reachable\":$is_reachable,\"ping_result\":\"$ping_result\",\"hostname\":\"$hostname\"}")
        fi
    done
    
    local hosts_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host_discovery": {
    "targets": [$(IFS=,; echo "${host_info_array[*]}")]
  }
}
EOF
)
    
    echo "$hosts_info" | jq . > "$hosts_file"
    log_success "Host discovery saved to: $hosts_file"
}

# Discover port scanning
Discover-PortScanning() {
    local discovery_dir="$1"
    log_info "Discovering port scanning..."
    
    local ports_file="${discovery_dir}/port_scanning.json"
    
    # Parse scan targets and ports
    IFS=',' read -ra TARGETS <<< "$T1018_001A_SCAN_TARGETS"
    IFS=',' read -ra PORTS <<< "$T1018_001B_SCAN_PORTS"
    local port_info_array=()
    
    for target in "${TARGETS[@]}"; do
        local target=$(echo "$target" | tr -d ' ')
        if [[ -n "$target" ]]; then
            local target_ports=()
            
            for port in "${PORTS[@]}"; do
                local port=$(echo "$port" | tr -d ' ')
                if [[ -n "$port" ]]; then
                    # Scan port using nc
                    local nc_result=$(timeout "$T1018_001B_SCAN_T1018_001B_TIMEOUT" nc -zv "$target" "$port" 2>&1 || echo "Connection failed")
                    local is_open=$([[ "$nc_result" == *"succeeded"* ]] && echo "true" || echo "false")
                    
                    target_ports+=("{\"port\":$port,\"is_open\":$is_open,\"result\":\"$nc_result\"}")
                fi
            done
            
            port_info_array+=("{\"target\":\"$target\",\"ports\":[$(IFS=,; echo "${target_ports[*]}")]}")
        fi
    done
    
    local ports_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "port_scanning": {
    "targets": [$(IFS=,; echo "${port_info_array[*]}")]
  }
}
EOF
)
    
    echo "$ports_info" | jq . > "$ports_file"
    log_success "Port scanning saved to: $ports_file"
}

# Discover services
Discover-Services() {
    local discovery_dir="$1"
    log_info "Discovering services..."
    
    local services_file="${discovery_dir}/service_discovery.json"
    
    # Common services to check
    local common_services=("ssh" "http" "https" "ftp" "smtp" "pop3" "imap" "dns" "dhcp" "ntp")
    local service_info_array=()
    
    for service in "${common_services[@]}"; do
        # Check if service is running locally
        local is_running=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
        local is_enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
        
        service_info_array+=("{\"service\":\"$service\",\"is_running\":\"$is_running\",\"is_enabled\":\"$is_enabled\"}")
    done
    
    # Check for common listening services
    local listening_services=$(ss -tuln state listening 2>/dev/null | grep -E ":(22|80|443|21|25|110|143|53|67|123)" | awk '{print "{\"port\":\""$5"\",\"protocol\":\""$1"\"}"}' | jq -s . || echo "[]")
    
    local services_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "service_discovery": {
    "common_services": [$(IFS=,; echo "${service_info_array[*]}")],
    "listening_services": $listening_services
  }
}
EOF
)
    
    echo "$services_info" | jq . > "$services_file"
    log_success "Service discovery saved to: $services_file"
}

# Discover network scanning
Discover-NetworkScanning() {
    local discovery_dir="$1"
    log_info "Discovering network scanning..."
    
    local network_scan_file="${discovery_dir}/network_scanning.json"
    
    # Get local network range
    local local_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    local network_range=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3".0/24"}' || echo "127.0.0.0/24")
    
    # Scan local network (limited to avoid excessive scanning)
    local network_hosts=()
    local base_ip=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3}' || echo "127.0.0")
    
    # Scan a few hosts in the local network
    for i in {1..5}; do
        local test_ip="$base_ip.$i"
        if [[ "$test_ip" != "$local_ip" ]]; then
            local ping_result=$(ping -c 1 -W 1 "$test_ip" 2>/dev/null | grep -E "time=|unreachable|timeout" || echo "No response")
            local is_reachable=$([[ "$ping_result" == *"time="* ]] && echo "true" || echo "false")
            
            network_hosts+=("{\"ip\":\"$test_ip\",\"is_reachable\":$is_reachable,\"ping_result\":\"$ping_result\"}")
        fi
    done
    
    local network_scan_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "network_scanning": {
    "local_ip": "$local_ip",
    "network_range": "$network_range",
    "scanned_hosts": [$(IFS=,; echo "${network_hosts[*]}")]
  }
}
EOF
)
    
    echo "$network_scan_info" | jq . > "$network_scan_file"
    log_success "Network scanning saved to: $network_scan_file"
}

# Discover DNS enumeration
Discover-DNSEnumeration() {
    local discovery_dir="$1"
    log_info "Discovering DNS enumeration..."
    
    local dns_file="${discovery_dir}/dns_enumeration.json"
    
    # Get local hostname and domain
    local hostname=$(hostname || echo "Unknown")
    local domain=$(hostname -d 2>/dev/null || echo "Unknown")
    
    # DNS queries
    local dns_queries=()
    
    # Query local hostname
    if [[ "$hostname" != "Unknown" ]]; then
        local hostname_ip=$(dig +short "$hostname" 2>/dev/null | head -1 || echo "Unknown")
        dns_queries+=("{\"query\":\"$hostname\",\"result\":\"$hostname_ip\",\"type\":\"A\"}")
    fi
    
    # Query local domain
    if [[ "$domain" != "Unknown" ]]; then
        local domain_ns=$(dig +short NS "$domain" 2>/dev/null | head -1 || echo "Unknown")
        dns_queries+=("{\"query\":\"$domain\",\"result\":\"$domain_ns\",\"type\":\"NS\"}")
    fi
    
    # Query common DNS servers
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    for dns_server in "${dns_servers[@]}"; do
        local dns_response=$(dig +short @"$dns_server" google.com 2>/dev/null | head -1 || echo "No response")
        dns_queries+=("{\"query\":\"google.com\",\"dns_server\":\"$dns_server\",\"result\":\"$dns_response\",\"type\":\"A\"}")
    done
    
    local dns_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "dns_enumeration": {
    "hostname": "$hostname",
    "domain": "$domain",
    "queries": [$(IFS=,; echo "${dns_queries[*]}")]
  }
}
EOF
)
    
    echo "$dns_info" | jq . > "$dns_file"
    log_success "DNS enumeration saved to: $dns_file"
}

# Discover reverse DNS
Discover-ReverseDNS() {
    local discovery_dir="$1"
    log_info "Discovering reverse DNS..."
    
    local reverse_dns_file="${discovery_dir}/reverse_dns.json"
    
    # Get local IP
    local local_ip=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    
    # Reverse DNS queries
    local reverse_queries=()
    
    # Reverse DNS for local IP
    local reverse_hostname=$(dig +short -x "$local_ip" 2>/dev/null | head -1 || echo "Unknown")
    reverse_queries+=("{\"ip\":\"$local_ip\",\"hostname\":\"$reverse_hostname\"}")
    
    # Reverse DNS for common IPs
    local common_ips=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    for ip in "${common_ips[@]}"; do
        local hostname=$(dig +short -x "$ip" 2>/dev/null | head -1 || echo "Unknown")
        reverse_queries+=("{\"ip\":\"$ip\",\"hostname\":\"$hostname\"}")
    done
    
    # Reverse DNS for local network
    local base_ip=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3}' || echo "127.0.0")
    for i in {1..3}; do
        local test_ip="$base_ip.$i"
        if [[ "$test_ip" != "$local_ip" ]]; then
            local hostname=$(dig +short -x "$test_ip" 2>/dev/null | head -1 || echo "Unknown")
            reverse_queries+=("{\"ip\":\"$test_ip\",\"hostname\":\"$hostname\"}")
        fi
    done
    
    local reverse_dns_info=$(cat <<EOF
{
  "technique": "T1018.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "reverse_dns": {
    "local_ip": "$local_ip",
    "queries": [$(IFS=,; echo "${reverse_queries[*]}")]
  }
}
EOF
)
    
    echo "$reverse_dns_info" | jq . > "$reverse_dns_file"
    log_success "Reverse DNS saved to: $reverse_dns_file"
}

# Step 6: Process results
Process-Results() {
    local discovery_dir="$1"
    log_info "Processing discovery results..."
    
    # Create summary file
    local summary_file="${discovery_dir}/summary.json"
    
    # Count files and create summary
    local file_count=$(find "$discovery_dir" -name "*.json" | wc -l)
    
    local summary=$(cat <<EOF
{
  "technique": "T1018.001a",
  "name": "Remote System Discovery: Remote Host Enumeration",
  "description": "Discovers remote systems and hosts on the network, including host discovery, port scanning, and service enumeration",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "local_network_info.json",
    "host_discovery.json",
    "port_scanning.json",
    "service_discovery.json",
    "network_scanning.json",
    "dns_enumeration.json",
    "reverse_dns.json"
  ],
  "configuration": {
    "include_host_discovery": $T1018_001B_INCLUDE_HOST_DISCOVERY,
    "include_port_scanning": $T1018_001B_INCLUDE_PORT_SCANNING,
    "include_service_discovery": $T1018_001B_INCLUDE_SERVICE_DISCOVERY,
    "include_network_scanning": $T1018_001B_INCLUDE_NETWORK_SCANNING,
    "include_dns_enumeration": $T1018_001B_INCLUDE_DNS_ENUMERATION,
    "include_reverse_dns": $T1018_001B_INCLUDE_REVERSE_DNS,
    "scan_targets": "$T1018_001A_SCAN_TARGETS",
    "scan_ports": "$T1018_001B_SCAN_PORTS",
    "scan_timeout": $T1018_001B_SCAN_T1018_001B_TIMEOUT
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Remote system discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "Remote system discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
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
            log_success "Remote system discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
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
