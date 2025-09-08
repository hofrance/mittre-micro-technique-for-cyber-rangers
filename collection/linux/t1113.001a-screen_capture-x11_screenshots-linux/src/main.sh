
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1113_001A_DEBUG_MODE="${T1113_001A_DEBUG_MODE:-false}"
    export T1113_001A_TIMEOUT="${T1113_001A_TIMEOUT:-300}"
    export T1113_001A_FALLBACK_MODE="${T1113_001A_FALLBACK_MODE:-real}"
    export T1113_001A_OUTPUT_FORMAT="${T1113_001A_OUTPUT_FORMAT:-json}"
    export T1113_001A_POLICY_CHECK="${T1113_001A_POLICY_CHECK:-true}"
    export T1113_001A_MAX_FILES="${T1113_001A_MAX_FILES:-200}"
    export T1113_001A_MAX_FILE_SIZE="${T1113_001A_MAX_FILE_SIZE:-1048576}"
    export T1113_001A_SCAN_DEPTH="${T1113_001A_SCAN_DEPTH:-3}"
    export T1113_001A_EXCLUDE_CACHE="${T1113_001A_EXCLUDE_CACHE:-true}"
    export T1113_001A_CAPTURE_DURATION="${T1113_001A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1113.001a - Screen Capture: X11 Screenshots Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Capture X11 desktop screenshots ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    # Detect display environment
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
        export DISPLAY_ENV="x11"
    fi
    # Check for Wayland screenshot tools
    if ! command -v import >/dev/null && ! command -v scrot >/dev/null && ! command -v xwd >/dev/null; then
        if command -v gnome-screenshot >/dev/null || command -v wl-screenshot >/dev/null; then
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using Wayland screenshot tools" >&2
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] No screenshot tools available" >&2
            exit 1
        fi
    fi
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    # Check for X11 screenshot tools
    if ! command -v import >/dev/null && ! command -v scrot >/dev/null && ! command -v xwd >/dev/null; then
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] X11 screenshot tools (import, scrot, or xwd) required"; exit 1
    fi
}

# Environment variables loading

