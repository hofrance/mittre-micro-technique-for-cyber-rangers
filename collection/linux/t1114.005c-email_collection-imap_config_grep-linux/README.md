# T1114.005C - Extract IMAP Configuration via Grep Search

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.005C for Linux environments. Extract IMAP configuration data by searching through files with grep patterns.

## Technique Details
- **ID**: T1114.005C
- **Name**: Extract IMAP Configuration via Grep Search
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_005C_OUTPUT_BASE="/tmp/mitre_results" && export T1114_005C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: grep search for IMAP config data ONLY
- Scope: One specific search action
- Dependency: Bash + grep + filesystem access
- Privilege: User

## Environment Variables
- `T1114_005C_CASE_SENSITIVE`: Configuration parameter (default: false)
- `T1114_005C_FILE_EXTENSIONS`: File extensions to process (default: .conf,.cfg,.rc,.config)
- `T1114_005C_INCLUDE_CONTEXT`: Configuration parameter [true/false] (default: true)
- `T1114_005C_MAX_MATCHES`: Configuration parameter (default: 200)
- `T1114_005C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_005C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_005C_SEARCH_PATHS`: Configuration parameter (default: /home/*,/etc)
- `T1114_005C_SEARCH_PATTERNS`: Configuration parameter (default: imap,password,server,port,ssl)
- `T1114_005C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_005C_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_005C_T1114_005C_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_005C_T1114_005C_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.005C Specific Variables
- `T1114_005C_SEARCH_PATHS`: Paths to search (default: "$HOME/.config,$HOME/.thunderbird,$HOME/.mozilla-thunderbird")
- `T1114_005C_GREP_PATTERNS`: Grep patterns (default: "imap.*server,mail.*server,smtp.*server")
- `T1114_005C_MAX_FILE_SIZE`: Maximum file size bytes (default: 1048576)
- `T1114_005C_T1114_005C_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_005C_T1114_005C_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_005c_imap_grep_collection.json`: Grep search results with metadata

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

