#!/bin/bash

# t1595.001i - scanning_ip_blocks-zmap_high_speed_tcp_scan
# MITRE ATT&CK Enterprise - Reconnaissance Tactic (TA0043)
# ATOMIC ACTION: Comprehensive network scanning using High-Speed TCP ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier
#  t1595_001i

# FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION

function Get-Configuration {
    echo "[DEBUG] Loading configuration for t1595.001i" >&2

    # Core Configuration
        # Variable TARGETS critique - vérification ajoutée
    export T1595_001i_OUTPUT_BASE="${t1595_001i_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1595_001i_OUTPUT_MODE="${t1595_001i_OUTPUT_MODE:-simple}"
    export T1595_001i_SILENT_MODE="${t1595_001i_SILENT_MODE:-false}"

    # Comprehensive Scanning Configuration
    export T1595_001i_SERVICE_DETECTION="${t1595_001i_SERVICE_DETECTION:-true}"
    export T1595_001i_VERSION_SCANNING="${t1595_001i_VERSION_SCANNING:-true}"
    export T1595_001i_OS_DETECTION="${t1595_001i_OS_DETECTION:-true}"
    export T1595_001i_SCRIPT_SCANNING="${t1595_001i_SCRIPT_SCANNING:-false}"

    # Performance & Timing
    export T1595_001i_TIMING_TEMPLATE="${t1595_001i_TIMING_TEMPLATE:-normal}"
    export T1595_001i_RATE_LIMIT="${t1595_001i_RATE_LIMIT:-0}"
    export T1595_001i_HOST_TIMEOUT="${t1595_001i_HOST_TIMEOUT:-30}"
    export T1595_001i_PARALLELISM="${t1595_001i_PARALLELISM:-5}"

    # Advanced Options
        # Variable CUSTOM_FLAGS critique - vérification ajoutée
    export T1595_001i_EXCLUDE_HOSTS="${t1595_001i_EXCLUDE_HOSTS:-}"
    export T1595_001i_RESOLVE_HOSTNAMES="${t1595_001i_RESOLVE_HOSTNAMES:-true}"
    export T1595_001i_SCRIPT_CATEGORIES="${t1595_001i_SCRIPT_CATEGORIES:-}"

    # Validation des paramètres critiques
    if [[ -z "$t1595_001i_TARGETS" ]]; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] t1595.001i_TARGETS is required" >&2
        return 1
    fi

    # Création répertoire de sortie
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export T1595_001i_RESULTS_DIR="$t1595_001i_OUTPUT_BASE/t1595.001i_${timestamp}"
    mkdir -p "$t1595_001i_RESULTS_DIR" 2>/dev/null || {
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] Cannot create output directory" >&2
        return 1
    }

    return 0

    # ===== VÉRIFICATIONS VARIABLES CRITIQUES =====
    
    # Vérification TARGETS (si utilisée)
    if grep -q "TARGETS" "../reconnaissance/linux/t1595.001i-scanning_ip_blocks-zmap_high_speed_tcp_scan-linux/src/main.sh" && [[ -z "${T1595_001I_TARGETS:-}" ]]; then
        echo "Error: TARGET parameter is required. Please specify target hosts or networks." >&2
        echo "Usage: T1595_001I_TARGETS='192.168.1.0/24' $0" >&2
        return 1
    fi
    
    # Vérification WORDLIST (si utilisée)
    if grep -q "WORDLIST" "../reconnaissance/linux/t1595.001i-scanning_ip_blocks-zmap_high_speed_tcp_scan-linux/src/main.sh" && [[ -z "${T1595_001I_WORDLIST:-}" ]]; then
        echo "Error: WORDLIST parameter is required for scanning." >&2
        return 1
    fi
    
    # Export des variables critiques si elles existent
    [[ -n "${T1595_001I_TARGETS:-}" ]] && export T1595_001I_TARGETS="$T1595_001I_TARGETS"
    [[ -n "${T1595_001I_WORDLIST:-}" ]] && export T1595_001I_WORDLIST="$T1595_001I_WORDLIST"
    
    # ===== FIN VÉRIFICATIONS CRITIQUES =====


    # ===== VARIABLES ESSENTIELLES RECONNAISSANCE =====
    export T1595_001I_DEBUG_MODE="${T1595_001I_DEBUG_MODE:-false}"
    export T1595_001I_TIMEOUT="${T1595_001I_TIMEOUT:-300}"
    export T1595_001I_FALLBACK_MODE="${T1595_001I_FALLBACK_MODE:-simulation}"
    export T1595_001I_OUTPUT_FORMAT="${T1595_001I_OUTPUT_FORMAT:-json}"
    export T1595_001I_POLICY_CHECK="${T1595_001I_POLICY_CHECK:-true}"
    export T1595_001I_RATE_LIMIT="${T1595_001I_RATE_LIMIT:-10}"
    export T1595_001I_MAX_HOSTS="${T1595_001I_MAX_HOSTS:-254}"
    export T1595_001I_SCAN_DEPTH="${T1595_001I_SCAN_DEPTH:-basic}"
    export T1595_001I_TIMING_TEMPLATE="${T1595_001I_TIMING_TEMPLATE:-normal}"
    export T1595_001I_SERVICE_DETECTION="${T1595_001I_SERVICE_DETECTION:-true}"
    # ===== FIN VARIABLES RECONNAISSANCE =====

}
# FUNCTION 2/4 : PRECONDITION CHECK

