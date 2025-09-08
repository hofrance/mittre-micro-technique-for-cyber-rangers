# T1069.002A - Permission Groups Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1069.002A for Windows environments. Permission Groups Discovery - Domain Groups Enumeration (Security Analysis).

## Technique Details
- **ID**: T1069.002A
- **Name**: Permission Groups Discovery
- **Parent Technique**: Permission Groups Discovery (T1069)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: User (Domain User Context)

## Manual Execution
```powershell
# Set environment variables
$env:T1069_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique (REAL SYSTEM ACTIONS)
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: Permission Groups Discovery - Domain Groups Enumeration ONLY
- Scope: One specific action
- Dependency: PowerShell + Active Directory Module + Domain Access
- Privilege: Domain User

## Real System Actions Performed
This technique performs measurable actions on the Windows system:
- **Get-ADGroup -Filter *** : Retrieves all Active Directory groups with comprehensive properties
- **Domain Groups Enumeration**: Enumerates all domain groups and their attributes
- **Group Properties Analysis**: Analyzes group scope, category, creation dates, and membership counts
- **Security Group Discovery**: Identifies security groups within the domain
- **Group Membership Statistics**: Calculates membership statistics and group distributions
- **File Creation**: Generates detailed JSON reports with domain groups data
- **Domain Security Assessment**: Provides domain group security analysis

## Advanced Analysis Capabilities
- **Comprehensive Domain Mapping**: Maps complete domain group hierarchy
- **Group Classification**: Classifies groups by type, scope, and security context
- **Membership Analysis**: Analyzes group memberships and user distributions
- **Security Group Identification**: Identifies critical security groups and their roles
- **Group Lifecycle Analysis**: Tracks group creation, modification, and usage patterns
- **Domain Statistics**: Provides comprehensive domain group statistics and metrics
- **Security Assessment**: Evaluates domain group security posture and configurations

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
- `t1069.002a_results.json`: Execution results with domain groups enumeration data
- `t1069.002a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime
- `activedirectory` - Active Directory PowerShell module

**Technique-Specific Dependencies:**
- `Get-ADGroup` - Active Directory module for domain group enumeration
- `Microsoft.ActiveDirectory.Management` - PowerShell module for Active Directory management
- `Active Directory Web Services` - AD DS service for remote management
- `LDAP` - Lightweight Directory Access Protocol for directory queries
- `Domain Controller Access` - Access to domain controllers for group enumeration

### Installation Commands

#### Windows Package Manager (winget)
```powershell
winget install Microsoft.PowerShell
winget install Microsoft.DotNet.Runtime
# Install RSAT for Active Directory tools
winget install Microsoft.RemoteServerAdministrationTools
```

#### Chocolatey
```powershell
choco install powershell-core
choco install dotnet-runtime
# Install RSAT for Active Directory
choco install rsat
```

#### Manual Installation
```powershell
# Download and install PowerShell Core
# Download and install .NET Runtime
# Install Remote Server Administration Tools (RSAT)
# Enable Active Directory module: Enable-WindowsOptionalFeature -Online -FeatureName RSAT-AD-PowerShell
```

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <tool_name>
# [ERROR] Active Directory module not available
```

**Domain Requirements:**
- Domain-joined computer or access to domain controller
- Domain user credentials with appropriate permissions
- Network connectivity to Active Directory services

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
