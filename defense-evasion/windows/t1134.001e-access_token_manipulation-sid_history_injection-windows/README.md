# T1134.001E - SID History Injection

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001E for Windows environments. Inject SID history into access tokens for privilege escalation.

## Technique Details
- **ID**: T1134.001E
- **Name**: SID History Injection
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **Administrator**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001E_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Inject SID history into token for cross-domain access ONLY
- Scope: One specific SID history injection
- Dependency: PowerShell + Windows API access
- Privilege: Administrator (Domain Admin for full effect)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001E Specific Variables
- `T1134_001E_TARGET_USER`: Target user for SID injection (default: "current")
- `T1134_001E_SID_TO_ADD`: SID to inject (default: "S-1-5-21-1234567890-1234567890-1234567890-519")
- `T1134_001E_INJECTION_METHOD`: Method to use (default: "token")
- `T1134_001E_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001E_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001e_sid_history_injection.json`: SID injection results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001e_sid_injection_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 or Server 2016+
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll, ntdll.dll)
- Administrator or Domain Admin privileges

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```