# T1560.005E - Steganographic Archives

## Description
This package implements MITRE ATT&CK atomic micro-technique T1560.005E for Linux environments. Hide archived data using steganographic techniques.

## Technique Details
- **ID**: T1560.005E
- **Name**: Steganographic Archives
- **Parent Technique**: T1560
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1560_005E_OUTPUT_BASE="/tmp/mitre_results" && chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: create steganographic archives ONLY

## Environment Variables
- `T1560_005E_ARCHIVE_NAME`: Configuration parameter (default: hidden_data)
- `T1560_005E_COVER_IMAGES`: Configuration parameter (default: auto)
- `T1560_005E_MAX_ARCHIVES`: Configuration parameter (default: 5)
- `T1560_005E_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1560_005E_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1560_005E_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1560_005E_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1560_005E_STEGO_METHOD`: Configuration parameter (default: steghide)
- `T1560_005E_STEGO_PASSWORD`: Configuration parameter (default: auto)
- `T1560_005E_TIMEOUT`: Timeout in seconds (default: 300)

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
     bash bc bzip2 find gnupg grep gzip jq openssl p7zip-full steghide outguess imagemagick tar xz-utils zip
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc bzip2 find gnupg2 grep gzip jq openssl p7zip steghide tar xz zip
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc bzip2 find gnupg grep gzip jq openssl p7zip-full steghide outguess imagemagick tar xz-utils zip
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

