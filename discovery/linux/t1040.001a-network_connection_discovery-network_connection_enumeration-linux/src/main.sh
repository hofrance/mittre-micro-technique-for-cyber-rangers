
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1040_001A_DEBUG_MODE="${T1040_001A_DEBUG_MODE:-false}"
    export T1040_001A_TIMEOUT="${T1040_001A_TIMEOUT:-300}"
    export T1040_001A_FALLBACK_MODE="${T1040_001A_FALLBACK_MODE:-simulate}"
    export T1040_001A_OUTPUT_FORMAT="${T1040_001A_OUTPUT_FORMAT:-json}"
    export T1040_001A_POLICY_CHECK="${T1040_001A_POLICY_CHECK:-true}"
    export T1040_001A_MAX_SERVICES="${T1040_001A_MAX_SERVICES:-200}"
    export T1040_001A_INCLUDE_SYSTEM="${T1040_001A_INCLUDE_SYSTEM:-true}"
    export T1040_001A_DETAIL_LEVEL="${T1040_001A_DETAIL_LEVEL:-standard}"
    export T1040_001A_RESOLVE_HOSTNAMES="${T1040_001A_RESOLVE_HOSTNAMES:-true}"
    export T1040_001A_MAX_PROCESSES="${T1040_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1040.001a - Network Connection Discovery: Network Connection Enumeration
# MITRE ATT&CK Technique: T1040.001
# Description: Discovers active network connections, listening ports, and network communication patterns

set -euo pipefail

# Default configuration
T1040_001A_OUTPUT_BASE="${T1040_001A_OUTPUT_BASE:-/tmp/mitre_results}"
T1040_001A_OUTPUT_MODE="${T1040_001A_OUTPUT_MODE:-simple}"
T1040_001A_SILENT_MODE="${T1040_001A_SILENT_MODE:-false}"
T1040_001A_TIMEOUT="${T1040_001A_TIMEOUT:-30}"

# Technique-specific configuration
T1040_001A_INCLUDE_ACTIVE_CONNECTIONS="${T1040_001A_INCLUDE_ACTIVE_CONNECTIONS:-true}"
T1040_001A_INCLUDE_LISTENING_PORTS="${T1040_001A_INCLUDE_LISTENING_PORTS:-true}"
T1040_001A_INCLUDE_ROUTING_TABLE="${T1040_001A_INCLUDE_ROUTING_TABLE:-true}"
T1040_001A_INCLUDE_ARP_TABLE="${T1040_001A_INCLUDE_ARP_TABLE:-true}"
T1040_001A_INCLUDE_NETWORK_INTERFACES="${T1040_001A_INCLUDE_NETWORK_INTERFACES:-true}"
T1040_001A_INCLUDE_DNS_RESOLUTION="${T1040_001A_INCLUDE_DNS_RESOLUTION:-true}"
T1040_001A_INCLUDE_NETSTAT="${T1040_001A_INCLUDE_NETSTAT:-true}"
T1040_001A_INCLUDE_SS="${T1040_001A_INCLUDE_SS:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1040_001A_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1040_001A_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1040_001A_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "ip" "ss" "netstat" "cat" "grep" "head" "tail" "awk" "cut" "tr" "sort" "uniq" "wc")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install jq net-tools"
        log_info "  CentOS/RHEL/Fedora: sudo yum install jq net-tools"
        log_info "  Arch Linux: sudo pacman -S jq net-tools"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1040_001A_INCLUDE_ACTIVE_CONNECTIONS" "T1040_001A_INCLUDE_LISTENING_PORTS" 
                     "T1040_001A_INCLUDE_ROUTING_TABLE" "T1040_001A_INCLUDE_ARP_TABLE"
                     "T1040_001A_INCLUDE_NETWORK_INTERFACES" "T1040_001A_INCLUDE_DNS_RESOLUTION"
                     "T1040_001A_INCLUDE_NETSTAT" "T1040_001A_INCLUDE_SS")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
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
    if ! command -v ip &> /dev/null; then
        log_error "Cannot access 'ip' command - insufficient permissions"
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
    local discovery_dir="${T1040_001A_OUTPUT_BASE}/t1040.001a_network_connection_discovery_${timestamp}"
    
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
    log_info "Performing network connection discovery..."
    
    # Discover active connections
    if [[ "$T1040_001A_INCLUDE_ACTIVE_CONNECTIONS" == "true" ]]; then
        Discover-ActiveConnections "$discovery_dir"
    fi
    
    # Discover listening ports
    if [[ "$T1040_001A_INCLUDE_LISTENING_PORTS" == "true" ]]; then
        Discover-ListeningPorts "$discovery_dir"
    fi
    
    # Discover routing table
    if [[ "$T1040_001A_INCLUDE_ROUTING_TABLE" == "true" ]]; then
        Discover-RoutingTable "$discovery_dir"
    fi
    
    # Discover ARP table
    if [[ "$T1040_001A_INCLUDE_ARP_TABLE" == "true" ]]; then
        Discover-ARPTable "$discovery_dir"
    fi
    
    # Discover network interfaces
    if [[ "$T1040_001A_INCLUDE_NETWORK_INTERFACES" == "true" ]]; then
        Discover-NetworkInterfaces "$discovery_dir"
    fi
    
    # Discover DNS resolution
    if [[ "$T1040_001A_INCLUDE_DNS_RESOLUTION" == "true" ]]; then
        Discover-DNSResolution "$discovery_dir"
    fi
    
    # Discover netstat information
    if [[ "$T1040_001A_INCLUDE_NETSTAT" == "true" ]]; then
        Discover-NetstatInfo "$discovery_dir"
    fi
    
    # Discover ss information
    if [[ "$T1040_001A_INCLUDE_SS" == "true" ]]; then
        Discover-SSInfo "$discovery_dir"
    fi
    
    log_success "Network connection discovery completed"
}

