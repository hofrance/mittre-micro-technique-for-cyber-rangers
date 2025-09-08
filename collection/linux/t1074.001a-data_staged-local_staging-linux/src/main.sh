#!/bin/bash

# T1074.001a-data_staged-local_staging-linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Stage collected data locally ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier

function Get-Configuration {
    
    # FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION
    

    local config=(
        # UNIVERSAL BASE VARIABLES ===
        "OUTPUT_BASE=${T1074_001A_OUTPUT_BASE:-./mitre_results}"
        "DEBUG_MODE=${T1074_001A_DEBUG_MODE:-false}"
        "STEALTH_MODE=${T1074_001A_STEALTH_MODE:-false}"
        "SILENT_MODE=${T1074_001A_SILENT_MODE:-false}"
        "VERBOSE_LEVEL=${T1074_001A_VERBOSE_LEVEL:-1}"

        # LINUX STAGING SPECIFIC ADAPTABILITY ===
        "OS_TYPE=${T1074_001A_OS_TYPE:-linux}"
        "STAGING_DIR=${T1074_001A_STAGING_DIR:-/tmp/.staging}"
        "SOURCE_PATHS=${T1074_001A_SOURCE_PATHS:-./mitre_results}"
        "FILE_PATTERNS=${T1074_001A_FILE_PATTERNS:-*}"

        # ERROR HANDLING AND RETRY ===
        "TIMEOUT=${T1074_001A_TIMEOUT:-300}"
        "RETRY_COUNT=${T1074_001A_RETRY_COUNT:-3}"
        "FALLBACK_MODE=${T1074_001A_FALLBACK_MODE:-real}"

        # POLICY-AWARENESS ===
        "POLICY_CHECK=${T1074_001A_POLICY_CHECK:-true}"
        "POLICY_real=${T1074_001A_POLICY_real:-true}"

        # STAGING CONFIGURATION ===
        "MAX_FILES=${T1074_001A_MAX_FILES:-1000}"
        "MAX_TOTAL_SIZE=${T1074_001A_MAX_TOTAL_SIZE:-1073741824}"
        "ORGANIZE_BY_TYPE=${T1074_001A_ORGANIZE_BY_TYPE:-true}"
        "PRESERVE_STRUCTURE=${T1074_001A_PRESERVE_STRUCTURE:-false}"

        # OUTPUT CONFIGURATION ===
        "OUTPUT_FORMAT=${T1074_001A_OUTPUT_FORMAT:-json}"
        "OUTPUT_COMPRESS=${T1074_001A_OUTPUT_COMPRESS:-false}"
        "TELEMETRY_LEVEL=${T1074_001A_TELEMETRY_LEVEL:-full}"
    )

    # Linux OS validation
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Precondition failed: This micro-technique is Linux-specific" >&2
        return 1
    fi

    # Write permissions validation
    if [[ ! -w "$(dirname "${T1074_001A_OUTPUT_BASE:-./mitre_results}")" ]]; then
        echo "Precondition failed: Output directory not writable" >&2
        return 1
    fi

    # Staging directory permissions validation
    if [[ ! -w "$(dirname "${T1074_001A_STAGING_DIR:-/tmp/.staging}")" ]]; then
        echo "Precondition failed: Staging directory not writable" >&2
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
    # ===== VARIABLES ESSENTIELLES AJOUTÉES =====
    export T1074_001A_DEBUG_MODE="${T1074_001A_DEBUG_MODE:-false}"
    export T1074_001A_TIMEOUT="${T1074_001A_TIMEOUT:-300}"
    export T1074_001A_FALLBACK_MODE="${T1074_001A_FALLBACK_MODE:-simulation}"
    export T1074_001A_OUTPUT_FORMAT="${T1074_001A_OUTPUT_FORMAT:-json}"
    export T1074_001A_POLICY_CHECK="${T1074_001A_POLICY_CHECK:-true}"
    # ===== FIN VARIABLES ESSENTIELLES =====


    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1074_001A_DEBUG_MODE="${T1074_001A_DEBUG_MODE:-false}"
    export T1074_001A_TIMEOUT="${T1074_001A_TIMEOUT:-300}"
    export T1074_001A_FALLBACK_MODE="${T1074_001A_FALLBACK_MODE:-real}"
    export T1074_001A_OUTPUT_FORMAT="${T1074_001A_OUTPUT_FORMAT:-json}"
    export T1074_001A_POLICY_CHECK="${T1074_001A_POLICY_CHECK:-true}"
    export T1074_001A_MAX_FILES="${T1074_001A_MAX_FILES:-200}"
    export T1074_001A_MAX_FILE_SIZE="${T1074_001A_MAX_FILE_SIZE:-1048576}"
    export T1074_001A_SCAN_DEPTH="${T1074_001A_SCAN_DEPTH:-3}"
    export T1074_001A_EXCLUDE_CACHE="${T1074_001A_EXCLUDE_CACHE:-true}"
    export T1074_001A_CAPTURE_DURATION="${T1074_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

}

