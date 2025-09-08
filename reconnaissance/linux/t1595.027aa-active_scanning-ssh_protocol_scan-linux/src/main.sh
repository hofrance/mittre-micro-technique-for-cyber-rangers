#!/bin/bash

# T1595_027AA - active_scanning-ssh_protocol_scan
# MITRE ATT&CK Enterprise - Reconnaissance Tactic (TA0043)
# ATOMIC ACTION: SSH protocol scanning using specialized techniques ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier
#  T1595_027AA

# FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION

function Get-Configuration {
    echo "[DEBUG] Loading configuration for T1595_027AA" >&2

    # Core Configuration
        # Variable TARGETS critique - vérification ajoutée
    export T1595_027aa_OUTPUT_BASE="${T1595_027AA_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1595_027aa_OUTPUT_MODE="${T1595_027AA_OUTPUT_MODE:-simple}"
    export T1595_027aa_SILENT_MODE="${T1595_027AA_SILENT_MODE:-false}"

    # Protocol-Specific Configuration
    export T1595_027aa_PROTOCOL_PORTS="${T1595_027AA_PROTOCOL_PORTS:-22}"
    export T1595_027aa_VERSION_DETECTION="${T1595_027AA_VERSION_DETECTION:-true}"
    export T1595_027aa_SCRIPT_SCANNING="${T1595_027AA_SCRIPT_SCANNING:-false}"
    export T1595_027aa_SERVICE_DETECTION="${T1595_027AA_SERVICE_DETECTION:-true}"

    # Performance & Timing
    export T1595_027aa_TIMING_TEMPLATE="${T1595_027AA_TIMING_TEMPLATE:-normal}"
    export T1595_027aa_RATE_LIMIT="${T1595_027AA_RATE_LIMIT:-50}"
    export T1595_027aa_TIMEOUT="${T1595_027AA_TIMEOUT:-10}"
    export T1595_027aa_PARALLELISM="${T1595_027AA_PARALLELISM:-3}"

    # Advanced Options
        # Variable CUSTOM_FLAGS critique - vérification ajoutée
    export T1595_027aa_EXCLUDE_HOSTS="${T1595_027AA_EXCLUDE_HOSTS:-}"
    export T1595_027aa_SCRIPT_CATEGORIES="${T1595_027AA_SCRIPT_CATEGORIES:-}"
    export T1595_027aa_RESOLVE_HOSTNAMES="${T1595_027AA_RESOLVE_HOSTNAMES:-true}"

    # Validation des paramètres critiques
    if [[ -z "$T1595_027AA_TARGETS" ]]; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] T1595_027AA_TARGETS is required" >&2
        return 1
    fi

    # Création répertoire de sortie
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export T1595_027aa_RESULTS_DIR="$T1595_027AA_OUTPUT_BASE/T1595_027AA_${timestamp}"
    mkdir -p "$T1595_027AA_RESULTS_DIR" 2>/dev/null || {
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] Cannot create output directory" >&2
        return 1
    }

    return 0

    # ===== VÉRIFICATIONS VARIABLES CRITIQUES =====
    
    # Vérification TARGETS (si utilisée)
    if grep -q "TARGETS" "../reconnaissance/linux/t1595.027aa-active_scanning-ssh_protocol_scan-linux/src/main.sh" && [[ -z "${T1595_027A_TARGETS:-}" ]]; then
        echo "Error: TARGET parameter is required. Please specify target hosts or networks." >&2
        echo "Usage: T1595_027A_TARGETS='192.168.1.0/24' $0" >&2
        return 1
    fi
    
    # Vérification WORDLIST (si utilisée)
    if grep -q "WORDLIST" "../reconnaissance/linux/t1595.027aa-active_scanning-ssh_protocol_scan-linux/src/main.sh" && [[ -z "${T1595_027A_WORDLIST:-}" ]]; then
        echo "Error: WORDLIST parameter is required for scanning." >&2
        return 1
    fi
    
    # Export des variables critiques si elles existent
    [[ -n "${T1595_027A_TARGETS:-}" ]] && export T1595_027A_TARGETS="$T1595_027A_TARGETS"
    [[ -n "${T1595_027A_WORDLIST:-}" ]] && export T1595_027A_WORDLIST="$T1595_027A_WORDLIST"
    
    # ===== FIN VÉRIFICATIONS CRITIQUES =====


    # ===== VARIABLES ESSENTIELLES RECONNAISSANCE =====
    export T1595_027A_DEBUG_MODE="${T1595_027A_DEBUG_MODE:-false}"
    export T1595_027A_TIMEOUT="${T1595_027A_TIMEOUT:-300}"
    export T1595_027A_FALLBACK_MODE="${T1595_027A_FALLBACK_MODE:-simulation}"
    export T1595_027A_OUTPUT_FORMAT="${T1595_027A_OUTPUT_FORMAT:-json}"
    export T1595_027A_POLICY_CHECK="${T1595_027A_POLICY_CHECK:-true}"
    export T1595_027A_RATE_LIMIT="${T1595_027A_RATE_LIMIT:-10}"
    export T1595_027A_MAX_HOSTS="${T1595_027A_MAX_HOSTS:-254}"
    export T1595_027A_SCAN_DEPTH="${T1595_027A_SCAN_DEPTH:-basic}"
    export T1595_027A_TIMING_TEMPLATE="${T1595_027A_TIMING_TEMPLATE:-normal}"
    export T1595_027A_SERVICE_DETECTION="${T1595_027A_SERVICE_DETECTION:-true}"
    # ===== FIN VARIABLES RECONNAISSANCE =====

}
# FUNCTION 2/4 : PRECONDITION CHECK

