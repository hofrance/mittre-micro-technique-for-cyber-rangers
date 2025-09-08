# T1057.001A - t1057.001a process discovery running processes enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1057.001a for Linux environments.

## Technique Details
- **ID**: t1057.001a
- **Name**: t1057.001a process discovery running processes enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1057_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1057_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1057_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1057_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1057_001A_SILENT_MODE`: `true` | `false`
- `T1057_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1057_001A_MAX_PROCESSES`: integer
- `T1057_001A_FILTER_BY_USER`: username or empty
- `T1057_001A_FILTER_BY_COMMAND`: substring or empty
- `T1057_001A_INCLUDE_SYSTEM_PROCESSES`: `true` | `false`
- `T1057_001A_INCLUDE_USER_PROCESSES`: `true` | `false`
- `T1057_001A_INCLUDE_PROCESS_TREE`: `true` | `false`
- `T1057_001A_INCLUDE_PROCESS_FILES`: `true` | `false`
- `T1057_001A_INCLUDE_PROCESS_NETWORK`: `true` | `false`
- `T1057_001A_INCLUDE_PROCESS_ENV`: `true` | `false`

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
export T1057_001A_OUTPUT_BASE="${T1057.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1057_001A_OUTPUT_MODE="debug"
./src/main.sh
```
