# T1119.002A - Content-Based File Filtering
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: filter files based on content patterns ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1119_002A_OUTPUT_BASE) { $env:T1119_002A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1119_002A_TIMEOUT) { [int]$env:T1119_002A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1119_002A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1119_002A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1119_002A_VERBOSE_LEVEL) { [int]$env:T1119_002A_VERBOSE_LEVEL } else { 1 }
        
        # Policy-awareness Windows
        "POLICY_CHECK" = if ($env:T1119_002A_POLICY_CHECK) { $env:T1119_002A_POLICY_CHECK -eq "true" } else { $true }
        "POLICY_SIMULATE" = if ($env:T1119_002A_POLICY_SIMULATE) { $env:T1119_002A_POLICY_SIMULATE -eq "true" } else { $false }
        "FALLBACK_MODE" = if ($env:T1119_002A_FALLBACK_MODE) { $env:T1119_002A_FALLBACK_MODE } else { "simulate" }
        
        # Variables sp  cialis  es T1119.002A
        "OUTPUT_MODE" = if ($env:T1119_002A_OUTPUT_MODE) { $env:T1119_002A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1119_002A_SILENT_MODE -eq "true"
        "SEARCH_PATTERNS" = if ($env:T1119_002A_SEARCH_PATTERNS) { $env:T1119_002A_SEARCH_PATTERNS } else { "password,secret,key" }
        "FILE_EXTENSIONS" = if ($env:T1119_002A_FILE_EXTENSIONS) { $env:T1119_002A_FILE_EXTENSIONS } else { "txt,conf,ini,cfg" }
        "MAX_FILES" = if ($env:T1119_002A_MAX_FILES) { [int]$env:T1119_002A_MAX_FILES } else { 1000 }
        
        # Defense Evasion
        "SLEEP_JITTER" = if ($env:T1119_002A_SLEEP_JITTER) { [int]$env:T1119_002A_SLEEP_JITTER } else { 0 }
        
        # Telemetry
        "ECS_VERSION" = if ($env:T1119_002A_ECS_VERSION) { $env:T1119_002A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1119_002A_CORRELATION_ID) { $env:T1119_002A_CORRELATION_ID } else { "auto" }
    }
    
    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1119_002A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }
    
    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: filter files based on content patterns ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic content-based file filtering..." -ForegroundColor Yellow
    }
    
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "content_based_file_filtering"
        "technique_id" =  "T1119.002A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1119_002a_content_filtering"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Simulate content-based filtering (atomic action)
        $searchPatterns = $Config.SEARCH_PATTERNS -split ','
        $fileExtensions = $Config.FILE_EXTENSIONS -split ','
        
        $filteredFiles = @()
        $searchPaths = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop", "$env:TEMP")
        
        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                foreach ($ext in $fileExtensions) {
                    $files = Get-ChildItem $path -Filter "*.$ext" -Recurse -ErrorAction SilentlyContinue | Select-Object -First $Config.MAX_FILES
                    foreach ($file in $files) {
                        try {
                            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                            if ($content) {
                                foreach ($pattern in $searchPatterns) {
                                    if ($content -match $pattern) {
                                        $filteredFiles += @{
                                            "file_path" = $file.FullName
                                            "file_name" = $file.Name
                                            "file_size" = $file.Length
                                            "extension" = $ext
                                            "pattern_found" = $pattern
                                            "last_modified" = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                                        }
                                        break
                                    }
                                }
                            }
                        }
                        catch {
                            # Skip files that can't be read
                        }
                    }
                }
            }
        }
        
        $results.results = @{
            "status" =  "success"
            "files_filtered" = $filteredFiles.Count
            "search_patterns" = $searchPatterns
            "file_extensions" = $fileExtensions
            "search_paths" = $searchPaths
            "filtered_files" = $filteredFiles
            "max_files_limit" = $Config.MAX_FILES
            "output_directory" = $outputDir
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[SUCCESS] Content-based filtering completed: $($filteredFiles.Count) files found" -ForegroundColor Green
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
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1119_002a_content_filtering"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }
    
    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "CONTENT-BASED FILE FILTERING ==="
                $simpleOutput += "`nFiles filtered: $($Data.results.files_filtered)"
                $simpleOutput += "`nPatterns: $($Data.results.search_patterns -join ', ')"
                $simpleOutput += "`nExtensions: $($Data.results.file_extensions -join ', ')"
            } else {
                $simpleOutput = "Content-based filtering failed: $($Data.results.error)"
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
            Write-Host "[COMPLETE] T1119.002A atomic execution finished - Output: $outputPath" -ForegroundColor Green
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