function Precondition-Check {
    echo "[DEBUG] Checking preconditions for T1595_027AA" >&2

    # Vérification OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] This technique requires Linux" >&2
        return 2
    fi

    # Vérification outils
    if ! command -v nmap &> /dev/null; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] nmap is required but not installed" >&2
        return 2
    fi

    # Vérification version nmap
    local nmap_version=$(nmap --version | head -1 | grep -oP '\d+\.\d+')
    if [[ "$(echo "$nmap_version < 7.0" | bc -l)" -eq 1 ]]; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[WARNING] nmap version $nmap_version detected, 7.0+ recommended" >&2
    fi

    # Vérification réseau
    if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[WARNING] No internet connectivity detected" >&2
    fi

    # Vérification NSE scripts si activés
    if [[ "$T1595_027AA_SCRIPT_SCANNING" == "true" ]]; then
        if [[ ! -d "/usr/share/nmap/scripts" ]] && [[ ! -d "/usr/local/share/nmap/scripts" ]]; then
            [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[WARNING] NSE scripts directory not found" >&2
        fi
    fi

    # Validation des fichiers cibles
    if [[ -f "$T1595_027AA_TARGETS" ]]; then
        if [[ ! -r "$T1595_027AA_TARGETS" ]]; then
            [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] Target file not readable" >&2
            return 2
        fi
    fi

    return 0
}
# FUNCTION 3/4 : ATOMIC ACTION

function Atomic-Action {
    echo "[DEBUG] Executing atomic action for T1595_027AA" >&2

    local scan_results="$T1595_027AA_RESULTS_DIR/scan_results.json"
    local technical_details="$T1595_027AA_RESULTS_DIR/technical_details.xml"
    local nse_results="$T1595_027AA_RESULTS_DIR/nse_results.json"
    local scan_start=$(date +%s)

    # Construction des flags nmap pour le protocole spécifique
    local nmap_cmd="nmap -sV -p 22 --script=ssh* -T4"

    # Configuration ports spécifiques au protocole
    nmap_cmd="$nmap_cmd -p $T1595_027AA_PROTOCOL_PORTS"

    # Configuration service detection
    if [[ "$T1595_027AA_SERVICE_DETECTION" == "true" ]]; then
        nmap_cmd="$nmap_cmd -sV"
    fi

    # Configuration version detection
    if [[ "$T1595_027AA_VERSION_DETECTION" == "true" ]]; then
        nmap_cmd="$nmap_cmd --version-intensity 7"
    fi

    # Configuration script scanning pour le protocole
    if [[ "$T1595_027AA_SCRIPT_SCANNING" == "true" ]]; then
        if [[ -n "$T1595_027AA_SCRIPT_CATEGORIES" ]]; then
            nmap_cmd="$nmap_cmd --script=$T1595_027AA_SCRIPT_CATEGORIES"
        else
            nmap_cmd="$nmap_cmd --script=SSH*"
        fi
    fi

    # Configuration timing
    case "$T1595_027AA_TIMING_TEMPLATE" in
        "polite")
            nmap_cmd="$nmap_cmd -T2"
            ;;
        "normal")
            nmap_cmd="$nmap_cmd -T3"
            ;;
        "aggressive")
            nmap_cmd="$nmap_cmd -T4"
            ;;
    esac

    # Configuration rate limiting
    if [[ "$T1595_027AA_RATE_LIMIT" != "0" ]]; then
        nmap_cmd="$nmap_cmd --max-rate $T1595_027AA_RATE_LIMIT"
    fi

    # Configuration timeout
    nmap_cmd="$nmap_cmd --host-timeout $T1595_027AA_TIMEOUT"

    # Configuration parallélisme
    nmap_cmd="$nmap_cmd --min-parallelism $T1595_027AA_PARALLELISM --max-parallelism $T1595_027AA_PARALLELISM"

    # Configuration exclusions
    if [[ -n "$T1595_027AA_EXCLUDE_HOSTS" ]]; then
        nmap_cmd="$nmap_cmd --exclude $T1595_027AA_EXCLUDE_HOSTS"
    fi

    # Configuration résolution DNS
    if [[ "$T1595_027AA_RESOLVE_HOSTNAMES" == "false" ]]; then
        nmap_cmd="$nmap_cmd -n"
    fi

    # Flags personnalisés
    if [[ -n "$T1595_027AA_CUSTOM_FLAGS" ]]; then
        nmap_cmd="$nmap_cmd $T1595_027AA_CUSTOM_FLAGS"
    fi

    # Cibles
    nmap_cmd="$nmap_cmd $T1595_027AA_TARGETS"

    # Outputs multiples
    nmap_cmd="$nmap_cmd -oX $technical_details -oG $T1595_027AA_RESULTS_DIR/grepable_output.txt"

    # Exécution du scan
    [[ "$T1595_027AA_OUTPUT_MODE" == "debug" ]] && echo "[DEBUG] Executing: $nmap_cmd" >&2

    if ! eval "$nmap_cmd" > "$T1595_027AA_RESULTS_DIR/nmap_output.txt" 2>&1; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] SSH protocol scan failed" >&2
        return 3
    fi

    local scan_end=$(date +%s)
    local scan_duration=$((scan_end - scan_start))

    # Traitement des résultats
    if [[ -f "$technical_details" ]]; then
        # Extraction des statistiques spécifiques au protocole
        local hosts_scanned=$(grep -c "host.*state" "$technical_details" 2>/dev/null || echo "0")
        local protocol_services=$(grep -c "port.*state=\"open\"" "$technical_details" 2>/dev/null || echo "0")
        local version_detected=$(grep -c "service.*version" "$technical_details" 2>/dev/null || echo "0")

        # Création du rapport JSON
        cat > "$scan_results" << JSON_EOF
{
  "technique_id": "T1595_027AA",
  "technique_name": "active_scanning-ssh_protocol_scan",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "protocol": "SSH",
  "scan_duration_seconds": $scan_duration,
  "configuration": {
    "protocol_ports": "$T1595_027AA_PROTOCOL_PORTS",
    "version_detection": $T1595_027AA_VERSION_DETECTION,
    "script_scanning": $T1595_027AA_SCRIPT_SCANNING,
    "service_detection": $T1595_027AA_SERVICE_DETECTION,
    "timing_template": "$T1595_027AA_TIMING_TEMPLATE",
    "rate_limit": $T1595_027AA_RATE_LIMIT
  },
  "results": {
    "hosts_scanned": $hosts_scanned,
    "protocol_services_found": $protocol_services,
    "version_detection_successful": $version_detected,
    "scan_successful": true
  }
}
JSON_EOF
    else
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] No scan results generated" >&2
        return 3
    fi

    return 0
}
# FUNCTION 4/4 : POSTCONDITION VERIFY

