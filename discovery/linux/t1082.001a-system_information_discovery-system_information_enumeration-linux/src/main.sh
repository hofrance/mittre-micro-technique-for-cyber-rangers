
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1082_001A_DEBUG_MODE="${T1082_001A_DEBUG_MODE:-false}"
    export T1082_001A_TIMEOUT="${T1082_001A_TIMEOUT:-300}"
    export T1082_001A_FALLBACK_MODE="${T1082_001A_FALLBACK_MODE:-simulate}"
    export T1082_001A_OUTPUT_FORMAT="${T1082_001A_OUTPUT_FORMAT:-json}"
    export T1082_001A_POLICY_CHECK="${T1082_001A_POLICY_CHECK:-true}"
    export T1082_001A_MAX_SERVICES="${T1082_001A_MAX_SERVICES:-200}"
    export T1082_001A_INCLUDE_SYSTEM="${T1082_001A_INCLUDE_SYSTEM:-true}"
    export T1082_001A_DETAIL_LEVEL="${T1082_001A_DETAIL_LEVEL:-standard}"
    export T1082_001A_RESOLVE_HOSTNAMES="${T1082_001A_RESOLVE_HOSTNAMES:-true}"
    export T1082_001A_MAX_PROCESSES="${T1082_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1082.001a - System Information Discovery: System Information Enumeration
# MITRE ATT&CK Technique: T1082.001
# Description: Collects comprehensive system information including OS details, hardware info, system configuration, and environment data

set -euo pipefail

# Default configuration
T1082_001B_OUTPUT_BASE="${T1082_001B_OUTPUT_BASE:-/tmp/mitre_results}"
T1082_001B_OUTPUT_MODE="${T1082_001B_OUTPUT_MODE:-simple}"
T1082_001B_SILENT_MODE="${T1082_001B_SILENT_MODE:-false}"
T1082_001B_TIMEOUT="${T1082_001B_TIMEOUT:-30}"

# Technique-specific configuration
T1082_001B_INCLUDE_HARDWARE="${T1082_001B_INCLUDE_HARDWARE:-true}"
T1082_001B_INCLUDE_OS_DETAILS="${T1082_001B_INCLUDE_OS_DETAILS:-true}"
T1082_001B_INCLUDE_SYSTEM_CONFIG="${T1082_001B_INCLUDE_SYSTEM_CONFIG:-true}"
T1082_001B_INCLUDE_ENVIRONMENT="${T1082_001B_INCLUDE_ENVIRONMENT:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1082_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1082_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1082_001B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "uname" "cat" "grep" "head" "tail" "awk" "cut" "tr" "sort" "uniq")
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
    local bool_vars=("T1082_001B_INCLUDE_HARDWARE" "T1082_001B_INCLUDE_OS_DETAILS" 
                     "T1082_001B_INCLUDE_SYSTEM_CONFIG" "T1082_001B_INCLUDE_ENVIRONMENT")
    
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
    
    # Check if we have read access to system files
    if [[ ! -r /proc/version ]]; then
        log_error "Cannot read /proc/version - insufficient permissions"
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
    local discovery_dir="${T1082_001B_OUTPUT_BASE}/t1082.001b_system_information_discovery_${timestamp}"
    
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
    log_info "Performing system information discovery..."
    
    # Discover OS details
    if [[ "$T1082_001B_INCLUDE_OS_DETAILS" == "true" ]]; then
        Discover-OSDetails "$discovery_dir"
    fi
    
    # Discover hardware information
    if [[ "$T1082_001B_INCLUDE_HARDWARE" == "true" ]]; then
        Discover-HardwareInfo "$discovery_dir"
    fi
    
    # Discover system configuration
    if [[ "$T1082_001B_INCLUDE_SYSTEM_CONFIG" == "true" ]]; then
        Discover-SystemConfig "$discovery_dir"
    fi
    
    # Discover environment information
    if [[ "$T1082_001B_INCLUDE_ENVIRONMENT" == "true" ]]; then
        Discover-EnvironmentInfo "$discovery_dir"
    fi
    
    log_success "System information discovery completed"
}

# Discover OS details
Discover-OSDetails() {
    local discovery_dir="$1"
    log_info "Discovering OS details..."
    
    local os_file="${discovery_dir}/os_details.json"
    
    # Collect OS information
    local os_info=$(cat <<EOF
{
  "technique": "T1082.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "os_details": {
    "kernel": {
      "name": "$(uname -s)",
      "release": "$(uname -r)",
      "version": "$(uname -v)",
      "machine": "$(uname -m)",
      "processor": "$(uname -p)"
    },
    "distribution": {
      "name": "$(cat /etc/os-release 2>/dev/null | grep -E '^NAME=' | cut -d'=' -f2 | tr -d '"' || echo 'Unknown')",
      "version": "$(cat /etc/os-release 2>/dev/null | grep -E '^VERSION=' | cut -d'=' -f2 | tr -d '"' || echo 'Unknown')",
      "id": "$(cat /etc/os-release 2>/dev/null | grep -E '^ID=' | cut -d'=' -f2 | tr -d '"' || echo 'Unknown')"
    },
    "hostname": "$(hostname)",
    "domain": "$(hostname -d 2>/dev/null || echo 'Unknown')",
    "uptime": "$(uptime -p 2>/dev/null || echo 'Unknown')",
    "boot_time": "$(date -d @$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1) 2>/dev/null || echo 'Unknown')",
    "timezone": "$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'Unknown')"
  }
}
EOF
)
    
    echo "$os_info" | jq . > "$os_file"
    log_success "OS details saved to: $os_file"
}

