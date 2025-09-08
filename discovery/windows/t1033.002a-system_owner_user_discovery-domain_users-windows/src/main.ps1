# T1033 - System Owner/User Discovery
# MITRE ATT&CK Enterprise - Discovery Tactic (TA0007)
# ATOMIC ACTION: Discover system users
# Platform: Windows

Set-StrictMode -Version Latest

function Get-Configuration {
    $config = @{
        Technique = "T1033"
        TechniqueName = "System Owner/User Discovery"
        OutputMode = "simple"
        SilentMode = $false
        SafeMode = $false
        Results = @{
            InitialPrivilege = "User"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Success = $false
            ErrorMessage = ""
            ExecutionTime = 0
        }
    }
    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)

    $startTime = Get-Date

    try {
        Write-Host "   Discovering system users..." -ForegroundColor Cyan

        $users = Get-LocalUser | Select-Object Name
        $Config.Results.Success = $true
        $Config.Results.ExecutionTime = (Get-Date) - $startTime

        Write-Host "  Found $($users.Count) local users" -ForegroundColor Green

        return @{ Success = $true; Data = "Users discovery completed" }

    }
    catch {
        $Config.Results.Success = $false
        $Config.Results.ErrorMessage = $_.Exception.Message
        $Config.Results.ExecutionTime = (Get-Date) - $startTime

        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Write-StandardizedOutput {
    param([hashtable]$Config)

    if (-not $Config.SilentMode) {
        Write-Host ""
        Write-Host "[$($Config.Technique)] $($Config.TechniqueName)" -ForegroundColor Green
        Write-Host "   Execution Time: $($Config.Results.Timestamp)"
        Write-Host "   Success: $($Config.Results.Success)"
        if ($Config.Results.Success) {
            Write-Host "   Status: Users discovery completed"
        } else {
            Write-Host "   Error: $($Config.Results.ErrorMessage)" -ForegroundColor Red
        }
    }
}

function Main {
    try {
        $Config = Get-Configuration
        if ($Config.SafeMode) {
            Write-Host "[SAFE MODE] $($Config.Technique) - Simulation only" -ForegroundColor Yellow
            exit 124
        }

        $result = Invoke-MicroTechniqueAction -Config $config
        Write-StandardizedOutput -Config $config

        if ($result.Success) {
            Write-Host "[SUCCESS] $($Config.Technique) completed" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "[FAILED] $($Config.Technique) failed" -ForegroundColor Red
            exit 1
        }

    }
    catch {
        Write-Host "[ERROR] $($Config.Technique) execution error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Main

