
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1087_002B_DEBUG_MODE="${T1087_002B_DEBUG_MODE:-false}"
    export T1087_002B_TIMEOUT="${T1087_002B_TIMEOUT:-300}"
    export T1087_002B_FALLBACK_MODE="${T1087_002B_FALLBACK_MODE:-simulate}"
    export T1087_002B_OUTPUT_FORMAT="${T1087_002B_OUTPUT_FORMAT:-json}"
    export T1087_002B_POLICY_CHECK="${T1087_002B_POLICY_CHECK:-true}"
    export T1087_002B_MAX_SERVICES="${T1087_002B_MAX_SERVICES:-200}"
    export T1087_002B_INCLUDE_SYSTEM="${T1087_002B_INCLUDE_SYSTEM:-true}"
    export T1087_002B_DETAIL_LEVEL="${T1087_002B_DETAIL_LEVEL:-standard}"
    export T1087_002B_RESOLVE_HOSTNAMES="${T1087_002B_RESOLVE_HOSTNAMES:-true}"
    export T1087_002B_MAX_PROCESSES="${T1087_002B_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1087.002b - Account Discovery: Domain Account Enumeration
# MITRE ATT&CK Technique: T1087.002
# Description: Discovers domain accounts and group memberships using various methods including LDAP queries, NIS, and domain services

set -euo pipefail

# Default configuration
T1087_002B_OUTPUT_BASE="${T1087_002B_OUTPUT_BASE:-/tmp/mitre_results}"
T1087_002B_OUTPUT_MODE="${T1087_002B_OUTPUT_MODE:-simple}"
T1087_002B_SILENT_MODE="${T1087_002B_SILENT_MODE:-false}"
T1087_002B_TIMEOUT="${T1087_002B_TIMEOUT:-30}"

# Technique-specific configuration
T1087_002B_INCLUDE_LDAP="${T1087_002B_INCLUDE_LDAP:-true}"
T1087_002B_INCLUDE_NIS="${T1087_002B_INCLUDE_NIS:-true}"
T1087_002B_INCLUDE_SSSD="${T1087_002B_INCLUDE_SSSD:-true}"
T1087_002B_INCLUDE_KERBEROS="${T1087_002B_INCLUDE_KERBEROS:-true}"
T1087_002B_INCLUDE_SAMBA="${T1087_002B_INCLUDE_SAMBA:-true}"
T1087_002B_DOMAIN="${T1087_002B_DOMAIN:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$T1087_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    if [[ "$T1087_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$T1087_002B_SILENT_MODE" != "true" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Step 1: Check critical dependencies
Check-CriticalDeps() {
    log_info "Checking critical dependencies..."
    
    local deps=("jq" "getent" "id" "groups" "cat" "grep" "awk" "cut" "tr")
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
    local bool_vars=("T1087_002B_INCLUDE_LDAP" "T1087_002B_INCLUDE_NIS" 
                     "T1087_002B_INCLUDE_SSSD" "T1087_002B_INCLUDE_KERBEROS" "T1087_002B_INCLUDE_SAMBA")
    
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
    
    # Check if domain is configured
    if [[ -z "$T1087_002B_DOMAIN" ]]; then
        log_warning "No domain specified, will attempt auto-detection"
    fi
    
    log_success "System preconditions validated"
    return 0
}

# Step 4: Initialize output structure
Initialize-OutputStructure() {
    log_info "Initializing output structure..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local discovery_dir="${T1087_002B_OUTPUT_BASE}/t1087.002b_domain_account_enumeration_${timestamp}"
    
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
    log_info "Performing domain account enumeration..."
    
    # Discover LDAP accounts
    if [[ "$T1087_002B_INCLUDE_LDAP" == "true" ]]; then
        Discover-LDAPAccounts "$discovery_dir"
    fi
    
    # Discover NIS accounts
    if [[ "$T1087_002B_INCLUDE_NIS" == "true" ]]; then
        Discover-NISAccounts "$discovery_dir"
    fi
    
    # Discover SSSD accounts
    if [[ "$T1087_002B_INCLUDE_SSSD" == "true" ]]; then
        Discover-SSSDAccounts "$discovery_dir"
    fi
    
    # Discover Kerberos accounts
    if [[ "$T1087_002B_INCLUDE_KERBEROS" == "true" ]]; then
        Discover-KerberosAccounts "$discovery_dir"
    fi
    
    # Discover Samba accounts
    if [[ "$T1087_002B_INCLUDE_SAMBA" == "true" ]]; then
        Discover-SambaAccounts "$discovery_dir"
    fi
    
    log_success "Domain account enumeration completed"
}