function Postcondition-Verify {
    echo "[DEBUG] Verifying postconditions for T1595_027AA" >&2

    local results_dir="$T1595_027AA_RESULTS_DIR"
    local scan_results="$results_dir/scan_results.json"
    local technical_details="$results_dir/technical_details.xml"

    # Vérification fichiers de sortie
    if [[ ! -f "$scan_results" ]]; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] Scan results file missing" >&2
        return 4
    fi

    if [[ ! -f "$technical_details" ]]; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] Technical details file missing" >&2
        return 4
    fi

    # Validation contenu JSON
    if ! jq empty "$scan_results" 2>/dev/null; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[ERROR] Invalid JSON in scan results" >&2
        return 4
    fi

    # Validation contenu XML
    if ! xmllint --noout "$technical_details" 2>/dev/null; then
        [[ "$T1595_027AA_SILENT_MODE" != "true" ]] && echo "[WARNING] XML validation failed, but continuing" >&2
    fi

    # Création métadonnées d'exécution
    local metadata_file="$results_dir/metadata/execution_metadata.json"
    mkdir -p "$results_dir/metadata"

    cat > "$metadata_file" << META_EOF
{
  "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "technique_id": "T1595_027AA",
  "technique_name": "active_scanning-ssh_protocol_scan",
  "protocol": "SSH",
  "execution_mode": "$T1595_027AA_OUTPUT_MODE",
  "silent_mode": "$T1595_027AA_SILENT_MODE",
  "results_directory": "$results_dir",
  "files_generated": $(find "$results_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$results_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration_snapshot": {
    "targets": "$T1595_027AA_TARGETS",
    "protocol_ports": "$T1595_027AA_PROTOCOL_PORTS",
    "version_detection": $T1595_027AA_VERSION_DETECTION,
    "timing_template": "$T1595_027AA_TIMING_TEMPLATE",
    "rate_limit": $T1595_027AA_RATE_LIMIT
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
    case "$T1595_027AA_OUTPUT_MODE" in
        "debug")
            echo "[DEBUG] active_scanning-ssh_protocol_scan completed successfully" >&2
            echo "[DEBUG] Results saved to: $T1595_027AA_RESULTS_DIR" >&2
            find "$T1595_027AA_RESULTS_DIR" -name "*.json" -o -name "*.xml" | while read -r file; do
                echo "[DEBUG] Generated: $file" >&2
            done
            ;;
        "simple")
            echo "[SUCCESS] active_scanning-ssh_protocol_scan completed" >&2
            echo "[INFO] Results saved to: $T1595_027AA_RESULTS_DIR" >&2
            ;;
        "stealth")
            # Sortie minimale pour les opérations furtives
            ;;
        "silent")
            # Aucune sortie
            ;;
        *)
            echo "[INFO] active_scanning-ssh_protocol_scan completed" >&2
            ;;
    esac

    Postcondition-Verify || exit $?
}
# SCRIPT ENTRY POINT

main "$@"
