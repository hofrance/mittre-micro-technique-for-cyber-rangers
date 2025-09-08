# T1560.003C - Encrypted Archives

## Description
This package implements MITRE ATT&CK atomic micro-technique T1560.003C for Linux environments. Archive collected data with encryption for secure storage or exfiltration.

## Technique Details
- **ID**: T1560.003C
- **Name**: Encrypted Archives
- **Parent Technique**: T1560
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1560_003C_OUTPUT_BASE="/tmp/mitre_results" && export T1560_003C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: create encrypted archives ONLY
- Scope: One specific archiving action
- Dependency: Bash + encryption tools
- Privilege: User

## Environment Variables
- `T1560_003C_ARCHIVE_NAME`: Configuration parameter (default: encrypted_data)
- `T1560_003C_CIPHER`: Configuration parameter (default: aes-256-cbc)
- `T1560_003C_ENCRYPTION_KEY`: Configuration parameter (default: auto)
- `T1560_003C_ENCRYPTION_METHOD`: Encryption method [openssl/gpg/zip] (default: openssl)
- `T1560_003C_MAX_ARCHIVES`: Configuration parameter (default: 5)
- `T1560_003C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1560_003C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1560_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1560_003C_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1560_003C_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1560_003C_T1560_003C_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1560_003C_T1560_003C_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1560.003C Specific Variables
- `T1560_003C_ENCRYPTION_METHOD`: Encryption method (default: "openssl")
- `T1560_003C_ENCRYPTION_KEY`: Encryption key (default: "auto")
- `T1560_003C_SOURCE_PATHS`: Source paths (default: "$HOME/Documents")
- `T1560_003C_ARCHIVE_FORMAT`: Archive format (default: "tar.gz.enc")
- `T1560_003C_T1560_003C_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1560_003C_T1560_003C_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1560_003c_encrypted_archives.json`: Archive results with metadata

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

