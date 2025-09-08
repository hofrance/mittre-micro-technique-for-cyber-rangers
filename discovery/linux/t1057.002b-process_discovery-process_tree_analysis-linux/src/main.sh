
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1057_002B_DEBUG_MODE="${T1057_002B_DEBUG_MODE:-false}"
    export T1057_002B_TIMEOUT="${T1057_002B_TIMEOUT:-300}"
    export T1057_002B_FALLBACK_MODE="${T1057_002B_FALLBACK_MODE:-simulate}"
    export T1057_002B_OUTPUT_FORMAT="${T1057_002B_OUTPUT_FORMAT:-json}"
    export T1057_002B_POLICY_CHECK="${T1057_002B_POLICY_CHECK:-true}"
    export T1057_002B_MAX_SERVICES="${T1057_002B_MAX_SERVICES:-200}"
    export T1057_002B_INCLUDE_SYSTEM="${T1057_002B_INCLUDE_SYSTEM:-true}"
    export T1057_002B_DETAIL_LEVEL="${T1057_002B_DETAIL_LEVEL:-standard}"
    export T1057_002B_RESOLVE_HOSTNAMES="${T1057_002B_RESOLVE_HOSTNAMES:-true}"
    export T1057_002B_MAX_PROCESSES="${T1057_002B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1057.002b - Process Discovery: Process Tree Analysis
# MITRE ATT&CK Technique: T1057.002
# Description: Analyzes process trees to understand process relationships, parent-child hierarchies, and process spawning patterns

set -euo pipefail

# Default configuration
T1057_002B_OUTPUT_BASE="${T1057_002B_OUTPUT_BASE:-/tmp/mitre_results}"
T1057_002B_OUTPUT_MODE="${T1057_002B_OUTPUT_MODE:-simple}"
T1057_002B_SILENT_MODE="${T1057_002B_SILENT_MODE:-false}"
T1057_002B_TIMEOUT="${T1057_002B_TIMEOUT:-30}"

# Technique-specific configuration
T1057_002B_INCLUDE_PROCESS_TREE="${T1057_002B_INCLUDE_PROCESS_TREE:-true}"
T1057_002B_INCLUDE_PROCESS_RELATIONSHIPS="${T1057_002B_INCLUDE_PROCESS_RELATIONSHIPS:-true}"
T1057_002B_INCLUDE_PROCESS_ENVIRONMENT="${T1057_002B_INCLUDE_PROCESS_ENVIRONMENT:-true}"
T1057_002B_INCLUDE_PROCESS_FILES="${T1057_002B_INCLUDE_PROCESS_FILES:-true}"
T1057_002B_INCLUDE_PROCESS_NETWORK="${T1057_002B_INCLUDE_PROCESS_NETWORK:-true}"
T1057_002B_MAX_DEPTH="${T1057_002B_MAX_DEPTH:-5}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1057_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1057_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1057_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "ps" "pstree" "cat" "grep" "awk" "cut" "tr" "sort" "uniq" "lsof")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_deps[*]}"
        log_info "Installation commands:"
        log_info "  Ubuntu/Debian: sudo apt-get install psmisc lsof"
        log_info "  CentOS/RHEL/Fedora: sudo yum install psmisc lsof"
        log_info "  Arch Linux: sudo pacman -S psmisc lsof"
        return 1
    fi
    
    log_success "All critical dependencies are available"
    return 0
}

# Step 2: Load environment variables
Load-EnvironmentVariables() {
    log_info "Loading environment variables..."
    
    # Validate boolean environment variables
    local bool_vars=("T1057_002B_INCLUDE_PROCESS_TREE" "T1057_002B_INCLUDE_PROCESS_RELATIONSHIPS" 
                     "T1057_002B_INCLUDE_PROCESS_ENVIRONMENT" "T1057_002B_INCLUDE_PROCESS_FILES" "T1057_002B_INCLUDE_PROCESS_NETWORK")
    
    for var in "${bool_vars[@]}"; do
        local value="${!var}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_warning "Invalid value for $var: '$value'. Defaulting to 'true'"
            export "$var=true"
        fi
    done
    
    # Validate max depth
    if ! [[ "$T1057_002B_MAX_DEPTH" =~ ^[0-9]+$ ]] || [[ "$T1057_002B_MAX_DEPTH" -lt 1 ]] || [[ "$T1057_002B_MAX_DEPTH" -gt 10 ]]; then
        log_warning "Invalid max depth: '$T1057_002B_MAX_DEPTH'. Defaulting to '5'"
        export T1057_002B_MAX_DEPTH="5"
    fi
    
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
    
    # Check if /proc is accessible
    if [[ ! -d "/proc" ]]; then
        log_error "/proc filesystem is not accessible"
        return 1
    fi
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1057_002B_OUTPUT_BASE}/t1057.002b_process_tree_analysis_${timestamp}"
    
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
    log_info "Performing process tree analysis..."
    
    # Analyze process tree
    if [[ "$T1057_002B_INCLUDE_PROCESS_TREE" == "true" ]]; then
        Analyze-ProcessTree "$discovery_dir"
    fi
    
    # Analyze process relationships
    if [[ "$T1057_002B_INCLUDE_PROCESS_RELATIONSHIPS" == "true" ]]; then
        Analyze-ProcessRelationships "$discovery_dir"
    fi
    
    # Analyze process environment
    if [[ "$T1057_002B_INCLUDE_PROCESS_ENVIRONMENT" == "true" ]]; then
        Analyze-ProcessEnvironment "$discovery_dir"
    fi
    
    # Analyze process files
    if [[ "$T1057_002B_INCLUDE_PROCESS_FILES" == "true" ]]; then
        Analyze-ProcessFiles "$discovery_dir"
    fi
    
    # Analyze process network
    if [[ "$T1057_002B_INCLUDE_PROCESS_NETWORK" == "true" ]]; then
        Analyze-ProcessNetwork "$discovery_dir"
    fi
    
    log_success "Process tree analysis completed"
}

