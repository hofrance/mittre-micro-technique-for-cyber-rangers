
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1113_006F_DEBUG_MODE="${T1113_006F_DEBUG_MODE:-false}"
    export T1113_006F_TIMEOUT="${T1113_006F_TIMEOUT:-300}"
    export T1113_006F_FALLBACK_MODE="${T1113_006F_FALLBACK_MODE:-real}"
    export T1113_006F_OUTPUT_FORMAT="${T1113_006F_OUTPUT_FORMAT:-json}"
    export T1113_006F_POLICY_CHECK="${T1113_006F_POLICY_CHECK:-true}"
    export T1113_006F_MAX_FILES="${T1113_006F_MAX_FILES:-200}"
    export T1113_006F_MAX_FILE_SIZE="${T1113_006F_MAX_FILE_SIZE:-1048576}"
    export T1113_006F_SCAN_DEPTH="${T1113_006F_SCAN_DEPTH:-3}"
    export T1113_006F_EXCLUDE_CACHE="${T1113_006F_EXCLUDE_CACHE:-true}"
    export T1113_006F_CAPTURE_DURATION="${T1113_006F_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1113.006f - Screen Capture: Window Specific Capture Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Capture specific window screenshots ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    # Detect display environment
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
        export DISPLAY_ENV="x11"
    fi
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    # Check for window capture tools
    if ! command -v import >/dev/null && ! command -v scrot >/dev/null; then
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Window capture tools (import or scrot) required"; exit 1
    fi
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1113_006F_OUTPUT_BASE="${T1113_006F_OUTPUT_BASE:-./mitre_results}"
    export TT1113_006F_TIMEOUT="${TT1113_006F_TIMEOUT:-300}"
    export TT1113_006F_OUTPUT_MODE="${TT1113_006F_OUTPUT_MODE:-simple}"
    export TT1113_006F_SILENT_MODE="${TT1113_006F_SILENT_MODE:-false}"
    export T1113_006F_MAX_WINDOWS="${T1113_006F_MAX_WINDOWS:-10}"
    
    export T1113_006F_DISPLAY_TARGET="${T1113_006F_DISPLAY_TARGET:-${DISPLAY:-:0}}"
    export T1113_006F_TARGET_WINDOWS="${T1113_006F_TARGET_WINDOWS:-auto}"
    export T1113_006F_WINDOW_PATTERNS="${T1113_006F_WINDOW_PATTERNS:-browser,terminal,editor}"
    export T1113_006F_IMAGE_FORMAT="${T1113_006F_IMAGE_FORMAT:-png}"
    export T1113_006F_IMAGE_QUALITY="${T1113_006F_IMAGE_QUALITY:-85}"
    export T1113_006F_INCLUDE_DECORATIONS="${T1113_006F_INCLUDE_DECORATIONS:-false}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1113_006F_OUTPUT_BASE" ]] && { [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1113_006F_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1113_006F_OUTPUT_BASE")" ]] && { [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    [[ -z "$T1113_006F_DISPLAY_TARGET" ]] && { [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] No X11 display available"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1113_006F_OUTPUT_BASE/T1113_006f_window_capture_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{window_screenshots,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# Window-specific screenshot capture
Capture-WindowScreenshot() {
    local collection_dir="$1" window_id="$2" window_name="$3"
    
    local screenshot_file="$collection_dir/window_screenshots/window_${window_name//[^a-zA-Z0-9]/_}_$(date +%s).${T1113_006F_IMAGE_FORMAT}"
    
    if command -v import >/dev/null; then
        local import_args=("-window" "$window_id" "-quality" "$T1113_006F_IMAGE_QUALITY")
        [[ "$T1113_006F_INCLUDE_DECORATIONS" == "false" ]] && import_args+=("-crop" "0x0")
        
        if import "${import_args[@]}" "$screenshot_file" 2>/dev/null; then
            local file_size=$(stat -c%s "$screenshot_file" 2>/dev/null || echo 0)
            echo "$screenshot_file:$file_size"
            [[ "$TT1113_006F_SILENT_MODE" != "true" ]] && echo "  + Captured: Window $window_name ($file_size bytes)" >&2
            return 0
        fi
    elif command -v scrot >/dev/null; then
        if scrot -s -q "$T1113_006F_IMAGE_QUALITY" "$screenshot_file" 2>/dev/null; then
            local file_size=$(stat -c%s "$screenshot_file" 2>/dev/null || echo 0)
            echo "$screenshot_file:$file_size"
            [[ "$TT1113_006F_SILENT_MODE" != "true" ]] && echo "  + Captured: Window $window_name ($file_size bytes)" >&2
            return 0
        fi
    fi
    return 1
}

# Get target windows
Get-TargetWindows() {
    if [[ "$T1113_006F_TARGET_WINDOWS" == "auto" ]]; then
        IFS=',' read -ra patterns <<< "$T1113_006F_WINDOW_PATTERNS"
        
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs)
            xwininfo -tree -root 2>/dev/null | grep -i "$pattern" | head -5 | while read -r line; do
                local window_id=$(echo "$line" | grep -o '0x[0-9a-f]*')
                local window_name=$(echo "$line" | sed 's/.*"\([^"]*\)".*/\1/')
                [[ -n "$window_id" ]] && echo "$window_id:$window_name"
            done
        done
    else
        IFS=',' read -ra windows <<< "$T1113_006F_TARGET_WINDOWS"
        for window in "${windows[@]}"; do
            window=$(echo "$window" | xargs)
            echo "$window:manual"
        done
    fi
}

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "DISPLAY=$DISPLAY" > "$collection_dir/metadata/display_context.txt"
    xwininfo -tree -root > "$collection_dir/metadata/window_tree.txt" 2>/dev/null
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1113_006F_SILENT_MODE is true
    [[ "$TT1113_006F_SILENT_MODE" != "true" && "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "WINDOW CAPTURE "
    echo "Windows: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1113.006f",
    "results": {
        "windows_captured": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$TT1113_006F_SILENT_MODE" != "true" ]] && echo "$json_output"
}

# Stealth output generation
Generate-StealthOutput() {
    local files_collected="$1"
    echo "$files_collected" > /dev/null 2>&1
}

# None output generation
Generate-NoneOutput() {
    : # No output
}
# 4 MAIN ORCHESTRATORS (10-20 lines each)
# Function 1: Configuration (10-20 lines) - Orchestrator
Get-Configuration() {
    Check-CriticalDeps || exit 1
    # Detect display environment
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
        export DISPLAY_ENV="x11"
    fi
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    
    local collection_dir
    collection_dir=$(Initialize-OutputStructure) || exit 1
    
    echo "$collection_dir"
}

# Function 2: Atomic Action (10-20 lines) - Orchestrator
Invoke-MicroTechniqueAction() {
    local collection_dir="$1"
    local collected_files=() total_size=0 file_count=0
    
    Log-ExecutionMessage "[INFO] Capturing window screenshots..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    local target_windows
    target_windows=($(Get-TargetWindows))
    
    for window_info in "${target_windows[@]}"; do
        IFS=':' read -r window_id window_name <<< "$window_info"
        
        if result=$(Capture-WindowScreenshot "$collection_dir" "$window_id" "$window_name"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            [[ $file_count -ge ${T1113_006F_MAX_WINDOWS:-10} ]] && break
        fi
    done
    
    Collect-SystemMetadata "$collection_dir"
    echo "$file_count:$total_size:$(IFS=,; echo "${collected_files[*]}")"
}

# Function 3: Output (10-20 lines) - Orchestrator
Write-StandardizedOutput() {
    local collection_dir="$1" files_collected="$2" total_size="$3"
    
    case "${OUTPUT_MODE:-simple}" in
        "simple")  Generate-SimpleOutput "$files_collected" "$total_size" "$collection_dir" ;;
        "debug")   Generate-DebugOutput "$files_collected" "$total_size" "$collection_dir" ;;
        "stealth") Generate-StealthOutput "$files_collected" ;;
        "none")    Generate-NoneOutput ;;
    esac
}

# Function 4: Main (10-15 lines) - Chief Orchestrator
Main() {
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    # Load environment variables in main context
    Load-EnvironmentVariables

    local collection_dir
    collection_dir=$(Get-Configuration) || exit 2
    
    local results
    results=$(Invoke-MicroTechniqueAction "$collection_dir") || exit 1
    
    IFS=':' read -r files_collected total_size _ <<< "$results"
    Write-StandardizedOutput "$collection_dir" "$files_collected" "$total_size"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected windows captured"
    exit 0
}

# Execute
Main "$@"
# Simple window capture function
Capture-WindowSpecific() {
    local collection_dir="$1" window_num="$2"
    local image_file="$collection_dir/windows/window_${window_num}_$(date +%s).png"
    
    mkdir -p "$(dirname "$image_file")" 2>/dev/null || true
    
    if command -v import >/dev/null; then
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using ImageMagick for window capture" >&2
        import -window root "$image_file" 2>/dev/null
    elif command -v scrot >/dev/null; then
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using scrot for window capture" >&2
        scrot "$image_file" 2>/dev/null
    else
        [[ "${TT1113_006F_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No window capture tool available" >&2
        return 1
    fi
    
    if [[ -f "$image_file" && -s "$image_file" ]]; then
        local file_size=$(stat -c%s "$image_file" 2>/dev/null || echo "0")
        echo "$image_file:$file_size"
        return 0
    fi
    
    return 1
}
