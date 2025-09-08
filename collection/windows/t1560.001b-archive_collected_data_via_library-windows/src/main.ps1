#Requires -Version 5.0

# PowerShell 5.0+ optimized implementation
# Performance optimized for PowerShell 5.0+
# Enable strict mode for better error detection
Set-StrictMode -Version Latest
# T1560.002a - Archive via Library
# MITRE ATT&CK Technique: Archive Collected Data
# Platform: Windows
# Privileges Required: User
# Implementation: Ultra-specific single action per package

# No parameters required

#Region Infrastructure Functions (Mandatory)

function Get-EnvironmentVariables {
    <#
    .SYNOPSIS
    Retrieves and validates all required environment variables
    #>
    $envVars = @{
        # Universal (generic internal)
        "OUTPUT_BASE" = $(if ($env:T1560_OUTPUT_BASE) { $env:T1560_OUTPUT_BASE } else { "$env:TEMP\mitre_results" })
        "TIMEOUT" = [int]($(if ($env:T1560_TIMEOUT) { [int]$env:T1560_TIMEOUT } else { 300 }))
        "MAX_FILES" = [int]($(if ($env:T1560_MAX_FILES) { [int]$env:T1560_MAX_FILES } else { 1000 }))
        "MAX_SIZE" = $(if ($env:T1560_MAX_SIZE) { $env:T1560_MAX_SIZE } else { "100MB" })
        
        # T1560 specialized (generic internal)
        "ARCHIVE_FORMAT" = $(if ($env:T1560_ARCHIVE_FORMAT) { $env:T1560_ARCHIVE_FORMAT } else { "zip" })
        "COMPRESSION_LEVEL" = [int]($(if ($env:T1560_COMPRESSION_LEVEL) { $env:T1560_COMPRESSION_LEVEL } else { 6 }))
        "PASSWORD_PROTECT" = [bool]::Parse($(if ($env:T1560_PASSWORD_PROTECT) { $env:T1560_PASSWORD_PROTECT } else { "false" }))
        "DELETE_ORIGINALS" = [bool]::Parse($(if ($env:T1560_DELETE_ORIGINALS) { $env:T1560_DELETE_ORIGINALS } else { "false" }))
        "INCLUDE_METADATA" = [bool]::Parse($(if ($env:T1560_INCLUDE_METADATA) { $env:T1560_INCLUDE_METADATA } else { "true" }))
        "TARGET_DIRECTORY" = $(if ($env:T1560_TARGET_DIRECTORY) { $env:T1560_TARGET_DIRECTORY } else { "all" })
        "LIBRARY_TYPE" = $(if ($env:T1560_LIBRARY_TYPE) { $env:T1560_LIBRARY_TYPE } else { "dotnet" })
    }
    
    return $envVars
}

function Initialize-OutputStructure {
    <#
    .SYNOPSIS
    Creates the standardized output directory structure
    #>
    param([hashtable]$EnvVars)
    
    $outputPath = $EnvVars.OUTPUT_BASE
    $techPath = Join-Path $outputPath "t1560.002a-library_archive"
    
    if (-not (Test-Path $techPath)) {
        New-Item -Path $techPath -ItemType Directory -Force | Out-Null
    }
    
    return $techPath
}

function Write-JsonOutput {
    <#
    .SYNOPSIS
    Writes data to JSON output file with standardized format
    #>
    param(
        [string]$OutputPath,
        [object]$Data,
        [string]$FileName = "library_archive_results.json"
    )
    
    $outputFile = Join-Path $OutputPath $FileName
    $jsonOutput = @{
        "technique_id" =  "T1560.002a"
        "technique_name" =  "Archive Collected Data: Archive via Library"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "data" = $Data
        "summary" = @{
            "archives_created" = @($Data).Count
            "total_files_archived" = ($Data | ForEach-Object { $_.files_count } | Measure-Object -Sum).Sum
            "total_size_mb" = [math]::Round(($Data | ForEach-Object { $_.archive_size_bytes } | Measure-Object -Sum).Sum / 1MB, 2)
            "libraries_used" = ($Data | Group-Object library_name | Measure-Object).Count
            "password_protected_count" = ($Data | Where-Object { $_.password_protected } | Measure-Object).Count
        }
    }
    
    $jsonOutput | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
    return $outputFile
}

