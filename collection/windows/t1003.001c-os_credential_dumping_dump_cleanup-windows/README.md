# T1003.004A - Os Credential Dumping D Dump Cleanup

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1003.004A for Windows environments. Os Credential Dumping D Dump Cleanup with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1003.004A
- **Name**: Os Credential Dumping D Dump Cleanup
- **Parent Technique**: T1003
- **Tactic**: TA0006 - Credential Access
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: os credential dumping d dump cleanup ONLY
- Scope: One specific collection action
- Dependency: PowerShell + Windows APIs
- Privilege: User

## Environment Variables

### Universal Variables (Deputy Standard)
- `T1003_004A_OUTPUT_BASE`: Base directory for results (default: "$env:TEMP\mitre_results") - Values: any valid directory path
- `T1003_004A_TIMEOUT`: Execution timeout in seconds (default: 300) - Values: any positive integer
- `T1003_004A_DEBUG_MODE`: Enable debug output (default: false) - Values: true/false
- `T1003_004A_STEALTH_MODE`: Enable stealth execution (default: false) - Values: true/false
- `T1003_004A_VERBOSE_LEVEL`: Verbosity level 0-3 (default: 1) - Values: 0 (silent)/1 (basic)/2 (detailed)/3 (debug)

### Policy-Awareness Variables (Windows)
- `T1003_004A_POLICY_CHECK`: Check Windows policies before execution (default: true) - Values: true/false
- `T1003_004A_POLICY_BYPASS`: Attempt policy bypass if blocked (default: false) - Values: true/false
- `T1003_004A_POLICY_SIMULATE`: Simulate execution if policy blocks (default: true) - Values: true/false
- `T1003_004A_FALLBACK_MODE`: Fallback mode when policy blocks (default: "simulate") - Values: "simulate"/"skip"/"fail"

### T1003.004A Specific Variables
- `T1003_004A_OUTPUT_MODE`: Output mode (default: "simple") - Values: "simple"/"debug"/"stealth"
- `T1003_004A_SILENT_MODE`: Enable silent execution - ZERO OUTPUT (default: false) - Values: true/false
- `T1003_004A_RETRY_COUNT`: Number of retry attempts (default: 3) - Values: 0-10
- `T1003_004A_RETRY_DELAY`: Delay between retries in seconds (default: 5) - Values: 1-60

### Defense Evasion Variables (Windows)
- `T1003_004A_OBFUSCATION_LEVEL`: Obfuscation level 0-3 (default: 0) - Values: 0 (none)/1 (basic)/2 (moderate)/3 (high)
- `T1003_004A_AV_EVASION`: Enable AV evasion techniques (default: false) - Values: true/false
- `T1003_004A_SANDBOX_DETECTION`: Enable sandbox detection (default: true) - Values: true/false
- `T1003_004A_SLEEP_JITTER`: Random sleep jitter in seconds (default: 0) - Values: 0 (disabled) or any positive integer

### Telemetry Variables (ECS/OpenTelemetry)
- `T1003_004A_ECS_VERSION`: ECS schema version (default: "8.0") - Values: "8.0"/"1.12.0" or any valid ECS version
- `T1003_004A_SYSLOG_SERVER`: Syslog server for telemetry (optional) - Values: IP address or hostname (e.g., "192.168.1.100" or "syslog.example.com")
- `T1003_004A_CORRELATION_ID`: Correlation ID for DAG chaining (default: "auto") - Values: "auto" or any custom string

## Output Files
- `t1003_004a_results.json`: Collection results with Deputy metadata
- `t1003_004a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1003_004A_SILENT_MODE="true"; $env:T1003_004A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1003_004A_POLICY_CHECK="true"; $env:T1003_004A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1003_004A_OUTPUT_MODE="debug"; $env:T1003_004A_VERBOSE_LEVEL="3"; $env:T1003_004A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1003_004A_STEALTH_MODE="true"; $env:T1003_004A_AV_EVASION="true"; $env:T1003_004A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes (Deputy Standard)
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled