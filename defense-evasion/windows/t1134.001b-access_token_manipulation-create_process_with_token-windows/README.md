# T1134.001B - Create Process with Token

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001B for Windows environments. Create a new process with a stolen/duplicated access token.

## Technique Details
- **ID**: T1134.001B
- **Name**: Create Process with Token
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **Administrator**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001B_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create new process using duplicated token ONLY
- Scope: One specific process creation with token
- Dependency: PowerShell + Windows API access
- Privilege: Administrator

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001B Specific Variables
- `T1134_001B_TARGET_PROCESS`: Target process for token duplication (default: "winlogon")
- `T1134_001B_NEW_PROCESS`: New process to create (default: "cmd.exe")
- `T1134_001B_PROCESS_ARGS`: Arguments for new process (default: "/c whoami")
- `T1134_001B_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001B_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001b_create_process_with_token.json`: Process creation results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001b_process_token_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll, kernel32.dll)
- SeDebugPrivilege

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```