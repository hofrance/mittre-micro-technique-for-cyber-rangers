# T1057.001B - Process Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1057.001B for Windows environments. Process Discovery - Detailed Process Analysis (Deep Inspection).

## Technique Details
- **ID**: T1057.001B
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
**Single Observable Action**: Process Discovery - Detailed Process Analysis ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Process APIs + Deep Inspection
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-Process -Id $config.TARGET_PROCESS_ID**: Retrieves specific processes by Process ID
- **Get-Process -Name $config.TARGET_PROCESS_NAME**: Retrieves processes by exact name matching
- **Get-Process | Where-Object { $_.Id -gt 4 }**: Enumerates all user-mode processes (excludes system processes)
- **Get-Process | Where-Object { $_.ProcessName -in @("explorer", "notepad", "chrome", "firefox", "powershell") }**: Filters processes by common application names
- **Deep Process Inspection**: Analyzes process properties, memory usage, CPU usage, and relationships
- **File Creation**: Generates detailed JSON reports with process analysis data
- **Process Performance Monitoring**: Captures real-time process metrics and statistics

## Advanced Analysis Capabilities
- **Targeted Process Retrieval**: Get specific processes by ID or name
- **User Process Enumeration**: Filter out system processes (ID > 4)
- **Application-Specific Analysis**: Focus on common user applications
- **Performance Metrics Collection**: CPU, memory, and resource usage analysis
- **Process Relationship Mapping**: Parent-child process analysis
- **Comprehensive Reporting**: Detailed analysis reports for security investigations

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
- `t1057.001b_results.json`: Execution results with detailed process analysis data
- `t1057.001b_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-Process` - PowerShell process enumeration with filtering capabilities
- `Get-CimInstance` - Windows Management Instrumentation for extended process data
- `Win32_Process` - WMI process information class with performance metrics
- `Microsoft.PowerShell.Management` - PowerShell management module for process operations
- `System.Diagnostics.Process` - .NET process management and performance monitoring
- `Where-Object` - PowerShell filtering cmdlet for process selection

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
