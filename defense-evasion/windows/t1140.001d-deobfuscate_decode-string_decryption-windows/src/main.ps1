# MITRE ATT&CK T1140.001D - String Decryption
# Implements string decryption techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1140_001D_OUTPUT_BASE) { $env:T1140_001D_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1140_001D_TIMEOUT) { [int]$env:T1140_001D_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1140_001D_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1140_001D_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1140_001D_VERBOSE_LEVEL) { [int]$env:T1140_001D_VERBOSE_LEVEL } else { 1 }
        "ENCRYPTED_STRING" = if ($env:T1140_001D_ENCRYPTED_STRING) { $env:T1140_001D_ENCRYPTED_STRING } else { "SGVsbG8gRW5jcnlwdGVkIFdvcmxk" }
        "DECRYPTION_METHOD" = if ($env:T1140_001D_DECRYPTION_METHOD) { $env:T1140_001D_DECRYPTION_METHOD } else { "base64" }
        "ENCRYPTION_KEY" = if ($env:T1140_001D_ENCRYPTION_KEY) { $env:T1140_001D_ENCRYPTION_KEY } else { "MySecretKey123" }
    }
}

function Create-EncryptedString {
    param([hashtable]$Config)

    try {
        $originalString = "This is a secret message that should be encrypted"

        # Create encrypted version using Base64
        $encryptedBytes = [System.Text.Encoding]::UTF8.GetBytes($originalString)
        $encryptedString = [Convert]::ToBase64String($encryptedBytes)

        # Save to file
        $encryptedPath = Join-Path $Config.OUTPUT_BASE "encrypted_string.txt"
        $encryptedString | Out-File -FilePath $encryptedPath -Encoding UTF8

        return @{
            Success = $true
            Error = $null
            OriginalString = $originalString
            EncryptedString = $encryptedString
            EncryptedFilePath = $encryptedPath
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            OriginalString = $null
            EncryptedString = $null
            EncryptedFilePath = $null
        }
    }
}

function Decrypt-String {
    param([string]$EncryptedString, [string]$Method, [string]$Key, [hashtable]$Config)

    try {
        $decryptionSteps = @()
        $currentString = $EncryptedString

        switch ($Method.ToLower()) {
            "base64" {
                # Base64 decryption
                $originalString = $currentString
                $decryptedBytes = [Convert]::FromBase64String($currentString)
                $currentString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

                $decryptionSteps += @{
                    Method = "base64"
                    Description = "Decoded Base64 string"
                    OriginalString = $originalString
                    DecryptedString = $currentString
                }
            }

            "xor" {
                # XOR decryption
                $originalString = $currentString
                $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
                $encryptedBytes = [System.Text.Encoding]::UTF8.GetBytes($currentString)

                $decryptedBytes = for ($i = 0; $i -lt $encryptedBytes.Length; $i++) {
                    $encryptedBytes[$i] -bxor $keyBytes[$i % $keyBytes.Length]
                }

                $currentString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

                $decryptionSteps += @{
                    Method = "xor"
                    Description = "Applied XOR decryption with key: $Key"
                    OriginalString = $originalString
                    DecryptedString = $currentString
                }
            }

            "rot13" {
                # ROT13 decryption
                $originalString = $currentString
                $currentString = $currentString.ToCharArray() | ForEach-Object {
                    if ($_ -cmatch '[A-M]') { [char](([int]$_) + 13) }
                    elseif ($_ -cmatch '[N-Z]') { [char](([int]$_) - 13) }
                    elseif ($_ -cmatch '[a-m]') { [char](([int]$_) + 13) }
                    elseif ($_ -cmatch '[n-z]') { [char](([int]$_) - 13) }
                    else { $_ }
                } | Join-String

                $decryptionSteps += @{
                    Method = "rot13"
                    Description = "Applied ROT13 decryption"
                    OriginalString = $originalString
                    DecryptedString = $currentString
                }
            }
        }

        # Save decrypted string to file
        $decryptedPath = Join-Path $Config.OUTPUT_BASE "decrypted_string.txt"
        $currentString | Out-File -FilePath $decryptedPath -Encoding UTF8

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Applied decryption method: $Method" -ForegroundColor Cyan
        }

        return @{
            Success = $true
            Error = $null
            OriginalEncryptedString = $EncryptedString
            DecryptedString = $currentString
            DecryptedFilePath = $decryptedPath
            DecryptionSteps = $decryptionSteps
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            OriginalEncryptedString = $EncryptedString
            DecryptedString = $null
            DecryptedFilePath = $null
            DecryptionSteps = $null
        }
    }
}

function Invoke-StringDecryption {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting string decryption technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "string_decryption"
        "technique_id" = "T1140.001D"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1140_001d_string_decryption"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Create encrypted string
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Creating encrypted string..." -ForegroundColor Cyan
        }

        $encryptedResult = Create-EncryptedString -Config $Config

        if (-not $encryptedResult.Success) {
            throw "Failed to create encrypted string: $($encryptedResult.Error)"
        }

        # Step 2: Decrypt the string
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Decrypting string using method: $($Config.DECRYPTION_METHOD)" -ForegroundColor Cyan
        }

        $decryptionResult = Decrypt-String -EncryptedString $encryptedResult.EncryptedString -Method $Config.DECRYPTION_METHOD -Key $Config.ENCRYPTION_KEY -Config $Config

        if (-not $decryptionResult.Success) {
            throw "Failed to decrypt string: $($decryptionResult.Error)"
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "string_decryption"
            "output_directory" = $outputDir
            "encrypted_file_path" = $encryptedResult.EncryptedFilePath
            "decrypted_file_path" = $decryptionResult.DecryptedFilePath
            "decryption_method" = $Config.DECRYPTION_METHOD
            "original_encrypted_string" = $encryptedResult.EncryptedString
            "decrypted_string" = $decryptionResult.DecryptedString
            "decryption_steps" = $decryptionResult.DecryptionSteps
            "technique_demonstrated" = "String decryption revealing hidden content"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "string_decrypted" = $true
            "files_created" = $true
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] String decryption completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "string_decryption"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] String decryption failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-StringDecryption -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1140.001D STRING DECRYPTION RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Decryption Method: $($results.results.decryption_method)" -ForegroundColor Yellow
    Write-Host "Decryption Steps: $($results.results.decryption_steps.Count)" -ForegroundColor Magenta
    Write-Host "Decrypted String Length: $($results.results.decrypted_string.Length)" -ForegroundColor Blue
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1140.001D STRING DECRYPTION FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
