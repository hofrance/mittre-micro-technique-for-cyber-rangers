
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1083_001B_DEBUG_MODE="${T1083_001B_DEBUG_MODE:-false}"
    export T1083_001B_TIMEOUT="${T1083_001B_TIMEOUT:-300}"
    export T1083_001B_FALLBACK_MODE="${T1083_001B_FALLBACK_MODE:-simulate}"
    export T1083_001B_OUTPUT_FORMAT="${T1083_001B_OUTPUT_FORMAT:-json}"
    export T1083_001B_POLICY_CHECK="${T1083_001B_POLICY_CHECK:-true}"
    export T1083_001B_MAX_SERVICES="${T1083_001B_MAX_SERVICES:-200}"
    export T1083_001B_INCLUDE_SYSTEM="${T1083_001B_INCLUDE_SYSTEM:-true}"
    export T1083_001B_DETAIL_LEVEL="${T1083_001B_DETAIL_LEVEL:-standard}"
    export T1083_001B_RESOLVE_HOSTNAMES="${T1083_001B_RESOLVE_HOSTNAMES:-true}"
    export T1083_001B_MAX_PROCESSES="${T1083_001B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1083.001a - File and Directory Discovery: File System Enumeration
# MITRE ATT&CK Technique: T1083.001
# Description: Discovers files and directories on the system, including hidden files, recent files, and file system structure

set -euo pipefail

# Default configuration
T1083_001B_OUTPUT_BASE="${T1083_001B_OUTPUT_BASE:-/tmp/mitre_results}"
T1083_001B_OUTPUT_MODE="${T1083_001B_OUTPUT_MODE:-simple}"
T1083_001B_SILENT_MODE="${T1083_001B_SILENT_MODE:-false}"
T1083_001B_TIMEOUT="${T1083_001B_TIMEOUT:-30}"

# Technique-specific configuration
T1083_001B_INCLUDE_HIDDEN_FILES="${T1083_001B_INCLUDE_HIDDEN_FILES:-true}"
T1083_001B_INCLUDE_RECENT_FILES="${T1083_001B_INCLUDE_RECENT_FILES:-true}"
T1083_001B_INCLUDE_SYSTEM_DIRS="${T1083_001B_INCLUDE_SYSTEM_DIRS:-true}"
T1083_001B_INCLUDE_USER_DIRS="${T1083_001B_INCLUDE_USER_DIRS:-true}"
T1083_001B_MAX_DEPTH="${T1083_001B_MAX_DEPTH:-3}"
T1083_001B_FILE_LIMIT="${T1083_001B_FILE_LIMIT:-1000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1083_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1083_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1083_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "find" "ls" "stat" "file" "grep" "head" "tail" "awk" "cut" "tr" "sort" "uniq" "wc")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install jq"
        log_info "  CentOS/RHEL/Fedora: sudo yum install jq"
        log_info "  Arch Linux: sudo pacman -S jq"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1083_001B_INCLUDE_HIDDEN_FILES" "T1083_001B_INCLUDE_RECENT_FILES" 
                     "T1083_001B_INCLUDE_SYSTEM_DIRS" "T1083_001B_INCLUDE_USER_DIRS")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
        fi
    done
    
    # Validate numeric environment variables
    local num_vars=("T1083_001B_MAX_DEPTH" "T1083_001B_FILE_LIMIT")
    
    for var in "${num_vars[@]}"; do
        local value="${!var}"
        if ! [[ "$value" =~ ^[0-9]+$ ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to appropriate value"
            if [[ "$var" == "T1083_001B_MAX_DEPTH" ]]; then
                export "$var=3"
            elif [[ "$var" == "T1083_001B_FILE_LIMIT" ]]; then
                export "$var=1000"
            fi
        fi
    done
    
    log_success "Environment variables loaded successfully"
}

# Step 3: Validate system preconditions
Validate-SystemPreconditions() {
    log_info "Validating system preconditions..."
    
    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "This technique is designed for Linux systems only"
        return 1
    fi
    
    # Check if we have read access to current directory
    if [[ ! -r . ]]; then
        log_error "Cannot read current directory - insufficient permissions"
        return 1
    fi
    
    # Check if jq is working
    if ! echo '{"test": "value"}' | jq -e . >/dev/null 2>&1; then
        log_error "jq is not working properly"
        return 1
    fi
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1083_001B_OUTPUT_BASE}/t1083.001b_file_and_directory_discovery_${timestamp}"
    
    if mkdir -p "$discovery_dir"; then
        log_success "Output directory created: $discovery_dir"
        echo "$discovery_dir"
    else
        log_error "Failed to create output directory: $discovery_dir"
        return 1
    fi
}

