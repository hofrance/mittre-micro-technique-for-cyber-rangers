# T1564.001A - Hidden Files and Directories
# MITRE ATT&CK Technique: T1564 - Hide Artifacts
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # File system manipulation capabilities
    return $true
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        TargetPath = if ($env:T1564_001A_TARGET_PATH) { $env:T1564_001A_TARGET_PATH } else { "" }
        HideMethod = if ($env:T1564_001A_HIDE_METHOD) { $env:T1564_001A_HIDE_METHOD } else { "attributes" }
        CreateSample = if ($env:T1564_001A_CREATE_SAMPLE -eq "true") { $true } else { $false }
        OutputMode = if ($env:T1564_001A_OUTPUT_MODE) { $env:T1564_001A_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1564_001A_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Hide-FileUsingAttributes {
    param($Path)
    
    try {
        if (Test-Path $Path) {
            # Get current attributes
            $item = Get-Item $Path -Force
            $originalAttributes = $item.Attributes
            
            # Set hidden and system attributes
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::System
            
            # Verify the change
            $newAttributes = (Get-Item $Path -Force).Attributes
            
            return @{
                Success = $true
                Path = $Path
                OriginalAttributes = $originalAttributes
                NewAttributes = $newAttributes
                IsHidden = ($newAttributes -band [System.IO.FileAttributes]::Hidden) -ne 0
                IsSystem = ($newAttributes -band [System.IO.FileAttributes]::System) -ne 0
            }
        }
        else {
            return @{
                Success = $false
                Error = "Path does not exist"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Hide-FileUsingDollarSign {
    param($Path)
    
    try {
        # Create a file/folder with $ at the end (hidden in network shares)
        $directory = [System.IO.Path]::GetDirectoryName($Path)
        $filename = [System.IO.Path]::GetFileName($Path)
        $hiddenName = "$filename$"
        $hiddenPath = Join-Path $directory $hiddenName
        
        if (Test-Path $Path) {
            # If it's a file
            if ((Get-Item $Path).PSIsContainer -eq $false) {
                Copy-Item -Path $Path -Destination $hiddenPath -Force
            }
            else {
                # If it's a directory
                Copy-Item -Path $Path -Destination $hiddenPath -Recurse -Force
            }
            
            return @{
                Success = $true
                OriginalPath = $Path
                HiddenPath = $hiddenPath
                Method = "Dollar Sign Suffix"
                Description = "File/folder ending with $ is hidden in network shares"
            }
        }
        else {
            # Create new hidden item
            if ($Path -match "\.[^\\]*$") {
                # It's a file
                New-Item -Path $hiddenPath -ItemType File -Force | Out-Null
            }
            else {
                # It's a directory
                New-Item -Path $hiddenPath -ItemType Directory -Force | Out-Null
            }
            
            return @{
                Success = $true
                HiddenPath = $hiddenPath
                Method = "Dollar Sign Suffix"
                Created = $true
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Hide-FileUsingDotPrefix {
    param($Path)
    
    try {
        # Create a file/folder with . prefix (Unix-style hidden)
        $directory = [System.IO.Path]::GetDirectoryName($Path)
        $filename = [System.IO.Path]::GetFileName($Path)
        $hiddenName = ".$filename"
        $hiddenPath = Join-Path $directory $hiddenName
        
        if (Test-Path $Path) {
            if ((Get-Item $Path).PSIsContainer -eq $false) {
                Copy-Item -Path $Path -Destination $hiddenPath -Force
            }
            else {
                Copy-Item -Path $Path -Destination $hiddenPath -Recurse -Force
            }
            
            # Also set hidden attribute
            $item = Get-Item $hiddenPath -Force
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
            
            return @{
                Success = $true
                OriginalPath = $Path
                HiddenPath = $hiddenPath
                Method = "Dot Prefix"
                Description = "File/folder starting with . is hidden in some contexts"
            }
        }
        else {
            # Create new hidden item
            if ($Path -match "\.[^\\]*$") {
                New-Item -Path $hiddenPath -ItemType File -Force | Out-Null
            }
            else {
                New-Item -Path $hiddenPath -ItemType Directory -Force | Out-Null
            }
            
            # Set hidden attribute
            $item = Get-Item $hiddenPath -Force
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
            
            return @{
                Success = $true
                HiddenPath = $hiddenPath
                Method = "Dot Prefix"
                Created = $true
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Hide-InSystemDirectory {
    param($SourcePath, $SystemDir)
    
    try {
        # Common system directories where files are less likely to be noticed
        $systemDirs = @{
            "temp" = $env:TEMP
            "appdata" = $env:APPDATA
            "localappdata" = $env:LOCALAPPDATA
            "programdata" = $env:ProgramData
            "windows_temp" = "C:\Windows\Temp"
            "windows_tasks" = "C:\Windows\Tasks"
            "windows_debug" = "C:\Windows\Debug"
        }
        
        $targetDir = if ($SystemDir -and $systemDirs.ContainsKey($SystemDir)) {
            $systemDirs[$SystemDir]
        } else {
            $systemDirs["temp"]
        }
        
        # Create subdirectory with legitimate-looking name
        $subDirs = @("cache", "logs", "temp", "data", "config", "settings")
        $subDir = Get-Random -InputObject $subDirs
        $hiddenDir = Join-Path $targetDir $subDir
        
        if (-not (Test-Path $hiddenDir)) {
            New-Item -Path $hiddenDir -ItemType Directory -Force | Out-Null
        }
        
        # Copy file with legitimate-looking name
        $legitimateNames = @("svchost", "update", "config", "service", "system", "temp")
        $newName = (Get-Random -InputObject $legitimateNames) + "_" + (Get-Random -Maximum 9999)
        
        if ($SourcePath -and (Test-Path $SourcePath)) {
            $extension = [System.IO.Path]::GetExtension($SourcePath)
            $hiddenPath = Join-Path $hiddenDir "$newName$extension"
            Copy-Item -Path $SourcePath -Destination $hiddenPath -Force
        }
        else {
            $hiddenPath = Join-Path $hiddenDir "$newName.dat"
            New-Item -Path $hiddenPath -ItemType File -Force | Out-Null
        }
        
        # Set hidden attribute
        $item = Get-Item $hiddenPath -Force
        $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
        
        return @{
            Success = $true
            HiddenPath = $hiddenPath
            SystemDirectory = $targetDir
            Method = "System Directory Hiding"
            Description = "File hidden in system directory with legitimate name"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Create-SampleArtifacts {
    param($BaseDir)
    
    try {
        $samples = @()
        
        # Create sample malware directory
        $malwareDir = Join-Path $BaseDir "malware_test"
        New-Item -Path $malwareDir -ItemType Directory -Force | Out-Null
        
        # Create sample files
        $sampleFiles = @(
            @{Name="payload.exe"; Content="MZ`u{0}`u{0}This program cannot be run in DOS mode."},
            @{Name="config.dat"; Content="server=192.168.1.100`nport=4444`nkey=secret123"},
            @{Name="keylog.txt"; Content="[KEYLOGGER DATA]`n2024-01-01 10:00:00 - User activity logged"}
        )
        
        foreach ($file in $sampleFiles) {
            $filePath = Join-Path $malwareDir $file.Name
            Set-Content -Path $filePath -Value $file.Content
            $samples += $filePath
        }
        
        return @{
            Success = $true
            BaseDirectory = $malwareDir
            SampleFiles = $samples
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1564.001A"
        TechniqueName = "Hidden Files and Directories"
        Results = @{
            InitialPrivilege = ""
            HiddenArtifacts = @()
            SampleArtifacts = @()
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
    
    # Validate hide method
    if ($Config.HideMethod -notin @("attributes", "dollar", "dot", "system", "all")) {
        $Config.HideMethod = "attributes"
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
        Write-Host "[INFO] Creating hidden files and directories..." -ForegroundColor Yellow
    }
    
    # Create sample artifacts if needed
    if ($Config.CreateSample -or -not $Config.TargetPath) {
        $sampleResult = Create-SampleArtifacts -BaseDir $Config.OutputBase
        if ($sampleResult.Success) {
            $Config.Results.SampleArtifacts = $sampleResult.SampleFiles
            $Config.TargetPath = $sampleResult.BaseDirectory
        }
    }
    
    # ATOMIC ACTION: Hide artifacts
    $results = @()
    
    if ($Config.HideMethod -eq "all") {
        # Try all methods
        $methods = @("attributes", "dollar", "dot", "system")
        foreach ($method in $methods) {
            $targetPath = if ($Config.Results.SampleArtifacts.Count -gt 0) {
                $Config.Results.SampleArtifacts[0]
            } else {
                $Config.TargetPath
            }
            
            $result = switch ($method) {
                "attributes" { Hide-FileUsingAttributes -Path $targetPath }
                "dollar" { Hide-FileUsingDollarSign -Path $targetPath }
                "dot" { Hide-FileUsingDotPrefix -Path $targetPath }
                "system" { Hide-InSystemDirectory -SourcePath $targetPath -SystemDir "temp" }
            }
            
            if ($result.Success) {
                $results += $result
            }
        }
    }
    else {
        # Use specific method
        $result = switch ($Config.HideMethod) {
            "attributes" { Hide-FileUsingAttributes -Path $Config.TargetPath }
            "dollar" { Hide-FileUsingDollarSign -Path $Config.TargetPath }
            "dot" { Hide-FileUsingDotPrefix -Path $Config.TargetPath }
            "system" { Hide-InSystemDirectory -SourcePath $Config.TargetPath -SystemDir "temp" }
        }
        
        if ($result.Success) {
            $results += $result
        }
    }
    
    $Config.Results.HiddenArtifacts = $results
    
    if ($results.Count -gt 0) {
        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] Successfully hidden $($results.Count) artifact(s)" -ForegroundColor Green
            foreach ($result in $results) {
                if ($result.HiddenPath) {
                    Write-Host "    Hidden: $($result.HiddenPath)" -ForegroundColor Green
                }
            }
        }
    }
    else {
        $Config.Results.ErrorMessage = "Failed to hide any artifacts"
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Failed to hide artifacts" -ForegroundColor Red
        }
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1564.001a_hidden_files_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Hidden Files and Directories Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Hide Method: $($Config.HideMethod)"
            
            if ($Config.Results.SampleArtifacts.Count -gt 0) {
                Write-Host "    Sample Artifacts Created: $($Config.Results.SampleArtifacts.Count)"
            }
            
            Write-Host "    Hidden Artifacts: $($Config.Results.HiddenArtifacts.Count)"
            foreach ($artifact in $Config.Results.HiddenArtifacts) {
                Write-Host "      Method: $($artifact.Method)"
                if ($artifact.HiddenPath) {
                    Write-Host "      Path: $($artifact.HiddenPath)"
                }
                if ($artifact.IsHidden) {
                    Write-Host "      Hidden: $($artifact.IsHidden)"
                }
                if ($artifact.IsSystem) {
                    Write-Host "      System: $($artifact.IsSystem)"
                }
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
                    TargetPath = $Config.TargetPath
                    HideMethod = $Config.HideMethod
                    CreateSample = $Config.CreateSample
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                    ProcessId = $PID
                }
            }
            $debugOutput | ConvertTo-Json -Depth 5 | Out-File "$outputDir\t1564_001a_hidden_files.json"
            Write-Host "[DEBUG] Results saved to: $outputDir" -ForegroundColor Cyan
        }
        
        "stealth" {
            # Silent operation
        }
    }
}

function Main {
    # Exit codes: 0=SUCCESS, 1=FAILED, 2=SKIPPED
    
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
    if ($Config.Results.HiddenArtifacts.Count -gt 0) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

