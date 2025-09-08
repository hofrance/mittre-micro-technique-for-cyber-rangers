
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1018_001A_DEBUG_MODE="${T1018_001A_DEBUG_MODE:-false}"
    export T1018_001A_TIMEOUT="${T1018_001A_TIMEOUT:-300}"
    export T1018_001A_FALLBACK_MODE="${T1018_001A_FALLBACK_MODE:-simulate}"
    export T1018_001A_OUTPUT_FORMAT="${T1018_001A_OUTPUT_FORMAT:-json}"
    export T1018_001A_POLICY_CHECK="${T1018_001A_POLICY_CHECK:-true}"
    export T1018_001A_MAX_SERVICES="${T1018_001A_MAX_SERVICES:-200}"
    export T1018_001A_INCLUDE_SYSTEM="${T1018_001A_INCLUDE_SYSTEM:-true}"
    export T1018_001A_DETAIL_LEVEL="${T1018_001A_DETAIL_LEVEL:-standard}"
    export T1018_001A_RESOLVE_HOSTNAMES="${T1018_001A_RESOLVE_HOSTNAMES:-true}"
    export T1018_001A_MAX_PROCESSES="${T1018_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1018.001a - Remote System Discovery: Network Host Discovery
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover remote network hosts ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "ping" "hostname" "ip" "arp")
    
    [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1018_001B_OUTPUT_BASE="${T1018_001B_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1018_001B_TIMEOUT="${T1018_001B_TIMEOUT:-300}"
    export T1018_001B_OUTPUT_MODE="${T1018_001B_OUTPUT_MODE:-simple}"
    export T1018_001B_SILENT_MODE="${T1018_001B_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1018_001A_SCAN_TARGETS="${T1018_001A_SCAN_TARGETS:-127.0.0.1,localhost}"
    export T1018_001B_SCAN_PORTS="${T1018_001B_SCAN_PORTS:-22,80,443,8080}"
    export T1018_001B_TIMEOUT="${T1018_001B_TIMEOUT:-2}"
    export T1018_001B_PING_COUNT="${T1018_001B_PING_COUNT:-1}"
    export T1018_001B_INCLUDE_LOCAL_NETWORK="${T1018_001B_INCLUDE_LOCAL_NETWORK:-true}"
    export T1018_001B_INCLUDE_GATEWAY="${T1018_001B_INCLUDE_GATEWAY:-true}"
    export T1018_001B_INCLUDE_DNS="${T1018_001B_INCLUDE_DNS:-true}"
    export T1018_001B_INCLUDE_ARP_TABLE="${T1018_001B_INCLUDE_ARP_TABLE:-true}"
    export T1018_001B_INCLUDE_ROUTING_TABLE="${T1018_001B_INCLUDE_ROUTING_TABLE:-true}"
    export T1018_001B_MAX_HOSTS="${T1018_001B_MAX_HOSTS:-50}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1018_001B_OUTPUT_BASE" ]] && { [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1018_001B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1018_001B_OUTPUT_BASE")" ]] && { [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1018_001B_OUTPUT_BASE/T1018_001a_network_host_discovery_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{network_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover local network information
Discover-LocalNetworkInfo() {
    local output_dir="$1"
    local network_file="$output_dir/network_info/local_network.json"
    
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local local_ip=""
    local gateway=""
    local dns_servers=""
    local network_interfaces=()
    
    # Get local IP address
    if command -v ip >/dev/null 2>&1; then
        local_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' || echo "unknown")
        gateway=$(ip route show default 2>/dev/null | grep -oP 'default via \K\S+' || echo "unknown")
    fi
    
    # Get DNS servers
    if [[ -f /etc/resolv.conf ]]; then
        dns_servers=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ',' | sed 's/,$//' || echo "unknown")
    fi
    
    # Get network interfaces
    if command -v ip >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9]+: ]]; then
                local interface=$(echo "$line" | awk '{print $2}' | sed 's/://')
                local ip_addr=$(ip addr show "$interface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1 || echo "")
                if [[ -n "$ip_addr" ]]; then
                    network_interfaces+=("{\"interface\":\"$interface\",\"ip_address\":\"$ip_addr\"}")
                fi
            fi
        done < <(ip link show 2>/dev/null)
    fi
    
    local network_data=$(cat <<EOF
{
  "hostname": "$hostname",
  "local_ip": "$local_ip",
  "gateway": "$gateway",
  "dns_servers": "$dns_servers",
  "network_interfaces": [$(IFS=','; echo "${network_interfaces[*]}")]
}
EOF
)
    
    echo "$network_data" > "$network_file" 2>/dev/null && {
        [[ "$T1018_001B_SILENT_MODE" != "true" && "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected local network information" >&2
        echo "local_network"
    }
}

# Discover ARP table
Discover-ARPTable() {
    local output_dir="$1"
    local arp_file="$output_dir/network_info/arp_table.json"
    
    [[ "$T1018_001B_INCLUDE_ARP_TABLE" != "true" ]] && return 0
    
    local arp_entries=()
    local total_entries=0
    
    # Read ARP table
    while IFS=' ' read -r ip_addr hw_type hw_addr flags interface; do
        [[ "$ip_addr" == "Address" ]] && continue
        [[ -z "$ip_addr" ]] && continue
        
        local entry=$(cat <<EOF
{
  "ip_address": "$ip_addr",
  "mac_address": "$hw_addr",
  "interface": "$interface",
  "hw_type": "$hw_type"
}
EOF
)
        arp_entries+=("$entry")
        ((total_entries++))
        
        [[ $total_entries -ge $T1018_001B_MAX_HOSTS ]] && break
    done < <(arp -n 2>/dev/null | tail -n +2)
    
    local arp_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_arp_entries": $total_entries,
  "arp_entries": [$(IFS=','; echo "${arp_entries[*]}")]
}
EOF
)
    
    echo "$arp_data" > "$arp_file" 2>/dev/null && {
        [[ "$T1018_001B_SILENT_MODE" != "true" && "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_entries ARP entries" >&2
        echo "$total_entries"
    }
}

# Discover routing table
Discover-RoutingTable() {
    local output_dir="$1"
    local routing_file="$output_dir/network_info/routing_table.json"
    
    [[ "$T1018_001B_INCLUDE_ROUTING_TABLE" != "true" ]] && return 0
    
    local routes=()
    local total_routes=0
    
    # Read routing table
    while IFS=' ' read -r destination gateway genmask flags metric ref use interface; do
        [[ "$destination" == "Destination" ]] && continue
        [[ -z "$destination" ]] && continue
        
        local route=$(cat <<EOF
{
  "destination": "$destination",
  "gateway": "$gateway",
  "netmask": "$genmask",
  "interface": "$interface",
  "flags": "$flags"
}
EOF
)
        routes+=("$route")
        ((total_routes++))
    done < <(route -n 2>/dev/null | tail -n +3)
    
    local routing_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_routes": $total_routes,
  "routes": [$(IFS=','; echo "${routes[*]}")]
}
EOF
)
    
    echo "$routing_data" > "$routing_file" 2>/dev/null && {
        [[ "$T1018_001B_SILENT_MODE" != "true" && "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_routes routing entries" >&2
        echo "$total_routes"
    }
}

# Ping discovery of hosts
Discover-HostsByPing() {
    local output_dir="$1"
    local ping_file="$output_dir/network_info/ping_discovery.json"
    
    local discovered_hosts=()
    local total_hosts=0
    
    # Parse scan targets
    IFS=',' read -ra TARGET_ARRAY <<< "$T1018_001A_SCAN_TARGETS"
    
    for target in "${TARGET_ARRAY[@]}"; do
        target=$(echo "$target" | xargs)  # Trim whitespace
        [[ -z "$target" ]] && continue
        
        [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Pinging target: $target" >&2
        
        # Ping the target
        if ping -c "$T1018_001B_PING_COUNT" -W "$T1018_001B_TIMEOUT" "$target" >/dev/null 2>&1; then
            local host_info=$(cat <<EOF
{
  "target": "$target",
  "status": "reachable",
  "ping_count": $T1018_001B_PING_COUNT,
  "timeout": $T1018_001B_TIMEOUT
}
EOF
)
            discovered_hosts+=("$host_info")
            ((total_hosts++))
            
            [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Host $target is reachable" >&2
        else
            local host_info=$(cat <<EOF
{
  "target": "$target",
  "status": "unreachable",
  "ping_count": $T1018_001B_PING_COUNT,
  "timeout": $T1018_001B_TIMEOUT
}
EOF
)
            discovered_hosts+=("$host_info")
            ((total_hosts++))
            
            [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Host $target is unreachable" >&2
        fi
        
        [[ $total_hosts -ge $T1018_001B_MAX_HOSTS ]] && break
    done
    
    local ping_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_targets": "$T1018_001A_SCAN_TARGETS",
  "ping_configuration": {
    "count": $T1018_001B_PING_COUNT,
    "timeout": $T1018_001B_TIMEOUT
  },
  "total_hosts_tested": $total_hosts,
  "hosts": [$(IFS=','; echo "${discovered_hosts[*]}")]
}
EOF
)
    
    echo "$ping_data" > "$ping_file" 2>/dev/null && {
        [[ "$T1018_001B_SILENT_MODE" != "true" && "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Ping discovery completed for $total_hosts hosts" >&2
        echo "$total_hosts"
    }
}

# Discover local network hosts (if enabled)
Discover-LocalNetworkHosts() {
    local output_dir="$1"
    local local_network_file="$output_dir/network_info/local_network_hosts.json"
    
    [[ "$T1018_001B_INCLUDE_LOCAL_NETWORK" != "true" ]] && return 0
    
    local network_hosts=()
    local total_network_hosts=0
    
    # Get local network range from ARP table
    while IFS=' ' read -r ip_addr hw_type hw_addr flags interface; do
        [[ "$ip_addr" == "Address" ]] && continue
        [[ -z "$ip_addr" ]] && continue
        [[ "$ip_addr" == "127.0.0.1" ]] && continue
        
        local host_info=$(cat <<EOF
{
  "ip_address": "$ip_addr",
  "mac_address": "$hw_addr",
  "interface": "$interface",
  "source": "arp_table"
}
EOF
)
        network_hosts+=("$host_info")
        ((total_network_hosts++))
        
        [[ $total_network_hosts -ge $T1018_001B_MAX_HOSTS ]] && break
    done < <(arp -n 2>/dev/null | tail -n +2)
    
    local network_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_network_hosts": $total_network_hosts,
  "network_hosts": [$(IFS=','; echo "${network_hosts[*]}")]
}
EOF
)
    
    echo "$network_data" > "$local_network_file" 2>/dev/null && {
        [[ "$T1018_001B_SILENT_MODE" != "true" && "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_network_hosts local network hosts" >&2
        echo "$total_network_hosts"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_arp_entries=0
    local total_routes=0
    local total_ping_hosts=0
    local total_network_hosts=0
    
    [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting network host discovery..." >&2
    
    # Discover different types of network information
    local network_result=$(Discover-LocalNetworkInfo "$discovery_dir")
    [[ -n "$network_result" ]] && echo "  + Local network info collected" >&2
    
    local arp_count=$(Discover-ARPTable "$discovery_dir")
    [[ -n "$arp_count" ]] && total_arp_entries=$arp_count
    
    local routes_count=$(Discover-RoutingTable "$discovery_dir")
    [[ -n "$routes_count" ]] && total_routes=$routes_count
    
    local ping_count=$(Discover-HostsByPing "$discovery_dir")
    [[ -n "$ping_count" ]] && total_ping_hosts=$ping_count
    
    local network_count=$(Discover-LocalNetworkHosts "$discovery_dir")
    [[ -n "$network_count" ]] && total_network_hosts=$network_count
    
    # Create summary file
    local summary_file="$discovery_dir/network_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1018.001a",
  "technique_name": "Remote System Discovery: Network Host Discovery",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_arp_entries": $total_arp_entries,
  "total_routes": $total_routes,
  "total_ping_hosts": $total_ping_hosts,
  "total_network_hosts": $total_network_hosts,
  "configuration": {
    "scan_targets": "$T1018_001A_SCAN_TARGETS",
    "scan_ports": "$T1018_001B_SCAN_PORTS",
    "ping_timeout": $T1018_001B_TIMEOUT,
    "ping_count": $T1018_001B_PING_COUNT,
    "include_local_network": $T1018_001B_INCLUDE_LOCAL_NETWORK,
    "include_gateway": $T1018_001B_INCLUDE_GATEWAY,
    "include_dns": $T1018_001B_INCLUDE_DNS,
    "include_arp_table": $T1018_001B_INCLUDE_ARP_TABLE,
    "include_routing_table": $T1018_001B_INCLUDE_ROUTING_TABLE,
    "max_hosts": $T1018_001B_MAX_HOSTS
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1018_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_arp_entries ARP entries, $total_routes routes, $total_ping_hosts ping hosts, $total_network_hosts network hosts." >&2
    
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
  "technique_id": "T1018.001a",
  "technique_name": "Remote System Discovery: Network Host Discovery",
  "output_mode": "${T1018_001B_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1018_001B_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "scan_targets": "$T1018_001A_SCAN_TARGETS",
    "scan_ports": "$T1018_001B_SCAN_PORTS",
    "ping_timeout": $T1018_001B_TIMEOUT,
    "ping_count": $T1018_001B_PING_COUNT,
    "max_hosts": $T1018_001B_MAX_HOSTS
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Network host discovery completed" >&2
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
