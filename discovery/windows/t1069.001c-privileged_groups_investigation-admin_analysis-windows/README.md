# T1069.001C - Permission Groups Discovery (Admin Analysis)

## Description
This package implements MITRE ATT&CK atomic micro-technique T1069.001C for Windows environments. Permission Groups Discovery - Privileged Groups Investigation (Admin Analysis) - Alternative Implementation.

## Technique Details
- **ID**: T1069.001C
- **Name**: Permission Groups Discovery
- **Parent Technique**: Permission Groups Discovery (T1069)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: User

## Manual Execution
```powershell
# Set environment variables
$env:T1069_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique (REAL SYSTEM ACTIONS)
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: Permission Groups Discovery - Privileged Groups Investigation (Admin Analysis) ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Local Groups APIs + Administrative Analysis
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-LocalGroup -Name $groupName**: Retrieves specific privileged groups by name
- **Get-LocalGroupMember -Group $groupName**: Extracts membership information for privileged groups
- **Administrative Analysis**: Focuses on admin group investigation and analysis
- **Privilege Assessment**: Evaluates administrative privileges and access levels
- **Group Security Analysis**: Analyzes group security configurations and memberships
- **File Creation**: Generates detailed JSON reports with administrative analysis
- **Security Assessment**: Provides administrative privilege risk analysis

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1069_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1069_OUTPUT_FORMAT` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1069_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1069_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1069_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |
| `T1069_MAX_RESULTS` | Maximum results to return | `100`, `500`, `1000`, `5000` | `1000` | No |
| `T1069_DISCOVERY_SCOPE` | Scope of discovery operation | `local`, `remote`, `all` | `local` | No |
| `T1069_ENUMERATION_DEPTH` | Depth of enumeration | `1`, `2`, `3` | `1` | No |
| `T1069_FILTER_RESULTS` | Enable result filtering | `true`, `false` | `false` | No |

## Output Files
- `t1069.001c_results.json`: Execution results with privileged groups admin analysis data
- `t1069.001c_security_audit.log`: Security audit log

## Dependencies
- `powershell` - PowerShell interpreter
- `Get-LocalGroup` - PowerShell LocalAccounts module for privileged group enumeration
- `Get-LocalGroupMember` - PowerShell LocalAccounts module for privileged group membership extraction

## Technical Requirements

### System Requirements

- PowerShell 5.0 or higher
- Windows API access for system enumeration
- WMI access for system queries

### Dependencies

- Windows Management Instrumentation (WMI) access
- Registry read permissions
- Network connectivity (for network discovery techniques)

### Output Files
- `discovery_results.json`: Complete discovery execution results
- `execution_metadata.json`: Execution metadata and environment information

### Core Functionality

- Get-EnvironmentVariables: Environment configuration
- Initialize-OutputStructure: Create output directory structure
- Write-JsonOutput: Generate structured JSON output files
- Get-ExecutionMetadata: Collect execution and system metadata
- Invoke-SafeCommand: Execute commands with error handling
- Write-SimpleOutput: Realistic output mode (default)
- Write-DebugOutput: Forensic JSON output mode
- Write-StealthOutput: Covert operation mode
- Select-OutputMode: Triple output architecture controller
- Get-DiscoveryTarget: Primary discovery enumeration function
- main: Primary technique execution

---
*Package Version: 0.1.0*  
*Last Updated: August 16, 2025*  
*MITRE ATT&CK Discovery Framework Implementation*
