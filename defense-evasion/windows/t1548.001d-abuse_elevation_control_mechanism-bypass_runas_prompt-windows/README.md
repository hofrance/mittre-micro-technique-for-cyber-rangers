# T1548.001D - Bypass RunAs Elevation Prompt

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001D for Windows environments. Bypass RunAs elevation prompt using Windows COM elevation moniker.

## Technique Details
- **ID**: T1548.001D
- **Name**: Bypass RunAs Elevation Prompt
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001D_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Bypass RunAs elevation prompt via COM elevation moniker ONLY
- Scope: One specific elevation bypass action
- Dependency: PowerShell + COM access
- Privilege: User (escalates to Admin)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001D Specific Variables
- `T1548_001D_TARGET_COMMAND`: Command to execute with elevated privileges (default: "cmd.exe")
- `T1548_001D_COM_CLSID`: COM CLSID for elevation (default: "{3E5FC7F9-9A51-4367-9063-A120244FBEC7}")
- `T1548_001D_METHOD`: Elevation method (default: "ShellExecute")
- `T1548_001D_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001D_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001d_bypass_runas_prompt.json`: Bypass results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001d_elevation_bypass_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with COM support
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- COM elevation interfaces
- IFileOperation COM interface

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```