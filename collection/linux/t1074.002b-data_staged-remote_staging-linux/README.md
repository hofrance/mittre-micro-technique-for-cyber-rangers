# T1074.002B - Remote Data Staging

## Description
This package implements MITRE ATT&CK atomic micro-technique T1074.002B for Linux environments. Stage collected data on remote systems before exfiltration.

## Technique Details
- **ID**: T1074.002B
- **Name**: Remote Data Staging
- **Parent Technique**: T1074
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1074_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1074_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: stage data remotely ONLY
- Scope: One specific staging action
- Dependency: Bash + network tools
- Privilege: User

## Environment Variables
- `T1074_002B_COMPRESS_BEFORE`: Configuration parameter (default: false)
- `T1074_002B_LOCAL_MODE`: Configuration parameter (default: true)
- `T1074_002B_MAX_FILES`: Maximum number of files to process (default: 500)
- `T1074_002B_MAX_TOTAL_SIZE`: Configuration parameter (default: 1073741824)
- `T1074_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1074_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1074_002B_REMOTE_HOST`: Configuration parameter (default: )
- `T1074_002B_REMOTE_PATH`: Configuration parameter (default: /tmp/staging)
- `T1074_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1074_002B_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1074_002B_TIMEOUT`: Timeout in seconds (default: 300)
- `T1074_002B_TRANSFER_METHOD`: Configuration parameter (default: scp)

### Universal Variables
- `T1074_002B_T1074_002B_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1074_002B_T1074_002B_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1074.002B Specific Variables
- `T1074_002B_REMOTE_SERVERS`: Remote servers (default: "auto")
- `T1074_002B_STAGING_PROTOCOL`: Staging protocol (default: "scp")
- `T1074_002B_SOURCE_PATHS`: Source data paths (default: "$HOME")
- `T1074_002B_MAX_STAGING_SIZE`: Maximum staging size MB (default: 100)
- `T1074_002B_T1074_002B_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1074_002B_T1074_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1074_002b_remote_staging.json`: Staging results with metadata

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
     bash bc find gnupg grep gzip jq openssl tar
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc find gnupg2 grep gzip jq openssl tar
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc find gnupg grep gzip jq openssl tar
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

