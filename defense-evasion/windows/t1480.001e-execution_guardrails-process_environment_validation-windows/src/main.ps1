# T1480.001E - Process Environment Validation
# MITRE ATT&CK Technique: T1480 - Execution Guardrails
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # PowerShell process management
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        RequiredProcesses = if ($env:T1480_001E_REQUIRED_PROCESSES) { $env:T1480_001E_REQUIRED_PROCESSES } else { "" }
        ForbiddenProcesses = if ($env:T1480_001E_FORBIDDEN_PROCESSES) { $env:T1480_001E_FORBIDDEN_PROCESSES } else { "" }
        RequiredServices = if ($env:T1480_001E_REQUIRED_SERVICES) { $env:T1480_001E_REQUIRED_SERVICES } else { "" }
        MinProcessCount = if ($env:T1480_001E_MIN_PROCESS_COUNT) { [int]$env:T1480_001E_MIN_PROCESS_COUNT } else { 0 }
        MaxProcessCount = if ($env:T1480_001E_MAX_PROCESS_COUNT) { [int]$env:T1480_001E_MAX_PROCESS_COUNT } else { 0 }
        ParentProcess = if ($env:T1480_001E_PARENT_PROCESS) { $env:T1480_001E_PARENT_PROCESS } else { "" }
        ActionOnFail = if ($env:T1480_001E_ACTION_ON_FAIL) { $env:T1480_001E_ACTION_ON_FAIL } else { "exit" }
        OutputMode = if ($env:T1480_001E_OUTPUT_MODE) { $env:T1480_001E_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1480_001E_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Test-RequiredProcesses {
    param($RequiredList)
    
    try {
        $requiredProcesses = $RequiredList -split "," | ForEach-Object { $_.Trim() }
        $runningProcesses = Get-Process | Select-Object -ExpandProperty Name -Unique
        
        $results = @()
        $allFound = $true
        
        foreach ($required in $requiredProcesses) {
            $found = $false
            
            # Support wildcards
            if ($required -like "*%*") {
                $pattern = $required -replace "%", "*"
                $found = $runningProcesses | Where-Object { $_ -like $pattern }
            } else {
                $found = $runningProcesses -contains $required
            }
            
            $results += @{
                Process = $required
                Found = [bool]$found
            }
            
            if (-not $found) {
                $allFound = $false
            }
        }
        
        return @{
            Success = $true
            RequiredProcesses = $requiredProcesses
            Results = $results
            AllFound = $allFound
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            AllFound = $false
        }
    }
}

function Test-ForbiddenProcesses {
    param($ForbiddenList)
    
    try {
        $forbiddenProcesses = $ForbiddenList -split "," | ForEach-Object { $_.Trim() }
        $runningProcesses = Get-Process | Select-Object -ExpandProperty Name -Unique
        
        $results = @()
        $noneFound = $true
        
        foreach ($forbidden in $forbiddenProcesses) {
            $found = $false
            
            # Support wildcards
            if ($forbidden -like "*%*") {
                $pattern = $forbidden -replace "%", "*"
                $found = $runningProcesses | Where-Object { $_ -like $pattern }
            } else {
                $found = $runningProcesses -contains $forbidden
            }
            
            $results += @{
                Process = $forbidden
                Found = [bool]$found
            }
            
            if ($found) {
                $noneFound = $false
            }
        }
        
        return @{
            Success = $true
            ForbiddenProcesses = $forbiddenProcesses
            Results = $results
            NoneFound = $noneFound
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            NoneFound = $false
        }
    }
}

function Test-RequiredServices {
    param($RequiredList)
    
    try {
        $requiredServices = $RequiredList -split "," | ForEach-Object { $_.Trim() }
        $runningServices = Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object -ExpandProperty Name
        
        $results = @()
        $allRunning = $true
        
        foreach ($required in $requiredServices) {
            $service = Get-Service -Name $required -ErrorAction SilentlyContinue
            
            if ($service) {
                $isRunning = $service.Status -eq 'Running'
                $results += @{
                    Service = $required
                    Exists = $true
                    Status = $service.Status
                    Running = $isRunning
                }
                
                if (-not $isRunning) {
                    $allRunning = $false
                }
            } else {
                $results += @{
                    Service = $required
                    Exists = $false
                    Status = "Not Found"
                    Running = $false
                }
                $allRunning = $false
            }
        }
        
        return @{
            Success = $true
            RequiredServices = $requiredServices
            Results = $results
            AllRunning = $allRunning
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            AllRunning = $false
        }
    }
}

function Test-ProcessCount {
    param($MinCount, $MaxCount)
    
    try {
        $processCount = (Get-Process).Count
        
        $inRange = $true
        $reason = ""
        
        if ($MinCount -gt 0 -and $processCount -lt $MinCount) {
            $inRange = $false
            $reason = "Too few processes"
        }
        
        if ($MaxCount -gt 0 -and $processCount -gt $MaxCount) {
            $inRange = $false
            $reason = "Too many processes"
        }
        
        return @{
            Success = $true
            CurrentCount = $processCount
            MinCount = $MinCount
            MaxCount = $MaxCount
            InRange = $inRange
            Reason = $reason
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            InRange = $false
        }
    }
}

function Test-ParentProcess {
    param($RequiredParent)
    
    try {
        # Get current process parent
        $currentProcess = Get-Process -Id $PID
        $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $PID"
        $parentPID = $wmiProcess.ParentProcessId
        
        if ($parentPID) {
            $parentProcess = Get-Process -Id $parentPID -ErrorAction SilentlyContinue
            
            if ($parentProcess) {
                $match = $parentProcess.Name -eq $RequiredParent -or
                        $parentProcess.ProcessName -eq $RequiredParent
                
                return @{
                    Success = $true
                    CurrentProcess = $currentProcess.Name
                    ParentProcess = $parentProcess.Name
                    ParentPID = $parentPID
                    RequiredParent = $RequiredParent
                    Match = $match
                }
            }
        }
        
        return @{
            Success = $true
            CurrentProcess = $currentProcess.Name
            ParentProcess = "Unknown"
            ParentPID = $parentPID
            RequiredParent = $RequiredParent
            Match = $false
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

function Get-ProcessEnvironmentInfo {
    try {
        $info = @{
            ProcessCount = (Get-Process).Count
            ServiceCount = (Get-Service | Where-Object { $_.Status -eq 'Running' }).Count
            CurrentUser = $env:USERNAME
            SessionName = $env:SESSIONNAME
            ComputerName = $env:COMPUTERNAME
            ProcessorCount = $env:NUMBER_OF_PROCESSORS
            SystemRoot = $env:SystemRoot
        }
        
        # Get session type
        $sessionType = "Unknown"
        if ($env:SESSIONNAME -like "Console*") {
            $sessionType = "Console"
        } elseif ($env:SESSIONNAME -like "RDP*") {
            $sessionType = "RDP"
        } elseif (-not $env:SESSIONNAME) {
            $sessionType = "Service"
        }
        
        $info.SessionType = $sessionType
        
        return $info
    }
    catch {
        return @{}
    }
}

function Invoke-GuardrailAction {
    param($Action, $Reason)
    
    switch ($Action) {
        "exit" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Process environment validation failed: $Reason" -ForegroundColor Red
            }
            exit 2
        }
        "sleep" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Process environment validation failed, sleeping..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3600
            exit 2
        }
        "kill" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Process environment validation failed, terminating forbidden processes..." -ForegroundColor Red
            }
            # Note: This is for demonstration only
            exit 2
        }
        "continue" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Process environment validation failed, continuing anyway" -ForegroundColor Yellow
            }
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1480.001E"
        TechniqueName = "Process Environment Validation"
        Results = @{
            InitialPrivilege = ""
            EnvironmentInfo = @{}
            ValidationChecks = @{}
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
    
    # Store silent mode globally
    $Global:SilentMode = $Config.SilentMode
    
    # Validate action on fail
    if ($Config.ActionOnFail -notin @("exit", "sleep", "kill", "continue")) {
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
        Write-Host "[INFO] Validating process environment..." -ForegroundColor Yellow
    }
    
    # Get environment info
    $Config.Results.EnvironmentInfo = Get-ProcessEnvironmentInfo
    
    # ATOMIC ACTION: Validate process environment
    $allChecksPassed = $true
    
    # Check required processes
    if ($Config.RequiredProcesses) {
        $processCheck = Test-RequiredProcesses -RequiredList $Config.RequiredProcesses
        $Config.Results.ValidationChecks.RequiredProcesses = $processCheck
        
        if (-not $processCheck.AllFound) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Required processes not found"
        }
    }
    
    # Check forbidden processes
    if ($Config.ForbiddenProcesses) {
        $forbiddenCheck = Test-ForbiddenProcesses -ForbiddenList $Config.ForbiddenProcesses
        $Config.Results.ValidationChecks.ForbiddenProcesses = $forbiddenCheck
        
        if (-not $forbiddenCheck.NoneFound) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Forbidden processes detected"
            
            # List detected forbidden processes
            $detected = $forbiddenCheck.Results | Where-Object { $_.Found } | ForEach-Object { $_.Process }
            if ($detected) {
                $Config.Results.FailureReason += ": $($detected -join ', ')"
            }
        }
    }
    
    # Check required services
    if ($Config.RequiredServices) {
        $serviceCheck = Test-RequiredServices -RequiredList $Config.RequiredServices
        $Config.Results.ValidationChecks.RequiredServices = $serviceCheck
        
        if (-not $serviceCheck.AllRunning) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Required services not running"
        }
    }
    
    # Check process count
    if ($Config.MinProcessCount -gt 0 -or $Config.MaxProcessCount -gt 0) {
        $countCheck = Test-ProcessCount -MinCount $Config.MinProcessCount -MaxCount $Config.MaxProcessCount
        $Config.Results.ValidationChecks.ProcessCount = $countCheck
        
        if (-not $countCheck.InRange) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = $countCheck.Reason
        }
    }
    
    # Check parent process
    if ($Config.ParentProcess) {
        $parentCheck = Test-ParentProcess -RequiredParent $Config.ParentProcess
        $Config.Results.ValidationChecks.ParentProcess = $parentCheck
        
        if (-not $parentCheck.Match) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Wrong parent process"
        }
    }
    
    $Config.Results.ExecutionAllowed = $allChecksPassed
    
    if (-not $Config.SilentMode) {
        if ($allChecksPassed) {
            Write-Host "[SUCCESS] All process environment checks passed" -ForegroundColor Green
            Write-Host "    Environment validated for execution" -ForegroundColor Green
        } else {
            Write-Host "[FAILED] Process environment validation failed" -ForegroundColor Red
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
    
    $outputDir = Join-Path $Config.OutputBase "T1480.001e_process_env_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Process Environment Validation Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Environment Info:"
            Write-Host "      Process Count: $($Config.Results.EnvironmentInfo.ProcessCount)"
            Write-Host "      Service Count: $($Config.Results.EnvironmentInfo.ServiceCount)"
            Write-Host "      Session Type: $($Config.Results.EnvironmentInfo.SessionType)"
            
            Write-Host "    Validation Checks:"
            foreach ($check in $Config.Results.ValidationChecks.Keys) {
                $result = $Config.Results.ValidationChecks[$check]
                Write-Host "      $check : " -NoNewline
                
                switch ($check) {
                    "RequiredProcesses" { Write-Host "$($result.AllFound)" }
                    "ForbiddenProcesses" { Write-Host "$($result.NoneFound)" }
                    "RequiredServices" { Write-Host "$($result.AllRunning)" }
                    "ProcessCount" { Write-Host "$($result.InRange) (Current: $($result.CurrentCount))" }
                    "ParentProcess" { Write-Host "$($result.Match) (Parent: $($result.ParentProcess))" }
                }
            }
            
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
                    RequiredProcesses = $Config.RequiredProcesses
                    ForbiddenProcesses = $Config.ForbiddenProcesses
                    RequiredServices = $Config.RequiredServices
                    MinProcessCount = $Config.MinProcessCount
                    MaxProcessCount = $Config.MaxProcessCount
                    ParentProcess = $Config.ParentProcess
                    ActionOnFail = $Config.ActionOnFail
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                    ProcessId = $PID
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1480_001e_process_env.json"
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
        # Note: If action is "exit", "sleep", or "kill", we won't reach here
        exit 2
    }
}

# Execute main function
Main

