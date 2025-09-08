# T1006.001a - Direct Volume Access: Volume Detection
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Detect and enumerate system volumes ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }

        T1006_001A_INCLUDE_MOUNT_POINTS = if ($env:T1006_001A_INCLUDE_MOUNT_POINTS) { $env:T1006_001A_INCLUDE_MOUNT_POINTS -eq "true" } else { $true }
        T1006_001A_FILTER_REMOVABLE = if ($env:T1006_001A_FILTER_REMOVABLE) { $env:T1006_001A_FILTER_REMOVABLE -eq "true" } else { $false }
        T1006_001A_INCLUDE_NETWORK_DRIVES = if ($env:T1006_001A_INCLUDE_NETWORK_DRIVES) { $env:T1006_001A_INCLUDE_NETWORK_DRIVES -eq "true" } else { $false }
        T1006_001A_CHECK_PERMISSIONS = if ($env:T1006_001A_CHECK_PERMISSIONS) { $env:T1006_001A_CHECK_PERMISSIONS -eq "true" } else { $true }
        T1006_001A_DETAILED_INFO = if ($env:T1006_001A_DETAILED_INFO) { $env:T1006_001A_DETAILED_INFO -eq "true" } else { $true }
        T1006_001A_MIN_SIZE_GB = if ($env:T1006_001A_MIN_SIZE_GB) { [double]$env:T1006_001A_MIN_SIZE_GB } else { 0 }
        T1006_001A_OUTPUT_MODE = if ($env:T1006_001A_OUTPUT_MODE) { $env:T1006_001A_OUTPUT_MODE } else { "debug" }
        T1006_001A_SILENT_MODE = if ($env:T1006_001A_SILENT_MODE) { $env:T1006_001A_SILENT_MODE -eq "true" } else { $false }
        T1006_001A_STEALTH_MODE = if ($env:T1006_001A_STEALTH_MODE) { $env:T1006_001A_STEALTH_MODE -eq "true" } else { $false }
        # NEW: Performance optimizations
        T1006_001A_MAX_VOLUMES = if ($env:T1006_001A_MAX_VOLUMES) { [int]$env:T1006_001A_MAX_VOLUMES } else { 20 }  # Circuit breaker
        T1006_001A_ENABLE_TIMEOUT = if ($env:T1006_001A_ENABLE_TIMEOUT) { $env:T1006_001A_ENABLE_TIMEOUT -eq "true" } else { $true }
        T1006_001A_QUICK_MODE = if ($env:T1006_001A_QUICK_MODE) { $env:T1006_001A_QUICK_MODE -eq "true" } else { $false }  # Skip slow operations
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: System volume detection ONLY
    if (-not $Config.T1006_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic volume detection..." -ForegroundColor Yellow
    }
    
    $volumeResults = @{
        "action" =  "volume_detection"
        "technique_id" =  "T1006.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    $volumes = @()
    $startTime = Get-Date
    $circuitBreaker = $false
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1006.001a-volume_detection"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Get volume information using WMI (optimized)
        $wmiVolumes = Get-CimInstance -Class Win32_Volume | Where-Object { $null -ne $_.DriveLetter }
        
        foreach ($volume in $wmiVolumes) {
            # Circuit breaker check
            if ($Config.T1006_001A_ENABLE_TIMEOUT) {
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -gt ($Config.TIMEOUT * 0.8)) {
                    $circuitBreaker = $true
                    if (-not $Config.T1006_001A_SILENT_MODE) {
                        Write-Host "[WARN] Circuit breaker activated - approaching timeout" -ForegroundColor Yellow
                    }
                    break
                }
            }
            
            if ($volumes.Count -ge $Config.T1006_001A_MAX_VOLUMES) {
                $circuitBreaker = $true
                if (-not $Config.T1006_001A_SILENT_MODE) {
                    Write-Host "[WARN] Circuit breaker activated - max volumes reached ($($Config.T1006_001A_MAX_VOLUMES))" -ForegroundColor Yellow
                }
                break
            }
            
            # Filter by size if specified
            $volumeSizeGB = [math]::Round($volume.Capacity / 1GB, 2)
            if ($volumeSizeGB -lt $Config.T1006_001A_MIN_SIZE_GB) {
                continue
            }
            
            # Filter removable drives if specified
            if ($Config.T1006_001A_FILTER_REMOVABLE) {
                $driveType = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $volume.DriveLetter.TrimEnd(':') + ':' }
                if ($driveType -and $driveType.DriveType -eq 2) {  # Removable disk
                    continue
                }
            }
            
            $volumeInfo = @{
                "drive_letter" = $volume.DriveLetter
                "label" = $volume.Label
                "file_system" = $volume.FileSystem
                "size_gb" = $volumeSizeGB
                "free_space_gb" = [math]::Round($volume.FreeSpace / 1GB, 2)
                "used_space_percent" = if ($volume.Capacity -gt 0) { 
                    [math]::Round((($volume.Capacity - $volume.FreeSpace) / $volume.Capacity) * 100, 1) 
                } else { 0 }
                "device_id" = $volume.DeviceID
                "serial_number" = $volume.SerialNumber
                "boot_volume" = $volume.BootVolume
                "system_volume" = $volume.SystemVolume
                "page_file_present" = $volume.PageFilePresent
                "dirty" = $volume.DirtyBitSet
                "compressed" = $volume.Compressed
                "automount" = $volume.Automount
            }
            
            # Add detailed information if requested (skip in quick mode)
            if ($Config.T1006_001A_DETAILED_INFO -and -not $Config.T1006_001A_QUICK_MODE) {
                try {
                    $logicalDisk = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $volume.DriveLetter.TrimEnd(':') + ':' }
                    if ($logicalDisk) {
                        $volumeInfo.drive_type = switch ($logicalDisk.DriveType) {
                            1 { "No Root Directory" }
                            2 { "Removable Disk" }
                            3 { "Local Disk" }
                            4 { "Network Drive" }
                            5 { "Compact Disc" }
                            6 { "RAM Disk" }
                            default { "Unknown" }
                        }
                        $volumeInfo.media_type = $logicalDisk.MediaType
                        $volumeInfo.provider_name = $logicalDisk.ProviderName
                    }
                } catch {
                    $volumeInfo.detailed_info_error = $_.Exception.Message
                }
            }
            
            # Include mount points if requested (skip in quick mode)
            if ($Config.T1006_001A_INCLUDE_MOUNT_POINTS -and -not $Config.T1006_001A_QUICK_MODE) {
                try {
                    $mountPoints = Get-CimInstance -Class Win32_MountPoint | Where-Object { $_.Volume -eq $volume.DeviceID }
                    $volumeInfo.mount_points = $mountPoints | ForEach-Object { $_.Directory }
                } catch {
                    $volumeInfo.mount_points_error = $_.Exception.Message
                }
            }
            
            # Check permissions if requested (optimized - skip slow operations in quick mode)
            if ($Config.T1006_001A_CHECK_PERMISSIONS -and -not $Config.T1006_001A_QUICK_MODE) {
                try {
                    $drivePath = $volume.DriveLetter.TrimEnd(':') + ':\'
                    $accessTest = Test-Path $drivePath -PathType Container
                    $volumeInfo.accessible = $accessTest
                    
                    if ($accessTest) {
                        # Quick permission check without listing directory contents
                        $volumeInfo.readable = $true
                        $volumeInfo.root_items_count = "Not counted (performance)"
                    } else {
                        $volumeInfo.readable = $false
                    }
                } catch {
                    $volumeInfo.permission_check_error = $_.Exception.Message
                    $volumeInfo.accessible = $false
                    $volumeInfo.readable = $false
                }
            }
            
            $volumes += $volumeInfo
        }
        
        # Include network drives if requested (skip in quick mode)
        if ($Config.T1006_001A_INCLUDE_NETWORK_DRIVES -and -not $Config.T1006_001A_QUICK_MODE) {
            try {
                $networkDrives = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 4 }
                foreach ($netDrive in $networkDrives) {
                    if ($volumes.Count -ge $Config.T1006_001A_MAX_VOLUMES) {
                        break
                    }
                    
                    $volumes += @{
                        "drive_letter" = $netDrive.DeviceID
                        "label" = $netDrive.VolumeName
                        "drive_type" =  "Network Drive"
                        "size_gb" = [math]::Round($netDrive.Size / 1GB, 2)
                        "free_space_gb" = [math]::Round($netDrive.FreeSpace / 1GB, 2)
                        "provider_name" = $netDrive.ProviderName
                        "is_network_drive" = $true
                    }
                }
            } catch {
                # Network drive enumeration failed
            }
        }
        
        $volumeResults.results = @{
            "status" = if ($circuitBreaker) { "partial_success" } else { "success" }
            "total_volumes" = $volumes.Count
            "volumes_detected" = $volumes
            "detection_method" =  "wmi"
            "include_mount_points" = $Config.T1006_001A_INCLUDE_MOUNT_POINTS
            "include_network_drives" = $Config.T1006_001A_INCLUDE_NETWORK_DRIVES
            "filter_removable" = $Config.T1006_001A_FILTER_REMOVABLE
            "min_size_gb" = $Config.T1006_001A_MIN_SIZE_GB
            "circuit_breaker_activated" = $circuitBreaker
            "performance_metrics" = @{
                "execution_time_seconds" = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
                "volumes_per_second" = if (((Get-Date) - $startTime).TotalSeconds -gt 0) { 
                    [math]::Round($volumes.Count / ((Get-Date) - $startTime).TotalSeconds, 2) 
                } else { 0 }
            }
            "configuration_used" = @{
                "max_volumes" = $Config.T1006_001A_MAX_VOLUMES
                "enable_timeout_protection" = $Config.T1006_001A_ENABLE_TIMEOUT
                "quick_mode" = $Config.T1006_001A_QUICK_MODE
            }
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1006_001A_SILENT_MODE) {
            $statusMsg = if ($circuitBreaker) { "PARTIAL SUCCESS" } else { "SUCCESS" }
            Write-Host "[$statusMsg] Volume detection completed: $($volumes.Count) volumes found" -ForegroundColor $(if ($circuitBreaker) { "Yellow" } else { "Green" })
        }
    }
    catch {
        $volumeResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "volumes_detected" = @()
            "total_volumes" = 0
        }
        
        if (-not $Config.T1006_001A_SILENT_MODE) {
            Write-Error "Volume detection failed: $($_.Exception.Message)"
        }
    }
    
    return $volumeResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1006.001a-volume_detection"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1006_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Volume detection: $($Data.results.total_volumes) volumes found"
            } else {
                $simpleOutput = "Volume detection failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1006_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "volume_detection_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "volume_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "volume_detection.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1006_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Volume data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1006_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1006.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1006_001A_SILENT_MODE) {
            Write-Error "T1006.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)



