# T1069.001A - Permission Groups Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1069.001A for Windows environments. Permission Groups Discovery - Local Groups Enumeration (Basic Discovery).

## Technique Details
- **ID**: T1069.001A
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
**Single Observable Action**: Permission Groups Discovery - Local Groups Enumeration ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Local Groups APIs + System Commands
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-LocalGroup**: Retrieves all local groups using PowerShell LocalAccounts module
- **net localgroup**: Enumerates local groups using system command for fallback
- **WMI Group Enumeration**: Queries Win32_Group for comprehensive group discovery
- **Group Verification**: Validates discovered groups against system registry
- **Local Group Membership Analysis**: Analyzes group properties and configurations
- **File Creation**: Generates detailed JSON reports with local groups data
- **Group Information Extraction**: Extracts group names, descriptions, and properties

## Advanced Analysis Capabilities
- **Multi-Method Enumeration**: Uses Get-LocalGroup, WMI, and net commands
- **Fallback Mechanisms**: Automatic fallback if primary method fails
- **Group Property Analysis**: Extracts detailed group information and metadata
- **Verification and Validation**: Cross-verifies group existence and properties
- **Comprehensive Reporting**: Detailed reports for security analysis and auditing
- **Error Handling**: Robust error handling for different Windows versions

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

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1069_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1069_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1069_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1069_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1069_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1069.001a_results.json`: Execution results with local groups enumeration data
- `t1069.001a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-LocalGroup` - PowerShell LocalAccounts module for local group enumeration
- `Microsoft.PowerShell.LocalAccounts` - PowerShell module for local account management
- `net localgroup` - System command for local group enumeration
- `Win32_Group` - WMI class for group information and properties
- `Microsoft.PowerShell.Management` - PowerShell management module for system operations
- `System.Diagnostics.Process` - .NET process management for command execution

### Installation Commands

#### Windows Package Manager (winget)
```powershell
winget install Microsoft.PowerShell
winget install Microsoft.DotNet.Runtime
```

#### Chocolatey
```powershell
choco install powershell-core
choco install dotnet-runtime
```

#### Manual Installation
```powershell
# Download and install PowerShell Core
# Download and install .NET Runtime
```

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <tool_name>
```

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
