# t1595.001g - scanning_ip_blocks-comprehensive_udp_scan

## Overview
**Micro-technique for comprehensive network reconnaissance** using Comprehensive UDP scanning techniques. Part of the **Reconnaissance (TA0043)** tactic in MITRE ATT&CK framework.

### Atomic Action
- **Single Observable Action**: Perform comprehensive network scanning ONLY
- **Exhaustive Coverage**: Maximum information gathering and service detection
- **Multi-Tool Support**: Optimized for nmap scanning engine

### Contract Architecture
- **Get-Configuration**: Environment variable validation and setup
- **Precondition-Check**: Network environment and tool validation
- **Atomic-Action**: Comprehensive scanning with full detection
- **Postcondition-Verify**: Results validation and cleanup

## Quick Start
```bash
# Basic comprehensive scan
export t1595.001g_TARGETS="192.168.1.0/24"
export t1595.001g_OUTPUT_MODE="simple"
./src/main.sh

# Full service detection
export t1595.001g_OUTPUT_MODE="debug"
export t1595.001g_SERVICE_DETECTION="true"
export t1595.001g_VERSION_SCANNING="true"
./src/main.sh

# OS fingerprinting
export t1595.001g_OS_DETECTION="true"
export t1595.001g_TIMING_TEMPLATE="normal"
./src/main.sh
```

## Environment Variables

### Core Configuration
- `t1595.001g_TARGETS`: Target specification (IP/range/file) - **Required**
- `t1595.001g_OUTPUT_BASE`: Base output directory (default: /tmp/mitre_results)
- `t1595.001g_OUTPUT_MODE`: Output mode (simple/debug/stealth/silent) - default: simple
- `t1595.001g_SILENT_MODE`: Suppress all output (true/false) - default: false

### Comprehensive Scanning
- `t1595.001g_SERVICE_DETECTION`: Enable service detection (true/false) - default: true
- `t1595.001g_VERSION_SCANNING`: Enable version detection (true/false) - default: true
- `t1595.001g_OS_DETECTION`: Enable OS fingerprinting (true/false) - default: true
- `t1595.001g_SCRIPT_SCANNING`: Enable NSE scripts (true/false) - default: false

### Performance & Timing
- `t1595.001g_TIMING_TEMPLATE`: Nmap timing (normal/aggressive/insane) - default: normal
- `t1595.001g_RATE_LIMIT`: Packets per second limit (0=unlimited) - default: 0
- `t1595.001g_PARALLELISM`: Parallel scan groups (1-10) - default: 5
- `t1595.001g_HOST_TIMEOUT`: Individual host timeout (seconds) - default: 30

### Advanced Options
- `t1595.001g_CUSTOM_FLAGS`: Additional nmap flags
- `t1595.001g_EXCLUDE_HOSTS`: Hosts to exclude from scan
- `t1595.001g_RESOLVE_HOSTNAMES`: DNS resolution (true/false) - default: true
- `t1595.001g_SCRIPT_CATEGORIES`: NSE script categories to run

## Output Modes

### Simple Mode (Default)
Human-readable scan results with comprehensive information:
```
[INFO] Comprehensive Comprehensive UDP scan started
[INFO] Targets: 192.168.1.0/24
[INFO] Found 15 hosts, 47 ports open, 23 services identified
[INFO] OS detection: 12/15 hosts fingerprinted
[INFO] Results saved to: /tmp/mitre_results/t1595.001g_results.json
```

### Debug Mode
Detailed technical information with timing and NSE script output:
```
[DEBUG] Nmap command: nmap -sU -p- -T3 -sV -O -T3
[DEBUG] Scan duration: 145.2 seconds
[DEBUG] NSE scripts executed: 15
[DEBUG] Service versions detected: 23
[DEBUG] OS fingerprints: 12 successful
```

### Stealth Mode
Minimal output for covert operations (logs only to files):
```
[STEALTH] Operation completed - check results directory
```

### Silent Mode
No console output whatsoever (completely silent execution).

## Output Files

