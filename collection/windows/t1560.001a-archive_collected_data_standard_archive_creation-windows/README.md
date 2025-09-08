# T1560.001A - Archive Collected Data A Standard Archive Creation

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1560.001A for Windows environments. Archive Collected Data A Standard Archive Creation with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1560.001A
- **Name**: Archive Collected Data A Standard Archive Creation
- **Parent Technique**: T1560
- **Tactic**: TA0009 - Collection
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: archive collected data a standard archive creation ONLY
- Scope: One specific collection action
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
- `T1560_001A_POLICY_CHECK`: Check Windows policies before execution (default: true)
- `T1560_001A_POLICY_BYPASS`: Attempt policy bypass if blocked (default: false)
- `T1560_001A_POLICY_SIMULATE`: Simulate execution if policy blocks (default: true)
- `T1560_001A_FALLBACK_MODE`: Fallback mode: simulate/skip/fail (default: "simulate")

### T1560.001A Specific Variables
- `T1560_001A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1560_001A_SILENT_MODE`: Enable silent execution - **ZERO OUTPUT** (default: false)
- `T1560_001A_RETRY_COUNT`: Number of retry attempts (default: 3)
- `T1560_001A_RETRY_DELAY`: Delay between retries in seconds (default: 5)

### Defense Evasion Variables (Windows)
- `T1560_001A_OBFUSCATION_LEVEL`: Obfuscation level 0-3 (default: 0)
- `T1560_001A_AV_EVASION`: Enable AV evasion techniques (default: false)
- `T1560_001A_SANDBOX_DETECTION`: Enable sandbox detection (default: true)
- `T1560_001A_SLEEP_JITTER`: Random sleep jitter in seconds (default: 0)

### Telemetry Variables (ECS/OpenTelemetry)
- `T1560_001A_ECS_VERSION`: ECS schema version (default: "8.0")
- `T1560_001A_SYSLOG_SERVER`: Syslog server for telemetry (optional)
- `T1560_001A_CORRELATION_ID`: Correlation ID for DAG chaining (default: "auto")

## Output Files
- `t1560_001a_results.json`: Collection results with Deputy metadata
- `t1560_001a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1560_001A_SILENT_MODE="true"; $env:T1560_001A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1560_001A_POLICY_CHECK="true"; $env:T1560_001A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1560_001A_OUTPUT_MODE="debug"; $env:T1560_001A_VERBOSE_LEVEL="3"; $env:T1560_001A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1560_001A_STEALTH_MODE="true"; $env:T1560_001A_AV_EVASION="true"; $env:T1560_001A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes (Deputy Standard)
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled