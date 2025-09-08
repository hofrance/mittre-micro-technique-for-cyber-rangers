
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1016_001A_DEBUG_MODE="${T1016_001A_DEBUG_MODE:-false}"
    export T1016_001A_TIMEOUT="${T1016_001A_TIMEOUT:-300}"
    export T1016_001A_FALLBACK_MODE="${T1016_001A_FALLBACK_MODE:-simulate}"
    export T1016_001A_OUTPUT_FORMAT="${T1016_001A_OUTPUT_FORMAT:-json}"
    export T1016_001A_POLICY_CHECK="${T1016_001A_POLICY_CHECK:-true}"
    export T1016_001A_MAX_SERVICES="${T1016_001A_MAX_SERVICES:-200}"
    export T1016_001A_INCLUDE_SYSTEM="${T1016_001A_INCLUDE_SYSTEM:-true}"
    export T1016_001A_DETAIL_LEVEL="${T1016_001A_DETAIL_LEVEL:-standard}"
    export T1016_001A_RESOLVE_HOSTNAMES="${T1016_001A_RESOLVE_HOSTNAMES:-true}"
    export T1016_001A_MAX_PROCESSES="${T1016_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1016.001a - System Network Configuration Discovery: Network Configuration Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover system network configuration ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "ip" "route" "cat" "awk" "hostname")
    
    [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1016_001A_OUTPUT_BASE="${T1016_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1016_001A_TIMEOUT="${T1016_001A_TIMEOUT:-300}"
    export T1016_001A_OUTPUT_MODE="${T1016_001A_OUTPUT_MODE:-simple}"
    export T1016_001A_SILENT_MODE="${T1016_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1016_001A_INCLUDE_INTERFACES="${T1016_001A_INCLUDE_INTERFACES:-true}"
    export T1016_001A_INCLUDE_ROUTES="${T1016_001A_INCLUDE_ROUTES:-true}"
    export T1016_001A_INCLUDE_DNS="${T1016_001A_INCLUDE_DNS:-true}"
    export T1016_001A_INCLUDE_FIREWALL="${T1016_001A_INCLUDE_FIREWALL:-true}"
    export T1016_001A_INCLUDE_NETWORK_FILES="${T1016_001A_INCLUDE_NETWORK_FILES:-true}"
    export T1016_001A_INCLUDE_NETWORK_SERVICES="${T1016_001A_INCLUDE_NETWORK_SERVICES:-true}"
    export T1016_001A_MAX_INTERFACES="${T1016_001A_MAX_INTERFACES:-20}"
    export T1016_001A_MAX_ROUTES="${T1016_001A_MAX_ROUTES:-50}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1016_001A_OUTPUT_BASE" ]] && { [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] t1016_001a_TT1016.001A_TT1016_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1016_001A_OUTPUT_BASE")" ]] && { [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1016_001A_OUTPUT_BASE/T1016_001a_network_configuration_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{network_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover network interfaces
Discover-NetworkInterfaces() {
    local output_dir="$1"
    local interfaces_file="$output_dir/network_info/network_interfaces.json"
    
    [[ "$T1016_001A_INCLUDE_INTERFACES" != "true" ]] && return 0
    
    local interfaces=()
    local total_interfaces=0
    
    # Get network interfaces using ip command
    while IFS=' ' read -r ifindex ifname flags link_type address; do
        [[ "$ifindex" == "1:" ]] && continue  # Skip header
        [[ -z "$ifindex" ]] && continue
        [[ "$ifname" == "lo:" ]] && continue  # Skip loopback for now
        
        local interface_name=$(echo "$ifname" | sed 's/://')
        local interface_status="down"
        local interface_address=""
        local interface_mac=""
        
        # Get interface status
        if ip link show "$interface_name" 2>/dev/null | grep -q "UP"; then
            interface_status="up"
        fi
        
        # Get IP address
        interface_address=$(ip addr show "$interface_name" 2>/dev/null | grep "inet " | awk '{print $2}' | head -1 || echo "")
        
        # Get MAC address
        interface_mac=$(ip link show "$interface_name" 2>/dev/null | grep "link/ether" | awk '{print $2}' || echo "")
        
        local interface_info=$(cat <<EOF
{
  "interface_name": "$interface_name",
  "interface_index": "$ifindex",
  "interface_status": "$interface_status",
  "interface_address": "$interface_address",
  "interface_mac": "$interface_mac",
  "link_type": "$link_type"
}
EOF
)
        interfaces+=("$interface_info")
        ((total_interfaces++))
        
        [[ $total_interfaces -ge $T1016_001A_MAX_INTERFACES ]] && break
    done < <(ip link show 2>/dev/null | grep -E "^[0-9]+:")
    
    local interfaces_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_interfaces": $total_interfaces,
  "network_interfaces": [$(IFS=','; echo "${interfaces[*]}")]
}
EOF
)
    
    echo "$interfaces_data" > "$interfaces_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_interfaces network interfaces" >&2
        echo "$total_interfaces"
    }
}

# Discover routing table
Discover-RoutingTable() {
    local output_dir="$1"
    local routes_file="$output_dir/network_info/routing_table.json"
    
    [[ "$T1016_001A_INCLUDE_ROUTES" != "true" ]] && return 0
    
    local routes=()
    local total_routes=0
    
    # Get routing table
    while IFS=' ' read -r destination gateway genmask flags metric ref use iface; do
        [[ "$destination" == "Destination" ]] && continue
        [[ -z "$destination" ]] && continue
        
        local route_info=$(cat <<EOF
{
  "destination": "$destination",
  "gateway": "$gateway",
  "genmask": "$genmask",
  "flags": "$flags",
  "metric": "$metric",
  "ref": "$ref",
  "use": "$use",
  "interface": "$iface"
}
EOF
)
        routes+=("$route_info")
        ((total_routes++))
        
        [[ $total_routes -ge $T1016_001A_MAX_ROUTES ]] && break
    done < <(route -n 2>/dev/null | grep -v "Kernel")
    
    local routes_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_routes": $total_routes,
  "routing_table": [$(IFS=','; echo "${routes[*]}")]
}
EOF
)
    
    echo "$routes_data" > "$routes_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_routes routing entries" >&2
        echo "$total_routes"
    }
}

# Discover DNS configuration
Discover-DNSConfiguration() {
    local output_dir="$1"
    local dns_file="$output_dir/network_info/dns_configuration.json"
    
    [[ "$T1016_001A_INCLUDE_DNS" != "true" ]] && return 0
    
    local dns_servers=()
    local total_dns=0
    
    # Get DNS servers from resolv.conf
    if [[ -f "/etc/resolv.conf" ]]; then
        while IFS=' ' read -r type value; do
            [[ "$type" == "nameserver" ]] && {
                dns_servers+=("\"$value\"")
                ((total_dns++))
            }
        done < /etc/resolv.conf
    fi
    
    # Get domain and search information
    local domain=$(grep "^domain" /etc/resolv.conf 2>/dev/null | awk '{print $2}' || echo "")
    local search=$(grep "^search" /etc/resolv.conf 2>/dev/null | awk '{print $2}' || echo "")
    
    local dns_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_dns_servers": $total_dns,
  "dns_servers": [$(IFS=','; echo "${dns_servers[*]}")],
  "domain": "$domain",
  "search": "$search"
}
EOF
)
    
    echo "$dns_data" > "$dns_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_dns DNS servers" >&2
        echo "$total_dns"
    }
}

# Discover firewall configuration
Discover-FirewallConfiguration() {
    local output_dir="$1"
    local firewall_file="$output_dir/network_info/firewall_configuration.json"
    
    [[ "$T1016_001A_INCLUDE_FIREWALL" != "true" ]] && return 0
    
    local firewall_rules=()
    local total_rules=0
    
    # Check for iptables
    if command -v iptables >/dev/null 2>&1; then
        while IFS=' ' read -r chain policy target prot opt source destination; do
            [[ "$chain" == "Chain" ]] && continue
            [[ -z "$chain" ]] && continue
            
            local rule_info=$(cat <<EOF
{
  "chain": "$chain",
  "policy": "$policy",
  "target": "$target",
  "protocol": "$prot",
  "options": "$opt",
  "source": "$source",
  "destination": "$destination"
}
EOF
)
            firewall_rules+=("$rule_info")
            ((total_rules++))
            
            [[ $total_rules -ge 50 ]] && break
        done < <(iptables -L -n 2>/dev/null | grep -E "^Chain|^[A-Z]")
    fi
    
    local firewall_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_firewall_rules": $total_rules,
  "firewall_rules": [$(IFS=','; echo "${firewall_rules[*]}")]
}
EOF
)
    
    echo "$firewall_data" > "$firewall_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_rules firewall rules" >&2
        echo "$total_rules"
    }
}

# Discover network configuration files
Discover-NetworkFiles() {
    local output_dir="$1"
    local files_file="$output_dir/network_info/network_files.json"
    
    [[ "$T1016_001A_INCLUDE_NETWORK_FILES" != "true" ]] && return 0
    
    local network_files=()
    local total_files=0
    
    # Common network configuration files
    local config_files=(
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/network/interfaces"
        "/etc/sysconfig/network-scripts/ifcfg-*"
        "/etc/netplan/*.yaml"
        "/etc/systemd/network/*.network"
    )
    
    for pattern in "${config_files[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                local file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
                local file_permissions=$(stat -c%a "$file" 2>/dev/null || echo "unknown")
                
                local file_info=$(cat <<EOF
{
  "file_path": "$file",
  "file_size": $file_size,
  "file_permissions": "$file_permissions"
}
EOF
)
                network_files+=("$file_info")
                ((total_files++))
            fi
        done
        
        [[ $total_files -ge 20 ]] && break
    done
    
    local files_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_network_files": $total_files,
  "network_files": [$(IFS=','; echo "${network_files[*]}")]
}
EOF
)
    
    echo "$files_data" > "$files_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_files network configuration files" >&2
        echo "$total_files"
    }
}

