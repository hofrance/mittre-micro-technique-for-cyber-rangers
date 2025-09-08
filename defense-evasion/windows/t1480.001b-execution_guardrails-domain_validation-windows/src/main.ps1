# T1480.001B - Domain Validation
# MITRE ATT&CK Technique: T1480 - Execution Guardrails
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # .NET networking support
    try {
        Add-Type -AssemblyName System.DirectoryServices
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        return $true
    } catch {
        return $false
    }
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        TargetDomain = if ($env:T1480_001B_TARGET_DOMAIN) { $env:T1480_001B_TARGET_DOMAIN } else { "" }
        DomainController = if ($env:T1480_001B_DOMAIN_CONTROLLER) { $env:T1480_001B_DOMAIN_CONTROLLER } else { "" }
        CheckType = if ($env:T1480_001B_CHECK_TYPE) { $env:T1480_001B_CHECK_TYPE } else { "membership" }
        ActionOnFail = if ($env:T1480_001B_ACTION_ON_FAIL) { $env:T1480_001B_ACTION_ON_FAIL } else { "exit" }
        OutputMode = if ($env:T1480_001B_OUTPUT_MODE) { $env:T1480_001B_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1480_001B_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Test-DomainMembership {
    param($TargetDomain)
    
    try {
        # Get current computer domain
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $currentDomain = $computerSystem.Domain
        $isDomainJoined = $computerSystem.PartOfDomain
        
        if (-not $isDomainJoined) {
            return @{
                Success = $true
                IsDomainJoined = $false
                CurrentDomain = "WORKGROUP"
                TargetDomain = $TargetDomain
                Match = $false
            }
        }
        
        # Compare domains
        $match = $currentDomain -eq $TargetDomain -or 
                 $currentDomain -like "*.$TargetDomain" -or
                 $TargetDomain -like "*.$currentDomain"
        
        return @{
            Success = $true
            IsDomainJoined = $true
            CurrentDomain = $currentDomain
            TargetDomain = $TargetDomain
            Match = $match
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Match = $false
        }
    }
}

function Test-DomainController {
    param($DomainController)
    
    try {
        # Try to resolve DC
        $resolved = $false
        $ipAddress = $null
        
        try {
            $dns = [System.Net.Dns]::GetHostEntry($DomainController)
            $ipAddress = $dns.AddressList[0].ToString()
            $resolved = $true
        } catch {
            $resolved = $false
        }
        
        # Try to ping DC
        $pingable = $false
        if ($resolved) {
            $ping = Test-Connection -ComputerName $DomainController -Count 1 -Quiet
            $pingable = $ping
        }
        
        # Try LDAP connection
        $ldapReachable = $false
        if ($resolved) {
            try {
                $ldapPath = "LDAP://$DomainController"
                $entry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)
                $searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
                $searcher.SearchScope = "Base"
                $searcher.Filter = "(objectClass=*)"
                $result = $searcher.FindOne()
                $ldapReachable = ($null -ne $result)
                $entry.Close()
            } catch {
                $ldapReachable = $false
            }
        }
        
        return @{
            Success = $true
            DomainController = $DomainController
            Resolved = $resolved
            IPAddress = $ipAddress
            Pingable = $pingable
            LDAPReachable = $ldapReachable
            IsValid = ($resolved -and ($pingable -or $ldapReachable))
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            IsValid = $false
        }
    }
}

function Test-DomainTrust {
    param($TargetDomain)
    
    try {
        # Get current domain
        $currentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        
        # Get domain trusts
        $trusts = $currentDomain.GetAllTrustRelationships()
        
        $trustedDomains = @()
        foreach ($trust in $trusts) {
            $trustedDomains += $trust.TargetName
        }
        
        $isTrusted = $trustedDomains -contains $TargetDomain
        
        return @{
            Success = $true
            CurrentDomain = $currentDomain.Name
            TrustedDomains = $trustedDomains
            TargetDomain = $TargetDomain
            IsTrusted = $isTrusted
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            IsTrusted = $false
        }
    }
}

