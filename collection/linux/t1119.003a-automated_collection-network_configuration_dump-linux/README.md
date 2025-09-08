# T1119.003A - Automated network configuration dumping

## Description
This package implements MITRE ATT&CK atomic micro-technique T1119.003A for Linux environments. Automated network configuration dumping

## Technique Details
- **ID**: T1119.003A
- **Name**: Automated network configuration dumping
- **Parent Technique**: T1119
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1119_003A_OUTPUT_BASE="/tmp/mitre_results" && export T1119_003A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: automated network configuration dumping ONLY
- Scope: One specific collection action
- Dependency: Bash + specific utilities
- Privilege: User

## Environment Variables
- `T1119_003A_DUMP_TYPES`: Configuration parameter (default: interfaces,routes,arp,dns,firewall)
- `T1119_003A_INCLUDE_BRIDGES`: Configuration parameter [true/false] (default: true)
- `T1119_003A_INCLUDE_IPTABLES`: Configuration parameter [true/false] (default: true)
- `T1119_003A_INCLUDE_TUNNELS`: Configuration parameter [true/false] (default: true)
- `T1119_003A_INCLUDE_WIRELESS`: Configuration parameter [true/false] (default: true)
- `T1119_003A_MAX_DUMPS`: Configuration parameter (default: 20)
- `T1119_003A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1119_003A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1119_003A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1119_003A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1119_003A_T1119_003A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1119_003A_T1119_003A_TIMEOUT`: Execution timeout in seconds (default: 300)
- `MAX_FILES`: Maximum number of files to process (default: varies)

### T1119.003A Specific Variables
- `T1119_003A_T1119_003A_OUTPUT_MODE`: Configuration parameter (default: "simple")
- `T1119_003A_T1119_003A_SILENT_MODE`: Configuration parameter (default: "false")

## System Requirements
- **Linux Distributions**: Ubuntu/Debian, RHEL/CentOS/Rocky, Fedora, openSUSE, Arch (95%+ compatibility)
- **Bash**: Version 4.0+ (standard on all modern distributions)
- **Core Utilities**: find, stat, grep, awk, sed (pre-installed on all distributions)
- **Permissions**: Appropriate access to target resources
- **Display Server**: X11 or Wayland (for GUI-based techniques)
## Dependencies
- **Universal**: bash, coreutils (find, stat, cat, grep)
- **Technique-specific**: Auto-detected with graceful fallbacks
- **Package managers**: Not required (no installation needed)

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Output Files
- `t1119_003a_collection.json`: Collection results with metadata

## Core Functionality
- Get-EnvironmentVariables: Load ultra-granular configuration
- Initialize-OutputStructure: Create atomic output structure
- Invoke-MicroTechniqueAction: Execute atomic action ONLY
- Write-JsonOutput: Triple-mode output (simple/debug/stealth)
- Get-ExecutionMetadata: Execution metadata collection

## Micro-Technique Family
**Automated Collection Family (T1119.001A→T1119.007G)**

---
