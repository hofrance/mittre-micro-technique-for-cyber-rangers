# T1197.001B - BITS Persistence

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1197.001B for Windows environments. Establish persistence using BITS jobs with SetNotifyCmdLine.

## Technique Details
- **ID**: T1197.001B
- **Name**: BITS Persistence
- **Parent Technique**: T1197
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1197_001B_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create persistent BITS job with notification command ONLY
- Scope: One specific BITS persistence job
- Dependency: PowerShell + BITS service
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1197.001B Specific Variables
- `T1197_001B_PERSISTENCE_COMMAND`: Command to execute on job completion (default: "powershell.exe -nop -w hidden -c 'echo Persistence triggered'")
- `T1197_001B_JOB_NAME`: BITS job name (default: "MicrosoftUpdate_[random]")
- `T1197_001B_DUMMY_URL`: URL for dummy download (default: "https://www.microsoft.com/robots.txt")
- `T1197_001B_RETRY_DELAY`: Retry delay in seconds (default: 3600)
- `T1197_001B_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1197_001B_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1197_001b_bits_persistence.json`: BITS persistence results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1197.001b_bits_persist_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with BITS service
- bitsadmin.exe

**Technique-Specific Dependencies:**
- BITS service running
- Admin rights for some persistence methods

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```