#!/bin/bash

# T1595.001a - Stealth SYN Scan
# MITRE ATT&CK Enterprise - Reconnaissance Tactic (TA0043)
# ATOMIC ACTION: Stealth network scanning using SYN scan ONLY
# Platform: Linux | Contract: One action, one dependency, one privilege tier
#  T1595.001a
# Technique identifier for variable substitution
technique_id="T1595_001A"
# FUNCTION 1/4 : CONFIGURATION AND PRECONDITION VALIDATION

function Get-Configuration {
    echo "[DEBUG] Loading configuration for T1595.001a" >&2

    # Core Configuration
        # Variable TARGETS critique - vérification ajoutée
    export T1595_001A_OUTPUT_BASE="${T1595_001A_OUTPUT_BASE:-/tmp/mitre_results}"
    export T1595_001A_OUTPUT_MODE="${T1595_001A_OUTPUT_MODE:-simple}"
    export T1595_001A_SILENT_MODE="${T1595_001A_SILENT_MODE:-false}"

    # Stealth & Evasion Configuration
    export T1595_001A_EVASION_LEVEL="${T1595_001A_EVASION_LEVEL:-advanced}"
    export T1595_001A_TIMING_TEMPLATE="${T1595_001A_TIMING_TEMPLATE:-sneaky}"
    export T1595_001A_DECOY_COUNT="${T1595_001A_DECOY_COUNT:-3}"
    export T1595_001A_SOURCE_PORT="${T1595_001A_SOURCE_PORT:-random}"
    export T1595_001A_FRAGMENT_SIZE="${T1595_001A_FRAGMENT_SIZE:-8}"

    # Network & Performance
    export T1595_001A_RATE_LIMIT="${T1595_001A_RATE_LIMIT:-10}"
    export T1595_001A_TIMEOUT="${T1595_001A_TIMEOUT:-5}"
    export T1595_001A_MAX_RETRIES="${T1595_001A_MAX_RETRIES:-2}"
    export T1595_001A_PARALLELISM="${T1595_001A_PARALLELISM:-1}"

    # Advanced Options
        # Variable CUSTOM_FLAGS critique - vérification ajoutée
    export T1595_001A_EXCLUDE_HOSTS="${T1595_001A_EXCLUDE_HOSTS:-}"
    export T1595_001A_RESOLVE_HOSTNAMES="${T1595_001A_RESOLVE_HOSTNAMES:-false}"

    # Validation des paramètres critiques
    if [[ -z "$t1595_001a_TARGETS" ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] t1595_001a_TARGETS is required" >&2
        return 1
    fi

    # Création répertoire de sortie
    local timestamp=$(date +%Y%m%d_%H%M%S)
    export t1595_001a_RESULTS_DIR="${t1595_001a_OUTPUT_BASE}/t1595_001a_${timestamp}"
    mkdir -p "${!technique_id}_RESULTS_DIR" 2>/dev/null || {
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Cannot create output directory" >&2
        return 1
    }

    return 0

    # ===== VÉRIFICATIONS VARIABLES CRITIQUES =====
    
    # Vérification TARGETS (si utilisée)
    if grep -q "TARGETS" "../reconnaissance/linux/t1595.001a-scanning_ip_blocks-stealth_syn_scan-linux/src/main.sh" && [[ -z "${T1595_001A_TARGETS:-}" ]]; then
        echo "Error: TARGET parameter is required. Please specify target hosts or networks." >&2
        echo "Usage: T1595_001A_TARGETS='192.168.1.0/24' $0" >&2
        return 1
    fi
    
    # Vérification WORDLIST (si utilisée)
    if grep -q "WORDLIST" "../reconnaissance/linux/t1595.001a-scanning_ip_blocks-stealth_syn_scan-linux/src/main.sh" && [[ -z "${T1595_001A_WORDLIST:-}" ]]; then
        echo "Error: WORDLIST parameter is required for scanning." >&2
        return 1
    fi
    
    # Export des variables critiques si elles existent
    [[ -n "${T1595_001A_TARGETS:-}" ]] && export T1595_001A_TARGETS="$T1595_001A_TARGETS"
    [[ -n "${T1595_001A_WORDLIST:-}" ]] && export T1595_001A_WORDLIST="$T1595_001A_WORDLIST"
    
    # ===== FIN VÉRIFICATIONS CRITIQUES =====


    # ===== VARIABLES ESSENTIELLES RECONNAISSANCE =====
    export T1595_001A_DEBUG_MODE="${T1595_001A_DEBUG_MODE:-false}"
    export T1595_001A_TIMEOUT="${T1595_001A_TIMEOUT:-300}"
    export T1595_001A_FALLBACK_MODE="${T1595_001A_FALLBACK_MODE:-simulation}"
    export T1595_001A_OUTPUT_FORMAT="${T1595_001A_OUTPUT_FORMAT:-json}"
    export T1595_001A_POLICY_CHECK="${T1595_001A_POLICY_CHECK:-true}"
    export T1595_001A_RATE_LIMIT="${T1595_001A_RATE_LIMIT:-10}"
    export T1595_001A_MAX_HOSTS="${T1595_001A_MAX_HOSTS:-254}"
    export T1595_001A_SCAN_DEPTH="${T1595_001A_SCAN_DEPTH:-basic}"
    export T1595_001A_TIMING_TEMPLATE="${T1595_001A_TIMING_TEMPLATE:-normal}"
    export T1595_001A_SERVICE_DETECTION="${T1595_001A_SERVICE_DETECTION:-true}"
    # ===== FIN VARIABLES RECONNAISSANCE =====

}
# FUNCTION 2/4 : PRECONDITION CHECK

function Precondition-Check {
    echo "[DEBUG] Checking preconditions for t1595_001a" >&2

    # Vérification OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] This technique requires Linux" >&2
        return 2
    fi

    # Vérification outils
    if ! command -v nmap &> /dev/null; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] nmap is required but not installed" >&2
        return 2
    fi

    # Vérification version nmap
    local nmap_version=$(nmap --version | head -1 | grep -oP '\d+\.\d+')
    if [[ "$(echo "$nmap_version < 7.0" | bc -l)" -eq 1 ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[WARNING] nmap version $nmap_version detected, 7.0+ recommended" >&2
    fi

    # Vérification réseau
    if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[WARNING] No internet connectivity detected" >&2
    fi

    # Vérification permissions
    if [[ "$t1595_001a_EVASION_LEVEL" == "maximum" ]] && [[ $EUID -ne 0 ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[WARNING] Maximum evasion may require root privileges" >&2
    fi

    # Validation des fichiers cibles
    if [[ -f "t1595_001a_TARGETS" ]]; then
        if [[ ! -r "t1595_001a_TARGETS" ]]; then
            [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Target file not readable" >&2
            return 2
        fi
    fi

    return 0
}
# FUNCTION 3/4 : ATOMIC ACTION

function Atomic-Action {
    echo "[DEBUG] Executing atomic action for t1595_001a" >&2

    local scan_results="${t1595_001a_RESULTS_DIR}/scan_results.json"
    local technical_details="${t1595_001a_RESULTS_DIR}/technical_details.xml"
    local scan_start=$(date +%s)

    # Construction des flags nmap selon le type de scan
    local nmap_cmd="nmap ${nmap_flags}"

    # Configuration stealth et evasion
    case "t1595_001a_EVASION_LEVEL" in
        "maximum")
            nmap_cmd="$nmap_cmd --spoof-mac 0 --badsum --data-length 16"
            ;;
        "advanced")
            nmap_cmd="$nmap_cmd --spoof-mac 0 --data-length 8"
            ;;
        "basic")
            nmap_cmd="$nmap_cmd --data-length 4"
            ;;
    esac

    # Configuration timing
    case "t1595_001a_TIMING_TEMPLATE" in
        "paranoid")
            nmap_cmd="$nmap_cmd -T0"
            ;;
        "sneaky")
            nmap_cmd="$nmap_cmd -T1"
            ;;
        "polite")
            nmap_cmd="$nmap_cmd -T2"
            ;;
    esac

    # Configuration rate limiting
    if [[ "$t1595_001a_RATE_LIMIT" != "0" ]]; then
        nmap_cmd="$nmap_cmd --max-rate ${!technique_id}_RATE_LIMIT"
    fi

    # Configuration fragmentation
    if [[ "$t1595_001a_FRAGMENT_SIZE" != "0" ]]; then
        nmap_cmd="$nmap_cmd -f --mtu ${!technique_id}_FRAGMENT_SIZE"
    fi

    # Configuration decoys
    if [[ "t1595_001a_DECOY_COUNT" -gt 0 ]]; then
        local decoys=""
        for i in $(seq 1 "${!technique_id}_DECOY_COUNT"); do
            decoys="$decoys,$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255))"
        done
        nmap_cmd="$nmap_cmd -D $decoys"
    fi

    # Configuration source port
    if [[ "$t1595_001a_SOURCE_PORT" != "random" ]]; then
        nmap_cmd="$nmap_cmd --source-port ${!technique_id}_SOURCE_PORT"
    fi

    # Configuration exclusions
    if [[ -n "t1595_001a_EXCLUDE_HOSTS" ]]; then
        nmap_cmd="$nmap_cmd --exclude ${t1595_001a_EXCLUDE_HOSTS}"
    fi

    # Configuration résolution DNS
    if [[ "$t1595_001a_RESOLVE_HOSTNAMES" == "false" ]]; then
        nmap_cmd="$nmap_cmd -n"
    fi

    # Configuration parallélisme
    nmap_cmd="$nmap_cmd --min-parallelism ${!technique_id}_PARALLELISM --max-parallelism ${!technique_id}_PARALLELISM"

    # Flags personnalisés
    if [[ -n "t1595_001a_CUSTOM_FLAGS" ]]; then
        nmap_cmd="$nmap_cmd ${t1595_001a_CUSTOM_FLAGS}"
    fi

    # Cibles
    nmap_cmd="$nmap_cmd ${t1595_001a_TARGETS}"

    # Outputs multiples
    nmap_cmd="$nmap_cmd -oX $technical_details -oG ${t1595_001a_RESULTS_DIR}/grepable_output.txt"

    # Exécution du scan
    [[ "$t1595_001a_OUTPUT_MODE" == "debug" ]] && echo "[DEBUG] Executing: $nmap_cmd" >&2

    if ! eval "$nmap_cmd" > "${t1595_001a_RESULTS_DIR}/nmap_output.txt" 2>&1; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Nmap scan failed" >&2
        return 3
    fi

    local scan_end=$(date +%s)
    local scan_duration=$((scan_end - scan_start))

    # Traitement des résultats
    if [[ -f "$technical_details" ]]; then
        # Extraction des statistiques de base
        local hosts_up=$(grep -c 'host.*state="up"' "$technical_details" 2>/dev/null || echo "0")
        local ports_open=$(grep -c 'port.*state="open"' "$technical_details" 2>/dev/null || echo "0")

        # Création du rapport JSON
        cat > "$scan_results" << JSON_EOF
{
  "technique_id": "t1595_001a",
  "technique_name": "${technique_name}",
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_type": "${scan_type}",
  "scan_duration_seconds": $scan_duration,
  "configuration": {
    "targets": "${!technique_id}_TARGETS",
    "evasion_level": "${!technique_id}_EVASION_LEVEL",
    "timing_template": "${!technique_id}_TIMING_TEMPLATE",
    "rate_limit": ${!technique_id}_RATE_LIMIT,
    "nmap_command": "$nmap_cmd"
  },
  "results": {
    "hosts_discovered": $hosts_up,
    "ports_found": $ports_open,
    "scan_successful": true
  }
}
JSON_EOF
    else
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] No scan results generated" >&2
        return 3
    fi

    return 0
}
# FUNCTION 4/4 : POSTCONDITION VERIFY

