#!/bin/bash

# T1007.001A - System Service Discovery: Service Enumeration
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Enumerate system services ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier
#  T1007.001A

# FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION

function Get-Configuration {
    
    # CONFIGURATION AND ENVIRONMENT VARIABLE STANDARDIZATION
    

    # Universal Base Variables
    export T1007_001A_OUTPUT_BASE="${T1007_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1007_001A_DEBUG_MODE="${T1007_001A_DEBUG_MODE:-false}"
    export T1007_001A_STEALTH_MODE="${T1007_001A_STEALTH_MODE:-false}"
    export T1007_001A_SILENT_MODE="${T1007_001A_SILENT_MODE:-false}"
    export T1007_001A_VERBOSE_LEVEL="${T1007_001A_VERBOSE_LEVEL:-1}"

    # Linux-Specific Adaptability
    export T1007_001A_OS_TYPE="${T1007_001A_OS_TYPE:-linux}"
    export T1007_001A_SHELL_TYPE="${T1007_001A_SHELL_TYPE:-bash}"
    export T1007_001A_EXEC_METHOD="${T1007_001A_EXEC_METHOD:-native}"
    export T1007_001A_PLATFORM_VARIANT="${T1007_001A_PLATFORM_VARIANT:-auto}"

    # Error Handling and Retry
    export T1007_001A_TIMEOUT="${T1007_001A_TIMEOUT:-300}"
    export T1007_001A_RETRY_COUNT="${T1007_001A_RETRY_COUNT:-3}"
    export T1007_001A_RETRY_DELAY="${T1007_001A_RETRY_DELAY:-5}"
    export T1007_001A_FALLBACK_MODE="${T1007_001A_FALLBACK_MODE:-simulate}"
    export T1007_001A_ERROR_THRESHOLD="${T1007_001A_ERROR_THRESHOLD:-5}"

    # Policy-Awareness
    export T1007_001A_POLICY_CHECK="${T1007_001A_POLICY_CHECK:-true}"
    export T1007_001A_POLICY_BYPASS="${T1007_001A_POLICY_BYPASS:-false}"
    export T1007_001A_POLICY_SIMULATE="${T1007_001A_POLICY_SIMULATE:-true}"
    export T1007_001A_POLICY_ADAPT="${T1007_001A_POLICY_ADAPT:-true}"
    export T1007_001A_POLICY_TIMEOUT="${T1007_001A_POLICY_TIMEOUT:-30}"

    # Output Configuration
    export T1007_001A_OUTPUT_FORMAT="${T1007_001A_OUTPUT_FORMAT:-json}"
    export T1007_001A_OUTPUT_COMPRESS="${T1007_001A_OUTPUT_COMPRESS:-false}"
    export T1007_001A_OUTPUT_ENCRYPT="${T1007_001A_OUTPUT_ENCRYPT:-false}"
    export T1007_001A_OUTPUT_STRUCTURED="${T1007_001A_OUTPUT_STRUCTURED:-true}"
    export T1007_001A_TELEMETRY_LEVEL="${T1007_001A_TELEMETRY_LEVEL:-full}"

    # Technique-Specific Configuration
    export T1007_001A_SERVICE_MANAGERS="${T1007_001A_SERVICE_MANAGERS:-systemd,init,upstart,service}"
    export T1007_001A_SERVICE_STATES="${T1007_001A_SERVICE_STATES:-active,inactive,enabled,disabled,running,stopped}"
    export T1007_001A_MAX_SERVICES="${T1007_001A_MAX_SERVICES:-200}"
    export T1007_001A_INCLUDE_SYSTEM="${T1007_001A_INCLUDE_SYSTEM:-true}"
    export T1007_001A_INCLUDE_USER="${T1007_001A_INCLUDE_USER:-true}"
    export T1007_001A_DETAIL_LEVEL="${T1007_001A_DETAIL_LEVEL:-standard}"

    # Adaptive Behavior
    export T1007_001A_QUICK_MODE="${T1007_001A_QUICK_MODE:-false}"
    export T1007_001A_INTENSIVE_MODE="${T1007_001A_INTENSIVE_MODE:-false}"
    export T1007_001A_STEALTH_DELAY="${T1007_001A_STEALTH_DELAY:-100}"
    export T1007_001A_MEMORY_LIMIT="${T1007_001A_MEMORY_LIMIT:-512M}"
    export T1007_001A_CPU_LIMIT="${T1007_001A_CPU_LIMIT:-50}"

    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1007_001A_DEBUG_MODE="${T1007_001A_DEBUG_MODE:-false}"
    export T1007_001A_TIMEOUT="${T1007_001A_TIMEOUT:-300}"
    export T1007_001A_FALLBACK_MODE="${T1007_001A_FALLBACK_MODE:-simulate}"
    export T1007_001A_OUTPUT_FORMAT="${T1007_001A_OUTPUT_FORMAT:-json}"
    export T1007_001A_POLICY_CHECK="${T1007_001A_POLICY_CHECK:-true}"
    export T1007_001A_MAX_SERVICES="${T1007_001A_MAX_SERVICES:-200}"
    export T1007_001A_INCLUDE_SYSTEM="${T1007_001A_INCLUDE_SYSTEM:-true}"
    export T1007_001A_DETAIL_LEVEL="${T1007_001A_DETAIL_LEVEL:-standard}"
    export T1007_001A_RESOLVE_HOSTNAMES="${T1007_001A_RESOLVE_HOSTNAMES:-true}"
    export T1007_001A_MAX_PROCESSES="${T1007_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

}
# FUNCTION 2/4 : PRECONDITION CHECK

