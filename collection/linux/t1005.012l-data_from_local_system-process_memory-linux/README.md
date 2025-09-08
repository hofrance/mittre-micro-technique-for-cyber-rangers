# T1005.012L - Extract Process Memory Data

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.012L for Linux environments. Extract sensitive data from process memory spaces.

## Technique Details
- **ID**: T1005.012L
- **Name**: Extract Process Memory Data
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for other processes)

## Manual Execution
```bash
export T1005_012L_OUTPUT_BASE="/tmp/mitre_results" && export T1005_012L_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract process memory data ONLY
- Scope: One specific collection action
- Dependency: Bash + memory access tools
- Privilege: User/Admin

## Environment Variables
- `T1005_012L_DUMP_METHOD`: Configuration parameter (default: gcore)
- `T1005_012L_INCLUDE_THREADS`: Configuration parameter [true/false] (default: false)
- `T1005_012L_MAX_DUMP_SIZE`: Configuration parameter (default: 104857600)
- `T1005_012L_MAX_PROCESSES`: Configuration parameter (default: 10)
- `T1005_012L_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_012L_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_012L_PROCESS_PATTERNS`: Configuration parameter (default: ssh,gpg,browser,password)
- `T1005_012L_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_012L_TARGET_PROCESSES`: Configuration parameter (default: auto)
- `T1005_012L_TIMEOUT`: Timeout in seconds (default: 300)
- `T1005_012L_USER_MODE`: Configuration parameter (default: )

## Output Files
- `t1005_012l_process_memory.json`: Collection results with metadata

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
     bash bc find gcore gdb grep jq libc6-dbg
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc find gcore gdb glibc-debuginfo grep jq
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc find gcore gdb grep jq glibc-debug
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

