# T1056.004D - SSH Session Input Capture

## Description
This package implements MITRE ATT&CK atomic micro-technique T1056.004D for Linux environments. Capture input from SSH sessions for remote monitoring.

## Technique Details
- **ID**: T1056.004D
- **Name**: SSH Session Input Capture
- **Parent Technique**: T1056
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1056_004D_OUTPUT_BASE="/tmp/mitre_results" && export T1056_004D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: capture SSH session input ONLY
- Scope: One specific capture action
- Dependency: Bash + SSH access + monitoring tools
- Privilege: User

## Environment Variables
- `T1056_004D_CAPTURE_DURATION`: Configuration parameter (default: 300)
- `T1056_004D_CAPTURE_METHOD`: Configuration parameter (default: strace)
- `T1056_004D_INCLUDE_INBOUND`: Configuration parameter [true/false] (default: true)
- `T1056_004D_INCLUDE_OUTBOUND`: Configuration parameter [true/false] (default: true)
- `T1056_004D_MAX_SESSIONS`: Configuration parameter (default: 10)
- `T1056_004D_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1056_004D_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1056_004D_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1056_004D_SSH_PROCESSES`: Configuration parameter (default: auto)
- `T1056_004D_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1056_004D_T1056_004D_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1056_004D_T1056_004D_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1056.004D Specific Variables
- `T1056_004D_SSH_SESSIONS`: SSH sessions to monitor (default: "auto")
- `T1056_004D_CAPTURE_DURATION`: Capture duration in seconds (default: 60)
- `T1056_004D_MONITOR_METHOD`: Monitor method (default: "script")
- `T1056_004D_INCLUDE_OUTPUT`: Include command output [true/false] (default: true)
- `T1056_004D_T1056_004D_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1056_004D_T1056_004D_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1056_004d_ssh_session_capture.json`: Capture results with metadata

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

