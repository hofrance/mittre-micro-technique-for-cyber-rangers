# T1114.003C - Extract Mutt Spool Mail Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.003C for Linux environments. Extract Mutt/UNIX spool mail files for the current user.

## Technique Details
- **ID**: T1114.003C
- **Name**: Extract Mutt Spool Mail Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_003C_OUTPUT_BASE="/tmp/mitre_results" && export T1114_003C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract spool mail files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_003C_INCLUDE_SYSTEM`: Configuration parameter [true/false] (default: false)
- `T1114_003C_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1114_003C_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_003C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_003C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_003C_SPOOL_PATHS`: Configuration parameter (default: /var/spool/mail,/var/mail)
- `T1114_003C_TIMEOUT`: Timeout in seconds (default: 300)
- `T1114_003C_USER_SPOOLS`: Configuration parameter (default: auto)

### Universal Variables
- `T1114_003C_T1114_003C_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_003C_T1114_003C_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.003C Specific Variables
- `T1114_003C_SPOOL_PATHS`: Spool paths to check (default: "/var/spool/mail/$(whoami),/var/mail/$(whoami),$HOME/Mail")
- `T1114_003C_MAX_SPOOL_SIZE`: Maximum file size bytes (default: 5242880)
- `T1114_003C_T1114_003C_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_003C_STEALTH_MODE`: Enable stealth operation (default: false)
- `T1114_003C_T1114_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_003c_mutt_spool_collection.json`: Collection results with metadata

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

