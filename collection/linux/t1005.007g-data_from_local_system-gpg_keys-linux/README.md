# T1005.007G - Extract GPG Keys

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.007G for Linux environments. Extract GPG (GNU Privacy Guard) keys from user directories for cryptographic analysis.

## Technique Details
- **ID**: T1005.007G
- **Name**: Extract GPG Keys
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_007G_OUTPUT_BASE="/tmp/mitre_results" && export T1005_007G_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract GPG keys ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1005_007G_GPG_PATHS`: Configuration parameter (default: /home/*/.gnupg,/root/.gnupg)
- `T1005_007G_INCLUDE_PRIVATE`: Configuration parameter [true/false] (default: true)
- `T1005_007G_INCLUDE_PUBLIC`: Configuration parameter [true/false] (default: true)
- `T1005_007G_INCLUDE_TRUSTDB`: Configuration parameter [true/false] (default: true)
- `T1005_007G_KEY_PATTERNS`: Configuration parameter (default: *.gpg,*.asc,pubring.*,secring.*,trustdb.gpg)
- `T1005_007G_MAX_FILES`: Maximum number of files to process (default: 50)
- `T1005_007G_MAX_FILE_SIZE`: Maximum file size to process (default: 10485760)
- `T1005_007G_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_007G_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_007G_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_007G_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_007g_gpg_keys.json`: Collection results with metadata

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
     bash bc coreutils find findutils grep jq
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc coreutils find findutils grep jq
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc coreutils find findutils grep jq
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

