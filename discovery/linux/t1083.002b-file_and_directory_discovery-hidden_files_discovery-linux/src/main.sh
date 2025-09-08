
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1083_002B_DEBUG_MODE="${T1083_002B_DEBUG_MODE:-false}"
    export T1083_002B_TIMEOUT="${T1083_002B_TIMEOUT:-300}"
    export T1083_002B_FALLBACK_MODE="${T1083_002B_FALLBACK_MODE:-simulate}"
    export T1083_002B_OUTPUT_FORMAT="${T1083_002B_OUTPUT_FORMAT:-json}"
    export T1083_002B_POLICY_CHECK="${T1083_002B_POLICY_CHECK:-true}"
    export T1083_002B_MAX_SERVICES="${T1083_002B_MAX_SERVICES:-200}"
    export T1083_002B_INCLUDE_SYSTEM="${T1083_002B_INCLUDE_SYSTEM:-true}"
    export T1083_002B_DETAIL_LEVEL="${T1083_002B_DETAIL_LEVEL:-standard}"
    export T1083_002B_RESOLVE_HOSTNAMES="${T1083_002B_RESOLVE_HOSTNAMES:-true}"
    export T1083_002B_MAX_PROCESSES="${T1083_002B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1083.002b - File and Directory Discovery: Hidden Files Discovery
# MITRE ATT&CK Technique: T1083.002
# Description: Discovers hidden files and directories using various methods including dot files, alternate data streams, and steganography techniques

set -euo pipefail

# Default configuration
T1083_002B_OUTPUT_BASE="${T1083_002B_OUTPUT_BASE:-/tmp/mitre_results}"
T1083_002B_OUTPUT_MODE="${T1083_002B_OUTPUT_MODE:-simple}"
T1083_002B_SILENT_MODE="${T1083_002B_SILENT_MODE:-false}"
T1083_002B_TIMEOUT="${T1083_002B_TIMEOUT:-30}"

# Technique-specific configuration
T1083_002B_INCLUDE_DOT_FILES="${T1083_002B_INCLUDE_DOT_FILES:-true}"
T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES="${T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES:-true}"
T1083_002B_INCLUDE_ALTERNATE_STREAMS="${T1083_002B_INCLUDE_ALTERNATE_STREAMS:-true}"
T1083_002B_INCLUDE_STEGANOGRAPHY="${T1083_002B_INCLUDE_STEGANOGRAPHY:-true}"
T1083_002B_INCLUDE_SYMLINKS="${T1083_002B_INCLUDE_SYMLINKS:-true}"
T1083_002B_SCAN_PATHS="${T1083_002B_SCAN_PATHS:-/home,/tmp,/var,/etc}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1083_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1083_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1083_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "find" "ls" "stat" "file" "strings" "xxd" "cat" "grep" "awk" "cut" "tr")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install jq binutils"
        log_info "  CentOS/RHEL/Fedora: sudo yum install jq binutils"
        log_info "  Arch Linux: sudo pacman -S jq binutils"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1083_002B_INCLUDE_DOT_FILES" "T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES" 
                     "T1083_002B_INCLUDE_ALTERNATE_STREAMS" "T1083_002B_INCLUDE_STEGANOGRAPHY" "T1083_002B_INCLUDE_SYMLINKS")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
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
    
    # Check if scan paths exist
    IFS=',' read -ra PATHS <<< "$T1083_002B_SCAN_PATHS"
    for path in "${PATHS[@]}"; do
        if [[ ! -d "$path" ]]; then
            log_warning "Scan path does not exist: $path"
        fi
    done
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1083_002B_OUTPUT_BASE}/t1083.002b_hidden_files_discovery_${timestamp}"
    
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
    log_info "Performing hidden files discovery..."
    
    # Discover dot files
    if [[ "$T1083_002B_INCLUDE_DOT_FILES" == "true" ]]; then
        Discover-DotFiles "$discovery_dir"
    fi
    
    # Discover hidden attributes
    if [[ "$T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES" == "true" ]]; then
        Discover-HiddenAttributes "$discovery_dir"
    fi
    
    # Discover alternate streams
    if [[ "$T1083_002B_INCLUDE_ALTERNATE_STREAMS" == "true" ]]; then
        Discover-AlternateStreams "$discovery_dir"
    fi
    
    # Discover steganography
    if [[ "$T1083_002B_INCLUDE_STEGANOGRAPHY" == "true" ]]; then
        Discover-Steganography "$discovery_dir"
    fi
    
    # Discover symbolic links
    if [[ "$T1083_002B_INCLUDE_SYMLINKS" == "true" ]]; then
        Discover-Symlinks "$discovery_dir"
    fi
    
    log_success "Hidden files discovery completed"
}

