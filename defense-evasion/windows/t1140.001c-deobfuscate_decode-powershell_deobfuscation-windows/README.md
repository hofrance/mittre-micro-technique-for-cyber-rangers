**Administrator privileges required for this technique**

# T1140.001C - Deobfuscate PowerShell scripts

## Overview
This package implements MITRE ATT&CK atomic micro-technique T1140.001C for Windows environments. Deobfuscate PowerShell scripts.

## Technique Details
- **ID**: T1140.001C
- **Name**: Deobfuscate PowerShell scripts
- **Parent Technique**: t1140
- **Tactic**: TA0005 - Defense Evasion
- **Platform**: Windows
- **Permissions Required**: **User**

## Manual Execution
```powershell
powershell -ExecutionPolicy Bypass -File src\main.ps1
```
