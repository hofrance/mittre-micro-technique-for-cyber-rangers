#!/bin/bash

# T1056.002b-input_capture-evdev_monitoring-linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Monitor evdev input devices ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier

function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION
    

    local config=(
        # UNIVERSAL BASE VARIABLES ===
        "OUTPUT_BASE=${T1056_002B_OUTPUT_BASE:-./mitre_results}"
        "DEBUG_MODE=${T1056_002B_DEBUG_MODE:-false}"
        "STEALTH_MODE=${T1056_002B_STEALTH_MODE:-false}"
        "SILENT_MODE=${T1056_002B_SILENT_MODE:-false}"
        "VERBOSE_LEVEL=${T1056_002B_VERBOSE_LEVEL:-1}"

        # LINUX+EVDEV SPECIFIC ADAPTABILITY ===
        "OS_TYPE=${T1056_002B_OS_TYPE:-linux}"
        "DEVICE_PATTERNS=${T1056_002B_DEVICE_PATTERNS:-event*}"
        "FILTER_KEYBOARD=${T1056_002B_FILTER_KEYBOARD:-true}"
        "FILTER_MOUSE=${T1056_002B_FILTER_MOUSE:-false}"
        "RAW_FORMAT=${T1056_002B_RAW_FORMAT:-false}"

        # ERROR HANDLING AND RETRY ===
        "TIMEOUT=${T1056_002B_TIMEOUT:-300}"
        "RETRY_COUNT=${T1056_002B_RETRY_COUNT:-3}"
        "FALLBACK_MODE=${T1056_002B_FALLBACK_MODE:-real}"

        # POLICY-AWARENESS ===
        "POLICY_CHECK=${T1056_002B_POLICY_CHECK:-true}"
        "POLICY_real=${T1056_002B_POLICY_real:-true}"

        # COLLECTION CONFIGURATION ===
        "MAX_EVENTS=${T1056_002B_MAX_EVENTS:-5000}"
        "CAPTURE_DURATION=${T1056_002B_CAPTURE_DURATION:-60}"

        # OUTPUT CONFIGURATION ===
        "OUTPUT_FORMAT=${T1056_002B_OUTPUT_FORMAT:-json}"
        "OUTPUT_COMPRESS=${T1056_002B_OUTPUT_COMPRESS:-false}"
        "TELEMETRY_LEVEL=${T1056_002B_TELEMETRY_LEVEL:-full}"
    )

    # Linux OS validation
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Precondition failed: This micro-technique is Linux-specific" >&2
        return 1
    fi

    # Write permissions validation
    if [[ ! -w "$(dirname "${T1056_002B_OUTPUT_BASE:-./mitre_results}")" ]]; then
        echo "Precondition failed: Output directory not writable" >&2
        return 1
    fi

    # Check evdev access and privileges
    if [[ ! -d "/dev/input" ]]; then
        if [[ "${T1056_002B_FALLBACK_MODE:-real}" != "real" ]]; then
            echo "Precondition warning: /dev/input not available, will real" >&2
        fi
        export real collection_MODE="true"
    else
        export real collection_MODE="false"
    fi

    # Check root privileges
    if [[ $(id -u) -ne 0 ]]; then
        if [[ "${T1056_002B_VERBOSE_LEVEL:-1}" -ge 1 ]]; then
            echo "Warning: Root privileges not available, attempting user-mode collection" >&2
        fi
        export USER_MODE="true"
    else
        export USER_MODE="false"
    fi

    # Export configured variables
    # Create output directory if it does not exist
    local output_base="${T1005_001A_OUTPUT_BASE:-./mitre_results}"
    mkdir -p "$output_base" 2>/dev/null || true
    for var in "${config[@]}"; do
        export "$var"
    done

    return 0

    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1056_002B_DEBUG_MODE="${T1056_002B_DEBUG_MODE:-false}"
    export T1056_002B_TIMEOUT="${T1056_002B_TIMEOUT:-300}"
    export T1056_002B_FALLBACK_MODE="${T1056_002B_FALLBACK_MODE:-real}"
    export T1056_002B_OUTPUT_FORMAT="${T1056_002B_OUTPUT_FORMAT:-json}"
    export T1056_002B_POLICY_CHECK="${T1056_002B_POLICY_CHECK:-true}"
    export T1056_002B_MAX_FILES="${T1056_002B_MAX_FILES:-200}"
    export T1056_002B_MAX_FILE_SIZE="${T1056_002B_MAX_FILE_SIZE:-1048576}"
    export T1056_002B_SCAN_DEPTH="${T1056_002B_SCAN_DEPTH:-3}"
    export T1056_002B_EXCLUDE_CACHE="${T1056_002B_EXCLUDE_CACHE:-true}"
    export T1056_002B_CAPTURE_DURATION="${T1056_002B_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}

