# T1082.001A - System Information Discovery: System Version Check

## Description
This package implements MITRE ATT&CK atomic micro-technique T1082.001A for Linux environments. Discover system version information including kernel details, distribution information, system status, and processor details.

## Technique Details
- **ID**: T1082.001A
- **Name**: System Information Discovery: System Version Check
- **Parent Technique**: T1082
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1082_001B_OUTPUT_BASE="/tmp/mitre_results" && export T1082_001B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: discover system version information ONLY
- Scope: One specific discovery action
- Dependency: Bash + system utilities
- Privilege: User

## Environment variables

- `T1082_001B_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1082_001B_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1082_001B_SILENT_MODE`: `true` | `false`
- `T1082_001B_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1082_001B_INCLUDE_DISTRO_INFO`: `true` | `false`
- `T1082_001B_INCLUDE_HOSTNAME`: `true` | `false`
- `T1082_001B_INCLUDE_KERNEL_INFO`: `true` | `false`
- `T1082_001B_INCLUDE_PROCESSOR_INFO`: `true` | `false`
- `T1082_001B_INCLUDE_SYSTEM_INFO`: `true` | `false`
- `T1082_001B_INCLUDE_UPTIME`: `true` | `false`

## Output Files
- `system_info/kernel_information.json`: Kernel details (name, release, version, architecture)
- `system_info/distribution_information.json`: Distribution details (name, version, codename)
- `system_info/system_information.json`: System status (hostname, uptime, load, timezone)
- `system_info/processor_information.json`: Processor details (model, cores, threads)
- `system_info/discovery_summary.json`: Summary of collected information
- `metadata/execution_metadata.json`: Execution metadata and statistics

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor  
- `bc` - Calculator utility
- `grep` - Text search utility
- `cat` - File concatenation utility
- `uname` - System information utility
- `lsb_release` - LSB release information utility

**Technique-Specific Dependencies:**
- `coreutils` - Basic file, shell and text utilities
- `lsb-release` - Linux Standard Base release information

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc coreutils grep jq lsb-release
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc coreutils grep jq redhat-lsb-core
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc coreutils grep jq lsb-release
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Discovery Capabilities

### Kernel Information
- Kernel name and release version
- Kernel build information
- Machine architecture
- Processor type and hardware platform
- Operating system identifier

### Distribution Information
- Distribution name and version
- Distribution codename
- Full distribution description
- Support for multiple detection methods (lsb_release, /etc/os-release, etc.)

### System Information
- Hostname
- System uptime and load average
- Current time and timezone
- Boot time information

### Processor Information
- Processor model and architecture
- Number of CPU cores
- Number of processor threads
- Hardware platform details

## Example Output

### Kernel Information
```json
{
  "kernel_name": "Linux",
  "kernel_release": "5.15.0-78-generic",
  "kernel_version": "#86-Ubuntu SMP Thu Oct 12 15:02:56 UTC 2023",
  "machine_architecture": "x86_64",
  "processor_type": "x86_64",
  "hardware_platform": "x86_64",
  "operating_system": "GNU/Linux"
}
```

### Distribution Information
```json
{
  "distribution_name": "Ubuntu",
  "distribution_version": "22.04.3",
  "distribution_codename": "jammy",
  "distribution_description": "Ubuntu 22.04.3 LTS"
}
```

### System Information
```json
{
  "hostname": "ubuntu-server",
  "uptime": "up 5 days, 3:42",
  "system_load": "0.52, 0.58, 0.59",
  "current_time": "Mon Dec 18 10:30:15 UTC 2023",
  "timezone": "UTC",
  "boot_time": "2023-12-13 06:48"
}
```

## Security Considerations

### Detection Avoidance
- Use `stealth` mode to minimize console output
- Results are saved to filesystem for later analysis
- No network communication required

### Permission Requirements
- **User level**: Can access most system information
- **No root required**: Standard user privileges sufficient
- **Read-only operations**: No system modifications

### Logging and Monitoring
- System calls may be logged by auditd
- File access to /proc and /etc may be monitored
- Command execution may appear in shell history

## Integration with Other Techniques

### Related Discovery Techniques
- **T1082.002b**: Hardware Information Discovery
- **T1082.003c**: OS Configuration Discovery
- **T1087.001a**: Local Account Enumeration
- **T1016.001a**: System Network Configuration Discovery

### Collection Techniques
- **T1005.001a**: System Configuration Files Collection
- **T1005.002b**: User Home Directories Collection
- **T1005.003c**: Application Configuration Files Collection

## Troubleshooting

### Common Issues
1. **Missing lsb_release**: Install lsb-release package
2. **Permission denied**: Ensure output directory is writable
3. **No distribution info**: Check /etc/os-release file exists
4. **Invalid JSON output**: Verify jq is installed and working

### Debug Mode
Enable debug mode for detailed execution information:
```bash
export T1082_001B_OUTPUT_MODE="debug"
./src/main.sh
```

### Validation
Check generated files for completeness:
```bash
find /tmp/mitre_results -name "*.json" -exec jq . {} \;
```
