# T1119.002A - Automated System Information Gathering

## Description
This package implements MITRE ATT&CK atomic micro-technique T1119.002A for Linux environments. Automated collection of system information for reconnaissance.

## Technique Details
- **ID**: T1119.002A
- **Name**: Automated System Information Gathering
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1119_002A_OUTPUT_BASE="/tmp/mitre_results" && export T1119_002A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: gather system information automatically ONLY
- Scope: One specific collection action
- Dependency: Bash + system utilities
- Privilege: User

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1119_002A_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/home/user/system_info` | `./mitre_results` | Yes |
| `T1119_002A_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1119_002A_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1119_002A_SILENT_MODE` | Enable silent execution | `true`, `false` | `false` | No |

### Collection Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1119_002A_MAX_INFO_FILES` | Maximum number of info files to collect | `10`, `25`, `50`, `100` | `50` | No |
| `T1119_002A_INFO_CATEGORIES` | Information categories to collect | `system`, `network`, `processes`, `users`, `hardware` | `system,network,processes,users,hardware` | No |

### Content Filtering Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1119_002A_INCLUDE_HARDWARE` | Include hardware information | `true`, `false` | `true` | No |
| `T1119_002A_INCLUDE_NETWORK` | Include network information | `true`, `false` | `true` | No |

### Examples

#### Basic System Information Gathering
```bash
export T1119_002A_OUTPUT_BASE="/tmp/system_info"
export T1119_002A_MAX_INFO_FILES="25"
export T1119_002A_INFO_CATEGORIES="system,hardware"
```

#### Network-Focused Collection
```bash
export T1119_002A_OUTPUT_BASE="/tmp/network_info"
export T1119_002A_INFO_CATEGORIES="network"
export T1119_002A_INCLUDE_NETWORK="true"
export T1119_002A_INCLUDE_HARDWARE="false"
```

#### Stealth Mode Collection
```bash
export T1119_002A_SILENT_MODE="true"
export T1119_002A_MAX_INFO_FILES="10"
export T1119_002A_TIMEOUT="120"
```


## Output Files
- `t1119_002a_system_information.json`: System info collection results with metadata

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