function Precondition-Check {
    
    # SYSTEM AND DEPENDENCY VALIDATION
    

    local missing_deps=()
    local required_deps=("bash" "jq" "bc" "grep" "systemctl" "service" "ps" "cat" "awk")

    # Check OS compatibility
    if [[ "$T1007_001A_OS_TYPE" != "linux" ]]; then
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Unsupported OS: $T1007_001A_OS_TYPE (requires: linux)" >&2
        return 2  # SKIPPED_PRECONDITION
    fi

    # Check shell compatibility
    if [[ "$T1007_001A_SHELL_TYPE" != "bash" ]]; then
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Unsupported shell: $T1007_001A_SHELL_TYPE (requires: bash)" >&2
        return 2  # SKIPPED_PRECONDITION
    fi

    # Check critical dependencies
    [[ "$T1007_001A_STEALTH_MODE" != "true" ]] && echo "[INFO] Checking critical dependencies..." >&2

    for cmd in "${required_deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "$T1007_001A_STEALTH_MODE" != "true" ]] && echo "  + Found: $cmd" >&2
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Missing required dependencies:" >&2
        for dep in "${missing_deps[@]}"; do
            echo "  x Missing: $dep" >&2
        done

        # Installation instructions
        if [[ "$T1007_001A_SILENT_MODE" != "true" ]]; then
            echo "" >&2
            echo "INSTALLATION COMMANDS:" >&2
            echo "Ubuntu/Debian: sudo apt-get install -y ${missing_deps[*]}" >&2
            echo "CentOS/RHEL:   sudo dnf install -y ${missing_deps[*]}" >&2
            echo "Arch Linux:    sudo pacman -S ${missing_deps[*]}" >&2
            echo "" >&2
        fi
        return 2  # SKIPPED_PRECONDITION
    fi

    # Validate output directory
    if [[ ! -w "$(dirname "$T1007_001A_OUTPUT_BASE")" ]]; then
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Output directory not writable: $(dirname "$T1007_001A_OUTPUT_BASE")" >&2
        return 2  # SKIPPED_PRECONDITION
    fi

    [[ "$T1007_001A_STEALTH_MODE" != "true" ]] && echo "[INFO] All preconditions satisfied" >&2
    return 0  # SUCCESS
}
# FUNCTION 3/4 : ATOMIC ACTION

