# T1134.001H - Token Privileges Escalation

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1134.001H for Windows environments. Escalate token privileges by enabling disabled privileges.

## Technique Details
- **ID**: T1134.001H
- **Name**: Token Privileges Escalation
- **Parent Technique**: T1134
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **Administrator**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1134_001H_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Enable all available but disabled privileges in token ONLY
- Scope: One specific privilege escalation operation
- Dependency: PowerShell + Windows API access
- Privilege: Administrator

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1134.001H Specific Variables
- `T1134_001H_TARGET_PRIVILEGES`: Specific privileges to enable (default: "all")
- `T1134_001H_PRIVILEGE_LIST`: List of privileges if not all (default: "SeDebugPrivilege,SeBackupPrivilege,SeRestorePrivilege")
- `T1134_001H_TEST_PRIVILEGES`: Test enabled privileges (default: true)
- `T1134_001H_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1134_001H_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1134_001h_token_privileges_escalation.json`: Privilege escalation results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1134.001h_privilege_escalation_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11
- .NET Framework 4.5+

**Technique-Specific Dependencies:**
- Windows API access (advapi32.dll)
- Administrator privileges for most privilege escalations

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```