### JSON Results (`scan_results.json`)
```json
{
  "technique_id": "t1595.001g",
  "technique_name": "scanning_ip_blocks-comprehensive_udp_scan",
  "scan_timestamp": "2024-01-15T10:30:00Z",
  "scan_type": "Comprehensive UDP",
  "configuration": {
    "service_detection": true,
    "version_scanning": true,
    "os_detection": true,
    "timing_template": "normal"
  },
  "results": {
    "hosts_discovered": 15,
    "ports_found": 47,
    "services_identified": 23,
    "os_fingerprinted": 12,
    "scan_duration_seconds": 145.2
  },
  "hosts": [
    {
      "ip": "192.168.1.10",
      "hostname": "server1.local",
      "state": "up",
      "os": {
        "name": "Linux",
        "accuracy": 95,
        "type": "general purpose"
      },
      "ports": [
        {
          "port": 22,
          "protocol": "tcp",
          "state": "open",
          "service": "ssh",
          "version": "OpenSSH 8.2",
          "product": "OpenSSH",
          "extrainfo": "Ubuntu Linux"
        }
      ]
    }
  ]
}
```

### Technical Details (`technical_details.xml`)
Complete nmap XML output with all scan data.

### NSE Script Results (`nse_results.json`)
Detailed NSE script execution results and findings.

## Examples

### Full Network Reconnaissance
```bash
export t1595.001g_TARGETS="192.168.1.0/24"
export t1595.001g_SERVICE_DETECTION="true"
export t1595.001g_VERSION_SCANNING="true"
export t1595.001g_OS_DETECTION="true"
export t1595.001g_OUTPUT_MODE="simple"
./src/main.sh
```

### Service Inventory
```bash
export t1595.001g_TARGETS="10.0.0.0/16"
export t1595.001g_SCRIPT_SCANNING="true"
export t1595.001g_SCRIPT_CATEGORIES="discovery,version"
export t1595.001g_OUTPUT_MODE="debug"
./src/main.sh
```

### Vulnerability Assessment Prep
```bash
export t1595.001g_TARGETS="scan_targets.txt"
export t1595.001g_VERSION_SCANNING="true"
export t1595.001g_SCRIPT_CATEGORIES="vuln,exploit"
export t1595.001g_TIMING_TEMPLATE="polite"
./src/main.sh
```

## Security Considerations

### Network Impact
- **High Bandwidth**: Comprehensive scans generate significant traffic
- **Long Duration**: Exhaustive scans take considerable time
- **IDS Detection**: Full scanning may trigger intrusion detection
- **Resource Intensive**: CPU and memory intensive operations

### Operational Security
- **Network Awareness**: Consider firewall policies and IDS placement
- **Timing Constraints**: Use appropriate timing for target environment
- **Legal Compliance**: Ensure authorization for comprehensive scanning
- **Impact Assessment**: Evaluate potential disruption to target systems

## Error Handling

### Return Codes
- `0`: Success - Scan completed successfully
- `1`: Configuration Error - Invalid environment variables
- `2`: Precondition Failed - Network/tool requirements not met
- `3`: Execution Error - Scan failed during execution
- `4`: Postcondition Error - Results validation failed
- `124`: Timeout - Operation exceeded time limits
- `130`: User Interrupt - Operation cancelled by user

### Common Issues
```bash
# Network congestion
export t1595.001g_RATE_LIMIT="100"
export t1595.001g_TIMING_TEMPLATE="polite"
./src/main.sh
# Reduces impact on network infrastructure

# IDS evasion
export t1595.001g_SCRIPT_SCANNING="false"
export t1595.001g_TIMING_TEMPLATE="sneaky"
./src/main.sh
# Reduces detection probability

# Resource limits
export t1595.001g_HOST_TIMEOUT="60"
export t1595.001g_PARALLELISM="3"
./src/main.sh
# Manages resource usage
```

## Dependencies

### Required Tools
- **nmap**: 7.0+ (comprehensive scanning and reconnaissance)
- **bash**: 4.0+ (script execution environment)

### Recommended Enhancements
- **jq**: For JSON output processing
- **xmlstarlet**: For XML parsing and validation
- **nmap-scripts**: NSE script collection for enhanced detection

## Architecture Details

### Contract Functions
1. **Get-Configuration**: Validate and load environment variables
2. **Precondition-Check**: Verify network access and tool availability
3. **Atomic-Action**: Execute comprehensive scanning with full detection
4. **Postcondition-Verify**: Validate results and cleanup

### Data Flow
```
Environment Variables → Configuration Validation → Precondition Check
                      ↓
              Network Environment Assessment
                      ↓
              Comprehensive Scan Execution with Detection
                      ↓
              Results Processing and NSE Script Analysis
                      ↓
              Standardized Output Generation
```

## Contributing
This micro-technique follows standards for:
- Atomic decomposition of adversarial behaviors
- Standardized environment variable patterns
- Contract-driven architecture
- Multi-modal output capabilities

