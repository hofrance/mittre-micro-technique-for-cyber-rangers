# T1083.001A - File and Directory Discovery: Basic File Enumeration

## Description
This package implements MITRE ATT&CK atomic micro-technique T1083.001A for Linux environments. Discover and enumerate files and directories across specified paths with detailed metadata collection.

## Technique Details
- **ID**: T1083.001A
- **Name**: File and Directory Discovery: Basic File Enumeration
- **Parent Technique**: T1083
- **Tactic**: TA0007 - Discovery
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1083_001B_OUTPUT_BASE="/tmp/mitre_results" && export T1083_001B_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: discover and enumerate files and directories ONLY
- Scope: One specific discovery action
- Dependency: Bash + filesystem utilities
- Privilege: User

## Environment variables

- `T1083_001B_OUTPUT_BASE`: base output path (e.g., `/tmp/mitre_results`)
- `T1083_001B_OUTPUT_MODE`: `simple` | `debug` | `stealth`
- `T1083_001B_SILENT_MODE`: `true` | `false`
- `T1083_001B_TIMEOUT`: timeout in seconds (e.g., `300`)
- `T1083_001B_SCAN_PATHS`: comma-separated list of paths
- `T1083_001B_FILE_PATTERNS`: comma-separated patterns (e.g., `*.log,*.conf`)
- `T1083_001B_MAX_FILES`: integer
- `T1083_001B_MAX_DEPTH`: integer
- `T1083_001B_INCLUDE_HIDDEN`: `true` | `false`
- `T1083_001B_INCLUDE_PERMISSIONS`: `true` | `false`
- `T1083_001B_INCLUDE_SIZES`: `true` | `false`
- `T1083_001B_INCLUDE_TIMESTAMPS`: `true` | `false`

## Output Files
- `file_listings/[path]_files.json`: File listings for each scanned path
- `file_listings/[path]_directories.json`: Directory listings for each scanned path
- `file_listings/discovery_summary.json`: Summary of all discoveries
- `metadata/execution_metadata.json`: Execution metadata and statistics

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor  
- `bc` - Calculator utility
- `grep` - Text search utility
- `find` - File search utility
- `stat` - File status utility
- `ls` - Directory listing utility
- `du` - Disk usage utility

**Technique-Specific Dependencies:**
- `coreutils` - Basic file, shell and text utilities
- `findutils` - File search utilities

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc coreutils find findutils grep jq
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc coreutils find findutils grep jq
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc coreutils find findutils grep jq
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

## Discovery Capabilities

### File Discovery
- File paths and names
- File sizes in bytes
- File permissions (octal and symbolic)
- Modification timestamps
- File ownership (user and group)
- Access permissions (readable, writable, executable)

### Directory Discovery
- Directory paths and names
- Directory permissions
- Modification timestamps
- Directory ownership
- Access permissions

### Configuration Options
- **Scan Paths**: Multiple paths can be specified
- **Depth Control**: Limit directory traversal depth
- **File Patterns**: Filter files by extension/pattern
- **Hidden Files**: Include or exclude hidden files
- **File Limits**: Control maximum files per path

## Example Output

### File Listing
```json
{
  "scan_path": "/etc",
  "scan_timestamp": "2023-12-18T10:30:15Z",
  "max_depth": 3,
  "include_hidden": true,
  "file_patterns": "*.conf,*.cfg,*.txt,*.log,*.sh,*.py,*.json,*.xml",
  "total_files_found": 45,
  "files": [
    {
      "path": "/etc/hosts",
      "size_bytes": "220",
      "permissions": "644",
      "modified_time": "2023-12-13 06:48:00",
      "owner": "root",
      "group": "root",
      "readable": "true",
      "writable": "false",
      "executable": "false"
    }
  ]
}
```

