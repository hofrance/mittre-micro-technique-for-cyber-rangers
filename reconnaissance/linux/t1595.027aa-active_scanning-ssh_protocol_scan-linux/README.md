# t1595.027aa - active_scanning-ssh_protocol_scan

## Overview
**Micro-technique for SSH protocol reconnaissance** using specialized scanning techniques. Part of the **Reconnaissance (TA0043)** tactic in MITRE ATT&CK framework.

### Atomic Action
- **Single Observable Action**: Perform SSH protocol scanning ONLY
- **Protocol-Specific**: Optimized for SSH service detection and enumeration
- **Comprehensive Coverage**: Full SSH protocol analysis and fingerprinting

### Contract Architecture
- **Get-Configuration**: Environment variable validation and setup
- **Precondition-Check**: Network environment and protocol validation
- **Atomic-Action**: SSH protocol scanning with service detection
- **Postcondition-Verify**: Results validation and cleanup

## Quick Start
```bash
# Basic SSH protocol scan
export t1595.027aa_TARGETS="192.168.1.0/24"
export t1595.027aa_OUTPUT_MODE="simple"
./src/main.sh

# Full SSH enumeration with version detection
export t1595.027aa_OUTPUT_MODE="debug"
export t1595.027aa_VERSION_DETECTION="true"
export t1595.027aa_SCRIPT_SCANNING="true"
./src/main.sh

# Custom SSH ports and timing
export t1595.027aa_PROTOCOL_PORTS="22"
export t1595.027aa_TIMING_TEMPLATE="polite"
./src/main.sh
```

## Environment Variables

### Core Configuration
- `t1595.027aa_TARGETS`: Target specification (IP/range/file) - **Required**
- `t1595.027aa_OUTPUT_BASE`: Base output directory (default: /tmp/mitre_results)
- `t1595.027aa_OUTPUT_MODE`: Output mode (simple/debug/stealth/silent) - default: simple
- `t1595.027aa_SILENT_MODE`: Suppress all output (true/false) - default: false

### Protocol-Specific Configuration
- `t1595.027aa_PROTOCOL_PORTS`: SSH ports to scan (default: 22)
- `t1595.027aa_VERSION_DETECTION`: Enable version detection (true/false) - default: true
- `t1595.027aa_SCRIPT_SCANNING`: Enable SSH NSE scripts (true/false) - default: false
- `t1595.027aa_SERVICE_DETECTION`: Enable service fingerprinting (true/false) - default: true

### Network & Performance
- `t1595.027aa_TIMING_TEMPLATE`: Nmap timing (polite/normal/aggressive) - default: normal
- `t1595.027aa_RATE_LIMIT`: Packets per second limit (0=unlimited) - default: 50
- `t1595.027aa_TIMEOUT`: Individual probe timeout (seconds) - default: 10
- `t1595.027aa_PARALLELISM`: Parallel scan groups (1-5) - default: 3

### Advanced Options
- `t1595.027aa_CUSTOM_FLAGS`: Additional nmap flags
- `t1595.027aa_EXCLUDE_HOSTS`: Hosts to exclude from scan
- `t1595.027aa_SCRIPT_CATEGORIES`: NSE script categories (auth,brute,default)
- `t1595.027aa_RESOLVE_HOSTNAMES`: DNS resolution (true/false) - default: true

## Output Modes

### Simple Mode (Default)
Human-readable scan results with SSH service information:
```
[INFO] SSH protocol scan started
[INFO] Targets: 192.168.1.0/24
[INFO] Found 8 SSH services, 5 with version info
[INFO] Results saved to: /tmp/mitre_results/t1595.027aa_results.json
```

### Debug Mode
Detailed technical information with NSE script output:
```
[DEBUG] Nmap command: nmap -sV -p 22 --script=ssh* -T4 -p 22 -sV -T3
[DEBUG] Scan duration: 67.3 seconds
[DEBUG] NSE scripts executed: 12
[DEBUG] SSH services identified: 8
[DEBUG] Version detection: 5 successful
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
  "technique_id": "t1595.027aa",
  "technique_name": "active_scanning-ssh_protocol_scan",
  "scan_timestamp": "2024-01-15T10:30:00Z",
  "protocol": "SSH",
  "configuration": {
    "protocol_ports": "22",
    "version_detection": true,
    "script_scanning": false,
    "timing_template": "normal"
  },
  "results": {
    "hosts_scanned": 15,
    "protocol_services_found": 8,
    "version_detection_successful": 5,
    "scan_duration_seconds": 67.3
  },
  "services": [
    {
      "host": "192.168.1.10",
      "port": 22,
      "protocol": "SSH",
      "state": "open",
      "service": "SSH",
      "version": "OpenSSH 8.2",
      "extrainfo": "Ubuntu Linux"
    }
  ]
}
```

