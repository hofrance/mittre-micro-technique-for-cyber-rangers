# T1083.001A - t1083.001b file and directory discovery file system enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1083.001b for Linux environments.

## Technique Details
- **ID**: t1083.001b
- **Name**: t1083.001b file and directory discovery file system enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1083_001B_OUTPUT_BASE="/tmp/mitre_results" && export T1083_001B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1083_001B_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1083_001B_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1083_001B_SILENT_MODE`: `true` | `false`
- `T1083_001B_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1083_001B_MAX_DEPTH`: integer
- `T1083_001B_FILE_LIMIT`: integer
- `T1083_001B_INCLUDE_HIDDEN_FILES`: `true` | `false`
- `T1083_001B_INCLUDE_RECENT_FILES`: `true` | `false`
- `T1083_001B_INCLUDE_SYSTEM_DIRS`: `true` | `false`
- `T1083_001B_INCLUDE_USER_DIRS`: `true` | `false`

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
export T1083_001B_OUTPUT_BASE="${T1083.001B_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1083_001B_OUTPUT_MODE="debug"
./src/main.sh
```
