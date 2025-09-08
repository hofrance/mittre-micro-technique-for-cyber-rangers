# T1056.006F - GUI Application Input Capture

## Description
This package implements MITRE ATT&CK atomic micro-technique T1056.006F for Linux environments. Capture input from GUI applications through various monitoring techniques.

## Technique Details
- **ID**: T1056.006F
- **Name**: GUI Application Input Capture
- **Parent Technique**: T1056
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (GUI access)

## Manual Execution
```bash
export T1056_006F_OUTPUT_BASE="/tmp/mitre_results" && export T1056_006F_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: capture GUI application input ONLY
- Scope: One specific capture action
- Dependency: Bash + GUI monitoring tools
- Privilege: User

## Environment Variables
- `T1056_006F_CAPTURE_DURATION`: Configuration parameter (default: 120)
- `T1056_006F_DISPLAY_TARGET`: Configuration parameter (default: :0)
- `T1056_006F_EVENT_TYPES`: Configuration parameter (default: KeyPress,KeyRelease,ButtonPress)
- `T1056_006F_FILTER_APPS`: Configuration parameter (default: browser,editor,terminal)
- `T1056_006F_MAX_EVENTS`: Configuration parameter (default: 2000)
- `T1056_006F_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1056_006F_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1056_006F_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1056_006F_TARGET_WINDOWS`: Configuration parameter (default: auto)
- `T1056_006F_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1056_006F_T1056_006F_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1056_006F_T1056_006F_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1056.006F Specific Variables
- `T1056_006F_CAPTURE_DURATION`: Capture duration in seconds (default: 60)
- `T1056_006F_TARGET_APPS`: Target applications (default: "auto")
- `T1056_006F_MONITOR_METHOD`: Monitor method (default: "xinput")
- `T1056_006F_INCLUDE_WINDOW_TITLES`: Include window titles [true/false] (default: true)
- `T1056_006F_T1056_006F_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1056_006F_T1056_006F_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1056_006f_gui_input_capture.json`: Capture results with metadata

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


## Performance Optimizations

### Adaptive Timeout Mode
This package includes intelligent timeout management:
- **Test Mode Detection**: Automatically detects testing environments
- **Quick Execution**: Reduces capture duration during automated tests
- **Timeout Prevention**: Avoids timeouts in CI/CD environments

### Environment Variables for Optimization
- `T[ID]_TIMEOUT`: When set low (<30s), enables quick mode
- `QUICK_MODE`: Automatically set to "true" in test environments
- `MAX_CAPTURE_TIME`: Adapts to available time budget

### Usage in Different Contexts
```bash
# Production mode (full capture)
export T[ID]_TIMEOUT=300
./src/main.sh

# Test mode (quick execution) 
export T[ID]_TIMEOUT=10
./src/main.sh  # Automatically uses quick mode
```

**Note**: The package automatically adapts its behavior based on the timeout value to prevent test failures while maintaining full functionality in production environments.

