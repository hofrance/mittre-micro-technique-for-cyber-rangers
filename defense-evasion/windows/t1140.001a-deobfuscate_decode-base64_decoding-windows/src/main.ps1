# T1140.001A - Base64 Decoding
# MITRE ATT&CK Technique: T1140 - Deobfuscate/Decode Files or Information
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # PowerShell has built-in Base64 support
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        EncodedData = if ($env:T1140_001A_ENCODED_DATA) { $env:T1140_001A_ENCODED_DATA } else { "SGVsbG8gV29ybGQh" }
        SourceFile = if ($env:T1140_001A_SOURCE_FILE) { $env:T1140_001A_SOURCE_FILE } else { "" }
        OutputFile = if ($env:T1140_001A_OUTPUT_FILE) { $env:T1140_001A_OUTPUT_FILE } else { "" }
        OutputMode = if ($env:T1140_001A_OUTPUT_MODE) { $env:T1140_001A_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1140_001A_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Decode-Base64String {
    param($EncodedString)
    
    try {
        $bytes = [System.Convert]::FromBase64String($EncodedString)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
        
        return @{
            Success = $true
            Decoded = $decoded
            ByteCount = $bytes.Length
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Decode-Base64File {
    param($FilePath, $OutputPath)
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{ Success = $false; Error = "File not found: $FilePath" }
        }
        
        $encodedContent = Get-Content -Path $FilePath -Raw
        $result = Decode-Base64String -EncodedString $encodedContent.Trim()
        
        if ($result.Success -and $OutputPath) {
            Set-Content -Path $OutputPath -Value $result.Decoded -NoNewline
            $result.OutputFile = $OutputPath
        }
        
        return $result
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1140.001A"
        TechniqueName = "Base64 Decoding"
        Results = @{
            InitialPrivilege = ""
            DecodedData = ""
            ByteCount = 0
            SourceType = ""
            OutputPath = ""
            ErrorMessage = ""
        }
    }
    
    # Test critical dependencies
    if (-not (Test-CriticalDependencies)) {
        $Config.Results.ErrorMessage = "Failed to load dependencies"
        return $config
    }
    
    # Load environment variables
    $envConfig = Initialize-EnvironmentVariables
    foreach ($key in $envConfig.Keys) {
        $config[$key] = $envConfig[$key]
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
        Write-Host "[INFO] Decoding Base64 data..." -ForegroundColor Yellow
    }

    # ATOMIC ACTION: Decode Base64 data
    if ($Config.SourceFile) {
        $Config.Results.SourceType = "File"
        $result = Decode-Base64File -FilePath $Config.SourceFile -OutputPath $Config.OutputFile
    }
    else {
        $Config.Results.SourceType = "String"
        $result = Decode-Base64String -EncodedString $Config.EncodedData

        if ($result.Success -and $Config.OutputFile) {
            Set-Content -Path $Config.OutputFile -Value $result.Decoded -NoNewline
            $result.OutputFile = $Config.OutputFile
        }
    }

    if ($result.Success) {
        $Config.Results.DecodedData = $result.Decoded
        $Config.Results.ByteCount = $result.ByteCount
        $Config.Results.OutputPath = $result.OutputFile

        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] Base64 decoded successfully" -ForegroundColor Green
        }
    }
    else {
        $Config.Results.ErrorMessage = $result.Error
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Decoding failed: $($result.Error)" -ForegroundColor Red
        }
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)

    $outputDir = Join-Path $Config.OutputBase "T1140.001a_base64_decode_$($Config.Timestamp)"

    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Base64 Decoding Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Source Type: $($Config.Results.SourceType)"
            Write-Host "    Bytes Decoded: $($Config.Results.ByteCount)"
            if ($Config.Results.OutputPath) {
                Write-Host "    Output File: $($Config.Results.OutputPath)"
            }
            if ($Config.Results.DecodedData.Length -le 100) {
                Write-Host "    Decoded: $($Config.Results.DecodedData)"
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
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1140_001a_base64_decode.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }

        "stealth" {
            # Silent operation
        }

        "silent" {
            # Completely silent - no output at all
        }
    }
}

function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 124=SKIPPED

    # Step 1: Get configuration
    $Config = Get-Configuration
    if (-not $Config.Success) {
        if ($Config.OutputMode -ne "silent") {
            Write-Host "[ERROR] $($Config.Results.ErrorMessage)" -ForegroundColor Red
        }
        exit 124  # SKIPPED - preconditions not met
    }

    # Step 2: Execute micro-technique
    $config = Invoke-MicroTechniqueAction -Config $config

    # Step 3: Write output
    Write-StandardizedOutput -Config $config

    # Return appropriate exit code
    if ($Config.Results.ByteCount -gt 0) {
        exit 0  # SUCCESS
    } else {
        exit 1  # FAILED
    }
}

# Execute main function
Main

