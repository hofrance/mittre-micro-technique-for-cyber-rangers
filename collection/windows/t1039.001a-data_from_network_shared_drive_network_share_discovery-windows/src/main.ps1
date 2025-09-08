# T1039.001a - Data from Network Shared Drive: Network Share Discovery
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Discover network shares ONLY (no access, no enumeration)
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        
        T1039_001A_SCAN_RANGE = if ($env:T1039_001A_SCAN_RANGE) { $env:T1039_001A_SCAN_RANGE } else { "local" }  # local|domain|custom
        T1039_001A_USE_NET_VIEW = if ($env:T1039_001A_USE_NET_VIEW) { $env:T1039_001A_USE_NET_VIEW -eq "true" } else { $true }
        T1039_001A_USE_SMB_CMDLETS = if ($env:T1039_001A_USE_SMB_CMDLETS) { $env:T1039_001A_USE_SMB_CMDLETS -eq "true" } else { $true }
        T1039_001A_TIMEOUT_MS = if ($env:T1039_001A_TIMEOUT_MS) { [int]$env:T1039_001A_TIMEOUT_MS } else { 5000 }
        T1039_001A_INCLUDE_HIDDEN = if ($env:T1039_001A_INCLUDE_HIDDEN) { $env:T1039_001A_INCLUDE_HIDDEN -eq "true" } else { $false }
        T1039_001A_RESOLVE_NAMES = if ($env:T1039_001A_RESOLVE_NAMES) { $env:T1039_001A_RESOLVE_NAMES -eq "true" } else { $true }
        T1039_001A_CUSTOM_HOSTS = if ($env:T1039_001A_CUSTOM_HOSTS) { $env:T1039_001A_CUSTOM_HOSTS -split "," } else { @() }
        T1039_001A_OUTPUT_MODE = if ($env:T1039_001A_OUTPUT_MODE) { $env:T1039_001A_OUTPUT_MODE } else { "debug" }
        T1039_001A_SILENT_MODE = if ($env:T1039_001A_SILENT_MODE) { $env:T1039_001A_SILENT_MODE -eq "true" } else { $false }
        T1039_001A_STEALTH_MODE = if ($env:T1039_001A_STEALTH_MODE) { $env:T1039_001A_STEALTH_MODE -eq "true" } else { $false }
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Network share discovery ONLY
    if (-not $Config.T1039_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic network share discovery..." -ForegroundColor Yellow
    }
    
    $discoveryResults = @{
        "action" =  "network_share_discovery"
        "technique_id" =  "T1039.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    $discoveredShares = @()
    $discoveryMethods = @()
    
    try {
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1039.001a-share_discovery"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Method 1: net view command
        if ($Config.T1039_001A_USE_NET_VIEW) {
            try {
                if (-not $Config.T1039_001A_SILENT_MODE) {
                    Write-Host "[INFO] Using net view for share discovery..." -ForegroundColor Cyan
                }
                
                $netViewResult = & net view 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $discoveryMethods += "net_view"
                    
                    # Parse net view output
                    $netViewResult | ForEach-Object {
                        if ($_ -match '\\\\([^\s]+)\s+(.*)') {
                            $computerName = $matches[1]
                            $description = $matches[2].Trim()
                            
                            # Get shares for this computer
                            try {
                                $computerShares = & net view "\\$computerName" 2>&1
                                if ($LASTEXITCODE -eq 0) {
                                    $computerShares | ForEach-Object {
                                        if ($_ -match '([^\s]+)\s+([^\s]+)\s+(.*)') {
                                            $shareName = $matches[1]
                                            $shareType = $matches[2]
                                            $shareComment = $matches[3]
                                            
                                            $discoveredShares += @{
                                                "computer_name" = $computerName
                                                "share_name" = $shareName
                                                "share_type" = $shareType
                                                "comment" = $shareComment
                                                "unc_path" =  "\\$computerName\$shareName"
                                                "discovery_method" =  "net_view"
                                                "discovery_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                                            }
                                        }
                                    }
                                }
                            } catch {
                                # Computer not accessible
                            }
                        }
                    }
                }
            } catch {
                if (-not $Config.T1039_001A_SILENT_MODE) {
                    Write-Warning "net view failed: $($_.Exception.Message)"
                }
            }
        }
        
        # Method 2: SMB PowerShell cmdlets
        if ($Config.T1039_001A_USE_SMB_CMDLETS) {
            try {
                if (-not $Config.T1039_001A_SILENT_MODE) {
                    Write-Host "[INFO] Using SMB cmdlets for share discovery..." -ForegroundColor Cyan
                }
                
                # Get local SMB shares first
                $localShares = Get-SmbShare -ErrorAction SilentlyContinue
                foreach ($share in $localShares) {
                    $discoveredShares += @{
                        "computer_name" = $env:COMPUTERNAME
                        "share_name" = $share.Name
                        "share_type" = $share.ShareType.ToString()
                        "path" = $share.Path
                        "description" = $share.Description
                        "unc_path" =  "\\$env:COMPUTERNAME\$($share.Name)"
                        "discovery_method" =  "smb_cmdlets"
                        "discovery_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        "is_local" = $true
                    }
                }
                
                $discoveryMethods += "smb_cmdlets"
            } catch {
                if (-not $Config.T1039_001A_SILENT_MODE) {
                    Write-Warning "SMB cmdlets failed: $($_.Exception.Message)"
                }
            }
        }
        
        # Method 3: Custom hosts scanning
        if ($Config.T1039_001A_CUSTOM_HOSTS.Count -gt 0) {
            foreach ($customHost in $Config.T1039_001A_CUSTOM_HOSTS) {
                $customHost = $customHost.Trim()
                try {
                    if (-not $Config.T1039_001A_SILENT_MODE) {
                        Write-Host "[INFO] Scanning custom host: $customHost" -ForegroundColor Cyan
                    }
                    
                    $hostShares = & net view "\\$customHost" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $hostShares | ForEach-Object {
                            if ($_ -match '([^\s]+)\s+([^\s]+)\s+(.*)') {
                                $shareName = $matches[1]
                                $shareType = $matches[2]
                                $shareComment = $matches[3]
                                
                                $discoveredShares += @{
                                    "computer_name" = $customHost
                                    "share_name" = $shareName
                                    "share_type" = $shareType
                                    "comment" = $shareComment
                                    "unc_path" =  "\\$customHost\$shareName"
                                    "discovery_method" =  "custom_scan"
                                    "discovery_time" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                                    "is_custom_host" = $true
                                }
                            }
                        }
                    }
                } catch {
                    # Host not accessible
                }
            }
        }
        
        # Remove duplicates based on UNC path
        $uniqueShares = $discoveredShares | Sort-Object unc_path -Unique
        
        $discoveryResults.results = @{
            "status" =  "success"
            "total_shares_discovered" = $uniqueShares.Count
            "discovery_methods_used" = $discoveryMethods
            "scan_range" = $Config.T1039_001A_SCAN_RANGE
            "custom_hosts_scanned" = $Config.T1039_001A_CUSTOM_HOSTS.Count
            "discovered_shares" = $uniqueShares
            "output_directory" = $outputDir
        }
        
        if (-not $Config.T1039_001A_SILENT_MODE) {
            Write-Host "[SUCCESS] Network share discovery completed: $($uniqueShares.Count) unique shares found" -ForegroundColor Green
        }
    }
    catch {
        $discoveryResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "discovered_shares" = @()
            "total_shares_discovered" = 0
        }
        
        if (-not $Config.T1039_001A_SILENT_MODE) {
            Write-Error "Network share discovery failed: $($_.Exception.Message)"
        }
    }
    
    return $discoveryResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1039.001a-share_discovery"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1039_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Share discovery: $($Data.results.total_shares_discovered) shares found"
            } else {
                $simpleOutput = "Share discovery failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1039_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "share_discovery_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "network_share_discovery.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "network_share_discovery.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1039_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Share discovery data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1039_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1039.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1039_001A_SILENT_MODE) {
            Write-Error "T1039.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


