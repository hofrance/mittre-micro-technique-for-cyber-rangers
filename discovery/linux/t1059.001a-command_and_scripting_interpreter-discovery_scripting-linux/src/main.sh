
    # ===== VARIABLES ESSENTIELLES DISCOVERY =====
    export T1059_001A_DEBUG_MODE="${T1059_001A_DEBUG_MODE:-false}"
    export T1059_001A_TIMEOUT="${T1059_001A_TIMEOUT:-300}"
    export T1059_001A_FALLBACK_MODE="${T1059_001A_FALLBACK_MODE:-simulate}"
    export T1059_001A_OUTPUT_FORMAT="${T1059_001A_OUTPUT_FORMAT:-json}"
    export T1059_001A_POLICY_CHECK="${T1059_001A_POLICY_CHECK:-true}"
    export T1059_001A_MAX_SERVICES="${T1059_001A_MAX_SERVICES:-200}"
    export T1059_001A_INCLUDE_SYSTEM="${T1059_001A_INCLUDE_SYSTEM:-true}"
    export T1059_001A_DETAIL_LEVEL="${T1059_001A_DETAIL_LEVEL:-standard}"
    export T1059_001A_RESOLVE_HOSTNAMES="${T1059_001A_RESOLVE_HOSTNAMES:-true}"
    export T1059_001A_MAX_PROCESSES="${T1059_001A_MAX_PROCESSES:-500}"
    # ===== FIN VARIABLES DISCOVERY =====

#!/bin/bash

# T1059.001a - Command and Scripting Interpreter: Discovery Scripting Linux
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover command and scripting interpreters ONLY
# Platform: Linux | Architecture: 4 orchestrators + auxiliary functions

