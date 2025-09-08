# T1114.004A - Extract Postfix Mail Server Logs

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.004A for Linux environments. Extract Postfix mail server logs for email analysis.

## Technique Details
- **ID**: T1114.004A
- **Name**: Extract Postfix Mail Server Logs
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for system logs)

## Manual Execution
```bash
export T1114_004A_OUTPUT_BASE="/tmp/mitre_results" && export T1114_004A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Postfix logs ONLY
- Scope: One specific extraction action
- Dependency: Bash + log access
- Privilege: User/Admin

## Environment Variables
- `T1114_004A_DATE_FILTER`: Configuration parameter (default: 7days)
- `T1114_004A_INCLUDE_ROTATED`: Configuration parameter [true/false] (default: true)
- `T1114_004A_LOG_PATTERNS`: Configuration parameter (default: mail.log*,postfix.log*,maillog*)
- `T1114_004A_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1114_004A_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_004A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_004A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_004A_POSTFIX_LOG_PATHS`: Configuration parameter (default: /var/log/mail.log,/var/log/postfix.log,/var/log/maillog)
- `T1114_004A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_004A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_004A_T1114_004A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_004A_T1114_004A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.004A Specific Variables
- `T1114_004A_POSTFIX_LOG_PATHS`: Log paths (default: "/var/log/mail.log,/var/log/maillog")
- `T1114_004A_MAX_LOG_SIZE`: Maximum log size MB (default: 100)
- `T1114_004A_INCLUDE_ROTATED`: Include rotated logs [true/false] (default: true)
- `T1114_004A_LOG_PATTERNS`: Log patterns (default: "*.log,*.log.*")
- `T1114_004A_T1114_004A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_004A_T1114_004A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_004a_postfix_logs.json`: Log extraction results with metadata

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

