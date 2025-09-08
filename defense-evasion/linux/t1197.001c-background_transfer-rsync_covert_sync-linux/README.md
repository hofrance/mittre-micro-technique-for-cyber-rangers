# T1197.001C - linux

## Description
This package implements MITRE ATT&CK atomic micro-technique T1197.001C for Linux environments. Perform covert file synchronization using rsync ONLY.

## Technique Details
- **ID**: T1197.001C
- **Name**: Perform covert file synchronization using rsync ONLY
- **Parent Technique**: T1197
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Linux
- **Permissions Required**: User

## Manual Execution
```bash
export T1197_001C_OUTPUT_BASE="/tmp/mitre_results"
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: Perform covert file synchronization using rsync ONLY ONLY
- Scope: One specific action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1197_001C_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/var/log/mitre`, `/home/user/results` | `/tmp/mitre_results` | Yes |
| `T1197_001C_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1197_001C_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1197_001C_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1197_001C_VERBOSE_LEVEL` | Verbosity level (0-3) | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |

### Security Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1197_001C_SIMULATION_MODE` | Enable simulation mode | `true`, `false` | `true` | No |
| `T1197_001C_SAFETY_CHECKS` | Enable safety checks | `true`, `false` | `true` | No |
| `T1197_001C_REQUIRE_CONFIRMATION` | Require user confirmation | `true`, `false` | `true` | No |
| `T1197_001C_STEALTH_MODE` | Enable stealth mode | `true`, `false` | `false` | No |
| `T1197_001C_POLICY_CHECK` | Enable policy compliance checking | `true`, `false` | `true` | No |

## Output Files
- `t1197.001c_001C_results.json`: Execution results with metadata
- `t1197.001c_001C_security_audit.log`: Security audit log

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor
- `coreutils` - Basic file utilities

**Technique-Specific Dependencies:**
- System-specific tools as needed

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