function Precondition-Check {
    echo "[DEBUG] Checking preconditions for t1595.001i" >&2

    # Vérification OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] This technique requires Linux" >&2
        return 2
    fi

    # Vérification outils
    if [[ "zmap" == "nmap" ]]; then
        if ! command -v nmap &> /dev/null; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] nmap is required but not installed" >&2
            return 2
        fi

        # Vérification version nmap
        local nmap_version=$(nmap --version | head -1 | grep -oP '\d+\.\d+')
        if [[ "$(echo "$nmap_version < 7.0" | bc -l)" -eq 1 ]]; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[WARNING] nmap version $nmap_version detected, 7.0+ recommended" >&2
        fi
    elif [[ "zmap" == "zmap" ]]; then
        if ! command -v zmap &> /dev/null; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] zmap is required but not installed" >&2
            return 2
        fi
    fi

    # Vérification réseau
    if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[WARNING] No internet connectivity detected" >&2
    fi

    # Vérification permissions
    if [[ "$t1595_001i_SCRIPT_SCANNING" == "true" ]] && [[ $EUID -ne 0 ]]; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[WARNING] NSE scripts may require root privileges" >&2
    fi

    # Validation des fichiers cibles
    if [[ -f "$t1595_001i_TARGETS" ]]; then
        if [[ ! -r "$t1595_001i_TARGETS" ]]; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] Target file not readable" >&2
            return 2
        fi
    fi

    return 0
}
# FUNCTION 3/4 : ATOMIC ACTION

