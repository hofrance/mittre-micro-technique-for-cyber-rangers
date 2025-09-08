# T1114.002C - Extract Evolution Mail Configuration Files

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.002C for Linux environments. Extract Evolution mail configuration files from user directories.

## Technique Details
- **ID**: T1114.002C
- **Name**: Extract Evolution Mail Configuration Files
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_002C_OUTPUT_BASE="/tmp/mitre_results" && export T1114_002C_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Evolution mail configuration files ONLY
- Scope: One specific collection action
- Dependency: Bash + Evolution config access
- Privilege: User

## Environment Variables
- `T1114_002C_CONFIG_PATTERNS`: Configuration file patterns (default: *.conf,*.xml,sources,*.gconf)
- `T1114_002C_EVOLUTION_CONFIG_PATHS`: Configuration paths to scan (default: /home/*/.evolution,/home/*/.config/evolution)
- `T1114_002C_INCLUDE_ACCOUNTS`: Configuration parameter [true/false] (default: true)
- `T1114_002C_INCLUDE_FILTERS`: Configuration parameter [true/false] (default: true)
- `T1114_002C_MAX_FILES`: Maximum number of files to process (default: 100)
- `T1114_002C_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1114_002C_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_002C_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_002C_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_002C_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_002C_T1114_002C_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_002C_T1114_002C_TIMEOUT`: Execution timeout in seconds (default: 300)
- `MAX_FILES`: Maximum number of files to process (default: varies)

### T1114.002C Specific Variables
- `T1114_002C_EVOLUTION_CONFIG_PATHS`: Evolution config paths to scan (default: "$HOME/.config/evolution")
- `T1114_002C_CONFIG_TYPES`: Config file types (default: "*.conf,*.ini,*.xml,*.db")
- `T1114_002C_MAX_CONFIG_SIZE`: Maximum config file size bytes (default: 1048576)
- `T1114_002C_INCLUDE_SUBDIRS`: Include subdirectories [true/false] (default: true)
- `T1114_002C_FILTER_SENSITIVE`: Filter sensitive config data [true/false] (default: false)
- `T1114_002C_EXCLUDE_TEMP`: Exclude temporary files [true/false] (default: true)
- `T1114_002C_T1114_002C_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_002C_STEALTH_MODE`: Enable stealth operation (default: false)
- `T1114_002C_T1114_002C_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## System Requirements
- **Linux Distributions**: Ubuntu/Debian, RHEL/CentOS/Rocky, Fedora, openSUSE, Arch (95%+ compatibility)
- **Bash**: Version 4.0+ (standard on all modern distributions)
- **Core Utilities**: find, stat, grep, awk, sed (pre-installed on all distributions)
- **Evolution**: Mail client configuration files must exist
- **Permissions**: Appropriate access to target resources

## Dependencies
- **Universal**: bash, coreutils (find, stat, cat, grep)
- **Technique-specific**: Evolution mail client config files
- **Package managers**: Not required (no installation needed)

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Output Files
- `t1114_002c_evolution_config_collection.json`: Collection results with metadata

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
