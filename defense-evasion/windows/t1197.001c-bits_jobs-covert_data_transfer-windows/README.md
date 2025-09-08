# T1197.001C - BITS Covert Data Transfer

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1197.001C for Windows environments. Use BITS jobs for covert data transfer and exfiltration.

## Technique Details
- **ID**: T1197.001C
- **Name**: BITS Covert Data Transfer
- **Parent Technique**: T1197
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1197_001C_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create BITS upload job for data exfiltration ONLY
- Scope: One specific BITS upload job
- Dependency: PowerShell + BITS service
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1197.001C Specific Variables
- `T1197_001C_SOURCE_FILE`: File to exfiltrate (default: "C:\Windows\System32\drivers\etc\hosts")
- `T1197_001C_UPLOAD_URL`: Upload destination URL (default: "https://httpbin.org/post")
- `T1197_001C_JOB_NAME`: BITS job name (default: "SystemDiagnostics_[random]")
- `T1197_001C_JOB_DESCRIPTION`: Job description (default: "System Diagnostics Upload")
- `T1197_001C_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1197_001C_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1197_001c_bits_covert_transfer.json`: BITS transfer results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1197.001c_covert_transfer_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with BITS service
- BitsTransfer PowerShell module

**Technique-Specific Dependencies:**
- BITS service running
- Network connectivity
- Upload endpoint (for real exfiltration)

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```