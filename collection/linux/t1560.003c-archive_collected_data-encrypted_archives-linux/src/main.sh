
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1560_003C_DEBUG_MODE="${T1560_003C_DEBUG_MODE:-false}"
    export T1560_003C_TIMEOUT="${T1560_003C_TIMEOUT:-300}"
    export T1560_003C_FALLBACK_MODE="${T1560_003C_FALLBACK_MODE:-real}"
    export T1560_003C_OUTPUT_FORMAT="${T1560_003C_OUTPUT_FORMAT:-json}"
    export T1560_003C_POLICY_CHECK="${T1560_003C_POLICY_CHECK:-true}"
    export T1560_003C_MAX_FILES="${T1560_003C_MAX_FILES:-200}"
    export T1560_003C_MAX_FILE_SIZE="${T1560_003C_MAX_FILE_SIZE:-1048576}"
    export T1560_003C_SCAN_DEPTH="${T1560_003C_SCAN_DEPTH:-3}"
    export T1560_003C_EXCLUDE_CACHE="${T1560_003C_EXCLUDE_CACHE:-true}"
    export T1560_003C_CAPTURE_DURATION="${T1560_003C_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1560.003c - Archive Collected Data: Encrypted Archives Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Create encrypted archives of collected data ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat tar; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1560_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    if ! command -v gpg >/dev/null && ! command -v openssl >/dev/null; then
        [[ "${TT1560_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Encryption tools (gpg or openssl) required"; exit 1
    fi
}

Load-EnvironmentVariables() {
    export T1560_003C_OUTPUT_BASE="${T1560_003C_OUTPUT_BASE:-./mitre_results}"
    export T1560_003C_TIMEOUT="${TT1560_003C_TIMEOUT:-300}"
    export T1560_003C_OUTPUT_MODE="${TT1560_003C_OUTPUT_MODE:-simple}"
    export T1560_003C_SILENT_MODE="${TT1560_003C_SILENT_MODE:-false}"
    export T1560_003C_MAX_ARCHIVES="${T1560_003C_MAX_ARCHIVES:-5}"
    
    export T1560_003C_SOURCE_PATHS="${T1560_003C_SOURCE_PATHS:-./mitre_results}"
    export T1560_003C_ENCRYPTION_METHOD="${T1560_003C_ENCRYPTION_METHOD:-openssl}"
    export T1560_003C_ENCRYPTION_KEY="${T1560_003C_ENCRYPTION_KEY:-auto}"
    export T1560_003C_CIPHER="${T1560_003C_CIPHER:-aes-256-cbc}"
    export T1560_003C_ARCHIVE_NAME="${T1560_003C_ARCHIVE_NAME:-encrypted_data}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1560_003C_OUTPUT_BASE" ]] && { [[ "${TT1560_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1560_003C_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1560_003C_OUTPUT_BASE")" ]] && { [[ "${TT1560_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1560_003C_OUTPUT_BASE/T1560_003c_encrypted_archives_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{encrypted_archives,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Create-EncryptedArchive() {
    local collection_dir="$1" source_path="$2" archive_num="$3"
    
    [[ ! -d "$source_path" ]] && return 1
    
    local archive_name="${T1560_003C_ARCHIVE_NAME}_${archive_num}_$(date +%s)"
    local tar_file="$collection_dir/encrypted_archives/${archive_name}.tar"
    local encrypted_file="$collection_dir/encrypted_archives/${archive_name}.tar.enc"
    local key_file="$collection_dir/encrypted_archives/.encryption_key"
    
    # Create tar archive first
    if tar -cf "$tar_file" -C "$(dirname "$source_path")" "$(basename "$source_path")" 2>/dev/null; then
        
        # Generate encryption key if auto
        local encryption_key
        if [[ "$T1560_003C_ENCRYPTION_KEY" == "auto" ]]; then
            if [[ ! -f "$key_file" ]]; then
                openssl rand -hex 32 > "$key_file" 2>/dev/null
                chmod 600 "$key_file"
            fi
            encryption_key=$(cat "$key_file")
        else
            encryption_key="$T1560_003C_ENCRYPTION_KEY"
        fi
        
        # Encrypt the archive
        case "$T1560_003C_ENCRYPTION_METHOD" in
            "openssl")
                if openssl enc -"$T1560_003C_CIPHER" -salt -in "$tar_file" -out "$encrypted_file" -k "$encryption_key" 2>/dev/null; then
                    rm -f "$tar_file"
                    local file_size=$(stat -c%s "$encrypted_file" 2>/dev/null || echo 0)
                    echo "$encrypted_file:$file_size"
                    [[ "$T1560_003C_SILENT_MODE" != "true" ]] && echo "  + Encrypted: $source_path ($file_size bytes)" >&2
                    return 0
                fi
                ;;
            "gpg")
                if gpg --batch --yes --cipher-algo AES256 --compress-algo 1 --symmetric --passphrase "$encryption_key" --output "$encrypted_file" "$tar_file" 2>/dev/null; then
                    rm -f "$tar_file"
                    local file_size=$(stat -c%s "$encrypted_file" 2>/dev/null || echo 0)
                    echo "$encrypted_file:$file_size"
                    [[ "$T1560_003C_SILENT_MODE" != "true" ]] && echo "  + Encrypted: $source_path ($file_size bytes)" >&2
                    return 0
                fi
                ;;
        esac
        
        rm -f "$tar_file" "$encrypted_file" 2>/dev/null
    fi
    return 1
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "Encryption method: $T1560_003C_ENCRYPTION_METHOD" > "$collection_dir/metadata/encryption_info.txt"
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1560_003C_SILENT_MODE is true
    [[ "$T1560_003C_SILENT_MODE" != "true" && "${TT1560_003C_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "ENCRYPTED ARCHIVES "
    echo "Archives: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1560.003c",
    "results": {
        "archives_created": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1560_003C_SILENT_MODE" != "true" ]] && echo "$json_output"
}

Generate-StealthOutput() { echo "$1" > /dev/null 2>&1; }
Generate-NoneOutput() { :; }
# 4 MAIN ORCHESTRATORS (10-20 lines each)
Get-Configuration() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    echo "$(Initialize-OutputStructure)"
}

Invoke-MicroTechniqueAction() {
    local collection_dir="$1"
    local collected_files=() total_size=0 file_count=0
    
    Log-ExecutionMessage "[INFO] Creating encrypted archives..."
    
    IFS=',' read -ra source_paths <<< "$T1560_003C_SOURCE_PATHS"
    
    local archive_num=1
    for source_path in "${source_paths[@]}"; do
        source_path=$(echo "$source_path" | xargs)
        
        if result=$(Create-EncryptedArchive "$collection_dir" "$source_path" "$archive_num"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            ((archive_num++))
            [[ $file_count -ge ${T1560_003C_MAX_ARCHIVES:-5} ]] && break
        fi
    done
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

Write-StandardizedOutput() {
    case "${OUTPUT_MODE:-simple}" in
        "simple")  Generate-SimpleOutput "$2" "$3" "$1" ;;
        "debug")   Generate-DebugOutput "$2" "$3" "$1" ;;
        "stealth") Generate-StealthOutput "$2" ;;
        "none")    Generate-NoneOutput ;;
    esac
}

Main() {
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    local collection_dir results
    collection_dir=$(Get-Configuration) || exit 2
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected archives created"
    exit 0
}

Main "$@"