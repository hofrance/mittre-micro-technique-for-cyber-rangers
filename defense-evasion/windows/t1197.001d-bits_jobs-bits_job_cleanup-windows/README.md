# T1197.001D - BITS Job Cleanup

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1197.001D for Windows environments. Clean up BITS job artifacts to hide traces.

## Technique Details
- **ID**: T1197.001D
- **Name**: BITS Job Cleanup
- **Parent Technique**: T1197
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1197_001D_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Remove completed/error BITS jobs and artifacts ONLY
- Scope: One specific BITS cleanup operation
- Dependency: PowerShell + BITS service
- Privilege: User (for own jobs)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1197.001D Specific Variables
- `T1197_001D_CLEANUP_SCOPE`: Scope of cleanup all/completed/error/specific (default: "completed")
- `T1197_001D_TARGET_JOB`: Specific job name/ID to clean (default: "")
- `T1197_001D_CLEANUP_FILES`: Also remove downloaded files (default: true)
- `T1197_001D_MAX_AGE_HOURS`: Max age of jobs to clean in hours (default: 24)
- `T1197_001D_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1197_001D_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1197_001d_bits_cleanup.json`: Cleanup results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1197.001d_bits_cleanup_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with BITS service
- BitsTransfer PowerShell module

**Technique-Specific Dependencies:**
- BITS service running
- Appropriate permissions for job removal

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```