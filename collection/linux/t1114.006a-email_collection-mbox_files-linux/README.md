# T1114.006A - Extract Mbox Email Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.006A for Linux environments. Extract Mbox format email files from various locations.

## Technique Details
- **ID**: T1114.006A
- **Name**: Extract Mbox Email Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_006A_OUTPUT_BASE="/tmp/mitre_results" && export T1114_006A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Mbox files ONLY
- Scope: One specific extraction action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_006A_INCLUDE_SYSTEM`: Configuration parameter [true/false] (default: false)
- `T1114_006A_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1114_006A_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_006A_MBOX_PATHS`: Configuration parameter (default: /home/*/Mail,/var/mail,/var/spool/mail)
- `T1114_006A_MBOX_PATTERNS`: Configuration parameter (default: *.mbox,mbox,inbox,sent)
- `T1114_006A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_006A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_006A_SCAN_DEPTH`: Maximum scan depth (default: 2)
- `T1114_006A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_006A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_006A_T1114_006A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_006A_T1114_006A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.006A Specific Variables
- `T1114_006A_MBOX_SEARCH_PATHS`: Search paths (default: "$HOME/Mail,$HOME/.mail,/var/mail")
- `T1114_006A_MBOX_PATTERNS`: Mbox patterns (default: "*.mbox,*.mail,mbox")
- `T1114_006A_MAX_MBOX_SIZE`: Maximum mbox size MB (default: 100)
- `T1114_006A_INCLUDE_SUBDIRS`: Include subdirectories [true/false] (default: true)
- `T1114_006A_T1114_006A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_006A_T1114_006A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_006a_mbox_files.json`: Mbox extraction results with metadata

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

