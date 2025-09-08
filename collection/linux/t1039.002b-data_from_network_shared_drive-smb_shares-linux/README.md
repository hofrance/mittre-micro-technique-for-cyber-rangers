# T1039.002B - Extract Data from SMB Shares

## Description
This package implements MITRE ATT&CK atomic micro-technique T1039.002B for Linux environments. Extract data from SMB (Server Message Block) network shares.

## Technique Details
- **ID**: T1039.002B
- **Name**: Extract Data from SMB Shares
- **Parent Technique**: T1039
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1039_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1039_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract data from SMB shares ONLY
- Scope: One specific collection action
- Dependency: Bash + SMB client tools
- Privilege: User

## Environment Variables
- `T1039_002B_EXCLUDE_SYSTEM`: Exclude system files [true/false] (default: true)
- `T1039_002B_FILE_PATTERNS`: File patterns to match (default: *.doc,*.pdf,*.txt,*.xls,*.ppt,*.docx,*.xlsx)
- `T1039_002B_MAX_FILES`: Maximum number of files to process (default: 500)
- `T1039_002B_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1039_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1039_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1039_002B_SCAN_DEPTH`: Maximum scan depth (default: 3)
- `T1039_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1039_002B_SMB_MOUNTS`: Configuration parameter (default: auto)
- `T1039_002B_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1039_002b_smb_shares_data.json`: Collection results with metadata

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
- `cifs-utils` - SMB/CIFS filesystem utilities
- `smbclient` - SMB client utility
- `nmblookup` - NetBIOS name lookup utility

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc cifs-utils find grep jq nmblookup smbclient
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc cifs-utils find grep jq nmblookup smbclient
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc cifs-utils find grep jq nmblookup smbclient
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

