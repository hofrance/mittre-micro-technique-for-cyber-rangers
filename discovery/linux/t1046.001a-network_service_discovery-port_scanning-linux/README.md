# T1046.001A - t1046.001a network service discovery port scanning linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1046.001a for Linux environments.

## Technique Details
- **ID**: t1046.001a
- **Name**: t1046.001a network service discovery port scanning linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1046_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1046_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1046_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1046_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1046_001A_SILENT_MODE`: `true` | `false`
- `T1046_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1046_001A_SCAN_TARGETS`: comma-separated list of hosts/IPs (e.g., `localhost,192.168.1.1`)
- `T1046_001A_SCAN_PORTS`: comma-separated list of ports (e.g., `21,22,80,443`)
- `T1046_001A_SCAN_TYPE`: `tcp` | `udp`
- `T1046_001A_INCLUDE_SERVICE_DETECTION`: `true` | `false`
- `T1046_001A_INCLUDE_BANNER_GRABBING`: `true` | `false`
- `T1046_001A_MAX_TARGETS`: integer (e.g., `10`)
- `T1046_001A_MAX_PORTS`: integer (e.g., `100`)

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
export T1046_001A_OUTPUT_BASE="${T1046.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1046_001A_OUTPUT_MODE="debug"
./src/main.sh
```
