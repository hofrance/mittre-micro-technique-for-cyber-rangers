# T1039.004D - Extract Data from SFTP Shares

## Description
This package implements MITRE ATT&CK atomic micro-technique T1039.004D for Linux environments. Extract data from SFTP (SSH File Transfer Protocol) network shares and servers.

## Technique Details
- **ID**: T1039.004D
- **Name**: Extract Data from SFTP Shares
- **Parent Technique**: T1039
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1039_004D_OUTPUT_BASE="/tmp/mitre_results" && export T1039_004D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract data from SFTP shares ONLY
- Scope: One specific collection action
- Dependency: Bash + SFTP client tools
- Privilege: User

## Environment Variables
- `T1039_004D_FILE_PATTERNS`: File patterns to match (default: *.doc,*.pdf,*.txt,*.key,*.pem)
- `T1039_004D_INCLUDE_HIDDEN`: Include hidden files [true/false] (default: false)
- `T1039_004D_MAX_FILES`: Maximum number of files to process (default: 300)
- `T1039_004D_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1039_004D_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1039_004D_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1039_004D_SCAN_DEPTH`: Maximum scan depth (default: 3)
- `T1039_004D_SFTP_MOUNTS`: Configuration parameter (default: auto)
- `T1039_004D_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1039_004D_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1039_004d_sftp_shares_data.json`: Collection results with metadata

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

