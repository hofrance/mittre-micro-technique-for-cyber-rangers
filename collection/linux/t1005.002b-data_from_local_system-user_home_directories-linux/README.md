# T1005.002B - Extract User Home Directories Data

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.002B for Linux environments. Extract data from user home directories for analysis.

## Technique Details
- **ID**: T1005.002B
- **Name**: Extract User Home Directories Data
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1005_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract user home directories data ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1005_002B_EXCLUDE_SYSTEM`: Exclude system files [true/false] (default: true)
- `T1005_002B_FILE_PATTERNS`: File patterns to match (default: .bashrc,.zshrc,.ssh/id_*,.gitconfig,.aws/credentials)
- `T1005_002B_HOME_PATHS`: Home directory paths (default: /home/*,/root)
- `T1005_002B_INCLUDE_HIDDEN`: Include hidden files [true/false] (default: true)
- `T1005_002B_MAX_FILES`: Maximum number of files to process (default: 1000)
- `T1005_002B_MAX_FILE_SIZE`: Maximum file size to process (default: 10485760)
- `T1005_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_002B_SCAN_DEPTH`: Maximum scan depth (default: 2)
- `T1005_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_002B_TARGET_USERS`: Target users (default: auto)
- `T1005_002B_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_002b_user_home_data.json`: Collection results with metadata

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

