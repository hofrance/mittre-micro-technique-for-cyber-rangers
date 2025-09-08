# T1114.003A - Extract Mutt Configuration

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.003A for Linux environments. Extract Mutt email client configuration files and settings.

## Technique Details
- **ID**: T1114.003A
- **Name**: Extract Mutt Configuration
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_003A_OUTPUT_BASE="/tmp/mitre_results" && chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Mutt configuration ONLY

## Environment Variables
- `T1114_003A_CONFIG_PATTERNS`: Configuration file patterns (default: .muttrc,muttrc,*.mutt)
- `T1114_003A_INCLUDE_ALIASES`: Configuration parameter [true/false] (default: true)
- `T1114_003A_INCLUDE_SIGNATURES`: Configuration parameter [true/false] (default: true)
- `T1114_003A_MAX_FILES`: Maximum number of files to process (default: 50)
- `T1114_003A_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1114_003A_MUTT_PATHS`: Configuration parameter (default: /home/*/.mutt,/home/*/.muttrc,/etc/Muttrc)
- `T1114_003A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_003A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_003A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_003A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_003A_T1114_003A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")

### T1114.003A Specific Variables
- `T1114_003A_INCLUDE_MAILBOXES`: Include mailboxes [true/false] (default: true)
- `T1114_003A_PARSE_CONFIGS`: Parse configuration files (default: true)
- `T1114_003A_EXTRACT_ALIASES`: Extract email aliases (default: true)
- `T1114_003A_FIND_CERTIFICATES`: Find certificates (default: true)
- `T1114_003A_T1114_003A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

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

