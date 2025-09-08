# T1018.001B - Remote System Discovery: Remote Host Enumeration

## Description
This package implements MITRE ATT&CK atomic micro-technique T1018.001B for Linux environments. Perform comprehensive remote host enumeration including DNS resolution, reverse DNS lookups, and advanced host discovery techniques beyond basic network scanning.

## Technique Details
- **ID**: T1018.001B
- **Name**: Remote System Discovery: Remote Host Enumeration
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
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment Variables
- `T1018_001B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1018_001B_OUTPUT_MODE`: `simple` | `debug` | `stealth` | `none` (default: `simple`)
- `T1018_001B_SILENT_MODE`: `true` | `false` (default: `false`)
- `T1018_001B_TIMEOUT`: Timeout in seconds (default: `300`)
- `T1018_001B_SCAN_TARGETS`: Comma-separated target hosts/IPs (e.g., `localhost,127.0.0.1,192.168.1.1`)
- `T1018_001B_SCAN_PORTS`: Comma-separated ports (e.g., `22,80,443,8080`)
- `T1018_001B_SCAN_T1018_001B_TIMEOUT`: Per-scan timeout in seconds (e.g., `5`)
- `T1018_001B_INCLUDE_HOST_DISCOVERY`: `true` | `false`
- `T1018_001B_INCLUDE_PORT_SCANNING`: `true` | `false`
- `T1018_001B_INCLUDE_SERVICE_DISCOVERY`: `true` | `false`
- `T1018_001B_INCLUDE_NETWORK_SCANNING`: `true` | `false`
- `T1018_001B_INCLUDE_DNS_ENUMERATION`: `true` | `false`
- `T1018_001B_INCLUDE_REVERSE_DNS`: `true` | `false`

## Output Files
- Results stored under the configured output base directory
- JSON output files for each discovery component
- Metadata files with execution information

## Dependencies
This technique requires standard Linux tools and utilities.

## Security Considerations
- **Detection**: Discovery activities may be logged
- **Permissions**: Requires read access to system information
- **Scope**: Limited to accessible system data
- **Impact**: Low - read-only operations

## Examples
```bash
# Basic execution
./src/main.sh

# Custom output directory
export T1018_001B_OUTPUT_BASE="${T1018.001B_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1018_001B_OUTPUT_MODE="debug"
./src/main.sh
```
