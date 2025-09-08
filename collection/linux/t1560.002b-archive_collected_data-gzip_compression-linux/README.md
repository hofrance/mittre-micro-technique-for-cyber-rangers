# T1560.002B - GZIP Archive Collected Data

## Description
This package implements MITRE ATT&CK atomic micro-technique T1560.002B for Linux environments. Archive collected data using GZIP compression for storage or exfiltration.

## Technique Details
- **ID**: T1560.002B
- **Name**: GZIP Archive Collected Data
- **Parent Technique**: T1560
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1560_002B_OUTPUT_BASE="/tmp/mitre_results" && export T1560_002B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: archive data with GZIP compression ONLY
- Scope: One specific archiving action
- Dependency: Bash + gzip utility
- Privilege: User

## Environment Variables
- `T1560_002B_COMPRESSION_LEVEL`: Configuration parameter (default: 6)
- `T1560_002B_FILE_PATTERNS`: File patterns to match (default: *)
- `T1560_002B_MAX_FILES`: Maximum number of files to process (default: 1000)
- `T1560_002B_MIN_FILE_SIZE`: Configuration parameter (default: 1024)
- `T1560_002B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1560_002B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1560_002B_PRESERVE_ORIGINAL`: Configuration parameter (default: false)
- `T1560_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1560_002B_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1560_002B_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1560_002B_T1560_002B_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1560_002B_T1560_002B_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1560.002B Specific Variables
- `T1560_002B_SOURCE_PATHS`: Source paths to archive (default: "$HOME/Documents")
- `T1560_002B_COMPRESSION_LEVEL`: Compression level 1-9 (default: 6)
- `T1560_002B_MAX_ARCHIVE_SIZE`: Maximum archive size MB (default: 100)
- `T1560_002B_PRESERVE_STRUCTURE`: Preserve directory structure (default: true)
- `T1560_002B_T1560_002B_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1560_002B_T1560_002B_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1560_002b_gzip_archive.json`: Archive results with metadata

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
- `tar` - Archive utility
- `gzip` - Compression utility
- `bzip2` - Alternative compression utility
- `xz` - Modern compression utility  
- `zip` - ZIP archive utility
- `p7zip` - 7-Zip archive utility
- `gnupg` - Encryption utility
- `openssl` - Cryptography toolkit
- `steghide` - Steganography tool

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc bzip2 find gnupg grep gzip jq openssl p7zip-full steghide tar xz-utils zip
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc bzip2 find gnupg2 grep gzip jq openssl p7zip steghide tar xz zip
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc bzip2 find gnupg grep gzip jq openssl p7zip steghide tar xz-utils zip
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

