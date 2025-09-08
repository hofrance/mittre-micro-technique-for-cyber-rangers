# T1119.002A - Content-Based File Filtering

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1119.002A for Windows environments. Content-Based File Filtering with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1119.002A
- **Name**: Content-Based File Filtering
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: filter files based on content patterns ONLY
- Scope: One specific content filtering action
- Dependency: PowerShell + Windows APIs
- Privilege: User

## Environment Variables

### Universal Variables (Deputy Standard)
- `OUTPUT_BASE`: Base directory for results (default: "$env:TEMP\mitre_results")
- `TIMEOUT`: Execution timeout in seconds (default: 300)
- `DEBUG_MODE`: Enable debug output (default: false)
- `STEALTH_MODE`: Enable stealth execution (default: false)
- `VERBOSE_LEVEL`: Verbosity level 0-3 (default: 1)

### Policy-Awareness Variables (Windows)
- `T1119_002A_POLICY_CHECK`: Check Windows policies before execution (default: true)
- `T1119_002A_POLICY_BYPASS`: Attempt policy bypass if blocked (default: false)
- `T1119_002A_POLICY_SIMULATE`: Simulate execution if policy blocks (default: true)
- `T1119_002A_FALLBACK_MODE`: Fallback mode: simulate/skip/fail (default: "simulate")

### T1119.002A Specific Variables
- `T1119_002A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1119_002A_SILENT_MODE`: Enable silent execution - **ZERO OUTPUT** (default: false)
- `T1119_002A_SEARCH_PATTERNS`: Content patterns to search for (default: "password,secret,key")
- `T1119_002A_FILE_EXTENSIONS`: File extensions to filter (default: "txt,conf,ini,cfg")
- `T1119_002A_MAX_FILES`: Maximum files to process (default: 1000)

### Defense Evasion Variables (Windows)
- `T1119_002A_OBFUSCATION_LEVEL`: Obfuscation level 0-3 (default: 0)
- `T1119_002A_AV_EVASION`: Enable AV evasion techniques (default: false)
- `T1119_002A_SANDBOX_DETECTION`: Enable sandbox detection (default: true)
- `T1119_002A_SLEEP_JITTER`: Random sleep jitter in seconds (default: 0)

### Telemetry Variables (ECS/OpenTelemetry)
- `T1119_002A_ECS_VERSION`: ECS schema version (default: "8.0")
- `T1119_002A_SYSLOG_SERVER`: Syslog server for telemetry (optional)
- `T1119_002A_CORRELATION_ID`: Correlation ID for DAG chaining (default: "auto")

## Output Files
- `t1119_002a_results.json`: Collection results with Deputy metadata
- `t1119_002a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1119_002A_SILENT_MODE="true"; $env:T1119_002A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1119_002A_POLICY_CHECK="true"; $env:T1119_002A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1119_002A_OUTPUT_MODE="debug"; $env:T1119_002A_VERBOSE_LEVEL="3"; $env:T1119_002A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1119_002A_STEALTH_MODE="true"; $env:T1119_002A_AV_EVASION="true"; $env:T1119_002A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled
