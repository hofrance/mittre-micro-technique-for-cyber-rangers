# T1119.006A - User Account Enumeration

## Description
This package implements MITRE ATT&CK atomic micro-technique T1119.006A for Linux environments. Automated enumeration of user accounts and groups.

## Technique Details
- **ID**: T1119.006A
- **Name**: User Account Enumeration
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1119_006A_OUTPUT_BASE="/tmp/mitre_results" && chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: enumerate user accounts ONLY

## Environment Variables
- `T1119_006A_INCLUDE_GROUPS`: Include group information [true/false] (default: true)
- `T1119_006A_INCLUDE_SUDO`: Include sudo users [true/false] (default: true)
- `T1119_006A_INCLUDE_SYSTEM_USERS`: Include system users [true/false] (default: false)
- `T1119_006A_MAX_USERS`: Maximum number of users to enumerate (default: 1000)
- `T1119_006A_MIN_UID`: Minimum UID to consider (default: 1000)
- `T1119_006A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1119_006A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1119_006A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1119_006A_TIMEOUT`: Timeout in seconds (default: 300)
- `T1119_006A_USER_SOURCES`: User information sources (default: /etc/passwd,/etc/shadow,/etc/group)

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

