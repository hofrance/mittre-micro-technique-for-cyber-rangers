# MITRE ATT&CK T1140.001C - PowerShell Deobfuscation
# Implements PowerShell deobfuscation techniques

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:T1140_001C_OUTPUT_BASE) { $env:T1140_001C_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1140_001C_TIMEOUT) { [int]$env:T1140_001C_TIMEOUT } else { 30 }
        "DEBUG_MODE" = $env:T1140_001C_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1140_001C_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1140_001C_VERBOSE_LEVEL) { [int]$env:T1140_001C_VERBOSE_LEVEL } else { 1 }
        "OBFUSCATED_SCRIPT" = if ($env:T1140_001C_OBFUSCATED_SCRIPT) { $env:T1140_001C_OBFUSCATED_SCRIPT } else { "`$x=``'Hello``'; `$y=``'World``'; Write-Host (```"`$x `$y```")" }
        "DEOBFUSCATION_METHODS" = if ($env:T1140_001C_DEOBFUSCATION_METHODS) { $env:T1140_001C_DEOBFUSCATION_METHODS } else { "string_replacement,variable_substitution,command_execution" }
    }
}

function Create-ObfuscatedScript {
    param([hashtable]$Config)

    try {
        # Create an obfuscated PowerShell script
        $obfuscatedScript = @"
# Obfuscated PowerShell Script
`$x = [Convert]::FromBase64String('SGVsbG8gV29ybGQ='); 
`$y = [System.Text.Encoding]::UTF8.GetString(`$x);
Write-Host `$y
"@

        # Save the obfuscated script to a file
        $scriptPath = Join-Path $Config.OUTPUT_BASE "obfuscated_script.ps1"
        $obfuscatedScript | Out-File -FilePath $scriptPath -Encoding UTF8

        return @{
            Success = $true
            Error = $null
            ObfuscatedScriptPath = $scriptPath
            ObfuscatedScript = $obfuscatedScript
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            ObfuscatedScriptPath = $null
            ObfuscatedScript = $null
        }
    }
}

function Deobfuscate-PowerShell {
    param([string]$ObfuscatedScript, [string]$Methods, [hashtable]$Config)

    try {
        $deobfuscationSteps = @()
        $currentScript = $ObfuscatedScript

        $methodList = $Methods -split ',' | ForEach-Object { $_.Trim() }

        foreach ($method in $methodList) {
            switch ($method) {
                "string_replacement" {
                    # Replace obfuscated strings
                    $originalScript = $currentScript
                    $currentScript = $currentScript -replace '\[Convert\]::FromBase64String\(''([^'']+)''\)', {
                        param($match)
                        $base64String = $match.Groups[1].Value
                        $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64String))
                        "'$decoded'"
                    }

                    $deobfuscationSteps += @{
                        Method = "string_replacement"
                        Description = "Replaced Base64 encoded strings"
                        OriginalSnippet = $originalScript
                        DeobfuscatedSnippet = $currentScript
                    }
                }

                "variable_substitution" {
                    # Substitute variables with their values
                    $originalScript = $currentScript
                    $currentScript = $currentScript -replace '\$x = ([^;]+);', '// Variable substitution'

                    $deobfuscationSteps += @{
                        Method = "variable_substitution"
                        Description = "Performed variable substitution"
                        OriginalSnippet = $originalScript
                        DeobfuscatedSnippet = $currentScript
                    }
                }

                "command_execution" {
                    # Execute and capture the deobfuscated command
                    $originalScript = $currentScript
                    try {
                        $executionResult = Invoke-Expression $currentScript 2>&1
                        $deobfuscationSteps += @{
                            Method = "command_execution"
                            Description = "Executed deobfuscated command"
                            OriginalSnippet = $originalScript
                            ExecutionResult = $executionResult.ToString()
                        }
                    } catch {
                        $deobfuscationSteps += @{
                            Method = "command_execution"
                            Description = "Command execution failed"
                            OriginalSnippet = $originalScript
                            ExecutionResult = $_.Exception.Message
                        }
                    }
                }
            }

            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
                Write-Host "[INFO] Applied deobfuscation method: $method" -ForegroundColor Cyan
            }
        }

        # Create a deobfuscated script file
        $deobfuscatedPath = Join-Path $Config.OUTPUT_BASE "deobfuscated_script.ps1"
        $currentScript | Out-File -FilePath $deobfuscatedPath -Encoding UTF8

        return @{
            Success = $true
            Error = $null
            OriginalScript = $ObfuscatedScript
            DeobfuscatedScript = $currentScript
            DeobfuscatedScriptPath = $deobfuscatedPath
            DeobfuscationSteps = $deobfuscationSteps
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            OriginalScript = $ObfuscatedScript
            DeobfuscatedScript = $null
            DeobfuscatedScriptPath = $null
            DeobfuscationSteps = $null
        }
    }
}

function Invoke-PowerShellDeobfuscation {
    param([hashtable]$Config)

    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
        Write-Host "[INFO] Starting PowerShell deobfuscation technique..." -ForegroundColor Yellow
    }

    $results = @{
        "action" = "powershell_deobfuscation"
        "technique_id" = "T1140.001C"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = "user"
        "results" = @{}
        "postconditions" = @{}
    }

    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1140_001c_powershell_deobfuscation"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Step 1: Create obfuscated script
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Creating obfuscated PowerShell script..." -ForegroundColor Cyan
        }

        $obfuscatedResult = Create-ObfuscatedScript -Config $Config

        if (-not $obfuscatedResult.Success) {
            throw "Failed to create obfuscated script: $($obfuscatedResult.Error)"
        }

        # Step 2: Deobfuscate the script
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[INFO] Deobfuscating PowerShell script..." -ForegroundColor Cyan
        }

        $deobfuscationResult = Deobfuscate-PowerShell -ObfuscatedScript $obfuscatedResult.ObfuscatedScript -Methods $Config.DEOBFUSCATION_METHODS -Config $Config

        if (-not $deobfuscationResult.Success) {
            throw "Failed to deobfuscate script: $($deobfuscationResult.Error)"
        }

        $results.results = @{
            "status" = "success"
            "action_performed" = "powershell_deobfuscation"
            "output_directory" = $outputDir
            "obfuscated_script_path" = $obfuscatedResult.ObfuscatedScriptPath
            "deobfuscated_script_path" = $deobfuscationResult.DeobfuscatedScriptPath
            "deobfuscation_methods_used" = $Config.DEOBFUSCATION_METHODS
            "deobfuscation_steps" = $deobfuscationResult.DeobfuscationSteps
            "original_script_length" = $obfuscatedResult.ObfuscatedScript.Length
            "deobfuscated_script_length" = $deobfuscationResult.DeobfuscatedScript.Length
            "technique_demonstrated" = "PowerShell script deobfuscation using multiple methods"

        }

        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "script_deobfuscated" = $true
            "files_created" = $true
            "technique_demonstration_successful" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[SUCCESS] PowerShell deobfuscation completed successfully" -ForegroundColor Green
        }

    } catch {
        $results.results = @{
            "status" = "error"
            "error_message" = $_.Exception.Message
            "action_performed" = "powershell_deobfuscation"
        }

        $results.postconditions = @{
            "action_completed" = $false
            "error_occurred" = $true
        }

        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE) {
            Write-Host "[ERROR] PowerShell deobfuscation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $results
}

# Main execution
$config = Get-Configuration
$results = Invoke-PowerShellDeobfuscation -Config $config

# Output results
if ($results.results.status -eq "success") {
    Write-Host "T1140.001C POWERSHELL DEOBFUSCATION RESULTS ===" -ForegroundColor Green
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Action: $($results.results.action_performed)" -ForegroundColor Cyan
    Write-Host "Deobfuscation Methods: $($results.results.deobfuscation_methods_used)" -ForegroundColor Yellow
    Write-Host "Deobfuscation Steps: $($results.results.deobfuscation_steps.Count)" -ForegroundColor Magenta
    Write-Host "Original Script Length: $($results.results.original_script_length)" -ForegroundColor Blue
    Write-Host "Deobfuscated Script Length: $($results.results.deobfuscated_script_length)" -ForegroundColor Cyan
    Write-Host "Technique Demonstrated: $($results.results.technique_demonstrated)" -ForegroundColor Cyan

} else {
    Write-Host "T1140.001C POWERSHELL DEOBFUSCATION FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($results.results.status)" -ForegroundColor Red
    Write-Host "Error: $($results.results.error_message)" -ForegroundColor Red
}
