# filepath: \\vmware-host\Shared Folders\deputy-one\tactics\collection\windows\t1114.001a-email_collection-a_email_client_detection-windows\src\main.ps1
# T1114.001a - Email Collection: Email Client Detection
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Detect installed email clients ONLY (no data extraction)
# Platform: Windows | Privilege: User | Type: Atomic Package

# CONTRACT METADATA
# Technique: T1114.001a
# Observable Action: email_client_detection
# Precondition: Windows OS, User privileges, Registry/Process access
# Postcondition: Detection results written to output, No data extraction performed
# Dependencies: PowerShell 5.1+, Windows Registry access
# Timeout: 300 seconds
# Return Codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED_PRECONDITION, 3=DENIED_POLICY, 4=FAILED_POSTCONDITION, 124=TIMEOUT

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        "SIMULATION_MODE" = if ($env:SIMULATION_MODE) { $env:SIMULATION_MODE -eq "true" } else { $false }
        "RETRY_ATTEMPTS" = if ($env:RETRY_ATTEMPTS) { [int]$env:RETRY_ATTEMPTS } else { 3 }
        "RETRY_DELAY" = if ($env:RETRY_DELAY) { [int]$env:RETRY_DELAY } else { 2 }
        
        T1114_001A_CHECK_REGISTRY = if ($env:T1114_001A_CHECK_REGISTRY) { $env:T1114_001A_CHECK_REGISTRY -eq "true" } else { $true }
        T1114_001A_CHECK_PROCESSES = if ($env:T1114_001A_CHECK_PROCESSES) { $env:T1114_001A_CHECK_PROCESSES -eq "true" } else { $true }
        T1114_001A_CHECK_INSTALLED_PROGRAMS = if ($env:T1114_001A_CHECK_INSTALLED_PROGRAMS) { $env:T1114_001A_CHECK_INSTALLED_PROGRAMS -eq "true" } else { $true }
        T1114_001A_CHECK_FILE_ASSOCIATIONS = if ($env:T1114_001A_CHECK_FILE_ASSOCIATIONS) { $env:T1114_001A_CHECK_FILE_ASSOCIATIONS -eq "true" } else { $true }
        T1114_001A_INCLUDE_PROFILES = if ($env:T1114_001A_INCLUDE_PROFILES) { $env:T1114_001A_INCLUDE_PROFILES -eq "true" } else { $true }
        T1114_001A_DETECT_VERSIONS = if ($env:T1114_001A_DETECT_VERSIONS) { $env:T1114_001A_DETECT_VERSIONS -eq "true" } else { $true }
        T1114_001A_CHECK_DEFAULT_CLIENT = if ($env:T1114_001A_CHECK_DEFAULT_CLIENT) { $env:T1114_001A_CHECK_DEFAULT_CLIENT -eq "true" } else { $true }
        T1114_001A_SCAN_COMMON_PATHS = if ($env:T1114_001A_SCAN_COMMON_PATHS) { $env:T1114_001A_SCAN_COMMON_PATHS -eq "true" } else { $true }
        T1114_001A_OUTPUT_MODE = if ($env:T1114_001A_OUTPUT_MODE) { $env:T1114_001A_OUTPUT_MODE } else { "debug" }
        T1114_001A_SILENT_MODE = if ($env:T1114_001A_SILENT_MODE) { $env:T1114_001A_SILENT_MODE -eq "true" } else { $false }
        T1114_001A_STEALTH_MODE = if ($env:T1114_001A_STEALTH_MODE) { $env:T1114_001A_STEALTH_MODE -eq "true" } else { $false }
    }
}

function Test-Preconditions {
    param([hashtable]$Config)
    
    # Check OS compatibility
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        return @{ valid = $false; reason = "PowerShell version 5.1+ required"; code = 2 }
    }
    
    # Check Windows platform
    if ($env:OS -notmatch "Windows") {
        return @{ valid = $false; reason = "Windows platform required"; code = 2 }
    }
    
    # Check user privileges (basic check)
    try {
        $testPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion"
        Get-Item $testPath -ErrorAction Stop | Out-Null
    } catch {
        return @{ valid = $false; reason = "Insufficient privileges for registry access"; code = 3 }
    }
    
    return @{ valid = $true; reason = "All preconditions met"; code = 0 }
}