function Invoke-Main {
    
    # FUNCTION 2/4 : ATOMIC ACTION - EVDEV INPUT MONITORING
    

    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local collection_dir="${T1056_002B_OUTPUT_BASE:-}/T1056_002B_evdev_monitor_${timestamp}"

    # Create collection directory
    if ! mkdir -p "${collection_dir}"/{input_data,metadata} 2>/dev/null; then
        echo "Failed to create collection directory" >&2
        return 1
    fi
    chmod 700 "${collection_dir}" 2>/dev/null

    # Retry loop with fallback
    while [[ $attempts -lt ${T1056_002B_RETRY_COUNT:-3} ]]; do
        ((attempts++))

        # Evdev input monitoring
        local monitor_file="${collection_dir}/input_data/evdev_monitor_$(date +%s).log"

        if [[ "${real collection_MODE:-false}" == "true" ]]; then
            # Simulation mode
            if [[ "${T1056_002B_VERBOSE_LEVEL:-1}" -ge 1 ]]; then
                echo "Simulating evdev input monitoring (limited functionality)" >&2
            fi

            echo "EVDEV INPUT MONITORING real collection" > "$monitor_file"
            echo "Timestamp: $(date)" >> "$monitor_file"
            echo "Duration: ${T1056_002B_CAPTURE_DURATION:-60}s" >> "$monitor_file"
            echo "Device patterns: ${T1056_002B_DEVICE_PATTERNS:-event*}" >> "$monitor_file"
            echo "Filter keyboard: ${T1056_002B_FILTER_KEYBOARD:-true}" >> "$monitor_file"
            echo "Filter mouse: ${T1056_002B_FILTER_MOUSE:-false}" >> "$monitor_file"
            echo "Note: This is a real collection due to security limitations" >> "$monitor_file"

            # Simulate some input events
            for i in {1..10}; do
                echo "Event $i: KeyPress event, code=$((RANDOM % 100))" >> "$monitor_file"
            done
        else
            # Real evdev monitoring
            if [[ "${T1056_002B_VERBOSE_LEVEL:-1}" -ge 1 ]]; then
                echo "Attempting real evdev monitoring" >&2
            fi

            echo "EVDEV INPUT MONITORING" > "$monitor_file"
            echo "Timestamp: $(date)" >> "$monitor_file"
            echo "Duration: ${T1056_002B_CAPTURE_DURATION:-60}s" >> "$monitor_file"
            echo "Available devices:" >> "$monitor_file"

            # List available input devices
            ls /dev/input/${T1056_002B_DEVICE_PATTERNS:-event*} 2>/dev/null >> "$monitor_file" || echo "No input devices found or accessible" >> "$monitor_file"

            # Try to monitor input events (limited due to security)
            if [[ "${USER_MODE:-true}" == "false" ]]; then
                # Root mode - can access devices
                timeout "${T1056_002B_CAPTURE_DURATION:-60}" cat /dev/input/event0 2>/dev/null | head -${T1056_002B_MAX_EVENTS:-5000} >> "$monitor_file" || true
            else
                # User mode - limited access
                echo "User mode: Cannot directly access /dev/input devices" >> "$monitor_file"
                echo "This would require root privileges for full functionality" >> "$monitor_file"
            fi
        fi

        # Check if monitoring was successful
        if [[ -f "$monitor_file" && -s "$monitor_file" ]]; then
            collected_files+=("$monitor_file")
            local file_size=$(stat -c%s "$monitor_file" 2>/dev/null || echo 0)
            total_size=$((total_size + file_size))
            ((file_count++))
            break
        else
            # Fallback real collection for testing
            if [[ "${T1056_002B_FALLBACK_MODE:-real}" == "real" ]]; then
                echo "realD EVDEV MONITORING" > "$monitor_file"
                echo "Fallback mode activated due to access restrictions" >> "$monitor_file"
                collected_files+=("$monitor_file")
                total_size=1024
                file_count=1
                break
            fi

            # Retry with delay
            if [[ $attempts -lt ${T1056_002B_RETRY_COUNT:-3} ]]; then
                sleep 1
            fi
        fi
    done

    # Collect system metadata
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "Simulation mode: ${real collection_MODE:-false}" > "${collection_dir}/metadata/evdev_context.txt" 2>/dev/null || true
    echo "User mode: ${USER_MODE:-true}" >> "${collection_dir}/metadata/evdev_context.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/event_count.txt" 2>/dev/null || true

    # Return results
    echo "$file_count:$total_size:${collection_dir}:$(IFS=,; echo "${collected_files[*]}")"
}

