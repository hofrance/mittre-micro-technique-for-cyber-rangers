# T1134.001C - Make/Modify Token

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001C for Windows environments. Create or modify Windows access tokens with custom privileges.

## Technique Details
- **ID**: T1134.001C
- **Name**: Make/Modify Token
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **Administrator**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001C_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create or modify access token with custom privileges ONLY
- Scope: One specific token creation/modification
- Dependency: PowerShell + Windows API access
- Privilege: Administrator

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001C Specific Variables
- `T1134_001C_TOKEN_ACTION`: Action to perform create/modify (default: "modify")
- `T1134_001C_TARGET_PRIVILEGES`: Privileges to add (default: "SeDebugPrivilege,SeBackupPrivilege")
- `T1134_001C_TARGET_PROCESS`: Target process for modification (default: "current")
- `T1134_001C_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001C_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001c_make_modify_token.json`: Token modification results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001c_token_modify_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll)
- Administrator privileges

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```