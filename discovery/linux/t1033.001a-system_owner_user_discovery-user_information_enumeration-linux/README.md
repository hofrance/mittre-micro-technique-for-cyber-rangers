# T1033.001A - t1033.001a system owner user discovery user information enumeration linux

## Description
This package implements MITRE ATT&CK atomic micro-technique t1033.001a for Linux environments.

## Technique Details
- **ID**: t1033.001a
- **Name**: t1033.001a system owner user discovery user information enumeration linux
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1033_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1033_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: perform discovery action ONLY
- Scope: One specific discovery action
- Dependency: Bash + system access
- Privilege: User

## Environment Variables
- `T1033_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1033_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1033_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1033_001A_TIMEOUT`: Timeout in seconds (default: 300)

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
export T1033_001A_OUTPUT_BASE="${T1033.001A_OUTPUT_BASE:-/tmp/mitre_results}/results"
./src/main.sh

# Debug mode
export T1033_001A_OUTPUT_MODE="debug"
./src/main.sh
```
