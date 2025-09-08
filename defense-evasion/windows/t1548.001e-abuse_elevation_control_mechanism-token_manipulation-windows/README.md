# T1548.001E - Token Manipulation for Elevation

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001E for Windows environments. Manipulate Windows access tokens for privilege elevation.

## Technique Details
- **ID**: T1548.001E
- **Name**: Token Manipulation for Elevation
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001E_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Manipulate process access token for elevation ONLY
- Scope: One specific token manipulation action
- Dependency: PowerShell + Windows API access
- Privilege: User (attempts elevation)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001E Specific Variables
- `T1548_001E_TARGET_PROCESS`: Target process for token manipulation (default: "winlogon")
- `T1548_001E_PRIVILEGE_NAME`: Privilege to enable (default: "SeDebugPrivilege")
- `T1548_001E_TOKEN_TYPE`: Token type to duplicate (default: "Primary")
- `T1548_001E_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001E_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001e_token_manipulation.json`: Token manipulation results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001e_token_manipulation_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll)
- Process access rights

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```