# Discover active connections
Discover-ActiveConnections() {
    local discovery_dir="$1"
    log_info "Discovering active connections..."
    
    local connections_file="${discovery_dir}/active_connections.json"
    
    # Get active connections using ss
    local active_connections=$(ss -tuln 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\"}"}' | jq -s . || echo "[]")
    
    # Get established connections
    local established_connections=$(ss -tuln state established 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\"}"}' | jq -s . || echo "[]")
    
    local connections_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "active_connections": {
    "all_connections": $active_connections,
    "established_connections": $established_connections
  }
}
EOF
)
    
    echo "$connections_info" | jq . > "$connections_file"
    log_success "Active connections saved to: $connections_file"
}

# Discover listening ports
Discover-ListeningPorts() {
    local discovery_dir="$1"
    log_info "Discovering listening ports..."
    
    local listening_file="${discovery_dir}/listening_ports.json"
    
    # Get listening ports using ss
    local listening_ports=$(ss -tuln state listening 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\"}"}' | jq -s . || echo "[]")
    
    # Get listening ports with process information
    local listening_with_process=$(ss -tulnp state listening 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\",\"process\":\""$6"\"}"}' | jq -s . || echo "[]")
    
    local listening_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "listening_ports": {
    "basic_listening": $listening_ports,
    "listening_with_process": $listening_with_process
  }
}
EOF
)
    
    echo "$listening_info" | jq . > "$listening_file"
    log_success "Listening ports saved to: $listening_file"
}

