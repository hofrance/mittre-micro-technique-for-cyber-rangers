# T1057.001A - Process Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1057.001A for Windows environments. Process Discovery - Basic Enumeration.

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
**Single Observable Action**: Process Discovery - Basic Enumeration ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Process APIs
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-Process**: Enumerates ALL running processes using PowerShell
- **Get-CimInstance Win32_Process**: Queries Windows Management Instrumentation for process details
- **Process Information Retrieval**: Collects PID, name, CPU usage, memory usage, user context
- **File Creation**: Generates JSON output files with comprehensive process enumeration data
- **System Process Query**: Accesses Windows process database for real-time information

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

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1057_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1057_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1057_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1057_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1057_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1057.001a_results.json`: Execution results with comprehensive process enumeration data
- `t1057.001a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-Process` - PowerShell process enumeration cmdlet
- `Get-CimInstance` - Windows Management Instrumentation queries
- `Win32_Process` - WMI process information class
- `Microsoft.PowerShell.Management` - PowerShell management module
- `System.Diagnostics.Process` - .NET process management classes

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
