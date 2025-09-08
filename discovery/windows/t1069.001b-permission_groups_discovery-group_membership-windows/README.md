# T1069.001B - Permission Groups Discovery (Group Membership)

## Description
This package implements MITRE ATT&CK atomic micro-technique T1069.001B for Windows environments. Permission Groups Discovery - Group Membership Analysis - Alternative Implementation.

## Technique Details
- **ID**: T1069.001B
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
**Single Observable Action**: Permission Groups Discovery - Group Membership Analysis ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Local Groups APIs + Membership Analysis
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-LocalGroup**: Retrieves all local groups for membership analysis
- **Get-LocalGroupMember**: Extracts detailed membership information for each local group
- **Group Membership Analysis**: Analyzes group memberships and member properties
- **Member Property Extraction**: Retrieves user properties and account details
- **Nested Group Analysis**: Analyzes hierarchical group relationships
- **File Creation**: Generates detailed JSON reports with group membership data
- **Membership Statistics**: Provides comprehensive membership analysis and reporting

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
- `t1069.001b_results.json`: Execution results with group membership analysis data
- `t1069.001b_security_audit.log`: Security audit log

## Dependencies
- `powershell` - PowerShell interpreter
- `Get-LocalGroup` - PowerShell LocalAccounts module for local group enumeration
- `Get-LocalGroupMember` - PowerShell LocalAccounts module for group membership extraction
