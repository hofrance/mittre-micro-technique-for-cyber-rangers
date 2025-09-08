# T1083.002B - t1083.002b file and directory discovery hidden files discovery linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1083.002b for Linux environments.

## Technique Details
- **ID**: t1083.002b
- **Name**: t1083.002b file and directory discovery hidden files discovery linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1083_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1083_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment Variables
- `T1083_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1083_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1083_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1083_002B_TIMEOUT`: Timeout in seconds (default: 300)

## Environment variables

- `T1083_002B_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1083_002B_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1083_002B_SILENT_MODE`: `true` | `false`
- `T1083_002B_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1083_002B_SCAN_PATHS`: comma-separated list of paths to scan
- `T1083_002B_INCLUDE_DOT_FILES`: `true` | `false`
- `T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES`: `true` | `false`
- `T1083_002B_INCLUDE_ALTERNATE_STREAMS`: `true` | `false`
- `T1083_002B_INCLUDE_STEGANOGRAPHY`: `true` | `false`
- `T1083_002B_INCLUDE_SYMLINKS`: `true` | `false`

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
export T1083_002B_OUTPUT_BASE="${T1083.002B_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1083_002B_OUTPUT_MODE="debug"
./src/main.sh
```
