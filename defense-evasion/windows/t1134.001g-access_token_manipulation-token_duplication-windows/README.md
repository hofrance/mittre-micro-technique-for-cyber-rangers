# T1134.001G - Token Duplication

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001G for Windows environments. Duplicate access tokens to create new security contexts.

## Technique Details
- **ID**: T1134.001G
- **Name**: Token Duplication
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001G_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Duplicate current or target process token ONLY
- Scope: One specific token duplication operation
- Dependency: PowerShell + Windows API access
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001G Specific Variables
- `T1134_001G_TOKEN_SOURCE`: Source for token current/process (default: "current")
- `T1134_001G_TARGET_PROCESS`: Target process if source is process (default: "explorer")
- `T1134_001G_TOKEN_TYPE`: Token type Primary/Impersonation (default: "Impersonation")
- `T1134_001G_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001G_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001g_token_duplication.json`: Token duplication results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001g_token_duplicate_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll, kernel32.dll)
- Token duplication rights

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```