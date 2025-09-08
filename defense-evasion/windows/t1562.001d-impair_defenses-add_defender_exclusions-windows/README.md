**Administrator privileges required for this technique**

# T1562.001D - MITRE ATT&CK Impair Defenses: Add Windows Defender Exclusions

## Package Information
- **Technique ID**: T1562.001D
- **Tactic**: TA0005 Defense Evasion
- **Platform**: Windows
- **Type**: inject (Active system modification)
- **Language**: PowerShell

## Description
This package adds comprehensive exclusions to Windows Defender. This is an atomic implementation focusing solely on creating path, extension, process, and IP exclusions to evade detection mechanisms.

## Environment Variables

### Variables used by src/main.ps1 (all `T1562_001_` prefixed)

- `T1562_001_OUTPUT_BASE`: Base output directory (default: C:\temp\mitre_results)
- `T1562_001_DEBUG_MODE`: Enable debug output (default: false)
- `T1562_001_STEALTH_MODE`: Enable stealth mode (default: true)
- `T1562_001_SAFE_MODE`: Enable safe mode simulation (default: false)

### Exclusion Specific (as referenced in src/main.ps1)
- `T1562_001_EXCLUSION_PATHS`: Comma-separated paths to exclude (default: C:\temp,C:\users\public,C:\windows\temp)
- `T1562_001_EXCLUSION_EXTENSIONS`: Comma-separated extensions to exclude (default: .exe,.dll,.ps1,.bat,.tmp)
- `T1562_001_EXCLUSION_PROCESSES`: Comma-separated processes to exclude (default: powershell.exe,cmd.exe,rundll32.exe)
- `T1562_001_EXCLUSION_IPS`: Comma-separated IP ranges to exclude (default: 192.168.1.0/24,10.0.0.0/8)
- `T1562_001_VERIFY_EXCLUSIONS`: Verify exclusions were added (default: true)

All environment variables used by `src/main.ps1` are listed above; if you modify `src/main.ps1`, update this section accordingly.

## Manual Execution

```powershell
powershell -ExecutionPolicy Bypass -File src\main.ps1
```

## Deputy CLI Integration

This package is compatible with Deputy CLI for automated deployment and execution within larger attack chains.

## Output Modes

- **Simple Mode** (default): Realistic attacker tool output
- **Debug Mode**: Comprehensive JSON forensic analysis
- **Stealth Mode**: Silent execution with minimal logging