function Atomic-Action {
    
    # SINGLE OBSERVABLE ACTION: Service Discovery ONLY
    

    local discovery_dir="$1"
    local service_count=0
    local discovered_services=()

    # Initialize service managers detection
    local service_managers=()
    if command -v systemctl >/dev/null 2>&1; then
        service_managers+=("systemd")
    fi
    if command -v service >/dev/null 2>&1; then
        service_managers+=("sysv-init")
    fi
    if command -v initctl >/dev/null 2>&1; then
        service_managers+=("upstart")
    fi

    [[ "$T1007_001A_DEBUG_MODE" == "true" ]] && echo "[DEBUG] Detected service managers: ${service_managers[*]}" >&2

    # Enumerate services from each manager
    for manager in "${service_managers[@]}"; do
        case "$manager" in
            "systemd")
                # SystemD services enumeration
                if systemctl list-units --type=service --all --no-pager >/dev/null 2>&1; then
                    while read -r line; do
                        if [[ $service_count -ge $T1007_001A_MAX_SERVICES ]]; then
                            break 2
                        fi
                        discovered_services+=("$line")
                        ((service_count++))
                    done < <(systemctl list-units --type=service --all --no-pager | grep -E '\.service' | head -n "$T1007_001A_MAX_SERVICES")
                fi
                ;;
            "sysv-init")
                # SysV init services enumeration
                if [[ -d /etc/init.d ]]; then
                    while read -r service_file; do
                        if [[ $service_count -ge $T1007_001A_MAX_SERVICES ]]; then
                            break 2
                        fi
                        discovered_services+=("$(basename "$service_file")")
                        ((service_count++))
                    done < <(find /etc/init.d -type f -executable 2>/dev/null | head -n "$T1007_001A_MAX_SERVICES")
                fi
                ;;
            "upstart")
                # Upstart services enumeration
                if [[ -d /etc/init ]]; then
                    while read -r service_file; do
                        if [[ $service_count -ge $T1007_001A_MAX_SERVICES ]]; then
                            break 2
                        fi
                        discovered_services+=("$(basename "$service_file" .conf)")
                        ((service_count++))
                    done < <(find /etc/init -name "*.conf" 2>/dev/null | head -n "$T1007_001A_MAX_SERVICES")
                fi
                ;;
        esac
    done

    # Generate output based on mode
    case "$T1007_001A_OUTPUT_FORMAT" in
        "json")
            # Generate JSON output
            {
                echo "{"
                echo "  \"@timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
                echo "  \"event\": {"
                echo "    \"module\": \"deputy\","
                echo "    \"action\": \"system_service_discovery\""
                echo "  },"
                echo "  \"mitre\": {"
                echo "    \"technique\": {"
                echo "      \"id\": \"T1007.001a\","
                echo "      \"name\": \"System Service Discovery: Service Enumeration\""
                echo "    }"
                echo "  },"
                echo "  \"discovery\": {"
                echo "    \"services\": {"
                echo "      \"total_count\": $service_count,"
                echo "      \"managers\": [$(printf '"%s",' "${service_managers[@]}" | sed 's/,$//')]"
                echo "    }"
                echo "  }"
                echo "}"
            } > "$discovery_dir/services_discovery.json"
            ;;
        "simple")
            # Generate simple text output
            {
                echo "SYSTEM SERVICE DISCOVERY COMPLETED"
                echo "Found: $service_count services"
                echo "Service managers: ${service_managers[*]}"
                echo "Collection directory: $discovery_dir"
                echo "Operation successful"
            } > "$discovery_dir/services_summary.txt"
            ;;
    esac

    # Stealth mode: minimal output
    if [[ "$T1007_001A_STEALTH_MODE" != "true" ]]; then
        echo "[INFO] Service discovery completed: $service_count services found" >&2
    fi

    return 0  # SUCCESS
}
# FUNCTION 4/4 : POSTCONDITION VERIFY

