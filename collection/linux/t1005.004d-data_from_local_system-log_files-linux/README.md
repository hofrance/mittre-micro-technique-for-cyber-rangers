# T1005.004D - Extract System Log Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.004D for Linux environments. Extract system log files for analysis and reconnaissance.

## Technique Details
- **ID**: T1005.004D
- **Name**: Extract System Log Files
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for system logs)

## Manual Execution
```bash
export T1005_004D_OUTPUT_BASE="/tmp/mitre_results" && export T1005_004D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract system log files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User/Admin

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1005_004D_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/var/log/mitre`, `/home/user/results` | `./mitre_results` | Yes |
| `T1005_004D_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1005_004D_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1005_004D_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1005_004D_SILENT_MODE` | Enable silent execution | `true`, `false` | `false` | No |

### Collection Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1005_004D_LOG_PATHS` | Paths to scan for log files | `/var/log`, `/var/log,/home/*/logs`, `/var/log,/tmp/logs` | `/var/log` | No |
| `T1005_004D_LOG_PATTERNS` | File patterns to match | `*.log`, `*.log,*.log.*`, `*.log,*.log.*,messages,syslog` | `*.log,*.log.*,messages,syslog` | No |
| `T1005_004D_MAX_FILES` | Maximum number of files to process | `10`, `50`, `100`, `500`, `1000` | `500` | No |
| `T1005_004D_MAX_FILE_SIZE` | Maximum file size in bytes | `1048576` (1MB), `5242880` (5MB), `52428800` (50MB), `104857600` (100MB) | `52428800` | No |
| `T1005_004D_SCAN_DEPTH` | Maximum directory depth to scan | `1`, `2`, `3`, `5` | `2` | No |

### Filtering Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1005_004D_INCLUDE_COMPRESSED` | Include compressed log files | `true`, `false` | `false` | No |
| `T1005_004D_EXCLUDE_SYSTEM` | Exclude system-generated files | `true`, `false` | `false` | No |

### Examples

#### Basic Log Collection
```bash
export T1005_004D_OUTPUT_BASE="/tmp/logs"
export T1005_004D_MAX_FILES="100"
export T1005_004D_LOG_PATHS="/var/log,/home/user/logs"
```

#### Debug Mode with Verbose Output
```bash
export T1005_004D_DEBUG_MODE="true"
export T1005_004D_VERBOSE_LEVEL="3"
export T1005_004D_OUTPUT_MODE="debug"
```

#### Custom Log Patterns
```bash
export T1005_004D_LOG_PATTERNS="*.log,*.out,*.err"
export T1005_004D_SCAN_DEPTH="3"
export T1005_004D_INCLUDE_COMPRESSED="true"
```

## Output Files
- `t1005_004d_system_log_files.json`: Collection results with metadata

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor
- `bc` - Calculator utility
- `grep` - Text search utility
- `find` - File search utility

**Technique-Specific Dependencies:**
- `coreutils` - Basic file, shell and text utilities
- `findutils` - File search utilities

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc coreutils find findutils grep jq
```

#### CentOS/RHEL/Fedora
```bash
sudo dnf install -y \
     bash bc coreutils find findutils grep jq
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc coreutils find findutils grep jq
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```
