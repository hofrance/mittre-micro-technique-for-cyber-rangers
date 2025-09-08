# T1134.001F - Token Stealing

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001F for Windows environments. Steal access tokens from running processes for impersonation.

## Technique Details
- **ID**: T1134.001F
- **Name**: Token Stealing
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **Administrator**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001F_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Steal and use access token from target process ONLY
- Scope: One specific token theft operation
- Dependency: PowerShell + Windows API access
- Privilege: Administrator

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001F Specific Variables
- `T1134_001F_TARGET_PROCESS`: Target process to steal token from (default: "lsass")
- `T1134_001F_USE_TOKEN`: Use stolen token immediately (default: true)
- `T1134_001F_TEST_COMMAND`: Command to test with stolen token (default: "whoami /all")
- `T1134_001F_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001F_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001f_token_stealing.json`: Token theft results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001f_token_theft_[timestamp]\`

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