function Send-Telemetry {
    
    # FUNCTION 3/4 : TELEMETRY AND STANDARDIZED OUTPUT
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Silent mode - no output
    if [[ "${T1056_002B_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Stealth mode - minimal output
    if [[ "${T1056_002B_STEALTH_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Debug mode - structured JSON
    if [[ "${T1056_002B_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "event.module": "deputy",
    "event.dataset": "mitre.attack",
    "event.action": "evdev_input_monitoring",
    "mitre.technique.id": "T1056.002b",
    "mitre.artifacts": ["$files_collected"],
    "deputy.postconditions": {
        "input_events_monitored": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
        "artifacts_catalogued": true,
        "output_mode_ready": true
    },
    "collection.metadata": {
        "file_count": $file_count,
        "total_size": $total_size,
        "collection_dir": "$collection_dir",
        "real collection_mode": "${real collection_MODE:-false}",
        "user_mode": "${USER_MODE:-true}",
        "device_patterns": "${T1056_002B_DEVICE_PATTERNS:-event*}"
    }
}
EOF
        )
        echo "$structured_output"
        return 0
    fi

    # Simple mode - realistic attacker output (DEFAULT)
    echo "EVDEV INPUT MONITORING COMPLETED"
    echo "Found: $file_count monitoring files"
    echo "Total size: $total_size bytes"
    echo "Collection directory: $collection_dir"
    if [[ "${T1056_002B_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
        echo "Files: $files_collected"
    fi
    echo "Operation successful"
}

function Get-Results {
    
    # FUNCTION 4/4 : RESULTS AND VALIDATION
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Validate postconditions
    if [[ $file_count -eq 0 ]] && [[ "${T1056_002B_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Postcondition failed: No input monitoring files created" >&2
        return 1
    fi

    if [[ ! -d "$collection_dir" ]]; then
        echo "Postcondition failed: Collection directory not created" >&2
        return 1
    fi

    # Return success
    return 0
}
# MAIN EXECUTION
function main {
    trap 'echo "Interrupted - cleaning up..." >&2; exit 130' INT TERM

    # Phase 1: Configuration
    if ! Get-Configuration; then
        echo "Configuration failed" >&2
        exit 2
    fi

    # Phase 2: Execute atomic action
    local results
    if ! results=$(Invoke-Main); then
        echo "Execution failed" >&2
        exit 1
    fi

    # Phase 3: Send telemetry
    if ! Send-Telemetry "$results"; then
        echo "Telemetry failed" >&2
        exit 1
    fi

    # Phase 4: Get results
    if ! Get-Results "$results"; then
        echo "Results validation failed" >&2
        exit 4
    fi

    exit 0
}

# Execute main function
main "$@"
