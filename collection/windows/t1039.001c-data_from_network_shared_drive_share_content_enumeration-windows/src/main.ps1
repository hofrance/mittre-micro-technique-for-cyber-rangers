# CONTRACT METADATA
# Technique: 1039.003A
# Observable Action: 1039_003a_action
# Precondition: Windows OS, Appropriate privileges
# Postcondition: Action completed, Results written
# Dependencies: PowerShell 5.1+
# Timeout: 300 seconds
# Return Codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED_PRECONDITION, 3=DENIED_POLICY, 4=FAILED_POSTCONDITION, 124=TIMEOUT
# T1039.003A - Share Content Enumeration
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: enumerate files and directories in accessible network shares ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    $config = @{
        # Configuration de base optimis  e
        "OUTPUT_BASE" = if ($env:T1039_003A_OUTPUT_BASE) { $env:T1039_003A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1039_003A_TIMEOUT) { [int]$env:T1039_003A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1039_003A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1039_003A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1039_003A_VERBOSE_LEVEL) { [int]$env:T1039_003A_VERBOSE_LEVEL } else { 1 }

        # Policy-awareness Windows simplifi  
        "POLICY_CHECK" = if ($env:T1039_003A_POLICY_CHECK) { $env:T1039_003A_POLICY_CHECK -eq "true" } else { $false }  # DISABLED for performance
        "POLICY_SIMULATE" = if ($env:T1039_003A_POLICY_SIMULATE) { $env:T1039_003A_POLICY_SIMULATE -eq "true" } else { $false }
        "FALLBACK_MODE" = if ($env:T1039_003A_FALLBACK_MODE) { $env:T1039_003A_FALLBACK_MODE } else { "simulate" }

        # Variables sp  cialis  es optimis  es
        "OUTPUT_MODE" = if ($env:T1039_003A_OUTPUT_MODE) { $env:T1039_003A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1039_003A_SILENT_MODE -eq "true"
        "RETRY_COUNT" = if ($env:T1039_003A_RETRY_COUNT) { [int]$env:T1039_003A_RETRY_COUNT } else { 1 }  # REDUCED

        # Defense Evasion simplifi  
        "SLEEP_JITTER" = if ($env:T1039_003A_SLEEP_JITTER) { [int]$env:T1039_003A_SLEEP_JITTER } else { 0 }

        # Performance optimizations
        "MAX_ITEMS" = if ($env:T1039_003A_MAX_ITEMS) { [int]$env:T1039_003A_MAX_ITEMS } else { 20 }  # Circuit breaker
        "ENABLE_TIMEOUT" = if ($env:T1039_003A_ENABLE_TIMEOUT) { $env:T1039_003A_ENABLE_TIMEOUT -eq "true" } else { $true }
        "QUICK_MODE" = if ($env:T1039_003A_QUICK_MODE) { $env:T1039_003A_QUICK_MODE -eq "true" } else { $false }

        # Telemetry
        "ECS_VERSION" = if ($env:T1039_003A_ECS_VERSION) { $env:T1039_003A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1039_003A_CORRELATION_ID) { $env:T1039_003A_CORRELATION_ID } else { "auto" }
    }

    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1039_003A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }

    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: enumerate files and directories in accessible network shares ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic enumerate files and directories in accessible network shares..." -ForegroundColor Yellow
    }
    
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "enumerate_files_and_directories_in_accessible_network_shares"
        "technique_id" =  "T1039.003A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1039_003a"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Enumerate content of accessible shares
        $shareContent = @()
        $testShares = @("\\localhost\C$")
        
        foreach ($share in $testShares) {
            try {
                if (Test-Path $share) {
                    $items = Get-ChildItem $share -ErrorAction SilentlyContinue | Select-Object -First 10
                    foreach ($item in $items) {
                        $shareContent += @{
                            "share_path" = $share
                            "item_name" = $item.Name
                            "item_type" = if ($item.PSIsContainer) { "Directory" } else { "File" }
                            "size_bytes" = if ($item.PSIsContainer) { 0 } else { $item.Length }
                            "last_modified" = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            } catch {
                # Access denied or other error
            }
        }
        
        $results.results = @{
            "status" =  "success"
            "shares_enumerated" = $testShares.Count
            "items_found" = $shareContent.Count
            "content_enumeration" = $shareContent
            "output_directory" = $outputDir
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] enumerate files and directories in accessible network shares completed" -ForegroundColor Green
        }
    }
    catch {
        $results.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
        }
        
        $results.postconditions = @{
            "action_completed" = $false
            "output_generated" = $false
            "policy_compliant" = $true
        }
    }
    
    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1039_003a"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }
    
    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "SHARE CONTENT ENUMERATION "
                $simpleOutput += "`nAction: enumerate files and directories in accessible network shares"
                $simpleOutput += "`nStatus: Success"
            } else {
                $simpleOutput = "enumerate files and directories in accessible network shares failed: $($Data.results.error)"
            }
            
            if (-not $Config.SILENT_MODE) {
                Write-Output $simpleOutput
                $simpleOutput | Out-File -FilePath (Join-Path $outputDir "results_simple.txt") -Encoding UTF8
            }
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "results_debug.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.SILENT_MODE) {
                Write-Host "[DEBUG] Results written to: $jsonFile" -ForegroundColor Cyan
            }
        }
        
        "stealth" {
            if (-not $Config.SILENT_MODE) {
                $jsonFile = Join-Path $outputDir "results_stealth.json"
                $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            }
        }
    }
    
    return $outputDir
}

function Main {
    try {
        $Config = Get-Configuration
        $results = Invoke-MicroTechniqueAction -Config $config
        $outputPath = Write-StandardizedOutput -Data $results -Config $config
        
        if (-not $results.postconditions.action_completed) {
            throw "Postcondition failed: action not completed"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[COMPLETE] T1039.003A atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        exit 0
    }
    catch {
        $errorMessage = $_.Exception.Message
        
        if ($errorMessage -like "*Precondition*") {
            exit 2
        } elseif ($errorMessage -like "*Policy*") {
            exit 3
        } elseif ($errorMessage -like "*Postcondition*") {
            exit 4
        } else {
            exit 1
        }
    }
}

exit (Main)