# Critical dependencies verification
Check-CriticalDeps() { 
    local missing_deps=()
    local required_deps=("bash" "jq" "grep" "cat" "awk" "cut" "tr" "sort" "uniq" "wc" "stat" "ls" "which" "command" "type")
    
    [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] Checking critical dependencies..." >&2
    
    for cmd in "${required_deps[@]}"; do 
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        else
            [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "  + Found: $cmd" >&2
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo ""
        [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  x Missing: $dep"
        done
        echo ""
        echo "INSTALLATION COMMANDS:"
        echo "Ubuntu/Debian: sudo apt-get install -y ${missing_deps[*]}"
        echo "CentOS/RHEL:   sudo dnf install -y ${missing_deps[*]}"
        echo "Arch Linux:    sudo pacman -S ${missing_deps[*]}"
        echo ""
        exit 1
    fi
    
    [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[INFO] All dependencies satisfied" >&2
}

# Environment variables loading
Load-EnvironmentVariables() {
    export T1059_001A_OUTPUT_BASE="${T1059_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1059_001A_TIMEOUT="${T1059_001A_TIMEOUT:-300}"
    export T1059_001A_OUTPUT_MODE="${T1059_001A_OUTPUT_MODE:-simple}"
    export T1059_001A_SILENT_MODE="${T1059_001A_SILENT_MODE:-false}"
    export T1059_001A_INCLUDE_SHELLS="${T1059_001A_INCLUDE_SHELLS:-true}"
    export T1059_001A_INCLUDE_SCRIPTS="${T1059_001A_INCLUDE_SCRIPTS:-true}"
    export T1059_001A_INCLUDE_LANGUAGES="${T1059_001A_INCLUDE_LANGUAGES:-true}"
    export T1059_001A_SCAN_PATHS="${T1059_001A_SCAN_PATHS:-/usr/bin,/usr/local/bin,/opt,/home}"
}

# System preconditions validation
Validate-SystemPreconditions() {
    [[ -z "$T1059_001A_OUTPUT_BASE" ]] && { [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] TT1059.001A_TT1059_001A_OUTPUT_BASE not set"; return 1; }
    [[ ! -w "$(dirname "$T1059_001A_OUTPUT_BASE")" ]] && { [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[ERROR] Output directory not writable"; return 1; }
    return 0
}

# Output structure initialization
Initialize-OutputStructure() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export DISCOVERY_DIR="$T1059_001A_OUTPUT_BASE/T1059_001a_discovery_scripting_$timestamp"
    mkdir -p "$DISCOVERY_DIR"/{interpreters,metadata} 2>/dev/null || return 1
    chmod 700 "$DISCOVERY_DIR" 2>/dev/null
    echo "$DISCOVERY_DIR"
}

# Shell discovery
Discover-Shells() {
    local discovery_dir="$1"
    
    if [[ "$T1059_001A_INCLUDE_SHELLS" == "true" ]]; then
        local shells_file="$discovery_dir/interpreters/shells.json"
        
        # Common shells
        local shells=("bash" "sh" "zsh" "fish" "tcsh" "csh" "ksh" "dash" "ash" "busybox")
        local shell_info=()
        
        for shell in "${shells[@]}"; do
            local shell_path=$(which "$shell" 2>/dev/null)
            if [[ -n "$shell_path" ]]; then
                local shell_version=$("$shell" --version 2>/dev/null | head -1 | cut -d' ' -f4- | tr -d '"' || echo "Unknown")
                local shell_size=$(stat -c%s "$shell_path" 2>/dev/null || echo "0")
                
                shell_info+=("{\"name\":\"$shell\",\"path\":\"$shell_path\",\"version\":\"$shell_version\",\"size\":\"$shell_size\"}")
            fi
        done
        
        # Create JSON output
        cat > "$shells_file" << EOF
{
    "technique": "T1059.001a",
    "component": "shells",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "shells": [$(IFS=,; echo "${shell_info[*]}")]
}
EOF
        
        echo "SHELLS:${#shell_info[@]}"
    fi
}

# Script discovery
Discover-Scripts() {
    local discovery_dir="$1"
    
    if [[ "$T1059_001A_INCLUDE_SCRIPTS" == "true" ]]; then
        local scripts_file="$discovery_dir/interpreters/scripts.json"
        
        # Find script files
        local script_files=()
        IFS=',' read -ra scan_paths <<< "$T1059_001A_SCAN_PATHS"
        
        for scan_path in "${scan_paths[@]}"; do
            scan_path=$(echo "$scan_path" | xargs)
            if [[ -d "$scan_path" ]]; then
                while IFS= read -r -d '' script_file; do
                    script_files+=("$script_file")
                done < <(find "$scan_path" -type f -executable -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" -o -name "*.js" -o -name "*.php" 2>/dev/null | head -50)
            fi
        done
        
        # Create JSON output
        cat > "$scripts_file" << EOF
{
    "technique": "T1059.001a",
    "component": "scripts",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scripts_found": ${#script_files[@]},
    "script_files": [$(printf '"%s"' "${script_files[@]}" | tr '\n' ',' | sed 's/,$//')]
}
EOF
        
        echo "SCRIPTS:${#script_files[@]}"
    fi
}

# Language discovery
Discover-Languages() {
    local discovery_dir="$1"
    
    if [[ "$T1059_001A_INCLUDE_LANGUAGES" == "true" ]]; then
        local languages_file="$discovery_dir/interpreters/languages.json"
        
        # Common programming languages
        local languages=("python" "perl" "ruby" "node" "php" "java" "gcc" "g++" "go" "rustc" "cargo" "dotnet" "mono")
        local language_info=()
        
        for lang in "${languages[@]}"; do
            local lang_path=$(which "$lang" 2>/dev/null)
            if [[ -n "$lang_path" ]]; then
                local lang_version=$("$lang" --version 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '"' || echo "Unknown")
                local lang_size=$(stat -c%s "$lang_path" 2>/dev/null || echo "0")
                
                language_info+=("{\"name\":\"$lang\",\"path\":\"$lang_path\",\"version\":\"$lang_version\",\"size\":\"$lang_size\"}")
            fi
        done
        
        # Create JSON output
        cat > "$languages_file" << EOF
{
    "technique": "T1059.001a",
    "component": "languages",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "languages": [$(IFS=,; echo "${language_info[*]}")]
}
EOF
        
        echo "LANGUAGES:${#language_info[@]}"
    fi
}

# System metadata collection
Collect-SystemMetadata() {
    local discovery_dir="$1"
    
    # Try to write metadata files, ignore errors
    echo "$(uname -a)" > "$discovery_dir/metadata/system_info.txt" 2>/dev/null || [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] Could not write system_info.txt" >&2
    echo "$(id)" > "$discovery_dir/metadata/user_context.txt" 2>/dev/null || [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] Could not write user_context.txt" >&2
    echo "$(pwd)" > "$discovery_dir/metadata/working_dir.txt" 2>/dev/null || [[ "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "[WARNING] Could not write working_dir.txt" >&2
}

# Execution message logging
Log-ExecutionMessage() {
    [[ "${T1059_001A_SILENT_MODE}" != "true" && "${T1059_001A_OUTPUT_MODE:-simple}" != "stealth" ]] && echo "$1" >&2
}

# Simple output generation
Generate-SimpleOutput() {
    local components_discovered="$1" discovery_dir="$2"
    echo "COMMAND AND SCRIPTING INTERPRETER DISCOVERY"
    echo "Components: $components_discovered"
    echo "Complete"
}

# Debug output generation
Generate-DebugOutput() {
    local components_discovered="$1" discovery_dir="$2"
    local json_output=$(cat << EOF
{
    "@timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "technique": "T1059.001a",
    "results": {
        "components_discovered": $components_discovered,
        "discovery_directory": "$discovery_dir"
    }
}
EOF
)
    echo "$json_output" > "$discovery_dir/metadata/results.json"
    [[ "$T1059_001A_SILENT_MODE" != "true" ]] && echo "$json_output"
}

# Stealth output generation
Generate-StealthOutput() {
    local components_discovered="$1"
    echo "$components_discovered" > /dev/null 2>&1
}

# None output generation
Generate-NoneOutput() {
    : # No output
}

# 4 MAIN ORCHESTRATORS (10-20 lines each)

# Function 1: Configuration (10-20 lines) - Orchestrator
Get-Configuration() {
    Check-CriticalDeps || exit 1
    Load-EnvironmentVariables
    Validate-SystemPreconditions || exit 1
    
    local discovery_dir
    discovery_dir=$(Initialize-OutputStructure) || exit 1
    
    echo "$discovery_dir"
}

# Function 2: Atomic Action (10-20 lines) - Orchestrator
Invoke-MicroTechniqueAction() {
    local discovery_dir="$1"
    local discovered_components=() component_count=0
    
    Log-ExecutionMessage "[INFO] Performing command and scripting interpreter discovery..."
    
    # ATOMIC ACTION: Orchestration of auxiliary functions
    if [[ "$T1059_001A_INCLUDE_SHELLS" == "true" ]]; then
        if result=$(Discover-Shells "$discovery_dir"); then
            discovered_components+=("$result")
            ((component_count++))
        fi
    fi
    
    if [[ "$T1059_001A_INCLUDE_SCRIPTS" == "true" ]]; then
        if result=$(Discover-Scripts "$discovery_dir"); then
            discovered_components+=("$result")
            ((component_count++))
        fi
    fi
    
    if [[ "$T1059_001A_INCLUDE_LANGUAGES" == "true" ]]; then
        if result=$(Discover-Languages "$discovery_dir"); then
            discovered_components+=("$result")
            ((component_count++))
        fi
    fi
    
    Collect-SystemMetadata "$discovery_dir"
    echo "$component_count:$(IFS=,; echo "${discovered_components[*]}")"
}

# Function 3: Output (10-20 lines) - Orchestrator
Write-StandardizedOutput() {
    local discovery_dir="$1" components_discovered="$2"
    
    case "${TT1059_001A_OUTPUT_MODE:-simple}" in
        "simple")  Generate-SimpleOutput "$components_discovered" "$discovery_dir" ;;
        "debug")   Generate-DebugOutput "$components_discovered" "$discovery_dir" ;;
        "stealth") Generate-StealthOutput "$components_discovered" ;;
        "none")    Generate-NoneOutput ;;
    esac
}

# Function 4: Main (10-15 lines) - Chief Orchestrator
Main() {
    trap 'echo "[INTERRUPTED] Cleaning up..."; exit 130' INT TERM
    
    # Load environment variables in main context
    Load-EnvironmentVariables
    
    local discovery_dir
    discovery_dir=$(Get-Configuration) || exit 2
    
    local results
    results=$(Invoke-MicroTechniqueAction "$discovery_dir") || exit 1
    
    IFS=':' read -r components_discovered _ <<< "$results"
    Write-StandardizedOutput "$discovery_dir" "$components_discovered"
    
    Log-ExecutionMessage "[SUCCESS] Completed: $components_discovered components discovered"
    exit 0
}

# Execute
Main "$@"
