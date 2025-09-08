# T1480.001D - Geolocation Checks
# MITRE ATT&CK Technique: T1480 - Execution Guardrails
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # .NET web client support
    try {
        Add-Type -AssemblyName System.Device
        return $true
    } catch {
        # System.Device might not be available, that's OK
        return $true
    }
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        TargetCountry = if ($env:T1480_001D_TARGET_COUNTRY) { $env:T1480_001D_TARGET_COUNTRY } else { "" }
        TargetCity = if ($env:T1480_001D_TARGET_CITY) { $env:T1480_001D_TARGET_CITY } else { "" }
        TargetRegion = if ($env:T1480_001D_TARGET_REGION) { $env:T1480_001D_TARGET_REGION } else { "" }
        MaxDistance = if ($env:T1480_001D_MAX_DISTANCE_KM) { [int]$env:T1480_001D_MAX_DISTANCE_KM } else { 0 }
        TargetLat = if ($env:T1480_001D_TARGET_LAT) { [double]$env:T1480_001D_TARGET_LAT } else { 0 }
        TargetLon = if ($env:T1480_001D_TARGET_LON) { [double]$env:T1480_001D_TARGET_LON } else { 0 }
        ActionOnFail = if ($env:T1480_001D_ACTION_ON_FAIL) { $env:T1480_001D_ACTION_ON_FAIL } else { "exit" }
        OutputMode = if ($env:T1480_001D_OUTPUT_MODE) { $env:T1480_001D_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1480_001D_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Get-GeoLocationByIP {
    try {
        # Try multiple geolocation services
        $services = @(
            @{
                Name = "ipapi"
                Url = "http://ip-api.com/json/"
                Parser = {
                    param($response)
                    $data = $response | ConvertFrom-Json
                    if ($data.status -eq "success") {
                        return @{
                            Success = $true
                            IP = $data.query
                            Country = $data.country
                            CountryCode = $data.countryCode
                            Region = $data.regionName
                            City = $data.city
                            Latitude = $data.lat
                            Longitude = $data.lon
                            ISP = $data.isp
                            Timezone = $data.timezone
                        }
                    }
                    return @{ Success = $false }
                }
            },
            @{
                Name = "ipinfo"
                Url = "https://ipinfo.io/json"
                Parser = {
                    param($response)
                    $data = $response | ConvertFrom-Json
                    if ($data.loc) {
                        $coords = $data.loc -split ","
                        return @{
                            Success = $true
                            IP = $data.ip
                            Country = $data.country
                            CountryCode = $data.country
                            Region = $data.region
                            City = $data.city
                            Latitude = [double]$coords[0]
                            Longitude = [double]$coords[1]
                            ISP = $data.org
                            Timezone = $data.timezone
                        }
                    }
                    return @{ Success = $false }
                }
            }
        )
        
        foreach ($service in $services) {
            try {
                $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5
                $location = & $service.Parser -response $response.Content
                if ($location.Success) {
                    return $location
                }
            } catch {
                # Try next service
            }
        }
        
        return @{
            Success = $false
            Error = "All geolocation services failed"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-GeoLocationByTimezone {
    try {
        $timezone = [System.TimeZoneInfo]::Local
        
        # Map common timezones to approximate locations
        $timezoneMap = @{
            "Eastern Standard Time" = @{ Country = "US"; Region = "East Coast" }
            "Central Standard Time" = @{ Country = "US"; Region = "Central" }
            "Mountain Standard Time" = @{ Country = "US"; Region = "Mountain" }
            "Pacific Standard Time" = @{ Country = "US"; Region = "West Coast" }
            "GMT Standard Time" = @{ Country = "GB"; Region = "London" }
            "Central European Standard Time" = @{ Country = "EU"; Region = "Central Europe" }
            "China Standard Time" = @{ Country = "CN"; Region = "Beijing" }
            "Tokyo Standard Time" = @{ Country = "JP"; Region = "Tokyo" }
            "India Standard Time" = @{ Country = "IN"; Region = "India" }
            "AUS Eastern Standard Time" = @{ Country = "AU"; Region = "Sydney" }
        }
        
        $location = $timezoneMap[$timezone.StandardName]
        if ($location) {
            return @{
                Success = $true
                Method = "Timezone"
                Country = $location.Country
                Region = $location.Region
                Timezone = $timezone.StandardName
            }
        }
        
        return @{
            Success = $false
            Error = "Unknown timezone"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-CountryRequirement {
    param($CurrentCountry, $CurrentCountryCode, $TargetCountry)
    
    # Support both country names and codes
    $match = ($CurrentCountry -eq $TargetCountry) -or 
             ($CurrentCountryCode -eq $TargetCountry) -or
             ($CurrentCountry -like "*$TargetCountry*")
    
    return @{
        CurrentCountry = $CurrentCountry
        CurrentCountryCode = $CurrentCountryCode
        TargetCountry = $TargetCountry
        Match = $match
    }
}

function Test-CityRequirement {
    param($CurrentCity, $TargetCity)
    
    $match = ($CurrentCity -eq $TargetCity) -or
             ($CurrentCity -like "*$TargetCity*")
    
    return @{
        CurrentCity = $CurrentCity
        TargetCity = $TargetCity
        Match = $match
    }
}

function Test-RegionRequirement {
    param($CurrentRegion, $TargetRegion)
    
    $match = ($CurrentRegion -eq $TargetRegion) -or
             ($CurrentRegion -like "*$TargetRegion*")
    
    return @{
        CurrentRegion = $CurrentRegion
        TargetRegion = $TargetRegion
        Match = $match
    }
}

function Test-DistanceRequirement {
    param($CurrentLat, $CurrentLon, $TargetLat, $TargetLon, $MaxDistance)
    
    # Haversine formula for distance calculation
    $R = 6371  # Earth radius in km
    $dLat = ($TargetLat - $CurrentLat) * [Math]::PI / 180
    $dLon = ($TargetLon - $CurrentLon) * [Math]::PI / 180
    $lat1 = $CurrentLat * [Math]::PI / 180
    $lat2 = $TargetLat * [Math]::PI / 180
    
    $a = [Math]::Sin($dLat/2) * [Math]::Sin($dLat/2) + 
         [Math]::Sin($dLon/2) * [Math]::Sin($dLon/2) * 
         [Math]::Cos($lat1) * [Math]::Cos($lat2)
    $c = 2 * [Math]::Atan2([Math]::Sqrt($a), [Math]::Sqrt(1-$a))
    $distance = $R * $c
    
    return @{
        CurrentLocation = "$CurrentLat,$CurrentLon"
        TargetLocation = "$TargetLat,$TargetLon"
        Distance = [Math]::Round($distance, 2)
        MaxDistance = $MaxDistance
        InRange = ($distance -le $MaxDistance)
    }
}

function Invoke-GuardrailAction {
    param($Action, $Reason)
    
    switch ($Action) {
        "exit" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Geolocation check failed: $Reason" -ForegroundColor Red
            }
            exit 2
        }
        "sleep" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Geolocation check failed, sleeping..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3600
            exit 2
        }
        "continue" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Geolocation check failed, continuing anyway" -ForegroundColor Yellow
            }
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1480.001D"
        TechniqueName = "Geolocation Checks"
        Results = @{
            InitialPrivilege = ""
            CurrentLocation = @{}
            LocationChecks = @{}
            ExecutionAllowed = $false
            FailureReason = ""
            ErrorMessage = ""
        }
    }
    
    # Test critical dependencies
    if (-not (Test-CriticalDependencies)) {
        $Config.Results.ErrorMessage = "Failed to load dependencies"
        return $config
    }
    
    # Load environment variables
    $envConfig = Initialize-EnvironmentVariables
    foreach ($key in $envConfig.Keys) {
        $config[$key] = $envConfig[$key]
    }
    
    # Store silent mode globally
    $Global:SilentMode = $Config.SilentMode
    
    # Validate action on fail
    if ($Config.ActionOnFail -notin @("exit", "sleep", "continue")) {
        $Config.ActionOnFail = "exit"
    }
    
    $Config.Success = $true
    return $config
}

function Invoke-MicroTechniqueAction {
    param($Config)
    
    # Get initial privilege level
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $Config.Results.InitialPrivilege = if ($isAdmin) { "Administrator" } else { "User" }
    
    if (-not $Config.SilentMode) {
        Write-Host "[INFO] Checking geolocation requirements..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Get current location
    $location = Get-GeoLocationByIP
    
    if (-not $location.Success) {
        # Fallback to timezone-based location
        $location = Get-GeoLocationByTimezone
    }
    
    if (-not $location.Success) {
        $Config.Results.ErrorMessage = "Failed to determine location"
        $Config.Results.FailureReason = "Could not determine current location"
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Could not determine current location" -ForegroundColor Red
        }
        Invoke-GuardrailAction -Action $Config.ActionOnFail -Reason $Config.Results.FailureReason
        return $Config
    }
    
    $Config.Results.CurrentLocation = $location
    $allChecksPassed = $true
    
    # Check country requirement
    if ($Config.TargetCountry -and $location.Country) {
        $countryCheck = Test-CountryRequirement -CurrentCountry $location.Country `
                                               -CurrentCountryCode $location.CountryCode `
                                               -TargetCountry $Config.TargetCountry
        $Config.Results.LocationChecks.Country = $countryCheck
        
        if (-not $countryCheck.Match) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Wrong country"
        }
    }
    
    # Check city requirement
    if ($Config.TargetCity -and $location.City) {
        $cityCheck = Test-CityRequirement -CurrentCity $location.City -TargetCity $Config.TargetCity
        $Config.Results.LocationChecks.City = $cityCheck
        
        if (-not $cityCheck.Match) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Wrong city"
        }
    }
    
    # Check region requirement
    if ($Config.TargetRegion -and $location.Region) {
        $regionCheck = Test-RegionRequirement -CurrentRegion $location.Region -TargetRegion $Config.TargetRegion
        $Config.Results.LocationChecks.Region = $regionCheck
        
        if (-not $regionCheck.Match) {
            $allChecksPassed = $false
            $Config.Results.FailureReason = "Wrong region"
        }
    }
    
    # Check distance requirement
    if ($Config.TargetLat -ne 0 -and $Config.TargetLon -ne 0 -and $Config.MaxDistance -gt 0) {
        if ($location.Latitude -and $location.Longitude) {
            $distanceCheck = Test-DistanceRequirement -CurrentLat $location.Latitude `
                                                     -CurrentLon $location.Longitude `
                                                     -TargetLat $Config.TargetLat `
                                                     -TargetLon $Config.TargetLon `
                                                     -MaxDistance $Config.MaxDistance
            $Config.Results.LocationChecks.Distance = $distanceCheck
            
            if (-not $distanceCheck.InRange) {
                $allChecksPassed = $false
                $Config.Results.FailureReason = "Outside allowed distance"
            }
        }
    }
    
    $Config.Results.ExecutionAllowed = $allChecksPassed
    
    if (-not $Config.SilentMode) {
        if ($allChecksPassed) {
            Write-Host "[SUCCESS] All geolocation checks passed" -ForegroundColor Green
            Write-Host "    Current location: $($location.City), $($location.Country)" -ForegroundColor Green
        } else {
            Write-Host "[FAILED] Geolocation checks failed" -ForegroundColor Red
            Write-Host "    Reason: $($Config.Results.FailureReason)" -ForegroundColor Red
        }
    }
    
    # Take action if checks failed
    if (-not $allChecksPassed) {
        Invoke-GuardrailAction -Action $Config.ActionOnFail -Reason $Config.Results.FailureReason
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1480.001d_geolocation_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Geolocation Check Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            
            if ($Config.Results.CurrentLocation.Success) {
                $loc = $Config.Results.CurrentLocation
                Write-Host "    Current Location:"
                if ($loc.IP) { Write-Host "      IP: $($loc.IP)" }
                if ($loc.Country) { Write-Host "      Country: $($loc.Country) ($($loc.CountryCode))" }
                if ($loc.City) { Write-Host "      City: $($loc.City)" }
                if ($loc.Region) { Write-Host "      Region: $($loc.Region)" }
                if ($loc.Latitude) { Write-Host "      Coordinates: $($loc.Latitude), $($loc.Longitude)" }
            }
            
            Write-Host "    Checks Performed:"
            foreach ($check in $Config.Results.LocationChecks.Keys) {
                $result = $Config.Results.LocationChecks[$check]
                Write-Host "      $check : $($result.Match)"
            }
            
            Write-Host "    Execution Allowed: $($Config.Results.ExecutionAllowed)"
            if (-not $Config.Results.ExecutionAllowed) {
                Write-Host "    Failure Reason: $($Config.Results.FailureReason)"
                Write-Host "    Action Taken: $($Config.ActionOnFail)"
            }
        }
        
        "debug" {
            $null = New-Item -ItemType Directory -Path $outputDir -Force
            $debugOutput = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Technique = $Config.Technique
                TechniqueName = $Config.TechniqueName
                Platform = "Windows"
                ExecutionResults = $Config.Results
                Configuration = @{
                    TargetCountry = $Config.TargetCountry
                    TargetCity = $Config.TargetCity
                    TargetRegion = $Config.TargetRegion
                    TargetCoordinates = if ($Config.TargetLat -ne 0) { "$($Config.TargetLat),$($Config.TargetLon)" } else { "N/A" }
                    MaxDistance = $Config.MaxDistance
                    ActionOnFail = $Config.ActionOnFail
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    Timezone = [System.TimeZoneInfo]::Local.DisplayName
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1480_001d_geolocation.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }
        
        "stealth" {
            # Silent operation
        }
    }
}

function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED/GUARDRAIL
    
    # Step 1: Get configuration
    $Config = Get-Configuration
    if (-not $Config.Success) {
        Write-Host "[ERROR] $($Config.Results.ErrorMessage)" -ForegroundColor Red
        exit 1
    }
    
    # Step 2: Execute micro-technique
    $config = Invoke-MicroTechniqueAction -Config $config
    
    # Step 3: Write output
    Write-StandardizedOutput -Config $config
    
    # Return appropriate exit code
    if ($Config.Results.ExecutionAllowed) {
        exit 0
    } else {
        # Note: If action is "exit" or "sleep", we won't reach here
        exit 2
    }
}

# Execute main function
Main

