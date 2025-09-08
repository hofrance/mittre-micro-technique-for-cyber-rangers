# T1033.002A - System Owner/User Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1033.002A for Windows environments. System Owner/User Discovery - Domain Users.

## Technique Details
- **ID**: T1033.002A
- **Name**: System Owner/User Discovery
- **Parent Technique**: System Owner/User Discovery (T1033)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: User

## Manual Execution
```powershell
# Set environment variables
$env:T1033_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique (REAL SYSTEM ACTIONS)
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: System Owner/User Discovery - Domain Users ONLY
- Scope: One specific action
- Dependency: PowerShell + Active Directory + System Commands
- Privilege: User (Domain user context)

## Real System Actions Performed
This technique performs measurable actions on the Windows domain:
- **Get-ADUser -Filter *** : Enumerates ALL Active Directory user accounts in the domain
- **Get-ADGroup** and **Get-ADGroupMember**: Discovers domain groups and their memberships
- **dsquery user**: Performs LDAP queries for domain user discovery
- **net user /domain**: Queries domain user accounts using Windows NET commands
- **Directory Services Access**: Queries Active Directory Domain Services for user information
- **File Creation**: Generates comprehensive JSON output files with domain user data

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1033_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1033_OUTPUT_FORMAT` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1033_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1033_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1033_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |
| `T1033_MAX_RESULTS` | Maximum results to return | `100`, `500`, `1000`, `5000` | `1000` | No |
| `T1033_DISCOVERY_SCOPE` | Scope of discovery operation | `local`, `remote`, `all` | `local` | No |
| `T1033_ENUMERATION_DEPTH` | Depth of enumeration | `1`, `2`, `3` | `1` | No |
| `T1033_FILTER_RESULTS` | Enable result filtering | `true`, `false` | `false` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1033_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1033_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1033_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1033_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1033_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1033.002a_results.json`: Execution results with comprehensive domain user enumeration data
- `t1033.002a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-ADUser` - Active Directory user enumeration (requires RSAT optional)
- `Get-ADGroup` - Active Directory group enumeration (requires RSAT optional)
- `Get-ADGroupMember` - Active Directory group membership (requires RSAT optional)
- `dsquery` - Directory Services query tool (built-in Windows)
- `net user /domain` - Windows NET command for domain users (built-in)
- `Active Directory Domain Services` - Domain connectivity required

### Installation Commands

#### Windows Package Manager (winget)
```powershell
winget install Microsoft.PowerShell
winget install Microsoft.DotNet.Runtime
# Optional: RSAT for enhanced AD functionality
winget install Microsoft.RemoteServerAdministrationTools
```

#### Chocolatey
```powershell
choco install powershell-core
choco install dotnet-runtime
# Optional: RSAT for enhanced AD functionality
choco install rsat
```

#### Manual Installation
```powershell
# Download and install PowerShell Core
# Download and install .NET Runtime
# Optional: Install RSAT from Windows Features
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