# Discover LDAP accounts
Discover-LDAPAccounts() {
    local discovery_dir="$1"
    log_info "Discovering LDAP accounts..."
    
    local ldap_file="${discovery_dir}/ldap_accounts.json"
    local ldap_accounts=()
    
    # Check if LDAP is configured
    if [[ -f "/etc/ldap/ldap.conf" ]] || [[ -f "/etc/openldap/ldap.conf" ]]; then
        log_info "LDAP configuration found"
        
        # Try to get LDAP users using getent
        if command -v getent &> /dev/null; then
            while IFS=: read -r username password uid gid gecos home shell; do
                if [[ "$uid" -ge 1000 ]] && [[ "$uid" -lt 65534 ]]; then
                    local account_info=$(cat <<EOF
{
  "username": "$username",
  "uid": "$uid",
  "gid": "$gid",
  "gecos": "$gecos",
  "home": "$home",
  "shell": "$shell",
  "source": "ldap"
}
EOF
)
                    ldap_accounts+=("$account_info")
                fi
            done < <(getent passwd 2>/dev/null | grep -v "^[^:]*:[^:]*:[0-9]\{1,3\}:" || true)
        fi
    else
        log_info "No LDAP configuration found"
    fi
    
    # Create JSON output
    local ldap_accounts_json=$(printf '%s\n' "${ldap_accounts[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1087.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "ldap_accounts": {
    "count": $(echo "$ldap_accounts_json" | jq 'length'),
    "accounts": $ldap_accounts_json,
    "configuration": {
      "ldap_conf_exists": $([[ -f "/etc/ldap/ldap.conf" ]] && echo "true" || echo "false"),
      "openldap_conf_exists": $([[ -f "/etc/openldap/ldap.conf" ]] && echo "true" || echo "false")
    }
  }
}
EOF
)
    
    echo "$result" | jq . > "$ldap_file"
    log_success "LDAP accounts saved to: $ldap_file"
}

# Discover NIS accounts
Discover-NISAccounts() {
    local discovery_dir="$1"
    log_info "Discovering NIS accounts..."
    
    local nis_file="${discovery_dir}/nis_accounts.json"
    local nis_accounts=()
    
    # Check if NIS is configured
    if command -v ypcat &> /dev/null || [[ -f "/etc/yp.conf" ]]; then
        log_info "NIS configuration found"
        
        # Try to get NIS users
        if command -v ypcat &> /dev/null; then
            while IFS=: read -r username password uid gid gecos home shell; do
                if [[ "$uid" -ge 1000 ]] && [[ "$uid" -lt 65534 ]]; then
                    local account_info=$(cat <<EOF
{
  "username": "$username",
  "uid": "$uid",
  "gid": "$gid",
  "gecos": "$gecos",
  "home": "$home",
  "shell": "$shell",
  "source": "nis"
}
EOF
)
                    nis_accounts+=("$account_info")
                fi
            done < <(ypcat passwd 2>/dev/null || true)
        fi
    else
        log_info "No NIS configuration found"
    fi
    
    # Create JSON output
    local nis_accounts_json=$(printf '%s\n' "${nis_accounts[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1087.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "nis_accounts": {
    "count": $(echo "$nis_accounts_json" | jq 'length'),
    "accounts": $nis_accounts_json,
    "configuration": {
      "ypcat_available": $(command -v ypcat &> /dev/null && echo "true" || echo "false"),
      "yp_conf_exists": $([[ -f "/etc/yp.conf" ]] && echo "true" || echo "false")
    }
  }
}
EOF
)
    
    echo "$result" | jq . > "$nis_file"
    log_success "NIS accounts saved to: $nis_file"
}

# Discover SSSD accounts
Discover-SSSDAccounts() {
    local discovery_dir="$1"
    log_info "Discovering SSSD accounts..."
    
    local sssd_file="${discovery_dir}/sssd_accounts.json"
    local sssd_accounts=()
    
    # Check if SSSD is configured
    if [[ -f "/etc/sssd/sssd.conf" ]] || systemctl is-active --quiet sssd; then
        log_info "SSSD configuration found"
        
        # Try to get SSSD users
        if command -v sssctl &> /dev/null; then
            while IFS=: read -r username password uid gid gecos home shell; do
                if [[ "$uid" -ge 1000 ]] && [[ "$uid" -lt 65534 ]]; then
                    local account_info=$(cat <<EOF
{
  "username": "$username",
  "uid": "$uid",
  "gid": "$gid",
  "gecos": "$gecos",
  "home": "$home",
  "shell": "$shell",
  "source": "sssd"
}
EOF
)
                    sssd_accounts+=("$account_info")
                fi
            done < <(sssctl user-list 2>/dev/null | while read -r user; do getent passwd "$user" 2>/dev/null; done || true)
        fi
    else
        log_info "No SSSD configuration found"
    fi
    
    # Create JSON output
    local sssd_accounts_json=$(printf '%s\n' "${sssd_accounts[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1087.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "sssd_accounts": {
    "count": $(echo "$sssd_accounts_json" | jq 'length'),
    "accounts": $sssd_accounts_json,
    "configuration": {
      "sssd_conf_exists": $([[ -f "/etc/sssd/sssd.conf" ]] && echo "true" || echo "false"),
      "sssd_active": $(systemctl is-active --quiet sssd && echo "true" || echo "false"),
      "sssctl_available": $(command -v sssctl &> /dev/null && echo "true" || echo "false")
    }
  }
}
EOF
)
    
    echo "$result" | jq . > "$sssd_file"
    log_success "SSSD accounts saved to: $sssd_file"
}

