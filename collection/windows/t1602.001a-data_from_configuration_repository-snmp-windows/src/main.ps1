
# MITRE ATT&CK T1602.001A - Data from Configuration Repository: SNMP (Windows)
# Configuration data collection via SNMP protocol
# Date: August 17, 2025


# Environment variables configuration
$OUTPUT_BASE = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\Temp\mitre_results" }
$TIMEOUT = if ($env:TIMEOUT) { $env:TIMEOUT } else { "300" }
$MAX_FILES = if ($env:MAX_FILES) { $env:MAX_FILES } else { "1000" }
$MAX_SIZE = if ($env:MAX_SIZE) { $env:MAX_SIZE } else { "100MB" }
$SIMULATION_MODE = if ($env:SIMULATION_MODE) { $env:SIMULATION_MODE } else { "true" }

# Variables specific to T1602
$T1602_DEBUG_MODE = if ($env:T1602_DEBUG_MODE) { $env:T1602_DEBUG_MODE } else { "false" }
$T1602_STEALTH_MODE = if ($env:T1602_STEALTH_MODE) { $env:T1602_STEALTH_MODE } else { "false" }
$T1602_OUTPUT_FORMAT = if ($env:T1602_OUTPUT_FORMAT) { $env:T1602_OUTPUT_FORMAT } else { "simple" }


# UNIVERSAL INFRASTRUCTURE FUNCTIONS


function Get-EnvironmentVariables {
    return @{
        "OUTPUT_BASE" = $OUTPUT_BASE
        "TIMEOUT" = $TIMEOUT
        "MAX_FILES" = $MAX_FILES
        "MAX_SIZE" = $MAX_SIZE
        "SIMULATION_MODE" = $SIMULATION_MODE
        T1602_DEBUG_MODE = $T1602_DEBUG_MODE
        T1602_STEALTH_MODE = $T1602_STEALTH_MODE
        T1602_OUTPUT_FORMAT = $T1602_OUTPUT_FORMAT
    }
}

function Initialize-OutputStructure {
    param([string]$BasePath)
    
    $outputDir = Join-Path $BasePath "t1602\001a-snmp-data"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    return $outputDir
}

function Write-JsonOutput {
    param(
        [string]$FilePath,
        [hashtable]$Data
    )
    
    $Data | ConvertTo-Json -Depth 5 | Set-Content $FilePath -Encoding UTF8
}

function Get-ExecutionMetadata {
    return @{
        "Timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "Technique" =  "T1602.001A"
        "Platform" =  "Windows"
        "User" = $env:USERNAME
        "Computer" = $env:COMPUTERNAME
        "ProcessId" = $PID
        "PowerShellVersion" = $PSVersionTable.PSVersion.ToString()
    }
}

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [array]$Arguments = @(),
        [int]$TimeoutSeconds = 30
    )
    
    try {
        if ($Arguments.Count -gt 0) {
            $result = & $Command @Arguments 2>&1
        } else {
            $result = & $Command 2>&1
        }
        return @{ Success = $true; Output = $result; Error = $null }
    } catch {
        return @{ Success = $false; Output = $null; Error = $_.Exception.Message }
    }
}


# FONCTIONS TRIPLE OUTPUT ARCHITECTURE


function Write-SimpleOutput {
    param([string]$Message)
    if ($T1602_STEALTH_MODE -ne "true") {
        Write-Host $Message
    }
}

function Write-DebugOutput {
    param([hashtable]$Data)
    if ($T1602_DEBUG_MODE -eq "true") {
        $Data | ConvertTo-Json -Depth 3 | Write-Host
    }
}

function Write-StealthOutput {
    param([string]$Message)
    if ($T1602_STEALTH_MODE -eq "true") {
        # Mode silencieux - pas de sortie console
        Add-Content -Path "$OUTPUT_BASE\t1602_stealth.log" -Value "$(Get-Date): $Message" -ErrorAction SilentlyContinue
    }
}

function Select-OutputMode {
    if ($T1602_DEBUG_MODE -eq "true") {
        return "debug"
    } elseif ($T1602_STEALTH_MODE -eq "true") {
        return "stealth"
    } else {
        return "simple"
    }
}


# MAIN FUNCTION - SNMP COLLECTION


