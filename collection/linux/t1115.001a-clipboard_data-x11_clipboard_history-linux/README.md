# T1115.001A - X11 Clipboard History Collection

## Description
This package implements MITRE ATT&CK atomic micro-technique T1115.001A for Linux environments. Collect clipboard history data from X11 clipboard managers.

## Technique Details
- **ID**: T1115.001A
- **Name**: X11 Clipboard History Collection
- **Parent Technique**: T1115
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (X11 access)

## Manual Execution
```bash
export T1115_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1115_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: collect X11 clipboard history ONLY
- Scope: One specific collection action
- Dependency: Bash + X11 + clipboard tools
- Privilege: User

## Environment Variables
- `T1115_001A_DISPLAY_TARGET`: Configuration parameter (default: :0)
- `T1115_001A_FILTER_SENSITIVE`: Configuration parameter [true/false] (default: true)
- `T1115_001A_MAX_ENTRIES`: Configuration parameter (default: 100)
- `T1115_001A_MIN_LENGTH`: Configuration parameter (default: 10)
- `T1115_001A_MONITOR_DURATION`: Configuration parameter (default: 300)
- `T1115_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1115_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1115_001A_POLL_INTERVAL`: Configuration parameter (default: 5)
- `T1115_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1115_001A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1115_001A_T1115_001A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1115_001A_T1115_001A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1115.001A Specific Variables
- `T1115_001A_X11_DISPLAY`: X11 display (default: ":0.0")
- `T1115_001A_CLIPBOARD_MANAGERS`: Clipboard managers (default: "parcellite,clipit,xclip")
- `T1115_001A_MAX_HISTORY_SIZE`: Maximum history size MB (default: 10)
- `T1115_001A_INCLUDE_IMAGES`: Include image clipboard [true/false] (default: false)
- `T1115_001A_T1115_001A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1115_001A_T1115_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1115_001a_x11_clipboard_history.json`: Clipboard collection results with metadata

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