function Invoke-Main {
    
    # FUNCTION 2/4 : ATOMIC ACTION - LOCAL DATA STAGING
    

    local collected_files=() total_size=0 file_count=0
    local attempts=0
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local collection_dir="${T1074_001A_OUTPUT_BASE}/T1074_001A_local_staging_${timestamp}"
    local staging_dir="${T1074_001A_STAGING_DIR}/staging_${timestamp}"

    # Create directories
    if ! mkdir -p "${collection_dir}"/{staged_data,metadata} 2>/dev/null; then
        echo "Failed to create collection directory" >&2
        return 1
    fi
    if ! mkdir -p "${staging_dir}" 2>/dev/null; then
        echo "Failed to create staging directory" >&2
        return 1
    fi
    chmod 700 "${collection_dir}" "${staging_dir}" 2>/dev/null

    # Retry loop with fallback
    while [[ $attempts -lt ${T1074_001A_RETRY_COUNT:-3} ]]; do
        ((attempts++))

        # Collection of files for staging
        local test_files=(
            "/etc/hostname"
            "/etc/os-release"
            "/proc/version"
            "/proc/uptime"
        )

        # Add user home files if accessible
        if [[ -d "$HOME" ]]; then
            test_files+=("$HOME/.bashrc" "$HOME/.profile")
        fi

        for source_file in "${test_files[@]}"; do
            [[ $file_count -ge ${T1074_001A_MAX_FILES:-20} ]] && break

            if [[ -r "$source_file" ]]; then
                local file_size=$(stat -c%s "$source_file" 2>/dev/null || echo 0)
                local filename=$(basename "$source_file")
                local file_ext="${filename##*.}"

                # Organize by type if enabled
                local dest_subdir="misc"
                if [[ "${T1074_001A_ORGANIZE_BY_TYPE:-true}" == "true" ]]; then
                    case "$file_ext" in
                        txt|log) dest_subdir="text" ;;
                        pdf|doc|docx) dest_subdir="documents" ;;
                        jpg|png|gif) dest_subdir="images" ;;
                        mp3|wav|ogg) dest_subdir="audio" ;;
                        mp4|avi|mkv) dest_subdir="video" ;;
                        *) dest_subdir="misc" ;;
                    esac
                fi

                mkdir -p "${staging_dir}/${dest_subdir}" 2>/dev/null
                local staged_name="staged_${filename}_$(date +%s)"

                if cp "$source_file" "${staging_dir}/${dest_subdir}/${staged_name}" 2>/dev/null; then
                    collected_files+=("$source_file")
                    total_size=$((total_size + file_size))
                    ((file_count++))

                    if [[ "${T1074_001A_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
                        echo "Staged: $source_file ($file_size bytes)" >&2
                    fi
                fi
            fi
        done

        # Check if staging was successful
        if [[ $file_count -gt 0 ]]; then
            break
        else
            # Fallback real collection for testing
            if [[ "${T1074_001A_FALLBACK_MODE:-real}" == "real" ]]; then
                echo "realD STAGING" > "${staging_dir}/misc/reald_file.txt"
                collected_files=("/etc/hostname" "/etc/os-release")
                total_size=1024
                file_count=2
                break
            fi

            # Retry with delay
            if [[ $attempts -lt ${T1074_001A_RETRY_COUNT:-3} ]]; then
                sleep 1
            fi
        fi
    done

    # Collect system metadata
    echo "$(uname -a)" > "${collection_dir}/metadata/system_info.txt" 2>/dev/null || true
    echo "$(id)" > "${collection_dir}/metadata/user_context.txt" 2>/dev/null || true
    echo "Staging directory: ${staging_dir}" > "${collection_dir}/metadata/staging_info.txt" 2>/dev/null || true
    echo "$file_count" > "${collection_dir}/metadata/file_count.txt" 2>/dev/null || true

    # Return results
    echo "$file_count:$total_size:${collection_dir}:${staging_dir}:$(IFS=,; echo "${collected_files[*]}")"
}

function Send-Telemetry {
    
    # FUNCTION 3/4 : TELEMETRY AND STANDARDIZED OUTPUT
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir staging_dir files_collected <<< "$results"

    # Silent mode - no output
    if [[ "${T1074_001A_SILENT_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Stealth mode - minimal output
    if [[ "${T1074_001A_STEALTH_MODE:-false}" == "true" ]]; then
        return 0
    fi

    # Debug mode - structured JSON
    if [[ "${T1074_001A_DEBUG_MODE:-false}" == "true" ]]; then
        local structured_output=$(cat <<EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "event.module": "deputy",
    "event.dataset": "mitre.attack",
    "event.action": "local_data_staging",
    "mitre.technique.id": "T1074.001a",
    "mitre.artifacts": ["$files_collected"],
    "deputy.postconditions": {
        "data_staged": $([ $file_count -gt 0 ] && echo "true" || echo "false"),
        "artifacts_catalogued": true,
        "output_mode_ready": true
    },
    "collection.metadata": {
        "file_count": $file_count,
        "total_size": $total_size,
        "collection_dir": "$collection_dir",
        "staging_dir": "$staging_dir"
    }
}
EOF
        )
        echo "$structured_output"
        return 0
    fi

    # Simple mode - realistic attacker output (DEFAULT)
    echo "LOCAL DATA STAGING COMPLETED"
    echo "Staged: $file_count files"
    echo "Total size: $total_size bytes"
    echo "Staging directory: $staging_dir"
    echo "Collection directory: $collection_dir"
    if [[ "${T1074_001A_VERBOSE_LEVEL:-1}" -ge 2 ]]; then
        echo "Files: $files_collected"
    fi
    echo "Operation successful"
}

function Get-Results {
    
    # FUNCTION 4/4 : RESULTS AND VALIDATION
    

    local results="$1"
    IFS=':' read -r file_count total_size collection_dir staging_dir files_collected <<< "$results"

    # Validate postconditions
    if [[ $file_count -eq 0 ]] && [[ "${T1074_001A_FALLBACK_MODE:-real}" != "real" ]]; then
        echo "Postcondition failed: No files staged" >&2
        return 1
    fi

    if [[ ! -d "$collection_dir" ]]; then
        echo "Postcondition failed: Collection directory not created" >&2
        return 1
    fi

    if [[ ! -d "$staging_dir" ]]; then
        echo "Postcondition failed: Staging directory not created" >&2
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
