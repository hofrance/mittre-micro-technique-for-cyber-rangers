# T1003.003a - OS Credential Dumping: Dump Compression
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Compress memory dump file ONLY (requires prior dump creation)
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }

        T1003_003A_SOURCE_DUMP = if ($env:T1003_003A_SOURCE_DUMP) { $env:T1003_003A_SOURCE_DUMP } else { "$env:TEMP\mitre_results\t1003.002a-memory_dump\memory_dump.json" }
        T1003_003A_COMPRESSION_METHOD = if ($env:T1003_003A_COMPRESSION_METHOD) { $env:T1003_003A_COMPRESSION_METHOD } else { "zip" }
        T1003_003A_COMPRESSION_LEVEL = if ($env:T1003_003A_COMPRESSION_LEVEL) { [int]$env:T1003_003A_COMPRESSION_LEVEL } else { 6 }
        T1003_003A_PASSWORD_PROTECT = if ($env:T1003_003A_PASSWORD_PROTECT) { $env:T1003_003A_PASSWORD_PROTECT -eq "true" } else { $true }
        T1003_003A_DELETE_ORIGINAL = if ($env:T1003_003A_DELETE_ORIGINAL) { $env:T1003_003A_DELETE_ORIGINAL -eq "true" } else { $true }
        T1003_003A_SPLIT_SIZE_MB = if ($env:T1003_003A_SPLIT_SIZE_MB) { [int]$env:T1003_003A_SPLIT_SIZE_MB } else { 0 }
        T1003_003A_OUTPUT_MODE = if ($env:T1003_003A_OUTPUT_MODE) { $env:T1003_003A_OUTPUT_MODE } else { "debug" }
        T1003_003A_SILENT_MODE = if ($env:T1003_003A_SILENT_MODE) { $env:T1003_003A_SILENT_MODE -eq "true" } else { $false }
        # NEW: Robustness improvements
        T1003_003A_SIMULATE_MODE = if ($env:T1003_003A_SIMULATE_MODE) { $env:T1003_003A_SIMULATE_MODE -eq "true" } else { $false }  # Simulate if no dump found
        T1003_003A_MAX_COMPRESSION_TIME = if ($env:T1003_003A_MAX_COMPRESSION_TIME) { [int]$env:T1003_003A_MAX_COMPRESSION_TIME } else { 60 }  # Max compression time
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Compress dump file ONLY
    if (-not $Config.T1003_003A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic dump compression..." -ForegroundColor Yellow
    }
    
    $compressionResults = @{
        "action" =  "dump_compression"
        "technique_id" =  "T1003.003a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
    }
    
    try {
        # ROBUSTNESS: Check if source dump exists
        if (-not (Test-Path $Config.T1003_003A_SOURCE_DUMP)) {
            if ($Config.T1003_003A_SIMULATE_MODE) {
                # Simulate successful compression
                $compressionResults.results = @{
                    "status" =  "simulated_success"
                    "simulation_reason" =  "Source dump not found - simulating compression"
                    "simulated_compressed_size_mb" = 50.5
                    "simulated_compression_ratio_percent" = 75.2
                    "simulated_compression_time_seconds" = 2.3
                    "source_file_expected" = $Config.T1003_003A_SOURCE_DUMP
                }
                
                if (-not $Config.T1003_003A_SILENT_MODE) {
                    Write-Host "[SIMULATE] Dump compression simulated (source not found)" -ForegroundColor Yellow
                }
                return $compressionResults
            } else {
                $compressionResults.results = @{
                    "status" =  "skipped"
                    "error" =  "Memory dump data not found. Run t1003.002a first or enable SIMULATE_MODE."
                    "source_file" = $Config.T1003_003A_SOURCE_DUMP
                }
                return $compressionResults
            }
        }
        
        # Load and validate source dump data
        try {
            $dumpData = Get-Content $Config.T1003_003A_SOURCE_DUMP | ConvertFrom-Json
        } catch {
            if ($Config.T1003_003A_SIMULATE_MODE) {
                $compressionResults.results = @{
                    "status" =  "simulated_success"
                    "simulation_reason" =  "Source dump corrupted - simulating compression"
                    "simulated_compressed_size_mb" = 45.8
                    "simulated_compression_ratio_percent" = 72.1
                    "simulated_compression_time_seconds" = 1.9
                }
                
                if (-not $Config.T1003_003A_SILENT_MODE) {
                    Write-Host "[SIMULATE] Dump compression simulated (source corrupted)" -ForegroundColor Yellow
                }
                return $compressionResults
            } else {
                $compressionResults.results = @{
                    "status" =  "error"
                    "error" =  "Failed to parse source dump data: $($_.Exception.Message)"
                }
                return $compressionResults
            }
        }
        
        # Check if source dump was successful
        if ($dumpData.results.status -ne "success") {
            if ($Config.T1003_003A_SIMULATE_MODE) {
                $compressionResults.results = @{
                    "status" =  "simulated_success"
                    "simulation_reason" =  "Source dump failed - simulating compression"
                    "source_status" = $dumpData.results.status
                    "simulated_compressed_size_mb" = 42.3
                    "simulated_compression_ratio_percent" = 69.8
                    "simulated_compression_time_seconds" = 1.7
                }
                
                if (-not $Config.T1003_003A_SILENT_MODE) {
                    Write-Host "[SIMULATE] Dump compression simulated (source failed)" -ForegroundColor Yellow
                }
                return $compressionResults
            } else {
                $compressionResults.results = @{
                    "status" =  "skipped"
                    "error" =  "Source dump was not successful"
                    "source_status" = $dumpData.results.status
                }
                return $compressionResults
            }
        }
        
        $originalDumpPath = $dumpData.results.dump_path
        
        # Check if original dump file exists
        if (-not (Test-Path $originalDumpPath)) {
            if ($Config.T1003_003A_SIMULATE_MODE) {
                $compressionResults.results = @{
                    "status" =  "simulated_success"
                    "simulation_reason" =  "Original dump file not found - simulating compression"
                    "expected_path" = $originalDumpPath
                    "simulated_compressed_size_mb" = 48.7
                    "simulated_compression_ratio_percent" = 74.5
                    "simulated_compression_time_seconds" = 2.1
                }
                
                if (-not $Config.T1003_003A_SILENT_MODE) {
                    Write-Host "[SIMULATE] Dump compression simulated (original file missing)" -ForegroundColor Yellow
                }
                return $compressionResults
            } else {
                $compressionResults.results = @{
                    "status" =  "failed"
                    "error" =  "Original dump file not found at: $originalDumpPath"
                }
                return $compressionResults
            }
        }
        
        # Prepare compression
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1003.003a-dump_compression"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $originalSize = (Get-Item $originalDumpPath).Length
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $compressedFileName = "lsass_dump_compressed_$timestamp.zip"
        $compressedPath = Join-Path $outputDir $compressedFileName
        
        if (-not $Config.T1003_003A_SILENT_MODE) {
            Write-Host "[INFO] Compressing dump: $([math]::Round($originalSize/1MB, 2)) MB" -ForegroundColor Cyan
        }
        
        $startTime = Get-Date
        
        # Perform compression with timeout protection
        $compressionJob = Start-Job -ScriptBlock {
            param($sourcePath, $destPath, $method)
            try {
                switch ($method) {
                    "zip" {
                        Compress-Archive -Path $sourcePath -DestinationPath $destPath -CompressionLevel Optimal -Force
                        return @{ Success = $true; Error = $null }
                    }
                    default {
                        return @{ Success = $false; Error = "Unsupported compression method: $method" }
                    }
                }
            } catch {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        } -ArgumentList $originalDumpPath, $compressedPath, $Config.T1003_003A_COMPRESSION_METHOD
        
        # Wait for compression with timeout
        $jobCompleted = Wait-Job $compressionJob -Timeout $Config.T1003_003A_MAX_COMPRESSION_TIME
        $compressionResult = Receive-Job $compressionJob
        Remove-Job $compressionJob
        
        if (-not $jobCompleted) {
            # Compression timed out
            Stop-Job $compressionJob -ErrorAction SilentlyContinue
            Remove-Job $compressionJob -ErrorAction SilentlyContinue
            
            $compressionResults.results = @{
                "status" =  "timeout"
                "error" =  "Compression exceeded timeout of $($Config.T1003_003A_MAX_COMPRESSION_TIME) seconds"
                "original_size_mb" = [math]::Round($originalSize / 1MB, 2)
            }
            return $compressionResults
        }
        
        if (-not $compressionResult.Success) {
            $compressionResults.results = @{
                "status" =  "error"
                "error" =  "Compression failed: $($compressionResult.Error)"
                "original_size_mb" = [math]::Round($originalSize / 1MB, 2)
            }
            return $compressionResults
        }
        
        $endTime = Get-Date
        $compressionTime = [math]::Round(($endTime - $startTime).TotalSeconds, 2)
        
        if (Test-Path $compressedPath) {
            $compressedSize = (Get-Item $compressedPath).Length
            $compressionRatio = [math]::Round((1 - ($compressedSize / $originalSize)) * 100, 1)
            
            # Delete original if requested
            if ($Config.T1003_003A_DELETE_ORIGINAL) {
                Remove-Item $originalDumpPath -Force
                $originalDeleted = $true
            } else {
                $originalDeleted = $false
            }
            
            $compressionResults.results = @{
                "status" =  "success"
                "compressed_file" = $compressedPath
                "original_size_bytes" = $originalSize
                "compressed_size_bytes" = $compressedSize
                "original_size_mb" = [math]::Round($originalSize / 1MB, 2)
                "compressed_size_mb" = [math]::Round($compressedSize / 1MB, 2)
                "compression_ratio_percent" = $compressionRatio
                "compression_method" = $Config.T1003_003A_COMPRESSION_METHOD
                "compression_time_seconds" = $compressionTime
                "original_deleted" = $originalDeleted
                "original_path" = $originalDumpPath
            }
            
            if (-not $Config.T1003_003A_SILENT_MODE) {
                Write-Host "[SUCCESS] Dump compressed: $compressionRatio% reduction ($([math]::Round($compressedSize/1MB, 2)) MB)" -ForegroundColor Green
            }
        } else {
            $compressionResults.results = @{
                "status" =  "failed"
                "error" =  "Compression completed but output file not found"
                "expected_path" = $compressedPath
            }
        }
    }
    catch {
        $compressionResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
        }
        
        if (-not $Config.T1003_003A_SILENT_MODE) {
            Write-Error "Dump compression failed: $($_.Exception.Message)"
        }
    }
    
    return $compressionResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1003.003a-dump_compression"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1003_003A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Dump compressed: $($Data.results.compression_ratio_percent)% reduction"
            } else {
                $simpleOutput = "Compression failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1003_003A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "compression_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "dump_compression.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "dump_compression.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1003_003A_SILENT_MODE) {
                Write-Host "[DEBUG] Compression data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1003_003A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1003.003a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1003_003A_SILENT_MODE) {
            Write-Error "T1003.003a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)



