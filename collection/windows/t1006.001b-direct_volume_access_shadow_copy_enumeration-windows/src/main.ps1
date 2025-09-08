# T1006.002a - Direct Volume Access: Shadow Copy Enumeration
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Enumerate shadow copies ONLY (no access, no file extraction)
# Platform: Windows | Privilege: Administrator | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        
        T1006_002A_SOURCE_VOLUMES = if ($env:T1006_002A_SOURCE_VOLUMES) { $env:T1006_002A_SOURCE_VOLUMES } else { "$env:TEMP\mitre_results\t1006.001a-volume_detection\volume_detection.json" }
        T1006_002A_INCLUDE_DETAILS = if ($env:T1006_002A_INCLUDE_DETAILS) { $env:T1006_002A_INCLUDE_DETAILS -eq "true" } else { $true }
        T1006_002A_MAX_COPIES = if ($env:T1006_002A_MAX_COPIES) { [int]$env:T1006_002A_MAX_COPIES } else { 100 }
        T1006_002A_FILTER_BY_DATE = if ($env:T1006_002A_FILTER_BY_DATE) { $env:T1006_002A_FILTER_BY_DATE -eq "true" } else { $false }
        T1006_002A_MIN_AGE_DAYS = if ($env:T1006_002A_MIN_AGE_DAYS) { [int]$env:T1006_002A_MIN_AGE_DAYS } else { 0 }
        T1006_002A_MAX_AGE_DAYS = if ($env:T1006_002A_MAX_AGE_DAYS) { [int]$env:T1006_002A_MAX_AGE_DAYS } else { 365 }
        T1006_002A_USE_VSSADMIN = if ($env:T1006_002A_USE_VSSADMIN) { $env:T1006_002A_USE_VSSADMIN -eq "true" } else { $true }
        T1006_002A_USE_WMI = if ($env:T1006_002A_USE_WMI) { $env:T1006_002A_USE_WMI -eq "true" } else { $true }
        T1006_002A_OUTPUT_MODE = if ($env:T1006_002A_OUTPUT_MODE) { $env:T1006_002A_OUTPUT_MODE } else { "debug" }
        T1006_002A_SILENT_MODE = if ($env:T1006_002A_SILENT_MODE) { $env:T1006_002A_SILENT_MODE -eq "true" } else { $false }
        T1006_002A_STEALTH_MODE = if ($env:T1006_002A_STEALTH_MODE) { $env:T1006_002A_STEALTH_MODE -eq "true" } else { $false }
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Shadow copy enumeration ONLY
    if (-not $Config.T1006_002A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic shadow copy enumeration..." -ForegroundColor Yellow
    }
    
    $shadowResults = @{
        "action" =  "shadow_copy_enumeration"
        "technique_id" =  "T1006.002a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "administrator"
    }
    
    # Check administrator privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        $shadowResults.results = @{
            "status" =  "failed"
            "error" =  "Administrator privileges required for shadow copy enumeration"
        }
        return $shadowResults
    }
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1006.002a-shadow_enumeration"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $shadowCopies = @()
        $enumerationMethods = @()
        
        # Method 1: vssadmin command
        if ($Config.T1006_002A_USE_VSSADMIN) {
            try {
                if (-not $Config.T1006_002A_SILENT_MODE) {
                    Write-Host "[INFO] Using vssadmin for shadow copy enumeration..." -ForegroundColor Cyan
                }
                
                $vssOutput = & vssadmin list shadows 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $enumerationMethods += "vssadmin"
                    
                    # Parse vssadmin output
                    $currentShadow = @{}
                    foreach ($line in $vssOutput) {
                        if ($line -match "Contents of shadow copy set ID: (.+)") {
                            if ($currentShadow.Count -gt 0) {
                                $shadowCopies += $currentShadow
                                $currentShadow = @{}
                            }
                            $currentShadow.shadow_set_id = $matches[1].Trim()
                        }
                        elseif ($line -match "Shadow Copy ID: (.+)") {
                            $currentShadow.shadow_copy_id = $matches[1].Trim()
                        }
                        elseif ($line -match "Original Volume: (.+)") {
                            $currentShadow.original_volume = $matches[1].Trim()
                        }
                        elseif ($line -match "Shadow Copy Volume: (.+)") {
                            $currentShadow.shadow_volume = $matches[1].Trim()
                        }
                        elseif ($line -match "Creation Time: (.+)") {
                            $currentShadow.creation_time = $matches[1].Trim()
                            $currentShadow.enumeration_method = "vssadmin"
                        }
                    }
                    
                    # Add last shadow copy if exists
                    if ($currentShadow.Count -gt 0) {
                        $shadowCopies += $currentShadow
                    }
                }
            } catch {
                if (-not $Config.T1006_002A_SILENT_MODE) {
                    Write-Warning "vssadmin enumeration failed: $($_.Exception.Message)"
                }
            }
        }
        
        # Method 2: WMI enumeration
        if ($Config.T1006_002A_USE_WMI) {
            try {
                if (-not $Config.T1006_002A_SILENT_MODE) {
                    Write-Host "[INFO] Using WMI for shadow copy enumeration..." -ForegroundColor Cyan
                }
                
                $wmiShadows = Get-WmiObject -Class Win32_ShadowCopy -ErrorAction SilentlyContinue
                
                if ($wmiShadows) {
                    $enumerationMethods += "wmi"
                    
                    foreach ($shadow in $wmiShadows) {
                        $shadowInfo = @{
                            "shadow_copy_id" = $shadow.ID
                            "device_object" = $shadow.DeviceObject
                            "volume_name" = $shadow.VolumeName
                            "originating_machine" = $shadow.OriginatingMachine
                            "service_machine" = $shadow.ServiceMachine
                            "install_date" = if ($shadow.InstallDate) { 
                                [System.Management.ManagementDateTimeConverter]::ToDateTime($shadow.InstallDate).ToString("yyyy-MM-dd HH:mm:ss")
                            } else { $null }
                            "provider_id" = $shadow.ProviderID
                            "state" = $shadow.State
                            "enumeration_method" =  "wmi"
                        }
                        
                        # Check if this shadow copy is already in the list (from vssadmin)
                        $duplicate = $false
                        foreach ($existingShadow in $shadowCopies) {
                            if ($existingShadow.shadow_copy_id -eq $shadowInfo.shadow_copy_id) {
                                $duplicate = $true
                                break
                            }
                        }
                        
                        if (-not $duplicate) {
                            $shadowCopies += $shadowInfo
                        }
                    }
                }
            } catch {
                if (-not $Config.T1006_002A_SILENT_MODE) {
                    Write-Warning "WMI shadow copy enumeration failed: $($_.Exception.Message)"
                }
            }
        }
        
        # Apply date filtering if requested
        if ($Config.T1006_002A_FILTER_BY_DATE -and $shadowCopies.Count -gt 0) {
            $filteredShadows = @()
            $cutoffDateMin = (Get-Date).AddDays(-$Config.T1006_002A_MAX_AGE_DAYS)
            $cutoffDateMax = (Get-Date).AddDays(-$Config.T1006_002A_MIN_AGE_DAYS)
            
            foreach ($shadow in $shadowCopies) {
                $shadowDate = $null
                
                if ($shadow.creation_time) {
                    try {
                        $shadowDate = [DateTime]::Parse($shadow.creation_time)
                    } catch {
                        # Could not parse date
                    }
                } elseif ($shadow.install_date) {
                    try {
                        $shadowDate = [DateTime]::Parse($shadow.install_date)
                    } catch {
                        # Could not parse date
                    }
                }
                
                if ($shadowDate -and $shadowDate -ge $cutoffDateMin -and $shadowDate -le $cutoffDateMax) {
                    $filteredShadows += $shadow
                }
            }
            
            $shadowCopies = $filteredShadows
        }
        
        # Limit number of shadow copies if specified
        if ($shadowCopies.Count -gt $Config.T1006_002A_MAX_COPIES) {
            $shadowCopies = $shadowCopies | Select-Object -First $Config.T1006_002A_MAX_COPIES
        }
        
        $shadowResults.results = @{
            "status" =  "success"
            "total_shadow_copies" = $shadowCopies.Count
            "enumeration_methods_used" = $enumerationMethods
            "shadow_copies" = $shadowCopies
            "configuration_used" = @{
                "use_vssadmin" = $Config.T1006_002A_USE_VSSADMIN
                "use_wmi" = $Config.T1006_002A_USE_WMI
                "include_details" = $Config.T1006_002A_INCLUDE_DETAILS
                "max_copies" = $Config.T1006_002A_MAX_COPIES
                "filter_by_date" = $Config.T1006_002A_FILTER_BY_DATE
            }
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1006_002A_SILENT_MODE) {
            Write-Host "[SUCCESS] Shadow copy enumeration completed: $($shadowCopies.Count) shadow copies found" -ForegroundColor Green
        }
    }
    catch {
        $shadowResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "shadow_copies" = @()
            "total_shadow_copies" = 0
        }
        
        if (-not $Config.T1006_002A_SILENT_MODE) {
            Write-Error "Shadow copy enumeration failed: $($_.Exception.Message)"
        }
    }
    
    return $shadowResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1006.002a-shadow_enumeration"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1006_002A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Shadow copies found: $($Data.results.total_shadow_copies)"
            } else {
                $simpleOutput = "Shadow copy enumeration failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1006_002A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "shadow_enumeration_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "shadow_copy_enumeration.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "shadow_copy_enumeration.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1006_002A_SILENT_MODE) {
                Write-Host "[DEBUG] Shadow copy data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1006_002A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1006.002a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1006_002A_SILENT_MODE) {
            Write-Error "T1006.002a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


