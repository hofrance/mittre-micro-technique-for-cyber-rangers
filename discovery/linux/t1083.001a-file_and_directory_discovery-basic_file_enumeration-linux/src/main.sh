
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1083_001A_DEBUG_MODE="${T1083_001A_DEBUG_MODE:-false}"
    export T1083_001A_TIMEOUT="${T1083_001A_TIMEOUT:-300}"
    export T1083_001A_FALLBACK_MODE="${T1083_001A_FALLBACK_MODE:-simulate}"
    export T1083_001A_OUTPUT_FORMAT="${T1083_001A_OUTPUT_FORMAT:-json}"
    export T1083_001A_POLICY_CHECK="${T1083_001A_POLICY_CHECK:-true}"
    export T1083_001A_MAX_SERVICES="${T1083_001A_MAX_SERVICES:-200}"
    export T1083_001A_INCLUDE_SYSTEM="${T1083_001A_INCLUDE_SYSTEM:-true}"
    export T1083_001A_DETAIL_LEVEL="${T1083_001A_DETAIL_LEVEL:-standard}"
    export T1083_001A_RESOLVE_HOSTNAMES="${T1083_001A_RESOLVE_HOSTNAMES:-true}"
    export T1083_001A_MAX_PROCESSES="${T1083_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1083.001a - File and Directory Discovery: Basic File Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover and enumerate files and directories ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "find" "stat" "ls" "du")
    
    [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  x Missing: $dep"
        done
        echo ""
        echo "INSTALLATION COMMANDS:"
        echo "Ubuntu/Debian: sudo apt-get install -y ${missing_deps[*]}"
        echo "CentOS/RHEL:   sudo dnf install -y ${missing_deps[*]}"
        echo "Arch Linux:    sudo pacman -S ${missing_deps[*]}"
        echo ""
        exit 1
    fi
    
    [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1083_001B_OUTPUT_BASE="${T1083_001B_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1083_001B_TIMEOUT="${T1083_001B_TIMEOUT:-300}"
    export T1083_001B_OUTPUT_MODE="${T1083_001B_OUTPUT_MODE:-simple}"
    export T1083_001B_SILENT_MODE="${T1083_001B_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1083_001B_SCAN_PATHS="${T1083_001B_SCAN_PATHS:-/tmp,/home,/etc}"
    export T1083_001B_MAX_DEPTH="${T1083_001B_MAX_DEPTH:-3}"
    export T1083_001B_MAX_FILES="${T1083_001B_MAX_FILES:-1000}"
    export T1083_001B_INCLUDE_HIDDEN="${T1083_001B_INCLUDE_HIDDEN:-true}"
    export T1083_001B_INCLUDE_PERMISSIONS="${T1083_001B_INCLUDE_PERMISSIONS:-true}"
    export T1083_001B_INCLUDE_SIZES="${T1083_001B_INCLUDE_SIZES:-true}"
    export T1083_001B_INCLUDE_TIMESTAMPS="${T1083_001B_INCLUDE_TIMESTAMPS:-true}"
    export T1083_001B_FILE_PATTERNS="${T1083_001B_FILE_PATTERNS:-*.conf,*.cfg,*.txt,*.log,*.sh,*.py,*.json,*.xml}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1083_001B_OUTPUT_BASE" ]] && { [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1083_001B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1083_001B_OUTPUT_BASE")" ]] && { [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1083_001B_OUTPUT_BASE/T1083_001a_file_enumeration_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{file_listings,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Convert file patterns to find-compatible format
Convert-FilePatterns() {
    local patterns="$1"
    local find_patterns=""
    
    IFS=',' read -ra PATTERN_ARRAY <<< "$patterns"
    for pattern in "${PATTERN_ARRAY[@]}"; do
        if [[ -n "$find_patterns" ]]; then
            find_patterns="$find_patterns -o -name '$pattern'"
        else
            find_patterns="-name '$pattern'"
        fi
    done
    
    echo "$find_patterns"
}

# Discover files in a specific path
Discover-FilesInPath() {
    local path="$1"
    local output_dir="$2"
    local max_depth="$3"
    local max_files="$4"
    local include_hidden="$5"
    local file_patterns="$6"
    
    [[ ! -d "$path" ]] && return 1
    
    local path_name=$(basename "$path" | tr '/' '_')
    local output_file="$output_dir/file_listings/${path_name}_files.json"
    local temp_file=$(mktemp)
    
    # Build find command
    local find_cmd="find '$path' -maxdepth $max_depth -type f"
    
    # Add hidden files filter
    if [[ "$include_hidden" != "true" ]]; then
        find_cmd="$find_cmd ! -name '.*'"
    fi
    
    # Add file patterns if specified
    if [[ -n "$file_patterns" ]]; then
        local patterns=$(Convert-FilePatterns "$file_patterns")
        find_cmd="$find_cmd \\( $patterns \\)"
    fi
    
    # Add output formatting
    find_cmd="$find_cmd -printf '%p|%s|%m|%TY-%Tm-%Td %TH:%TM:%TS|%u|%g\n' | head -n $max_files"
    
    # Execute find command and process results
    local file_count=0
    local files_array=()
    
    while IFS='|' read -r filepath size perms timestamp user group; do
        [[ -z "$filepath" ]] && continue
        
        local file_info=$(cat <<EOF
{
  "path": "$filepath",
  "size_bytes": "$size",
  "permissions": "$perms",
  "modified_time": "$timestamp",
  "owner": "$user",
  "group": "$group",
  "readable": "$([[ -r "$filepath" ]] && echo "true" || echo "false")",
  "writable": "$([[ -w "$filepath" ]] && echo "true" || echo "false")",
  "executable": "$([[ -x "$filepath" ]] && echo "true" || echo "false")"
}
EOF
)
        files_array+=("$file_info")
        ((file_count++))
        
        [[ $file_count -ge $max_files ]] && break
    done < <(eval "$find_cmd" 2>/dev/null)
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "scan_path": "$path",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "max_depth": $max_depth,
  "include_hidden": $include_hidden,
  "file_patterns": "$file_patterns",
  "total_files_found": $file_count,
  "files": [$(IFS=','; echo "${files_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$output_file" 2>/dev/null && {
        [[ "$T1083_001B_SILENT_MODE" != "true" && "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $file_count files in $path" >&2
        echo "$file_count"
    }
}

# Discover directories in a specific path
Discover-DirectoriesInPath() {
    local path="$1"
    local output_dir="$2"
    local max_depth="$3"
    local include_hidden="$4"
    
    [[ ! -d "$path" ]] && return 1
    
    local path_name=$(basename "$path" | tr '/' '_')
    local output_file="$output_dir/file_listings/${path_name}_directories.json"
    
    # Build find command for directories
    local find_cmd="find '$path' -maxdepth $max_depth -type d"
    
    # Add hidden directories filter
    if [[ "$include_hidden" != "true" ]]; then
        find_cmd="$find_cmd ! -name '.*'"
    fi
    
    # Add output formatting
    find_cmd="$find_cmd -printf '%p|%m|%TY-%Tm-%Td %TH:%TM:%TS|%u|%g\n'"
    
    # Execute find command and process results
    local dir_count=0
    local dirs_array=()
    
    while IFS='|' read -r dirpath perms timestamp user group; do
        [[ -z "$dirpath" ]] && continue
        
        local dir_info=$(cat <<EOF
{
  "path": "$dirpath",
  "permissions": "$perms",
  "modified_time": "$timestamp",
  "owner": "$user",
  "group": "$group",
  "readable": "$([[ -r "$dirpath" ]] && echo "true" || echo "false")",
  "writable": "$([[ -w "$dirpath" ]] && echo "true" || echo "false")",
  "executable": "$([[ -x "$dirpath" ]] && echo "true" || echo "false")"
}
EOF
)
        dirs_array+=("$dir_info")
        ((dir_count++))
    done < <(eval "$find_cmd" 2>/dev/null)
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "scan_path": "$path",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "max_depth": $max_depth,
  "include_hidden": $include_hidden,
  "total_directories_found": $dir_count,
  "directories": [$(IFS=','; echo "${dirs_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$output_file" 2>/dev/null && {
        [[ "$T1083_001B_SILENT_MODE" != "true" && "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $dir_count directories in $path" >&2
        echo "$dir_count"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_files=0
    local total_dirs=0
    local scanned_paths=()
    
    [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting file and directory discovery..." >&2
    
    # Parse scan paths
    IFS=',' read -ra PATH_ARRAY <<< "$T1083_001B_SCAN_PATHS"
    
    for path in "${PATH_ARRAY[@]}"; do
        path=$(echo "$path" | xargs)  # Trim whitespace
        [[ -z "$path" ]] && continue
        
        [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Scanning path: $path" >&2
        
        # Discover files
        local file_count=$(Discover-FilesInPath "$path" "$discovery_dir" "$T1083_001B_MAX_DEPTH" "$T1083_001B_MAX_FILES" "$T1083_001B_INCLUDE_HIDDEN" "$T1083_001B_FILE_PATTERNS")
        [[ -n "$file_count" ]] && total_files=$((total_files + file_count))
        
        # Discover directories
        local dir_count=$(Discover-DirectoriesInPath "$path" "$discovery_dir" "$T1083_001B_MAX_DEPTH" "$T1083_001B_INCLUDE_HIDDEN")
        [[ -n "$dir_count" ]] && total_dirs=$((total_dirs + dir_count))
        
        scanned_paths+=("$path")
    done
    
    # Create summary file
    local summary_file="$discovery_dir/file_listings/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1083.001a",
  "technique_name": "File and Directory Discovery: Basic File Enumeration",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scanned_paths": $(printf '%s\n' "${scanned_paths[@]}" | jq -R . | jq -s .),
  "total_paths_scanned": ${#scanned_paths[@]},
  "total_files_discovered": $total_files,
  "total_directories_discovered": $total_dirs,
  "max_depth": $T1083_001B_MAX_DEPTH,
  "include_hidden": $T1083_001B_INCLUDE_HIDDEN,
  "file_patterns": "$T1083_001B_FILE_PATTERNS",
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1083_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_files files and $total_dirs directories across ${#scanned_paths[@]} paths." >&2
    
    return 0
}

# Results processing and output
Process-Results() {
    local discovery_dir="$1"
    
    # Create metadata
    local metadata_file="$discovery_dir/metadata/execution_metadata.json"
    local metadata=$(cat <<EOF
{
  "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "technique_id": "T1083.001a",
  "technique_name": "File and Directory Discovery: Basic File Enumeration",
  "output_mode": "${T1083_001B_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1083_001B_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "scan_configuration": {
    "scan_paths": "$T1083_001B_SCAN_PATHS",
    "max_depth": $T1083_001B_MAX_DEPTH,
    "max_files": $T1083_001B_MAX_FILES,
    "include_hidden": $T1083_001B_INCLUDE_HIDDEN,
    "file_patterns": "$T1083_001B_FILE_PATTERNS"
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] File and directory discovery completed" >&2
            echo "[INFO] Results saved to: $discovery_dir" >&2
            ;;
        "stealth")
            # Minimal output for stealth mode
            ;;
        "none")
            # No output
            ;;
    esac
    
    return 0
}

# Main execution flow
main() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    local discovery_dir=$(Initialize-OutputStructure) || exit 1
    Perform-Discovery "$discovery_dir" || exit 1
    Process-Results "$discovery_dir"
}

main "$@"