# Step 5: Perform discovery
Perform-Discovery() {
    local discovery_dir="$1"
    log_info "Performing file and directory discovery..."
    
    # Discover file system structure
    Discover-FileSystemStructure "$discovery_dir"
    
    # Discover hidden files
    if [[ "$T1083_001B_INCLUDE_HIDDEN_FILES" == "true" ]]; then
        Discover-HiddenFiles "$discovery_dir"
    fi
    
    # Discover recent files
    if [[ "$T1083_001B_INCLUDE_RECENT_FILES" == "true" ]]; then
        Discover-RecentFiles "$discovery_dir"
    fi
    
    # Discover system directories
    if [[ "$T1083_001B_INCLUDE_SYSTEM_DIRS" == "true" ]]; then
        Discover-SystemDirectories "$discovery_dir"
    fi
    
    # Discover user directories
    if [[ "$T1083_001B_INCLUDE_USER_DIRS" == "true" ]]; then
        Discover-UserDirectories "$discovery_dir"
    fi
    
    log_success "File and directory discovery completed"
}

# Discover file system structure
Discover-FileSystemStructure() {
    local discovery_dir="$1"
    log_info "Discovering file system structure..."
    
    local structure_file="${discovery_dir}/file_system_structure.json"
    
    # Collect file system structure information
    local structure_info=$(cat <<EOF
{
  "technique": "T1083.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "file_system_structure": {
    "current_directory": "$(pwd)",
    "home_directory": "$(echo \$HOME)",
    "root_directory": "/",
    "mount_points": $(mount | awk '{print "{\"device\":\""$1"\",\"mount_point\":\""$3"\",\"filesystem\":\""$5"\",\"options\":\""$6"\"}"}' | jq -s .),
    "disk_usage": $(df -h | grep -v '^Filesystem' | awk '{print "{\"filesystem\":\""$1"\",\"size\":\""$2"\",\"used\":\""$3"\",\"available\":\""$4"\",\"use_percent\":\""$5"\",\"mounted_on\":\""$6"\"}"}' | jq -s .),
    "directory_tree": {
      "max_depth": $T1083_001B_MAX_DEPTH,
      "file_limit": $T1083_001B_FILE_LIMIT
    }
  }
}
EOF
)
    
    echo "$structure_info" | jq . > "$structure_file"
    log_success "File system structure saved to: $structure_file"
}

# Discover hidden files
Discover-HiddenFiles() {
    local discovery_dir="$1"
    log_info "Discovering hidden files..."
    
    local hidden_file="${discovery_dir}/hidden_files.json"
    
    # Find hidden files in common locations
    local hidden_files=$(find /home /root /tmp /var/tmp /opt /usr/local -maxdepth 3 -name ".*" -type f 2>/dev/null | head -"$T1083_001B_FILE_LIMIT" | while read -r file; do
        if [[ -r "$file" ]]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            local modified=$(stat -c%Y "$file" 2>/dev/null || echo "0")
            local permissions=$(stat -c%a "$file" 2>/dev/null || echo "000")
            local owner=$(stat -c%U "$file" 2>/dev/null || echo "unknown")
            
            echo "{\"path\":\"$file\",\"size\":$size,\"modified\":$modified,\"permissions\":\"$permissions\",\"owner\":\"$owner\"}"
        fi
    done | jq -s .)
    
    local hidden_info=$(cat <<EOF
{
  "technique": "T1083.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hidden_files": {
    "count": $(echo "$hidden_files" | jq 'length'),
    "files": $hidden_files
  }
}
EOF
)
    
    echo "$hidden_info" | jq . > "$hidden_file"
    log_success "Hidden files saved to: $hidden_file"
}

# Discover recent files
Discover-RecentFiles() {
    local discovery_dir="$1"
    log_info "Discovering recent files..."
    
    local recent_file="${discovery_dir}/recent_files.json"
    
    # Find recently modified files
    local recent_files=$(find /home /root /tmp /var/tmp /opt /usr/local -maxdepth 3 -type f -mtime -7 2>/dev/null | head -"$T1083_001B_FILE_LIMIT" | while read -r file; do
        if [[ -r "$file" ]]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            local modified=$(stat -c%Y "$file" 2>/dev/null || echo "0")
            local permissions=$(stat -c%a "$file" 2>/dev/null || echo "000")
            local owner=$(stat -c%U "$file" 2>/dev/null || echo "unknown")
            local file_type=$(file -b "$file" 2>/dev/null || echo "unknown")
            
            echo "{\"path\":\"$file\",\"size\":$size,\"modified\":$modified,\"permissions\":\"$permissions\",\"owner\":\"$owner\",\"type\":\"$file_type\"}"
        fi
    done | jq -s .)
    
    local recent_info=$(cat <<EOF
{
  "technique": "T1083.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "recent_files": {
    "count": $(echo "$recent_files" | jq 'length'),
    "files": $recent_files
  }
}
EOF
)
    
    echo "$recent_info" | jq . > "$recent_file"
    log_success "Recent files saved to: $recent_file"
}