# Discover hardware information
Discover-HardwareInfo() {
    local discovery_dir="$1"
    log_info "Discovering hardware information..."
    
    local hardware_file="${discovery_dir}/hardware_info.json"
    
    # Collect hardware information
    local hardware_info=$(cat <<EOF
{
  "technique": "T1082.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hardware_info": {
    "cpu": {
      "model": "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs || echo 'Unknown')",
      "cores": "$(nproc)",
      "architecture": "$(uname -m)"
    },
    "memory": {
      "total": "$(grep MemTotal /proc/meminfo | awk '{print $2}' || echo 'Unknown')",
      "available": "$(grep MemAvailable /proc/meminfo | awk '{print $2}' || echo 'Unknown')",
      "free": "$(grep MemFree /proc/meminfo | awk '{print $2}' || echo 'Unknown')"
    },
    "disk": {
      "partitions": $(df -h | grep -v '^Filesystem' | awk '{print "{\"filesystem\":\""$1"\",\"size\":\""$2"\",\"used\":\""$3"\",\"available\":\""$4"\",\"use_percent\":\""$5"\",\"mounted_on\":\""$6"\"}"}' | jq -s .),
      "block_devices": $(lsblk -J 2>/dev/null | jq '.blockdevices' || echo '[]')
    },
    "system": {
      "manufacturer": "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'Unknown')",
      "product": "$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')",
      "serial": "$(cat /sys/class/dmi/id/product_serial 2>/dev/null || echo 'Unknown')"
    }
  }
}
EOF
)
    
    echo "$hardware_info" | jq . > "$hardware_file"
    log_success "Hardware information saved to: $hardware_file"
}

# Discover system configuration
Discover-SystemConfig() {
    local discovery_dir="$1"
    log_info "Discovering system configuration..."
    
    local config_file="${discovery_dir}/system_config.json"
    
    # Collect system configuration
    local config_info=$(cat <<EOF
{
  "technique": "T1082.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "system_config": {
    "users": {
      "current_user": "$(whoami)",
      "user_id": "$(id -u)",
      "group_id": "$(id -g)",
      "groups": $(id -Gn | tr ' ' '\n' | jq -R . | jq -s .)
    },
    "limits": {
      "file_descriptors": "$(ulimit -n 2>/dev/null || echo 'Unknown')",
      "processes": "$(ulimit -u 2>/dev/null || echo 'Unknown')"
    },
    "kernel_parameters": {
      "max_files": "$(cat /proc/sys/fs/file-max 2>/dev/null || echo 'Unknown')",
      "max_processes": "$(cat /proc/sys/kernel/pid_max 2>/dev/null || echo 'Unknown')"
    },
    "security": {
      "selinux": "$(getenforce 2>/dev/null || echo 'Disabled')",
      "apparmor": "Available"
    }
  }
}
EOF
)
    
    echo "$config_info" | jq . > "$config_file"
    log_success "System configuration saved to: $config_file"
}

# Discover environment information
Discover-EnvironmentInfo() {
    local discovery_dir="$1"
    log_info "Discovering environment information..."
    
    local env_file="${discovery_dir}/environment_info.json"
    
    # Collect environment information
    local env_info=$(cat <<EOF
{
  "technique": "T1082.001a",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment_info": {
    "environment_variables": {
      "PATH": "$(echo \$PATH)",
      "HOME": "$(echo \$HOME)",
      "USER": "$(echo \$USER)",
      "SHELL": "$(echo \$SHELL)",
      "LANG": "$(echo \$LANG)",
      "PWD": "$(echo \$PWD)"
    },
    "shell_info": {
      "shell": "$(echo \$SHELL)",
      "shell_version": "$(bash --version 2>/dev/null | head -1 || echo 'Unknown')"
    },
    "system_info": {
      "load_average": "$(cat /proc/loadavg | awk '{print $1, $2, $3}' || echo 'Unknown')",
      "processes": "$(cat /proc/stat | grep 'processes' | awk '{print $2}' || echo 'Unknown')",
      "context_switches": "$(cat /proc/stat | grep 'ctxt' | awk '{print $2}' || echo 'Unknown')"
    }
  }
}
EOF
)
    
    echo "$env_info" | jq . > "$env_file"
    log_success "Environment information saved to: $env_file"
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
  "technique": "T1082.001a",
  "name": "System Information Discovery: System Information Enumeration",
  "description": "Comprehensive system information collection including OS details, hardware info, system configuration, and environment data",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "os_details.json",
    "hardware_info.json", 
    "system_config.json",
    "environment_info.json"
  ],
  "configuration": {
    "include_hardware": $T1082_001B_INCLUDE_HARDWARE,
    "include_os_details": $T1082_001B_INCLUDE_OS_DETAILS,
    "include_system_config": $T1082_001B_INCLUDE_SYSTEM_CONFIG,
    "include_environment": $T1082_001B_INCLUDE_ENVIRONMENT
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "System information discovery completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "System information discovery completed successfully"
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
            log_success "System information discovery completed successfully"
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
