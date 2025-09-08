# T1140.001E - Compressed Data Extraction
# MITRE ATT&CK Technique: T1140 - Deobfuscate/Decode Files or Information
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # .NET compression support
    try {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        return $true
    } catch {
        return $false
    }
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        CompressedData = if ($env:T1140_001E_COMPRESSED_DATA) { $env:T1140_001E_COMPRESSED_DATA } else { "" }
        SourceFile = if ($env:T1140_001E_SOURCE_FILE) { $env:T1140_001E_SOURCE_FILE } else { "" }
        CompressionType = if ($env:T1140_001E_COMPRESSION_TYPE) { $env:T1140_001E_COMPRESSION_TYPE } else { "gzip" }
        OutputPath = if ($env:T1140_001E_OUTPUT_PATH) { $env:T1140_001E_OUTPUT_PATH } else { "" }
        OutputMode = if ($env:T1140_001E_OUTPUT_MODE) { $env:T1140_001E_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1140_001E_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Extract-GzipData {
    param($CompressedBytes, $OutputPath)
    
    try {
        $inputStream = New-Object System.IO.MemoryStream(,$CompressedBytes)
        $gzipStream = New-Object System.IO.Compression.GzipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $outputStream = New-Object System.IO.MemoryStream
        
        $gzipStream.CopyTo($outputStream)
        $decompressedBytes = $outputStream.ToArray()
        
        $gzipStream.Close()
        $inputStream.Close()
        $outputStream.Close()
        
        if ($OutputPath) {
            [System.IO.File]::WriteAllBytes($OutputPath, $decompressedBytes)
        }
        
        return @{
            Success = $true
            DecompressedBytes = $decompressedBytes
            DecompressedText = [System.Text.Encoding]::UTF8.GetString($decompressedBytes)
            OriginalSize = $CompressedBytes.Length
            DecompressedSize = $decompressedBytes.Length
            CompressionRatio = [math]::Round($CompressedBytes.Length / $decompressedBytes.Length * 100, 2)
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Extract-ZipData {
    param($CompressedBytes, $OutputPath)
    
    try {
        $tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
        [System.IO.File]::WriteAllBytes($tempZip, $CompressedBytes)
        
        if ($OutputPath) {
            if (-not (Test-Path $OutputPath)) {
                New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $OutputPath)
            
            # Get extracted content info
            $extractedFiles = Get-ChildItem -Path $OutputPath -Recurse -File
            $totalSize = ($extractedFiles | Measure-Object -Property Length -Sum).Sum
            
            $result = @{
                Success = $true
                ExtractedFiles = $extractedFiles.Count
                ExtractPath = $OutputPath
                OriginalSize = $CompressedBytes.Length
                DecompressedSize = $totalSize
                CompressionRatio = [math]::Round($CompressedBytes.Length / $totalSize * 100, 2)
            }
        }
        else {
            # Just get info without extracting
            $archive = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
            $entries = $archive.Entries
            $totalSize = ($entries | Measure-Object -Property Length -Sum).Sum
            
            $result = @{
                Success = $true
                ExtractedFiles = $entries.Count
                OriginalSize = $CompressedBytes.Length
                DecompressedSize = $totalSize
                CompressionRatio = [math]::Round($CompressedBytes.Length / $totalSize * 100, 2)
            }
            
            $archive.Dispose()
        }
        
        Remove-Item -Path $tempZip -Force
        return $result
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Extract-DeflateData {
    param($CompressedBytes, $OutputPath)
    
    try {
        $inputStream = New-Object System.IO.MemoryStream(,$CompressedBytes)
        $deflateStream = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $outputStream = New-Object System.IO.MemoryStream
        
        $deflateStream.CopyTo($outputStream)
        $decompressedBytes = $outputStream.ToArray()
        
        $deflateStream.Close()
        $inputStream.Close()
        $outputStream.Close()
        
        if ($OutputPath) {
            [System.IO.File]::WriteAllBytes($OutputPath, $decompressedBytes)
        }
        
        return @{
            Success = $true
            DecompressedBytes = $decompressedBytes
            DecompressedText = [System.Text.Encoding]::UTF8.GetString($decompressedBytes)
            OriginalSize = $CompressedBytes.Length
            DecompressedSize = $decompressedBytes.Length
            CompressionRatio = [math]::Round($CompressedBytes.Length / $decompressedBytes.Length * 100, 2)
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Create-CompressedSample {
    param($Text, $CompressionType)
    
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    
    switch ($CompressionType) {
        "gzip" {
            $outputStream = New-Object System.IO.MemoryStream
            $gzipStream = New-Object System.IO.Compression.GzipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            $gzipStream.Write($plainBytes, 0, $plainBytes.Length)
            $gzipStream.Close()
            $compressed = $outputStream.ToArray()
            $outputStream.Close()
        }
        "zip" {
            $tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
            $tempDir = [System.IO.Path]::GetTempFileName()
            Remove-Item $tempDir
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            
            $tempFile = Join-Path $tempDir "payload.txt"
            Set-Content -Path $tempFile -Value $Text
            
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $tempZip)
            $compressed = [System.IO.File]::ReadAllBytes($tempZip)
            
            Remove-Item $tempDir -Recurse -Force
            Remove-Item $tempZip -Force
        }
        default {
            # Deflate
            $outputStream = New-Object System.IO.MemoryStream
            $deflateStream = New-Object System.IO.Compression.DeflateStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
            $deflateStream.Write($plainBytes, 0, $plainBytes.Length)
            $deflateStream.Close()
            $compressed = $outputStream.ToArray()
            $outputStream.Close()
        }
    }
    
    return [Convert]::ToBase64String($compressed)
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1140.001E"
        TechniqueName = "Compressed Data Extraction"
        Results = @{
            InitialPrivilege = ""
            CompressionType = ""
            OriginalSize = 0
            DecompressedSize = 0
            CompressionRatio = 0
            ExtractedFiles = 0
            OutputPath = ""
            ErrorMessage = ""
        }
    }
    
    # Test critical dependencies
    if (-not (Test-CriticalDependencies)) {
        $Config.Results.ErrorMessage = "Failed to load compression dependencies"
        return $config
    }
    
    # Load environment variables
    $envConfig = Initialize-EnvironmentVariables
    foreach ($key in $envConfig.Keys) {
        $config[$key] = $envConfig[$key]
    }
    
    # Validate compression type
    if ($Config.CompressionType -notin @("gzip", "zip", "deflate")) {
        $Config.CompressionType = "gzip"
    }
    
    # If no compressed data provided, create a sample
    if (-not $Config.CompressedData -and -not $Config.SourceFile) {
        $sampleText = "This is a secret payload that was compressed to evade detection!"
        $Config.CompressedData = Create-CompressedSample -Text $sampleText -CompressionType $Config.CompressionType
    }
    
    $Config.Success = $true
    return $config
}

function Invoke-MicroTechniqueAction {
    param($Config)
    
    # Get initial privilege level
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $Config.Results.InitialPrivilege = if ($isAdmin) { "Administrator" } else { "User" }
    
    if (-not $Config.SilentMode) {
        Write-Host "[INFO] Extracting compressed data ($($Config.CompressionType))..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Extract compressed data
    $Config.Results.CompressionType = $Config.CompressionType
    
    # Load compressed data
    if ($Config.SourceFile) {
        if (-not (Test-Path $Config.SourceFile)) {
            $Config.Results.ErrorMessage = "Source file not found"
            return $Config
        }
        $compressedBytes = [System.IO.File]::ReadAllBytes($Config.SourceFile)
    }
    else {
        try {
            $compressedBytes = [Convert]::FromBase64String($Config.CompressedData)
        }
        catch {
            $Config.Results.ErrorMessage = "Invalid base64 compressed data"
            return $Config
        }
    }
    
    # Perform extraction based on compression type
    switch ($Config.CompressionType) {
        "gzip" {
            $result = Extract-GzipData -CompressedBytes $compressedBytes -OutputPath $Config.OutputPath
        }
        "zip" {
            $result = Extract-ZipData -CompressedBytes $compressedBytes -OutputPath $Config.OutputPath
        }
        "deflate" {
            $result = Extract-DeflateData -CompressedBytes $compressedBytes -OutputPath $Config.OutputPath
        }
    }
    
    if ($result.Success) {
        $Config.Results.OriginalSize = $result.OriginalSize
        $Config.Results.DecompressedSize = $result.DecompressedSize
        $Config.Results.CompressionRatio = $result.CompressionRatio
        
        if ($result.ExtractedFiles) {
            $Config.Results.ExtractedFiles = $result.ExtractedFiles
        }
        
        if ($result.ExtractPath) {
            $Config.Results.OutputPath = $result.ExtractPath
        } elseif ($Config.OutputPath) {
            $Config.Results.OutputPath = $Config.OutputPath
        }
        
        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] Data extracted successfully" -ForegroundColor Green
            Write-Host "    Compression ratio: $($result.CompressionRatio)%" -ForegroundColor Green
        }
    }
    else {
        $Config.Results.ErrorMessage = $result.Error
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Extraction failed: $($result.Error)" -ForegroundColor Red
        }
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1140.001e_extract_compressed_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Compressed Data Extraction Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Compression Type: $($Config.Results.CompressionType)"
            Write-Host "    Original Size: $($Config.Results.OriginalSize) bytes"
            Write-Host "    Decompressed Size: $($Config.Results.DecompressedSize) bytes"
            Write-Host "    Compression Ratio: $($Config.Results.CompressionRatio)%"
            if ($Config.Results.ExtractedFiles -gt 0) {
                Write-Host "    Extracted Files: $($Config.Results.ExtractedFiles)"
            }
            if ($Config.Results.OutputPath) {
                Write-Host "    Output Path: $($Config.Results.OutputPath)"
            }
        }
        
        "debug" {
            $null = New-Item -ItemType Directory -Path $outputDir -Force
            $debugOutput = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Technique = $Config.Technique
                TechniqueName = $Config.TechniqueName
                Platform = "Windows"
                ExecutionResults = $Config.Results
                Configuration = @{
                    CompressionType = $Config.CompressionType
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1140_001e_extract_compressed.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }
        
        "stealth" {
            # Silent operation
        }
    }
}

function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED
    
    # Step 1: Get configuration
    $Config = Get-Configuration
    if (-not $Config.Success) {
        Write-Host "[ERROR] $($Config.Results.ErrorMessage)" -ForegroundColor Red
        exit 1
    }
    
    # Step 2: Execute micro-technique
    $config = Invoke-MicroTechniqueAction -Config $config
    
    # Step 3: Write output
    Write-StandardizedOutput -Config $config
    
    # Return appropriate exit code
    if ($Config.Results.DecompressedSize -gt 0) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

