# T1114.005B - Extract IMAP Configuration Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.005B for Linux environments. Extract IMAP configuration files from user directories and system locations.

## Technique Details
- **ID**: T1114.005B
- **Name**: Extract IMAP Configuration Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_005B_OUTPUT_BASE="/tmp/mitre_results" && export T1114_005B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract IMAP config files ONLY
- Scope: One specific extraction action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_005B_CONFIG_PATHS`: Configuration paths to scan (default: /home/*/.imaprc,/etc/imapd.conf)
- `T1114_005B_CONFIG_PATTERNS`: Configuration file patterns (default: *.imaprc,*.conf,*.cfg)
- `T1114_005B_MAX_FILES`: Maximum number of files to process (default: 50)
- `T1114_005B_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1114_005B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_005B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_005B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_005B_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_005B_T1114_005B_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_005B_T1114_005B_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.005B Specific Variables
- `T1114_005B_IMAP_CONFIG_PATHS`: Paths to search (default: "$HOME/.thunderbird,$HOME/.mozilla-thunderbird,$HOME/.config")
- `T1114_005B_CONFIG_PATTERNS`: File patterns (default: "*.cfg,*.conf,*.ini,prefs.js")
- `T1114_005B_MAX_FILE_SIZE`: Maximum file size bytes (default: 1048576)
- `T1114_005B_T1114_005B_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_005B_T1114_005B_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_005b_imap_config_collection.json`: Collection results with metadata

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

