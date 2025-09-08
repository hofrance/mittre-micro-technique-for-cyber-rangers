# T1114.003D - Extract muttrc Configuration Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.003D for Linux environments. Extract muttrc configuration files from user directories.

## Technique Details
- **ID**: T1114.003D
- **Name**: Extract muttrc Configuration Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_003D_OUTPUT_BASE="/tmp/mitre_results" && export T1114_003D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract muttrc configuration files ONLY

## Environment Variables
- `T1114_003D_CONFIG_PATTERNS`: Configuration file patterns (default: .muttrc,muttrc,*.mutt,*.rc)
- `T1114_003D_INCLUDE_SYSTEM`: Configuration parameter [true/false] (default: true)
- `T1114_003D_MAX_FILES`: Maximum number of files to process (default: 30)
- `T1114_003D_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1114_003D_MUTTRC_PATHS`: Configuration parameter (default: /home/*/.muttrc,/home/*/.mutt/muttrc,/etc/Muttrc)
- `T1114_003D_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_003D_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_003D_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_003D_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1114_003d_muttrc_collection.json`: Collection results with metadata

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