# Discover network services
Discover-NetworkServices() {
    local output_dir="$1"
    local services_file="$output_dir/network_info/network_services.json"
    
    [[ "$T1016_001A_INCLUDE_NETWORK_SERVICES" != "true" ]] && return 0
    
    local network_services=()
    local total_services=0
    
    # Get listening network services
    if command -v ss >/dev/null 2>&1; then
        while IFS=' ' read -r proto recv_q send_q local_addr foreign_addr state pid_program; do
            [[ "$proto" == "Netid" ]] && continue
            [[ -z "$proto" ]] && continue
            [[ "$state" != "LISTEN" ]] && continue
            
            local port=$(echo "$local_addr" | grep -o ':[0-9]*' | sed 's/://' || echo "")
            local service_name=$(Get-ServiceName "$port")
            
            local service_info=$(cat <<EOF
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
            network_services+=("$service_info")
            ((total_services++))
            
            [[ $total_services -ge 30 ]] && break
        done < <(ss -tuln 2>/dev/null | grep LISTEN)
    fi
    
    local services_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_network_services": $total_services,
  "network_services": [$(IFS=','; echo "${network_services[*]}")]
}
EOF
)
    
    echo "$services_data" > "$services_file" 2>/dev/null && {
        [[ "$T1016_001A_SILENT_MODE" != "true" && "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_services network services" >&2
        echo "$total_services"
    }
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

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_interfaces=0
    local total_routes=0
    local total_dns=0
    local total_firewall=0
    local total_files=0
    local total_services=0
    
    [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting network configuration discovery..." >&2
    
    # Discover different types of network configuration
    local interfaces_count=$(Discover-NetworkInterfaces "$discovery_dir")
    [[ -n "$interfaces_count" ]] && total_interfaces=$interfaces_count
    
    local routes_count=$(Discover-RoutingTable "$discovery_dir")
    [[ -n "$routes_count" ]] && total_routes=$routes_count
    
    local dns_count=$(Discover-DNSConfiguration "$discovery_dir")
    [[ -n "$dns_count" ]] && total_dns=$dns_count
    
    local firewall_count=$(Discover-FirewallConfiguration "$discovery_dir")
    [[ -n "$firewall_count" ]] && total_firewall=$firewall_count
    
    local files_count=$(Discover-NetworkFiles "$discovery_dir")
    [[ -n "$files_count" ]] && total_files=$files_count
    
    local services_count=$(Discover-NetworkServices "$discovery_dir")
    [[ -n "$services_count" ]] && total_services=$services_count
    
    # Create summary file
    local summary_file="$discovery_dir/network_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1016.001a",
  "technique_name": "System Network Configuration Discovery: Network Configuration Enumeration",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_interfaces": $total_interfaces,
  "total_routes": $total_routes,
  "total_dns_servers": $total_dns,
  "total_firewall_rules": $total_firewall,
  "total_network_files": $total_files,
  "total_network_services": $total_services,
  "configuration": {
    "include_interfaces": $T1016_001A_INCLUDE_INTERFACES,
    "include_routes": $T1016_001A_INCLUDE_ROUTES,
    "include_dns": $T1016_001A_INCLUDE_DNS,
    "include_firewall": $T1016_001A_INCLUDE_FIREWALL,
    "include_network_files": $T1016_001A_INCLUDE_NETWORK_FILES,
    "include_network_services": $T1016_001A_INCLUDE_NETWORK_SERVICES,
    "max_interfaces": $T1016_001A_MAX_INTERFACES,
    "max_routes": $T1016_001A_MAX_ROUTES
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1016_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_interfaces interfaces, $total_routes routes, $total_dns DNS servers, $total_firewall firewall rules, $total_files network files, $total_services network services." >&2
    
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
  "technique_id": "T1016.001a",
  "technique_name": "System Network Configuration Discovery: Network Configuration Enumeration",
  "output_mode": "${T1016_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1016_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "include_interfaces": $T1016_001A_INCLUDE_INTERFACES,
    "include_routes": $T1016_001A_INCLUDE_ROUTES,
    "max_interfaces": $T1016_001A_MAX_INTERFACES
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${TT1016_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Network configuration discovery completed" >&2
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