# Multi-environment screenshot capture function
Capture-X11Screenshot() {
    local collection_dir="$1" screenshot_num="$2"
    local screenshot_file="$collection_dir/screenshots/screenshot_${screenshot_num}_$(date +%s).${T1113_001A_IMAGE_FORMAT}"
    
    # Detect environment and use appropriate tool
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using Wayland screenshot method" >&2
        if command -v gnome-screenshot >/dev/null; then
            gnome-screenshot --file="$screenshot_file" --include-pointer 2>/dev/null
        elif command -v wl-screenshot >/dev/null; then
            wl-screenshot -o "$screenshot_file" 2>/dev/null
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No Wayland screenshot tool available" >&2
            return 1
        fi
    else
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using X11 screenshot method" >&2
        if command -v scrot >/dev/null; then
            scrot -q "$T1113_001A_IMAGE_QUALITY" "$screenshot_file" 2>/dev/null
        elif command -v import >/dev/null; then
            import -window root -quality "$T1113_001A_IMAGE_QUALITY" "$screenshot_file" 2>/dev/null
        elif command -v xwd >/dev/null; then
            xwd -root -out "$screenshot_file" 2>/dev/null
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No X11 screenshot tool available" >&2
            return 1
        fi
    fi
    
    if [[ -f "$screenshot_file" ]]; then
        local file_size=$(stat -c%s "$screenshot_file" 2>/dev/null || echo "0")
        echo "$screenshot_file:$file_size"
        return 0
    fi
    
    return 1
}
Load-EnvironmentVariables() {
    export T1113_001A_OUTPUT_BASE="${T1113_001A_OUTPUT_BASE:-./mitre_results}"
    export T1113_001A_TIMEOUT="${T1113_001A_TIMEOUT:-300}"
    export T1113_001A_OUTPUT_MODE="${T1113_001A_OUTPUT_MODE:-simple}"
    export T1113_001A_SILENT_MODE="${T1113_001A_SILENT_MODE:-false}"
    export T1113_001A_MAX_SCREENSHOTS="${T1113_001A_SCREENSHOT_COUNT:-2}"
    
    export T1113_001A_DISPLAY_TARGET="${T1113_001A_DISPLAY_TARGET:-${DISPLAY:-:0}}"
    export T1113_001A_SCREENSHOT_COUNT="${T1113_001A_SCREENSHOT_COUNT:-1}"
    export T1113_001A_INTERVAL_SECONDS="${T1113_001A_INTERVAL_SECONDS:-1}"
    export T1113_001A_IMAGE_FORMAT="${T1113_001A_IMAGE_FORMAT:-png}"
    export T1113_001A_IMAGE_QUALITY="${T1113_001A_IMAGE_QUALITY:-85}"
    export T1113_001A_CAPTURE_TOOL="${T1113_001A_CAPTURE_TOOL:-auto}"
    export T1113_001A_INCLUDE_CURSOR="${T1113_001A_INCLUDE_CURSOR:-true}"
    export T1113_001A_FULL_SCREEN="${T1113_001A_FULL_SCREEN:-true}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1113_001A_OUTPUT_BASE" ]] && { [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1113_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1113_001A_OUTPUT_BASE")" ]] && { [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    [[ -z "$T1113_001A_DISPLAY_TARGET" ]] && { [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] No X11 display available"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1113_001A_OUTPUT_BASE/T1113_001a_x11_screenshots_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{screenshots,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# X11 screenshot capture

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    echo "DISPLAY=$DISPLAY" > "$collection_dir/metadata/x11_context.txt"
    xdpyinfo > "$collection_dir/metadata/display_info.txt" 2>/dev/null
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1113_001A_SILENT_MODE is true
    [[ "$T1113_001A_SILENT_MODE" != "true" && "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "X11 SCREENSHOT CAPTURE "
    echo "Screenshots: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1113.001a",
    "results": {
        "screenshots_captured": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1113_001A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
        export DISPLAY_ENV="x11"
    fi
    # Check for Wayland screenshot tools
    if ! command -v import >/dev/null && ! command -v scrot >/dev/null && ! command -v xwd >/dev/null; then
        if command -v gnome-screenshot >/dev/null || command -v wl-screenshot >/dev/null; then
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using Wayland screenshot tools" >&2
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] No screenshot tools available" >&2
            exit 1
        fi
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
    
    Log-ExecutionMessage "[INFO] Capturing X11 screenshots..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    # Ensure variable is not empty
    [[ -z "$T1113_001A_SCREENSHOT_COUNT" ]] && T1113_001A_SCREENSHOT_COUNT="1"
    for i in $(seq 1 "$T1113_001A_SCREENSHOT_COUNT"); do
        if result=$(Capture-X11Screenshot "$collection_dir" "$i"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            
            # Wait between screenshots if multiple
            [[ $i -lt $T1113_001A_SCREENSHOT_COUNT ]] && sleep "$T1113_001A_INTERVAL_SECONDS"
        fi
        [[ $file_count -ge ${T1113_001A_SCREENSHOT_COUNT:-2} ]] && break
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected screenshots captured"
    exit 0
}

# Execute
Main "$@"
# Multi-environment screenshot support
Capture-X11Screenshot() {
    local collection_dir="$1" screenshot_num="$2"
    
    local screenshot_file="$collection_dir/screenshots/screenshot_${screenshot_num}_$(date +%s).${T1113_001A_IMAGE_FORMAT}"
    
    # Detect environment and use appropriate tool
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using Wayland screenshot method" >&2
        if command -v gnome-screenshot >/dev/null; then
            gnome-screenshot --file="$screenshot_file" --include-pointer 2>/dev/null
        elif command -v wl-screenshot >/dev/null; then
            wl-screenshot -o "$screenshot_file" 2>/dev/null
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No Wayland screenshot tool available" >&2
            return 1
        fi
    else
        [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using X11 screenshot method" >&2
        # Try different X11 tools
        if command -v import >/dev/null; then
            import -window root -quality "$T1113_001A_IMAGE_QUALITY" "$screenshot_file" 2>/dev/null
        elif command -v scrot >/dev/null; then
            scrot -q "$T1113_001A_IMAGE_QUALITY" "$screenshot_file" 2>/dev/null
        elif command -v xwd >/dev/null; then
            xwd -root -out "$screenshot_file" 2>/dev/null
        else
            [[ "${T1113_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No X11 screenshot tool available" >&2
            return 1
        fi
    fi
    
    if [[ -f "$screenshot_file" ]]; then
        local file_size=$(stat -c%s "$screenshot_file" 2>/dev/null || echo "0")
        echo "$screenshot_file:$file_size"
        return 0
    fi
    
    return 1
}

# Override the original function