# Discover system directories
Discover-SystemDirectories() {
    local discovery_dir="$1"
    log_info "Discovering system directories..."
    
    local system_file="${discovery_dir}/system_directories.json"
    
    # Common system directories to check
    local system_dirs=("/etc" "/var" "/usr" "/opt" "/tmp" "/var/tmp" "/proc" "/sys" "/dev" "/boot" "/lib" "/lib64")
    local system_info_array=()
    
    for dir in "${system_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            local file_count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
            local dir_count=$(find "$dir" -maxdepth 1 -type d 2>/dev/null | wc -l)
            local permissions=$(stat -c%a "$dir" 2>/dev/null || echo "000")
            local owner=$(stat -c%U "$dir" 2>/dev/null || echo "unknown")
            
            system_info_array+=("{\"path\":\"$dir\",\"file_count\":$file_count,\"dir_count\":$dir_count,\"permissions\":\"$permissions\",\"owner\":\"$owner\"}")
        fi
    done
    
    local system_info=$(cat <<EOF
{
  "technique": "T1083.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "system_directories": {
    "count": ${#system_dirs[@]},
    "directories": [$(IFS=,; echo "${system_info_array[*]}")]
  }
}
EOF
)
    
    echo "$system_info" | jq . > "$system_file"
    log_success "System directories saved to: $system_file"
}

# Discover user directories
Discover-UserDirectories() {
    local discovery_dir="$1"
    log_info "Discovering user directories..."
    
    local user_file="${discovery_dir}/user_directories.json"
    
    # Get current user's home directory
    local current_user=$(whoami)
    local home_dir=$(echo \$HOME)
    
    # Discover user-specific directories
    local user_dirs=("$home_dir" "/home" "/root")
    local user_info_array=()
    
    for dir in "${user_dirs[@]}"; do
        if [[ -d "$dir" && -r "$dir" ]]; then
            local file_count=$(find "$dir" -maxdepth 2 -type f 2>/dev/null | wc -l)
            local dir_count=$(find "$dir" -maxdepth 2 -type d 2>/dev/null | wc -l)
            local permissions=$(stat -c%a "$dir" 2>/dev/null || echo "000")
            local owner=$(stat -c%U "$dir" 2>/dev/null || echo "unknown")
            
            # Get some interesting files in user directories
            local interesting_files=$(find "$dir" -maxdepth 2 -type f \( -name ".*rc" -o -name ".*profile" -o -name ".*bash*" -o -name ".*ssh*" -o -name ".*config" \) 2>/dev/null | head -10 | jq -R . | jq -s .)
            
            user_info_array+=("{\"path\":\"$dir\",\"file_count\":$file_count,\"dir_count\":$dir_count,\"permissions\":\"$permissions\",\"owner\":\"$owner\",\"interesting_files\":$interesting_files}")
        fi
    done
    
    local user_info=$(cat <<EOF
{
  "technique": "T1083.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "user_directories": {
    "current_user": "$current_user",
    "home_directory": "$home_dir",
    "directories": [$(IFS=,; echo "${user_info_array[*]}")]
  }
}
EOF
)
    
    echo "$user_info" | jq . > "$user_file"
    log_success "User directories saved to: $user_file"
}

# Step 6: Process results
Process-Results() {
    local discovery_dir="$1"
    log_info "Processing discovery results..."
    
    # Create summary file
    local summary_file="${discovery_dir}/summary.json"
    
    # Count files and create summary
    local file_count=$(find "$discovery_dir" -name "*.json" | wc -l)
    
    local summary=$(cat <<EOF
{
  "technique": "T1083.001a",
  "name": "File and Directory Discovery: File System Enumeration",
  "description": "Discovers files and directories on the system, including hidden files, recent files, and file system structure",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "file_system_structure.json",
    "hidden_files.json",
    "recent_files.json",
    "system_directories.json",
    "user_directories.json"
  ],
  "configuration": {
    "include_hidden_files": $T1083_001B_INCLUDE_HIDDEN_FILES,
    "include_recent_files": $T1083_001B_INCLUDE_RECENT_FILES,
    "include_system_dirs": $T1083_001B_INCLUDE_SYSTEM_DIRS,
    "include_user_dirs": $T1083_001B_INCLUDE_USER_DIRS,
    "max_depth": $T1083_001B_MAX_DEPTH,
    "file_limit": $T1083_001B_FILE_LIMIT
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "File and directory discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "File and directory discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            echo "Summary:"
            echo "$summary" | jq .
            ;;
        "stealth")
            # Minimal output
            ;;
        "none")
            # No output
            ;;
        *)
            log_success "File and directory discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
    esac
}

# Main function
main() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    local discovery_dir=$(Initialize-OutputStructure) || exit 1
    Perform-Discovery "$discovery_dir" || exit 1
    Process-Results "$discovery_dir"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
