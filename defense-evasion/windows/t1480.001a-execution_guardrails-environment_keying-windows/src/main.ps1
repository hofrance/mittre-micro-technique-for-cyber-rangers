# T1480.001A - Environment Keying
# MITRE ATT&CK Technique: T1480 - Execution Guardrails
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # PowerShell environment check capabilities
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        RequiredDomain = if ($env:T1480_001A_REQUIRED_DOMAIN) { $env:T1480_001A_REQUIRED_DOMAIN } else { "" }
        RequiredHostname = if ($env:T1480_001A_REQUIRED_HOSTNAME) { $env:T1480_001A_REQUIRED_HOSTNAME } else { "" }
        RequiredUsername = if ($env:T1480_001A_REQUIRED_USERNAME) { $env:T1480_001A_REQUIRED_USERNAME } else { "" }
        RequiredProcess = if ($env:T1480_001A_REQUIRED_PROCESS) { $env:T1480_001A_REQUIRED_PROCESS } else { "" }
        ActionOnFail = if ($env:T1480_001A_ACTION_ON_FAIL) { $env:T1480_001A_ACTION_ON_FAIL } else { "exit" }
        OutputMode = if ($env:T1480_001A_OUTPUT_MODE) { $env:T1480_001A_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1480_001A_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Test-DomainRequirement {
    param($RequiredDomain)
    
    try {
        $currentDomain = $env:USERDNSDOMAIN
        if (-not $currentDomain) {
            # Try alternative methods
            $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
            $currentDomain = $computerSystem.Domain
        }
        
        $match = $false
        if ($RequiredDomain -like "*.*") {
            # Full domain name
            $match = $currentDomain -eq $RequiredDomain
        } else {
            # Partial domain name
            $match = $currentDomain -like "*$RequiredDomain*"
        }
        
        return @{
            Success = $true
            CurrentDomain = $currentDomain
            RequiredDomain = $RequiredDomain
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Test-HostnameRequirement {
    param($RequiredHostname)
    
    try {
        $currentHostname = $env:COMPUTERNAME
        
        $match = $false
        if ($RequiredHostname -like "*%") {
            # Pattern matching
            $pattern = $RequiredHostname -replace '%', '*'
            $match = $currentHostname -like $pattern
        } else {
            # Exact match
            $match = $currentHostname -eq $RequiredHostname
        }
        
        return @{
            Success = $true
            CurrentHostname = $currentHostname
            RequiredHostname = $RequiredHostname
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Test-UsernameRequirement {
    param($RequiredUsername)
    
    try {
        $currentUsername = $env:USERNAME
        
        $match = $false
        if ($RequiredUsername -like "*\*") {
            # Domain\Username format
            $fullUsername = "$env:USERDOMAIN\$env:USERNAME"
            $match = $fullUsername -eq $RequiredUsername
        } else {
            # Just username
            $match = $currentUsername -eq $RequiredUsername
        }
        
        return @{
            Success = $true
            CurrentUsername = $currentUsername
            RequiredUsername = $RequiredUsername
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Test-ProcessRequirement {
    param($RequiredProcess)
    
    try {
        $runningProcesses = Get-Process | Select-Object -ExpandProperty Name -Unique
        
        $match = $false
        if ($RequiredProcess -contains ",") {
            # Multiple processes (ANY match)
            $requiredList = $RequiredProcess -split "," | ForEach-Object { $_.Trim() }
            foreach ($proc in $requiredList) {
                if ($runningProcesses -contains $proc) {
                    $match = $true
                    break
                }
            }
        } else {
            # Single process
            $match = $runningProcesses -contains $RequiredProcess
        }
        
        return @{
            Success = $true
            RunningProcesses = $runningProcesses.Count
            RequiredProcess = $RequiredProcess
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Test-EnvironmentKey {
    param($EnvKey, $EnvValue)
    
    try {
        $currentValue = [Environment]::GetEnvironmentVariable($EnvKey)
        
        $match = $false
        if ($currentValue) {
            if ($EnvValue -like "*") {
                # Just check if exists
                $match = $true
            } else {
                # Check value
                $match = $currentValue -eq $EnvValue
            }
        }
        
        return @{
            Success = $true
            Key = $EnvKey
            CurrentValue = $currentValue
            RequiredValue = $EnvValue
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Invoke-GuardrailAction {
    param($Action, $Reason)
    
    switch ($Action) {
        "exit" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Environment check failed: $Reason" -ForegroundColor Red
            }
            exit 2
        }
        "sleep" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Environment check failed, sleeping..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3600
            exit 2
        }
        "continue" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Environment check failed, continuing anyway" -ForegroundColor Yellow
            }
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1480.001A"
        TechniqueName = "Environment Keying"
        Results = @{
            InitialPrivilege = ""
            ChecksPassed = 0
            ChecksFailed = 0
            EnvironmentChecks = @{}
            ExecutionAllowed = $false
            FailureReason = ""
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
    
    # Store silent mode globally for guardrail action
    $Global:SilentMode = $Config.SilentMode
    
    # Validate action on fail
    if ($Config.ActionOnFail -notin @("exit", "sleep", "continue")) {
        $Config.ActionOnFail = "exit"
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
        Write-Host "[INFO] Checking environment guardrails..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Check environment requirements
    $allChecksPassed = $true
    
    # Check domain requirement
    if ($Config.RequiredDomain) {
        $domainCheck = Test-DomainRequirement -RequiredDomain $Config.RequiredDomain
        $Config.Results.EnvironmentChecks.Domain = $domainCheck
        
        if ($domainCheck.Match) {
            $Config.Results.ChecksPassed++
        } else {
            $Config.Results.ChecksFailed++
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Domain mismatch"
        }
    }
    
    # Check hostname requirement
    if ($Config.RequiredHostname) {
        $hostnameCheck = Test-HostnameRequirement -RequiredHostname $Config.RequiredHostname
        $Config.Results.EnvironmentChecks.Hostname = $hostnameCheck
        
        if ($hostnameCheck.Match) {
            $Config.Results.ChecksPassed++
        } else {
            $Config.Results.ChecksFailed++
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Hostname mismatch"
        }
    }
    
    # Check username requirement
    if ($Config.RequiredUsername) {
        $usernameCheck = Test-UsernameRequirement -RequiredUsername $Config.RequiredUsername
        $Config.Results.EnvironmentChecks.Username = $usernameCheck
        
        if ($usernameCheck.Match) {
            $Config.Results.ChecksPassed++
        } else {
            $Config.Results.ChecksFailed++
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Username mismatch"
        }
    }
    
    # Check process requirement
    if ($Config.RequiredProcess) {
        $processCheck = Test-ProcessRequirement -RequiredProcess $Config.RequiredProcess
        $Config.Results.EnvironmentChecks.Process = $processCheck
        
        if ($processCheck.Match) {
            $Config.Results.ChecksPassed++
        } else {
            $Config.Results.ChecksFailed++
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Required process not running"
        }
    }
    
    # Check for custom environment variables
    Get-ChildItem env: | Where-Object { $_.Name -like "T1480_001A_ENV_*" } | ForEach-Object {
        $envKey = $_.Name -replace "T1480_001A_ENV_", ""
        $envValue = $_.Value
        
        $envCheck = Test-EnvironmentKey -EnvKey $envKey -EnvValue $envValue
        $Config.Results.EnvironmentChecks."Env_$envKey" = $envCheck
        
        if ($envCheck.Match) {
            $Config.Results.ChecksPassed++
        } else {
            $Config.Results.ChecksFailed++
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Environment variable mismatch: $envKey"
        }
    }
    
    $Config.Results.ExecutionAllowed = $allChecksPassed
    
    if (-not $Config.SilentMode) {
        if ($allChecksPassed) {
            Write-Host "[SUCCESS] All environment checks passed" -ForegroundColor Green
            Write-Host "    Execution is allowed in this environment" -ForegroundColor Green
        } else {
            Write-Host "[FAILED] Environment checks failed" -ForegroundColor Red
            Write-Host "    Reason: $($Config.Results.FailureReason)" -ForegroundColor Red
        }
    }
    
    # Take action if checks failed
    if (-not $allChecksPassed) {
        Invoke-GuardrailAction -Action $Config.ActionOnFail -Reason $Config.Results.FailureReason
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1480.001a_env_keying_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Environment Keying Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Checks Passed: $($Config.Results.ChecksPassed)"
            Write-Host "    Checks Failed: $($Config.Results.ChecksFailed)"
            Write-Host "    Execution Allowed: $($Config.Results.ExecutionAllowed)"
            if (-not $Config.Results.ExecutionAllowed) {
                Write-Host "    Failure Reason: $($Config.Results.FailureReason)"
                Write-Host "    Action Taken: $($Config.ActionOnFail)"
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
                    RequiredDomain = $Config.RequiredDomain
                    RequiredHostname = $Config.RequiredHostname
                    RequiredUsername = $Config.RequiredUsername
                    RequiredProcess = $Config.RequiredProcess
                    ActionOnFail = $Config.ActionOnFail
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    Domain = $env:USERDNSDOMAIN
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1480_001a_env_keying.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }
        
        "stealth" {
            # Silent operation
        }
    }
}

function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED/GUARDRAIL
    
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
    if ($Config.Results.ExecutionAllowed) {
        exit 0
    } else {
        # Note: If action is "exit" or "sleep", we won't reach here
        exit 2
    }
}

# Execute main function
Main