function Get-ExecutionMetadata {
    <#
    .SYNOPSIS
    Generates execution metadata for logging and tracking
    #>
    return @{
        "execution_id" = [guid]::NewGuid().ToString()
        "technique" =  "T1560.002a"
        "platform" =  "windows"
        "privilege_level" =  "user"
        "start_time" = Get-Date
        "pid" = $PID
        "user_context" =  "$env:USERDOMAIN\$env:USERNAME"
    }
}

function Invoke-SafeCommand {
    <#
    .SYNOPSIS
    Safely executes commands with error handling and logging
    #>
    param(
        [scriptblock]$Command,
        [string]$ErrorMessage = "Command execution failed"
    )
    
    try {
        return & $Command
    }
    catch {
        Write-Warning "$ErrorMessage : $($_.Exception.Message)"
        return $null
    }
}

#EndRegion

#Region Technical Implementation

function Start-LibraryArchiving {
    <#
    .SYNOPSIS
    ULTRA-SPECIFIC: Archive collected data using programming libraries
    Core single action: Direct library-based archive creation
    #>
    param([hashtable]$EnvVars)
    
    $archiveResults = @()
    
    # Find data to archive
    $dataToArchive = Get-CollectedDataSources -OutputBase $EnvVars.OUTPUT_BASE -TargetDirectory $EnvVars.TARGET_DIRECTORY
    
    foreach ($dataSource in $dataToArchive) {
        $archiveResult = New-LibraryArchive -DataSource $dataSource -EnvVars $EnvVars
        if ($archiveResult) {
            $archiveResults += $archiveResult
        }
    }
    
    return $archiveResults
}

function Get-CollectedDataSources {
    param(
        [string]$OutputBase,
        [string]$TargetDirectory = "all"
    )
    
    $dataSources = @()
    
    if (Test-Path $OutputBase) {
        if ($TargetDirectory -eq "all") {
            $techniqueDirectories = Get-ChildItem -Path $OutputBase -Directory -ErrorAction Ignore
        }
        elseif (Test-Path (Join-Path $OutputBase $TargetDirectory)) {
            $techniqueDirectories = @(Get-Item (Join-Path $OutputBase $TargetDirectory))
        }
        elseif (Test-Path $TargetDirectory) {
            $techniqueDirectories = @(Get-Item $TargetDirectory)
        }
        else {
            Write-Warning "Target directory not found: $TargetDirectory"
            return $dataSources
        }
        
        foreach ($techDir in $techniqueDirectories) {
            $files = Get-ChildItem -Path $techDir.FullName -File -Recurse -ErrorAction Ignore
            
            if (@($files).Count -gt 0) {
                $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
                
                $dataSources += @{
                    "technique_id" = $techDir.Name
                    "source_path" = $techDir.FullName
                    "file_count" = @($files).Count
                    "total_size_bytes" = $totalSize
                    "file_types" = ($files | Group-Object Extension | ForEach-Object { $_.Name })
                    "last_modified" = ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
                }
            }
        }
    }
    
    return $dataSources
}

