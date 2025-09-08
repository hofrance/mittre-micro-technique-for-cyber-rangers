# MITRE ATT&CK T1197.001D - BITS Jobs: BITS Job Cleanup
# Implements BITS job cleanup techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1197_001D_OUTPUT_BASE) { $env:T1197_001D_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1197_001D_TIMEOUT) { [int]$env:T1197_001D_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1197_001D_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1197_001D_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1197_001D_VERBOSE_LEVEL) { [int]$env:T1197_001D_VERBOSE_LEVEL } else { 1 }
        "CLEANUP_METHOD" = if ($env:T1197_001D_CLEANUP_METHOD) { $env:T1197_001D_CLEANUP_METHOD } else { "complete_removal" }
        "TARGET_JOBS" = if ($env:T1197_001D_TARGET_JOBS) { $env:T1197_001D_TARGET_JOBS } else { "*" }
    }
}

function Get-BITSJobs {
    try {
        $bitsJobs = Get-BitsTransfer

        $jobsInfo = $bitsJobs | ForEach-Object {
            @{
                JobId = $_.JobId
                DisplayName = $_.DisplayName
                JobState = $_.JobState.ToString()
                OwnerAccount = $_.OwnerAccount
                CreationTime = $_.CreationTime
                ModificationTime = $_.ModificationTime
                BytesTotal = $_.BytesTotal
                BytesTransferred = $_.BytesTransferred
            }
        }

        return @{
            Success = $true
            Error = $null
            Jobs = $jobsInfo
            TotalJobs = $jobsInfo.Count
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Jobs = @()
            TotalJobs = 0
        }
    }
}

function Clean-BITSJobs {
    param([string]$TargetJobs, [string]$CleanupMethod, [hashtable]$Config)

    try {
        $cleanupResults = @{
            JobsFound = 0
            JobsRemoved = 0
            CleanupMethod = $CleanupMethod
            RemovedJobs = @()
        }

        # Get all BITS jobs
        $bitsJobs = Get-BitsTransfer

        foreach ($job in $bitsJobs) {
            $cleanupResults.JobsFound++

            # Remove the job
            Remove-BitsTransfer -BitsJob $job

            $cleanupResults.RemovedJobs += @{
                JobId = $job.JobId
                DisplayName = $job.DisplayName
                RemovalTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                Success = $true
            }

            $cleanupResults.JobsRemoved++

            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
                Write-Host "[INFO] Removed BITS job: $($job.DisplayName)" -ForegroundColor Cyan
            }
        }

        # Also clean up BITS-related files
        $bitsTempPath = "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader"
        if (Test-Path $bitsTempPath) {
            $tempFiles = Get-ChildItem $bitsTempPath -File -ErrorAction SilentlyContinue
            $cleanupResults.TempFilesCleaned = $tempFiles.Count

            foreach ($file in $tempFiles) {
                try {
                    Remove-Item $file.FullName -Force
                } catch {
                    # Continue if file cannot be removed
                }
            }
        }

        return @{
            Success = $true
            Error = $null
            CleanupResults = $cleanupResults
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            CleanupResults = $null
        }
    }
}

function Invoke-BITSJobCleanup {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting BITS job cleanup technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "bits_job_cleanup"
        "technique_id" = "T1197.001D"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1197_001d_bits_job_cleanup"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Get existing BITS jobs
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Getting existing BITS jobs..." -ForegroundColor Cyan
        }

        $jobsResult = Get-BITSJobs

        if (-not $jobsResult.Success) {
            Write-Host "[WARNING] Failed to get BITS jobs: $($jobsResult.Error)" -ForegroundColor Yellow
        }

        # Step 2: Clean up BITS jobs
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Cleaning up BITS jobs using method: $($Config.CLEANUP_METHOD)" -ForegroundColor Cyan
        }

        $cleanupResult = Clean-BITSJobs -TargetJobs $Config.TARGET_JOBS -CleanupMethod $Config.CLEANUP_METHOD -Config $Config

        if (-not $cleanupResult.Success) {
            throw "Failed to clean up BITS jobs: $($cleanupResult.Error)"
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "bits_job_cleanup"
            "output_directory" = $outputDir
            "cleanup_method" = $Config.CLEANUP_METHOD
            "target_jobs" = $Config.TARGET_JOBS
            "jobs_before_cleanup" = $jobsResult.Jobs
            "cleanup_results" = $cleanupResult.CleanupResults
            "technique_demonstrated" = "BITS job cleanup to remove forensic evidence"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "jobs_cleaned" = $cleanupResult.CleanupResults.JobsRemoved -gt 0
            "forensic_cleanup_performed" = $true
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] BITS job cleanup completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "bits_job_cleanup"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] BITS job cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-BITSJobCleanup -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1197.001D BITS JOB CLEANUP RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Cleanup Method: $($results.results.cleanup_method)" -ForegroundColor Yellow
    Write-Host "Jobs Cleaned: $($results.results.cleanup_results.JobsRemoved)" -ForegroundColor Magenta
    Write-Host "Target Jobs: $($results.results.target_jobs)" -ForegroundColor Blue
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1197.001D BITS JOB CLEANUP FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
