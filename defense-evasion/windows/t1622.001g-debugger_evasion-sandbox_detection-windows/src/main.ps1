# MITRE ATT&CK T1622.001G - Debugger Evasion: Sandbox Detection
param()
function Check-SandboxEnvironment {
    try {
        # Check for sandbox indicators
        $sandboxIndicators = @(
            @{ Name = "Username"; Check = { $env:USERNAME -match "(sandbox|test|user|john|admin)" } }
            @{ Name = "ComputerName"; Check = { $env:COMPUTERNAME -match "(sandbox|test|vm|virtual)" } }
            @{ Name = "ProcessCount"; Check = { (Get-Process).Count -lt 20 } }
            @{ Name = "ServiceCount"; Check = { (Get-Service).Count -lt 50 } }
            @{ Name = "LowMemory"; Check = { (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -lt 2GB } }
        )
        
        $sandboxDetected = $false
        $detectedIndicators = @()
        
        foreach ($indicator in $sandboxIndicators) {
            if (& $indicator.Check) {
                $sandboxDetected = $true
                $detectedIndicators += $indicator.Name
            }
        }
        
        $sandboxCheck = @{
            "SandboxDetected" = $sandboxDetected
            "DetectedIndicators" = $detectedIndicators
            "CheckResult" = if ($sandboxDetected) { "Sandbox environment detected" } else { "Normal environment detected" }
        }
        
        if ($sandboxDetected) {
            Write-Host "T1622.001G: Sandbox detection completed - Sandbox indicators detected: $($detectedIndicators -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "T1622.001G: Sandbox detection completed - Normal environment detected" -ForegroundColor Green
        }
        
        return @{ Success = $true; SandboxInfo = $sandboxCheck }
    } catch {
        Write-Host "T1622.001G: Sandbox detection failed" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
$result = Check-SandboxEnvironment
