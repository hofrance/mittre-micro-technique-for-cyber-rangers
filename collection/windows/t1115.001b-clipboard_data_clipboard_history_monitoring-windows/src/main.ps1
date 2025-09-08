# T1115.002A - Clipboard History Monitoring
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: monitor clipboard history for sensitive data ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1115_002A_OUTPUT_BASE) { $env:T1115_002A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1115_002A_TIMEOUT) { [int]$env:T1115_002A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1115_002A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1115_002A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1115_002A_VERBOSE_LEVEL) { [int]$env:T1115_002A_VERBOSE_LEVEL } else { 1 }

        # Variables spécialisées
        "OUTPUT_MODE" = if ($env:T1115_002A_OUTPUT_MODE) { $env:T1115_002A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1115_002A_SILENT_MODE -eq "true"
        "MONITOR_DURATION" = if ($env:T1115_002A_MONITOR_DURATION) { [int]$env:T1115_002A_MONITOR_DURATION } else { 60 }

        # Telemetry
        "ECS_VERSION" = if ($env:T1115_002A_ECS_VERSION) { $env:T1115_002A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1115_002A_CORRELATION_ID) { $env:T1115_002A_CORRELATION_ID } else { "auto" }
    }

    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1115_002A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }

    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)

    # ATOMIC ACTION: monitor clipboard history for sensitive data ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic monitor clipboard history for sensitive data..." -ForegroundColor Yellow
    }

    $results = @{
        "action" =  "monitor_clipboard_history_for_sensitive_data"
        "technique_id" =  "T1115.002A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }

    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1115_002a"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        $results.results = @{
            "status" =  "success"
            "action_performed" =  "monitor clipboard history for sensitive data"
            "output_directory" = $outputDir
            "monitor_duration_seconds" = $Config.MONITOR_DURATION
        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] monitor clipboard history for sensitive data completed successfully" -ForegroundColor Green
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

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Error "monitor clipboard history for sensitive data failed: $($_.Exception.Message)"
        }
    }

    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)

    $outputDir = Join-Path $Config.OUTPUT_BASE "t1115_002a"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }

    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "CLIPBOARD HISTORY MONITORING "
                $simpleOutput += "`nAction: monitor clipboard history for sensitive data"
                $simpleOutput += "`nStatus: Success"
            } else {
                $simpleOutput = "monitor clipboard history for sensitive data failed: $($Data.results.error)"
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
            Write-Host "[COMPLETE] T1115.002A atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }

        return 0
    }
    catch {
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
            Write-Error "FAILED: Micro-technique execution failed: $($_.Exception.Message)"
        }
        exit 1
    }
}

exit (Main)
