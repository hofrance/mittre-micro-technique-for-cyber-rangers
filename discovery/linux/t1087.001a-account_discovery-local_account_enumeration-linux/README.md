# T1087.001A - t1087.001a account discovery local account enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1087.001a for Linux environments.

## Technique Details
- **ID**: t1087.001a
- **Name**: t1087.001a account discovery local account enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1087_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1087_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment variables

- `T1087_001A_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1087_001A_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1087_001A_SILENT_MODE`: `true` | `false`
- `T1087_001A_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1087_001A_MIN_UID`: integer (e.g., `1000`)
- `T1087_001A_MAX_UID`: integer (e.g., `60000`)
- `T1087_001A_INCLUDE_SYSTEM_ACCOUNTS`: `true` | `false`
- `T1087_001A_INCLUDE_DISABLED_ACCOUNTS`: `true` | `false`
- `T1087_001A_INCLUDE_LOCKED_ACCOUNTS`: `true` | `false`
- `T1087_001A_INCLUDE_LAST_LOGIN`: `true` | `false`
- `T1087_001A_INCLUDE_GROUPS`: `true` | `false`
- `T1087_001A_INCLUDE_HOME_DIRS`: `true` | `false`
- `T1087_001A_INCLUDE_SHELL_INFO`: `true` | `false`

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
export T1087_001A_OUTPUT_BASE="${T1087.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1087_001A_OUTPUT_MODE="debug"
./src/main.sh
```
