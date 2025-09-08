# T1134.001D - Parent PID Spoofing

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001D for Windows environments. Spoof parent process ID when creating new processes.

## Technique Details
- **ID**: T1134.001D
- **Name**: Parent PID Spoofing
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001D_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create process with spoofed parent PID ONLY
- Scope: One specific process creation with PPID spoofing
- Dependency: PowerShell + Windows API access
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001D Specific Variables
- `T1134_001D_TARGET_PARENT`: Target parent process name (default: "explorer")
- `T1134_001D_NEW_PROCESS`: Process to create (default: "notepad.exe")
- `T1134_001D_PROCESS_ARGS`: Arguments for new process (default: "")
- `T1134_001D_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001D_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001d_parent_pid_spoofing.json`: PPID spoofing results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001d_ppid_spoof_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (kernel32.dll)
- Process creation rights

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```