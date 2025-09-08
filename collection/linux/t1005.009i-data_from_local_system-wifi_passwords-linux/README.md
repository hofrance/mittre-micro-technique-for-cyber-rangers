# T1005.009I - Extract WiFi Passwords

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.009I for Linux environments. Extract WiFi passwords from network configuration files and system storage.

## Technique Details
- **ID**: T1005.009I
- **Name**: Extract WiFi Passwords
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for system configs)

## Manual Execution
```bash
export T1005_009I_OUTPUT_BASE="/tmp/mitre_results" && export T1005_009I_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract WiFi passwords ONLY
- Scope: One specific collection action
- Dependency: Bash + network config access
- Privilege: User/Admin

## Environment Variables
- `T1005_009I_CONNECTION_PATTERNS`: Configuration parameter (default: *.nmconnection,*.conf)
- `T1005_009I_INCLUDE_WEP`: Configuration parameter [true/false] (default: true)
- `T1005_009I_INCLUDE_WPA`: Configuration parameter [true/false] (default: true)
- `T1005_009I_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1005_009I_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1005_009I_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_009I_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_009I_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_009I_TIMEOUT`: Timeout in seconds (default: 300)
- `T1005_009I_WIFI_PATHS`: Configuration parameter (default: /etc/NetworkManager/system-connections,/var/lib/NetworkManager)

## Output Files
- `t1005_009i_wifi_passwords.json`: Collection results with metadata

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