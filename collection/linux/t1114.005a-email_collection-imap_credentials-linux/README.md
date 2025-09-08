# T1114.005A - Extract IMAP Credentials

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.005A for Linux environments. Extract IMAP authentication credentials from configuration files.

## Technique Details
- **ID**: T1114.005A
- **Name**: Extract IMAP Credentials
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_005A_OUTPUT_BASE="/tmp/mitre_results" && export T1114_005A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract IMAP credentials ONLY
- Scope: One specific extraction action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_005A_CONFIG_PATHS`: Configuration paths to scan (default: /home/*/.imaprc,/home/*/.fetchmailrc,/etc/fetchmailrc)
- `T1114_005A_CREDENTIAL_PATTERNS`: Configuration parameter (default: password,passwd,user,username,server,host)
- `T1114_005A_MASK_PASSWORDS`: Configuration parameter (default: false)
- `T1114_005A_MAX_FILES`: Maximum number of files to process (default: 50)
- `T1114_005A_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1114_005A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_005A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_005A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_005A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_005A_T1114_005A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_005A_T1114_005A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.005A Specific Variables
- `T1114_005A_IMAP_CREDENTIAL_PATHS`: Credential paths (default: "$HOME/.thunderbird,$HOME/.mozilla-thunderbird")
- `T1114_005A_CREDENTIAL_PATTERNS`: Credential patterns (default: "prefs.js,*.cfg,*.conf")
- `T1114_005A_MAX_FILE_SIZE`: Maximum file size MB (default: 10)
- `T1114_005A_INCLUDE_PASSWORDS`: Include passwords [true/false] (default: false)
- `T1114_005A_T1114_005A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_005A_T1114_005A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_005a_imap_credentials.json`: Credential extraction results with metadata

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

