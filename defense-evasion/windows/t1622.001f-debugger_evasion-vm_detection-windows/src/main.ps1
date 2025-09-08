# MITRE ATT&CK T1622.001F - Debugger Evasion: VM Detection
param()
function Check-VMEnvironment {
    try {
        # Check for VM indicators
        $vmIndicators = @(
            @{ Name = "VMware"; Check = { (Get-WmiObject Win32_ComputerSystem).Manufacturer -match "VMware" } }
            @{ Name = "VirtualBox"; Check = { (Get-WmiObject Win32_ComputerSystem).Model -match "VirtualBox" } }
            @{ Name = "Hyper-V"; Check = { (Get-WmiObject Win32_ComputerSystem).Manufacturer -match "Microsoft" -and (Get-Service | Where-Object { $_.Name -eq "vmms" }) } }
        )
        
        $vmDetected = $false
        $detectedVM = ""
        
        foreach ($indicator in $vmIndicators) {
            if (& $indicator.Check) {
                $vmDetected = $true
                $detectedVM = $indicator.Name
                break
            }
        }
        
        $vmCheck = @{
            "VMDetected" = $vmDetected
            "DetectedVMType" = $detectedVM
            "CheckResult" = if ($vmDetected) { "VM environment detected" } else { "Physical environment detected" }
        }
        
        if ($vmDetected) {
            Write-Host "T1622.001F: VM detection completed - VM environment detected: $detectedVM" -ForegroundColor Yellow
        } else {
            Write-Host "T1622.001F: VM detection completed - Physical environment detected" -ForegroundColor Green
        }
        
        return @{ Success = $true; VMInfo = $vmCheck }
    } catch {
        Write-Host "T1622.001F: VM detection failed" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
$result = Check-VMEnvironment
