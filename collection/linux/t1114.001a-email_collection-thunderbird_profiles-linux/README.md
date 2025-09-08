# T1114.001A - Extract Thunderbird Email Profiles

## Description
This package implements MITRE ATT&CK atomic micro-technique T1114.001A for Linux environments. Extract Thunderbird email client profiles and configuration data.

## Technique Details
- **ID**: T1114.001A
- **Name**: Extract Thunderbird Email Profiles
- **Parent Technique**: T1114
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1114_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1114_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: extract Thunderbird profiles ONLY
- Scope: One specific extraction action
- Dependency: Bash + filesystem access
- Privilege: User

## Environment Variables
- `T1114_001A_DATA_TYPES`: Configuration parameter (default: mbox,msf,db,json)
- `T1114_001A_INCLUDE_ATTACHMENTS`: Configuration parameter [true/false] (default: false)
- `T1114_001A_MAX_FILES`: Maximum number of files to process (default: 500)
- `T1114_001A_MAX_FILE_SIZE`: Maximum file size to process (default: 104857600)
- `T1114_001A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1114_001A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1114_001A_PROFILE_PATTERNS`: File patterns to match (default: *.default,*.default-*)
- `T1114_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1114_001A_THUNDERBIRD_PATHS`: Configuration parameter (default: /home/*/.thunderbird,/home/*/.mozilla-thunderbird)
- `T1114_001A_TIMEOUT`: Timeout in seconds (default: 300)

### Universal Variables
- `T1114_001A_T1114_001A_OUTPUT_BASE`: Base directory for results (default: "/tmp/mitre_results")
- `T1114_001A_T1114_001A_TIMEOUT`: Execution timeout in seconds (default: 300)

### T1114.001A Specific Variables
- `T1114_001A_THUNDERBIRD_PATHS`: Thunderbird paths (default: "$HOME/.thunderbird,$HOME/.mozilla-thunderbird")
- `T1114_001A_PROFILE_PATTERNS`: Profile patterns (default: "*.default,*.default-release")
- `T1114_001A_MAX_PROFILE_SIZE`: Maximum profile size MB (default: 100)
- `T1114_001A_INCLUDE_PREFERENCES`: Include prefs.js [true/false] (default: true)
- `T1114_001A_T1114_001A_OUTPUT_MODE`: Output mode simple/debug/stealth (default: "simple")
- `T1114_001A_T1114_001A_SILENT_MODE`: Enable silent execution [true/false] (default: false)

## Output Files
- `t1114_001a_thunderbird_profiles.json`: Profile extraction results with metadata

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
- `thunderbird` - Mozilla email client (optional)
- `evolution` - GNOME email client (optional) 
- `mutt` - Terminal-based email client (optional)
- `postfix` - Mail server (optional)

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc evolution find grep jq mutt postfix thunderbird
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     bash bc evolution find grep jq mutt postfix thunderbird
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc evolution find grep jq mutt postfix thunderbird
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

