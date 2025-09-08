# T1005.010J - Extract Browser Data

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.010J for Linux environments. Extract browser data including history, cookies, and stored credentials.

## Technique Details
- **ID**: T1005.010J
- **Name**: Extract Browser Data
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_010J_OUTPUT_BASE="/tmp/mitre_results" && export T1005_010J_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract browser data ONLY
- Scope: One specific collection action
- Dependency: Bash + browser profile access
- Privilege: User

## Environment Variables
- `T1005_010J_BROWSER_PATHS`: Configuration parameter (default: /home/*/.mozilla,/home/*/.config/google-chrome,/home/*/.config/chromium)
- `T1005_010J_DATA_TYPES`: Configuration parameter (default: cookies,passwords,bookmarks,history)
- `T1005_010J_INCLUDE_EXTENSIONS`: Configuration parameter [true/false] (default: false)
- `T1005_010J_INCLUDE_PROFILES`: Configuration parameter [true/false] (default: true)
- `T1005_010J_MAX_FILES`: Maximum number of files to process (default: 200)
- `T1005_010J_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1005_010J_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_010J_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_010J_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_010J_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_010j_browser_data.json`: Collection results with metadata

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