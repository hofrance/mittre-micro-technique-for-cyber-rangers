**Administrator privileges required for this technique**

# T1562.001E - MITRE ATT&CK Impair Defenses: Disable Windows Defender Tamper Protection

## Package Information
- **Technique ID**: T1562.001E
- **Tactic**: TA0005 Defense Evasion
- **Platform**: Windows
- **Type**: inject (Active system modification)
- **Language**: PowerShell

## Description
This package disables Windows Defender Tamper Protection specifically. This is an atomic implementation focusing solely on tamper protection mechanisms that prevent unauthorized changes to security settings.

## Environment Variables


### Variables used by src/main.ps1 (all `T1562_001_` prefixed)

- `T1562_001_OUTPUT_BASE`: Base output directory (default: C:\temp\mitre_results)
- `T1562_001_DEBUG_MODE`: Enable debug output (default: false)
- `T1562_001_STEALTH_MODE`: Enable stealth mode (default: true)
- `T1562_001_SAFE_MODE`: Enable safe mode simulation (default: false)

### Tamper Protection Specific (as referenced in src/main.ps1)
- `T1562_001_REGISTRY_METHOD`: Use registry method to disable (default: true)
- `T1562_001_POLICY_METHOD`: Use group policy method (default: false)
- `T1562_001_VERIFY_DISABLE`: Verify tamper protection is disabled (default: true)
- `T1562_001_BACKUP_SETTINGS`: Backup current settings before modification (default: true)
- `T1562_001_FORCE_DISABLE`: Force disable using multiple methods (default: false)

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
