# T1140.001B - XOR Decryption
# MITRE ATT&CK Technique: T1140 - Deobfuscate/Decode Files or Information
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # PowerShell has built-in byte manipulation support
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        EncryptedData = if ($env:T1140_001B_ENCRYPTED_DATA) { $env:T1140_001B_ENCRYPTED_DATA } else { "" }
        SourceFile = if ($env:T1140_001B_SOURCE_FILE) { $env:T1140_001B_SOURCE_FILE } else { "" }
        XorKey = if ($env:T1140_001B_XOR_KEY) { $env:T1140_001B_XOR_KEY } else { "42" }
        OutputFile = if ($env:T1140_001B_OUTPUT_FILE) { $env:T1140_001B_OUTPUT_FILE } else { "" }
        OutputMode = if ($env:T1140_001B_OUTPUT_MODE) { $env:T1140_001B_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1140_001B_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Decrypt-XorData {
    param(
        [byte[]]$Data,
        [byte[]]$Key
    )
    
    try {
        $decrypted = New-Object byte[] $Data.Length
        
        for ($i = 0; $i -lt $Data.Length; $i++) {
            $decrypted[$i] = $Data[$i] -bxor $Key[$i % $Key.Length]
        }
        
        return @{
            Success = $true
            DecryptedBytes = $decrypted
            DecryptedString = [System.Text.Encoding]::UTF8.GetString($decrypted)
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Decrypt-XorFile {
    param($FilePath, $Key, $OutputPath)
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{ Success = $false; Error = "File not found: $FilePath" }
        }
        
        $encryptedBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
        
        $result = Decrypt-XorData -Data $encryptedBytes -Key $keyBytes
        
        if ($result.Success -and $OutputPath) {
            [System.IO.File]::WriteAllBytes($OutputPath, $result.DecryptedBytes)
            $result.OutputFile = $OutputPath
        }
        
        return $result
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Create-XorSample {
    param($PlainText, $Key)
    
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
    $encrypted = New-Object byte[] $plainBytes.Length
    
    for ($i = 0; $i -lt $plainBytes.Length; $i++) {
        $encrypted[$i] = $plainBytes[$i] -bxor $keyBytes[$i % $keyBytes.Length]
    }
    
    return [Convert]::ToBase64String($encrypted)
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1140.001B"
        TechniqueName = "XOR Decryption"
        Results = @{
            InitialPrivilege = ""
            DecryptedData = ""
            ByteCount = 0
            XorKey = ""
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
    
    # If no encrypted data provided, create a sample
    if (-not $Config.EncryptedData -and -not $Config.SourceFile) {
        $Config.EncryptedData = Create-XorSample -PlainText "Secret Message" -Key $Config.XorKey
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
        Write-Host "[INFO] Decrypting XOR data..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Decrypt XOR data
    $Config.Results.XorKey = $Config.XorKey
    
    if ($Config.SourceFile) {
        $Config.Results.SourceType = "File"
        $result = Decrypt-XorFile -FilePath $Config.SourceFile -Key $Config.XorKey -OutputPath $Config.OutputFile
    }
    else {
        $Config.Results.SourceType = "String"
        # Decode base64 first if needed
        try {
            $encryptedBytes = [Convert]::FromBase64String($Config.EncryptedData)
        }
        catch {
            $encryptedBytes = [System.Text.Encoding]::UTF8.GetBytes($Config.EncryptedData)
        }
        
        $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Config.XorKey)
        $result = Decrypt-XorData -Data $encryptedBytes -Key $keyBytes
        
        if ($result.Success -and $Config.OutputFile) {
            [System.IO.File]::WriteAllBytes($Config.OutputFile, $result.DecryptedBytes)
            $result.OutputFile = $Config.OutputFile
        }
    }
    
    if ($result.Success) {
        $Config.Results.DecryptedData = $result.DecryptedString
        $Config.Results.ByteCount = $result.DecryptedBytes.Length
        $Config.Results.OutputPath = $result.OutputFile
        
        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] XOR decryption completed" -ForegroundColor Green
        }
    }
    else {
        $Config.Results.ErrorMessage = $result.Error
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Decryption failed: $($result.Error)" -ForegroundColor Red
        }
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1140.001b_xor_decrypt_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] XOR Decryption Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Source Type: $($Config.Results.SourceType)"
            Write-Host "    XOR Key: $($Config.Results.XorKey)"
            Write-Host "    Bytes Decrypted: $($Config.Results.ByteCount)"
            if ($Config.Results.OutputPath) {
                Write-Host "    Output File: $($Config.Results.OutputPath)"
            }
            if ($Config.Results.DecryptedData.Length -le 100) {
                Write-Host "    Decrypted: $($Config.Results.DecryptedData)"
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
                    XorKey = $Config.XorKey
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1140_001b_xor_decrypt.json"
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
    if ($Config.Results.ByteCount -gt 0) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

