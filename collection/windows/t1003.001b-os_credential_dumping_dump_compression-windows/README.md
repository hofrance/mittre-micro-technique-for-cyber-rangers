# T1003.003A - Os Credential Dumping C Dump Compression

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1003.003A for Windows environments. Os Credential Dumping C Dump Compression with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1003.003A
- **Name**: Os Credential Dumping C Dump Compression
- **Parent Technique**: T1003
- **Tactic**: TA0006 - Credential Access
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: os credential dumping c dump compression ONLY
- Scope: One specific collection action
- Dependency: PowerShell + Windows APIs
- Privilege: User

## Environment Variables

### Universal Variables (Deputy Standard)
- `T1003_003A_OUTPUT_BASE`: Base directory for results (default: "$env:TEMP\mitre_results")
- `T1003_003A_TIMEOUT`: Execution timeout in seconds (default: 300)

### Policy-Awareness Variables (Windows)
- `T1003_003A_POLICY_CHECK`: Check Windows policies before execution (default: true) - Values: true/false
- `T1003_003A_POLICY_BYPASS`: Attempt policy bypass if blocked (default: false) - Values: true/false
- `T1003_003A_POLICY_SIMULATE`: Simulate execution if policy blocks (default: true) - Values: true/false
- `T1003_003A_FALLBACK_MODE`: Fallback mode when policy blocks (default: "simulate") - Values: "simulate"/"skip"/"fail"

### T1003.003A Specific Variables
- `T1003_003A_SOURCE_DUMP`: Source dump file path (default: memory_dump.json) - Values: any valid file path
- `T1003_003A_COMPRESSION_METHOD`: Compression method (default: "zip") - Values: "zip"/"7z"/"gzip"/"tar.gz"
- `T1003_003A_COMPRESSION_LEVEL`: Compression level 1-9 (default: 6) - Values: 1-9 (1=fastest, 9=best compression)
- `T1003_003A_PASSWORD_PROTECT`: Password protect compressed file (default: true) - Values: true/false
- `T1003_003A_DELETE_ORIGINAL`: Delete original file after compression (default: true) - Values: true/false
- `T1003_003A_SPLIT_SIZE_MB`: Split size in MB, 0 = no split (default: 0) - Values: 0 (no split) or any positive integer
- `T1003_003A_OUTPUT_MODE`: Output mode (default: "debug") - Values: "simple"/"debug"/"stealth"
- `T1003_003A_SILENT_MODE`: Enable silent execution - ZERO OUTPUT (default: false) - Values: true/false
- `T1003_003A_SIMULATE_MODE`: Simulate compression if source not found (default: true) - Values: true/false
- `T1003_003A_MAX_COMPRESSION_TIME`: Maximum compression time in seconds (default: 60) - Values: any positive integer

## Output Files
- `t1003_003a_results.json`: Collection results with Deputy metadata
- `t1003_003a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1003_003A_SILENT_MODE="true"; $env:T1003_003A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1003_003A_POLICY_CHECK="true"; $env:T1003_003A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1003_003A_OUTPUT_MODE="debug"; $env:T1003_003A_VERBOSE_LEVEL="3"; $env:T1003_003A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1003_003A_STEALTH_MODE="true"; $env:T1003_003A_AV_EVASION="true"; $env:T1003_003A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes (Deputy Standard)
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled