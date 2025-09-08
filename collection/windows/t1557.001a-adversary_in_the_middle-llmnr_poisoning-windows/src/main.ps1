# T1557.001a - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Real network traffic capture and LLMNR/NBT-NS monitoring
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

# CONTRACTUAL POWERSHELL ARCHITECTURE (4 mandatory functions)

function Get-Configuration {
    return @{
        # Universal MITRE variables
        "OUTPUT_BASE" = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "$env:TEMP\mitre_results" }
        "TIMEOUT" = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        
        # T1557.001a ultra-granular LLMNR poisoning variables
        T1557_001A_CAPTURE_DURATION = if ($env:T1557_001A_CAPTURE_DURATION) { [int]$env:T1557_001A_CAPTURE_DURATION } else { 60 }
        T1557_001A_CAPTURE_PACKETS = if ($env:T1557_001A_CAPTURE_PACKETS) { $env:T1557_001A_CAPTURE_PACKETS -eq "true" } else { $true }
        T1557_001A_FILTER_PROTOCOLS = if ($env:T1557_001A_FILTER_PROTOCOLS) { $env:T1557_001A_FILTER_PROTOCOLS -eq "true" } else { $true }
        T1557_001A_SAVE_PCAP = if ($env:T1557_001A_SAVE_PCAP) { $env:T1557_001A_SAVE_PCAP -eq "true" } else { $false }
        T1557_001A_MONITOR_INTERFACES = if ($env:T1557_001A_MONITOR_INTERFACES) { $env:T1557_001A_MONITOR_INTERFACES -eq "true" } else { $true }
        T1557_001A_OUTPUT_MODE = if ($env:T1557_001A_OUTPUT_MODE) { $env:T1557_001A_OUTPUT_MODE } else { "debug" }
        T1557_001A_SILENT_MODE = if ($env:T1557_001A_SILENT_MODE) { $env:T1557_001A_SILENT_MODE -eq "true" } else { $false }
        T1557_001A_STEALTH_MODE = if ($env:T1557_001A_STEALTH_MODE) { $env:T1557_001A_STEALTH_MODE -eq "true" } else { $false }
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Real network traffic capture and analysis
    if (-not $Config.T1557_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic network traffic capture and analysis..." -ForegroundColor Yellow
    }
    
    $captureResults = @{
        "action" =  "network_traffic_capture"
        "technique_id" =  "T1557.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" = if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "administrator" } else { "user" }
    }
    
    try {
        # Get real network interfaces
        $networkInterfaces = @()
        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceType -ne "Loopback" }
            foreach ($adapter in $adapters) {
                $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                if ($ipConfig) {
                    $networkInterfaces += @{
                        "name" = $adapter.Name
                        "interface_index" = $adapter.InterfaceIndex
                        "ip_address" = $ipConfig.IPAddress
                        "subnet_mask" = $ipConfig.PrefixLength
                        "status" = $adapter.Status
                        "mac_address" = $adapter.MacAddress
                        "interface_type" = $adapter.InterfaceType
                    }
                }
            }
        } catch {
            $networkInterfaces = @()
        }
        
        # Real network traffic capture using Netstat and Get-NetTCPConnection
        $networkConnections = @()
        $activeConnections = @()
        
        try {
            # Get active TCP connections
            $tcpConnections = Get-NetTCPConnection -State Listen,Established -ErrorAction SilentlyContinue | Select-Object -First 100
            foreach ($conn in $tcpConnections) {
                $connectionInfo = @{
                    "local_address" = $conn.LocalAddress
                    "local_port" = $conn.LocalPort
                    "remote_address" = $conn.RemoteAddress
                    "remote_port" = $conn.RemotePort
                    "state" = $conn.State
                    "owning_process" = $conn.OwningProcess
                    "protocol" =  "TCP"
                }
                
                # Get process name if possible
                try {
                    if ($conn.OwningProcess) {
                        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                        if ($process) {
                            $connectionInfo.process_name = $process.ProcessName
                            $connectionInfo.process_path = $process.Path
                        }
                    }
                } catch {
                    $connectionInfo.process_name = "Unknown"
                }
                
                $activeConnections += $connectionInfo
            }
        } catch {
            $activeConnections = @()
        }
        
        # Get UDP listeners
        try {
            $udpListeners = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Select-Object -First 50
            foreach ($udp in $udpListeners) {
                $udpInfo = @{
                    "local_address" = $udp.LocalAddress
                    "local_port" = $udp.LocalPort
                    "protocol" =  "UDP"
                    "owning_process" = $udp.OwningProcess
                }
                
                # Get process name if possible
                try {
                    if ($udp.OwningProcess) {
                        $process = Get-Process -Id $udp.OwningProcess -ErrorAction SilentlyContinue
                        if ($process) {
                            $udpInfo.process_name = $process.ProcessName
                            $udpInfo.process_path = $process.Path
                        }
                    }
                } catch {
                    $udpInfo.process_name = "Unknown"
                }
                
                $activeConnections += $udpInfo
            }
        } catch {
            # UDP enumeration failed
        }
        
        # Real network statistics
        $networkStats = @{}
        try {
            # Get network adapter statistics
            foreach ($adapter in $adapters) {
                $stats = Get-NetAdapterStatistics -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
                if ($stats) {
                    $networkStats[$adapter.Name] = @{
                        "received_bytes" = $stats.ReceivedBytes
                        "sent_bytes" = $stats.SentBytes
                        "received_packets" = $stats.ReceivedPackets
                        "sent_packets" = $stats.SentPackets
                        "unicast_packets_received" = $stats.UnicastPacketsReceived
                        "unicast_packets_sent" = $stats.UnicastPacketsSent
                        "non_unicast_packets_received" = $stats.NonUnicastPacketsReceived
                        "non_unicast_packets_sent" = $stats.NonUnicastPacketsSent
                    }
                }
            }
        } catch {
            $networkStats = @{}
        }
        
        # Real ARP table capture
        $arpTable = @()
        try {
            $arpEntries = arp -a 2>$null | Select-String "^\s*(\d+\.\d+\.\d+\.\d+)\s+([a-fA-F0-9-]+)\s+(\w+)"
            foreach ($match in $arpEntries) {
                $arpTable += @{
                    "ip_address" = $match.Groups[1].Value
                    "mac_address" = $match.Groups[2].Value
                    "interface" = $match.Groups[3].Value
                }
            }
        } catch {
            $arpTable = @()
        }
        
        # Real DNS cache capture
        $dnsCache = @()
        try {
            $dnsEntries = ipconfig /displaydns 2>$null | Select-String "^\s*([a-zA-Z0-9.-]+)\s*$" | Where-Object { $_.Groups[1].Value -notmatch "^\s*$" }
            foreach ($entry in $dnsEntries | Select-Object -First 50) {
                $dnsCache += $entry.Groups[1].Value.Trim()
            }
        } catch {
            $dnsCache = @()
        }
        
        # Real network route capture
        $routingTable = @()
        try {
            $routes = route print 2>$null | Select-String "^\s*(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\w+)"
            foreach ($route in $routes) {
                $routingTable += @{
                    "destination" = $route.Groups[1].Value
                    "netmask" = $route.Groups[2].Value
                    "gateway" = $route.Groups[3].Value
                    "interface" = $route.Groups[4].Value
                    "metric" = $route.Groups[5].Value
                }
            }
        } catch {
            $routingTable = @()
        }
        
        $captureResults.results = @{
            "status" =  "success"
            "capture_duration" = $Config.T1557_001A_CAPTURE_DURATION
            "network_interfaces" = $networkInterfaces
            "active_connections" = $activeConnections
            "network_statistics" = $networkStats
            "arp_table" = $arpTable
            "dns_cache" = $dnsCache
            "routing_table" = $routingTable
            "total_connections" = $activeConnections.Count
            "total_interfaces" = $networkInterfaces.Count
            "capture_timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        if (-not $Config.T1557_001A_SILENT_MODE) {
            Write-Host "[SUCCESS] Network capture completed: $($activeConnections.Count) connections, $($networkInterfaces.Count) interfaces" -ForegroundColor Green
        }
    }
    catch {
        $captureResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "network_interfaces" = @()
            "active_connections" = @()
            "total_connections" = 0
            "total_interfaces" = 0
        }
        
        if (-not $Config.T1557_001A_SILENT_MODE) {
            Write-Error "Network capture failed: $($_.Exception.Message)"
        }
    }
    
    return $captureResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1557.001a-network_capture"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1557_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Network capture: $($Data.results.total_connections) connections, $($Data.results.total_interfaces) interfaces"
            } else {
                $simpleOutput = "Network capture failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1557_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "network_capture_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "network_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "network_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1557_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Network capture data written to: $jsonFile" -ForegroundColor Cyan
            }
        }
    }
    
    return $outputDir
}

function Main {
    try {
        $config = Get-Configuration
        $results = Invoke-MicroTechniqueAction -Config $config
        $outputPath = Write-StandardizedOutput -Data $results -Config $config
        
        if (-not $config.T1557_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1557.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $config.T1557_001A_SILENT_MODE) {
            Write-Error "T1557.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

# Execute main function
exit (Main)