function Postcondition-Verify {
    
    # RESULT VALIDATION AND POST-PROCESSING
    

    local discovery_dir="$1"

    # Verify output files were created
    if [[ ! -f "$discovery_dir/services_discovery.json" ]] && [[ ! -f "$discovery_dir/services_summary.txt" ]]; then
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] No output files generated" >&2
        return 4  # FAILED_POSTCONDITION
    fi

    # Validate JSON output if present
    if [[ -f "$discovery_dir/services_discovery.json" ]]; then
        if ! jq . "$discovery_dir/services_discovery.json" >/dev/null 2>&1; then
            [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Invalid JSON output" >&2
            return 4  # FAILED_POSTCONDITION
        fi

        # Verify expected JSON structure
        local service_count
        service_count=$(jq -r '.discovery.services.total_count // 0' "$discovery_dir/services_discovery.json")
        if [[ $service_count -lt 0 ]]; then
            [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Invalid service count in JSON" >&2
            return 4  # FAILED_POSTCONDITION
        fi
    fi

    # Compress output if requested
    if [[ "$T1007_001A_OUTPUT_COMPRESS" == "true" ]]; then
        if command -v gzip >/dev/null 2>&1; then
            gzip "$discovery_dir"/*.json "$discovery_dir"/*.txt 2>/dev/null || true
        fi
    fi

    # Generate execution metadata
    {
        echo "{"
        echo "  \"@timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"execution\": {"
        echo "    \"technique\": \"T1007.001A\","
        echo "    \"status\": \"SUCCESS\","
        echo "    \"output_directory\": \"$discovery_dir\","
        echo "    \"compressed\": $T1007_001A_OUTPUT_COMPRESS"
        echo "  }"
        echo "}"
    } > "$discovery_dir/execution_metadata.json"

    [[ "$T1007_001A_STEALTH_MODE" != "true" ]] && echo "[INFO] Postcondition verification successful" >&2
    return 0  # SUCCESS
}
# MAIN EXECUTION ORCHESTRATOR

main() {
    
    # CONTRACT-DRIVEN EXECUTION FLOW
    

    # Step 1: Configuration and Environment Setup
    Get-Configuration || {
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Configuration failed" >&2
        exit 1  # FAILED
    }

    # Step 2: Precondition Validation
    Precondition-Check || {
        exit_code=$?
        case $exit_code in
            2)  # SKIPPED_PRECONDITION
                [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[INFO] Preconditions not met, skipping execution" >&2
                ;;
            *)  # Other errors
                [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Precondition check failed (code: $exit_code)" >&2
                ;;
        esac
        exit $exit_code
    }

    # Step 3: Initialize Output Directory
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local discovery_dir="$T1007_001A_OUTPUT_BASE/T1007_001A_services_$timestamp"

    mkdir -p "$discovery_dir" || {
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Cannot create output directory: $discovery_dir" >&2
        exit 1  # FAILED
    }

    # Step 4: Execute Atomic Action
    Atomic-Action "$discovery_dir" || {
        exit_code=$?
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Atomic action failed (code: $exit_code)" >&2
        exit $exit_code
    }

    # Step 5: Postcondition Verification
    Postcondition-Verify "$discovery_dir" || {
        exit_code=$?
        [[ "$T1007_001A_SILENT_MODE" != "true" ]] && echo "[ERROR] Postcondition verification failed (code: $exit_code)" >&2
        exit $exit_code
    }

    # Success
    case "$T1007_001A_OUTPUT_FORMAT" in
        "simple")
            [[ "$T1007_001A_SILENT_MODE" != "true" ]] && cat "$discovery_dir/services_summary.txt" >&2
            ;;
        "json")
            [[ "$T1007_001A_DEBUG_MODE" == "true" ]] && [[ "$T1007_001A_SILENT_MODE" != "true" ]] && \
                echo "[DEBUG] Results saved to: $discovery_dir" >&2
            ;;
    esac

    return 0  # SUCCESS
}
# SCRIPT ENTRY POINT

main "$@"