# Discover Kerberos accounts
Discover-KerberosAccounts() {
    local discovery_dir="$1"
    log_info "Discovering Kerberos accounts..."
    
    local kerberos_file="${discovery_dir}/kerberos_accounts.json"
    local kerberos_info=()
    
    # Check if Kerberos is configured
    if [[ -f "/etc/krb5.conf" ]] || command -v klist &> /dev/null; then
        log_info "Kerberos configuration found"
        
        # Get Kerberos configuration
        local realm=$(grep -E '^[[:space:]]*default_realm' /etc/krb5.conf 2>/dev/null | awk '{print $3}' || echo "Unknown")
        local kdc=$(grep -E '^[[:space:]]*kdc' /etc/krb5.conf 2>/dev/null | head -1 | awk '{print $3}' || echo "Unknown")
        
        # Check for active tickets
        local tickets=""
        if command -v klist &> /dev/null; then
            tickets=$(klist 2>/dev/null | head -10 | jq -R . | jq -s . || echo '[]')
        fi
        
        local kerberos_config=$(cat <<EOF
{
  "realm": "$realm",
  "kdc": "$kdc",
  "active_tickets": $tickets,
  "configuration_file": "/etc/krb5.conf"
}
EOF
)
        kerberos_info+=("$kerberos_config")
    else
        log_info "No Kerberos configuration found"
    fi
    
    # Create JSON output
    local kerberos_info_json=$(printf '%s\n' "${kerberos_info[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1087.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "kerberos_accounts": {
    "count": $(echo "$kerberos_info_json" | jq 'length'),
    "configuration": $kerberos_info_json,
    "available": $(command -v klist &> /dev/null && echo "true" || echo "false")
  }
}
EOF
)
    
    echo "$result" | jq . > "$kerberos_file"
    log_success "Kerberos accounts saved to: $kerberos_file"
}

# Discover Samba accounts
Discover-SambaAccounts() {
    local discovery_dir="$1"
    log_info "Discovering Samba accounts..."
    
    local samba_file="${discovery_dir}/samba_accounts.json"
    local samba_accounts=()
    
    # Check if Samba is configured
    if [[ -f "/etc/samba/smb.conf" ]] || command -v pdbedit &> /dev/null; then
        log_info "Samba configuration found"
        
        # Try to get Samba users
        if command -v pdbedit &> /dev/null; then
            while IFS=: read -r username uid gid home shell; do
                if [[ "$uid" -ge 1000 ]] && [[ "$uid" -lt 65534 ]]; then
                    local account_info=$(cat <<EOF
{
  "username": "$username",
  "uid": "$uid",
  "gid": "$gid",
  "home": "$home",
  "shell": "$shell",
  "source": "samba"
}
EOF
)
                    samba_accounts+=("$account_info")
                fi
            done < <(pdbedit -L 2>/dev/null | while read -r user; do getent passwd "$user" 2>/dev/null; done || true)
        fi
    else
        log_info "No Samba configuration found"
    fi
    
    # Create JSON output
    local samba_accounts_json=$(printf '%s\n' "${samba_accounts[@]}" | jq -s .)
    
    local result=$(cat <<EOF
{
  "technique": "T1087.002b",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "samba_accounts": {
    "count": $(echo "$samba_accounts_json" | jq 'length'),
    "accounts": $samba_accounts_json,
    "configuration": {
      "smb_conf_exists": $([[ -f "/etc/samba/smb.conf" ]] && echo "true" || echo "false"),
      "pdbedit_available": $(command -v pdbedit &> /dev/null && echo "true" || echo "false")
    }
  }
}
EOF
)
    
    echo "$result" | jq . > "$samba_file"
    log_success "Samba accounts saved to: $samba_file"
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
  "technique": "T1087.002b",
  "name": "Account Discovery: Domain Account Enumeration",
  "description": "Discovers domain accounts and group memberships using various methods including LDAP queries, NIS, and domain services",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_directory": "$discovery_dir",
  "files_generated": $file_count,
  "files": [
    "ldap_accounts.json",
    "nis_accounts.json",
    "sssd_accounts.json",
    "kerberos_accounts.json",
    "samba_accounts.json"
  ],
  "configuration": {
    "include_ldap": $T1087_002B_INCLUDE_LDAP,
    "include_nis": $T1087_002B_INCLUDE_NIS,
    "include_sssd": $T1087_002B_INCLUDE_SSSD,
    "include_kerberos": $T1087_002B_INCLUDE_KERBEROS,
    "include_samba": $T1087_002B_INCLUDE_SAMBA,
    "domain": "$T1087_002B_DOMAIN"
  }
}
EOF
)
    
    echo "$summary" | jq . > "$summary_file"
    
    # Display results based on output mode
    case "${OUTPUT_MODE:-simple}" in
        "simple")
            log_success "Domain account enumeration completed successfully"
            log_info "Output directory: $discovery_dir"
            log_info "Files generated: $file_count"
            ;;
        "debug")
            log_success "Domain account enumeration completed successfully"
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
            log_success "Domain account enumeration completed successfully"
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