function Test-Postconditions {
    param([hashtable]$Results, [hashtable]$Config)
    
    # Verify output directory exists
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1114.001a-email_detection"
    if (-not (Test-Path $outputDir)) {
        return @{ valid = $false; reason = "Output directory not created"; code = 4 }
    }
    
    # Verify results structure
    if (-not $Results.ContainsKey("results") -or -not $Results.results.ContainsKey("email_clients")) {
        return @{ valid = $false; reason = "Invalid results structure"; code = 4 }
    }
    
    # Verify no data extraction occurred (atomic action compliance)
    $hasDataExtraction = $Results.results.email_clients | Where-Object { 
        $_.ContainsKey("email_data") -or $_.ContainsKey("extracted_content") 
    }
    if ($hasDataExtraction) {
        return @{ valid = $false; reason = "Data extraction detected - violates atomic action"; code = 4 }
    }
    
    return @{ valid = $true; reason = "All postconditions met"; code = 0 }
}

function Invoke-AtomicAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Email client detection ONLY
    if (-not $Config.T1114_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic email client detection..." -ForegroundColor Yellow
    }
    
    $startTime = Get-Date
    $detectionResults = @{
        "@timestamp" = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        "event" = @{
            "kind" =  "event"
            "category" =  "collection"
            "type" =  "info"
            "action" =  "email_client_detection"
        }
        "technique" = @{
            "id" =  "T1114.001a"
            "name" =  "Email Collection"
            "subtechnique" =  "Email Client Detection"
        }
        "host" = @{
            "hostname" = $env:COMPUTERNAME
            "os" = @{
                "name" =  "Windows"
                "version" = (Get-WmiObject Win32_OperatingSystem).Caption
            }
        }
        "user" = @{
            "name" = $env:USERNAME
            "domain" = $env:USERDOMAIN
        }
        "process" = @{
            "pid" = $PID
            "name" =  "powershell.exe"
            "executable" = $PSHOME + "\powershell.exe"
        }
        "mitre" = @{
            "atomic" = @{
                "action" =  "email_client_detection"
                "privilege_level" =  "user"
                "simulation_mode" = $Config.SIMULATION_MODE
            }
        }
    }
    
    $detectedClients = @()
    $performanceMetrics = @{
        "start_time" = $startTime
        "methods_attempted" = 0
        "methods_succeeded" = 0
        "total_execution_time" = 0
        "retry_count" = 0
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1114.001a-email_detection"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Circuit breaker for timeout
        $timeoutJob = Start-Job -ScriptBlock {
            param($Timeout)
            Start-Sleep -Seconds $Timeout
            return "TIMEOUT"
        } -ArgumentList $Config.TIMEOUT
        
        # Method 1: Registry-based detection
        if ($Config.T1114_001A_CHECK_REGISTRY) {
            $performanceMetrics.methods_attempted++
            
            if ($Config.SIMULATION_MODE) {
                $detectedClients += @{
                    "client_name" =  "Microsoft Outlook (Simulated)"
                    "detection_method" =  "registry"
                    "installation_detected" = $true
                    "version" =  "16.0.0.0"
                }
                $performanceMetrics.methods_succeeded++
            } else {
                $retryCount = 0
                $success = $false
                
                while ($retryCount -lt $Config.RETRY_ATTEMPTS -and -not $success) {
                    try {
                        $emailRegistryPaths = @(
                            "HKLM:\SOFTWARE\Microsoft\Office\*\Outlook",
                            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\*\Outlook",
                            "HKCU:\SOFTWARE\Microsoft\Office\*\Outlook",
                            "HKLM:\SOFTWARE\Mozilla\Thunderbird",
                            "HKCU:\SOFTWARE\Mozilla\Thunderbird",
                            "HKLM:\SOFTWARE\Microsoft\Windows Mail",
                            "HKCU:\SOFTWARE\Microsoft\Windows Mail"
                        )
                        
                        foreach ($regPath in $emailRegistryPaths) {
                            try {
                                $regItems = Get-Item $regPath -ErrorAction SilentlyContinue
                                foreach ($item in $regItems) {
                                    $clientInfo = @{
                                        "client_name" = if ($item.PSPath -match "Outlook") { "Microsoft Outlook" } 
                                                     elseif ($item.PSPath -match "Thunderbird") { "Mozilla Thunderbird" }
                                                     elseif ($item.PSPath -match "Windows Mail") { "Windows Mail" }
                                                     else { "Unknown" }
                                        "detection_method" =  "registry"
                                        "registry_path" = $item.PSPath
                                        "installation_detected" = $true
                                    }
                                    
                                    # Get version if requested
                                    if ($Config.T1114_001A_DETECT_VERSIONS) {
                                        try {
                                            $versionInfo = Get-ItemProperty -Path $item.PSPath -Name "Version" -ErrorAction SilentlyContinue
                                            if ($versionInfo) {
                                                $clientInfo.version = $versionInfo.Version
                                            }
                                        } catch {
                                            $clientInfo.version = "Unknown"
                                        }
                                    }
                                    
                                    $detectedClients += $clientInfo
                                }
                            } catch {
                                # Registry path not found or not accessible
                            }
                        }
                        $success = $true
                        $performanceMetrics.methods_succeeded++
                    } catch {
                        $retryCount++
                        $performanceMetrics.retry_count++
                        if ($retryCount -lt $Config.RETRY_ATTEMPTS) {
                            Start-Sleep -Seconds ($Config.RETRY_DELAY * [math]::Pow(2, $retryCount - 1))
                        }
                    }
                }
            }
        }
        
        # Method 2: Process-based detection
        if ($Config.T1114_001A_CHECK_PROCESSES) {
            $performanceMetrics.methods_attempted++
            
            if ($Config.SIMULATION_MODE) {
                $detectedClients += @{
                    "client_name" =  "Mozilla Thunderbird (Simulated)"
                    "detection_method" =  "process"
                    "process_id" = 1234
                    "process_name" =  "thunderbird"
                    "is_running" = $true
                }
                $performanceMetrics.methods_succeeded++
            } else {
                $retryCount = 0
                $success = $false
                
                while ($retryCount -lt $Config.RETRY_ATTEMPTS -and -not $success) {
                    try {
                        $emailProcesses = @("outlook", "thunderbird", "mailbird", "postbox", "emclient", "winmail")
                        
                        foreach ($processName in $emailProcesses) {
                            try {
                                $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
                                foreach ($process in $processes) {
                                    $clientInfo = @{
                                        "client_name" = switch ($processName) {
                                            "outlook" { "Microsoft Outlook" }
                                            "thunderbird" { "Mozilla Thunderbird" }
                                            "mailbird" { "Mailbird" }
                                            "postbox" { "Postbox" }
                                            "emclient" { "eM Client" }
                                            "winmail" { "Windows Mail" }
                                            default { $processName }
                                        }
                                        "detection_method" =  "process"
                                        "process_id" = $process.Id
                                        "process_name" = $process.ProcessName
                                        "process_path" = (try { $process.MainModule.FileName } catch { "Access Denied" })
                                        "start_time" = $process.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                                        "is_running" = $true
                                    }
                                    
                                    # Get version from file if possible
                                    if ($Config.T1114_001A_DETECT_VERSIONS -and $clientInfo.process_path -ne "Access Denied") {
                                        try {
                                            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($clientInfo.process_path)
                                            $clientInfo.file_version = $versionInfo.FileVersion
                                            $clientInfo.product_version = $versionInfo.ProductVersion
                                        } catch {
                                            $clientInfo.version_error = $_.Exception.Message
                                        }
                                    }
                                    
                                    $detectedClients += $clientInfo
                                }
                            } catch {
                                # Process not found
                            }
                        }
                        $success = $true
                        $performanceMetrics.methods_succeeded++
                    } catch {
                        $retryCount++
                        $performanceMetrics.retry_count++
                        if ($retryCount -lt $Config.RETRY_ATTEMPTS) {
                            Start-Sleep -Seconds ($Config.RETRY_DELAY * [math]::Pow(2, $retryCount - 1))
                        }
                    }
                }
            }
        }
        
        # Method 3: Installed programs detection
        if ($Config.T1114_001A_CHECK_INSTALLED_PROGRAMS) {
            $performanceMetrics.methods_attempted++
            
            if ($Config.SIMULATION_MODE) {
                $detectedClients += @{
                    "client_name" =  "Windows Mail (Simulated)"
                    "detection_method" =  "installed_programs"
                    "display_version" =  "10.0.0.0"
                    "publisher" =  "Microsoft Corporation"
                }
                $performanceMetrics.methods_succeeded++
            } else {
                $retryCount = 0
                $success = $false
                
                while ($retryCount -lt $Config.RETRY_ATTEMPTS -and -not $success) {
                    try {
                        $uninstallPaths = @(
                            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
                        )
                        
                        foreach ($uninstallPath in $uninstallPaths) {
                            try {
                                $programs = Get-ItemProperty $uninstallPath -ErrorAction SilentlyContinue | Where-Object { 
                                    $_.DisplayName -match "Outlook|Thunderbird|Mail|Email" 
                                }
                                
                                foreach ($program in $programs) {
                                    $clientInfo = @{
                                        "client_name" = $program.DisplayName
                                        "detection_method" =  "installed_programs"
                                        "display_version" = $program.DisplayVersion
                                        "install_location" = $program.InstallLocation
                                        "install_date" = $program.InstallDate
                                        "publisher" = $program.Publisher
                                        "uninstall_string" = $program.UninstallString
                                        "registry_key" = $program.PSPath
                                    }
                                    
                                    $detectedClients += $clientInfo
                                }
                            } catch {
                                # Uninstall registry not accessible
                            }
                        }
                        $success = $true
                        $performanceMetrics.methods_succeeded++
                    } catch {
                        $retryCount++
                        $performanceMetrics.retry_count++
                        if ($retryCount -lt $Config.RETRY_ATTEMPTS) {
                            Start-Sleep -Seconds ($Config.RETRY_DELAY * [math]::Pow(2, $retryCount - 1))
                        }
                    }
                }
            }
        }
        
        # Method 4: File associations
        if ($Config.T1114_001A_CHECK_FILE_ASSOCIATIONS) {
            $performanceMetrics.methods_attempted++
            
            if ($Config.SIMULATION_MODE) {
                $detectedClients += @{
                    "client_name" =  "Associated Email Client (Simulated)"
                    "detection_method" =  "file_association"
                    "file_extension" =  ".eml"
                }
                $performanceMetrics.methods_succeeded++
            } else {
                $retryCount = 0
                $success = $false
                
                while ($retryCount -lt $Config.RETRY_ATTEMPTS -and -not $success) {
                    try {
                        $emailExtensions = @(".eml", ".msg", ".pst", ".ost", ".mbox")
                        
                        foreach ($ext in $emailExtensions) {
                            $assoc = & cmd /c "assoc $ext" 2>$null
                            if ($assoc -and $LASTEXITCODE -eq 0) {
                                $fileType = $assoc.Split('=')[1]
                                $command = & cmd /c "ftype $fileType" 2>$null
                                
                                if ($command -and $LASTEXITCODE -eq 0) {
                                    $clientInfo = @{
                                        "client_name" =  "Associated Email Client"
                                        "detection_method" =  "file_association"
                                        "file_extension" = $ext
                                        "file_type" = $fileType
                                        "command" = $command
                                    }
                                    
                                    $detectedClients += $clientInfo
                                }
                            }
                        }
                        $success = $true
                        $performanceMetrics.methods_succeeded++
                    } catch {
                        $retryCount++
                        $performanceMetrics.retry_count++
                        if ($retryCount -lt $Config.RETRY_ATTEMPTS) {
                            Start-Sleep -Seconds ($Config.RETRY_DELAY * [math]::Pow(2, $retryCount - 1))
                        }
                    }
                }
            }
        }
        
        # Check for default email client
        if ($Config.T1114_001A_CHECK_DEFAULT_CLIENT) {
            $performanceMetrics.methods_attempted++
            
            if ($Config.SIMULATION_MODE) {
                $detectedClients += @{
                    "client_name" =  "Microsoft Outlook (Default, Simulated)"
                    "detection_method" =  "default_client"
                    "is_default" = $true
                }
                $performanceMetrics.methods_succeeded++
            } else {
                $retryCount = 0
                $success = $false
                
                while ($retryCount -lt $Config.RETRY_ATTEMPTS -and -not $success) {
                    try {
                        $defaultClient = Get-ItemProperty "HKCU:\SOFTWARE\Clients\Mail" -Name "(Default)" -ErrorAction SilentlyContinue
                        if ($defaultClient) {
                            $clientInfo = @{
                                "client_name" = $defaultClient."(Default)"
                                "detection_method" =  "default_client"
                                "is_default" = $true
                            }
                            
                            $detectedClients += $clientInfo
                        }
                        $success = $true
                        $performanceMetrics.methods_succeeded++
                    } catch {
                        $retryCount++
                        $performanceMetrics.retry_count++
                        if ($retryCount -lt $Config.RETRY_ATTEMPTS) {
                            Start-Sleep -Seconds ($Config.RETRY_DELAY * [math]::Pow(2, $retryCount - 1))
                        }
                    }
                }
            }
        }
        
        # Check timeout
        if ($timeoutJob.State -eq "Completed") {
            $timeoutResult = Receive-Job $timeoutJob
            if ($timeoutResult -eq "TIMEOUT") {
                throw "Operation timed out after $($Config.TIMEOUT) seconds"
            }
        }
        Remove-Job $timeoutJob -Force
        
        # Remove duplicates based on client name
        $uniqueClients = $detectedClients | Sort-Object client_name -Unique
        
        $endTime = Get-Date
        $performanceMetrics.total_execution_time = ($endTime - $startTime).TotalSeconds
        $performanceMetrics.end_time = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        $detectionResults.results = @{
            "status" =  "success"
            "total_clients_detected" = $uniqueClients.Count
            "email_clients" = $uniqueClients
            "detection_methods_used" = ($uniqueClients.detection_method | Sort-Object -Unique)
            "detection_summary" = @{
                "registry_detections" = ($uniqueClients | Where-Object { $_.detection_method -eq "registry" }).Count
                "process_detections" = ($uniqueClients | Where-Object { $_.detection_method -eq "process" }).Count
                "installed_program_detections" = ($uniqueClients | Where-Object { $_.detection_method -eq "installed_programs" }).Count
                "file_association_detections" = ($uniqueClients | Where-Object { $_.detection_method -eq "file_association" }).Count
                "default_client_detected" = ($uniqueClients | Where-Object { $_.is_default -eq $true }).Count -gt 0
            }
            "performance" = $performanceMetrics
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1114_001A_SILENT_MODE) {
            Write-Host "[SUCCESS] Email client detection completed: $($uniqueClients.Count) clients found" -ForegroundColor Green
        }
    }
    catch {
        $endTime = Get-Date
        $performanceMetrics.total_execution_time = ($endTime - $startTime).TotalSeconds
        $performanceMetrics.end_time = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        $detectionResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "email_clients" = @()
            "total_clients_detected" = 0
            "performance" = $performanceMetrics
        }
        
        if (-not $Config.T1114_001A_SILENT_MODE) {
            Write-Error "Email client detection failed: $($_.Exception.Message)"
        }
    }
    
    return $detectionResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1114.001a-email_detection"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1114_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $clientNames = ($Data.results.email_clients | ForEach-Object { $_.client_name }) -join ", "
                $simpleOutput = "Email clients detected: $clientNames"
            } else {
                $simpleOutput = "Email client detection failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1114_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "email_detection_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "email_client_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "email_client_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1114_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Email detection data written to: $jsonFile" -ForegroundColor Cyan
            }
        }
        
        "silent" {
            # No output, just ensure file exists for postcondition check
            $jsonFile = Join-Path $outputDir "email_client_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
    }
    
    return $outputDir
}

function Main {
    try {
        $Config = Get-Configuration
        
        # Precondition check
        $preCheck = Test-Preconditions -Config $config
        if (-not $preCheck.valid) {
            if (-not $Config.T1114_001A_SILENT_MODE) {
                Write-Warning "Precondition failed: $($preCheck.reason)"
            }
            return $preCheck.code
        }
        
        $results = Invoke-AtomicAction -Config $config
        $outputPath = Write-StandardizedOutput -Data $results -Config $config
        
        # Postcondition check
        $postCheck = Test-Postconditions -Results $results -Config $config
        if (-not $postCheck.valid) {
            if (-not $Config.T1114_001A_SILENT_MODE) {
                Write-Error "Postcondition failed: $($postCheck.reason)"
            }
            return $postCheck.code
        }
        
        if (-not $Config.T1114_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1114.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1114_001A_SILENT_MODE) {
            Write-Error "T1114.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


