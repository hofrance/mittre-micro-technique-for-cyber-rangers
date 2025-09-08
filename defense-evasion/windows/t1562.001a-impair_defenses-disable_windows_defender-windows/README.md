# T1562.001a - Impair Defenses: Disable Windows Defender

## Overview

### Variables used by src/main.ps1 (all `T1562_001_` prefixed)

- `T1562_001_OUTPUT_BASE`: Base directory for results storage (Default: `C:\temp\mitre_results`)
- `T1562_001_DEBUG_MODE`: Enable debug output mode (Default: `false`)
- `T1562_001_STEALTH_MODE`: Enable stealth output mode (Default: `true`)
- `T1562_001_SAFE_MODE`: Enable safe mode simulation (Default: `false`)

### Defender Components & Bypass Variables (as used in src/main.ps1)
- `T1562_001_REALTIME_PROTECTION`: Real-time protection action (values: `disable` or `enable`) - Default: `disable`
- `T1562_001_CLOUD_PROTECTION`: Cloud protection action (Default: `disable`)
- `T1562_001_AUTOMATIC_SAMPLE_SUBMISSION`: Automatic sample submission action (Default: `disable`)
- `T1562_001_BEHAVIOR_MONITORING`: Behavior monitoring action (Default: `disable`)
- `T1562_001_INTRUSION_PREVENTION`: Intrusion prevention action (Default: `disable`)
- `T1562_001_SCRIPT_SCANNING`: Script scanning action (Default: `disable`)
- `T1562_001_ARCHIVE_SCANNING`: Archive scanning action (Default: `disable`)
- `T1562_001_EMAIL_SCANNING`: Email scanning action (Default: `disable`)
- `T1562_001_REMOVABLE_DRIVE_SCANNING`: Removable drive scanning action (Default: `disable`)

### Bypass method variables
- `T1562_001_BYPASS_METHOD`: Bypass technique (Default: `registry_service_wmi`)
- `T1562_001_TAMPER_PROTECTION_BYPASS`: Tamper Protection bypass method (Default: `trustedinstaller`)
- `T1562_001_REGISTRY_METHOD`: Registry modification method (Default: `direct`)
- `T1562_001_SERVICE_METHOD`: Service modification method (Default: `sc_config`)
- `T1562_001_WMI_METHOD`: WMI namespace to use (Default: `root_microsoft_defender`)

### Exclusions and anti-detection (as referenced in src/main.ps1)
- `T1562_001_ADD_EXCLUSIONS`: Add exclusions before disable (Default: `true`)
- `T1562_001_EXCLUSION_PATHS`: Paths to exclude (Default: `C:\temp,C:\users\public`)
- `T1562_001_EXCLUSION_EXTENSIONS`: File extensions to exclude (Default: `.exe,.dll,.ps1,.bat`)
- `T1562_001_EXCLUSION_PROCESSES`: Processes to exclude (Default: `powershell.exe,cmd.exe`)
- `T1562_001_EXCLUSION_IPS`: IP ranges to exclude (Default: `192.168.1.0/24`)
- `T1562_001_DISABLE_NOTIFICATIONS`: Disable user notifications (Default: `true`)
- `T1562_001_DISABLE_UI_ACCESS`: Disable UI access (Default: `true`)
- `T1562_001_SPOOF_STATUS`: Spoof Defender status (Default: `true`)
- `T1562_001_EVENT_LOG_SUPPRESS`: Suppress event logs (Default: `true`)
- `T1562_001_TIMELINE_CLEANUP`: Clean security timeline (Default: `true`)
- `T1562_001_MSRT_DISABLE`: Disable MSRT (Default: `true`)

All environment variables used by `src/main.ps1` are listed above; if you modify `src/main.ps1`, update this section accordingly.
- `T1562_001_UPDATE_DISABLE`: Disable definition updates (Default: `true`) - **Optional**
- `T1562_001_RECOVERY_PROTECTION`: Prevent automatic recovery (Default: `true`) - **Optional**
- `T1562_001_BACKUP_RESTORE_POINT`: Create restore point (Default: `false`) - **Optional**

## Usage

### PowerShell Example
```powershell
# Set environment variables for comprehensive Defender disable
$env:T1562_001_OUTPUT_BASE = "C:\temp\defender_disable"
$env:T1562_001_REALTIME_PROTECTION = "disable"
$env:T1562_001_CLOUD_PROTECTION = "disable"
$env:T1562_001_TAMPER_PROTECTION_BYPASS = "trustedinstaller"
$env:T1562_001_ADD_EXCLUSIONS = "true"

# Execute package
.\src\main.ps1
```

## Output

### Simple Mode (Default)
Raw, realistic output as an attacker tool would produce, focusing on defender disable status.

### Debug Mode
Comprehensive JSON output for forensic analysis with detailed bypass information.
Enable with: `$env:T1562_001_DEBUG_MODE = "true"`

### Stealth Mode
Minimal or silent output for covert operations.
Enable with: `$env:T1562_001_STEALTH_MODE = "true"`

## Requirements

### System Requirements
- **Platform**: Windows 10/11, Windows Server 2016+
- **Privileges**: Administrator + TrustedInstaller (for Tamper Protection bypass)
- **PowerShell**: 5.0+
- **Dependencies**: Windows Defender installed

### Security Considerations
- **CRITICAL**: This package disables primary system security
- **Irreversible**: Changes may be difficult to undo
- **Detection**: High probability of detection by EDR solutions


## Implementation Details

### MITRE ATT&CK Mapping
- **Technique ID**: T1562.001a
- **Technique Name**: Impair Defenses: Disable or Modify Tools
- **Sub-technique**: Disable Windows Defender
- **Tactic**: TA0005 Defense Evasion
- **Platform**: Windows
- **Data Sources**: Command, Process, Windows Registry, Service
- **Permissions Required**: Administrator

### Atomic Action
This package performs the atomic action of disabling Windows Defender components through multiple bypass techniques including Tamper Protection circumvention.