function Postcondition-Verify {
    echo "[DEBUG] Verifying postconditions for t1595_001a" >&2

    local results_dir="${!technique_id}_RESULTS_DIR"
    local scan_results="$results_dir/scan_results.json"
    local technical_details="$results_dir/technical_details.xml"

    # Vérification fichiers de sortie
    if [[ ! -f "$scan_results" ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Scan results file missing" >&2
        return 4
    fi

    if [[ ! -f "$technical_details" ]]; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Technical details file missing" >&2
        return 4
    fi

    # Validation contenu JSON
    if ! jq empty "$scan_results" 2>/dev/null; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[ERROR] Invalid JSON in scan results" >&2
        return 4
    fi

    # Validation contenu XML
    if ! xmllint --noout "$technical_details" 2>/dev/null; then
        [[ "$t1595_001a_SILENT_MODE" != "true" ]] && echo "[WARNING] XML validation failed, but continuing" >&2
    fi

    # Création métadonnées d'exécution
    local metadata_file="$results_dir/metadata/execution_metadata.json"
    mkdir -p "$results_dir/metadata"

    cat > "$metadata_file" << META_EOF
{
  "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "technique_id": "t1595_001a",
  "technique_name": "${technique_name}",
  "execution_mode": "${!technique_id}_OUTPUT_MODE",
  "silent_mode": "${!technique_id}_SILENT_MODE",
  "results_directory": "$results_dir",
  "files_generated": $(find "$results_dir" -type f 2>/dev/null | wc -l),
  "total_size_bytes": $(du -sb "$results_dir" 2>/dev/null | cut -f1 || echo 0),
  "configuration_snapshot": {
    "targets": "${!technique_id}_TARGETS",
    "evasion_level": "${!technique_id}_EVASION_LEVEL",
    "timing_template": "${!technique_id}_TIMING_TEMPLATE",
    "rate_limit": ${!technique_id}_RATE_LIMIT
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
    case "${!technique_id}_OUTPUT_MODE" in
        "debug")
            echo "[DEBUG] ${technique_name} completed successfully" >&2
            echo "[DEBUG] Results saved to: ${t1595_001a_RESULTS_DIR}" >&2
            find "${!technique_id}_RESULTS_DIR" -name "*.json" -o -name "*.xml" | while read -r file; do
                echo "[DEBUG] Generated: $file" >&2
            done
            ;;
        "simple")
            echo "[SUCCESS] ${technique_name} completed" >&2
            echo "[INFO] Results saved to: ${t1595_001a_RESULTS_DIR}" >&2
            ;;
        "stealth")
            # Sortie minimale pour les opérations furtives
            ;;
        "silent")
            # Aucune sortie
            ;;
        *)
            echo "[INFO] ${technique_name} completed" >&2
            ;;
    esac

    Postcondition-Verify || exit $?
}
# SCRIPT ENTRY POINT

main "$@"
