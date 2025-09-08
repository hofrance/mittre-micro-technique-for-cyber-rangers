# T1197.001A - BITS Background Download

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1197.001A for Windows environments. Use BITS jobs for background file downloads.

## Technique Details
- **ID**: T1197.001A
- **Name**: BITS Background Download
- **Parent Technique**: T1197
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1197_001A_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create BITS job to download file in background ONLY
- Scope: One specific BITS download job
- Dependency: PowerShell + BITS service
- Privilege: User

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1197.001A Specific Variables
- `T1197_001A_DOWNLOAD_URL`: URL to download from (default: "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/README.md")
- `T1197_001A_DESTINATION_PATH`: Download destination (default: "C:\temp\bits_download.txt")
- `T1197_001A_JOB_NAME`: BITS job name (default: "WindowsUpdate_[random]")
- `T1197_001A_PRIORITY`: Job priority (default: "NORMAL")
- `T1197_001A_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1197_001A_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1197_001a_bits_download.json`: BITS job results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1197.001a_bits_download_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with BITS service
- BitsTransfer PowerShell module

**Technique-Specific Dependencies:**
- BITS service running
- Network connectivity

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```