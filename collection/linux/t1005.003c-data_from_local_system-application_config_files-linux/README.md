# T1005.003C - Extract Application Configuration Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.003C for Linux environments. Extract application configuration files from the local system.

## Technique Details
- **ID**: T1005.003C
- **Name**: Extract Application Configuration Files
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_003C_OUTPUT_BASE="/tmp/mitre_results" && export T1005_003C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract application config files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1005_003C_APP_PATTERNS`: Application patterns (default: */config,*/settings,*/*.conf,*/*.cfg)
- `T1005_003C_CONFIG_DIRS`: Configuration directories (default: /home/*/.config,/root/.config)
- `T1005_003C_EXCLUDE_CACHE`: Exclude cache files [true/false] (default: true)
- `T1005_003C_EXCLUDE_SYSTEM`: Exclude system files [true/false] (default: true)
- `T1005_003C_FILE_EXTENSIONS`: File extensions to process (default: .conf,.cfg,.ini,.json,.xml,.yaml)
- `T1005_003C_MAX_FILES`: Maximum number of files to process (default: 200)
- `T1005_003C_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1005_003C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_003C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_003C_SCAN_DEPTH`: Maximum scan depth (default: 3)
- `T1005_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_003C_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_003c_app_config_files.json`: Collection results with metadata

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

