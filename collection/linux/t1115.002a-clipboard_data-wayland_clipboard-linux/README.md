# T1115.002A - Wayland Clipboard Data Collection

## Description
This package implements MITRE ATT&CK atomic micro-technique T1115.002A for Linux environments. Collect clipboard data from Wayland display server environments.

## Technique Details
- **ID**: T1115.002A
- **Name**: Wayland Clipboard Data Collection
- **Parent Technique**: T1115
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (Wayland access)

## Manual Execution
```bash
export T1115_002A_OUTPUT_BASE="/tmp/mitre_results" && export T1115_002A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: collect Wayland clipboard data ONLY
- Scope: One specific collection action
- Dependency: Bash + Wayland + clipboard tools
- Privilege: User

## Environment Variables
- `T1115_002A_FILTER_SENSITIVE`: Configuration parameter [true/false] (default: true)
- `T1115_002A_MAX_ENTRIES`: Configuration parameter (default: 100)
- `T1115_002A_MIN_LENGTH`: Configuration parameter (default: 10)
- `T1115_002A_MONITOR_DURATION`: Configuration parameter (default: 300)
- `T1115_002A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1115_002A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1115_002A_POLL_INTERVAL`: Configuration parameter (default: 5)
- `T1115_002A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1115_002A_TIMEOUT`: Timeout in seconds (default: 300)
- `T1115_002A_WAYLAND_DISPLAY`: Configuration parameter (default: wayland-0)

### Universal Variables
- `T1115_002A_T1115_002A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1115_002A_T1115_002A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1115.002A Specific Variables
- `T1115_002A_WAYLAND_DISPLAY`: Wayland display (default: "$WAYLAND_DISPLAY")
- `T1115_002A_CLIPBOARD_TYPES`: Clipboard types (default: "text,image")
- `T1115_002A_MONITOR_DURATION`: Monitor duration in seconds (default: 30)
- `T1115_002A_POLL_INTERVAL`: Poll interval in seconds (default: 2)
- `T1115_002A_T1115_002A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1115_002A_T1115_002A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1115_002a_wayland_clipboard.json`: Clipboard collection results with metadata

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