function Get-SNMPConfigurationData {
    Write-SimpleOutput "[SNMP] Starting configuration data collection..."
    
    $outputDir = Initialize-OutputStructure $OUTPUT_BASE
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $snmpData = @{
        "Metadata" = Get-ExecutionMetadata
        "Targets" = @()
        "Results" = @()
        "Summary" = @{
            "TotalTargets" = 0
            "SuccessfulQueries" = 0
            "FailedQueries" = 0
        }
    }
    
    # Common SNMP targets
    $snmpTargets = @(
        @{ Host = "127.0.0.1"; Community = "public"; Description = "Localhost" }
        @{ Host = "192.168.1.1"; Community = "public"; Description = "Potential Gateway" }
        @{ Host = "192.168.1.254"; Community = "public"; Description = "Potential Router" }
    )
    
    $snmpData.Summary.TotalTargets = $snmpTargets.Count
    
    foreach ($target in $snmpTargets) {
        Write-SimpleOutput "[SNMP] Testing target: $($target.Host)"
        
        $targetResult = @{
            "Host" = $target.Host
            "Community" = $target.Community
            "Description" = $target.Description
            "Status" =  "Unknown"
            "Data" = @{}
            "Error" = $null
            "Timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        if ($SIMULATION_MODE -eq "true") {
            # Simulation mode - fake data
            Write-SimpleOutput "[SNMP] Simulation mode - generating fake data"
            
            $targetResult.Status = "Success"
            $targetResult.Data = @{
                "SystemName" =  "ROUTER-$($target.Host.Replace('.', '-'))"
                "SystemDescr" =  "Cisco IOS Software, Version 15.1"
                "SystemUpTime" =  "42 days, 15:30:22"
                "SystemContact" =  "admin@company.com"
                "SystemLocation" =  "Server Room Floor 2"
                "Interfaces" = @(
                    @{ Name = "GigabitEthernet0/1"; Status = "up"; Speed = "1000000000" }
                    @{ Name = "GigabitEthernet0/2"; Status = "down"; Speed = "1000000000" }
                )
            }
            $snmpData.Summary.SuccessfulQueries++
            
        } else {
            # Real mode - authentic SNMP attempt
            try {
                # Use snmpwalk if available
                $snmpWalk = Invoke-SafeCommand "snmpwalk" @("-v2c", "-c", $target.Community, $target.Host, "1.3.6.1.2.1.1")
                
                if ($snmpWalk.Success) {
                    $targetResult.Status = "Success"
                    $targetResult.Data.RawOutput = $snmpWalk.Output
                    $snmpData.Summary.SuccessfulQueries++
                } else {
                    $targetResult.Status = "Failed"
                    $targetResult.Error = "SNMP query failed"
                    $snmpData.Summary.FailedQueries++
                }
                
            } catch {
                $targetResult.Status = "Failed"
                $targetResult.Error = $_.Exception.Message
                $snmpData.Summary.FailedQueries++
            }
        }
        
        $snmpData.Results += $targetResult
        $snmpData.Targets += $target
        
        # Output based on mode
        switch (Select-OutputMode) {
            "simple" {
                if ($targetResult.Status -eq "Success") {
                    Write-SimpleOutput "  [OK] $($target.Host) - Data collected"
                    if ($targetResult.Data.SystemName) {
                        Write-SimpleOutput "       System: $($targetResult.Data.SystemName)"
                    }
                } else {
                    Write-SimpleOutput "  [FAIL] $($target.Host) - $($targetResult.Error)"
                }
            }
            "debug" {
                Write-DebugOutput $targetResult
            }
            "stealth" {
                Write-StealthOutput "SNMP query $($target.Host): $($targetResult.Status)"
            }
        }
    }
    
    # Save results
    $outputFile = Join-Path $outputDir "snmp_data_$timestamp.json"
    Write-JsonOutput $outputFile $snmpData
    
    # Final report
    Write-SimpleOutput ""
    Write-SimpleOutput "[SNMP] Collection completed:"
    Write-SimpleOutput "       Targets tested: $($snmpData.Summary.TotalTargets)"
    Write-SimpleOutput "       Success: $($snmpData.Summary.SuccessfulQueries)"
    Write-SimpleOutput "       Failures: $($snmpData.Summary.FailedQueries)"
    Write-SimpleOutput "       Results: $outputFile"
    
    if ($T1602_DEBUG_MODE -eq "true") {
        Write-DebugOutput $snmpData.Summary
    }
    
    return $snmpData
}


# MAIN ENTRY POINT


try {
    Write-SimpleOutput "T1602.001A - Data from Configuration Repository: SNMP"
    Write-SimpleOutput ""
    
    # Environment validation
    $envVars = Get-EnvironmentVariables
    if ($T1602_DEBUG_MODE -eq "true") {
        Write-DebugOutput $envVars
    }
    
    # Main execution
    $result = Get-SNMPConfigurationData
    
    Write-SimpleOutput ""
    Write-SimpleOutput "Technique T1602.001A executed successfully"
    
    exit 0
    
} catch {
    Write-SimpleOutput "ERROR T1602.001A: $($_.Exception.Message)"
    
    if ($T1602_DEBUG_MODE -eq "true") {
        Write-DebugOutput @{
            "Error" = $_.Exception.Message
            "StackTrace" = $_.ScriptStackTrace
            "Timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    
    exit 1
}

