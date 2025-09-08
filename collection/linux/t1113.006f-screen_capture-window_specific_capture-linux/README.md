# T1113_006F - Window Specific Capture

## Description
This package implements MITRE ATT&CK atomic micro-technique T1113_006F for Linux environments.

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

## Manual Execution
```bash
export T1113_006F_OUTPUT_BASE="/tmp/mitre_results" && export T1113_006F_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Environment Variables
- `T1113_006F_DISPLAY_TARGET`: Configuration parameter (default: :0)
- `T1113_006F_IMAGE_FORMAT`: Image format [png/jpg/jpeg/bmp] (default: png)
- `T1113_006F_IMAGE_QUALITY`: Configuration parameter (default: 85)
- `T1113_006F_INCLUDE_DECORATIONS`: Configuration parameter [true/false] (default: false)
- `T1113_006F_MAX_WINDOWS`: Configuration parameter (default: 10)
- `T1113_006F_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1113_006F_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1113_006F_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1113_006F_TARGET_WINDOWS`: Configuration parameter (default: auto)
- `T1113_006F_TIMEOUT`: Timeout in seconds (default: 300)
- `T1113_006F_WINDOW_PATTERNS`: Configuration parameter (default: browser,terminal,editor)

## Output
The package will generate results in the specified output directory with standardized Deputy Framework output format.
