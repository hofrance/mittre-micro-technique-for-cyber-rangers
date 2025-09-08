# T1005.006F - Extract Bash History Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.006F for Linux environments. Extract bash history files to analyze user command execution patterns.

## Technique Details
- **ID**: T1005.006F
- **Name**: Extract Bash History Files
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_006F_OUTPUT_BASE="/tmp/mitre_results" && export T1005_006F_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract bash history files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1005_006F_EXCLUDE_EMPTY`: Configuration parameter [true/false] (default: true)
- `T1005_006F_HISTORY_PATHS`: Configuration parameter (default: /home/*/.bash_history,/root/.bash_history)
- `T1005_006F_HISTORY_PATTERNS`: Configuration parameter (default: .bash_history,.zsh_history,.history)
- `T1005_006F_INCLUDE_FISH`: Configuration parameter [true/false] (default: false)
- `T1005_006F_INCLUDE_ZSH`: Configuration parameter [true/false] (default: true)
- `T1005_006F_MAX_FILES`: Maximum number of files to process (default: 50)
- `T1005_006F_MAX_FILE_SIZE`: Maximum file size to process (default: 10485760)
- `T1005_006F_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_006F_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_006F_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_006F_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_006f_bash_history.json`: Collection results with metadata

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

