# T1057.001A - Process Discovery (Process Inventory Extended)

## Description
This package implements MITRE ATT&CK atomic micro-technique T1057.001A for Windows environments. Process Discovery - Basic Process Enumeration (Process Inventory Extended) - Alternative Implementation.

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
**Single Observable Action**: Process Discovery - Basic Process Enumeration (Process Inventory Extended) ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Process APIs + WMI + Extended Analysis
- Privilege: User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-Process | Where-Object { $_.ProcessName -ne "" }**: Retrieves all running processes with filtering
- **Get-WmiObject -Class Win32_Process**: Enumerates process details using Windows Management Instrumentation
- **Get-Process -Id $PID**: Retrieves specific process information for current process
- **Extended Process Inventory**: Creates comprehensive process inventory with enhanced details
- **Process Property Analysis**: Analyzes detailed process properties and attributes
- **Memory and CPU Analysis**: Evaluates process resource usage and performance metrics
- **File Creation**: Generates detailed JSON, CSV, and XML reports with extended process data
- **Multi-Format Output**: Provides process inventory in multiple output formats

## Advanced Analysis Capabilities
- **Enhanced Process Discovery**: Uses multiple methods for comprehensive process enumeration
- **Resource Usage Analysis**: Analyzes CPU and memory usage patterns
- **Process Classification**: Classifies processes by system vs user and resource usage
- **Multi-Format Reporting**: Generates reports in JSON, CSV, and XML formats
- **Performance Metrics**: Tracks process performance and resource consumption
- **Comprehensive Inventory**: Creates extended process inventory with detailed metadata
- **Statistical Analysis**: Provides statistical analysis of process populations

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
- `t1057.001a_results.json`: Execution results with extended process inventory data
- `t1057.001a_process_inventory.csv`: CSV format process inventory
- `t1057.001a_process_inventory.xml`: XML format process inventory
- `t1057.001a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-Process` - PowerShell process enumeration with filtering capabilities
- `Get-WmiObject` - Windows Management Instrumentation for extended process data
- `Win32_Process` - WMI process information class with comprehensive properties
- `Where-Object` - PowerShell filtering cmdlet for process selection
- `Microsoft.PowerShell.Management` - PowerShell management module for system operations
- `System.Diagnostics.Process` - .NET process management and performance monitoring

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
