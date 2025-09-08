# t1595.001c - scanning_ip_blocks-stealth_null_scan-linux

## Overview
**Micro-technique for stealth network reconnaissance** using ${scan_type} scanning techniques. Part of the **Reconnaissance (TA0043)** tactic in MITRE ATT&CK framework.

### Atomic Action
- **Single Observable Action**: Perform stealth network scanning ONLY
- **Minimal Footprint**: Designed for covert reconnaissance operations
- **Evasion-Aware**: Implements multiple IDS/IPS evasion techniques

### Contract Architecture
- **Get-Configuration**: Environment variable validation and setup
- **Precondition-Check**: Network environment and tool validation
- **Atomic-Action**: Stealth scanning execution with evasion
- **Postcondition-Verify**: Results validation and cleanup

## Quick Start
```bash
# Basic stealth scan
export t1595.001c_TARGETS="192.168.1.0/24"
export t1595.001c_OUTPUT_MODE="stealth"
./src/main.sh

# Debug mode with detailed output
export t1595.001c_OUTPUT_MODE="debug"
export t1595.001c_TARGETS="10.0.0.1-10.0.0.255"
./src/main.sh

# Custom evasion settings
export t1595.001c_EVASION_LEVEL="maximum"
export t1595.001c_TIMING_TEMPLATE="paranoid"
./src/main.sh
```

## Environment Variables

### Core Configuration
- `t1595.001c_TARGETS`: Target specification (IP/range/file) - **Required**
- `t1595.001c_OUTPUT_BASE`: Base output directory (default: /tmp/mitre_results)
- `t1595.001c_OUTPUT_MODE`: Output mode (simple/debug/stealth/silent) - default: simple
- `t1595.001c_SILENT_MODE`: Suppress all output (true/false) - default: false

### Stealth & Evasion
- `t1595.001c_EVASION_LEVEL`: Evasion intensity (none/basic/advanced/maximum) - default: advanced
- `t1595.001c_TIMING_TEMPLATE`: Nmap timing (paranoid/sneaky/polite) - default: sneaky
- `t1595.001c_DECOY_COUNT`: Number of decoy hosts (0-10) - default: 3
- `t1595.001c_SOURCE_PORT`: Spoofed source port - default: random
- `t1595.001c_FRAGMENT_SIZE`: Packet fragmentation size - default: 8

### Network & Performance
- `t1595.001c_RATE_LIMIT`: Packets per second limit - default: 10
- `t1595.001c_TIMEOUT`: Individual probe timeout (seconds) - default: 5
- `t1595.001c_MAX_RETRIES`: Maximum retry attempts - default: 2
- `t1595.001c_PARALLELISM`: Parallel scan groups - default: 1

### Advanced Options
- `t1595.001c_CUSTOM_FLAGS`: Additional nmap flags
- `t1595.001c_EXCLUDE_HOSTS`: Hosts to exclude from scan
- `t1595.001c_RESOLVE_HOSTNAMES`: DNS resolution (true/false) - default: false

## Output Modes

### Simple Mode (Default)
Human-readable scan results with basic information:
```
[INFO] Stealth ${scan_type} scan started
[INFO] Targets: 192.168.1.0/24
[INFO] Found 15 hosts, 3 ports open
[INFO] Results saved to: /tmp/mitre_results/t1595.001c_results.json
```

### Debug Mode
Detailed technical information with timing and performance:
```
[DEBUG] Nmap command: nmap ${nmap_flags} -T2 --max-rate 10
[DEBUG] Scan duration: 45.2 seconds
[DEBUG] Packets sent: 1250, received: 890
[DEBUG] Evasion techniques applied: timing, fragmentation
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
  "technique_id": "t1595.001c",
  "technique_name": "scanning_ip_blocks-stealth_null_scan-linux",
  "scan_timestamp": "2024-01-15T10:30:00Z",
  "scan_type": "${scan_type}",
  "targets": "192.168.1.0/24",
  "configuration": {
    "evasion_level": "advanced",
    "timing_template": "sneaky",
    "rate_limit": 10
  },
  "results": {
    "hosts_discovered": 15,
    "ports_found": 23,
    "services_identified": 8,
    "scan_duration_seconds": 45.2
  }
}
```

### Technical Details (`technical_details.xml`)
Nmap XML output with complete technical information.

### Execution Metadata (`metadata/execution_metadata.json`)
Complete execution context and configuration snapshot.

## Examples

### Basic Network Reconnaissance
```bash
export t1595.001c_TARGETS="192.168.1.0/24"
export t1595.001c_OUTPUT_MODE="simple"
export t1595.001c_EVASION_LEVEL="basic"
./src/main.sh
```

### Covert Infrastructure Mapping
```bash
export t1595.001c_TARGETS="10.0.0.0/16"
export t1595.001c_OUTPUT_MODE="stealth"
export t1595.001c_TIMING_TEMPLATE="paranoid"
export t1595.001c_RATE_LIMIT="5"
export t1595.001c_DECOY_COUNT="5"
./src/main.sh
```

### Rapid Assessment with Debug
```bash
export t1595.001c_TARGETS="scan_targets.txt"
export t1595.001c_OUTPUT_MODE="debug"
export t1595.001c_TIMING_TEMPLATE="polite"
./src/main.sh
```

## Security Considerations

### Evasion Techniques
- **Timing Control**: Paranoid/sneaky timing templates
- **Packet Fragmentation**: Split packets to avoid detection
- **Decoy Hosts**: Mix real scans with decoy traffic
- **Source Port Spoofing**: Randomize source ports
- **Rate Limiting**: Control scan speed to avoid thresholds

### Network Impact
- **Low Bandwidth**: Stealth scans minimize network traffic
- **IDS Friendly**: Designed to avoid common signatures
- **Stealth Duration**: Longer scans for better evasion
- **Minimal Footprint**: Single tool dependency (nmap)

### Operational Security
- **No Host Discovery**: Avoid ARP requests when possible
- **DNS Resolution**: Disabled by default to prevent leaks
- **Clean Exit**: Proper cleanup on interruption
- **Audit Trail**: Complete logging for forensic analysis

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
# Missing targets
export t1595.001c_TARGETS=""
./src/main.sh
# Returns: 1 (Configuration Error)

# Network unreachable
export t1595.001c_TARGETS="192.0.2.0/24"  # RFC 5737 test range
./src/main.sh
# Returns: 2 (Precondition Failed)

# Permission denied
sudo_required_but_not_used
# Returns: 2 (Precondition Failed)
```

## Dependencies

### Required Tools
- **nmap**: 7.0+ (network scanning and reconnaissance)
- **bash**: 4.0+ (script execution environment)

### Optional Enhancements
- **sudo**: For privileged scanning modes
- **jq**: For JSON output processing
- **xmlstarlet**: For XML parsing and validation

## Architecture Details

### Contract Functions
1. **Get-Configuration**: Validate and load environment variables
2. **Precondition-Check**: Verify network access and tool availability
3. **Atomic-Action**: Execute stealth scanning with evasion techniques
4. **Postcondition-Verify**: Validate results and cleanup

### Data Flow
```
Environment Variables → Configuration Validation → Precondition Check
                      ↓
              Network Environment Assessment
                      ↓
              Stealth Scan Execution with Evasion
                      ↓
              Results Processing and Validation
                      ↓
              Standardized Output Generation
```

## Contributing
This micro-technique follows standards for:
- Atomic decomposition of adversarial behaviors
- Standardized environment variable patterns
- Contract-driven architecture
- Multi-modal output capabilities