# Analyze process tree
Analyze-ProcessTree() {
    local discovery_dir="$1"
    log_info "Analyzing process tree..."
    
    local tree_file="${discovery_dir}/process_tree.json"
    local tree_data=()
    
    # Get process tree using pstree
    if command -v pstree &> /dev/null; then
        local pstree_output=$(pstree -p -a -n 2>/dev/null | head -50 | jq -R . | jq -s . || echo '[]')
        
        # Get process tree structure
        local tree_structure=$(pstree -p -a -n 2>/dev/null | head -20 | while read -r line; do
            echo "{\"tree_line\": \"$line\"}"
        done | jq -s . || echo '[]')
        
        tree_data+=("$tree_structure")
    fi
    
    # Get process hierarchy using ps
    local process_hierarchy=$(ps -eo pid,ppid,cmd --no-headers --sort=ppid 2>/dev/null | head -100 | while IFS=' ' read -r pid ppid cmd; do
        echo "{\"pid\": \"$pid\", \"ppid\": \"$ppid\", \"command\": \"$cmd\"}"
    done | jq -s . || echo '[]')
    
    # Create JSON output
    local result=$(cat <<EOF
{
  "technique": "T1057.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "process_tree": {
    "pstree_output": $pstree_output,
    "process_hierarchy": $process_hierarchy,
    "max_depth": "$T1057_002B_MAX_DEPTH",
    "total_processes": $(ps aux 2>/dev/null | wc -l || echo "0")
  }
}
EOF
)
    
    echo "$result" | jq . > "$tree_file"
    log_success "Process tree saved to: $tree_file"
}

# Analyze process relationships
Analyze-ProcessRelationships() {
    local discovery_dir="$1"
    log_info "Analyzing process relationships..."
    
    local relationships_file="${discovery_dir}/process_relationships.json"
    local relationships=()
    
    # Get parent-child relationships
    local parent_child=$(ps -eo pid,ppid,comm --no-headers 2>/dev/null | head -100 | while read -r pid ppid comm; do
        echo "{\"child_pid\": \"$pid\", \"parent_pid\": \"$ppid\", \"command\": \"$comm\"}"
    done | jq -s . || echo '[]')
    
    # Get process groups
    local process_groups=$(ps -eo pid,pgid,comm --no-headers 2>/dev/null | head -100 | while read -r pid pgid comm; do
        echo "{\"pid\": \"$pid\", \"pgid\": \"$pgid\", \"command\": \"$comm\"}"
    done | jq -s . || echo '[]')
    
    # Get session leaders
    local session_leaders=$(ps -eo pid,sid,comm --no-headers 2>/dev/null | head -100 | while read -r pid sid comm; do
        echo "{\"pid\": \"$pid\", \"sid\": \"$sid\", \"command\": \"$comm\"}"
    done | jq -s . || echo '[]')
    
    local result=$(cat <<EOF
{
  "technique": "T1057.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "process_relationships": {
    "parent_child": $parent_child,
    "process_groups": $process_groups,
    "session_leaders": $session_leaders
  }
}
EOF
)
    
    echo "$result" | jq . > "$relationships_file"
    log_success "Process relationships saved to: $relationships_file"
}

# Analyze process environment
Analyze-ProcessEnvironment() {
    local discovery_dir="$1"
    log_info "Analyzing process environment..."
    
    local environment_file="${discovery_dir}/process_environment.json"
    local env_data=()
    
    # Get environment variables for key processes
    local key_processes=("1" "$(pgrep -f systemd 2>/dev/null | head -1)" "$(pgrep -f sshd 2>/dev/null | head -1)")
    
    for pid in "${key_processes[@]}"; do
        if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
            log_info "Analyzing environment for PID: $pid"
            
            # Get process command
            local cmd=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' | jq -R . || echo "null")
            
            # Get environment variables (limited for security)
            local env_vars=$(cat "/proc/$pid/environ" 2>/dev/null | tr '\0' '\n' | grep -E '^(PATH|HOME|USER|SHELL|PWD)=' | head -10 | jq -R . | jq -s . || echo '[]')
            
            local process_env=$(cat <<EOF
{
  "pid": "$pid",
  "command": $cmd,
  "environment_variables": $env_vars
}
EOF
)
            env_data+=("$process_env")
        fi
    done
    
    # Create JSON output
    local env_data_json=$(printf '%s\n' "${env_data[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1057.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "process_environment": {
    "processes": $env_data_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$environment_file"
    log_success "Process environment saved to: $environment_file"
}

# Analyze process files
Analyze-ProcessFiles() {
    local discovery_dir="$1"
    log_info "Analyzing process files..."
    
    local files_file="${discovery_dir}/process_files.json"
    local file_data=()
    
    # Get file descriptors for key processes
    local key_processes=("1" "$(pgrep -f systemd 2>/dev/null | head -1)" "$(pgrep -f sshd 2>/dev/null | head -1)")
    
    for pid in "${key_processes[@]}"; do
        if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
            log_info "Analyzing files for PID: $pid"
            
            # Get process command
            local cmd=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' | jq -R . || echo "null")
            
            # Get open files using lsof
            local open_files=$(lsof -p "$pid" 2>/dev/null | tail -n +2 | head -20 | while read -r comm pid user fd type device size node name; do
                echo "{\"command\": \"$comm\", \"fd\": \"$fd\", \"type\": \"$type\", \"name\": \"$name\"}"
            done | jq -s . || echo '[]')
            
            local process_files=$(cat <<EOF
{
  "pid": "$pid",
  "command": $cmd,
  "open_files": $open_files
}
EOF
)
            file_data+=("$process_files")
        fi
    done
    
    # Create JSON output
    local file_data_json=$(printf '%s\n' "${file_data[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1057.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "process_files": {
    "processes": $file_data_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$files_file"
    log_success "Process files saved to: $files_file"
}

# Analyze process network
Analyze-ProcessNetwork() {
    local discovery_dir="$1"
    log_info "Analyzing process network connections..."
    
    local network_file="${discovery_dir}/process_network.json"
    local network_data=()
    
    # Get network connections for key processes
    local key_processes=("1" "$(pgrep -f systemd 2>/dev/null | head -1)" "$(pgrep -f sshd 2>/dev/null | head -1)")
    
    for pid in "${key_processes[@]}"; do
        if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
            log_info "Analyzing network for PID: $pid"
            
            # Get process command
            local cmd=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' | jq -R . || echo "null")
            
            # Get network connections using lsof
            local network_connections=$(lsof -i -p "$pid" 2>/dev/null | tail -n +2 | head -20 | while read -r comm pid user fd type device size node name; do
                echo "{\"command\": \"$comm\", \"fd\": \"$fd\", \"type\": \"$type\", \"name\": \"$name\"}"
            done | jq -s . || echo '[]')
            
            local process_network=$(cat <<EOF
{
  "pid": "$pid",
  "command": $cmd,
  "network_connections": $network_connections
}
EOF
)
            network_data+=("$process_network")
        fi
    done
    
    # Create JSON output
    local network_data_json=$(printf '%s\n' "${network_data[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1057.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "process_network": {
    "processes": $network_data_json
  }
}
EOF
)
    
    echo "$result" | jq . > "$network_file"
    log_success "Process network saved to: $network_file"
}

# Step 6: Process results
Process-Results() {
    local discovery_dir="$1"
    log_info "Processing discovery results..."
    
    # Create summary file
    local summary_file="${discovery_dir}/summary.json"
    
    # Count files and create summary
    local file_count=$(find "$discovery_dir" -name "*.json" | wc -l)
    
    # Count total processes
    local total_processes=$(ps aux 2>/dev/null | wc -l || echo "0")
    
    local summary=$(cat <<EOF
{
  "technique": "T1057.002b",
  "name": "Process Discovery: Process Tree Analysis",
  "description": "Analyzes process trees to understand process relationships, parent-child hierarchies, and process spawning patterns",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "process_tree.json",
    "process_relationships.json",
    "process_environment.json",
    "process_files.json",
    "process_network.json"
  ],
  "analysis_summary": {
    "total_processes": $total_processes,
    "max_depth_analyzed": "$T1057_002B_MAX_DEPTH"
  },
  "configuration": {
    "include_process_tree": $T1057_002B_INCLUDE_PROCESS_TREE,
    "include_process_relationships": $T1057_002B_INCLUDE_PROCESS_RELATIONSHIPS,
    "include_process_environment": $T1057_002B_INCLUDE_PROCESS_ENVIRONMENT,
    "include_process_files": $T1057_002B_INCLUDE_PROCESS_FILES,
    "include_process_network": $T1057_002B_INCLUDE_PROCESS_NETWORK
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Process tree analysis completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Total processes: $total_processes"
            ;;
        "debug")
            log_success "Process tree analysis completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Total processes: $total_processes"
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
            log_success "Process tree analysis completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            log_info "Total processes: $total_processes"
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

