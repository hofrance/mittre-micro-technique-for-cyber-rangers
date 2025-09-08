# T1016.001C - System Network Configuration Discovery

## Description
This package implements MITRE ATT&CK atomic micro-technique T1016.001C for Windows environments. System Network Configuration Discovery - DNS Discovery.

## Technique Details
- **ID**: T1016.001C
- **Name**: System Network Configuration Discovery
- **Parent Technique**: System Network Configuration Discovery (T1016)
- **Tactic**: Discovery (TA0007)
- **Platform**: Windows
- **Permissions Required**: Administrator

## Manual Execution
```powershell
# IMPORTANT: This technique requires Administrator privileges
# Run PowerShell as Administrator before executing

# Set environment variables
$env:T1016_OUTPUT_BASE = "C:\temp\mitre_results"

# Execute the technique
.\src\main.ps1
```

## Atomic Action
**Single Observable Action**: System Network Configuration Discovery - DNS Discovery ONLY
- Scope: One specific action
- Dependency: PowerShell + Windows APIs + Registry Access
- Privilege: Administrator (HKLM Registry access required)

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1016_OUTPUT_BASE` | Base directory for results | `C:\temp\mitre_results`, `C:\logs\mitre`, `C:\users\user\results` | `C:\temp\mitre_results` | Yes |
| `T1016_OUTPUT_FORMAT` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1016_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1016_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1016_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |
| `T1016_MAX_RESULTS` | Maximum results to return | `100`, `500`, `1000`, `5000` | `1000` | No |
| `T1016_DISCOVERY_SCOPE` | Scope of discovery operation | `local`, `remote`, `all` | `local` | No |
| `T1016_ENUMERATION_DEPTH` | Depth of enumeration | `1`, `2`, `3` | `1` | No |
| `T1016_FILTER_RESULTS` | Enable result filtering | `true`, `false` | `false` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1016_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `false` | No |
| `T1016_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1016_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `false` | No |
| `T1016_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1016_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1016.001c_results.json`: Execution results with metadata
- `t1016.001c_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `powershell` - PowerShell interpreter (Administrator mode)
- `dotnet` - .NET Framework/Runtime

**Technique-Specific Dependencies:**
- `Get-DnsClient` - DNS client configuration retrieval
- `Get-DnsClientServerAddress` - DNS server addresses
- `Resolve-DnsName` - DNS name resolution
- `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters` - Registry access (Administrator required)
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient` - Registry access (Administrator required)

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
