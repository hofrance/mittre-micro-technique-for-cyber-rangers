
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1135_001A_DEBUG_MODE="${T1135_001A_DEBUG_MODE:-false}"
    export T1135_001A_TIMEOUT="${T1135_001A_TIMEOUT:-300}"
    export T1135_001A_FALLBACK_MODE="${T1135_001A_FALLBACK_MODE:-simulate}"
    export T1135_001A_OUTPUT_FORMAT="${T1135_001A_OUTPUT_FORMAT:-json}"
    export T1135_001A_POLICY_CHECK="${T1135_001A_POLICY_CHECK:-true}"
    export T1135_001A_MAX_SERVICES="${T1135_001A_MAX_SERVICES:-200}"
    export T1135_001A_INCLUDE_SYSTEM="${T1135_001A_INCLUDE_SYSTEM:-true}"
    export T1135_001A_DETAIL_LEVEL="${T1135_001A_DETAIL_LEVEL:-standard}"
    export T1135_001A_RESOLVE_HOSTNAMES="${T1135_001A_RESOLVE_HOSTNAMES:-true}"
    export T1135_001A_MAX_PROCESSES="${T1135_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1135.001a - Network Share Discovery: SMB/NFS Shares
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover network shares (SMB/NFS) ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "mount" "df" "cat" "awk")
    
    [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1135_001A_OUTPUT_BASE="${T1135_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1135_001A_TIMEOUT="${T1135_001A_TIMEOUT:-300}"
    export T1135_001A_OUTPUT_MODE="${T1135_001A_OUTPUT_MODE:-simple}"
    export T1135_001A_SILENT_MODE="${T1135_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1135_001A_SCAN_TARGETS="${T1135_001A_SCAN_TARGETS:-127.0.0.1,localhost}"
    export T1135_001A_INCLUDE_SMB="${T1135_001A_INCLUDE_SMB:-true}"
    export T1135_001A_INCLUDE_NFS="${T1135_001A_INCLUDE_NFS:-true}"
    export T1135_001A_INCLUDE_MOUNTED_SHARES="${T1135_001A_INCLUDE_MOUNTED_SHARES:-true}"
    export T1135_001A_INCLUDE_SHARE_PERMISSIONS="${T1135_001A_INCLUDE_SHARE_PERMISSIONS:-true}"
    export T1135_001A_MAX_TARGETS="${T1135_001A_MAX_TARGETS:-10}"
    export T1135_001A_MAX_SHARES="${T1135_001A_MAX_SHARES:-50}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1135_001A_OUTPUT_BASE" ]] && { [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1135_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1135_001A_OUTPUT_BASE")" ]] && { [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1135_001A_OUTPUT_BASE/T1135_001a_network_shares_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{share_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover mounted NFS shares
Discover-MountedNFS() {
    local output_dir="$1"
    local nfs_file="$output_dir/share_info/mounted_nfs_shares.json"
    
    [[ "$T1135_001A_INCLUDE_NFS" != "true" ]] && return 0
    
    local nfs_shares=()
    local total_nfs=0
    
    # Get mounted NFS shares
    while IFS=' ' read -r filesystem mount_point fstype options; do
        [[ "$fstype" != "nfs" ]] && continue
        [[ -z "$filesystem" ]] && continue
        
        local server=$(echo "$filesystem" | cut -d':' -f1)
        local share_path=$(echo "$filesystem" | cut -d':' -f2)
        local permissions=""
        
        if [[ "$T1135_001A_INCLUDE_SHARE_PERMISSIONS" == "true" ]]; then
            permissions=$(ls -ld "$mount_point" 2>/dev/null | awk '{print $1}' || echo "unknown")
        fi
        
        local nfs_share=$(cat <<EOF
{
  "server": "$server",
  "share_path": "$share_path",
  "mount_point": "$mount_point",
  "filesystem": "$filesystem",
  "fstype": "$fstype",
  "options": "$options",
  "permissions": "$permissions"
}
EOF
)
        nfs_shares+=("$nfs_share")
        ((total_nfs++))
        
        [[ $total_nfs -ge $T1135_001A_MAX_SHARES ]] && break
    done < <(mount | grep -E "nfs|nfs4" 2>/dev/null)
    
    local nfs_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_nfs_shares": $total_nfs,
  "nfs_shares": [$(IFS=','; echo "${nfs_shares[*]}")]
}
EOF
)
    
    echo "$nfs_data" > "$nfs_file" 2>/dev/null && {
        [[ "$T1135_001A_SILENT_MODE" != "true" && "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_nfs mounted NFS shares" >&2
        echo "$total_nfs"
    }
}

# Discover mounted SMB/CIFS shares
Discover-MountedSMB() {
    local output_dir="$1"
    local smb_file="$output_dir/share_info/mounted_smb_shares.json"
    
    [[ "$T1135_001A_INCLUDE_SMB" != "true" ]] && return 0
    
    local smb_shares=()
    local total_smb=0
    
    # Get mounted SMB/CIFS shares
    while IFS=' ' read -r filesystem mount_point fstype options; do
        [[ "$fstype" != "cifs" ]] && continue
        [[ -z "$filesystem" ]] && continue
        
        local server=$(echo "$filesystem" | cut -d'/' -f3)
        local share_name=$(echo "$filesystem" | cut -d'/' -f4)
        local permissions=""
        
        if [[ "$T1135_001A_INCLUDE_SHARE_PERMISSIONS" == "true" ]]; then
            permissions=$(ls -ld "$mount_point" 2>/dev/null | awk '{print $1}' || echo "unknown")
        fi
        
        local smb_share=$(cat <<EOF
{
  "server": "$server",
  "share_name": "$share_name",
  "mount_point": "$mount_point",
  "filesystem": "$filesystem",
  "fstype": "$fstype",
  "options": "$options",
  "permissions": "$permissions"
}
EOF
)
        smb_shares+=("$smb_share")
        ((total_smb++))
        
        [[ $total_smb -ge $T1135_001A_MAX_SHARES ]] && break
    done < <(mount | grep -E "cifs|smb" 2>/dev/null)
    
    local smb_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_smb_shares": $total_smb,
  "smb_shares": [$(IFS=','; echo "${smb_shares[*]}")]
}
EOF
)
    
    echo "$smb_data" > "$smb_file" 2>/dev/null && {
        [[ "$T1135_001A_SILENT_MODE" != "true" && "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_smb mounted SMB shares" >&2
        echo "$total_smb"
    }
}

# Discover all mounted shares
Discover-AllMountedShares() {
    local output_dir="$1"
    local all_shares_file="$output_dir/share_info/all_mounted_shares.json"
    
    [[ "$T1135_001A_INCLUDE_MOUNTED_SHARES" != "true" ]] && return 0
    
    local all_shares=()
    local total_shares=0
    
    # Get all mounted filesystems
    while IFS=' ' read -r filesystem mount_point fstype options; do
        [[ -z "$filesystem" ]] && continue
        [[ "$mount_point" == "/" ]] && continue  # Skip root filesystem
        
        local share_type="local"
        local server=""
        local share_name=""
        
        # Determine share type
        if [[ "$fstype" == "nfs" ]] || [[ "$fstype" == "nfs4" ]]; then
            share_type="nfs"
            server=$(echo "$filesystem" | cut -d':' -f1)
            share_name=$(echo "$filesystem" | cut -d':' -f2)
        elif [[ "$fstype" == "cifs" ]] || [[ "$fstype" == "smb" ]]; then
            share_type="smb"
            server=$(echo "$filesystem" | cut -d'/' -f3)
            share_name=$(echo "$filesystem" | cut -d'/' -f4)
        fi
        
        local permissions=""
        if [[ "$T1135_001A_INCLUDE_SHARE_PERMISSIONS" == "true" ]]; then
            permissions=$(ls -ld "$mount_point" 2>/dev/null | awk '{print $1}' || echo "unknown")
        fi
        
        local share_info=$(cat <<EOF
{
  "filesystem": "$filesystem",
  "mount_point": "$mount_point",
  "fstype": "$fstype",
  "share_type": "$share_type",
  "server": "$server",
  "share_name": "$share_name",
  "options": "$options",
  "permissions": "$permissions"
}
EOF
)
        all_shares+=("$share_info")
        ((total_shares++))
        
        [[ $total_shares -ge $T1135_001A_MAX_SHARES ]] && break
    done < <(mount | grep -v " / " 2>/dev/null)
    
    local all_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_mounted_shares": $total_shares,
  "mounted_shares": [$(IFS=','; echo "${all_shares[*]}")]
}
EOF
)
    
    echo "$all_data" > "$all_shares_file" 2>/dev/null && {
        [[ "$T1135_001A_SILENT_MODE" != "true" && "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_shares total mounted shares" >&2
        echo "$total_shares"
    }
}

# Discover available NFS exports
Discover-NFSExports() {
    local output_dir="$1"
    local exports_file="$output_dir/share_info/nfs_exports.json"
    
    [[ "$T1135_001A_INCLUDE_NFS" != "true" ]] && return 0
    
    local exports_list=()
    local total_exports=0
    
    # Check for NFS exports file
    if [[ -f "/etc/exports" ]]; then
        while IFS='' read -r line; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue  # Skip comments
            [[ -z "${line// }" ]] && continue  # Skip empty lines
            
            local export_path=$(echo "$line" | awk '{print $1}')
            local export_options=$(echo "$line" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i}')
            
            local export_info=$(cat <<EOF
{
  "export_path": "$export_path",
  "export_options": "$export_options"
}
EOF
)
            exports_list+=("$export_info")
            ((total_exports++))
            
            [[ $total_exports -ge $T1135_001A_MAX_SHARES ]] && break
        done < /etc/exports
    fi
    
    local exports_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_nfs_exports": $total_exports,
  "nfs_exports": [$(IFS=','; echo "${exports_list[*]}")]
}
EOF
)
    
    echo "$exports_data" > "$exports_file" 2>/dev/null && {
        [[ "$T1135_001A_SILENT_MODE" != "true" && "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_exports NFS exports" >&2
        echo "$total_exports"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_nfs_shares=0
    local total_smb_shares=0
    local total_mounted_shares=0
    local total_nfs_exports=0
    
    [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting network share discovery..." >&2
    
    # Discover different types of shares
    local nfs_count=$(Discover-MountedNFS "$discovery_dir")
    [[ -n "$nfs_count" ]] && total_nfs_shares=$nfs_count
    
    local smb_count=$(Discover-MountedSMB "$discovery_dir")
    [[ -n "$smb_count" ]] && total_smb_shares=$smb_count
    
    local mounted_count=$(Discover-AllMountedShares "$discovery_dir")
    [[ -n "$mounted_count" ]] && total_mounted_shares=$mounted_count
    
    local exports_count=$(Discover-NFSExports "$discovery_dir")
    [[ -n "$exports_count" ]] && total_nfs_exports=$exports_count
    
    # Create summary file
    local summary_file="$discovery_dir/share_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1135.001a",
  "technique_name": "Network Share Discovery: SMB/NFS Shares",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_nfs_shares": $total_nfs_shares,
  "total_smb_shares": $total_smb_shares,
  "total_mounted_shares": $total_mounted_shares,
  "total_nfs_exports": $total_nfs_exports,
  "configuration": {
    "scan_targets": "$T1135_001A_SCAN_TARGETS",
    "include_smb": $T1135_001A_INCLUDE_SMB,
    "include_nfs": $T1135_001A_INCLUDE_NFS,
    "include_mounted_shares": $T1135_001A_INCLUDE_MOUNTED_SHARES,
    "include_share_permissions": $T1135_001A_INCLUDE_SHARE_PERMISSIONS,
    "max_targets": $T1135_001A_MAX_TARGETS,
    "max_shares": $T1135_001A_MAX_SHARES
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1135_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_nfs_shares NFS shares, $total_smb_shares SMB shares, $total_mounted_shares mounted shares, $total_nfs_exports NFS exports." >&2
    
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
  "technique_id": "T1135.001a",
  "technique_name": "Network Share Discovery: SMB/NFS Shares",
  "output_mode": "${T1135_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1135_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "scan_targets": "$T1135_001A_SCAN_TARGETS",
    "include_smb": $T1135_001A_INCLUDE_SMB,
    "include_nfs": $T1135_001A_INCLUDE_NFS,
    "max_targets": $T1135_001A_MAX_TARGETS
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${T1135_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Network share discovery completed" >&2
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
