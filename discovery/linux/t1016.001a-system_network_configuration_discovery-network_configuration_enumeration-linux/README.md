# T1016.001A - t1016.001a system network configuration discovery network configuration enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1016.001a for Linux environments.

## Technique Details
- **ID**: t1016.001a
- **Name**: t1016.001a system network configuration discovery network configuration enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1016_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1016_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1016_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1016_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1016_001A_SILENT_MODE`: `true` | `false`
- `T1016_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1016_001A_INCLUDE_INTERFACES`: `true` | `false`
- `T1016_001A_INCLUDE_ROUTES`: `true` | `false`
- `T1016_001A_INCLUDE_DNS`: `true` | `false`
- `T1016_001A_INCLUDE_FIREWALL`: `true` | `false`
- `T1016_001A_INCLUDE_NETWORK_FILES`: `true` | `false`
- `T1016_001A_INCLUDE_NETWORK_SERVICES`: `true` | `false`
- `T1016_001A_MAX_INTERFACES`: integer (e.g., `20`)
- `T1016_001A_MAX_ROUTES`: integer (e.g., `50`)

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
export T1016_001A_OUTPUT_BASE="${T1016.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1016_001A_OUTPUT_MODE="debug"
./src/main.sh
```
