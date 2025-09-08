# T1119.001A - Automated Process Memory Dumps

## Description
This package implements MITRE ATT&CK atomic micro-technique T1119.001A for Linux environments. Automated collection of process memory dumps for analysis.

## Technique Details
- **ID**: T1119.001A
- **Name**: Automated Process Memory Dumps
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for some processes)

## Manual Execution
```bash
export T1119_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1119_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: collect process memory dumps automatically ONLY
- Scope: One specific collection action
- Dependency: Bash + memory dump tools
- Privilege: User/Admin

## Environment Variables
- `T1119_001A_DUMP_METHOD`: Configuration parameter (default: gcore)
- `T1119_001A_MAX_DUMPS`: Configuration parameter (default: 5)
- `T1119_001A_MAX_DUMP_SIZE`: Configuration parameter (default: 1073741824)
- `T1119_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1119_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1119_001A_PROCESS_PATTERNS`: Configuration parameter (default: ssh,gpg,browser,password)
- `T1119_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1119_001A_TARGET_PROCESSES`: Configuration parameter (default: auto)
- `T1119_001A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1119_001A_T1119_001A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1119_001A_T1119_001A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1119.001A Specific Variables
- `T1119_001A_TARGET_PROCESSES`: Target processes (default: "auto")
- `T1119_001A_DUMP_METHOD`: Memory dump method (default: "gcore")
- `T1119_001A_MAX_DUMP_SIZE`: Maximum dump size MB (default: 500)
- `T1119_001A_INCLUDE_THREADS`: Include thread dumps [true/false] (default: true)
- `T1119_001A_T1119_001A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1119_001A_T1119_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1119_001a_process_memory_dumps.json`: Memory dump results with metadata

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

