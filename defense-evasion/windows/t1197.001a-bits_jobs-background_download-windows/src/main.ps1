# MITRE ATT&CK T1197.001A - BITS Jobs: Background Download
# Implements BITS background download techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1197_001A_OUTPUT_BASE) { $env:T1197_001A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1197_001A_TIMEOUT) { [int]$env:T1197_001A_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1197_001A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1197_001A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1197_001A_VERBOSE_LEVEL) { [int]$env:T1197_001A_VERBOSE_LEVEL } else { 1 }
        "DOWNLOAD_URL" = if ($env:T1197_001A_DOWNLOAD_URL) { $env:T1197_001A_DOWNLOAD_URL } else { "http://httpbin.org/uuid" }
        "LOCAL_FILE_PATH" = if ($env:T1197_001A_LOCAL_FILE_PATH) { $env:T1197_001A_LOCAL_FILE_PATH } else { "$env:TEMP\bits_downloaded_file.txt" }
        "BITS_JOB_NAME" = if ($env:T1197_001A_BITS_JOB_NAME) { $env:T1197_001A_BITS_JOB_NAME } else { "SystemUpdateDownload" }
    }
}

function Create-BITSJob {
    param([string]$JobName, [string]$Url, [string]$LocalPath, [hashtable]$Config)

    try {
        # Create BITS transfer job
        $bitsJob = Start-BitsTransfer -Source $Url -Destination $LocalPath -DisplayName $JobName -Description "System update download" -Asynchronous

        # Wait for completion (simulation)
        Start-Sleep -Seconds 2

        # Complete the job
        Complete-BitsTransfer -BitsJob $bitsJob

        $jobInfo = @{
            JobId = $bitsJob.JobId
            JobName = $bitsJob.DisplayName
            JobState = $bitsJob.JobState
            BytesTransferred = $bitsJob.BytesTransferred
            BytesTotal = $bitsJob.BytesTotal
            CreationTime = $bitsJob.CreationTime
            ModificationTime = $bitsJob.ModificationTime
        }

        return @{
            Success = $true
            Error = $null
            BITSJob = $bitsJob
            JobInfo = $jobInfo
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            BITSJob = $null
            JobInfo = $null
        }
    }
}

function Verify-BITSDownload {
    param([string]$LocalPath, [hashtable]$Config)

    try {
        $verificationResults = @{
            FileExists = $false
            FileSize = 0
            FileContent = $null
            DownloadSuccessful = $false
        }

        if (Test-Path $LocalPath) {
            $fileInfo = Get-Item $LocalPath
            $verificationResults.FileExists = $true
            $verificationResults.FileSize = $fileInfo.Length
            $verificationResults.FileContent = Get-Content $LocalPath -Raw -ErrorAction SilentlyContinue
            $verificationResults.DownloadSuccessful = $true
        }

        return @{
            Success = $true
            Error = $null
            Verification = $verificationResults
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Verification = $null
        }
    }
}

function Invoke-BITSBackgroundDownload {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting BITS background download technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "bits_background_download"
        "technique_id" = "T1197.001A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1197_001a_bits_background_download"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Create BITS job
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Creating BITS job for download..." -ForegroundColor Cyan
            Write-Host "[INFO] URL: $($Config.DOWNLOAD_URL)" -ForegroundColor Cyan
            Write-Host "[INFO] Local Path: $($Config.LOCAL_FILE_PATH)" -ForegroundColor Cyan
        }

        $bitsResult = Create-BITSJob -JobName $Config.BITS_JOB_NAME -Url $Config.DOWNLOAD_URL -LocalPath $Config.LOCAL_FILE_PATH -Config $Config

        if (-not $bitsResult.Success) {
            throw "Failed to create BITS job: $($bitsResult.Error)"
        }

        # Step 2: Verify download
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Verifying download..." -ForegroundColor Cyan
        }

        $verificationResult = Verify-BITSDownload -LocalPath $Config.LOCAL_FILE_PATH -Config $Config

        if (-not $verificationResult.Success) {
            Write-Host "[WARNING] Download verification failed: $($verificationResult.Error)" -ForegroundColor Yellow
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "bits_background_download"
            "output_directory" = $outputDir
            "download_url" = $Config.DOWNLOAD_URL
            "local_file_path" = $Config.LOCAL_FILE_PATH
            "bits_job_name" = $Config.BITS_JOB_NAME
            "bits_job_info" = $bitsResult.JobInfo
            "download_verification" = $verificationResult.Verification
            "technique_demonstrated" = "BITS background download for stealthy file transfer"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "bits_job_created" = $true
            "download_completed" = $verificationResult.Verification.DownloadSuccessful
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] BITS background download completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "bits_background_download"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] BITS background download failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-BITSBackgroundDownload -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1197.001A BITS BACKGROUND DOWNLOAD RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Download URL: $($results.results.download_url)" -ForegroundColor Yellow
    Write-Host "Local File: $($results.results.local_file_path)" -ForegroundColor Magenta
    Write-Host "BITS Job: $($results.results.bits_job_name)" -ForegroundColor Blue
    Write-Host "Download Verified: $($results.results.download_verification.DownloadSuccessful)" -ForegroundColor Cyan
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1197.001A BITS BACKGROUND DOWNLOAD FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
