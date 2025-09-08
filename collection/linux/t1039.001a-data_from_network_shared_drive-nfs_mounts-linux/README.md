# T1039.001A - Extract Data from NFS Mounts

## Description
This package implements MITRE ATT&CK atomic micro-technique T1039.001A for Linux environments. Extract data from Network File System (NFS) mounted drives.

## Technique Details
- **ID**: T1039.001A
- **Name**: Extract Data from NFS Mounts
- **Parent Technique**: T1039
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1039_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1039_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract data from NFS mounts ONLY
- Scope: One specific collection action
- Dependency: Bash + NFS access
- Privilege: User

## Environment Variables
- `T1039_001A_EXCLUDE_SYSTEM`: Exclude system files [true/false] (default: true)
- `T1039_001A_FILE_PATTERNS`: File patterns to match (default: *.doc,*.pdf,*.txt,*.xls,*.ppt)
- `T1039_001A_MAX_FILES`: Maximum number of files to process (default: 500)
- `T1039_001A_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1039_001A_NFS_MOUNTS`: Configuration parameter (default: auto)
- `T1039_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1039_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1039_001A_SCAN_DEPTH`: Maximum scan depth (default: 3)
- `T1039_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1039_001A_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1039_001a_nfs_data_collection.json`: Collection results with metadata

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
- `nfs-common` - NFS client utilities
- `mount.nfs` - NFS mount helper

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc find grep jq nfs-common
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc find grep jq nfs-utils
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc find grep jq nfs-common
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