# Discover routing table
Discover-RoutingTable() {
    local discovery_dir="$1"
    log_info "Discovering routing table..."
    
    local routing_file="${discovery_dir}/routing_table.json"
    
    # Get routing table
    local routing_table=$(ip route show 2>/dev/null | awk '{print "{\"destination\":\""$1"\",\"gateway\":\""$3"\",\"interface\":\""$5"\",\"flags\":\""$2"\"}"}' | jq -s . || echo "[]")
    
    # Get default route
    local default_route=$(ip route show default 2>/dev/null | awk '{print "{\"destination\":\""$1"\",\"gateway\":\""$3"\",\"interface\":\""$5"\",\"flags\":\""$2"\"}"}' | jq -s . || echo "[]")
    
    local routing_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "routing_table": {
    "all_routes": $routing_table,
    "default_routes": $default_route
  }
}
EOF
)
    
    echo "$routing_info" | jq . > "$routing_file"
    log_success "Routing table saved to: $routing_file"
}

# Discover ARP table
Discover-ARPTable() {
    local discovery_dir="$1"
    log_info "Discovering ARP table..."
    
    local arp_file="${discovery_dir}/arp_table.json"
    
    # Get ARP table
    local arp_table=$(ip neigh show 2>/dev/null | awk '{print "{\"ip_address\":\""$1"\",\"mac_address\":\""$5"\",\"interface\":\""$3"\",\"state\":\""$6"\"}"}' | jq -s . || echo "[]")
    
    # Get ARP table using arp command
    local arp_command=$(arp -n 2>/dev/null | grep -v '^Address' | awk '{print "{\"address\":\""$1"\",\"hwtype\":\""$2"\",\"hwaddress\":\""$3"\",\"flags\":\""$4"\",\"mask\":\""$5"\",\"iface\":\""$6"\"}"}' | jq -s . || echo "[]")
    
    local arp_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "arp_table": {
    "ip_neigh": $arp_table,
    "arp_command": $arp_command
  }
}
EOF
)
    
    echo "$arp_info" | jq . > "$arp_file"
    log_success "ARP table saved to: $arp_file"
}

# Discover network interfaces
Discover-NetworkInterfaces() {
    local discovery_dir="$1"
    log_info "Discovering network interfaces..."
    
    local interfaces_file="${discovery_dir}/network_interfaces.json"
    
    # Get network interfaces
    local interfaces=$(ip addr show 2>/dev/null | awk '/^[0-9]+:/ {iface=$2; gsub(/:/, "", iface); next} /inet / {print "{\"interface\":\""iface"\",\"family\":\""$1"\",\"address\":\""$2"\",\"scope\":\""$3"\",\"flags\":\""$4"\"}"}' | jq -s . || echo "[]")
    
    # Get interface statistics
    local interface_stats=$(cat /proc/net/dev 2>/dev/null | grep -v '^Inter' | grep -v '^ face' | awk '{print "{\"interface\":\""$1"\",\"rx_bytes\":\""$2"\",\"rx_packets\":\""$3"\",\"rx_errors\":\""$4"\",\"rx_dropped\":\""$5"\",\"tx_bytes\":\""$10"\",\"tx_packets\":\""$11"\",\"tx_errors\":\""$12"\",\"tx_dropped\":\""$13"\"}"}' | jq -s . || echo "[]")
    
    local interfaces_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "network_interfaces": {
    "interfaces": $interfaces,
    "statistics": $interface_stats
  }
}
EOF
)
    
    echo "$interfaces_info" | jq . > "$interfaces_file"
    log_success "Network interfaces saved to: $interfaces_file"
}

# Discover DNS resolution
Discover-DNSResolution() {
    local discovery_dir="$1"
    log_info "Discovering DNS resolution..."
    
    local dns_file="${discovery_dir}/dns_resolution.json"
    
    # Get DNS servers from resolv.conf
    local dns_servers=$(cat /etc/resolv.conf 2>/dev/null | grep '^nameserver' | awk '{print "{\"nameserver\":\""$2"\"}"}' | jq -s . || echo "[]")
    
    # Get search domains
    local search_domains=$(cat /etc/resolv.conf 2>/dev/null | grep '^search' | awk '{print "{\"search\":\""$2"\"}"}' | jq -s . || echo "[]")
    
    # Get domain
    local domain=$(cat /etc/resolv.conf 2>/dev/null | grep '^domain' | awk '{print "{\"domain\":\""$2"\"}"}' | jq -s . || echo "[]")
    
    local dns_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "dns_resolution": {
    "nameservers": $dns_servers,
    "search_domains": $search_domains,
    "domain": $domain
  }
}
EOF
)
    
    echo "$dns_info" | jq . > "$dns_file"
    log_success "DNS resolution saved to: $dns_file"
}

