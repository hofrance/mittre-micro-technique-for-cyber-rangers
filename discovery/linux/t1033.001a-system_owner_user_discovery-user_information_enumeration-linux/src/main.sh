
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1033_001A_DEBUG_MODE="${T1033_001A_DEBUG_MODE:-false}"
    export T1033_001A_TIMEOUT="${T1033_001A_TIMEOUT:-300}"
    export T1033_001A_FALLBACK_MODE="${T1033_001A_FALLBACK_MODE:-simulate}"
    export T1033_001A_OUTPUT_FORMAT="${T1033_001A_OUTPUT_FORMAT:-json}"
    export T1033_001A_POLICY_CHECK="${T1033_001A_POLICY_CHECK:-true}"
    export T1033_001A_MAX_SERVICES="${T1033_001A_MAX_SERVICES:-200}"
    export T1033_001A_INCLUDE_SYSTEM="${T1033_001A_INCLUDE_SYSTEM:-true}"
    export T1033_001A_DETAIL_LEVEL="${T1033_001A_DETAIL_LEVEL:-standard}"
    export T1033_001A_RESOLVE_HOSTNAMES="${T1033_001A_RESOLVE_HOSTNAMES:-true}"
    export T1033_001A_MAX_PROCESSES="${T1033_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1033.001a - System Owner/User Discovery: User Information Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover system owner and user information ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "id" "whoami" "who" "w" "cat" "awk")
    
    [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
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
    
    [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1033_001A_OUTPUT_BASE="${T1033_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1033_001A_TIMEOUT="${T1033_001A_TIMEOUT:-300}"
    export T1033_001A_OUTPUT_MODE="${T1033_001A_OUTPUT_MODE:-simple}"
    export T1033_001A_SILENT_MODE="${T1033_001A_SILENT_MODE:-false}"
    
    # Technique-specific variables
    export T1033_001A_INCLUDE_CURRENT_USER="${T1033_001A_INCLUDE_CURRENT_USER:-true}"
    export T1033_001A_INCLUDE_LOGGED_USERS="${T1033_001A_INCLUDE_LOGGED_USERS:-true}"
    export T1033_001A_INCLUDE_USER_DETAILS="${T1033_001A_INCLUDE_USER_DETAILS:-true}"
    export T1033_001A_INCLUDE_USER_SESSIONS="${T1033_001A_INCLUDE_USER_SESSIONS:-true}"
    export T1033_001A_INCLUDE_USER_GROUPS="${T1033_001A_INCLUDE_USER_GROUPS:-true}"
    export T1033_001A_INCLUDE_USER_HISTORY="${T1033_001A_INCLUDE_USER_HISTORY:-false}"
    export T1033_001A_MAX_USERS="${T1033_001A_MAX_USERS:-50}"
    export T1033_001A_INCLUDE_SYSTEM_USERS="${T1033_001A_INCLUDE_SYSTEM_USERS:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1033_001A_OUTPUT_BASE" ]] && { [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1033_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1033_001A_OUTPUT_BASE")" ]] && { [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1033_001A_OUTPUT_BASE/T1033_001a_user_information_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{user_info,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Discover current user information
Discover-CurrentUser() {
    local output_dir="$1"
    local current_user_file="$output_dir/user_info/current_user.json"
    
    [[ "$T1033_001A_INCLUDE_CURRENT_USER" != "true" ]] && return 0
    
    local current_user=$(whoami 2>/dev/null || echo "unknown")
    local current_uid=$(id -u 2>/dev/null || echo "unknown")
    local current_gid=$(id -g 2>/dev/null || echo "unknown")
    local current_groups=$(id -Gn 2>/dev/null || echo "unknown")
    local current_home=$(echo "$HOME" || echo "unknown")
    local current_shell=$(echo "$SHELL" || echo "unknown")
    
    local current_user_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_user": {
    "username": "$current_user",
    "uid": "$current_uid",
    "gid": "$current_gid",
    "groups": "$current_groups",
    "home_directory": "$current_home",
    "shell": "$current_shell"
  }
}
EOF
)
    
    echo "$current_user_data" > "$current_user_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered current user: $current_user" >&2
        echo "1"
    }
}

# Discover logged in users
Discover-LoggedUsers() {
    local output_dir="$1"
    local logged_users_file="$output_dir/user_info/logged_users.json"
    
    [[ "$T1033_001A_INCLUDE_LOGGED_USERS" != "true" ]] && return 0
    
    local logged_users=()
    local total_logged=0
    
    # Get logged in users using who command
    while IFS=' ' read -r username terminal login_time login_info; do
        [[ -z "$username" ]] && continue
        
        local user_info=$(cat <<EOF
{
  "username": "$username",
  "terminal": "$terminal",
  "login_time": "$login_time",
  "login_info": "$login_info"
}
EOF
)
        logged_users+=("$user_info")
        ((total_logged++))
        
        [[ $total_logged -ge $T1033_001A_MAX_USERS ]] && break
    done < <(who 2>/dev/null)
    
    local logged_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_logged_users": $total_logged,
  "logged_users": [$(IFS=','; echo "${logged_users[*]}")]
}
EOF
)
    
    echo "$logged_data" > "$logged_users_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_logged logged users" >&2
        echo "$total_logged"
    }
}

