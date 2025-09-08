
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1087_001A_DEBUG_MODE="${T1087_001A_DEBUG_MODE:-false}"
    export T1087_001A_TIMEOUT="${T1087_001A_TIMEOUT:-300}"
    export T1087_001A_FALLBACK_MODE="${T1087_001A_FALLBACK_MODE:-simulate}"
    export T1087_001A_OUTPUT_FORMAT="${T1087_001A_OUTPUT_FORMAT:-json}"
    export T1087_001A_POLICY_CHECK="${T1087_001A_POLICY_CHECK:-true}"
    export T1087_001A_MAX_SERVICES="${T1087_001A_MAX_SERVICES:-200}"
    export T1087_001A_INCLUDE_SYSTEM="${T1087_001A_INCLUDE_SYSTEM:-true}"
    export T1087_001A_DETAIL_LEVEL="${T1087_001A_DETAIL_LEVEL:-standard}"
    export T1087_001A_RESOLVE_HOSTNAMES="${T1087_001A_RESOLVE_HOSTNAMES:-true}"
    export T1087_001A_MAX_PROCESSES="${T1087_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1087.001a - Account Discovery: Local Account Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover and enumerate local user accounts ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "cat" "cut" "awk" "id" "whoami")
    
    [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1087_001A_OUTPUT_BASE="${T1087_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1087_001A_TIMEOUT="${T1087_001A_TIMEOUT:-300}"
    export T1087_001A_OUTPUT_MODE="${T1087_001A_OUTPUT_MODE:-simple}"
    export T1087_001A_SILENT_MODE="${T1087_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1087_001A_INCLUDE_SYSTEM_ACCOUNTS="${T1087_001A_INCLUDE_SYSTEM_ACCOUNTS:-false}"
    export T1087_001A_INCLUDE_DISABLED_ACCOUNTS="${T1087_001A_INCLUDE_DISABLED_ACCOUNTS:-true}"
    export T1087_001A_INCLUDE_LOCKED_ACCOUNTS="${T1087_001A_INCLUDE_LOCKED_ACCOUNTS:-true}"
    export T1087_001A_INCLUDE_SHELL_INFO="${T1087_001A_INCLUDE_SHELL_INFO:-true}"
    export T1087_001A_INCLUDE_HOME_DIRS="${T1087_001A_INCLUDE_HOME_DIRS:-true}"
    export T1087_001A_INCLUDE_GROUPS="${T1087_001A_INCLUDE_GROUPS:-true}"
    export T1087_001A_INCLUDE_LAST_LOGIN="${T1087_001A_INCLUDE_LAST_LOGIN:-true}"
    export T1087_001A_MIN_UID="${T1087_001A_MIN_UID:-1000}"
    export T1087_001A_MAX_UID="${T1087_001A_MAX_UID:-65535}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1087_001A_OUTPUT_BASE" ]] && { [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] t1087_001a_TT1087.001A_TT1087_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1087_001A_OUTPUT_BASE")" ]] && { [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1087_001A_OUTPUT_BASE/T1087_001a_account_enumeration_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{account_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover user accounts from /etc/passwd
Discover-UserAccounts() {
    local output_dir="$1"
    local accounts_file="$output_dir/account_info/user_accounts.json"
    
    local accounts_array=()
    local total_accounts=0
    
    # Read /etc/passwd and process each line
    while IFS=':' read -r username password uid gid gecos home shell; do
        # Skip system accounts if configured
        if [[ "$T1087_001A_INCLUDE_SYSTEM_ACCOUNTS" != "true" ]] && [[ $uid -lt $T1087_001A_MIN_UID ]]; then
            continue
        fi
        
        # Skip accounts outside UID range
        if [[ $uid -lt $T1087_001A_MIN_UID ]] || [[ $uid -gt $T1087_001A_MAX_UID ]]; then
            continue
        fi
        
        # Check if account is disabled (password field)
        local account_status="active"
        if [[ "$password" == "!" ]] || [[ "$password" == "*" ]]; then
            account_status="disabled"
            [[ "$T1087_001A_INCLUDE_DISABLED_ACCOUNTS" != "true" ]] && continue
        fi
        
        # Check if account is locked
        if [[ "$password" == "!"* ]]; then
            account_status="locked"
            [[ "$T1087_001A_INCLUDE_LOCKED_ACCOUNTS" != "true" ]] && continue
        fi
        
        # Get additional information
        local home_exists="false"
        [[ -d "$home" ]] && home_exists="true"
        
        local shell_exists="false"
        [[ -f "$shell" ]] && shell_exists="true"
        
        local groups=""
        if [[ "$T1087_001A_INCLUDE_GROUPS" == "true" ]]; then
            groups=$(id -Gn "$username" 2>/dev/null | tr ' ' ',' || echo "")
        fi
        
        local last_login="unknown"
        if [[ "$T1087_001A_INCLUDE_LAST_LOGIN" == "true" ]]; then
            if command -v lastlog >/dev/null 2>&1; then
                last_login=$(lastlog -u "$username" 2>/dev/null | tail -n +2 | awk '{print $4, $5, $6, $7}' || echo "unknown")
            fi
        fi
        
        # Create account object
        local account_info=$(cat <<EOF
{
  "username": "$username",
  "uid": $uid,
  "gid": $gid,
  "gecos": "$gecos",
  "home_directory": "$home",
  "shell": "$shell",
  "account_status": "$account_status",
  "home_exists": $home_exists,
  "shell_exists": $shell_exists,
  "groups": "$groups",
  "last_login": "$last_login"
}
EOF
)
        accounts_array+=("$account_info")
        ((total_accounts++))
        
    done < /etc/passwd
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "include_system_accounts": $T1087_001A_INCLUDE_SYSTEM_ACCOUNTS,
  "include_disabled_accounts": $T1087_001A_INCLUDE_DISABLED_ACCOUNTS,
  "include_locked_accounts": $T1087_001A_INCLUDE_LOCKED_ACCOUNTS,
  "uid_range": {
    "min": $T1087_001A_MIN_UID,
    "max": $T1087_001A_MAX_UID
  },
  "total_accounts_found": $total_accounts,
  "accounts": [$(IFS=','; echo "${accounts_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$accounts_file" 2>/dev/null && {
        [[ "$T1087_001A_SILENT_MODE" != "true" && "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_accounts user accounts" >&2
        echo "$total_accounts"
    }
}

# Discover group information
Discover-GroupInformation() {
    local output_dir="$1"
    local groups_file="$output_dir/account_info/group_information.json"
    
    [[ "$T1087_001A_INCLUDE_GROUPS" != "true" ]] && return 0
    
    local groups_array=()
    local total_groups=0
    
    # Read /etc/group and process each line
    while IFS=':' read -r groupname password gid members; do
        # Skip system groups if configured
        if [[ "$T1087_001A_INCLUDE_SYSTEM_ACCOUNTS" != "true" ]] && [[ $gid -lt $T1087_001A_MIN_UID ]]; then
            continue
        fi
        
        # Create group object
        local group_info=$(cat <<EOF
{
  "group_name": "$groupname",
  "gid": $gid,
  "members": "$members"
}
EOF
)
        groups_array+=("$group_info")
        ((total_groups++))
        
    done < /etc/group
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "include_system_groups": $T1087_001A_INCLUDE_SYSTEM_ACCOUNTS,
  "total_groups_found": $total_groups,
  "groups": [$(IFS=','; echo "${groups_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$groups_file" 2>/dev/null && {
        [[ "$T1087_001A_SILENT_MODE" != "true" && "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_groups groups" >&2
        echo "$total_groups"
    }
}

# Discover currently logged in users
Discover-LoggedInUsers() {
    local output_dir="$1"
    local logged_users_file="$output_dir/account_info/logged_in_users.json"
    
    local users_array=()
    local total_logged_users=0
    
    # Get currently logged in users
    while IFS=' ' read -r user terminal host login_time; do
        [[ -z "$user" ]] && continue
        
        # Get additional information
        local user_info=$(id "$user" 2>/dev/null || echo "")
        local uid=$(echo "$user_info" | grep -o 'uid=[0-9]*' | cut -d'=' -f2 || echo "unknown")
        local groups=$(echo "$user_info" | grep -o 'groups=[0-9,]*' | cut -d'=' -f2 | tr ',' ' ' || echo "")
        
        # Create user object
        local user_obj=$(cat <<EOF
{
  "username": "$user",
  "terminal": "$terminal",
  "host": "$host",
  "login_time": "$login_time",
  "uid": "$uid",
  "groups": "$groups"
}
EOF
)
        users_array+=("$user_obj")
        ((total_logged_users++))
        
    done < <(who 2>/dev/null)
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_logged_users": $total_logged_users,
  "users": [$(IFS=','; echo "${users_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$logged_users_file" 2>/dev/null && {
        [[ "$T1087_001A_SILENT_MODE" != "true" && "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_logged_users logged in users" >&2
        echo "$total_logged_users"
    }
}

# Discover sudo privileges
Discover-SudoPrivileges() {
    local output_dir="$1"
    local sudo_file="$output_dir/account_info/sudo_privileges.json"
    
    local sudo_users_array=()
    local total_sudo_users=0
    
    # Check /etc/sudoers and /etc/sudoers.d/* files
    local sudoers_files=("/etc/sudoers")
    
    # Add sudoers.d files if directory exists
    if [[ -d "/etc/sudoers.d" ]]; then
        while IFS= read -r -d '' file; do
            sudoers_files+=("$file")
        done < <(find /etc/sudoers.d -type f -name "*.sudoers" -print0 2>/dev/null)
    fi
    
    # Process each sudoers file
    for sudoers_file in "${sudoers_files[@]}"; do
        [[ ! -f "$sudoers_file" ]] && continue
        
        # Extract user specifications (simplified parsing)
        while IFS='' read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # Look for user specifications
            if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_-]*[[:space:]]+ALL= ]]; then
                local username=$(echo "$line" | awk '{print $1}')
                
                # Check if user exists
                if id "$username" >/dev/null 2>&1; then
                    local user_obj=$(cat <<EOF
{
  "username": "$username",
  "sudoers_file": "$sudoers_file",
  "privilege_line": "$line"
}
EOF
)
                    sudo_users_array+=("$user_obj")
                    ((total_sudo_users++))
                fi
            fi
        done < "$sudoers_file"
    done
    
    # Create JSON output
    local json_output=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_sudo_users": $total_sudo_users,
  "sudo_users": [$(IFS=','; echo "${sudo_users_array[*]}")]
}
EOF
)
    
    echo "$json_output" > "$sudo_file" 2>/dev/null && {
        [[ "$T1087_001A_SILENT_MODE" != "true" && "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_sudo_users sudo users" >&2
        echo "$total_sudo_users"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_accounts=0
    local total_groups=0
    local total_logged_users=0
    local total_sudo_users=0
    
    [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting local account discovery..." >&2
    
    # Discover different types of account information
    local accounts_count=$(Discover-UserAccounts "$discovery_dir")
    [[ -n "$accounts_count" ]] && total_accounts=$accounts_count
    
    local groups_count=$(Discover-GroupInformation "$discovery_dir")
    [[ -n "$groups_count" ]] && total_groups=$groups_count
    
    local logged_count=$(Discover-LoggedInUsers "$discovery_dir")
    [[ -n "$logged_count" ]] && total_logged_users=$logged_count
    
    local sudo_count=$(Discover-SudoPrivileges "$discovery_dir")
    [[ -n "$sudo_count" ]] && total_sudo_users=$sudo_count
    
    # Create summary file
    local summary_file="$discovery_dir/account_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1087.001a",
  "technique_name": "Account Discovery: Local Account Enumeration",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_user_accounts": $total_accounts,
  "total_groups": $total_groups,
  "total_logged_users": $total_logged_users,
  "total_sudo_users": $total_sudo_users,
  "configuration": {
    "include_system_accounts": $T1087_001A_INCLUDE_SYSTEM_ACCOUNTS,
    "include_disabled_accounts": $T1087_001A_INCLUDE_DISABLED_ACCOUNTS,
    "include_locked_accounts": $T1087_001A_INCLUDE_LOCKED_ACCOUNTS,
    "uid_range": {
      "min": $T1087_001A_MIN_UID,
      "max": $T1087_001A_MAX_UID
    }
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1087_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_accounts accounts, $total_groups groups, $total_logged_users logged users, $total_sudo_users sudo users." >&2
    
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
  "technique_id": "T1087.001a",
  "technique_name": "Account Discovery: Local Account Enumeration",
  "output_mode": "${T1087_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1087_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "include_system_accounts": $T1087_001A_INCLUDE_SYSTEM_ACCOUNTS,
    "include_disabled_accounts": $T1087_001A_INCLUDE_DISABLED_ACCOUNTS,
    "include_locked_accounts": $T1087_001A_INCLUDE_LOCKED_ACCOUNTS,
    "uid_range": {
      "min": $T1087_001A_MIN_UID,
      "max": $T1087_001A_MAX_UID
    }
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${TT1087_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] Local account discovery completed" >&2
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