# Discover netstat information
Discover-NetstatInfo() {
    local discovery_dir="$1"
    log_info "Discovering netstat information..."
    
    local netstat_file="${discovery_dir}/netstat_info.json"
    
    # Get netstat information
    local netstat_all=$(netstat -tuln 2>/dev/null | grep -v '^Active' | grep -v '^Proto' | awk '{print "{\"proto\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"foreign_address\":\""$5"\",\"state\":\""$6"\"}"}' | jq -s . || echo "[]")
    
    # Get netstat with process information
    local netstat_process=$(netstat -tulnp 2>/dev/null | grep -v '^Active' | grep -v '^Proto' | awk '{print "{\"proto\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"foreign_address\":\""$5"\",\"state\":\""$6"\",\"pid_program\":\""$7"\"}"}' | jq -s . || echo "[]")
    
    local netstat_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "netstat_info": {
    "all_connections": $netstat_all,
    "connections_with_process": $netstat_process
  }
}
EOF
)
    
    echo "$netstat_info" | jq . > "$netstat_file"
    log_success "Netstat information saved to: $netstat_file"
}

# Discover ss information
Discover-SSInfo() {
    local discovery_dir="$1"
    log_info "Discovering ss information..."
    
    local ss_file="${discovery_dir}/ss_info.json"
    
    # Get ss information for all protocols
    local ss_all=$(ss -tuln 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\"}"}' | jq -s . || echo "[]")
    
    # Get ss information with process details
    local ss_process=$(ss -tulnp 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\",\"process\":\""$6"\"}"}' | jq -s . || echo "[]")
    
    # Get ss information for specific states
    local ss_listening=$(ss -tuln state listening 2>/dev/null | grep -v '^State' | awk '{print "{\"state\":\""$1"\",\"recv_q\":\""$2"\",\"send_q\":\""$3"\",\"local_address\":\""$4"\",\"peer_address\":\""$5"\"}"}' | jq -s . || echo "[]")
    
    local ss_info=$(cat <<EOF
{
  "technique": "T1040.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "ss_info": {
    "all_connections": $ss_all,
    "connections_with_process": $ss_process,
    "listening_connections": $ss_listening
  }
}
EOF
)
    
    echo "$ss_info" | jq . > "$ss_file"
    log_success "SS information saved to: $ss_file"
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
  "technique": "T1040.001a",
  "name": "Network Connection Discovery: Network Connection Enumeration",
  "description": "Discovers active network connections, listening ports, and network communication patterns",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "active_connections.json",
    "listening_ports.json",
    "routing_table.json",
    "arp_table.json",
    "network_interfaces.json",
    "dns_resolution.json",
    "netstat_info.json",
    "ss_info.json"
  ],
  "configuration": {
    "include_active_connections": $T1040_001A_INCLUDE_ACTIVE_CONNECTIONS,
    "include_listening_ports": $T1040_001A_INCLUDE_LISTENING_PORTS,
    "include_routing_table": $T1040_001A_INCLUDE_ROUTING_TABLE,
    "include_arp_table": $T1040_001A_INCLUDE_ARP_TABLE,
    "include_network_interfaces": $T1040_001A_INCLUDE_NETWORK_INTERFACES,
    "include_dns_resolution": $T1040_001A_INCLUDE_DNS_RESOLUTION,
    "include_netstat": $T1040_001A_INCLUDE_NETSTAT,
    "include_ss": $T1040_001A_INCLUDE_SS
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Network connection discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "Network connection discovery completed successfully"
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
            log_success "Network connection discovery completed successfully"
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
