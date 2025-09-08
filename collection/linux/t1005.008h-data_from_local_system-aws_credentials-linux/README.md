# T1005.008H - Extract AWS Credentials

## Description
This package implements MITRE ATT&CK atomic micro-technique T1005.008H for Linux environments. Extract AWS (Amazon Web Services) credentials from configuration files and environment.

## Technique Details
- **ID**: T1005.008H
- **Name**: Extract AWS Credentials
- **Parent Technique**: T1005
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1005_008H_OUTPUT_BASE="/tmp/mitre_results" && export T1005_008H_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract AWS credentials ONLY
- Scope: One specific collection action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1005_008H_AWS_PATHS`: Configuration parameter (default: /home/*/.aws,/root/.aws)
- `T1005_008H_CREDENTIAL_FILES`: Configuration parameter (default: credentials,config,cli/cache)
- `T1005_008H_INCLUDE_CACHE`: Configuration parameter [true/false] (default: false)
- `T1005_008H_INCLUDE_PROFILES`: Configuration parameter [true/false] (default: true)
- `T1005_008H_MAX_FILES`: Maximum number of files to process (default: 20)
- `T1005_008H_MAX_FILE_SIZE`: Maximum file size to process (default: 1048576)
- `T1005_008H_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1005_008H_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1005_008H_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1005_008H_TIMEOUT`: Timeout in seconds (default: 300)

## Output Files
- `t1005_008h_aws_credentials.json`: Collection results with metadata

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor  
- `bc` - Calculator utility
- `grep` - Text search utility
- `find` - File search utility

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

