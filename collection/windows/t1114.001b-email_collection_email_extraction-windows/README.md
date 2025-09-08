# T1114.002A - Email Collection B Email Extraction

## Overview
This package implements MITRE ATT&CK micro-technique T1114.002A for Windows environments. Email Collection B Email Extraction with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1114.002A
- **Name**: Email Collection B Email Extraction
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: email extraction from detected clients ONLY
- Scope: One specific collection action
- Dependency: PowerShell + Windows APIs
- Privilege: User

## Environment Variables

### Universal Variables (Deputy Standard)
- `T1114_002A_OUTPUT_BASE`: Base directory for results (default: "$env:TEMP\mitre_results") - Values: any valid directory path
- `T1114_002A_TIMEOUT`: Execution timeout in seconds (default: 300) - Values: any positive integer
- `T1114_002A_DEBUG_MODE`: Enable debug output (default: false) - Values: true/false
- `T1114_002A_STEALTH_MODE`: Enable stealth execution (default: false) - Values: true/false
- `T1114_002A_VERBOSE_LEVEL`: Verbosity level 0-3 (default: 1) - Values: 0 (silent)/1 (basic)/2 (detailed)/3 (debug)

### Policy-Awareness Variables (Windows)
- `T1114_002A_POLICY_CHECK`: Check Windows policies before execution (default: true) - Values: true/false
- `T1114_002A_POLICY_SIMULATE`: Simulate execution if policy blocks (default: true) - Values: true/false
- `T1114_002A_FALLBACK_MODE`: Fallback mode when policy blocks (default: "simulate") - Values: "simulate"/"skip"/"fail"

### T1114.002A Specific Variables
- `T1114_002A_OUTPUT_MODE`: Output mode (default: "simple") - Values: "simple"/"debug"/"stealth"
- `T1114_002A_SILENT_MODE`: Enable silent execution - ZERO OUTPUT (default: false) - Values: true/false
- `T1114_002A_MAX_EMAILS`: Maximum number of emails to extract (default: 100) - Values: any positive integer
- `T1114_002A_EMAIL_FORMATS`: Email formats to search for (default: "eml,msg") - Values: "eml"/"msg"/"pst" (comma-separated)
- `T1114_002A_INCLUDE_ATTACHMENTS`: Include email attachments (default: false) - Values: true/false

### Defense Evasion Variables (Windows)
- `T1114_002A_SLEEP_JITTER`: Random sleep jitter in seconds (default: 0) - Values: 0 (disabled) or any positive integer

### Telemetry Variables (ECS/OpenTelemetry)
- `T1114_002A_ECS_VERSION`: ECS schema version (default: "8.0") - Values: "8.0"/"1.12.0" or any valid ECS version
- `T1114_002A_CORRELATION_ID`: Correlation ID for DAG chaining (default: "auto") - Values: "auto" or any custom string

## Output Files
- `t1114_002a_results.json`: Collection results with Deputy metadata
- `t1114_002a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1114_002A_SILENT_MODE="true"; $env:T1114_002A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1114_002A_POLICY_CHECK="true"; $env:T1114_002A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1114_002A_OUTPUT_MODE="debug"; $env:T1114_002A_VERBOSE_LEVEL="3"; $env:T1114_002A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1114_002A_STEALTH_MODE="true"; $env:T1114_002A_AV_EVASION="true"; $env:T1114_002A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes (Deputy Standard)
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled
