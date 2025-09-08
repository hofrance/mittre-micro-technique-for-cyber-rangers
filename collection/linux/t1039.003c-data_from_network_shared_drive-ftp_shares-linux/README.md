# T1039.003C - Extract Data from FTP Shares

## Description
This package implements MITRE ATT&CK atomic micro-technique T1039.003C for Linux environments. Extract data from FTP (File Transfer Protocol) network shares and servers.

## Technique Details
- **ID**: T1039.003C
- **Name**: Extract Data from FTP Shares
- **Parent Technique**: T1039
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1039_003C_OUTPUT_BASE="/tmp/mitre_results" && export T1039_003C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract data from FTP shares ONLY
- Scope: One specific collection action
- Dependency: Bash + FTP client tools
- Privilege: User

## Environment Variables
- `T1039_003C_FILE_PATTERNS`: File patterns to match (default: *.doc,*.pdf,*.txt,*.xls,*.csv)
- `T1039_003C_FTP_MOUNTS`: Configuration parameter (default: auto)
- `T1039_003C_INCLUDE_BINARY`: Configuration parameter [true/false] (default: false)
- `T1039_003C_MAX_FILES`: Maximum number of files to process (default: 300)
- `T1039_003C_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1039_003C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1039_003C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1039_003C_SCAN_DEPTH`: Maximum scan depth (default: 3)
- `T1039_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1039_003C_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1039_003c_ftp_shares_data.json`: Collection results with metadata

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
- `coreutils` - Basic file, shell and text utilities
- `findutils` - File search utilities

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc find ftp grep jq lftp ncftp
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc find ftp grep jq lftp ncftp
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc find ftp grep jq lftp ncftp
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