### Directory Listing
```json
{
  "scan_path": "/home",
  "scan_timestamp": "2023-12-18T10:30:15Z",
  "max_depth": 3,
  "include_hidden": true,
  "total_directories_found": 12,
  "directories": [
    {
      "path": "${T1083.001A_OUTPUT_BASE:-/tmp/mitre_results}",
      "permissions": "755",
      "modified_time": "2023-12-13 06:48:00",
      "owner": "user",
      "group": "user",
      "readable": "true",
      "writable": "true",
      "executable": "true"
    }
  ]
}
```

### Discovery Summary
```json
{
  "technique_id": "T1083.001a",
  "technique_name": "File and Directory Discovery: Basic File Enumeration",
  "discovery_timestamp": "2023-12-18T10:30:15Z",
  "scanned_paths": ["/tmp", "/home", "/etc"],
  "total_paths_scanned": 3,
  "total_files_discovered": 156,
  "total_directories_discovered": 23,
  "max_depth": 3,
  "include_hidden": true,
  "file_patterns": "*.conf,*.cfg,*.txt,*.log,*.sh,*.py,*.json,*.xml",
  "discovery_status": "completed"
}
```

## Security Considerations

### Detection Avoidance
- Use `stealth` mode to minimize console output
- Results are saved to filesystem for later analysis
- No network communication required
- Configurable file limits to avoid excessive I/O

### Permission Requirements
- **User level**: Can access files and directories user has permissions for
- **No root required**: Standard user privileges sufficient
- **Read-only operations**: No system modifications

### Logging and Monitoring
- File system access may be logged by auditd
- Directory traversal may be monitored
- Command execution may appear in shell history
- Large file listings may trigger monitoring alerts

## Integration with Other Techniques

### Related Discovery Techniques
- **T1083.002b**: Hidden Files Discovery
- **T1083.003c**: File Permissions Analysis
- **T1082.001a**: System Information Discovery
- **T1087.001a**: Local Account Enumeration

### Collection Techniques
- **T1005.001a**: System Configuration Files Collection
- **T1005.002b**: User Home Directories Collection
- **T1005.003c**: Application Configuration Files Collection

## Advanced Configuration

### Custom File Patterns
```bash
# Scan for specific file types
export T1083_001B_FILE_PATTERNS="*.key,*.pem,*.crt,*.p12,*.db,*.sqlite"

# Scan for configuration files
export T1083_001B_FILE_PATTERNS="*.conf,*.ini,*.cfg,*.yml,*.yaml,*.toml"

# Scan for log files
export T1083_001B_FILE_PATTERNS="*.log,*.out,*.err,*.trace"
```

### Multiple Scan Paths
```bash
# Scan multiple specific paths
export T1083_001B_SCAN_PATHS="/var/log,/opt,/usr/local,/root"

# Scan user directories
export T1083_001B_SCAN_PATHS="/home,/root,/var/www"
```

### Performance Tuning
```bash
# Limit discovery scope for faster execution
export T1083_001B_MAX_DEPTH="2"
export T1083_001B_MAX_FILES="500"
export T1083_001B_INCLUDE_HIDDEN="false"

# Comprehensive discovery
export T1083_001B_MAX_DEPTH="5"
export T1083_001B_MAX_FILES="5000"
export T1083_001B_INCLUDE_HIDDEN="true"
```

## Troubleshooting

### Common Issues
1. **Permission denied**: Some paths may not be accessible
2. **Large file listings**: Adjust MAX_FILES limit
3. **Slow performance**: Reduce MAX_DEPTH or scan fewer paths
4. **Missing files**: Check file patterns and hidden file settings

### Debug Mode
Enable debug mode for detailed execution information:
```bash
export T1083_001B_OUTPUT_MODE="debug"
./src/main.sh
```

### Validation
Check generated files for completeness:
```bash
find /tmp/mitre_results -name "*.json" -exec jq . {} \;
```

### Performance Monitoring
Monitor execution time and resource usage:
```bash
time ./src/main.sh
```
