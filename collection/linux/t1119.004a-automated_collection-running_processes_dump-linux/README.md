# T1119.004A - Running Processes Dump

## Description
This package implements MITRE ATT&CK atomic micro-technique T1119.004A for Linux environments. Automated collection of running processes information.

## Technique Details
- **ID**: T1119.004A
- **Name**: Running Processes Dump
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1119_004A_OUTPUT_BASE="/tmp/mitre_results" && chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: dump running processes info ONLY

## Environment Variables
- `T1119_004A_INCLUDE_CMDLINE`: Configuration parameter [true/false] (default: true)
- `T1119_004A_INCLUDE_ENVIRONMENT`: Configuration parameter [true/false] (default: false)
- `T1119_004A_INCLUDE_THREADS`: Configuration parameter [true/false] (default: false)
- `T1119_004A_MAX_PROCESSES`: Configuration parameter (default: 500)
- `T1119_004A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1119_004A_OUTPUT_FORMAT`: Configuration parameter (default: text)
- `T1119_004A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1119_004A_PROCESS_FILTERS`: Configuration parameter (default: all)
- `T1119_004A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1119_004A_TIMEOUT`: Timeout in seconds (default: 300)

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

