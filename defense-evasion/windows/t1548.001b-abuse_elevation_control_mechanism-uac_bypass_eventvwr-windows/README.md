# T1548.001B - UAC Bypass via EventVwr

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001B for Windows environments. Bypass UAC using eventvwr.exe registry hijacking technique.

## Technique Details
- **ID**: T1548.001B
- **Name**: UAC Bypass via EventVwr
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001B_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: UAC bypass via eventvwr.exe registry hijacking ONLY
- Scope: One specific UAC bypass action
- Dependency: PowerShell + Registry access
- Privilege: User (escalates to Admin)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001B Specific Variables
- `T1548_001B_TARGET_COMMAND`: Command to execute with elevated privileges (default: "cmd.exe /c start powershell.exe")
- `T1548_001B_REGISTRY_PATH`: Registry path for hijacking (default: "HKCU:\Software\Classes\mscfile\shell\open\command")
- `T1548_001B_CLEANUP`: Cleanup registry after execution (default: true)
- `T1548_001B_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001B_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001b_uac_bypass_eventvwr.json`: Bypass results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001b_uac_bypass_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with eventvwr.exe
- Registry write access (HKCU)

**Technique-Specific Dependencies:**
- `eventvwr.exe` - Event Viewer
- UAC enabled (default Windows configuration)

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```