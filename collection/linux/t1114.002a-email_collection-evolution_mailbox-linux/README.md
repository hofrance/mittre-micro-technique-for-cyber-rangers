# T1114_002A - Evolution Mailbox

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114_002A for Linux environments.

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
export T1114_002A_OUTPUT_BASE="/tmp/mitre_results" && export T1114_002A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Environment Variables
- `T1114_002A_EVOLUTION_PATHS`: Configuration parameter (default: /home/*/.evolution,/home/*/.local/share/evolution)
- `T1114_002A_INCLUDE_CALENDAR`: Configuration parameter [true/false] (default: false)
- `T1114_002A_INCLUDE_CONTACTS`: Configuration parameter [true/false] (default: true)
- `T1114_002A_MAILBOX_PATTERNS`: Configuration parameter (default: mbox,*.mbox,*.db)
- `T1114_002A_MAX_FILES`: Maximum number of files to process (default: 300)
- `T1114_002A_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_002A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_002A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_002A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_002A_TIMEOUT`: Timeout in seconds (default: 300)

## Output
The package will generate results in the specified output directory with standardized Deputy Framework output format.
