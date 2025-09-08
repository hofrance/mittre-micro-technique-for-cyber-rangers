# T1003.001a - OS Credential Dumping: LSASS Process Detection
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Detect and enumerate LSASS process ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

# CONTRACTUAL POWERSHELL ARCHITECTURE (4 mandatory functions)

function Get-Configuration {
    return @{
        # Universal MITRE variables - REAL ATTACK MODE
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1003.001a ultra-granular LSASS detection variables - REAL ATTACK MODE
        T1003_001A_DETECTION_TIMEOUT = 10000
        T1003_001A_RETRY_COUNT = 5
        T1003_001A_INCLUDE_DETAILS = $true
        T1003_001A_CHECK_PRIVILEGES = $true
        T1003_001A_PROCESS_NAME = "lsass"
        T1003_001A_VERIFY_INTEGRITY = $true
        T1003_001A_OUTPUT_MODE = "debug"
        T1003_001A_SILENT_MODE = $false
        T1003_001A_STEALTH_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: LSASS process detection ONLY
    if (-not $Config.T1003_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic LSASS process detection..." -ForegroundColor Yellow
    }
    
    $detectionResults = @{
        "action" =  "lsass_process_detection"
        "technique_id" =  "T1003.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "administrator" } else { "user" }
    }
    
    try {
        $retryCount = 0
        $lsassProcess = $null
        
        # Simple and safe process detection
        do {
            try {
                $lsassProcess = Get-Process -Name $Config.T1003_001A_PROCESS_NAME -ErrorAction SilentlyContinue
                
                # Basic validation
                if ($lsassProcess -and $lsassProcess.Id -gt 0) {
                    break
                } else {
                    $lsassProcess = $null
                }
            } catch {
                $lsassProcess = $null
            }
            
            if (-not $lsassProcess -and $retryCount -lt $Config.T1003_001A_RETRY_COUNT) {
                Start-Sleep -Milliseconds 500
                $retryCount++
            }
        } while (-not $lsassProcess -and $retryCount -lt $Config.T1003_001A_RETRY_COUNT)
        
        if ($lsassProcess) {
            # Only use the most basic and reliable properties
            $processDetails = @{
                "process_id" = $lsassProcess.Id
                "process_name" = $lsassProcess.ProcessName
                "status" =  "detected"
                "detection_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            
            # Try to get basic memory info safely
            try {
                if ($lsassProcess.WorkingSet64 -gt 0) {
                    $processDetails.working_set_mb = [math]::Round($lsassProcess.WorkingSet64 / 1MB, 2)
                }
            } catch {
                $processDetails.working_set_error = "Not accessible"
            }
            
            # Try to get virtual memory safely
            try {
                if ($lsassProcess.VirtualMemorySize64 -gt 0) {
                    $processDetails.virtual_memory_mb = [math]::Round($lsassProcess.VirtualMemorySize64 / 1MB, 2)
                }
            } catch {
                $processDetails.virtual_memory_error = "Not accessible"
            }
            
            # Try to get handle count safely
            try {
                if ($lsassProcess.HandleCount -ge 0) {
                    $processDetails.handle_count = $lsassProcess.HandleCount
                }
            } catch {
                $processDetails.handle_count_error = "Not accessible"
            }
            
            # Try to get thread count safely
            try {
                if ($lsassProcess.Threads -and $lsassProcess.Threads.Count -ge 0) {
                    $processDetails.thread_count = $lsassProcess.Threads.Count
                }
            } catch {
                $processDetails.thread_count_error = "Not accessible"
            }
            
            # Try to get session ID safely
            try {
                if ($lsassProcess.SessionId -ge 0) {
                    $processDetails.session_id = $lsassProcess.SessionId
                }
            } catch {
                $processDetails.session_id_error = "Not accessible"
            }
            
            # Try to get priority class safely
            try {
                if ($lsassProcess.PriorityClass) {
                    $processDetails.priority_class = $lsassProcess.PriorityClass.ToString()
                }
            } catch {
                $processDetails.priority_class_error = "Not accessible"
            }
            
            # Try to get responding status safely
            try {
                if ($lsassProcess.Responding -ne $null) {
                    $processDetails.responding = $lsassProcess.Responding
                }
            } catch {
                $processDetails.responding_error = "Not accessible"
            }
            
            # Try to get company info safely
            try {
                if ($lsassProcess.Company) {
                    $processDetails.company = $lsassProcess.Company
                }
            } catch {
                $processDetails.company_error = "Not accessible"
            }
            
            # Try to get file version safely
            try {
                if ($lsassProcess.FileVersion) {
                    $processDetails.file_version = $lsassProcess.FileVersion
                }
            } catch {
                $processDetails.file_version_error = "Not accessible"
            }
            
            # Try to get main module filename safely
            try {
                if ($lsassProcess.MainModule -and $lsassProcess.MainModule.FileName) {
                    $processDetails.main_module_filename = $lsassProcess.MainModule.FileName
                }
            } catch {
                $processDetails.main_module_error = "Not accessible"
            }
            
            # Try to get start time safely
            try {
                if ($lsassProcess -and $lsassProcess.StartTime) {
                    $processDetails.start_time = $lsassProcess.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                } elseif ($lsassProcess) {
                    $processDetails.start_time_error = "Start time not accessible"
                }
            } catch {
                $processDetails.start_time_error = "Not accessible: $($_.Exception.Message)"
            }
            
            $detectionResults.results = $processDetails
            
            if (-not $Config.T1003_001A_SILENT_MODE) {
                Write-Host "[SUCCESS] LSASS process detected - PID: $($processDetails.process_id)" -ForegroundColor Green
            }
        } else {
            $detectionResults.results = @{
                "status" =  "not_found"
                "process_name" = $Config.T1003_001A_PROCESS_NAME
                "retry_attempts" = $retryCount
                "error" =  "LSASS process not found after $retryCount attempts"
            }
            
            if (-not $Config.T1003_001A_SILENT_MODE) {
                Write-Warning "LSASS process not detected after $retryCount attempts"
            }
        }
    }
    catch {
        $detectionResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "process_name" = $Config.T1003_001A_PROCESS_NAME
        }
        
        if (-not $Config.T1003_001A_SILENT_MODE) {
            Write-Error "LSASS detection failed: $($_.Exception.Message)"
        }
    }
    
    return $detectionResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    # Initialize output structure
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1003.001a-lsass_detection"
    
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1003_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "detected") {
                $simpleOutput = "LSASS detected - PID: $($Data.results.process_id)"
                if ($Data.results.working_set_mb) {
                    $simpleOutput += ", Memory: $($Data.results.working_set_mb)MB"
                }
            } else {
                $simpleOutput = "LSASS not detected"
            }
            
            if (-not $Config.T1003_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "lsass_detection_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            # Minimal stealth output - only JSON file, no console
            $jsonFile = Join-Path $outputDir "lsass_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            # Full debug output with JSON
            $jsonFile = Join-Path $outputDir "lsass_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1003_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Full detection data written to: $jsonFile" -ForegroundColor Cyan
            }
        }
    }
    
    return $outputDir
}

function Main {
    try {
        # Load configuration
        $Config = Get-Configuration
        
        # Execute atomic technique
        $results = Invoke-MicroTechniqueAction -Config $config
        
        # Write standardized output
        $outputPath = Write-StandardizedOutput -Data $results -Config $config
        
        if (-not $Config.T1003_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1003.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1003_001A_SILENT_MODE) {
            Write-Error "T1003.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

# Execute main function
exit (Main)
