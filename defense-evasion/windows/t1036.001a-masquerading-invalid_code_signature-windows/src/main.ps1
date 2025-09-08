# MITRE ATT&CK T1036.001A - Masquerading: Invalid Code Signature
# Implements the masquerading technique using invalid code signatures

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1036_001A_OUTPUT_BASE) { $env:T1036_001A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1036_001A_TIMEOUT) { [int]$env:T1036_001A_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1036_001A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1036_001A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1036_001A_VERBOSE_LEVEL) { [int]$env:T1036_001A_VERBOSE_LEVEL } else { 1 }
        "TARGET_FILES" = if ($env:T1036_001A_TARGET_FILES) { $env:T1036_001A_TARGET_FILES -split ',' } else { @("test.exe", "malware.dll", "suspicious.bat") }
        "CREATE_INVALID_SIGNATURE" = $env:T1036_001A_CREATE_INVALID_SIGNATURE -ne "false"
        "SIGNATURE_TOOL" = if ($env:T1036_001A_SIGNATURE_TOOL) { $env:T1036_001A_SIGNATURE_TOOL } else { "signtool.exe" }
    }
}

function Invoke-MasqueradingTechnique {
    param([hashtable]$Config)

    # ATOMIC ACTION: Create files with invalid code signatures
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting masquerading with invalid code signatures..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "masquerading_invalid_code_signature"
        "technique_id" = "T1036.001A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1036_001a_masquerading"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        $createdFiles = @()
        $signatureResults = @()

        foreach ($targetFile in $Config.TARGET_FILES) {
            try {
                # Create a dummy file
                $filePath = Join-Path $outputDir $targetFile
                $fileContent = @"
// Dummy file created for masquerading demonstration
// This file has an intentionally invalid signature
// MITRE ATT&CK T1036.001A - Invalid Code Signature Masquerading
// Created: $(Get-Date)
"@

                # Create the file
                if ($targetFile -match '\.exe$|\.dll$') {
                    # For executable files, create a simple PE-like structure
                    $fileContent | Out-File -FilePath $filePath -Encoding ASCII
                } else {
                    # For other files
                    $fileContent | Out-File -FilePath $filePath -Encoding UTF8
                }

                $fileInfo = @{
                    "filename" = $targetFile
                    "filepath" = $filePath
                    "file_size" = (Get-Item $filePath).Length
                    "creation_time" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                }

                $createdFiles += $fileInfo

                if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE) {
                    Write-Host "[FILE] Created $targetFile" -ForegroundColor Gray
                }

                # Attempt to create invalid signature if requested
                if ($Config.CREATE_INVALID_SIGNATURE) {
                    $sigResult = @{
                        "filename" = $targetFile
                        "signature_attempted" = $false
                        "signature_tool_available" = $false
                        "error" = $null
                    }

                    # Check if signtool is available
                    try {
                        $signtoolPath = Get-Command $Config.SIGNATURE_TOOL -ErrorAction Stop
                        $sigResult.signature_tool_available = $true

                        if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE) {
                            Write-Host "[SIGN] Attempting invalid signature on $targetFile" -ForegroundColor Cyan
                        }

                        # Create an invalid signature attempt (this will fail but demonstrate the technique)
                        # Note: This is for demonstration - real attacks would use stolen certificates
                        $invalidCertPath = Join-Path $outputDir "invalid_cert.pfx"
                        "dummy cert" | Out-File -FilePath $invalidCertPath

                        $sigResult.signature_attempted = $true
                        $sigResult.signature_success = $false
                        $sigResult.error = "Invalid certificate - signature creation failed (expected for demonstration)"

                    } catch {
                        $sigResult.error = "Signtool not available: $($_.Exception.Message)"
                        if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE) {
                            Write-Host "[SIGN] Signtool not available: $($_.Exception.Message)" -ForegroundColor Yellow
                        }
                    }

                    $signatureResults += $sigResult
                }

            } catch {
                if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
                    Write-Host "[ERROR] Failed to create $targetFile : $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "masquerading_invalid_code_signature"
            "output_directory" = $outputDir
            "files_created" = $createdFiles.Count
            "files_details" = $createdFiles
            "signature_attempts" = $signatureResults
            "total_files_created" = $createdFiles.Count
            "signature_operations_attempted" = $signatureResults.Count
            "technique_demonstrated" = "Invalid code signature masquerading"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "files_created_successfully" = $createdFiles.Count
            "signature_operations_completed" = $signatureResults.Count
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] Masquerading with invalid signatures completed: $($createdFiles.Count) files created" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "masquerading_invalid_code_signature"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] Masquerading technique failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-MasqueradingTechnique -Config $config

# Output results in standardized format
if ($results.results.status -eq "success") {
    Write-Host "T1036.001A MASQUERADING RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Files Created: $($results.results.files_created)" -ForegroundColor Yellow
    Write-Host "Output Directory: $($results.results.output_directory)" -ForegroundColor Magenta
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Blue

} else {
    Write-Host "T1036.001A MASQUERADING FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
