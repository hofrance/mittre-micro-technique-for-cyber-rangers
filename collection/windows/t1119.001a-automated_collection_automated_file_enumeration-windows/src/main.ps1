# T1119.001a - Automated Collection: Automated File Enumeration
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Enumerate files by automated criteria ONLY (no content analysis)
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1119.001a - REAL ATTACK MODE - Extensive search for sensitive files
        T1119_001A_SEARCH_PATTERNS = @("*.doc*", "*.pdf", "*.txt", "*.xls*", "*.ppt*", "*.zip", "*.rar", "*.key", "*.pem", "*.crt", "*.cer", "*.pfx", "*.p12", "*.db", "*.sqlite", "*.sqlite3", "*.config", "*.ini", "*.xml", "*.json", "*.yaml", "*.yml", "*.log", "*.history", "*.bash_history", "*.zsh_history", "*.ps1", "*.bat", "*.cmd", "*.vbs", "*.js", "*.py", "*.php", "*.sql", "*.mdb", "*.accdb", "*.ost", "*.pst")
        T1119_001A_SEARCH_PATHS = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\AppData", "$env:PROGRAMDATA", "$env:WINDIR\System32", "$env:APPDATA\Microsoft\Windows\Recent", "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache", "$env:USERPROFILE\AppData\Local\Temp")
        T1119_001A_MAX_FILES = 10000
        T1119_001A_SCAN_DEPTH = 10
        T1119_001A_MIN_FILE_SIZE_KB = 0
        T1119_001A_MAX_FILE_SIZE_MB = 1000
        T1119_001A_INCLUDE_HIDDEN = $true
        T1119_001A_INCLUDE_SYSTEM = $true
        T1119_001A_DATE_FILTER_DAYS = 0
        T1119_001A_SORT_BY = "LastWriteTime"
        T1119_001A_OUTPUT_MODE = "debug"
        T1119_001A_SILENT_MODE = $false
        T1119_001A_STEALTH_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Automated file enumeration ONLY
    if (-not $Config.T1119_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic automated file enumeration..." -ForegroundColor Yellow
    }
    
    $enumerationResults = @{
        "action" =  "automated_file_enumeration"
        "technique_id" =  "T1119.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1119.001a-file_enumeration"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $enumeratedFiles = @()
        $totalFilesScanned = 0
        $totalSizeMB = 0
        
        if (-not $Config.T1119_001A_SILENT_MODE) {
            Write-Host "[INFO] Scanning paths: $($Config.T1119_001A_SEARCH_PATHS -join ', ')" -ForegroundColor Cyan
            Write-Host "[INFO] Patterns: $($Config.T1119_001A_SEARCH_PATTERNS -join ', ')" -ForegroundColor Cyan
        }
        
        foreach ($searchPath in $Config.T1119_001A_SEARCH_PATHS) {
            $searchPath = $searchPath.Trim()
            
            if (-not (Test-Path $searchPath)) {
                if (-not $Config.T1119_001A_SILENT_MODE) {
                    Write-Warning "Search path not found: $searchPath"
                }
                continue
            }
            
            foreach ($pattern in $Config.T1119_001A_SEARCH_PATTERNS) {
                $pattern = $pattern.Trim()
                
                try {
                    $searchParams = @{
                        "Path" = $searchPath
                        "Filter" = $pattern
                        "Recurse" = $Config.T1119_001A_SCAN_DEPTH -gt 1
                        "File" = $true
                        "ErrorAction" =  "SilentlyContinue"
                    }
                    
                    # Include hidden files if requested
                    if ($Config.T1119_001A_INCLUDE_HIDDEN) {
                        $searchParams.Force = $true
                    }
                    
                    $files = Get-ChildItem @searchParams
                    
                    foreach ($file in $files) {
                        $totalFilesScanned++
                        
                        # Apply size filters
                        $fileSizeKB = [math]::Round($file.Length / 1KB, 2)
                        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                        
                        if ($fileSizeKB -lt $Config.T1119_001A_MIN_FILE_SIZE_KB -or $fileSizeMB -gt $Config.T1119_001A_MAX_FILE_SIZE_MB) {
                            continue
                        }
                        
                        # Apply date filter if specified
                        if ($Config.T1119_001A_DATE_FILTER_DAYS -gt 0) {
                            $cutoffDate = (Get-Date).AddDays(-$Config.T1119_001A_DATE_FILTER_DAYS)
                            if ($file.LastWriteTime -lt $cutoffDate) {
                                continue
                            }
                        }
                        
                        # Skip system files if not included
                        if (-not $Config.T1119_001A_INCLUDE_SYSTEM -and ($file.Attributes -band [System.IO.FileAttributes]::System)) {
                            continue
                        }
                        
                        $fileInfo = @{
                            "file_path" = $file.FullName
                            "file_name" = $file.Name
                            "file_extension" = $file.Extension
                            "size_bytes" = $file.Length
                            "size_kb" = $fileSizeKB
                            "size_mb" = $fileSizeMB
                            "creation_time" = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                            "last_write_time" = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                            "last_access_time" = $file.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss")
                            "attributes" = $file.Attributes.ToString()
                            "is_hidden" = ($file.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0
                            "is_system" = ($file.Attributes -band [System.IO.FileAttributes]::System) -ne 0
                            "is_readonly" = ($file.Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0
                            "search_pattern" = $pattern
                            "search_path" = $searchPath
                            "enumeration_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                        }
                        
                        # Add file hash if file is small enough
                        if ($file.Length -lt 10MB) {
                            try {
                                $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                                if ($hash) {
                                    $fileInfo.sha256_hash = $hash.Hash
                                }
                            } catch {
                                $fileInfo.hash_error = $_.Exception.Message
                            }
                        }
                        
                        $enumeratedFiles += $fileInfo
                        $totalSizeMB += $fileSizeMB
                        
                        # Respect max files limit
                        if ($enumeratedFiles.Count -ge $Config.T1119_001A_MAX_FILES) {
                            break
                        }
                    }
                    
                    # Break if max files reached
                    if ($enumeratedFiles.Count -ge $Config.T1119_001A_MAX_FILES) {
                        break
                    }
                } catch {
                    if (-not $Config.T1119_001A_SILENT_MODE) {
                        Write-Warning "Pattern search failed for $pattern in $searchPath`: $($_.Exception.Message)"
                    }
                }
            }
            
            # Break if max files reached
            if ($enumeratedFiles.Count -ge $Config.T1119_001A_MAX_FILES) {
                break
            }
        }
        
        # Sort files based on configuration
        switch ($Config.T1119_001A_SORT_BY) {
            "LastWriteTime" { $enumeratedFiles = $enumeratedFiles | Sort-Object last_write_time -Descending }
            "Size" { $enumeratedFiles = $enumeratedFiles | Sort-Object size_bytes -Descending }
            "Name" { $enumeratedFiles = $enumeratedFiles | Sort-Object file_name }
            "Extension" { $enumeratedFiles = $enumeratedFiles | Sort-Object file_extension, file_name }
            default { $enumeratedFiles = $enumeratedFiles | Sort-Object last_write_time -Descending }
        }
        
        # Save enumeration results
        $enumerationFile = Join-Path $outputDir "file_enumeration.json"
        $enumeratedFiles | ConvertTo-Json -Depth 5 | Out-File -FilePath $enumerationFile -Encoding UTF8
        
        # Generate statistics
        $statistics = @{
            "total_files_enumerated" = $enumeratedFiles.Count
            "total_files_scanned" = $totalFilesScanned
            "total_size_mb" = [math]::Round($totalSizeMB, 2)
            "enumeration_efficiency" = if ($totalFilesScanned -gt 0) { [math]::Round(($enumeratedFiles.Count / $totalFilesScanned) * 100, 2) } else { 0 }
            "file_extensions" = ($enumeratedFiles | Group-Object file_extension | Sort-Object Count -Descending | ForEach-Object { @{ extension = $_.Name; count = $_.Count } })
            "size_distribution" = @{
                under_1mb = ($enumeratedFiles | Where-Object { $_.size_mb -lt 1 }).Count
                between_1_10mb = ($enumeratedFiles | Where-Object { $_.size_mb -ge 1 -and $_.size_mb -lt 10 }).Count
                over_10mb = ($enumeratedFiles | Where-Object { $_.size_mb -ge 10 }).Count
            }
            "date_range" = @{
                "oldest_file" = ($enumeratedFiles | Sort-Object last_write_time | Select-Object -First 1).last_write_time
                "newest_file" = ($enumeratedFiles | Sort-Object last_write_time -Descending | Select-Object -First 1).last_write_time
            }
        }
        
        $enumerationResults.results = @{
            "status" =  "success"
            "enumeration_file" = $enumerationFile
            "statistics" = $statistics
            "configuration_used" = @{
                "search_patterns" = $Config.T1119_001A_SEARCH_PATTERNS
                "search_paths" = $Config.T1119_001A_SEARCH_PATHS
                "max_files" = $Config.T1119_001A_MAX_FILES
                "scan_depth" = $Config.T1119_001A_SCAN_DEPTH
                "size_limits" = @{
                    "min_kb" = $Config.T1119_001A_MIN_FILE_SIZE_KB
                    "max_mb" = $Config.T1119_001A_MAX_FILE_SIZE_MB
                }
                "include_hidden" = $Config.T1119_001A_INCLUDE_HIDDEN
                "include_system" = $Config.T1119_001A_INCLUDE_SYSTEM
                "sort_by" = $Config.T1119_001A_SORT_BY
            }
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1119_001A_SILENT_MODE) {
            Write-Host "[SUCCESS] File enumeration completed: $($enumeratedFiles.Count) files found (scanned $totalFilesScanned total)" -ForegroundColor Green
        }
    }
    catch {
        $enumerationResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "files_enumerated" = if ($enumeratedFiles) { $enumeratedFiles.Count } else { 0 }
        }
        
        if (-not $Config.T1119_001A_SILENT_MODE) {
            Write-Error "Automated file enumeration failed: $($_.Exception.Message)"
        }
    }
    
    return $enumerationResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1119.001a-file_enumeration"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1119_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "File enumeration: $($Data.results.statistics.total_files_enumerated) files found ($($Data.results.statistics.total_size_mb) MB)"
            } else {
                $simpleOutput = "File enumeration failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1119_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "file_enumeration_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "automated_file_enumeration.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "automated_file_enumeration.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1119_001A_SILENT_MODE) {
                Write-Host "[DEBUG] File enumeration data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1119_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1119.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1119_001A_SILENT_MODE) {
            Write-Error "T1119.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


