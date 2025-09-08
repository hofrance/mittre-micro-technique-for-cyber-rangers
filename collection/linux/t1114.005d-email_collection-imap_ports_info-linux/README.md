# T1114.005D - Extract IMAP Ports Information

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.005D for Linux environments. Extract information about IMAP ports and network configurations from system and user files.

## Technique Details
- **ID**: T1114.005D
- **Name**: Extract IMAP Ports Information
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_005D_OUTPUT_BASE="/tmp/mitre_results" && export T1114_005D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract IMAP ports information ONLY
- Scope: One specific information gathering action
- Dependency: Bash + network tools + filesystem access
- Privilege: User

## Environment Variables
- `T1114_005D_IMAP_PORTS`: Configuration parameter (default: 143,993,110,995)
- `T1114_005D_INCLUDE_PROCESSES`: Configuration parameter [true/false] (default: true)
- `T1114_005D_MAX_ENTRIES`: Configuration parameter (default: 100)
- `T1114_005D_NETWORK_RANGE`: Configuration parameter (default: 192.168.1.0/24)
- `T1114_005D_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_005D_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_005D_SCAN_LOCALHOST`: Configuration parameter (default: true)
- `T1114_005D_SCAN_NETWORK`: Configuration parameter (default: false)
- `T1114_005D_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_005D_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_005D_T1114_005D_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_005D_T1114_005D_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.005D Specific Variables
- `T1114_005D_SEARCH_PATHS`: Paths to search (default: "$HOME/.config,$HOME/.thunderbird,/etc/services")
- `T1114_005D_PORT_PATTERNS`: Port patterns (default: "143,993,585,4190")
- `T1114_005D_INCLUDE_NETSTAT`: Include netstat info [true/false] (default: true)
- `T1114_005D_T1114_005D_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_005D_T1114_005D_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_005d_imap_ports_info.json`: IMAP ports information with metadata

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
- `thunderbird` - Mozilla email client (optional)
- `evolution` - GNOME email client (optional) 
- `mutt` - Terminal-based email client (optional)
- `postfix` - Mail server (optional)

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc evolution find grep jq mutt postfix thunderbird
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc evolution find grep jq mutt postfix thunderbird
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc evolution find grep jq mutt postfix thunderbird
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

