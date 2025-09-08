
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1082_001B_DEBUG_MODE="${T1082_001B_DEBUG_MODE:-false}"
    export T1082_001B_TIMEOUT="${T1082_001B_TIMEOUT:-300}"
    export T1082_001B_FALLBACK_MODE="${T1082_001B_FALLBACK_MODE:-simulate}"
    export T1082_001B_OUTPUT_FORMAT="${T1082_001B_OUTPUT_FORMAT:-json}"
    export T1082_001B_POLICY_CHECK="${T1082_001B_POLICY_CHECK:-true}"
    export T1082_001B_MAX_SERVICES="${T1082_001B_MAX_SERVICES:-200}"
    export T1082_001B_INCLUDE_SYSTEM="${T1082_001B_INCLUDE_SYSTEM:-true}"
    export T1082_001B_DETAIL_LEVEL="${T1082_001B_DETAIL_LEVEL:-standard}"
    export T1082_001B_RESOLVE_HOSTNAMES="${T1082_001B_RESOLVE_HOSTNAMES:-true}"
    export T1082_001B_MAX_PROCESSES="${T1082_001B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1082.001a - System Information Discovery: System Version Check
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover system version information ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "cat" "uname" "lsb_release")
    
    [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1082_001B_OUTPUT_BASE="${T1082_001B_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1082_001B_TIMEOUT="${T1082_001B_TIMEOUT:-300}"
    export T1082_001B_OUTPUT_MODE="${T1082_001B_OUTPUT_MODE:-simple}"
    export T1082_001B_SILENT_MODE="${T1082_001B_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1082_001B_INCLUDE_KERNEL_INFO="${T1082_001B_INCLUDE_KERNEL_INFO:-true}"
    export T1082_001B_INCLUDE_DISTRO_INFO="${T1082_001B_INCLUDE_DISTRO_INFO:-true}"
    export T1082_001B_INCLUDE_SYSTEM_INFO="${T1082_001B_INCLUDE_SYSTEM_INFO:-true}"
    export T1082_001B_INCLUDE_PROCESSOR_INFO="${T1082_001B_INCLUDE_PROCESSOR_INFO:-true}"
    export T1082_001B_INCLUDE_HOSTNAME="${T1082_001B_INCLUDE_HOSTNAME:-true}"
    export T1082_001B_INCLUDE_UPTIME="${T1082_001B_INCLUDE_UPTIME:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1082_001B_OUTPUT_BASE" ]] && { [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1082_001B_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1082_001B_OUTPUT_BASE")" ]] && { [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1082_001B_OUTPUT_BASE/T1082_001a_system_version_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{system_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Kernel information discovery
Discover-KernelInfo() {
    local output_dir="$1"
    local kernel_info_file="$output_dir/system_info/kernel_information.json"
    
    [[ "$T1082_001B_INCLUDE_KERNEL_INFO" != "true" ]] && return 0
    
    local kernel_data=$(cat <<EOF
{
  "kernel_name": "$(uname -s 2>/dev/null || echo "unknown")",
  "kernel_release": "$(uname -r 2>/dev/null || echo "unknown")",
  "kernel_version": "$(uname -v 2>/dev/null || echo "unknown")",
  "machine_architecture": "$(uname -m 2>/dev/null || echo "unknown")",
  "processor_type": "$(uname -p 2>/dev/null || echo "unknown")",
  "hardware_platform": "$(uname -i 2>/dev/null || echo "unknown")",
  "operating_system": "$(uname -o 2>/dev/null || echo "unknown")"
}
EOF
)
    
    echo "$kernel_data" > "$kernel_info_file" 2>/dev/null && {
        [[ "$T1082_001B_SILENT_MODE" != "true" && "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected kernel information" >&2
        echo "kernel_info"
    }
}

# Distribution information discovery
Discover-DistroInfo() {
    local output_dir="$1"
    local distro_info_file="$output_dir/system_info/distribution_information.json"
    
    [[ "$T1082_001B_INCLUDE_DISTRO_INFO" != "true" ]] && return 0
    
    local distro_name="unknown"
    local distro_version="unknown"
    local distro_codename="unknown"
    local distro_description="unknown"
    
    # Try different methods to get distribution info
    if command -v lsb_release >/dev/null 2>&1; then
        distro_name=$(lsb_release -si 2>/dev/null | head -1 || echo "unknown")
        distro_version=$(lsb_release -sr 2>/dev/null | head -1 || echo "unknown")
        distro_codename=$(lsb_release -sc 2>/dev/null | head -1 || echo "unknown")
        distro_description=$(lsb_release -sd 2>/dev/null | head -1 || echo "unknown")
    elif [[ -f /etc/os-release ]]; then
        distro_name=$(grep "^NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 | head -1 || echo "unknown")
        distro_version=$(grep "^VERSION=" /etc/os-release 2>/dev/null | cut -d'"' -f2 | head -1 || echo "unknown")
        distro_codename=$(grep "^VERSION_CODENAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 | head -1 || echo "unknown")
        distro_description=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 | head -1 || echo "unknown")
    elif [[ -f /etc/redhat-release ]]; then
        distro_description=$(cat /etc/redhat-release 2>/dev/null | head -1 || echo "unknown")
        distro_name="RedHat"
    elif [[ -f /etc/debian_version ]]; then
        distro_version=$(cat /etc/debian_version 2>/dev/null | head -1 || echo "unknown")
        distro_name="Debian"
    fi
    
    local distro_data=$(cat <<EOF
{
  "distribution_name": "$distro_name",
  "distribution_version": "$distro_version",
  "distribution_codename": "$distro_codename",
  "distribution_description": "$distro_description"
}
EOF
)
    
    echo "$distro_data" > "$distro_info_file" 2>/dev/null && {
        [[ "$T1082_001B_SILENT_MODE" != "true" && "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected distribution information" >&2
        echo "distro_info"
    }
}

# System information discovery
Discover-SystemInfo() {
    local output_dir="$1"
    local system_info_file="$output_dir/system_info/system_information.json"
    
    [[ "$T1082_001B_INCLUDE_SYSTEM_INFO" != "true" ]] && return 0
    
    local system_data=$(cat <<EOF
{
  "hostname": "$([[ "$T1082_001B_INCLUDE_HOSTNAME" == "true" ]] && hostname 2>/dev/null || echo "not_collected")",
  "uptime": "$([[ "$T1082_001B_INCLUDE_UPTIME" == "true" ]] && uptime 2>/dev/null || echo "not_collected")",
  "system_load": "$(uptime 2>/dev/null | grep -o 'load average:.*' | cut -d':' -f2 | xargs 2>/dev/null || echo "unknown")",
  "current_time": "$(date 2>/dev/null || echo "unknown")",
  "timezone": "$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")",
  "boot_time": "$(who -b 2>/dev/null | awk '{print $3, $4}' || echo "unknown")"
}
EOF
)
    
    echo "$system_data" > "$system_info_file" 2>/dev/null && {
        [[ "$T1082_001B_SILENT_MODE" != "true" && "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected system information" >&2
        echo "system_info"
    }
}

# Processor information discovery
Discover-ProcessorInfo() {
    local output_dir="$1"
    local processor_info_file="$output_dir/system_info/processor_information.json"
    
    [[ "$T1082_001B_INCLUDE_PROCESSOR_INFO" != "true" ]] && return 0
    
    local processor_model="unknown"
    local processor_cores="unknown"
    local processor_threads="unknown"
    local processor_architecture="unknown"
    
    if [[ -f /proc/cpuinfo ]]; then
        processor_model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "unknown")
        processor_cores=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "unknown")
        processor_threads=$(nproc 2>/dev/null || echo "unknown")
        processor_architecture=$(uname -m 2>/dev/null || echo "unknown")
    fi
    
    local processor_data=$(cat <<EOF
{
  "processor_model": "$processor_model",
  "processor_cores": "$processor_cores",
  "processor_threads": "$processor_threads",
  "processor_architecture": "$processor_architecture"
}
EOF
)
    
    echo "$processor_data" > "$processor_info_file" 2>/dev/null && {
        [[ "$T1082_001B_SILENT_MODE" != "true" && "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected processor information" >&2
        echo "processor_info"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local collected_info=()
    
    [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting system version discovery..." >&2
    
    # Discover different types of information
    local kernel_result=$(Discover-KernelInfo "$discovery_dir")
    [[ -n "$kernel_result" ]] && collected_info+=("$kernel_result")
    
    local distro_result=$(Discover-DistroInfo "$discovery_dir")
    [[ -n "$distro_result" ]] && collected_info+=("$distro_result")
    
    local system_result=$(Discover-SystemInfo "$discovery_dir")
    [[ -n "$system_result" ]] && collected_info+=("$system_result")
    
    local processor_result=$(Discover-ProcessorInfo "$discovery_dir")
    [[ -n "$processor_result" ]] && collected_info+=("$processor_result")
    
    # Create summary file
    local summary_file="$discovery_dir/system_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1082.001a",
  "technique_name": "System Information Discovery: System Version Check",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "collected_information_types": $(printf '%s\n' "${collected_info[@]}" | jq -R . | jq -s .),
  "total_information_types": ${#collected_info[@]},
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1082_001B_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Collected ${#collected_info[@]} information types." >&2
    
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
  "technique_id": "T1082.001a",
  "technique_name": "System Information Discovery: System Version Check",
  "output_mode": "${T1082_001B_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1082_001B_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0)
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
            echo "[SUCCESS] System version discovery completed" >&2
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
