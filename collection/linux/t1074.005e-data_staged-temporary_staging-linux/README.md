# T1074_005E - Temporary Staging

## Description
This package implements MITRE ATT&CK atomic micro-technique T1074_005E for Linux environments.

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
export T1074_005E_OUTPUT_BASE="/tmp/mitre_results" && export T1074_005E_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Environment Variables
- `T1074_005E_AUTO_CLEANUP`: Configuration parameter (default: false)
- `T1074_005E_MAX_FILES`: Maximum number of files to process (default: 1000)
- `T1074_005E_MAX_TOTAL_SIZE`: Configuration parameter (default: 1073741824)
- `T1074_005E_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1074_005E_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1074_005E_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1074_005E_SOURCE_PATHS`: Configuration parameter (default: /tmp/mitre_results)
- `T1074_005E_STAGING_PREFIX`: Configuration parameter (default: .tmp_)
- `T1074_005E_TEMP_DIRS`: Configuration parameter (default: /tmp,/var/tmp,/dev/shm)
- `T1074_005E_TIMEOUT`: Timeout in seconds (default: 300)

## Output
The package will generate results in the specified output directory with standardized Deputy Framework output format.
