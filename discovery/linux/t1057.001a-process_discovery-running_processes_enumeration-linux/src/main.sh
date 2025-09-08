
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1057_001A_DEBUG_MODE="${T1057_001A_DEBUG_MODE:-false}"
    export T1057_001A_TIMEOUT="${T1057_001A_TIMEOUT:-300}"
    export T1057_001A_FALLBACK_MODE="${T1057_001A_FALLBACK_MODE:-simulate}"
    export T1057_001A_OUTPUT_FORMAT="${T1057_001A_OUTPUT_FORMAT:-json}"
    export T1057_001A_POLICY_CHECK="${T1057_001A_POLICY_CHECK:-true}"
    export T1057_001A_MAX_SERVICES="${T1057_001A_MAX_SERVICES:-200}"
    export T1057_001A_INCLUDE_SYSTEM="${T1057_001A_INCLUDE_SYSTEM:-true}"
    export T1057_001A_DETAIL_LEVEL="${T1057_001A_DETAIL_LEVEL:-standard}"
    export T1057_001A_RESOLVE_HOSTNAMES="${T1057_001A_RESOLVE_HOSTNAMES:-true}"
    export T1057_001A_MAX_PROCESSES="${T1057_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1057.001a - Process Discovery: Running Processes Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover and enumerate running processes ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "ps" "cat" "awk" "sort")
    
    [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1057_001A_OUTPUT_BASE="${T1057_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1057_001A_TIMEOUT="${T1057_001A_TIMEOUT:-300}"
    export T1057_001A_OUTPUT_MODE="${T1057_001A_OUTPUT_MODE:-simple}"
    export T1057_001A_SILENT_MODE="${T1057_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1057_001A_INCLUDE_SYSTEM_PROCESSES="${T1057_001A_INCLUDE_SYSTEM_PROCESSES:-true}"
    export T1057_001A_INCLUDE_USER_PROCESSES="${T1057_001A_INCLUDE_USER_PROCESSES:-true}"
    export T1057_001A_INCLUDE_PROCESS_TREE="${T1057_001A_INCLUDE_PROCESS_TREE:-true}"
    export T1057_001A_INCLUDE_PROCESS_ENV="${T1057_001A_INCLUDE_PROCESS_ENV:-false}"
    export T1057_001A_INCLUDE_PROCESS_FILES="${T1057_001A_INCLUDE_PROCESS_FILES:-false}"
    export T1057_001A_INCLUDE_PROCESS_NETWORK="${T1057_001A_INCLUDE_PROCESS_NETWORK:-false}"
    export T1057_001A_MAX_PROCESSES="${T1057_001A_MAX_PROCESSES:-1000}"
    export T1057_001A_FILTER_BY_USER="${T1057_001A_FILTER_BY_USER:-}"
    export T1057_001A_FILTER_BY_COMMAND="${T1057_001A_FILTER_BY_COMMAND:-}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1057_001A_OUTPUT_BASE" ]] && { [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1057_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1057_001A_OUTPUT_BASE")" ]] && { [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1057_001A_OUTPUT_BASE/T1057_001a_process_enumeration_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{process_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover running processes
Discover-RunningProcesses() {
    local output_dir="$1"
    local processes_file="$output_dir/process_info/running_processes.json"
    
    local processes_array=()
    local total_processes=0
    
    # Get process list with detailed information
    while IFS=' ' read -r pid ppid user cpu_percent mem_percent vsz rss tty stat start time command; do
        [[ "$pid" == "PID" ]] && continue
        [[ -z "$pid" ]] && continue
        
        # Apply user filter if specified
        if [[ -n "$T1057_001A_FILTER_BY_USER" ]] && [[ "$user" != "$T1057_001A_FILTER_BY_USER" ]]; then
            continue
        fi
        
        # Apply command filter if specified
        if [[ -n "$T1057_001A_FILTER_BY_COMMAND" ]] && ! echo "$command" | grep -q "$T1057_001A_FILTER_BY_COMMAND"; then
            continue
        fi
        
        # Get additional process information
        local process_exe=""
        local process_cwd=""
        local process_args=""
        
        if [[ -r "/proc/$pid/exe" ]]; then
            process_exe=$(readlink "/proc/$pid/exe" 2>/dev/null || echo "")
        fi
        
        if [[ -r "/proc/$pid/cwd" ]]; then
            process_cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "")
        fi
        
        if [[ -r "/proc/$pid/cmdline" ]]; then
            process_args=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' || echo "")
        fi
        
        # Create process object
        local process_info=$(cat <<EOF
{
  "pid": $pid,
  "ppid": $ppid,
  "user": "$user",
  "cpu_percent": "$cpu_percent",
  "memory_percent": "$mem_percent",
  "virtual_memory": "$vsz",
  "resident_memory": "$rss",
  "tty": "$tty",
  "status": "$stat",
  "start_time": "$start",
  "cpu_time": "$time",
  "command": "$command",
  "executable": "$process_exe",
  "working_directory": "$process_cwd",
  "arguments": "$process_args"
}
EOF
)
        processes_array+=("$process_info")
        ((total_processes++))
        
        [[ $total_processes -ge $T1057_001A_MAX_PROCESSES ]] && break
    done < <(ps aux --no-headers 2>/dev/null | sort -k3 -nr)
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "include_system_processes": $T1057_001A_INCLUDE_SYSTEM_PROCESSES,
  "include_user_processes": $T1057_001A_INCLUDE_USER_PROCESSES,
  "filter_by_user": "$T1057_001A_FILTER_BY_USER",
  "filter_by_command": "$T1057_001A_FILTER_BY_COMMAND",
  "max_processes": $T1057_001A_MAX_PROCESSES,
  "total_processes_found": $total_processes,
  "processes": [$(IFS=','; echo "${processes_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$processes_file" 2>/dev/null && {
        [[ "$T1057_001A_SILENT_MODE" != "true" && "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_processes running processes" >&2
        echo "$total_processes"
    }
}

# Discover process tree
Discover-ProcessTree() {
    local output_dir="$1"
    local tree_file="$output_dir/process_info/process_tree.json"
    
    [[ "$T1057_001A_INCLUDE_PROCESS_TREE" != "true" ]] && return 0
    
    local tree_entries=()
    local total_tree_entries=0
    
    # Get process tree using ps
    while IFS=' ' read -r pid ppid user command; do
        [[ "$pid" == "PID" ]] && continue
        [[ -z "$pid" ]] && continue
        
        local tree_entry=$(cat <<EOF
{
  "pid": $pid,
  "ppid": $ppid,
  "user": "$user",
  "command": "$command"
}
EOF
)
        tree_entries+=("$tree_entry")
        ((total_tree_entries++))
        
        [[ $total_tree_entries -ge $T1057_001A_MAX_PROCESSES ]] && break
    done < <(ps -eo pid,ppid,user,comm --no-headers --forest 2>/dev/null | head -$T1057_001A_MAX_PROCESSES)
    
    local tree_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_tree_entries": $total_tree_entries,
  "process_tree": [$(IFS=','; echo "${tree_entries[*]}")]
}
EOF
)
    
    echo "$tree_data" > "$tree_file" 2>/dev/null && {
        [[ "$T1057_001A_SILENT_MODE" != "true" && "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_tree_entries process tree entries" >&2
        echo "$total_tree_entries"
    }
}

# Discover process environment variables
Discover-ProcessEnvironment() {
    local output_dir="$1"
    local env_file="$output_dir/process_info/process_environment.json"
    
    [[ "$T1057_001A_INCLUDE_PROCESS_ENV" != "true" ]] && return 0
    
    local env_entries=()
    local total_env_entries=0
    
    # Get environment variables for current process and a few others
    local sample_pids=($(ps -eo pid --no-headers 2>/dev/null | head -10))
    
    for pid in "${sample_pids[@]}"; do
        if [[ -r "/proc/$pid/environ" ]]; then
            local env_vars=$(cat "/proc/$pid/environ" 2>/dev/null | tr '\0' '\n' | head -20 | jq -R . | jq -s . || echo "[]")
            
            local env_entry=$(cat <<EOF
{
  "pid": $pid,
  "environment_variables": $env_vars
}
EOF
)
            env_entries+=("$env_entry")
            ((total_env_entries++))
            
            [[ $total_env_entries -ge 5 ]] && break  # Limit to 5 processes
        fi
    done
    
    local env_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_env_entries": $total_env_entries,
  "process_environment": [$(IFS=','; echo "${env_entries[*]}")]
}
EOF
)
    
    echo "$env_data" > "$env_file" 2>/dev/null && {
        [[ "$T1057_001A_SILENT_MODE" != "true" && "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered environment for $total_env_entries processes" >&2
        echo "$total_env_entries"
    }
}

# Discover process file descriptors
Discover-ProcessFiles() {
    local output_dir="$1"
    local files_file="$output_dir/process_info/process_files.json"
    
    [[ "$T1057_001A_INCLUDE_PROCESS_FILES" != "true" ]] && return 0
    
    local file_entries=()
    local total_file_entries=0
    
    # Get file descriptors for a few sample processes
    local sample_pids=($(ps -eo pid --no-headers 2>/dev/null | head -5))
    
    for pid in "${sample_pids[@]}"; do
        if [[ -d "/proc/$pid/fd" ]]; then
            local fd_count=$(ls "/proc/$pid/fd" 2>/dev/null | wc -l || echo "0")
            local fd_list=$(ls "/proc/$pid/fd" 2>/dev/null | head -10 | jq -R . | jq -s . || echo "[]")
            
            local file_entry=$(cat <<EOF
{
  "pid": $pid,
  "fd_count": $fd_count,
  "file_descriptors": $fd_list
}
EOF
)
            file_entries+=("$file_entry")
            ((total_file_entries++))
        fi
    done
    
    local files_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_file_entries": $total_file_entries,
  "process_files": [$(IFS=','; echo "${file_entries[*]}")]
}
EOF
)
    
    echo "$files_data" > "$files_file" 2>/dev/null && {
        [[ "$T1057_001A_SILENT_MODE" != "true" && "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered file info for $total_file_entries processes" >&2
        echo "$total_file_entries"
    }
}

# Discover process network connections
Discover-ProcessNetwork() {
    local output_dir="$1"
    local network_file="$output_dir/process_info/process_network.json"
    
    [[ "$T1057_001A_INCLUDE_PROCESS_NETWORK" != "true" ]] && return 0
    
    local network_entries=()
    local total_network_entries=0
    
    # Get network connections using netstat or ss if available
    if command -v ss >/dev/null 2>&1; then
        while IFS=' ' read -r proto recv_q send_q local_addr foreign_addr state pid_program; do
            [[ "$proto" == "Netid" ]] && continue
            [[ -z "$proto" ]] && continue
            
            local pid=$(echo "$pid_program" | grep -o '[0-9]*' | head -1 || echo "")
            [[ -z "$pid" ]] && continue
            
            local network_entry=$(cat <<EOF
{
  "protocol": "$proto",
  "local_address": "$local_addr",
  "foreign_address": "$foreign_addr",
  "state": "$state",
  "pid": "$pid"
}
EOF
)
            network_entries+=("$network_entry")
            ((total_network_entries++))
            
            [[ $total_network_entries -ge 50 ]] && break
        done < <(ss -tuln 2>/dev/null | head -50)
    fi
    
    local network_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_network_entries": $total_network_entries,
  "process_network": [$(IFS=','; echo "${network_entries[*]}")]
}
EOF
)
    
    echo "$network_data" > "$network_file" 2>/dev/null && {
        [[ "$T1057_001A_SILENT_MODE" != "true" && "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered network info for $total_network_entries connections" >&2
        echo "$total_network_entries"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_processes=0
    local total_tree_entries=0
    local total_env_entries=0
    local total_file_entries=0
    local total_network_entries=0
    
    [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting process discovery..." >&2
    
    # Discover different types of process information
    local processes_count=$(Discover-RunningProcesses "$discovery_dir")
    [[ -n "$processes_count" ]] && total_processes=$processes_count
    
    local tree_count=$(Discover-ProcessTree "$discovery_dir")
    [[ -n "$tree_count" ]] && total_tree_entries=$tree_count
    
    local env_count=$(Discover-ProcessEnvironment "$discovery_dir")
    [[ -n "$env_count" ]] && total_env_entries=$env_count
    
    local files_count=$(Discover-ProcessFiles "$discovery_dir")
    [[ -n "$files_count" ]] && total_file_entries=$files_count
    
    local network_count=$(Discover-ProcessNetwork "$discovery_dir")
    [[ -n "$network_count" ]] && total_network_entries=$network_count
    
    # Create summary file
    local summary_file="$discovery_dir/process_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1057.001a",
  "technique_name": "Process Discovery: Running Processes Enumeration",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_processes": $total_processes,
  "total_tree_entries": $total_tree_entries,
  "total_env_entries": $total_env_entries,
  "total_file_entries": $total_file_entries,
  "total_network_entries": $total_network_entries,
  "configuration": {
    "include_system_processes": $T1057_001A_INCLUDE_SYSTEM_PROCESSES,
    "include_user_processes": $T1057_001A_INCLUDE_USER_PROCESSES,
    "include_process_tree": $T1057_001A_INCLUDE_PROCESS_TREE,
    "include_process_env": $T1057_001A_INCLUDE_PROCESS_ENV,
    "include_process_files": $T1057_001A_INCLUDE_PROCESS_FILES,
    "include_process_network": $T1057_001A_INCLUDE_PROCESS_NETWORK,
    "max_processes": $T1057_001A_MAX_PROCESSES,
    "filter_by_user": "$T1057_001A_FILTER_BY_USER",
    "filter_by_command": "$T1057_001A_FILTER_BY_COMMAND"
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1057_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_processes processes, $total_tree_entries tree entries, $total_env_entries env entries, $total_file_entries file entries, $total_network_entries network entries." >&2
    
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
  "technique_id": "T1057.001a",
  "technique_name": "Process Discovery: Running Processes Enumeration",
  "output_mode": "${T1057_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1057_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "include_system_processes": $T1057_001A_INCLUDE_SYSTEM_PROCESSES,
    "include_user_processes": $T1057_001A_INCLUDE_USER_PROCESSES,
    "max_processes": $T1057_001A_MAX_PROCESSES
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${T1057_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Process discovery completed" >&2
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
