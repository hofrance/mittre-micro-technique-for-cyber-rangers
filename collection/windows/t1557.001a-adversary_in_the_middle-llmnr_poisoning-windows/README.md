# T1557.001A - Adversary-in-the-Middle LLMNR Poisoning

## Overview
This package implements MITRE ATT&CK micro-technique T1557.001A for Windows environments. Adversary-in-the-Middle LLMNR Poisoning with policy-awareness and Deputy compatibility.

## Technique Details
- **ID**: T1557.001A
- **Name**: Adversary-in-the-Middle LLMNR Poisoning
- **Parent Technique**: T1557
- **Tactic**: TA0006 - Credential Access
- **Platform**: Windows
- **Permissions Required**: **User**

## Atomic Action
**Single Observable Action**: network traffic capture and LLMNR/NBT-NS monitoring ONLY
- Scope: One specific collection action
- Dependency: PowerShell + Windows Networking APIs
- Privilege: User

## Environment Variables

### Universal Variables (Deputy Standard)
- `T1557_001A_OUTPUT_BASE`: Base directory for results (default: "$env:TEMP\mitre_results") - Values: any valid directory path
- `T1557_001A_TIMEOUT`: Execution timeout in seconds (default: 300) - Values: any positive integer

### T1557.001A Specific Variables
- `T1557_001A_CAPTURE_DURATION`: Network capture duration in seconds (default: 60) - Values: any positive integer (recommended: 30-300)
- `T1557_001A_CAPTURE_PACKETS`: Enable packet capture (default: true) - Values: true/false
- `T1557_001A_FILTER_PROTOCOLS`: Filter specific network protocols (default: true) - Values: true/false
- `T1557_001A_SAVE_PCAP`: Save captured packets to PCAP file (default: false) - Values: true/false
- `T1557_001A_MONITOR_INTERFACES`: Monitor network interfaces (default: true) - Values: true/false
- `T1557_001A_OUTPUT_MODE`: Output mode (default: "debug") - Values: "simple"/"debug"/"stealth"
- `T1557_001A_SILENT_MODE`: Enable silent execution - ZERO OUTPUT (default: false) - Values: true/false
- `T1557_001A_STEALTH_MODE`: Enable stealth execution (default: false) - Values: true/false



## Output Files
- `t1557_001a_results.json`: Network capture results with Deputy metadata
- `t1557_001a_ecs.json`: ECS-compatible telemetry (debug mode)

## Manual Execution

### Basic Execution
```powershell
# Standard execution with output
powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Silent Mode (Zero Output)
```powershell
# Complete silence - no console output, minimal file output
$env:T1557_001A_SILENT_MODE="true"; $env:T1557_001A_OUTPUT_MODE="stealth"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Policy-Aware Execution
```powershell
# Detect and adapt to Windows policies (GPO/EDR)
$env:T1557_001A_POLICY_CHECK="true"; $env:T1557_001A_FALLBACK_MODE="simulate"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Debug Mode with ECS Telemetry
```powershell
# Full debug output with ECS-compatible telemetry
$env:T1557_001A_OUTPUT_MODE="debug"; $env:T1557_001A_VERBOSE_LEVEL="3"; $env:T1557_001A_ECS_VERSION="8.0"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

### Stealth Execution
```powershell
# Minimal footprint with evasion techniques
$env:T1557_001A_STEALTH_MODE="true"; $env:T1557_001A_AV_EVASION="true"; $env:T1557_001A_OBFUSCATION_LEVEL="2"; powershell -ExecutionPolicy Bypass -File src/main.ps1
```

## Return Codes (Deputy Standard)
- **0**: SUCCESS - Contract fulfilled, postconditions met
- **1**: FAILED - Generic execution failure
- **2**: SKIPPED_PRECONDITION - Prerequisites not met
- **3**: DENIED_POLICY - Blocked by security policy
- **4**: FAILED_POSTCONDITION - Contract not fulfilled