# Discover dot files
Discover-DotFiles() {
    local discovery_dir="$1"
    log_info "Discovering dot files..."
    
    local dot_files_file="${discovery_dir}/dot_files.json"
    local dot_files=()
    
    # Parse scan paths
    IFS=',' read -ra PATHS <<< "$T1083_002B_SCAN_PATHS"
    
    for path in "${PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            log_info "Scanning path: $path"
            
            # Find dot files
            while IFS= read -r -d '' file; do
                local file_info=$(stat -c '{"path":"%n","size":"%s","permissions":"%a","owner":"%U","group":"%G","modified":"%y"}' "$file" 2>/dev/null || echo "{}")
                dot_files+=("$file_info")
            done < <(find "$path" -name ".*" -type f -print0 2>/dev/null | head -100)
        fi
    done
    
    # Create JSON output
    local dot_files_json=$(printf '%s\n' "${dot_files[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1083.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "dot_files": {
    "count": $(echo "$dot_files_json" | jq 'length'),
    "files": $dot_files_json,
    "scan_paths": $(echo "$T1083_002B_SCAN_PATHS" | jq -R . | jq -s .)
  }
}
EOF
)
    
    echo "$result" | jq . > "$dot_files_file"
    log_success "Dot files saved to: $dot_files_file"
}

# Discover hidden attributes
Discover-HiddenAttributes() {
    local discovery_dir="$1"
    log_info "Discovering hidden attributes..."
    
    local hidden_attrs_file="${discovery_dir}/hidden_attributes.json"
    local hidden_files=()
    
    # Parse scan paths
    IFS=',' read -ra PATHS <<< "$T1083_002B_SCAN_PATHS"
    
    for path in "${PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            log_info "Scanning path: $path"
            
            # Find files with hidden attributes
            while IFS= read -r -d '' file; do
                local file_info=$(stat -c '{"path":"%n","size":"%s","permissions":"%a","owner":"%U","group":"%G","modified":"%y","attributes":"%A"}' "$file" 2>/dev/null || echo "{}")
                hidden_files+=("$file_info")
            done < <(find "$path" -type f -exec lsattr {} + 2>/dev/null | grep -E '^[^/]*[hi]' | cut -d' ' -f2 | head -50 | tr '\n' '\0' | xargs -0 -I {} find "$path" -name "{}" -print0 2>/dev/null)
        fi
    done
    
    # Create JSON output
    local hidden_files_json=$(printf '%s\n' "${hidden_files[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1083.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hidden_attributes": {
    "count": $(echo "$hidden_files_json" | jq 'length'),
    "files": $hidden_files_json,
    "scan_paths": $(echo "$T1083_002B_SCAN_PATHS" | jq -R . | jq -s .)
  }
}
EOF
)
    
    echo "$result" | jq . > "$hidden_attrs_file"
    log_success "Hidden attributes saved to: $hidden_attrs_file"
}

# Discover alternate streams
Discover-AlternateStreams() {
    local discovery_dir="$1"
    log_info "Discovering alternate streams..."
    
    local streams_file="${discovery_dir}/alternate_streams.json"
    
    # Linux doesn't have native alternate data streams like Windows
    # But we can check for extended attributes and other metadata
    local streams_info=$(cat <<EOF
{
  "technique": "T1083.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "alternate_streams": {
    "note": "Linux does not support alternate data streams like Windows",
    "extended_attributes": {
      "description": "Extended attributes (xattr) are Linux equivalent",
      "examples": []
    },
    "metadata_files": {
      "description": "Hidden metadata files",
      "examples": [".DS_Store", "Thumbs.db", ".metadata"]
    }
  }
}
EOF
)
    
    echo "$streams_info" | jq . > "$streams_file"
    log_success "Alternate streams info saved to: $streams_file"
}