# Discover user details from /etc/passwd
Discover-UserDetails() {
    local output_dir="$1"
    local user_details_file="$output_dir/user_info/user_details.json"
    
    [[ "$T1033_001A_INCLUDE_USER_DETAILS" != "true" ]] && return 0
    
    local user_details=()
    local total_users=0
    
    # Get user details from /etc/passwd
    while IFS=':' read -r username password uid gid gecos home shell; do
        [[ -z "$username" ]] && continue
        
        # Skip system users if not included
        if [[ "$T1033_001A_INCLUDE_SYSTEM_USERS" != "true" ]] && [[ "$uid" -lt 1000 ]]; then
            continue
        fi
        
        local user_detail=$(cat <<EOF
{
  "username": "$username",
  "uid": "$uid",
  "gid": "$gid",
  "gecos": "$gecos",
  "home_directory": "$home",
  "shell": "$shell"
}
EOF
)
        user_details+=("$user_detail")
        ((total_users++))
        
        [[ $total_users -ge $T1033_001A_MAX_USERS ]] && break
    done < /etc/passwd
    
    local details_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_users": $total_users,
  "user_details": [$(IFS=','; echo "${user_details[*]}")]
}
EOF
)
    
    echo "$details_data" > "$user_details_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_users user details" >&2
        echo "$total_users"
    }
}

# Discover user sessions
Discover-UserSessions() {
    local output_dir="$1"
    local sessions_file="$output_dir/user_info/user_sessions.json"
    
    [[ "$T1033_001A_INCLUDE_USER_SESSIONS" != "true" ]] && return 0
    
    local user_sessions=()
    local total_sessions=0
    
    # Get user sessions using w command
    while IFS=' ' read -r username terminal from login_time idle jcpu pcpu what; do
        [[ "$username" == "USER" ]] && continue
        [[ -z "$username" ]] && continue
        
        local session_info=$(cat <<EOF
{
  "username": "$username",
  "terminal": "$terminal",
  "from": "$from",
  "login_time": "$login_time",
  "idle": "$idle",
  "jcpu": "$jcpu",
  "pcpu": "$pcpu",
  "what": "$what"
}
EOF
)
        user_sessions+=("$session_info")
        ((total_sessions++))
        
        [[ $total_sessions -ge $T1033_001A_MAX_USERS ]] && break
    done < <(w -h 2>/dev/null)
    
    local sessions_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_sessions": $total_sessions,
  "user_sessions": [$(IFS=','; echo "${user_sessions[*]}")]
}
EOF
)
    
    echo "$sessions_data" > "$sessions_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_sessions user sessions" >&2
        echo "$total_sessions"
    }
}

# Discover user groups
Discover-UserGroups() {
    local output_dir="$1"
    local groups_file="$output_dir/user_info/user_groups.json"
    
    [[ "$T1033_001A_INCLUDE_USER_GROUPS" != "true" ]] && return 0
    
    local user_groups=()
    local total_groups=0
    
    # Get group information from /etc/group
    while IFS=':' read -r groupname password gid members; do
        [[ -z "$groupname" ]] && continue
        
        # Skip system groups if not including system users
        if [[ "$T1033_001A_INCLUDE_SYSTEM_USERS" != "true" ]] && [[ "$gid" -lt 1000 ]]; then
            continue
        fi
        
        local group_info=$(cat <<EOF
{
  "group_name": "$groupname",
  "gid": "$gid",
  "members": "$members"
}
EOF
)
        user_groups+=("$group_info")
        ((total_groups++))
        
        [[ $total_groups -ge $T1033_001A_MAX_USERS ]] && break
    done < /etc/group
    
    local groups_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_groups": $total_groups,
  "user_groups": [$(IFS=','; echo "${user_groups[*]}")]
}
EOF
)
    
    echo "$groups_data" > "$groups_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_groups user groups" >&2
        echo "$total_groups"
    }
}

