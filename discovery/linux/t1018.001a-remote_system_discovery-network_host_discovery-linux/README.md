# T1018.001A - Remote System Discovery: Network Host Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1018.001A for Linux environments. Discover remote network hosts through ping scanning, ARP table analysis, routing table examination, and local network enumeration.

## Technique Details
- **ID**: T1018.001A
- **Name**: Remote System Discovery: Network Host Discovery
- **Parent Technique**: T1018
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1018_001B_OUTPUT_BASE="/tmp/mitre_results" && export T1018_001B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: discover remote network hosts ONLY
- Scope: One specific discovery action
- Dependency: Bash + network utilities
- Privilege: User

## Environment Variables
- `T1018_001B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1018_001B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1018_001B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1018_001B_TIMEOUT`: Timeout in seconds (default: 300)
- `T1018_001B_SCAN_TARGETS`: Comma-separated targets to ping (default: 127.0.0.1,localhost)
- `T1018_001B_SCAN_PORTS`: Comma-separated ports for future use (default: 22,80,443,8080)
- `T1018_001B_PING_TIMEOUT`: Ping timeout in seconds (default: 2)
- `T1018_001B_PING_COUNT`: Number of ping packets (default: 1)
- `T1018_001B_INCLUDE_LOCAL_NETWORK`: Include local network discovery [true/false] (default: true)
- `T1018_001B_INCLUDE_GATEWAY`: Include gateway information [true/false] (default: true)
- `T1018_001B_INCLUDE_DNS`: Include DNS information [true/false] (default: true)
- `T1018_001B_INCLUDE_ARP_TABLE`: Include ARP table [true/false] (default: true)
- `T1018_001B_INCLUDE_ROUTING_TABLE`: Include routing table [true/false] (default: true)
- `T1018_001B_MAX_HOSTS`: Maximum hosts to discover (default: 50)

## Output Files
- `network_info/local_network.json`: Local network configuration
- `network_info/arp_table.json`: ARP table entries
- `network_info/routing_table.json`: Routing table information
- `network_info/ping_discovery.json`: Ping scan results
- `network_info/local_network_hosts.json`: Local network hosts
- `network_info/discovery_summary.json`: Summary of all discoveries
- `metadata/execution_metadata.json`: Execution metadata and statistics

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor  
- `bc` - Calculator utility
- `grep` - Text search utility
- `ping` - Network connectivity testing
- `hostname` - Hostname utility
- `ip` - IP routing utility
- `arp` - ARP table utility

**Technique-Specific Dependencies:**
- `coreutils` - Basic file, shell and text utilities
- `iproute2` - IP routing utilities
- `net-tools` - Network utilities (arp, route)

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc coreutils grep jq iproute2 net-tools
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc coreutils grep jq iproute net-tools
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc coreutils grep jq iproute2 net-tools
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Discovery Capabilities

### Local Network Information
- Hostname and local IP address
- Gateway and DNS server information
- Network interface details
- Network configuration summary

### ARP Table Discovery
- IP to MAC address mappings
- Network interface associations
- Hardware type information
- ARP cache entries

### Routing Table Discovery
- Network routes and destinations
- Gateway information
- Interface associations
- Route flags and metrics

### Ping Discovery
- Host reachability testing
- Network connectivity verification
- Response time information
- Target status reporting

### Local Network Hosts
- Hosts discovered via ARP table
- MAC address information
- Interface associations
- Network topology mapping

## Example Output

### Local Network Information
```json
{
  "hostname": "ubuntu-server",
  "local_ip": "192.168.1.100",
  "gateway": "192.168.1.1",
  "dns_servers": "8.8.8.8,8.8.4.4",
  "network_interfaces": [
    {
      "interface": "eth0",
      "ip_address": "192.168.1.100/24"
    }
  ]
}
```

### ARP Table Discovery
```json
{
  "discovery_timestamp": "2023-12-18T10:30:15Z",
  "total_arp_entries": 5,
  "arp_entries": [
    {
      "ip_address": "192.168.1.1",
      "mac_address": "${EXAMPLE_MAC:-00:11:22:33:44:55}",
      "interface": "eth0",
      "hw_type": "ether"
    }
  ]
}
```

