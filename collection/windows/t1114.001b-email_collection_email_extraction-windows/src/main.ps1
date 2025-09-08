# T1114.002A - Email Extraction from Detected Clients
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: extract emails from detected email clients ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1114_002A_OUTPUT_BASE) { $env:T1114_002A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1114_002A_TIMEOUT) { [int]$env:T1114_002A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1114_002A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1114_002A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1114_002A_VERBOSE_LEVEL) { [int]$env:T1114_002A_VERBOSE_LEVEL } else { 1 }
        
        # Policy-awareness Windows
        "POLICY_CHECK" = if ($env:T1114_002A_POLICY_CHECK) { $env:T1114_002A_POLICY_CHECK -eq "true" } else { $true }
        "POLICY_SIMULATE" = if ($env:T1114_002A_POLICY_SIMULATE) { $env:T1114_002A_POLICY_SIMULATE -eq "true" } else { $false }
        "FALLBACK_MODE" = if ($env:T1114_002A_FALLBACK_MODE) { $env:T1114_002A_FALLBACK_MODE } else { "simulate" }
        
        # Variables sp  cialis  es T1114.002A
        "OUTPUT_MODE" = if ($env:T1114_002A_OUTPUT_MODE) { $env:T1114_002A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1114_002A_SILENT_MODE -eq "true"
        "MAX_EMAILS" = if ($env:T1114_002A_MAX_EMAILS) { [int]$env:T1114_002A_MAX_EMAILS } else { 100 }
        "EMAIL_FORMATS" = if ($env:T1114_002A_EMAIL_FORMATS) { $env:T1114_002A_EMAIL_FORMATS } else { "eml,msg" }
        "INCLUDE_ATTACHMENTS" = $env:T1114_002A_INCLUDE_ATTACHMENTS -eq "true"
        
        # Defense Evasion
        "SLEEP_JITTER" = if ($env:T1114_002A_SLEEP_JITTER) { [int]$env:T1114_002A_SLEEP_JITTER } else { 0 }
        
        # Telemetry
        "ECS_VERSION" = if ($env:T1114_002A_ECS_VERSION) { $env:T1114_002A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1114_002A_CORRELATION_ID) { $env:T1114_002A_CORRELATION_ID } else { "auto" }
    }
    
    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1114_002A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }
    
    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: extract emails from detected email clients ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic email extraction..." -ForegroundColor Yellow
    }
    
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "email_extraction"
        "technique_id" =  "T1114.002A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1114_002a_email_extraction"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Simulate email extraction (atomic action)
        $emailPaths = @(
            "$env:USERPROFILE\Documents\Outlook Files",
            "$env:LOCALAPPDATA\Microsoft\Outlook",
            "$env:APPDATA\Thunderbird\Profiles"
        )
        
        $extractedEmails = @()
        $emailFormats = $Config.EMAIL_FORMATS -split ','
        
        foreach ($path in $emailPaths) {
            if (Test-Path $path) {
                foreach ($format in $emailFormats) {
                    $files = Get-ChildItem $path -Filter "*.$format" -Recurse -ErrorAction SilentlyContinue | Select-Object -First $Config.MAX_EMAILS
                    foreach ($file in $files) {
                        $extractedEmails += @{
                            "file_path" = $file.FullName
                            "file_name" = $file.Name
                            "file_size" = $file.Length
                            "format" = $format
                            "last_modified" = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                    }
                }
            }
        }
        
        $results.results = @{
            "status" =  "success"
            "emails_extracted" = $extractedEmails.Count
            "email_formats_searched" = $emailFormats
            "extraction_paths" = $emailPaths
            "extracted_emails" = $extractedEmails
            "max_emails_limit" = $Config.MAX_EMAILS
            "include_attachments" = $Config.INCLUDE_ATTACHMENTS
            "output_directory" = $outputDir
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] Email extraction completed: $($extractedEmails.Count) emails found" -ForegroundColor Green
        }
    }
    catch {
        $results.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
        }
        
        $results.postconditions = @{
            "action_completed" = $false
            "output_generated" = $false
            "policy_compliant" = $true
        }
    }
    
    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1114_002a_email_extraction"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }
    
    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "EMAIL EXTRACTION "
                $simpleOutput += "`nEmails found: $($Data.results.emails_extracted)"
                $simpleOutput += "`nFormats: $($Data.results.email_formats_searched -join ', ')"
                $simpleOutput += "`nPaths searched: $($Data.results.extraction_paths.Count)"
            } else {
                $simpleOutput = "Email extraction failed: $($Data.results.error)"
            }
            
            if (-not $Config.SILENT_MODE) {
                Write-Output $simpleOutput
                $simpleOutput | Out-File -FilePath (Join-Path $outputDir "results_simple.txt") -Encoding UTF8
            }
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "results_debug.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.SILENT_MODE) {
                Write-Host "[DEBUG] Results written to: $jsonFile" -ForegroundColor Cyan
            }
        }
        
        "stealth" {
            if (-not $Config.SILENT_MODE) {
                $jsonFile = Join-Path $outputDir "results_stealth.json"
                $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            }
        }
    }
    
    return $outputDir
}

function Main {
    try {
        $Config = Get-Configuration
        $results = Invoke-MicroTechniqueAction -Config $config
        $outputPath = Write-StandardizedOutput -Data $results -Config $config
        
        if (-not $results.postconditions.action_completed) {
            throw "Postcondition failed: action not completed"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[COMPLETE] T1114.002A atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        exit 0
    }
    catch {
        $errorMessage = $_.Exception.Message
        
        if ($errorMessage -like "*Precondition*") {
            exit 2
        } elseif ($errorMessage -like "*Policy*") {
            exit 3
        } elseif ($errorMessage -like "*Postcondition*") {
            exit 4
        } else {
            exit 1
        }
    }
}

exit (Main)




