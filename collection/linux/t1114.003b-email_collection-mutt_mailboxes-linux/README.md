# T1114.003B - Extract Mutt Mailboxes

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.003B for Linux environments. Extract Mutt mailboxes references and mailbox files from user directories.

## Technique Details
- **ID**: T1114.003B
- **Name**: Extract Mutt Mailboxes
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_003B_OUTPUT_BASE="/tmp/mitre_results" && export T1114_003B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Mutt mailbox files ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_003B_INCLUDE_SYSTEM`: Configuration parameter [true/false] (default: false)
- `T1114_003B_MAILBOX_PATHS`: Configuration parameter (default: /home/*/Mail,/var/mail,/var/spool/mail)
- `T1114_003B_MAILBOX_PATTERNS`: Configuration parameter (default: *,mbox,*.mbox)
- `T1114_003B_MAX_FILES`: Maximum number of files to process (default: 200)
- `T1114_003B_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_003B_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_003B_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_003B_SCAN_DEPTH`: Maximum scan depth (default: 2)
- `T1114_003B_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_003B_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_003B_T1114_003B_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_003B_T1114_003B_TIMEOUT`: Execution timeout in seconds (default: 300)
- `MAX_FILES`: Maximum number of files to process (default: varies)

### T1114.003B Specific Variables
- `T1114_003B_MUTT_MAILBOX_PATHS`: Paths to search for Mutt mailboxes (default: "$HOME/Mail,$HOME/.mail")
- `T1114_003B_MAILBOX_PATTERNS`: File patterns (default: "*", can be "*.mbox,*.mail")
- `T1114_003B_MAX_MAILBOX_SIZE`: Maximum mailbox file size bytes (default: 10485760)
- `T1114_003B_INCLUDE_SUBDIRS`: Include subdirectories [true/false] (default: true)
- `T1114_003B_T1114_003B_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_003B_STEALTH_MODE`: Enable stealth operation (default: false)
- `T1114_003B_T1114_003B_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## System Requirements
- **Linux Distributions**: Ubuntu/Debian, RHEL/CentOS/Rocky, Fedora, openSUSE, Arch (95%+ compatibility)
- **Bash**: Version 4.0+ (standard on all modern distributions)
- **Core Utilities**: find, stat, grep, awk, sed (pre-installed on all distributions)

## Dependencies
- **Universal**: bash, coreutils (find, stat, cat, grep)
- **Technique-specific**: Mutt mailbox files present
- **Package managers**: Not required (no installation needed)

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Output Files
- `t1114_003b_mutt_mailboxes_collection.json`: Collection results with metadata

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
- **URL**: https://attack.mitre.org/techniques/T1114/
