# T1005.011K - Extract Environment Variables

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.011K for Linux environments. Extract environment variables that may contain sensitive information or configuration details.

## Technique Details
- **ID**: T1005.011K
- **Name**: Extract Environment Variables
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_011K_OUTPUT_BASE="/tmp/mitre_results" && export T1005_011K_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract environment variables ONLY
- Scope: One specific collection action
- Dependency: Bash + process access
- Privilege: User

## Environment Variables
- `T1005_011K_EXCLUDE_COMMON`: Configuration parameter [true/false] (default: true)
- `T1005_011K_FILTER_PATTERNS`: Configuration parameter (default: *PASSWORD*,*SECRET*,*TOKEN*,*KEY*,*API*)
- `T1005_011K_INCLUDE_SYSTEM`: Configuration parameter [true/false] (default: false)
- `T1005_011K_MAX_PROCESSES`: Configuration parameter (default: 100)
- `T1005_011K_MIN_LENGTH`: Configuration parameter (default: 5)
- `T1005_011K_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_011K_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_011K_PROC_PATHS`: Configuration parameter (default: /proc/*/environ)
- `T1005_011K_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_011K_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_011k_environment_variables.json`: Collection results with metadata

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

