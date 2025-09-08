# T1114.002D - Extract Evolution Mail Data Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.002D for Linux environments. Extract Evolution mail data files (maildir/cache/data stores) from user directories.

## Technique Details
- **ID**: T1114.002D
- **Name**: Extract Evolution Mail Data Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_002D_OUTPUT_BASE="/tmp/mitre_results" && export T1114_002D_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Evolution mail data files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_002D_EVOLUTION_DATA_PATHS`: Configuration parameter (default: /home/*/.local/share/evolution/mail)
- `T1114_002D_INCLUDE_DRAFTS`: Configuration parameter [true/false] (default: true)
- `T1114_002D_INCLUDE_SENT`: Configuration parameter [true/false] (default: true)
- `T1114_002D_MAILDATA_PATTERNS`: Configuration parameter (default: *,cur/*,new/*,tmp/*)
- `T1114_002D_MAX_FILES`: Maximum number of files to process (default: 400)
- `T1114_002D_MAX_FILE_SIZE`: Maximum file size to process (default: 52428800)
- `T1114_002D_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_002D_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_002D_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_002D_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_002D_T1114_002D_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_002D_T1114_002D_TIMEOUT`: Execution timeout in seconds (default: 300)
- `MAX_FILES`: Maximum number of files to process (default: varies)

### T1114.002D Specific Variables
- `T1114_002D_EVOLUTION_DATA_PATHS`: Evolution data paths to scan (default: "$HOME/.local/share/evolution")
- `T1114_002D_DATA_TYPES`: Data file types (default: "*.*,*.db,*.ibex.index,*.ibex.hash")
- `T1114_002D_MAX_DATA_SIZE`: Maximum data file size bytes (default: 10485760)
- `T1114_002D_INCLUDE_SUBDIRS`: Include subdirectories [true/false] (default: true)
- `T1114_002D_EXCLUDE_TEMP`: Exclude temporary files [true/false] (default: true)
- `T1114_002D_T1114_002D_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_002D_STEALTH_MODE`: Enable stealth operation (default: false)
- `T1114_002D_T1114_002D_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## System Requirements
- **Linux Distributions**: Ubuntu/Debian, RHEL/CentOS/Rocky, Fedora, openSUSE, Arch (95%+ compatibility)
- **Bash**: Version 4.0+ (standard on all modern distributions)
- **Core Utilities**: find, stat, grep, awk, sed (pre-installed on all distributions)
- **Permissions**: Appropriate access to target resources

## Dependencies
- **Universal**: bash, coreutils (find, stat, cat, grep)
- **Technique-specific**: Evolution mail data store present
- **Package managers**: Not required (no installation needed)

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Output Files
- `t1114_002d_evolution_maildata_collection.json`: Collection results with metadata

## Core Functionality
- Get-Configuration: Load ultra-granular configuration
- Initialize-OutputStructure: Create atomic output structure
- Invoke-MicroTechniqueAction: Execute atomic action ONLY
- Write-StandardizedOutput: Triple-mode output (simple/debug/stealth)
- Main: Orchestrate execution with graceful error handling

## Micro-Technique Family
**Email Collection Family (T1114.001A→T1114.006A)**

## MITRE ATT&CK Reference
- **Technique**: T1114 - Email Collection
- **Sub-technique**: T1114.002 - Email Collection: Email Collection
- **URL**: https://attack.mitre.org/techniques/T1114/002/
