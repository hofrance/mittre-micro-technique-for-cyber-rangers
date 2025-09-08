# T1622.001A - PEB BeingDebugged Flag Check

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1622.001A for Windows environments. Detect debugger presence using PEB BeingDebugged flag.

## Technique Details
- **ID**: T1622.001A
- **Name**: PEB BeingDebugged Flag Check
- **Parent Technique**: T1622
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1622_001A_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Check PEB BeingDebugged flag for debugger detection ONLY
- Scope: One specific anti-debugging check
- Dependency: PowerShell + Windows API access
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1622.001A Specific Variables
- `T1622_001A_ACTION_ON_DEBUG`: Action if debugger detected exit/continue/alert (default: "alert")
- `T1622_001A_CHECK_PARENT`: Also check parent process (default: true)
- `T1622_001A_EXIT_CODE`: Exit code if debugger detected (default: 100)
- `T1622_001A_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1622_001A_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1622_001a_peb_debugger_check.json`: Debugger detection results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1622.001a_peb_check_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (kernel32.dll, ntdll.dll)
- Process access rights

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```