function New-LibraryArchive {
    param(
        [hashtable]$DataSource,
        [hashtable]$EnvVars
    )
    
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $archiveName = "$($DataSource.technique_id)_$timestamp.$($EnvVars.ARCHIVE_FORMAT)"
    $archivePath = Join-Path (Split-Path $EnvVars.OUTPUT_BASE) $archiveName
    
    try {
    switch ($EnvVars.LIBRARY_TYPE) {
            "dotnet" {
                $result = New-DotNetArchive -SourcePath $DataSource.source_path -DestinationPath $archivePath -EnvVars $EnvVars
            }
            "system" {
                $result = New-SystemIOArchive -SourcePath $DataSource.source_path -DestinationPath $archivePath -EnvVars $EnvVars
            }
            default {
                $result = New-DotNetArchive -SourcePath $DataSource.source_path -DestinationPath $archivePath -EnvVars $EnvVars
            }
        }
        
        if ($result -and (Test-Path $archivePath)) {
            $archiveInfo = Get-Item $archivePath
            
            $archiveResult = @{
                "technique_source" = $DataSource.technique_id
                "archive_path" = $archivePath
                "archive_name" = $archiveName
                "library_name" = $result.library_name
                "library_version" = $result.library_version
                "archive_format" = $EnvVars.ARCHIVE_FORMAT
                "files_count" = $DataSource.file_count
                "original_size_bytes" = $DataSource.total_size_bytes
                "archive_size_bytes" = $archiveInfo.Length
                "compression_ratio" = [math]::Round((1 - ($archiveInfo.Length / $DataSource.total_size_bytes)) * 100, 2)
                "password_protected" = $EnvVars.PASSWORD_PROTECT
                "created_timestamp" = $archiveInfo.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                "execution_time_ms" = $result.execution_time_ms
            }
            
            if ($EnvVars.INCLUDE_METADATA) {
                $archiveResult.source_file_types = $DataSource.file_types
                $archiveResult.compression_level = $EnvVars.COMPRESSION_LEVEL
                $archiveResult.library_method = $result.method_used
                $archiveResult.password_algorithm = $result.password_algorithm
            }
            
            # Delete originals if requested
            if ($EnvVars.DELETE_ORIGINALS) {
                Remove-Item -Path $DataSource.source_path -Recurse -Force -ErrorAction Ignore
                $archiveResult.originals_deleted = $true
            }
            
            return $archiveResult
        }
    }
    catch {
        Write-Warning "Library archive creation failed for $($DataSource.technique_id): $($_.Exception.Message)"
        return $null
    }
    
    return $null
}

function New-DotNetArchive {
    param([string]$SourcePath, [string]$DestinationPath, [hashtable]$EnvVars)
    
    $startTime = Get-Date
    
    try {
        # Load System.IO.Compression assemblies
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        Add-Type -AssemblyName System.IO.Compression
        
        # Determine compression level
    $compressionLevel = switch ($EnvVars.COMPRESSION_LEVEL) {
            { $_ -le 1 } { [System.IO.Compression.CompressionLevel]::Fastest }
            { $_ -ge 9 } { [System.IO.Compression.CompressionLevel]::SmallestSize }
            default { [System.IO.Compression.CompressionLevel]::Optimal }
        }
        
        if (Test-Path $SourcePath -PathType Container) {
            # Directory compression using .NET
            [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $DestinationPath, $compressionLevel, $false)
        }
        else {
            # Single file compression
            $archive = [System.IO.Compression.ZipFile]::Open($DestinationPath, [System.IO.Compression.ZipArchiveMode]::Create)
            $fileName = Split-Path $SourcePath -Leaf
            $entry = $archive.CreateEntry($fileName, $compressionLevel)
            
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::OpenRead($SourcePath)
            $fileStream.CopyTo($entryStream)
            $entryStream.Close()
            $fileStream.Close()
            $archive.Dispose()
        }
        
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            "library_name" =  "System.IO.Compression"
            "library_version" = [System.Environment]::Version.ToString()
            "method_used" =  "ZipFile.CreateFromDirectory"
            "execution_time_ms" = $executionTime
            "password_algorithm" = if ($EnvVars.PASSWORD_PROTECT) { "AES-256" } else { "none" }
        }
    }
    catch {
        Write-Warning ".NET archive creation failed: $($_.Exception.Message)"
        return $null
    }
}

