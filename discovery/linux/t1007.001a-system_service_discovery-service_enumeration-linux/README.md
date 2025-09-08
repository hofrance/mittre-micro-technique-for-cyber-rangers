# T1007.001A - System Service Discovery: Service Enumeration

## Description
This package implements MITRE ATT&CK atomic micro-technique T1007.001A for Linux environments. Discover system services across multiple service managers (systemd, SysV init, Upstart) to understand system architecture and running services.

## Technique Details
- **ID**: T1007.001A
- **Name**: System Service Discovery: Service Enumeration
- **Parent Technique**: T1007
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1007_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1007_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1007_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1007_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1007_001A_SILENT_MODE`: `true` | `false`
- `T1007_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1007_001A_MAX_SERVICES`: integer (e.g., `200`)
- `T1007_001A_FILTER_BY_STATE`: `active` | `inactive` | empty
- `T1007_001A_INCLUDE_SYSTEMD_SERVICES`: `true` | `false`
- `T1007_001A_INCLUDE_INITD_SERVICES`: `true` | `false`
- `T1007_001A_INCLUDE_RUNNING_SERVICES`: `true` | `false`
- `T1007_001A_INCLUDE_STOPPED_SERVICES`: `true` | `false`
- `T1007_001A_INCLUDE_SERVICE_STATUS`: `true` | `false`
- `T1007_001A_INCLUDE_SERVICE_DEPENDENCIES`: `true` | `false`

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
export T1007_001A_OUTPUT_BASE="${T1007_001A_OUTPUT_BASE:-/tmp/mitre_results}"
./src/main.sh

# Debug mode
export T1007_001A_OUTPUT_MODE="debug"
./src/main.sh
```
