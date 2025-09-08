# T1480.001C - Time Based Execution
# MITRE ATT&CK Technique: T1480 - Execution Guardrails
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # PowerShell datetime support
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        StartTime = if ($env:T1480_001C_START_TIME) { $env:T1480_001C_START_TIME } else { "" }
        EndTime = if ($env:T1480_001C_END_TIME) { $env:T1480_001C_END_TIME } else { "" }
        DaysOfWeek = if ($env:T1480_001C_DAYS_OF_WEEK) { $env:T1480_001C_DAYS_OF_WEEK } else { "" }
        DateRange = if ($env:T1480_001C_DATE_RANGE) { $env:T1480_001C_DATE_RANGE } else { "" }
        Timezone = if ($env:T1480_001C_TIMEZONE) { $env:T1480_001C_TIMEZONE } else { "" }
        ActionOnFail = if ($env:T1480_001C_ACTION_ON_FAIL) { $env:T1480_001C_ACTION_ON_FAIL } else { "exit" }
        OutputMode = if ($env:T1480_001C_OUTPUT_MODE) { $env:T1480_001C_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1480_001C_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Test-TimeWindow {
    param($StartTime, $EndTime)
    
    try {
        $currentTime = Get-Date
        $currentTimeOnly = $currentTime.ToString("HH:mm")
        
        # Parse time strings
        $start = [DateTime]::ParseExact($StartTime, "HH:mm", $null)
        $end = [DateTime]::ParseExact($EndTime, "HH:mm", $null)
        $current = [DateTime]::ParseExact($currentTimeOnly, "HH:mm", $null)
        
        # Handle overnight windows
        if ($end -lt $start) {
            # Window crosses midnight
            $inWindow = ($current -ge $start) -or ($current -le $end)
        } else {
            # Normal window
            $inWindow = ($current -ge $start) -and ($current -le $end)
        }
        
        return @{
            Success = $true
            CurrentTime = $currentTimeOnly
            StartTime = $StartTime
            EndTime = $EndTime
            InWindow = $inWindow
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            InWindow = $false
        }
    }
}

function Test-DayOfWeek {
    param($AllowedDays)
    
    try {
        $currentDay = (Get-Date).DayOfWeek.ToString()
        $dayList = $AllowedDays -split "," | ForEach-Object { $_.Trim() }
        
        # Support abbreviated days
        $dayMappings = @{
            "Mon" = "Monday"
            "Tue" = "Tuesday"
            "Wed" = "Wednesday"
            "Thu" = "Thursday"
            "Fri" = "Friday"
            "Sat" = "Saturday"
            "Sun" = "Sunday"
        }
        
        $allowed = $false
        foreach ($day in $dayList) {
            $fullDay = if ($dayMappings.ContainsKey($day)) { $dayMappings[$day] } else { $day }
            if ($currentDay -eq $fullDay) {
                $allowed = $true
                break
            }
        }
        
        # Check for weekday/weekend keywords
        if ($AllowedDays -eq "Weekdays") {
            $allowed = $currentDay -in @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
        }
        elseif ($AllowedDays -eq "Weekend") {
            $allowed = $currentDay -in @("Saturday", "Sunday")
        }
        
        return @{
            Success = $true
            CurrentDay = $currentDay
            AllowedDays = $AllowedDays
            IsAllowed = $allowed
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            IsAllowed = $false
        }
    }
}

function Test-DateRange {
    param($DateRange)
    
    try {
        $currentDate = Get-Date
        
        # Parse date range (format: YYYY-MM-DD:YYYY-MM-DD)
        $dates = $DateRange -split ":"
        if ($dates.Count -ne 2) {
            throw "Invalid date range format"
        }
        
        $startDate = [DateTime]::ParseExact($dates[0].Trim(), "yyyy-MM-dd", $null)
        $endDate = [DateTime]::ParseExact($dates[1].Trim(), "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)
        
        $inRange = ($currentDate -ge $startDate) -and ($currentDate -le $endDate)
        
        return @{
            Success = $true
            CurrentDate = $currentDate.ToString("yyyy-MM-dd")
            StartDate = $startDate.ToString("yyyy-MM-dd")
            EndDate = $endDate.ToString("yyyy-MM-dd")
            InRange = $inRange
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

function Test-Timezone {
    param($RequiredTimezone)
    
    try {
        $currentTimezone = [System.TimeZoneInfo]::Local
        
        # Match by ID or display name
        $match = ($currentTimezone.Id -eq $RequiredTimezone) -or
                 ($currentTimezone.DisplayName -like "*$RequiredTimezone*") -or
                 ($currentTimezone.StandardName -eq $RequiredTimezone)
        
        # Also check UTC offset format (e.g., "UTC+5", "UTC-8")
        if ($RequiredTimezone -match "^UTC([+-]\d+)$") {
            $offset = [int]$matches[1]
            $currentOffset = $currentTimezone.BaseUtcOffset.Hours
            $match = $currentOffset -eq $offset
        }
        
        return @{
            Success = $true
            CurrentTimezone = $currentTimezone.DisplayName
            CurrentId = $currentTimezone.Id
            RequiredTimezone = $RequiredTimezone
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

function Get-SleepDuration {
    param($StartTime, $EndTime)
    
    try {
        $now = Get-Date
        $today = $now.Date
        
        # Parse start time for today
        $startDateTime = $today.AddHours([int]$StartTime.Split(':')[0]).AddMinutes([int]$StartTime.Split(':')[1])
        
        # If start time has passed today, use tomorrow
        if ($startDateTime -lt $now) {
            $startDateTime = $startDateTime.AddDays(1)
        }
        
        $sleepSeconds = ($startDateTime - $now).TotalSeconds
        return [int]$sleepSeconds
    }
    catch {
        return 3600  # Default 1 hour
    }
}

function Invoke-GuardrailAction {
    param($Action, $Reason, $Config)
    
    switch ($Action) {
        "exit" {
            if (-not $Config.SilentMode) {
                Write-Host "[GUARDRAIL] Time validation failed: $Reason" -ForegroundColor Red
            }
            exit 2
        }
        "sleep" {
            if (-not $Config.SilentMode) {
                Write-Host "[GUARDRAIL] Time validation failed: $Reason" -ForegroundColor Yellow
            }
            
            # Calculate sleep duration
            $sleepSeconds = 3600
            if ($Config.StartTime) {
                $sleepSeconds = Get-SleepDuration -StartTime $Config.StartTime -EndTime $Config.EndTime
                if (-not $Config.SilentMode) {
                    Write-Host "[GUARDRAIL] Sleeping for $sleepSeconds seconds until next window..." -ForegroundColor Yellow
                }
            }
            
            Start-Sleep -Seconds $sleepSeconds
            exit 2
        }
        "wait" {
            if (-not $Config.SilentMode) {
                Write-Host "[GUARDRAIL] Time validation failed: $Reason" -ForegroundColor Yellow
                Write-Host "[GUARDRAIL] Waiting for valid time window..." -ForegroundColor Yellow
            }
            
            # Loop until time window is valid
            while ($true) {
                Start-Sleep -Seconds 60
                
                # Re-check time conditions
                $valid = $true
                if ($Config.StartTime -and $Config.EndTime) {
                    $check = Test-TimeWindow -StartTime $Config.StartTime -EndTime $Config.EndTime
                    if (-not $check.InWindow) {
                        $valid = $false
                    }
                }
                
                if ($valid) {
                    if (-not $Config.SilentMode) {
                        Write-Host "[GUARDRAIL] Time window now valid, continuing..." -ForegroundColor Green
                    }
                    break
                }
            }
        }
        "continue" {
            if (-not $Config.SilentMode) {
                Write-Host "[GUARDRAIL] Time validation failed, continuing anyway" -ForegroundColor Yellow
            }
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1480.001C"
        TechniqueName = "Time Based Execution"
        Results = @{
            InitialPrivilege = ""
            TimeChecks = @{}
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
    
    # Validate action on fail
    if ($Config.ActionOnFail -notin @("exit", "sleep", "wait", "continue")) {
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
        Write-Host "[INFO] Checking time-based execution guardrails..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Check time conditions
    $allChecksPassed = $true
    
    # Check time window
    if ($Config.StartTime -and $Config.EndTime) {
        $timeCheck = Test-TimeWindow -StartTime $Config.StartTime -EndTime $Config.EndTime
        $Config.Results.TimeChecks.TimeWindow = $timeCheck
        
        if (-not $timeCheck.InWindow) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Outside allowed time window"
        }
    }
    
    # Check day of week
    if ($Config.DaysOfWeek) {
        $dayCheck = Test-DayOfWeek -AllowedDays $Config.DaysOfWeek
        $Config.Results.TimeChecks.DayOfWeek = $dayCheck
        
        if (-not $dayCheck.IsAllowed) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Not an allowed day"
        }
    }
    
    # Check date range
    if ($Config.DateRange) {
        $dateCheck = Test-DateRange -DateRange $Config.DateRange
        $Config.Results.TimeChecks.DateRange = $dateCheck
        
        if (-not $dateCheck.InRange) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Outside allowed date range"
        }
    }
    
    # Check timezone
    if ($Config.Timezone) {
        $tzCheck = Test-Timezone -RequiredTimezone $Config.Timezone
        $Config.Results.TimeChecks.Timezone = $tzCheck
        
        if (-not $tzCheck.Match) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Wrong timezone"
        }
    }
    
    $Config.Results.ExecutionAllowed = $allChecksPassed
    
    if (-not $Config.SilentMode) {
        if ($allChecksPassed) {
            Write-Host "[SUCCESS] All time checks passed" -ForegroundColor Green
            Write-Host "    Execution is allowed at this time" -ForegroundColor Green
        } else {
            Write-Host "[FAILED] Time checks failed" -ForegroundColor Red
            Write-Host "    Reason: $($Config.Results.FailureReason)" -ForegroundColor Red
        }
    }
    
    # Take action if checks failed
    if (-not $allChecksPassed) {
        Invoke-GuardrailAction -Action $Config.ActionOnFail -Reason $Config.Results.FailureReason -Config $Config
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1480.001c_time_based_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Time Based Execution Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            
            foreach ($check in $Config.Results.TimeChecks.Keys) {
                $result = $Config.Results.TimeChecks[$check]
                if ($result.Success) {
                    Write-Host "    $check : " -NoNewline
                    
                    switch ($check) {
                        "TimeWindow" { 
                            Write-Host "$($result.InWindow) (Current: $($result.CurrentTime), Window: $($result.StartTime)-$($result.EndTime))"
                        }
                        "DayOfWeek" { 
                            Write-Host "$($result.IsAllowed) (Current: $($result.CurrentDay), Allowed: $($result.AllowedDays))"
                        }
                        "DateRange" { 
                            Write-Host "$($result.InRange) (Current: $($result.CurrentDate), Range: $($result.StartDate) to $($result.EndDate))"
                        }
                        "Timezone" { 
                            Write-Host "$($result.Match) (Current: $($result.CurrentId), Required: $($result.RequiredTimezone))"
                        }
                    }
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
                    StartTime = $Config.StartTime
                    EndTime = $Config.EndTime
                    DaysOfWeek = $Config.DaysOfWeek
                    DateRange = $Config.DateRange
                    Timezone = $Config.Timezone
                    ActionOnFail = $Config.ActionOnFail
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Timezone = [System.TimeZoneInfo]::Local.DisplayName
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1480_001c_time_based.json"
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
        # Note: If action is "exit", "sleep", or "wait", we might not reach here
        exit 2
    }
}

# Execute main function
Main