# Discover user login history
Discover-UserHistory() {
    local output_dir="$1"
    local history_file="$output_dir/user_info/user_history.json"
    
    [[ "$T1033_001A_INCLUDE_USER_HISTORY" != "true" ]] && return 0
    
    local login_history=()
    local total_history=0
    
    # Get login history using last command
    while IFS=' ' read -r username terminal from login_time logout_time duration; do
        [[ -z "$username" ]] && continue
        [[ "$username" == "wtmp" ]] && continue
        
        local history_entry=$(cat <<EOF
{
  "username": "$username",
  "terminal": "$terminal",
  "from": "$from",
  "login_time": "$login_time",
  "logout_time": "$logout_time",
  "duration": "$duration"
}
EOF
)
        login_history+=("$history_entry")
        ((total_history++))
        
        [[ $total_history -ge 50 ]] && break
    done < <(last -n 50 2>/dev/null | head -50)
    
    local history_data=$(cat <<EOF
{
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_history_entries": $total_history,
  "login_history": [$(IFS=','; echo "${login_history[*]}")]
}
EOF
)
    
    echo "$history_data" > "$history_file" 2>/dev/null && {
        [[ "$T1033_001A_SILENT_MODE" != "true" && "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Discovered $total_history login history entries" >&2
        echo "$total_history"
    }
}

# Main discovery function
Perform-Discovery() {
    local discovery_dir="$1"
    local total_current_user=0
    local total_logged_users=0
    local total_user_details=0
    local total_user_sessions=0
    local total_user_groups=0
    local total_user_history=0
    
    [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Starting user information discovery..." >&2
    
    # Discover different types of user information
    local current_user_count=$(Discover-CurrentUser "$discovery_dir")
    [[ -n "$current_user_count" ]] && total_current_user=$current_user_count
    
    local logged_users_count=$(Discover-LoggedUsers "$discovery_dir")
    [[ -n "$logged_users_count" ]] && total_logged_users=$logged_users_count
    
    local user_details_count=$(Discover-UserDetails "$discovery_dir")
    [[ -n "$user_details_count" ]] && total_user_details=$user_details_count
    
    local user_sessions_count=$(Discover-UserSessions "$discovery_dir")
    [[ -n "$user_sessions_count" ]] && total_user_sessions=$user_sessions_count
    
    local user_groups_count=$(Discover-UserGroups "$discovery_dir")
    [[ -n "$user_groups_count" ]] && total_user_groups=$user_groups_count
    
    local user_history_count=$(Discover-UserHistory "$discovery_dir")
    [[ -n "$user_history_count" ]] && total_user_history=$user_history_count
    
    # Create summary file
    local summary_file="$discovery_dir/user_info/discovery_summary.json"
    local summary_data=$(cat <<EOF
{
  "technique_id": "T1033.001a",
  "technique_name": "System Owner/User Discovery: User Information Enumeration",
  "discovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_current_user": $total_current_user,
  "total_logged_users": $total_logged_users,
  "total_user_details": $total_user_details,
  "total_user_sessions": $total_user_sessions,
  "total_user_groups": $total_user_groups,
  "total_user_history": $total_user_history,
  "configuration": {
    "include_current_user": $T1033_001A_INCLUDE_CURRENT_USER,
    "include_logged_users": $T1033_001A_INCLUDE_LOGGED_USERS,
    "include_user_details": $T1033_001A_INCLUDE_USER_DETAILS,
    "include_user_sessions": $T1033_001A_INCLUDE_USER_SESSIONS,
    "include_user_groups": $T1033_001A_INCLUDE_USER_GROUPS,
    "include_user_history": $T1033_001A_INCLUDE_USER_HISTORY,
    "include_system_users": $T1033_001A_INCLUDE_SYSTEM_USERS,
    "max_users": $T1033_001A_MAX_USERS
  },
  "discovery_status": "completed"
}
EOF
)
    
    echo "$summary_data" > "$summary_file" 2>/dev/null
    
    [[ "${T1033_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Discovery completed. Found $total_current_user current user, $total_logged_users logged users, $total_user_details user details, $total_user_sessions sessions, $total_user_groups groups, $total_user_history history entries." >&2
    
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
  "technique_id": "T1033.001a",
  "technique_name": "System Owner/User Discovery: User Information Enumeration",
  "output_mode": "${T1033_001A_OUTPUT_MODE:-simple}",
  "silent_mode": "${T1033_001A_SILENT_MODE:-false}",
  "discovery_directory": "$discovery_dir",
  "files_generated": $(find "$discovery_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$discovery_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration": {
    "include_current_user": $T1033_001A_INCLUDE_CURRENT_USER,
    "include_logged_users": $T1033_001A_INCLUDE_LOGGED_USERS,
    "max_users": $T1033_001A_MAX_USERS
  }
}
EOF
)
    
    echo "$metadata" > "$metadata_file" 2>/dev/null
    
    # Output results based on mode
    case "${T1033_001A_OUTPUT_MODE:-simple}" in
        "debug")
            echo "[DEBUG] Discovery results saved to: $discovery_dir" >&2
            echo "[DEBUG] Generated files:" >&2
            find "$discovery_dir" -type f -exec echo "  - {}" \; >&2
            ;;
        "simple")
            echo "[SUCCESS] User information discovery completed" >&2
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
