**Administrator privileges required for this technique**

# T1562.001B - MITRE ATT&CK Impair Defenses: Disable Windows Defender Cloud Protection

## Package Information
- **Technique ID**: T1562.001B
- **Tactic**: TA0005 Defense Evasion
- **Platform**: Windows
- **Type**: inject (Active system modification)
- **Language**: PowerShell

## Description
This package disables Windows Defender Cloud Protection specifically. This is an atomic implementation focusing solely on cloud-based protection mechanisms, including Microsoft Active Protection Service (MAPS) and cloud-delivered protection features.

## Environment Variables

### Variables used by src/main.ps1 (all `T1562_001_` prefixed)

- `T1562_001_OUTPUT_BASE`: Base output directory (default: C:\temp\mitre_results)
- `T1562_001_DEBUG_MODE`: Enable debug output (default: false)
- `T1562_001_STEALTH_MODE`: Enable stealth mode (default: true)
- `T1562_001_SAFE_MODE`: Enable safe mode simulation (default: false)

### Cloud Protection Specific (as referenced in src/main.ps1)
- `T1562_001_DISABLE_MAPS`: Disable Microsoft Active Protection Service / MAPS (default: true)
- `T1562_001_DISABLE_SAMPLE_SUBMISSION`: Disable automatic sample submission (default: true)
- `T1562_001_BLOCK_ENDPOINTS`: Block cloud endpoints by adding hosts entries (default: false)
- `T1562_001_CLOUD_ENDPOINTS`: Comma-separated cloud endpoints to block (default: "wdcp.microsoft.com,wdcpalt.microsoft.com")

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
