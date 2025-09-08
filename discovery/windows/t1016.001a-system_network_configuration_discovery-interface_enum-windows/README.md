# T1016.001A - System Network Configuration Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1016.001A for Windows environments. System Network Configuration Discovery - Interface Enumeration.

## Technique Details
- **ID**: T1016.001A
- **Name**: System Network Configuration Discovery
- **Parent Technique**: System Network Configuration Discovery (T1016)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: User

## Manual Execution
```powershell
# Set environment variables
$env:T1016_001A_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: System Network Configuration Discovery - Interface Enumeration ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows APIs
- Privilege: User

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1016_001A_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1016_001A_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1016_001A_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1016_001A_MAX_INTERFACES` | Maximum interfaces to enumerate | `10`, `25`, `50`, `100` | `50` | No |
| `T1016_001A_INCLUDE_DISABLED` | Include disabled interfaces | `true`, `false` | `false` | No |
| `T1016_001A_INCLUDE_VIRTUAL` | Include virtual interfaces | `true`, `false` | `true` | No |
| `T1016_001A_INCLUDE_LOOPBACK` | Include loopback interfaces | `true`, `false` | `false` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1016_001A_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1016_001A_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1016_001A_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1016_001A_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1016_001A_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1016.001a_results.json`: Execution results with metadata
- `t1016.001a_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-NetAdapter` - Network adapter enumeration (Windows 8+/Server 2012+)
- `Get-NetIPConfiguration` - IP configuration retrieval
- `Get-NetRoute` - Network routing information
- `Win32_NetworkAdapter` - WMI fallback for network adapters
- `Win32_NetworkAdapterConfiguration` - WMI fallback for IP configuration

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