### Ping Discovery
```json
{
  "discovery_timestamp": "2023-12-18T10:30:15Z",
  "scan_targets": "127.0.0.1,localhost,192.168.1.1",
  "ping_configuration": {
    "count": 1,
    "timeout": 2
  },
  "total_hosts_tested": 3,
  "hosts": [
    {
      "target": "127.0.0.1",
      "status": "reachable",
      "ping_count": 1,
      "timeout": 2
    }
  ]
}
```

### Routing Table
```json
{
  "discovery_timestamp": "2023-12-18T10:30:15Z",
  "total_routes": 8,
  "routes": [
    {
      "destination": "0.0.0.0",
      "gateway": "192.168.1.1",
      "netmask": "0.0.0.0",
      "interface": "eth0",
      "flags": "UG"
    }
  ]
}
```

## Security Considerations

### Detection Avoidance
- Use `stealth` mode to minimize console output
- Results are saved to filesystem for later analysis
- Configurable ping parameters to avoid detection
- Limited network scanning scope

### Permission Requirements
- **User level**: Can access network utilities and ARP table
- **No root required**: Standard user privileges sufficient
- **Read-only operations**: No network modifications

### Logging and Monitoring
- Ping activities may be logged by network monitoring
- ARP table access may be monitored
- Network scanning may trigger IDS/IPS alerts
- Command execution may appear in shell history

## Integration with Other Techniques

### Related Discovery Techniques
- **T1046.001a**: Network Service Discovery - Port Scanning
- **T1135.001a**: Network Share Discovery - SMB/NFS Shares
- **T1082.001a**: System Information Discovery
- **T1083.001a**: File and Directory Discovery

### Collection Techniques
- **T1040.001a**: Network Sniffing - Packet Capture
- **T1016.001a**: System Network Configuration Discovery
- **T1033.001a**: System Owner/User Discovery

## Advanced Configuration

### Custom Scan Targets
```bash
# Scan specific targets
export T1018_001B_SCAN_TARGETS="192.168.1.1,192.168.1.10,192.168.1.100"

# Scan localhost only
export T1018_001B_SCAN_TARGETS="127.0.0.1,localhost"

# Scan multiple subnets
export T1018_001B_SCAN_TARGETS="10.0.0.1,172.16.0.1,192.168.0.1"
```

### Ping Configuration
```bash
# Fast ping scan
export T1018_001B_PING_TIMEOUT="1"
export T1018_001B_PING_COUNT="1"

# Comprehensive ping scan
export T1018_001B_PING_TIMEOUT="5"
export T1018_001B_PING_COUNT="3"
```

### Discovery Scope
```bash
# Comprehensive discovery
export T1018_001B_INCLUDE_LOCAL_NETWORK="true"
export T1018_001B_INCLUDE_ARP_TABLE="true"
export T1018_001B_INCLUDE_ROUTING_TABLE="true"

# Minimal discovery
export T1018_001B_INCLUDE_LOCAL_NETWORK="false"
export T1018_001B_INCLUDE_ARP_TABLE="false"
export T1018_001B_INCLUDE_ROUTING_TABLE="false"
```

## Troubleshooting

### Common Issues
1. **Permission denied**: Cannot access network utilities
2. **No network connectivity**: Ping fails for all targets
3. **Empty ARP table**: No recent network communication
4. **Missing utilities**: Network tools not installed

### Debug Mode
Enable debug mode for detailed execution information:
```bash
export T1018_001B_OUTPUT_MODE="debug"
./src/main.sh
```

### Validation
Check generated files for completeness:
```bash
find /tmp/mitre_results -name "*.json" -exec jq . {} \;
```

### Performance Monitoring
Monitor execution time and network activity:
```bash
time ./src/main.sh
```

## Use Cases

### Network Reconnaissance
- Identify active hosts on the network
- Map network topology
- Discover network infrastructure
- Identify potential targets

### Security Assessment
- Verify network connectivity
- Identify network entry points
- Map attack surface
- Validate network segmentation

### Incident Response
- Identify unauthorized hosts
- Map network changes
- Track network activity
- Analyze network traffic patterns

### Compliance Auditing
- Document network topology
- Verify network configuration
- Validate network policies
- Audit network access controls
