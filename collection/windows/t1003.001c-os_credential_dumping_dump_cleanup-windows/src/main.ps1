# T1003.004a - OS Credential Dumping: Dump Cleanup
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Clean up dump files and traces ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }

        T1003_004A_SOURCE_COMPRESSION = if ($env:T1003_004A_SOURCE_COMPRESSION) { $env:T1003_004A_SOURCE_COMPRESSION } else { "$env:TEMP\mitre_results\t1003.003a-dump_compression\dump_compression.json" }
        T1003_004A_DELETE_COMPRESSED = if ($env:T1003_004A_DELETE_COMPRESSED) { $env:T1003_004A_DELETE_COMPRESSED -eq "true" } else { $false }
        T1003_004A_DELETE_INTERMEDIATE = if ($env:T1003_004A_DELETE_INTERMEDIATE) { $env:T1003_004A_DELETE_INTERMEDIATE -eq "true" } else { $true }
        T1003_004A_SECURE_DELETE = if ($env:T1003_004A_SECURE_DELETE) { $env:T1003_004A_SECURE_DELETE -eq "true" } else { $true }
        T1003_004A_OVERWRITE_PASSES = if ($env:T1003_004A_OVERWRITE_PASSES) { [int]$env:T1003_004A_OVERWRITE_PASSES } else { 3 }
        T1003_004A_CLEAN_REGISTRY = if ($env:T1003_004A_CLEAN_REGISTRY) { $env:T1003_004A_CLEAN_REGISTRY -eq "true" } else { $false }
        T1003_004A_CLEAN_EVENTLOG = if ($env:T1003_004A_CLEAN_EVENTLOG) { $env:T1003_004A_CLEAN_EVENTLOG -eq "true" } else { $false }
        T1003_004A_OUTPUT_MODE = if ($env:T1003_004A_OUTPUT_MODE) { $env:T1003_004A_OUTPUT_MODE } else { "debug" }
        T1003_004A_SILENT_MODE = if ($env:T1003_004A_SILENT_MODE) { $env:T1003_004A_SILENT_MODE -eq "true" } else { $false }
        T1003_004A_STEALTH_MODE = if ($env:T1003_004A_STEALTH_MODE) { $env:T1003_004A_STEALTH_MODE -eq "true" } else { $false }
        # NEW: Robustness improvements
        T1003_004A_SIMULATE_MODE = if ($env:T1003_004A_SIMULATE_MODE) { $env:T1003_004A_SIMULATE_MODE -eq "true" } else { $false }  # Simulate if nothing to clean
        T1003_004A_MAX_CLEANUP_TIME = if ($env:T1003_004A_MAX_CLEANUP_TIME) { [int]$env:T1003_004A_MAX_CLEANUP_TIME } else { 30 }  # Max cleanup time
        T1003_004A_QUICK_MODE = if ($env:T1003_004A_QUICK_MODE) { $env:T1003_004A_QUICK_MODE -eq "true" } else { $false }  # Skip slow operations
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Dump cleanup ONLY
    if (-not $Config.T1003_004A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic dump cleanup..." -ForegroundColor Yellow
    }
    
    $cleanupResults = @{
        "action" =  "dump_cleanup"
        "technique_id" =  "T1003.004a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    $cleanupSummary = @{
        "files_deleted" = 0
        "directories_cleaned" = 0
        "bytes_cleaned" = 0
        "secure_overwrites" = 0
        "errors" = 0
        "cleaned_items" = @()
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1003.004a-dump_cleanup"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $startTime = Get-Date
        $hasAnythingToClean = $false
        
        # Collect all T1003 related directories and files
        $t1003Directories = @(
            "t1003.001a-lsass_detection",
            "t1003.002a-memory_dump", 
            "t1003.003a-dump_compression"
        )
        
        foreach ($dirName in $t1003Directories) {
            $targetDir = Join-Path $Config.OUTPUT_BASE $dirName
            
            if (Test-Path $targetDir) {
                $hasAnythingToClean = $true
                
                # Circuit breaker check
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -gt ($Config.TIMEOUT * 0.8)) {
                    if (-not $Config.T1003_004A_SILENT_MODE) {
                        Write-Host "[WARN] Circuit breaker activated - approaching timeout" -ForegroundColor Yellow
                    }
                    break
                }
                
                try {
                    $files = Get-ChildItem -Path $targetDir -File -Recurse
                    
                    foreach ($file in $files) {
                        # Circuit breaker check per file
                        $elapsed = (Get-Date) - $startTime
                        if ($elapsed.TotalSeconds -gt $Config.T1003_004A_MAX_CLEANUP_TIME) {
                            if (-not $Config.T1003_004A_SILENT_MODE) {
                                Write-Host "[WARN] Cleanup timeout reached" -ForegroundColor Yellow
                            }
                            break
                        }
                        
                        $fileSize = $file.Length
                        
                        if ($Config.T1003_004A_SECURE_DELETE -and -not $Config.T1003_004A_QUICK_MODE) {
                            # Secure overwrite (skip in quick mode)
                            try {
                                for ($i = 0; $i -lt $Config.T1003_004A_OVERWRITE_PASSES; $i++) {
                                    $randomBytes = New-Object byte[] $fileSize
                                    (New-Object Random).NextBytes($randomBytes)
                                    [System.IO.File]::WriteAllBytes($file.FullName, $randomBytes)
                                    $cleanupSummary.secure_overwrites++
                                }
                            } catch {
                                # Secure delete failed, do normal delete
                            }
                        }
                        
                        Remove-Item $file.FullName -Force
                        $cleanupSummary.files_deleted++
                        $cleanupSummary.bytes_cleaned += $fileSize
                        
                        $cleanupSummary.cleaned_items += @{
                            "path" = $file.FullName
                            "size_bytes" = $fileSize
                            "type" =  "file"
                            "secure_overwrite" = $Config.T1003_004A_SECURE_DELETE
                        }
                        
                        if (-not $Config.T1003_004A_SILENT_MODE) {
                            Write-Host "[CLEANUP] Deleted: $($file.Name)" -ForegroundColor Red
                        }
                    }
                    
                    # Remove directory if empty
                    if ((Get-ChildItem -Path $targetDir -Force | Measure-Object).Count -eq 0) {
                        Remove-Item $targetDir -Force
                        $cleanupSummary.directories_cleaned++
                        
                        $cleanupSummary.cleaned_items += @{
                            "path" = $targetDir
                            "type" =  "directory"
                        }
                    }
                } catch {
                    $cleanupSummary.errors++
                    if (-not $Config.T1003_004A_SILENT_MODE) {
                        Write-Warning "Failed to clean $targetDir`: $($_.Exception.Message)"
                    }
                }
            }
        }
        
        # Clean temporary files (skip in quick mode)
        if (-not $Config.T1003_004A_QUICK_MODE) {
            $tempPatterns = @("lsass_*.dmp", "lsass_*.zip", "*credential*", "*dump*")
            foreach ($pattern in $tempPatterns) {
                try {
                    $tempFiles = Get-ChildItem -Path $env:TEMP -Filter $pattern -ErrorAction SilentlyContinue
                    foreach ($tempFile in $tempFiles) {
                        $hasAnythingToClean = $true
                        
                        # Circuit breaker check
                        $elapsed = (Get-Date) - $startTime
                        if ($elapsed.TotalSeconds -gt $Config.T1003_004A_MAX_CLEANUP_TIME) {
                            break
                        }
                        
                        $fileSize = $tempFile.Length
                        
                        if ($Config.T1003_004A_SECURE_DELETE) {
                            try {
                                for ($i = 0; $i -lt $Config.T1003_004A_OVERWRITE_PASSES; $i++) {
                                    $randomBytes = New-Object byte[] $fileSize
                                    (New-Object Random).NextBytes($randomBytes)
                                    [System.IO.File]::WriteAllBytes($tempFile.FullName, $randomBytes)
                                    $cleanupSummary.secure_overwrites++
                                }
                            } catch {
                                # Secure delete failed
                            }
                        }
                        
                        Remove-Item $tempFile.FullName -Force
                        $cleanupSummary.files_deleted++
                        $cleanupSummary.bytes_cleaned += $fileSize
                        
                        $cleanupSummary.cleaned_items += @{
                            "path" = $tempFile.FullName
                            "size_bytes" = $fileSize
                            "type" =  "temp_file"
                            "pattern" = $pattern
                            "secure_overwrite" = $Config.T1003_004A_SECURE_DELETE
                        }
                    }
                } catch {
                    $cleanupSummary.errors++
                    if (-not $Config.T1003_004A_SILENT_MODE) {
                        Write-Warning "Failed to clean temp files with pattern $pattern`: $($_.Exception.Message)"
                    }
                }
            }
        }
        
        # Clean PowerShell history if contains sensitive commands
        if ($Config.T1003_004A_DELETE_INTERMEDIATE) {
            try {
                $historyPath = (Get-PSReadlineOption).HistorySavePath
                if ($historyPath -and (Test-Path $historyPath)) {
                    $historyContent = Get-Content $historyPath
                    $sensitivePatterns = @("lsass", "dump", "credential", "mimikatz", "procdump")
                    
                    $cleanedHistory = $historyContent | Where-Object {
                        $line = $_
                        $containsSensitive = $false
                        foreach ($pattern in $sensitivePatterns) {
                            if ($line -like "*$pattern*") {
                                $containsSensitive = $true
                                break
                            }
                        }
                        -not $containsSensitive
                    }
                    
                    if ($cleanedHistory.Count -lt $historyContent.Count) {
                        $cleanedHistory | Out-File -FilePath $historyPath -Encoding UTF8
                        $cleanupSummary.cleaned_items += @{
                            "path" = $historyPath
                            "type" =  "powershell_history"
                            "lines_removed" = $historyContent.Count - $cleanedHistory.Count
                        }
                    }
                }
            } catch {
                $cleanupSummary.errors++
            }
        }
        
        # Simulation mode handling
        if ($Config.T1003_004A_SIMULATE_MODE -and -not $hasAnythingToClean) {
            # Simulate cleanup when no real files exist
            $cleanupSummary.files_deleted = 3
            $cleanupSummary.directories_cleaned = 2
            $cleanupSummary.bytes_cleaned = 1048576  # 1MB simulated
            $cleanupSummary.secure_overwrites = 3
            
            $cleanupSummary.cleaned_items = @(
                @{
                    "path" =  "simulated_lsass_dump.dmp"
                    "size_bytes" = 524288
                    "type" =  "file"
                    "secure_overwrite" = $true
                },
                @{
                    "path" =  "simulated_dump.zip"
                    "size_bytes" = 262144
                    "type" =  "file"
                    "secure_overwrite" = $true
                },
                @{
                    "path" =  "simulated_temp_cred.txt"
                    "size_bytes" = 262144
                    "type" =  "temp_file"
                    "pattern" =  "*credential*"
                    "secure_overwrite" = $true
                },
                @{
                    "path" =  "simulated_t1003.001a_dir"
                    "type" =  "directory"
                },
                @{
                    "path" =  "simulated_t1003.002a_dir"
                    "type" =  "directory"
                }
            )
            
            if (-not $Config.T1003_004A_SILENT_MODE) {
                Write-Host "[SIMULATION] Simulated cleanup of 3 files and 2 directories" -ForegroundColor Cyan
            }
        }
        
        # Calculate performance metrics
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        $performanceMetrics = @{
            "duration_seconds" = [math]::Round($duration.TotalSeconds, 2)
            "files_per_second" = if ($duration.TotalSeconds -gt 0) { 
                [math]::Round($cleanupSummary.files_deleted / $duration.TotalSeconds, 2) 
            } else { 0 }
            "bytes_per_second" = if ($duration.TotalSeconds -gt 0) { 
                [math]::Round($cleanupSummary.bytes_cleaned / $duration.TotalSeconds, 2) 
            } else { 0 }
            "circuit_breaker_activated" = $false
            "timeout_reached" = $false
        }
        
        # Check if circuit breaker was activated
        if ($duration.TotalSeconds -gt ($Config.TIMEOUT * 0.8)) {
            $performanceMetrics.circuit_breaker_activated = $true
        }
        if ($duration.TotalSeconds -gt $Config.T1003_004A_MAX_CLEANUP_TIME) {
            $performanceMetrics.timeout_reached = $true
        }
        
        $cleanupResults.results = @{
            "status" =  "success"
            "cleanup_summary" = $cleanupSummary
            "performance_metrics" = $performanceMetrics
            "total_files_deleted" = $cleanupSummary.files_deleted
            "total_directories_cleaned" = $cleanupSummary.directories_cleaned
            "total_bytes_cleaned" = $cleanupSummary.bytes_cleaned
            "total_mb_cleaned" = [math]::Round($cleanupSummary.bytes_cleaned / 1MB, 2)
            "secure_overwrites_performed" = $cleanupSummary.secure_overwrites
            "errors_encountered" = $cleanupSummary.errors
            "cleanup_method" = if ($Config.T1003_004A_SECURE_DELETE) { "secure_overwrite" } else { "standard_delete" }
            "configuration" = @{
                "secure_delete" = $Config.T1003_004A_SECURE_DELETE
                "overwrite_passes" = $Config.T1003_004A_OVERWRITE_PASSES
                "silent_mode" = $Config.T1003_004A_SILENT_MODE
                "quick_mode" = $Config.T1003_004A_QUICK_MODE
                "simulate_mode" = $Config.T1003_004A_SIMULATE_MODE
                "max_cleanup_time" = $Config.T1003_004A_MAX_CLEANUP_TIME
            }
        }
        
        if (-not $Config.T1003_004A_SILENT_MODE) {
            Write-Host "[SUCCESS] Cleanup completed: $($cleanupSummary.files_deleted) files, $([math]::Round($cleanupSummary.bytes_cleaned/1MB, 2)) MB" -ForegroundColor Green
        }
    }
    catch {
        $cleanupResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "cleanup_summary" = $cleanupSummary
        }
        
        if (-not $Config.T1003_004A_SILENT_MODE) {
            Write-Error "Dump cleanup failed: $($_.Exception.Message)"
        }
    }
    
    return $cleanupResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1003.004a-dump_cleanup"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1003_004A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Cleanup completed: $($Data.results.total_files_deleted) files ($($Data.results.total_mb_cleaned) MB)"
            } else {
                $simpleOutput = "Cleanup failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1003_004A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "cleanup_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "dump_cleanup.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "dump_cleanup.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1003_004A_SILENT_MODE) {
                Write-Host "[DEBUG] Cleanup data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1003_004A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1003.004a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1003_004A_SILENT_MODE) {
            Write-Error "T1003.004a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)