function Atomic-Action {
    echo "[DEBUG] Executing atomic action for t1595.001i" >&2

    local scan_results="$t1595_001i_RESULTS_DIR/scan_results.json"
    local technical_details="$t1595_001i_RESULTS_DIR/technical_details.xml"
    local nse_results="$t1595_001i_RESULTS_DIR/nse_results.json"
    local scan_start=$(date +%s)

    # Construction des flags selon l'outil
    local cmd=""
    local output_flags=""

    if [[ "zmap" == "nmap" ]]; then
        cmd="nmap --target-port=80 --output-module=csv --rate=100000"

        # Configuration service detection
        if [[ "$t1595_001i_SERVICE_DETECTION" == "true" ]]; then
            cmd="$cmd -sV"
        fi

        # Configuration version scanning
        if [[ "$t1595_001i_VERSION_SCANNING" == "true" ]]; then
            cmd="$cmd --version-intensity 7"
        fi

        # Configuration OS detection
        if [[ "$t1595_001i_OS_DETECTION" == "true" ]]; then
            cmd="$cmd -O"
        fi

        # Configuration script scanning
        if [[ "$t1595_001i_SCRIPT_SCANNING" == "true" ]]; then
            if [[ -n "$t1595_001i_SCRIPT_CATEGORIES" ]]; then
                cmd="$cmd --script=$t1595_001i_SCRIPT_CATEGORIES"
            else
                cmd="$cmd --script=default"
            fi
        fi

        # Configuration timing
        case "$t1595_001i_TIMING_TEMPLATE" in
            "normal")
                cmd="$cmd -T3"
                ;;
            "aggressive")
                cmd="$cmd -T4"
                ;;
            "insane")
                cmd="$cmd -T5"
                ;;
        esac

        # Configuration rate limiting
        if [[ "$t1595_001i_RATE_LIMIT" != "0" ]]; then
            cmd="$cmd --max-rate $t1595_001i_RATE_LIMIT"
        fi

        # Configuration host timeout
        cmd="$cmd --host-timeout $t1595_001i_HOST_TIMEOUT"

        # Configuration parallélisme
        cmd="$cmd --min-parallelism $t1595_001i_PARALLELISM --max-parallelism $t1595_001i_PARALLELISM"

        # Configuration exclusions
        if [[ -n "$t1595_001i_EXCLUDE_HOSTS" ]]; then
            cmd="$cmd --exclude $t1595_001i_EXCLUDE_HOSTS"
        fi

        # Configuration résolution DNS
        if [[ "$t1595_001i_RESOLVE_HOSTNAMES" == "false" ]]; then
            cmd="$cmd -n"
        fi

        # Flags personnalisés
        if [[ -n "$t1595_001i_CUSTOM_FLAGS" ]]; then
            cmd="$cmd $t1595_001i_CUSTOM_FLAGS"
        fi

        # Cibles et outputs
        cmd="$cmd $t1595_001i_TARGETS"
        output_flags="-oX $technical_details -oG $t1595_001i_RESULTS_DIR/grepable_output.txt"

    elif [[ "zmap" == "zmap" ]]; then
        cmd="zmap --target-port=80 --output-module=csv --rate=100000"

        # Configuration rate limiting (Zmap specific)
        if [[ "$t1595_001i_RATE_LIMIT" != "0" ]]; then
            cmd="$cmd --rate=$t1595_001i_RATE_LIMIT}"
        fi

        # Configuration output
        cmd="$cmd -o $t1595_001i_RESULTS_DIR/zmap_results.csv"

        # Cibles
        cmd="$cmd $t1595_001i_TARGETS"
    fi

    # Exécution du scan
    [[ "$t1595_001i_OUTPUT_MODE" == "debug" ]] && echo "[DEBUG] Executing: $cmd $output_flags" >&2

    if [[ "zmap" == "nmap" ]]; then
        if ! eval "$cmd $output_flags" > "$t1595_001i_RESULTS_DIR/zmap_output.txt" 2>&1; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] zmap scan failed" >&2
            return 3
        fi
    else
        if ! eval "$cmd" > "$t1595_001i_RESULTS_DIR/zmap_output.txt" 2>&1; then
            [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] zmap scan failed" >&2
            return 3
        fi
    fi

    local scan_end=$(date +%s)
    local scan_duration=$((scan_end - scan_start))

    # Traitement des résultats
    if [[ "zmap" == "nmap" ]] && [[ -f "$technical_details" ]]; then
        # Extraction des statistiques de base
        local hosts_up=$(grep -c "host.*state=\"up\"" "$technical_details" 2>/dev/null || echo "0")
        local ports_open=$(grep -c "port.*state=\"open\"" "$technical_details" 2>/dev/null || echo "0")
        local services_identified=$(grep -c "service.*name=" "$technical_details" 2>/dev/null || echo "0")
        local os_fingerprinted=$(grep -c "osmatch" "$technical_details" 2>/dev/null || echo "0")

        # Création du rapport JSON
        cat > "$scan_results" << JSON_EOF
{
  "technique_id": "t1595.001i",
  "technique_name": "scanning_ip_blocks-zmap_high_speed_tcp_scan",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_type": "High-Speed TCP",
  "tool_used": "zmap",
  "scan_duration_seconds": $scan_duration,
  "configuration": {
    "service_detection": $t1595_001i_SERVICE_DETECTION,
    "version_scanning": $t1595_001i_VERSION_SCANNING,
    "os_detection": $t1595_001i_OS_DETECTION,
    "script_scanning": $t1595_001i_SCRIPT_SCANNING,
    "timing_template": "$t1595_001i_TIMING_TEMPLATE",
    "rate_limit": $t1595_001i_RATE_LIMIT
  },
  "results": {
    "hosts_discovered": $hosts_up,
    "ports_found": $ports_open,
    "services_identified": $services_identified,
    "os_fingerprinted": $os_fingerprinted,
    "scan_successful": true
  }
}
JSON_EOF

    elif [[ "zmap" == "zmap" ]] && [[ -f "$t1595_001i_RESULTS_DIR/zmap_results.csv" ]]; then
        # Traitement résultats Zmap
        local lines_count=$(wc -l < "$t1595_001i_RESULTS_DIR/zmap_results.csv" 2>/dev/null || echo "0")

        cat > "$scan_results" << JSON_EOF
{
  "technique_id": "t1595.001i",
  "technique_name": "scanning_ip_blocks-zmap_high_speed_tcp_scan",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_type": "High-Speed TCP",
  "tool_used": "zmap",
  "scan_duration_seconds": $scan_duration,
  "configuration": {
    "rate_limit": $t1595_001i_RATE_LIMIT
  },
  "results": {
    "responses_received": $lines_count,
    "scan_successful": true
  }
}
JSON_EOF
    else
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] No scan results generated" >&2
        return 3
    fi

    return 0
}
# FUNCTION 4/4 : POSTCONDITION VERIFY

