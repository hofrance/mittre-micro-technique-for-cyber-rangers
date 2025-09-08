**Administrator privileges required for this technique**

# T1562.001C - MITRE ATT&CK Impair Defenses: Disable Windows Defender Behavior Monitoring

## Package Information
- **Technique ID**: T1562.001C
- **Tactic**: TA0005 Defense Evasion
- **Platform**: Windows
- **Type**: inject (Active system modification)
- **Language**: PowerShell

## Description
This package disables Windows Defender Behavior Monitoring specifically. This is an atomic implementation focusing solely on behavioral analysis and monitoring features, including exploit protection and controlled folder access.

## Environment Variables

### Variables used by src/main.ps1 (all `T1562_001_` prefixed)

- `T1562_001_OUTPUT_BASE`: Base output directory (default: C:\temp\mitre_results)
- `T1562_001_DEBUG_MODE`: Enable debug output (default: false)
- `T1562_001_STEALTH_MODE`: Enable stealth mode (default: true)
- `T1562_001_SAFE_MODE`: Enable safe mode simulation (default: false)

### Behavior Monitoring Specific (as referenced in src/main.ps1)
- `T1562_001_DISABLE_BEHAVIOR_MONITORING`: Disable behavior monitoring (default: true)
- `T1562_001_DISABLE_SCRIPT_SCANNING`: Disable script scanning (default: true)
- `T1562_001_DISABLE_INTRUSION_PREVENTION`: Disable intrusion prevention system (default: true)
- `T1562_001_REGISTRY_BACKUP`: Backup registry before changes (default: false)

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
