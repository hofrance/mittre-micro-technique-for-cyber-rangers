# T1560.001A - TAR Archive Collected Data

## Description
This package implements MITRE ATT&CK atomic micro-technique T1560.001A for Linux environments. Archive collected data using TAR compression for storage or exfiltration.

## Technique Details
- **ID**: T1560.001A
- **Name**: TAR Archive Collected Data
- **Parent Technique**: T1560
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1560_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1560_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: archive data with TAR compression ONLY
- Scope: One specific archiving action
- Dependency: Bash + tar utility
- Privilege: User

## Environment Variables
- `T1560_001A_ARCHIVE_NAME`: Configuration parameter (default: collected_data)
- `T1560_001A_COMPRESSION_LEVEL`: Configuration parameter (default: 6)
- `T1560_001A_INCLUDE_METADATA`: Configuration parameter [true/false] (default: true)
- `T1560_001A_MAX_ARCHIVES`: Configuration parameter (default: 10)
- `T1560_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1560_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1560_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1560_001A_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1560_001A_SPLIT_SIZE`: Split archive size [10M/100M/1G] (default: 100M)
- `T1560_001A_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1560_001a_tar_archive.json`: Archive results with metadata

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