# Discover steganography
Discover-Steganography() {
    local discovery_dir="$1"
    log_info "Discovering potential steganography..."
    
    local stego_file="${discovery_dir}/steganography.json"
    local stego_files=()
    
    # Parse scan paths
    IFS=',' read -ra PATHS <<< "$T1083_002B_SCAN_PATHS"
    
    for path in "${PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            log_info "Scanning path: $path"
            
            # Find potential steganography files
            while IFS= read -r -d '' file; do
                local file_type=$(file "$file" 2>/dev/null | cut -d: -f2 | xargs)
                local file_size=$(stat -c '%s' "$file" 2>/dev/null || echo "0")
                
                # Check for suspicious patterns
                local strings_output=$(strings "$file" 2>/dev/null | head -10 | tr '\n' ' ' | jq -R .)
                local hex_pattern=$(xxd -l 100 "$file" 2>/dev/null | head -5 | jq -R . | jq -s . || echo '[]')
                
                local file_info=$(cat <<EOF
{
  "path": "$file",
  "type": "$file_type",
  "size": "$file_size",
  "strings": $strings_output,
  "hex_pattern": $hex_pattern
}
EOF
)
                stego_files+=("$file_info")
            done < <(find "$path" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.bmp" -o -name "*.wav" -o -name "*.mp3" \) -size +1M -print0 2>/dev/null | head -20)
        fi
    done
    
    # Create JSON output
    local stego_files_json=$(printf '%s\n' "${stego_files[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1083.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "steganography": {
    "count": $(echo "$stego_files_json" | jq 'length'),
    "files": $stego_files_json,
    "scan_paths": $(echo "$T1083_002B_SCAN_PATHS" | jq -R . | jq -s .)
  }
}
EOF
)
    
    echo "$result" | jq . > "$stego_file"
    log_success "Steganography info saved to: $stego_file"
}

# Discover symbolic links
Discover-Symlinks() {
    local discovery_dir="$1"
    log_info "Discovering symbolic links..."
    
    local symlinks_file="${discovery_dir}/symbolic_links.json"
    local symlinks=()
    
    # Parse scan paths
    IFS=',' read -ra PATHS <<< "$T1083_002B_SCAN_PATHS"
    
    for path in "${PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            log_info "Scanning path: $path"
            
            # Find symbolic links
            while IFS= read -r -d '' link; do
                local target=$(readlink "$link" 2>/dev/null || echo "Unknown")
                local link_info=$(stat -c '{"path":"%n","target":"%N","permissions":"%a","owner":"%U","group":"%G","modified":"%y"}' "$link" 2>/dev/null || echo "{}")
                symlinks+=("$link_info")
            done < <(find "$path" -type l -print0 2>/dev/null | head -50)
        fi
    done
    
    # Create JSON output
    local symlinks_json=$(printf '%s\n' "${symlinks[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1083.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "symbolic_links": {
    "count": $(echo "$symlinks_json" | jq 'length'),
    "links": $symlinks_json,
    "scan_paths": $(echo "$T1083_002B_SCAN_PATHS" | jq -R . | jq -s .)
  }
}
EOF
)
    
    echo "$result" | jq . > "$symlinks_file"
    log_success "Symbolic links saved to: $symlinks_file"
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
  "technique": "T1083.002b",
  "name": "File and Directory Discovery: Hidden Files Discovery",
  "description": "Discovers hidden files and directories using various methods including dot files, alternate data streams, and steganography techniques",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "dot_files.json",
    "hidden_attributes.json",
    "alternate_streams.json",
    "steganography.json",
    "symbolic_links.json"
  ],
  "configuration": {
    "include_dot_files": $T1083_002B_INCLUDE_DOT_FILES,
    "include_hidden_attributes": $T1083_002B_INCLUDE_HIDDEN_ATTRIBUTES,
    "include_alternate_streams": $T1083_002B_INCLUDE_ALTERNATE_STREAMS,
    "include_steganography": $T1083_002B_INCLUDE_STEGANOGRAPHY,
    "include_symlinks": $T1083_002B_INCLUDE_SYMLINKS,
    "scan_paths": "$T1083_002B_SCAN_PATHS"
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Hidden files discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "Hidden files discovery completed successfully"
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
            log_success "Hidden files discovery completed successfully"
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

