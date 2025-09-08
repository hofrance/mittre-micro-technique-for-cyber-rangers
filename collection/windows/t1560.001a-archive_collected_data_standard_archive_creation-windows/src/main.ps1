# T1560.001a - Archive Collected Data: Standard Archive Creation
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Create standard archive of collected data ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        
        T1560_001A_SOURCE_DIRECTORIES = if ($env:T1560_001A_SOURCE_DIRECTORIES) { $env:T1560_001A_SOURCE_DIRECTORIES -split ";" } else { @("$env:TEMP\mitre_results", "$env:USERPROFILE\Documents") }
        T1560_001A_ARCHIVE_FORMAT = if ($env:T1560_001A_ARCHIVE_FORMAT) { $env:T1560_001A_ARCHIVE_FORMAT } else { "zip" }
        T1560_001A_COMPRESSION_LEVEL = if ($env:T1560_001A_COMPRESSION_LEVEL) { [int]$env:T1560_001A_COMPRESSION_LEVEL } else { 6 }
        T1560_001A_INCLUDE_SUBDIRS = if ($env:T1560_001A_INCLUDE_SUBDIRS) { $env:T1560_001A_INCLUDE_SUBDIRS -eq "true" } else { $true }
        T1560_001A_MAX_ARCHIVE_SIZE_MB = if ($env:T1560_001A_MAX_ARCHIVE_SIZE_MB) { [int]$env:T1560_001A_MAX_ARCHIVE_SIZE_MB } else { 100 }
        T1560_001A_EXCLUDE_PATTERNS = if ($env:T1560_001A_EXCLUDE_PATTERNS) { $env:T1560_001A_EXCLUDE_PATTERNS -split "," } else { @("*.tmp", "*.log", "*.cache") }
        T1560_001A_TIMESTAMP_FILENAME = if ($env:T1560_001A_TIMESTAMP_FILENAME) { $env:T1560_001A_TIMESTAMP_FILENAME -eq "true" } else { $true }
        T1560_001A_DELETE_SOURCES = if ($env:T1560_001A_DELETE_SOURCES) { $env:T1560_001A_DELETE_SOURCES -eq "true" } else { $false }
        T1560_001A_OUTPUT_MODE = if ($env:T1560_001A_OUTPUT_MODE) { $env:T1560_001A_OUTPUT_MODE } else { "debug" }
        T1560_001A_SILENT_MODE = if ($env:T1560_001A_SILENT_MODE) { $env:T1560_001A_SILENT_MODE -eq "true" } else { $false }
        T1560_001A_STEALTH_MODE = if ($env:T1560_001A_STEALTH_MODE) { $env:T1560_001A_STEALTH_MODE -eq "true" } else { $false }
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Standard archive creation ONLY
    if (-not $Config.T1560_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic standard archive creation..." -ForegroundColor Yellow
    }
    
    $archiveResults = @{
        "action" =  "standard_archive_creation"
        "technique_id" =  "T1560.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1560.001a-archive"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Generate archive name
        if ($Config.T1560_001A_TIMESTAMP_FILENAME) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $archiveName = "collection_$timestamp.$($Config.T1560_001A_ARCHIVE_FORMAT)"
        } else {
            $archiveName = "collection.$($Config.T1560_001A_ARCHIVE_FORMAT)"
        }
        
        $archivePath = Join-Path $outputDir $archiveName
        
        # Collect files to archive
        $filesToArchive = @()
        $totalSizeMB = 0
        $processedDirectories = @()
        
        if (-not $Config.T1560_001A_SILENT_MODE) {
            Write-Host "[INFO] Scanning source directories for files to archive..." -ForegroundColor Cyan
        }
        
        foreach ($sourceDir in $Config.T1560_001A_SOURCE_DIRECTORIES) {
            $sourceDir = $sourceDir.Trim()
            
            if (Test-Path $sourceDir) {
                $processedDirectories += $sourceDir
                
                try {
                    $files = Get-ChildItem -Path $sourceDir -Recurse:$Config.T1560_001A_INCLUDE_SUBDIRS -File -ErrorAction SilentlyContinue
                    
                    foreach ($file in $files) {
                        # Check exclude patterns
                        $excluded = $false
                        foreach ($pattern in $Config.T1560_001A_EXCLUDE_PATTERNS) {
                            if ($file.Name -like $pattern.Trim()) {
                                $excluded = $true
                                break
                            }
                        }
                        
                        if (-not $excluded) {
                            $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                            
                            # Check if adding this file would exceed size limit
                            if (($totalSizeMB + $fileSizeMB) -le $Config.T1560_001A_MAX_ARCHIVE_SIZE_MB) {
                                $filesToArchive += @{
                                    "path" = $file.FullName
                                    "name" = $file.Name
                                    "size_bytes" = $file.Length
                                    "size_mb" = $fileSizeMB
                                    "source_directory" = $sourceDir
                                    "last_modified" = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                                }
                                $totalSizeMB += $fileSizeMB
                            }
                        }
                    }
                } catch {
                    if (-not $Config.T1560_001A_SILENT_MODE) {
                        Write-Warning "Failed to process directory $sourceDir`: $($_.Exception.Message)"
                    }
                }
            } else {
                if (-not $Config.T1560_001A_SILENT_MODE) {
                    Write-Warning "Source directory not found: $sourceDir"
                }
            }
        }
        
        if ($filesToArchive.Count -gt 0) {
            if (-not $Config.T1560_001A_SILENT_MODE) {
                Write-Host "[INFO] Creating archive with $($filesToArchive.Count) files ($totalSizeMB MB total)" -ForegroundColor Cyan
            }
            
            $startTime = Get-Date
            
            # Create archive based on format
            switch ($Config.T1560_001A_ARCHIVE_FORMAT.ToLower()) {
                "zip" {
                    $filePaths = $filesToArchive | ForEach-Object { $_.path }
                    Compress-Archive -Path $filePaths -DestinationPath $archivePath -CompressionLevel ([System.IO.Compression.CompressionLevel]::Optimal) -Force
                }
                "tar" {
                    # Using Windows 10+ built-in tar
                    $filePaths = $filesToArchive | ForEach-Object { "`"$($_.path)`"" }
                    $tarArgs = @("-czf", "`"$archivePath`"") + $filePaths
                    $result = & tar @tarArgs 2>&1
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Tar creation failed: $result"
                    }
                }
                default {
                    throw "Unsupported archive format: $($Config.T1560_001A_ARCHIVE_FORMAT)"
                }
            }
            
            $endTime = Get-Date
            $creationTime = [math]::Round(($endTime - $startTime).TotalSeconds, 2)
            
            # Verify archive creation
            if (Test-Path $archivePath) {
                $archiveInfo = Get-Item $archivePath
                $compressionRatio = [math]::Round((1 - ($archiveInfo.Length / ($totalSizeMB * 1MB))) * 100, 1)
                
                # Delete source files if requested
                $deletedFiles = 0
                if ($Config.T1560_001A_DELETE_SOURCES) {
                    foreach ($fileInfo in $filesToArchive) {
                        try {
                            Remove-Item $fileInfo.path -Force
                            $deletedFiles++
                        } catch {
                            # Continue on error
                        }
                    }
                }
                
                $archiveResults.results = @{
                    "status" =  "success"
                    "archive_path" = $archivePath
                    "archive_filename" = $archiveName
                    "archive_size_bytes" = $archiveInfo.Length
                    "archive_size_mb" = [math]::Round($archiveInfo.Length / 1MB, 2)
                    "files_archived" = $filesToArchive.Count
                    "original_total_size_mb" = $totalSizeMB
                    "compression_ratio_percent" = $compressionRatio
                    "archive_format" = $Config.T1560_001A_ARCHIVE_FORMAT
                    "creation_time_seconds" = $creationTime
                    "creation_timestamp" = $archiveInfo.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                    "source_directories" = $processedDirectories
                    "files_deleted" = $deletedFiles
                    "files_archived_details" = if ($Config.T1560_001A_OUTPUT_MODE -eq "debug") { $filesToArchive } else { $null }
                }
                
                if (-not $Config.T1560_001A_SILENT_MODE) {
                    Write-Host "[SUCCESS] Archive created: $archiveName ($($archiveResults.results.archive_size_mb) MB, $compressionRatio% compression)" -ForegroundColor Green
                }
            } else {
                $archiveResults.results = @{
                    "status" =  "failed"
                    "error" =  "Archive creation completed but file not found"
                    "expected_path" = $archivePath
                    "files_processed" = $filesToArchive.Count
                }
            }
        } else {
            $archiveResults.results = @{
                "status" =  "no_files"
                "error" =  "No files found to archive in source directories"
                "source_directories" = $processedDirectories
                "files_archived" = 0
            }
            
            if (-not $Config.T1560_001A_SILENT_MODE) {
                Write-Host "[INFO] No files found to archive" -ForegroundColor Yellow
            }
        }
    }
    catch {
        $archiveResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "files_processed" = if ($filesToArchive) { $filesToArchive.Count } else { 0 }
        }
        
        if (-not $Config.T1560_001A_SILENT_MODE) {
            Write-Error "Archive creation failed: $($_.Exception.Message)"
        }
    }
    
    return $archiveResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1560.001a-archive"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1560_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Archive created: $($Data.results.archive_filename) ($($Data.results.files_archived) files, $($Data.results.archive_size_mb) MB)"
            } elseif ($Data.results.status -eq "no_files") {
                $simpleOutput = "No files to archive"
            } else {
                $simpleOutput = "Archive creation failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1560_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "archive_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "standard_archive.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "standard_archive.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1560_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Archive data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1560_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1560.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1560_001A_SILENT_MODE) {
            Write-Error "T1560.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


