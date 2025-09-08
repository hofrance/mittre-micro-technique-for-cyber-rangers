# T1548.001C - linux

## Description
This package implements MITRE ATT&CK atomic micro-technique T1548.001C for Linux environments. Capabilities abuse ONLY.

## Technique Details
- **ID**: T1548.001C
- **Name**: Capabilities abuse ONLY
- **Parent Technique**: T1548
- **Tactic**: TA0004 - Privilege Escalation
- **Platform**: Linux
- **Permissions Required**: **Root**

## Manual Execution
```bash
export T1548_001C_OUTPUT_BASE="/tmp/mitre_results"
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: Capabilities abuse ONLY ONLY
- Scope: One specific action
- Dependency: Bash + filesystem access
- Privilege: Root

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1548_001C_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/var/log/mitre`, `/home/user/results` | `/tmp/mitre_results` | Yes |
| `T1548_001C_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1548_001C_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1548_001C_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1548_001C_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1548_001C_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `true` | No |
| `T1548_001C_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1548_001C_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `true` | No |
| `T1548_001C_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1548_001C_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1548.001c_001C_results.json`: Execution results with metadata
- `t1548.001c_001C_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor
- `coreutils` - Basic file utilities

**Technique-Specific Dependencies:**
- `sudo` - Superuser privilege escalation

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash jq coreutils
```

#### CentOS/RHEL/Fedora
```bash
sudo dnf install -y \
     bash jq coreutils
```

#### Arch Linux
```bash
sudo pacman -S \
     bash jq coreutils
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```