function Test-DomainUser {
    param($TargetDomain)
    
    try {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $userDomain = $currentUser.Name.Split('\')[0]
        
        # Check if user is from target domain
        $isFromDomain = $userDomain -eq $TargetDomain -or
                       $userDomain -eq $TargetDomain.Split('.')[0]
        
        # Try to validate against domain
        $validated = $false
        if ($isFromDomain) {
            try {
                $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
                    [System.DirectoryServices.AccountManagement.ContextType]::Domain,
                    $TargetDomain
                )
                $validated = $context.ValidateCredentials($currentUser.Name.Split('\')[1], $null)
                $context.Dispose()
            } catch {
                $validated = $false
            }
        }
        
        return @{
            Success = $true
            CurrentUser = $currentUser.Name
            UserDomain = $userDomain
            TargetDomain = $TargetDomain
            IsFromDomain = $isFromDomain
            Validated = $validated
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            IsFromDomain = $false
        }
    }
}

function Invoke-GuardrailAction {
    param($Action, $Reason)
    
    switch ($Action) {
        "exit" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Domain validation failed: $Reason" -ForegroundColor Red
            }
            exit 2
        }
        "sleep" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Domain validation failed, sleeping..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3600
            exit 2
        }
        "continue" {
            if (-not $Global:SilentMode) {
                Write-Host "[GUARDRAIL] Domain validation failed, continuing anyway" -ForegroundColor Yellow
            }
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1480.001B"
        TechniqueName = "Domain Validation"
        Results = @{
            InitialPrivilege = ""
            DomainChecks = @{}
            ValidationPassed = $false
            FailureReason = ""
            ErrorMessage = ""
        }
    }
    
    # Test critical dependencies
    if (-not (Test-CriticalDependencies)) {
        $Config.Results.ErrorMessage = "Failed to load Active Directory dependencies"
        return $config
    }
    
    # Load environment variables
    $envConfig = Initialize-EnvironmentVariables
    foreach ($key in $envConfig.Keys) {
        $config[$key] = $envConfig[$key]
    }
    
    # Store silent mode globally
    $Global:SilentMode = $Config.SilentMode
    
    # Validate check type
    if ($Config.CheckType -notin @("membership", "controller", "trust", "user", "all")) {
        $Config.CheckType = "membership"
    }
    
    # Set default target domain if not specified
    if (-not $Config.TargetDomain) {
        try {
            $Config.TargetDomain = $env:USERDNSDOMAIN
            if (-not $Config.TargetDomain) {
                $Config.TargetDomain = (Get-WmiObject Win32_ComputerSystem).Domain
            }
        } catch {
            $Config.TargetDomain = "WORKGROUP"
        }
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
        Write-Host "[INFO] Validating domain requirements..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Validate domain
    $validationPassed = $true
    
    # Check domain membership
    if ($Config.CheckType -eq "membership" -or $Config.CheckType -eq "all") {
        $membershipCheck = Test-DomainMembership -TargetDomain $Config.TargetDomain
        $Config.Results.DomainChecks.Membership = $membershipCheck
        
        if (-not $membershipCheck.Match) {
            $validationPassed = $false
            $Config.Results.FailureReason = "Not member of target domain"
        }
    }
    
    # Check domain controller
    if (($Config.CheckType -eq "controller" -or $Config.CheckType -eq "all") -and $Config.DomainController) {
        $dcCheck = Test-DomainController -DomainController $Config.DomainController
        $Config.Results.DomainChecks.DomainController = $dcCheck
        
        if (-not $dcCheck.IsValid) {
            $validationPassed = $false
            $Config.Results.FailureReason = "Cannot reach domain controller"
        }
    }
    
    # Check domain trust
    if ($Config.CheckType -eq "trust" -or $Config.CheckType -eq "all") {
        $trustCheck = Test-DomainTrust -TargetDomain $Config.TargetDomain
        $Config.Results.DomainChecks.Trust = $trustCheck
        
        if (-not $trustCheck.IsTrusted -and $trustCheck.Success) {
            $validationPassed = $false
            $Config.Results.FailureReason = "Domain is not trusted"
        }
    }
    
    # Check domain user
    if ($Config.CheckType -eq "user" -or $Config.CheckType -eq "all") {
        $userCheck = Test-DomainUser -TargetDomain $Config.TargetDomain
        $Config.Results.DomainChecks.User = $userCheck
        
        if (-not $userCheck.IsFromDomain) {
            $validationPassed = $false
            $Config.Results.FailureReason = "User not from target domain"
        }
    }
    
    $Config.Results.ValidationPassed = $validationPassed
    
    if (-not $Config.SilentMode) {
        if ($validationPassed) {
            Write-Host "[SUCCESS] Domain validation passed" -ForegroundColor Green
            Write-Host "    Target domain: $($Config.TargetDomain)" -ForegroundColor Green
        } else {
            Write-Host "[FAILED] Domain validation failed" -ForegroundColor Red
            Write-Host "    Reason: $($Config.Results.FailureReason)" -ForegroundColor Red
        }
    }
    
    # Take action if validation failed
    if (-not $validationPassed) {
        Invoke-GuardrailAction -Action $Config.ActionOnFail -Reason $Config.Results.FailureReason
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1480.001b_domain_valid_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Domain Validation Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Target Domain: $($Config.TargetDomain)"
            Write-Host "    Check Type: $($Config.CheckType)"
            Write-Host "    Validation Passed: $($Config.Results.ValidationPassed)"
            
            foreach ($check in $Config.Results.DomainChecks.Keys) {
                $result = $Config.Results.DomainChecks[$check]
                if ($result.Success) {
                    Write-Host "    $check Check: " -NoNewline
                    
                    switch ($check) {
                        "Membership" { Write-Host $result.Match }
                        "DomainController" { Write-Host $result.IsValid }
                        "Trust" { Write-Host $result.IsTrusted }
                        "User" { Write-Host $result.IsFromDomain }
                    }
                }
            }
            
            if (-not $Config.Results.ValidationPassed) {
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
                    TargetDomain = $Config.TargetDomain
                    DomainController = $Config.DomainController
                    CheckType = $Config.CheckType
                    ActionOnFail = $Config.ActionOnFail
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    Domain = $env:USERDNSDOMAIN
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1480_001b_domain_valid.json"
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
    if ($Config.Results.ValidationPassed) {
        exit 0
    } else {
        # Note: If action is "exit" or "sleep", we won't reach here
        exit 2
    }
}

# Execute main function
Main