### Technical Details (`technical_details.xml`)
Complete Nmap XML output with all SSH scan data.

### NSE Script Results (`nse_results.json`)
Detailed NSE script execution results for SSH.

## Examples

### Basic SSH Protocol Discovery
```bash
export t1595.027aa_TARGETS="192.168.1.0/24"
export t1595.027aa_PROTOCOL_PORTS="22"
export t1595.027aa_OUTPUT_MODE="simple"
./src/main.sh
```

### Advanced SSH Enumeration
```bash
export t1595.027aa_TARGETS="10.0.0.0/16"
export t1595.027aa_VERSION_DETECTION="true"
export t1595.027aa_SCRIPT_SCANNING="true"
export t1595.027aa_SCRIPT_CATEGORIES="auth,default"
export t1595.027aa_OUTPUT_MODE="debug"
./src/main.sh
```

### Custom SSH Port Scan
```bash
export t1595.027aa_TARGETS="scan_targets.txt"
export t1595.027aa_PROTOCOL_PORTS="22,2222,8022"
export t1595.027aa_TIMING_TEMPLATE="polite"
export t1595.027aa_RATE_LIMIT="30"
./src/main.sh
```

## Security Considerations

### Protocol-Specific Risks
- **SSH Service Fingerprinting**: May trigger logging and monitoring
- **Version Detection**: Can reveal vulnerable service versions
- **Authentication Probing**: NSE scripts may attempt authentication
- **Network Impact**: Protocol-specific scans may affect service availability

### Operational Security
- **Selective Targeting**: Use specific IP ranges to minimize exposure
- **Timing Control**: Polite timing reduces detection probability
- **Script Selection**: Choose NSE scripts carefully for operational security
- **Result Handling**: Secure storage of sensitive service information

## Error Handling

### Return Codes
- `0`: Success - SSH scan completed successfully
- `1`: Configuration Error - Invalid environment variables
- `2`: Precondition Failed - Network/tool requirements not met
- `3`: Execution Error - SSH scan failed during execution
- `4`: Postcondition Error - Results validation failed
- `124`: Timeout - Operation exceeded time limits
- `130`: User Interrupt - Operation cancelled by user

### Common Issues
```bash
# Network congestion
export t1595.027aa_RATE_LIMIT="20"
export t1595.027aa_TIMING_TEMPLATE="polite"
./src/main.sh
# Reduces impact on network infrastructure

# Service disruption concerns
export t1595.027aa_SCRIPT_SCANNING="false"
export t1595.027aa_VERSION_DETECTION="false"
./src/main.sh
# Minimizes potential service disruption

# Firewall blocking
export t1595.027aa_TIMING_TEMPLATE="sneaky"
export t1595.027aa_TIMEOUT="15"
./src/main.sh
# Improves success rate through restrictive firewalls
```

## Dependencies

### Required Tools
- **nmap**: 7.0+ (SSH protocol scanning and enumeration)
- **bash**: 4.0+ (script execution environment)

### Recommended Enhancements
- **jq**: For JSON output processing
- **xmlstarlet**: For XML parsing and validation
- **SSH-specific tools**: Protocol analyzers and testers

## Architecture Details

### Contract Functions
1. **Get-Configuration**: Validate and load environment variables
2. **Precondition-Check**: Verify network access and SSH availability
3. **Atomic-Action**: Execute SSH protocol scanning with detection
4. **Postcondition-Verify**: Validate results and cleanup

### Data Flow
```
Environment Variables → Configuration Validation → Precondition Check
                      ↓
              Network Environment Assessment
                      ↓
              SSH Protocol Scanning with Detection
                      ↓
              Service Enumeration and Analysis
                      ↓
              Standardized Output Generation
```

## Contributing
This micro-technique follows standards for:
- Atomic decomposition of adversarial behaviors
- Standardized environment variable patterns
- Contract-driven architecture
- Multi-modal output capabilities

