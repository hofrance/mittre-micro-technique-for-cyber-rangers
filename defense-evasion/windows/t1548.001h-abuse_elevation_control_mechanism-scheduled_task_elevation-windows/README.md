# T1548.001H - Scheduled Task Elevation

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1548.001H for Windows environments. Achieve privilege elevation using scheduled tasks with highest privileges.

## Technique Details
- **ID**: T1548.001H
- **Name**: Scheduled Task Elevation
- **Parent Technique**: T1548
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
$env:OUTPUT_BASE = "C:\temp\mitre_results"; $env:T1548_001H_SILENT_MODE = $false
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Atomic Action
**Single Observable Action**: Create and execute scheduled task with highest privileges ONLY
- Scope: One specific scheduled task elevation action
- Dependency: PowerShell + Task Scheduler access
- Privilege: User (escalates to SYSTEM)

## Environment Variables

### Universal Variables
- `OUTPUT_BASE`: Base directory for results (default: "C:\temp\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)

### T1548.001H Specific Variables
- `T1548_001H_TASK_NAME`: Scheduled task name (default: "SystemUpdate_[random]")
- `T1548_001H_TARGET_COMMAND`: Command to execute elevated (default: "cmd.exe /c whoami > C:\temp\elevated.txt")
- `T1548_001H_RUN_LEVEL`: Task run level (default: "Highest")
- `T1548_001H_CLEANUP`: Remove task after execution (default: true)
- `T1548_001H_OUTPUT_MODE`: Output mode simple/debug/stealth/none (default: "simple")
- `T1548_001H_SILENT_MODE`: Enable silent execution (default: false)

## Output Files
- `t1548_001h_scheduled_task_elevation.json`: Task execution results with metadata (debug mode)
- Output directory: `$OUTPUT_BASE\T1548.001h_task_elevation_[timestamp]\`

## Dependencies

### Required Tools
**Core Dependencies:**
- `powershell` - PowerShell 5.0+
- Windows 10/11 with Task Scheduler
- schtasks.exe

**Technique-Specific Dependencies:**
- Task Scheduler service running
- User permissions to create tasks

### Installation Commands
Windows components are built-in. No additional installation required.

**Note:** If dependencies are missing, you'll see:
```powershell
# [ERROR] Missing dependency: <component_name>
```