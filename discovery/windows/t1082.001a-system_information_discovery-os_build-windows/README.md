# T1082.001A - System Information Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1082.001A for Windows environments. System Information Discovery - OS Build Information Collection.

## Technique Details
- **ID**: T1082.001A
- **Name**: System Information Discovery
- **Parent Technique**: System Information Discovery (T1082)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: Administrator

## Manual Execution
```powershell
# Set environment variables
$env:T1082_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique (REAL SYSTEM ACTIONS - REQUIRES ADMIN)
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: System Information Discovery - OS Build Information ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows Registry Access + System Commands
- Privilege: Administrator (HKLM Registry Access Required)

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-ComputerInfo**: Retrieves comprehensive system information using PowerShell
- **Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"**: Accesses Windows registry for OS build details (Administrator Required)
- **systeminfo.exe**: Executes system information command for OS details
- **Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"**: Accesses system policies registry (Administrator Required)
- **Registry Key Enumeration**: Enumerates Windows registry keys for system information
- **OS Build Information Collection**: Collects Windows build, version, and edition details
- **System Specification Gathering**: Gathers hardware and software specifications
- **File Creation**: Generates detailed JSON reports with comprehensive system information
- **Security Feature Analysis**: Analyzes system security features and configurations

## Advanced Analysis Capabilities
- **Comprehensive OS Analysis**: Analyzes operating system build, version, and edition
- **Registry-Based Discovery**: Uses Windows registry for detailed system information
- **Hardware Specification Mapping**: Maps system hardware specifications and capabilities
- **Security Feature Detection**: Detects and analyzes system security features
- **Build Information Extraction**: Extracts detailed Windows build and version information
- **System Configuration Analysis**: Analyzes system configurations and settings
- **Comprehensive Reporting**: Generates detailed system information reports

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1082_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1082_OUTPUT_FORMAT` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1082_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1082_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1082_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |
| `T1082_MAX_RESULTS` | Maximum results to return | `100`, `500`, `1000`, `5000` | `1000` | No |
| `T1082_DISCOVERY_SCOPE` | Scope of discovery operation | `local`, `remote`, `all` | `local` | No |
| `T1082_ENUMERATION_DEPTH` | Depth of enumeration | `1`, `2`, `3` | `1` | No |
| `T1082_FILTER_RESULTS` | Enable result filtering | `true`, `false` | `false` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1082_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1082_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1082_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1082_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1082_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1082.001a_results.json`: Execution results with comprehensive OS build information
- `t1082.001a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-ComputerInfo` - PowerShell cmdlet for comprehensive system information
- `Get-ItemProperty` - PowerShell cmdlet for registry access (Administrator Required)
- `systeminfo.exe` - Windows system information command
- `HKLM Registry Access` - Windows registry access with administrative privileges
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
# [ERROR] Registry access denied - Administrator privileges required
```

**Administrator Requirements:**
- Administrative privileges required for HKLM registry access
- Elevated PowerShell session or RunAs Administrator
- System-level access for comprehensive system information collection

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