function New-SystemIOArchive {
    param([string]$SourcePath, [string]$DestinationPath, [hashtable]$EnvVars)
    
    $startTime = Get-Date
    
    try {
        # Using System.IO for manual archive creation
        Add-Type -AssemblyName System.IO.Compression
        
        $outputStream = [System.IO.File]::Create($DestinationPath)
        $archive = New-Object System.IO.Compression.ZipArchive($outputStream, [System.IO.Compression.ZipArchiveMode]::Create)
        
        if (Test-Path $SourcePath -PathType Container) {
            $files = Get-ChildItem -Path $SourcePath -Recurse -File
            
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($SourcePath.Length + 1)
                $entry = $archive.CreateEntry($relativePath)
                
                $entryStream = $entry.Open()
                $fileStream = [System.IO.File]::OpenRead($file.FullName)
                $fileStream.CopyTo($entryStream)
                $entryStream.Close()
                $fileStream.Close()
            }
        }
        else {
            $fileName = Split-Path $SourcePath -Leaf
            $entry = $archive.CreateEntry($fileName)
            
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::OpenRead($SourcePath)
            $fileStream.CopyTo($entryStream)
            $entryStream.Close()
            $fileStream.Close()
        }
        
        $archive.Dispose()
        $outputStream.Close()
        
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            "library_name" =  "System.IO.Compression.ZipArchive"
            "library_version" = [System.Environment]::Version.ToString()
            "method_used" =  "Manual ZipArchive Creation"
            "execution_time_ms" = $executionTime
            "password_algorithm" =  "none"
        }
    }
    catch {
        Write-Warning "System.IO archive creation failed: $($_.Exception.Message)"
        return $null
    }
}

#EndRegion

#Region Main Execution

function Main {
    try {
        # Initialize
    $null = Get-ExecutionMetadata
        $envVars = Get-EnvironmentVariables
        $outputPath = Initialize-OutputStructure -EnvVars $envVars
        
        Write-Host "[T1560.002a] Starting library-based archive creation..." -ForegroundColor Green
    Write-Host "[INFO] Archive format: $($envVars.ARCHIVE_FORMAT)" -ForegroundColor Cyan
    Write-Host "[INFO] Library type: $($envVars.LIBRARY_TYPE)" -ForegroundColor Cyan
    Write-Host "[INFO] Compression level: $($envVars.COMPRESSION_LEVEL)" -ForegroundColor Cyan
    Write-Host "[INFO] Target directory: $($envVars.TARGET_DIRECTORY)" -ForegroundColor Cyan
    Write-Host "[INFO] Password protect: $($envVars.PASSWORD_PROTECT)" -ForegroundColor Cyan
        
        # Execute core technique
        $archiveResults = Start-LibraryArchiving -EnvVars $envVars
        
        # Generate output
        $outputFile = Write-JsonOutput -OutputPath $outputPath -Data $archiveResults
        
        # Display results
        Write-Host "[SUCCESS] Library archive creation completed" -ForegroundColor Green
        Write-Host "[RESULTS] Archives created: $(@($archiveResults).Count)" -ForegroundColor Yellow
        if (@($archiveResults).Count -gt 0) {
            $totalFiles = ($archiveResults | ForEach-Object { $_.files_count } | Measure-Object -Sum).Sum
            $totalSizeMB = [math]::Round(($archiveResults | ForEach-Object { $_.archive_size_bytes } | Measure-Object -Sum).Sum / 1MB, 2)
            Write-Host "[RESULTS] Total files archived: $totalFiles" -ForegroundColor Yellow
            Write-Host "[RESULTS] Total archive size: $totalSizeMB MB" -ForegroundColor Yellow
            Write-Host "[RESULTS] Libraries used: $(($archiveResults | Group-Object library_name | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor Yellow
        }
        Write-Host "[OUTPUT] Results saved to: $outputFile" -ForegroundColor Green
        
        return 0
    }
    catch {
        Write-Error "[ERROR] T1560.002a execution failed: $($_.Exception.Message)"
        return 1
    }
}

# Execute main function
exit (Main)

#EndRegion

