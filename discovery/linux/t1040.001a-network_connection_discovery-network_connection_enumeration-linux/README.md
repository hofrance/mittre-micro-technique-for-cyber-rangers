# T1040.001A - t1040.001a network connection discovery network connection enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1040.001a for Linux environments.

## Technique Details
- **ID**: t1040.001a
- **Name**: t1040.001a network connection discovery network connection enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1040_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1040_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1040_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1040_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1040_001A_SILENT_MODE`: `true` | `false`
- `T1040_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1040_001A_INCLUDE_ACTIVE_CONNECTIONS`: `true` | `false`
- `T1040_001A_INCLUDE_LISTENING_PORTS`: `true` | `false`
- `T1040_001A_INCLUDE_ROUTING_TABLE`: `true` | `false`
- `T1040_001A_INCLUDE_ARP_TABLE`: `true` | `false`
- `T1040_001A_INCLUDE_NETWORK_INTERFACES`: `true` | `false`
- `T1040_001A_INCLUDE_DNS_RESOLUTION`: `true` | `false`
- `T1040_001A_INCLUDE_NETSTAT`: `true` | `false`
- `T1040_001A_INCLUDE_SS`: `true` | `false`

## Output Files
- Results stored in /tmp/mitre_results directory
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
export T1040_001A_OUTPUT_BASE="${T1040.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1040_001A_OUTPUT_MODE="debug"
./src/main.sh
```