function Postcondition-Verify {
    echo "[DEBUG] Verifying postconditions for t1595.001i" >&2

    local results_dir="$t1595_001i_RESULTS_DIR"
    local scan_results="$results_dir/scan_results.json"

    # Vérification fichiers de sortie
    if [[ ! -f "$scan_results" ]]; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] Scan results file missing" >&2
        return 4
    fi

    # Validation contenu JSON
    if ! jq empty "$scan_results" 2>/dev/null; then
        [[ "$t1595_001i_SILENT_MODE" != "true" ]] && echo "[ERROR] Invalid JSON in scan results" >&2
        return 4
    fi

    # Création métadonnées d'exécution
    local metadata_file="$results_dir/metadata/execution_metadata.json"
    mkdir -p "$results_dir/metadata"

    cat > "$metadata_file" << META_EOF
{
  "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "technique_id": "t1595.001i",
  "technique_name": "scanning_ip_blocks-zmap_high_speed_tcp_scan",
  "tool_used": "zmap",
  "execution_mode": "$t1595_001i_OUTPUT_MODE",
  "silent_mode": "$t1595_001i_SILENT_MODE",
  "results_directory": "$results_dir",
  "files_generated": $(find "$results_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$results_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration_snapshot": {
    "targets": "$t1595_001i_TARGETS",
    "service_detection": $t1595_001i_SERVICE_DETECTION,
    "version_scanning": $t1595_001i_VERSION_SCANNING,
    "timing_template": "$t1595_001i_TIMING_TEMPLATE",
    "rate_limit": $t1595_001i_RATE_LIMIT
  }
}
META_EOF

    return 0
}
# MAIN EXECUTION ORCHESTRATOR

main() {
    # Orchestration des fonctions contractuelles
    Get-Configuration || exit $?
    Precondition-Check || exit $?
    Atomic-Action || exit $?

    # Sortie selon le mode
    case "$t1595_001i_OUTPUT_MODE" in
        "debug")
            echo "[DEBUG] scanning_ip_blocks-zmap_high_speed_tcp_scan completed successfully" >&2
            echo "[DEBUG] Results saved to: $t1595_001i_RESULTS_DIR" >&2
            find "$t1595_001i_RESULTS_DIR" -name "*.json" -o -name "*.xml" -o -name "*.csv" | while read -r file; do
                echo "[DEBUG] Generated: $file" >&2
            done
            ;;
        "simple")
            echo "[SUCCESS] scanning_ip_blocks-zmap_high_speed_tcp_scan completed" >&2
            echo "[INFO] Results saved to: $t1595_001i_RESULTS_DIR" >&2
            ;;
        "stealth")
            # Sortie minimale pour les opérations furtives
            ;;
        "silent")
            # Aucune sortie
            ;;
        *)
            echo "[INFO] scanning_ip_blocks-zmap_high_speed_tcp_scan completed" >&2
            ;;
    esac

    Postcondition-Verify || exit $?
}
# SCRIPT ENTRY POINT

main "$@"
