# T1057.001A - Process Discovery (Running Inventory)

## Description
This package implements MITRE ATT&CK atomic micro-technique T1057.001A for Windows environments. Process Discovery - Basic Process Enumeration (Running Inventory) - Alternative Implementation.

## Technique Details
- **ID**: T1057.001A
- **Name**: Process Discovery
- **Parent Technique**: Process Discovery (T1057)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: User

## Manual Execution
```powershell
# Set environment variables
$env:T1057_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique (REAL SYSTEM ACTIONS)
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: Process Discovery - Basic Process Enumeration (Running Inventory) ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Process APIs
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-Process**: Retrieves all running processes for inventory
- **Process Running Inventory**: Creates inventory of currently running processes
- **Process Enumeration**: Enumerates active processes on the system
- **File Creation**: Generates detailed JSON reports with running process data
- **Process Analysis**: Provides running process analysis and statistics

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1057_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1057_OUTPUT_FORMAT` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1057_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1057_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1057_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |
| `T1057_MAX_RESULTS` | Maximum results to return | `100`, `500`, `1000`, `5000` | `1000` | No |
| `T1057_DISCOVERY_SCOPE` | Scope of discovery operation | `local`, `remote`, `all` | `local` | No |
| `T1057_ENUMERATION_DEPTH` | Depth of enumeration | `1`, `2`, `3` | `1` | No |
| `T1057_FILTER_RESULTS` | Enable result filtering | `true`, `false` | `false` | No |

## Output Files
- `t1057.001a_results.json`: Execution results with running process inventory data
- `t1057.001a_security_audit.log`: Security audit log

## Dependencies
- `powershell` - PowerShell interpreter
- `Get-Process` - PowerShell process enumeration for running inventory
