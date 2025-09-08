# T1018.002B - t1018.002b remote system discovery port scanning linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1018.002b for Linux environments.

## Technique Details
- **ID**: t1018.002b
- **Name**: t1018.002b remote system discovery port scanning linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1018_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1018_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1018_002B_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1018_002B_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1018_002B_SILENT_MODE`: `true` | `false`
- `T1018_002B_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1018_002B_SCAN_TARGETS`: comma-separated targets
- `T1018_002B_SCAN_PORTS`: comma-separated ports
- `T1018_002B_SCAN_TYPE`: `tcp` | `udp`
- `T1018_002B_SCAN_T1018_002B_TIMEOUT`: per-scan timeout in seconds
- `T1018_002B_INCLUDE_SERVICE_DETECTION`: `true` | `false`
- `T1018_002B_INCLUDE_VERSION_DETECTION`: `true` | `false`

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
export T1018_002B_OUTPUT_BASE="${T1018.002B_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1018_002B_OUTPUT_MODE="debug"
./src/main.sh
```
