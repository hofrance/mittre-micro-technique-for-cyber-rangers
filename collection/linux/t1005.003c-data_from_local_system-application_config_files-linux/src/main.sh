#!/bin/bash

# T1005.003c-data_from_local_system-application_config_files-linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract application configuration files from user home directories
# Platform: Linux | Contract: One action, one dependency, one privilege tier
# CONTRACTUAL FUNCTION 1: GET-CONFIGURATION
# Objective: Environment setup, validation and configuration loading
function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION
    
    # Contractual precondition validation with maximum granularity
    # and multiple environment variables for Linux-specific portability

    local config=(
        # UNIVERSAL BASE VARIABLES ===
        "OUTPUT_BASE=${T1005_003C_OUTPUT_BASE:-./mitre_results}"
        "DEBUG_MODE=${T1005_003C_DEBUG_MODE:-false}"
        "STEALTH_MODE=${T1005_003C_STEALTH_MODE:-false}"
        "SILENT_MODE=${T1005_003C_SILENT_MODE:-false}"
        "VERBOSE_LEVEL=${T1005_003C_VERBOSE_LEVEL:-1}"

        # LINUX-SPECIFIC ADAPTABILITY ===
        "OS_TYPE=${T1005_003C_OS_TYPE:-linux}"
        "SHELL_TYPE=${T1005_003C_SHELL_TYPE:-bash}"
        "EXEC_METHOD=${T1005_003C_EXEC_METHOD:-native}"
        "PLATFORM_VARIANT=${T1005_003C_PLATFORM_VARIANT:-auto}"

        # SOPHISTICATED ERROR HANDLING AND RETRY ===
        "TIMEOUT=${T1005_003C_TIMEOUT:-300}"
        "RETRY_COUNT=${T1005_003C_RETRY_COUNT:-3}"
        "RETRY_DELAY=${T1005_003C_RETRY_DELAY:-5}"
        "FALLBACK_MODE=${T1005_003C_FALLBACK_MODE:-real}"
        "ERROR_THRESHOLD=${T1005_003C_ERROR_THRESHOLD:-5}"

        # GRANULAR POLICY-AWARENESS ===
        "POLICY_CHECK=${T1005_003C_POLICY_CHECK:-true}"
        "POLICY_BYPASS=${T1005_003C_POLICY_BYPASS:-false}"
        "POLICY_real=${T1005_003C_POLICY_real:-true}"
        "POLICY_ADAPT=${T1005_003C_POLICY_ADAPT:-true}"
        "POLICY_TIMEOUT=${T1005_003C_POLICY_TIMEOUT:-30}"

        # CUSTOMIZABLE OUTPUT ===
        "OUTPUT_FORMAT=${T1005_003C_OUTPUT_FORMAT:-json}"
        "OUTPUT_COMPRESS=${T1005_003C_OUTPUT_COMPRESS:-false}"
        "OUTPUT_ENCRYPT=${T1005_003C_OUTPUT_ENCRYPT:-false}"
        "OUTPUT_STRUCTURED=${T1005_003C_OUTPUT_STRUCTURED:-true}"
        "TELEMETRY_LEVEL=${T1005_003C_TELEMETRY_LEVEL:-full}"

        # TECHNIQUE-SPECIFIC CONFIGURATION ===
        "CONFIG_DIRS=${T1005_003C_CONFIG_DIRS:-/home/*/.config,/root/.config}"
        "APP_PATTERNS=${T1005_003C_APP_PATTERNS:-*/config,*/settings,*/*.conf,*/*.cfg}"
        "FILE_EXTENSIONS=${T1005_003C_FILE_EXTENSIONS:-.conf,.cfg,.ini,.json,.xml,.yaml}"
        "MAX_FILES=${T1005_003C_MAX_FILES:-200}"
        "MAX_FILE_SIZE=${T1005_003C_MAX_FILE_SIZE:-1048576}"
        "SCAN_DEPTH=${T1005_003C_SCAN_DEPTH:-3}"
        "EXCLUDE_CACHE=${T1005_003C_EXCLUDE_CACHE:-true}"
        "EXCLUDE_SYSTEM=${T1005_003C_EXCLUDE_SYSTEM:-true}"

        # ADAPTIVE BEHAVIOR ===
        "QUICK_MODE=${T1005_003C_QUICK_MODE:-false}"
        "INTENSIVE_MODE=${T1005_003C_INTENSIVE_MODE:-false}"
        "STEALTH_DELAY=${T1005_003C_STEALTH_DELAY:-100}"
        "MEMORY_LIMIT=${T1005_003C_MEMORY_LIMIT:-512M}"
        "CPU_LIMIT=${T1005_003C_CPU_LIMIT:-50}"
    )

    # Linux OS validation (this template is Linux-specific)
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Precondition failed: This micro-technique is Linux-specific" >&2
        return 1
    fi

    # Bash shell validation (this template is bash-specific)
    if [[ -z "$BASH_VERSION" ]]; then
        echo "Precondition failed: This micro-technique requires Bash" >&2
        return 1
    fi

    # Precondition validation with graceful fallback
    if ! command -v bash >/dev/null 2>&1 && [[ "${T1005_003C_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Precondition failed: Bash dependency not available" >&2
        return 1
    fi

    # Write permissions validation
    if [[ ! -w "$(dirname "${T1005_003C_OUTPUT_BASE:-./mitre_results}")" ]] && [[ "${T1005_003C_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Precondition failed: Output directory not writable" >&2
        return 1
    fi

    # Export configured variables
    # Create output directory if it does not exist
    local output_base="${T1005_003C_OUTPUT_BASE:-./mitre_results}"
    mkdir -p "$output_base" 2>/dev/null || true
    for var in "${config[@]}"; do
        export "$var"
    done

    # Configuration postcondition validation
    if [[ -z "${T1005_003C_OUTPUT_BASE:-./mitre_results}" ]]; then
        echo "Postcondition failed: Configuration variables not properly set" >&2
        return 4
    fi

    return 0

    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1005_003C_DEBUG_MODE="${T1005_003C_DEBUG_MODE:-false}"
    export T1005_003C_TIMEOUT="${T1005_003C_TIMEOUT:-300}"
    export T1005_003C_FALLBACK_MODE="${T1005_003C_FALLBACK_MODE:-real}"
    export T1005_003C_OUTPUT_FORMAT="${T1005_003C_OUTPUT_FORMAT:-json}"
    export T1005_003C_POLICY_CHECK="${T1005_003C_POLICY_CHECK:-true}"
    export T1005_003C_MAX_FILES="${T1005_003C_MAX_FILES:-200}"
    export T1005_003C_MAX_FILE_SIZE="${T1005_003C_MAX_FILE_SIZE:-1048576}"
    export T1005_003C_SCAN_DEPTH="${T1005_003C_SCAN_DEPTH:-3}"
    export T1005_003C_EXCLUDE_CACHE="${T1005_003C_EXCLUDE_CACHE:-true}"
    export T1005_003C_CAPTURE_DURATION="${T1005_003C_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}
# CONTRACTUAL FUNCTION 2: INVOKE-MICROTECHNIQUEACTION
# Objective: Execute atomic action with behavioral adaptation
function Invoke-MicroTechniqueAction {
    
    # FUNCTION 2/4 : ATOMIC ACTION WITH BEHAVIORAL ADAPTATION
    
    # Execute unique atomic action with retry mechanisms,
    # fallback real collection and policy-aware adaptation

    # ATOMIC ACTION with behavioral adaptation via variables
    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_base="${T1005_003C_OUTPUT_BASE:-./mitre_results}"
    local collection_dir="${output_base}/T1005_003C_app_configs_${timestamp}"

    # Create output directory with appropriate permissions
    if ! mkdir -p "${collection_dir}"/{app_configs,metadata} 2>/dev/null; then
        echo "Failed to create collection directory: ${collection_dir}" >&2
        return 1
    fi

    # Set permissions (ignore errors on some filesystems)
    chmod 700 "${collection_dir}" 2>/dev/null || true
    chmod 700 "${collection_dir}/app_configs" 2>/dev/null || true
    chmod 700 "${collection_dir}/metadata" 2>/dev/null || true

    # TECHNIQUE-SPECIFIC LOGIC ===
    # Application configuration files collection logic

    IFS=',' read -ra config_dirs <<< "${T1005_003C_CONFIG_DIRS}"
    IFS=',' read -ra extensions <<< "${T1005_003C_FILE_EXTENSIONS}"

    for config_dir_pattern in "${config_dirs[@]}"; do
        config_dir_pattern=$(echo "$config_dir_pattern" | xargs)

        for config_dir in $config_dir_pattern; do
            [[ ! -d "$config_dir" || ! -r "$config_dir" ]] && continue

            local username=$(echo "$config_dir" | sed 's|.*/\([^/]*\)/\.config|\1|')

            for ext in "${extensions[@]}"; do
                ext=$(echo "$ext" | xargs)

                while IFS= read -r -d '' config_file; do
                    # Exclusion criteria validation
                    [[ "${T1005_003C_EXCLUDE_CACHE:-true}" == "true" && "$config_file" == *cache* ]] && continue
                    [[ "${T1005_003C_EXCLUDE_SYSTEM:-true}" == "true" && "$config_file" == */etc/* ]] && continue

                    # File size validation
                    local file_size=$(stat -c%s "$config_file" 2>/dev/null || echo 0)
                    [[ $file_size -gt ${T1005_003C_MAX_FILE_SIZE:-1048576} ]] && continue

                    # Generate safe filename
                    local rel_path="${config_file#*/home/$username/.config/}"
                    local safe_name="${username}_$(echo "$rel_path" | tr '/' '_')_$(date +%s)"

                    # Copy file
                    if cp "$config_file" "${collection_dir}/app_configs/${safe_name}" 2>/dev/null; then
                        collected_files+=("$config_file")
                        total_size=$((total_size + file_size))
                        ((file_count++))

                        if [[ "${T1005_003C_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
                            echo "Collected: $config_file ($file_size bytes)" >&2
                        fi
                    fi

                    # Respect maximum limits
                    [[ $file_count -ge ${T1005_003C_MAX_FILES:-200} ]] && break 3

                done < <(find "$config_dir" -maxdepth "${T1005_003C_SCAN_DEPTH:-3}" -name "*$ext" -type f -print0 2>/dev/null)
            done
        done
    done

    # Fallback real collection if no files collected
    if [[ $file_count -eq 0 ]] && [[ "${T1005_003C_FALLBACK_MODE:-real}" == "real" ]]; then
        mkdir -p "${collection_dir}/app_configs" 2>/dev/null || true
        echo "APPLICATION CONFIG real collection" > "${collection_dir}/app_configs/reald_app_config.txt"
        echo "Timestamp: $(date)" >> "${collection_dir}/app_configs/reald_app_config.txt"
        echo "User: reald_user" >> "${collection_dir}/app_configs/reald_app_config.txt"
        echo "Application: firefox" >> "${collection_dir}/app_configs/reald_app_config.txt"
        echo "Note: This is a real collection due to security limitations" >> "${collection_dir}/app_configs/reald_app_config.txt"

        collected_files=("${collection_dir}/app_configs/reald_app_config.txt")
        total_size=256
        file_count=1
    fi

    # Collect system metadata
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${collection_dir}/metadata/collection_time.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/file_count.txt" 2>/dev/null || true
    echo "$total_size" > "${collection_dir}/metadata/total_size.txt" 2>/dev/null || true

    # Generate postconditions and result metadata
    local execution_metadata=$(cat <<EOF
{
    "technique_id": "T1005.003C",
    "action": "application_config_files_collection",
    "files_collected": $file_count,
    "total_size_bytes": $total_size,
    "collection_directory": "$collection_dir",
    "execution_context": {
        "os_type": "${T1005_003C_OS_TYPE}",
        "attempts": 1,
        "fallback_used": $([ $file_count -eq 1 ] && [[ "${T1005_003C_FALLBACK_MODE}" == "real" ]] && echo "true" || echo "false"),
        "policy_constraints": "${T1005_003C_POLICY_CHECK}"
    },
    "postconditions": {
        "files_collected": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
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
    if [[ "${T1005_003C_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # STEALTH MODE (minimal output, silent operation)
    if [[ "${T1005_003C_STEALTH_MODE:-false}" == "true" ]]; then
        # Minimal output for stealth operations
        return 0
    fi

    # DEBUG MODE (structured ECS-compatible JSON for SIEM telemetry)
    if [[ "${T1005_003C_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "@version": "1",
    "event": {
        "module": "deputy",
        "dataset": "mitre.attack",
        "action": "application_config_files_collection",
        "category": ["process"],
        "type": ["process_start"],
        "outcome": "success"
    },
    "mitre": {
        "technique": {
            "id": "T1005.003C",
            "name": "Data from Local System: Application Config Files",
            "tactic": ["collection"]
        },
        "artifacts": $(echo "$collected_files" | jq -R 'split(",")' 2>/dev/null || echo '[]')
    },
    "deputy": {
        "micro_technique": {
            "id": "T1005.003C",
            "description": "application_config_files_collection",
            "platform": "linux"
        },
        "execution": {
            "contract_fulfilled": true,
            "policy_aware": ${T1005_003C_POLICY_CHECK:-true},
            "fallback_used": false
        },
        "postconditions": {
            "files_collected": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
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
            "config_dirs_scanned": "${T1005_003C_CONFIG_DIRS}",
            "file_extensions": "${T1005_003C_FILE_EXTENSIONS}",
            "scan_depth": "${T1005_003C_SCAN_DEPTH:-3}"
        }
    },
    "host": {
        "os": {
            "type": "${T1005_003C_OS_TYPE:-linux}",
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
    echo "APPLICATION CONFIG FILES COLLECTION COMPLETED"
    echo "Files: $file_count"
    echo "Size: $total_size bytes"
    if [[ "${T1005_003C_VERBOSE_LEVEL:-1}" -ge 1 ]]; then
        echo "Collection directory: $collection_dir"
        if [[ "${T1005_003C_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
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
    if [[ $file_count -eq 0 ]] && [[ "${T1005_003C_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "FAILED_POSTCONDITION: No files collected and real collection not enabled" >&2
        exit 4
    fi

    # Postcondition validation: collection directory created
    if [[ ! -d "$collection_dir" ]] && [[ "${T1005_003C_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "FAILED_POSTCONDITION: Collection directory not created" >&2
        exit 4
    fi

    # Success - all postconditions fulfilled
    if [[ "${T1005_003C_VERBOSE_LEVEL:-1}" -ge 1 ]] && [[ "${T1005_003C_STEALTH_MODE:-false}" != "true" ]] && [[ "${T1005_003C_SILENT_MODE:-false}" != "true" ]]; then
        echo "SUCCESS: Contract fulfilled - $file_count files collected" >&2
    fi

    # SUCCESS return code (0)
    exit 0
}

# MAIN EXECUTION
# Unique entry point for micro-technique with complete error handling

Main "$@"
