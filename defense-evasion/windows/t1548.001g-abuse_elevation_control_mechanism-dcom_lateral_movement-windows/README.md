# T1548.001G - DCOM Lateral Movement

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001G for Windows environments. Use DCOM for lateral movement with elevated privileges.

## Technique Details
- **ID**: T1548.001G
- **Name**: DCOM Lateral Movement
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001G_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Execute command via DCOM on local/remote system ONLY
- Scope: One specific DCOM execution action
- Dependency: PowerShell + DCOM access
- Privilege: User (with DCOM permissions)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001G Specific Variables
- `T1548_001G_TARGET_HOST`: Target host for DCOM (default: "localhost")
- `T1548_001G_DCOM_OBJECT`: DCOM object to use (default: "MMC20.Application")
- `T1548_001G_TARGET_COMMAND`: Command to execute (default: "calc.exe")
- `T1548_001G_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001G_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001g_dcom_lateral_movement.json`: DCOM execution results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001g_dcom_movement_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with DCOM support
- Network connectivity (for remote targets)

**Technique-Specific Dependencies:**
- DCOM enabled
- MMC20.Application or ShellWindows DCOM objects

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```