# T1074.001A - Local Data Staging

## Description
This package implements MITRE ATT&CK atomic micro-technique T1074.001A for Linux environments. Stage collected data locally before exfiltration.

## Technique Details
- **ID**: T1074.001A
- **Name**: Local Data Staging
- **Parent Technique**: T1074
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1074_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1074_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: stage data locally ONLY
- Scope: One specific staging action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1074_001A_FILE_PATTERNS`: File patterns to match (default: *)
- `T1074_001A_MAX_FILES`: Maximum number of files to process (default: 1000)
- `T1074_001A_MAX_TOTAL_SIZE`: Configuration parameter (default: 1073741824)
- `T1074_001A_ORGANIZE_BY_TYPE`: Configuration parameter (default: true)
- `T1074_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1074_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1074_001A_PRESERVE_STRUCTURE`: Configuration parameter (default: false)
- `T1074_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1074_001A_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1074_001A_STAGING_DIR`: Configuration parameter (default: /tmp/.staging)
- `T1074_001A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1074_001A_T1074_001A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1074_001A_T1074_001A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1074.001A Specific Variables
- `T1074_001A_STAGING_PATHS`: Staging directory paths (default: "/tmp,/var/tmp")
- `T1074_001A_SOURCE_PATHS`: Source data paths (default: "$HOME")
- `T1074_001A_MAX_STAGING_SIZE`: Maximum staging size MB (default: 100)
- `T1074_001A_COMPRESS_DATA`: Compress staged data (default: true)
- `T1074_001A_T1074_001A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1074_001A_T1074_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1074_001a_local_staging.json`: Staging results with metadata

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


## Performance Optimizations

### Adaptive Timeout Mode
This package includes intelligent timeout management:
- **Test Mode Detection**: Automatically detects testing environments
- **Quick Execution**: Reduces capture duration during automated tests
- **Timeout Prevention**: Avoids timeouts in CI/CD environments

### Environment Variables for Optimization
- `T[ID]_TIMEOUT`: When set low (<30s), enables quick mode
- `QUICK_MODE`: Automatically set to "true" in test environments
- `MAX_CAPTURE_TIME`: Adapts to available time budget

### Usage in Different Contexts
```bash
# Production mode (full capture)
export T[ID]_TIMEOUT=300
./src/main.sh

# Test mode (quick execution) 
export T[ID]_TIMEOUT=10
./src/main.sh  # Automatically uses quick mode
```

**Note**: The package automatically adapts its behavior based on the timeout value to prevent test failures while maintaining full functionality in production environments.

