# T1114.004C - Extract Postfix Mail Server Logs

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.004C for Linux environments. Extract and collect Postfix mail server log files for offline analysis.

## Technique Details
- **ID**: T1114.004C
- **Name**: Extract Postfix Mail Server Logs
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (may require elevated for system logs)

## Manual Execution
```bash
export T1114_004C_OUTPUT_BASE="/tmp/mitre_results" && export T1114_004C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Postfix log files ONLY
- Scope: One specific extraction action
- Dependency: Bash + log access
- Privilege: User/Admin

## Environment Variables
- `T1114_004C_EXTRACT_PATTERNS`: Configuration parameter (default: from=<.*>,to=<.*>,subject=.*)
- `T1114_004C_FILTER_EXTERNAL`: Configuration parameter [true/false] (default: true)
- `T1114_004C_INCLUDE_TIMESTAMPS`: Configuration parameter [true/false] (default: true)
- `T1114_004C_LOG_PATHS`: Configuration parameter (default: /var/log/mail.log,/var/log/postfix.log)
- `T1114_004C_MAX_EXTRACTS`: Configuration parameter (default: 500)
- `T1114_004C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_004C_OUTPUT_FORMAT`: Configuration parameter (default: csv)
- `T1114_004C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_004C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_004C_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_004C_T1114_004C_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_004C_T1114_004C_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.004C Specific Variables
- `T1114_004C_POSTFIX_LOG_PATHS`: Log file paths (default: "/var/log/mail.log,/var/log/maillog")
- `T1114_004C_MAX_LOG_SIZE`: Maximum log file size MB (default: 100)
- `T1114_004C_INCLUDE_ROTATED`: Include rotated logs [true/false] (default: true)
- `T1114_004C_T1114_004C_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_004C_T1114_004C_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_004c_postfix_logs_extraction.json`: Extraction results with metadata

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

