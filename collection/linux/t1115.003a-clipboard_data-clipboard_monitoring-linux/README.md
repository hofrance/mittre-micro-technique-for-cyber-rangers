# T1115.003A - Clipboard Data Monitoring

## Description
This package implements MITRE ATT&CK atomic micro-technique T1115.003A for Linux environments. Monitor clipboard data changes in real-time to capture stored data (focus on data collection aspect).

## Technique Details
- **ID**: T1115.003A
- **Name**: Clipboard Data Monitoring
- **Parent Technique**: T1115 (Clipboard Data)
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (clipboard access)

## Manual Execution
```bash
export T1115_003A_OUTPUT_BASE="/tmp/mitre_results" && export T1115_003A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: monitor clipboard data changes ONLY
- Scope: Data collection focused on clipboard content
- Dependency: Bash + clipboard data monitoring tools
- Privilege: User
- **Specialization**: Focus on DATA COLLECTION aspects of clipboard

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1115_003A_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/home/user/clipboard` | `./mitre_results` | Yes |
| `T1115_003A_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1115_003A_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1115_003A_SILENT_MODE` | Enable silent execution | `true`, `false` | `false` | No |

### Monitoring Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1115_003A_MAX_ENTRIES` | Maximum number of clipboard entries to capture | `10`, `50`, `100`, `200`, `500` | `200` | No |
| `T1115_003A_MONITOR_DURATION` | Monitoring duration in seconds | `60`, `300`, `600`, `1800`, `3600` | `600` | No |
| `T1115_003A_POLL_INTERVAL` | Polling interval in seconds | `1`, `3`, `5`, `10` | `3` | No |
| `T1115_003A_MIN_LENGTH` | Minimum clipboard content length | `1`, `5`, `10`, `20` | `5` | No |
| `T1115_003A_DETECT_DISPLAY` | Display environment detection | `auto`, `x11`, `wayland` | `auto` | No |

### Content Filtering Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1115_003A_FILTER_PATTERNS` | Patterns to filter sensitive content | `password,key,token,secret` | `password,key,token,secret` | No |

### Examples

#### Basic Clipboard Monitoring
```bash
export T1115_003A_OUTPUT_BASE="/tmp/clipboard"
export T1115_003A_MAX_ENTRIES="100"
export T1115_003A_MONITOR_DURATION="300"
```

#### Stealth Mode with Short Polling
```bash
export T1115_003A_SILENT_MODE="true"
export T1115_003A_POLL_INTERVAL="1"
export T1115_003A_MONITOR_DURATION="1800"
```

#### Custom Filtering
```bash
export T1115_003A_FILTER_PATTERNS="password,api_key,token,secret,credit_card"
export T1115_003A_MIN_LENGTH="10"
export T1115_003A_MAX_ENTRIES="50"
```

## Output Files
- `t1115_003a_clipboard_monitoring.json`: Monitoring results with metadata

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
- `xclip` - X11 clipboard utility
- `xsel` - X11 selection utility (alternative)
- `wl-clipboard` - Wayland clipboard utilities

### Installation Commands

#### Alternative Tools (Built-in Fallbacks)
If the primary clipboard tools are not available, the package includes automatic fallbacks:
- **Simulation mode**: Works without any clipboard tools installed
- **Basic clipboard access**: Uses X11/Wayland display detection
- **Cross-platform detection**: Automatically adapts to environment

**Note**: The package will automatically use the best available method.

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc find grep jq wl-clipboard xclip xsel
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc find grep jq wl-clipboard xclip xsel
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc find grep jq wl-clipboard xclip xsel
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

