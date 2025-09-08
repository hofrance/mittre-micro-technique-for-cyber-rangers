# T1548.001F - Elevation via COM Objects

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001F for Windows environments. Achieve privilege elevation using COM objects with auto-elevation.

## Technique Details
- **ID**: T1548.001F
- **Name**: Elevation via COM Objects
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001F_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Elevation using COM auto-elevated interfaces ONLY
- Scope: One specific COM elevation action
- Dependency: PowerShell + COM access
- Privilege: User (escalates to Admin)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001F Specific Variables
- `T1548_001F_COM_OBJECT`: COM object to use (default: "Shell.Application")
- `T1548_001F_COM_METHOD`: COM method to invoke (default: "ShellExecute")
- `T1548_001F_TARGET_COMMAND`: Command to execute elevated (default: "cmd.exe")
- `T1548_001F_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001F_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001f_elevation_via_com.json`: COM elevation results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001f_com_elevation_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with COM support
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- COM auto-elevated interfaces
- Shell.Application COM object

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```