# T1005_005E - Ssh Private Keys

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005_005E for Linux environments.

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

## Manual Execution
```bash
export T1005_005E_OUTPUT_BASE="/tmp/mitre_results" && export T1005_005E_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Environment Variables
- `T1005_005E_EXCLUDE_SYSTEM`: Configuration parameter [true/false] (default: true)
- `T1005_005E_INCLUDE_AUTHORIZED`: Configuration parameter [true/false] (default: true)
- `T1005_005E_INCLUDE_KNOWN_HOSTS`: Configuration parameter [true/false] (default: true)
- `T1005_005E_INCLUDE_PUBLIC`: Configuration parameter [true/false] (default: false)
- `T1005_005E_KEY_PATTERNS`: SSH key file patterns (default: id_*,*.pem,*.key)
- `T1005_005E_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1005_005E_MAX_KEY_SIZE`: Configuration parameter (default: 16384)
- `T1005_005E_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_005E_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_005E_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_005E_SSH_KEY_PATHS`: SSH key search paths (default: $HOME/.ssh,/root/.ssh)
- `T1005_005E_TIMEOUT`: Timeout in seconds (default: 300)
- `T1005_005E_VERIFY_FORMAT`: Configuration parameter [true/false] (default: true)

## Output
The package will generate results in the specified output directory with standardized Deputy Framework output format.
