# T1056.002B - Evdev Input Monitoring

## Description
This package implements MITRE ATT&CK atomic micro-technique T1056.002B for Linux environments. Monitor input events using the Linux evdev (event device) interface.

## Technique Details
- **ID**: T1056.002B
- **Name**: Evdev Input Monitoring
- **Parent Technique**: T1056
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for device access)

## Manual Execution
```bash
export T1056_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1056_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: monitor input via evdev ONLY
- Scope: One specific monitoring action
- Dependency: Bash + evdev access
- Privilege: User/Admin

## Environment Variables
- `T1056_002B_CAPTURE_DURATION`: Configuration parameter (default: 60)
- `T1056_002B_DEVICE_PATTERNS`: Configuration parameter (default: event*)
- `T1056_002B_FILTER_KEYBOARD`: Configuration parameter [true/false] (default: true)
- `T1056_002B_FILTER_MOUSE`: Configuration parameter [true/false] (default: false)
- `T1056_002B_MAX_EVENTS`: Configuration parameter (default: 5000)
- `T1056_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1056_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1056_002B_RAW_FORMAT`: Configuration parameter (default: false)
- `T1056_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1056_002B_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1056_002b_evdev_monitoring.json`: Input monitoring results with metadata

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
- `xinput` - X11 input device utility
- `xdotool` - X11 automation tool
- `evtest` - Input device event monitor
- `strace` - System call tracer

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc evtest find grep jq strace xdotool xinput
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc evtest find grep jq strace xdotool xorg-x11-server-utils
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc evtest find grep jq strace xdotool xinput
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```