# T1113.001a - Screen Capture: Single Screenshot
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Capture single screenshot ONLY
# Platform: Windows | Privilege: User | Type: Atomic Package
#
# CONTRACT:  T1113.001a, capture_screenshot, .NET_System_Drawing, user, internal,
#           windows_os + .net_available, screenshot_file_created, simple/debug/stealth/silent, high, 0/1/2 

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1113.001a - REAL ATTACK MODE - High quality screenshot capture
        T1113_001A_IMAGE_FORMAT = "png"
        T1113_001A_IMAGE_QUALITY = 100
        T1113_001A_INCLUDE_CURSOR = $true
        T1113_001A_FULL_SCREEN = $true
        T1113_001A_TIMESTAMP_FILENAME = $true
        T1113_001A_OUTPUT_MODE = "debug"
        T1113_001A_SILENT_MODE = $false
        T1113_001A_SIMULATE_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)

    # ATOMIC ACTION: Single screenshot capture ONLY
    if (-not $Config.T1113_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic screenshot capture..." -ForegroundColor Yellow
    }

    $screenshotResults = @{
        "action" =  "single_screenshot_capture"
        "technique_id" =  "T1113.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }

    try {
        # PRECONDITION: Check Windows OS and .NET availability
        if (-not ([Environment]::OSVersion.Platform -eq "Win32NT")) {
            $screenshotResults.results = @{
                "status" =  "SKIPPED_PRECONDITION"
                "error" =  "Windows OS required for screenshot capture"
                "contract_violation" =  "os_compatibility"
            }
            return $screenshotResults
        }

        # PRECONDITION: Check .NET assemblies
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        }
        catch {
            $screenshotResults.results = @{
                "status" =  "SKIPPED_PRECONDITION"
                "error" =  ".NET Drawing assemblies not available"
                "contract_violation" =  "dependency_availability"
            }
            return $screenshotResults
        }

        # SIMULATION MODE (Contract-compliant testing)
        if ($Config.T1113_001A_SIMULATE_MODE) {
            $screenshotResults.results = @{
                "status" =  "SUCCESS"
                "mode" =  "SIMULATION"
                "simulated_capture" =  "screenshot_simulation.png"
                "screen_resolution" =  "1920x1080"
                "file_size_bytes" = 1024000
                "performance_metrics" = @{
                    "duration_seconds" = 0.1
                    "simulated_capture_rate" =  "10MB/s"
                }
            }
            $screenshotResults.postconditions = @{
                "artifact_created" = $true
                "state_transition" =  "simulated_screenshot_captured"
                "file_generated" = $true
            }
            return $screenshotResults
        }

        # ATOMIC ACTION EXECUTION: Capture single screenshot
        $startTime = Get-Date

        # Get screen bounds
        $bounds = [Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = New-Object Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [Drawing.Graphics]::FromImage($bitmap)

        try {
            # Capture the screen
            $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.Size)

            # Generate filename with timestamp if requested
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $filename = if ($Config.T1113_001A_TIMESTAMP_FILENAME) {
                "screenshot_${timestamp}.$($Config.T1113_001A_IMAGE_FORMAT.ToLower())"
            } else {
                "screenshot.$($Config.T1113_001A_IMAGE_FORMAT.ToLower())"
            }

            # Create output directory if needed
            $outputDir = Join-Path $Config.OUTPUT_BASE "t1113.001a-screenshot_capture"
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }

            # Save the screenshot
            $outputPath = Join-Path $outputDir $filename
            $bitmap.Save($outputPath, $Config.T1113_001A_IMAGE_FORMAT)

            $endTime = Get-Date
            $duration = $endTime - $startTime

            # Get file info
            $fileInfo = Get-Item $outputPath

            $screenshotResults.results = @{
                "status" =  "SUCCESS"
                "mode" =  "REAL"
                "screenshot_path" = $outputPath
                "filename" = $filename
                "screen_resolution" =  "$($bounds.Width)x$($bounds.Height)"
                "image_format" = $Config.T1113_001A_IMAGE_FORMAT
                "file_size_bytes" = $fileInfo.Length
                "file_size_mb" = [math]::Round($fileInfo.Length / 1MB, 2)
                "capture_timestamp" = $fileInfo.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                "performance_metrics" = @{
                    "duration_seconds" = [math]::Round($duration.TotalSeconds, 2)
                    "capture_rate_mbps" = [math]::Round(($fileInfo.Length / 1MB) / $duration.TotalSeconds, 2)
                }
            }

            # POSTCONDITION VERIFICATION
            $screenshotResults.postconditions = @{
                "artifact_created" = (Test-Path $outputPath)
                "state_transition" =  "screenshot_captured"
                "file_generated" = $true
                "file_accessible" = (Test-Path $outputPath)
                "file_size_valid" = ($fileInfo.Length -gt 0)
            }

            if (-not $Config.T1113_001A_SILENT_MODE) {
                Write-Host "[SUCCESS] Screenshot captured: $outputPath ($($bounds.Width)x$($bounds.Height))" -ForegroundColor Green
            }
        }
        finally {
            # Clean up resources
            if ($graphics) { $graphics.Dispose() }
            if ($bitmap) { $bitmap.Dispose() }
        }

    } catch {
        $screenshotResults.results = @{
            "status" =  "FAILED"
            "error" = $_.Exception.Message
            "exception_type" = $_.Exception.GetType().Name
        }

        $screenshotResults.postconditions = @{
            "artifact_created" = $false
            "state_transition" =  "screenshot_failed"
            "file_generated" = $false
        }

        if (-not $Config.T1113_001A_SILENT_MODE) {
            Write-Error "Screenshot capture failed: $($_.Exception.Message)"
        }
    }

    return $screenshotResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)

    $outputDir = Join-Path $Config.OUTPUT_BASE "t1113.001a-screenshot_capture"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    switch ($Config.T1113_001A_OUTPUT_MODE) {
        "simple" {
            $simpleOutput = if ($Data.results.status -eq "SUCCESS") {
                "Screenshot captured: $($Data.results.filename) ($($Data.results.screen_resolution))"
            } else {
                "Screenshot capture failed: $($Data.results.error)"
            }

            if (-not $Config.T1113_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }

            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "screenshot_capture_simple.txt") -Encoding UTF8
        }

        "stealth" {
            # Minimal stealth output - JSON file only
            $jsonFile = Join-Path $outputDir "screenshot_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }

        "debug" {
            # Full debug output with JSON
            $jsonFile = Join-Path $outputDir "screenshot_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8

            if (-not $Config.T1113_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Screenshot capture data written to: $jsonFile" -ForegroundColor Cyan
            }
        }
    }

    return $outputDir
}

function Main {
    # Initialize config outside try-catch to avoid undefined variable errors
    $config = $null
    try {
        # CONTRACT INITIALIZATION: Load configuration
        $Config = Get-Configuration

        # ATOMIC EXECUTION: Execute precisely one observable action
        $results = Invoke-MicroTechniqueAction -Config $config

        # TELEMETRY GENERATION: Adaptive observability
        if ($Config.T1113_001A_OUTPUT_MODE -ne "silent") {
            $outputPath = Write-StandardizedOutput -Data $results -Config $config
        }

        # CONTRACT COMPLIANCE: Return standardized exit code
        $exitCode = switch ($results.results.status) {
            "SUCCESS" { 0 }
            "FAILED" { 1 }
            "SKIPPED_PRECONDITION" { 2 }
            "DENIED_POLICY" { 3 }
            "FAILED_POSTCONDITION" { 4 }
            "TIMEOUT" { 124 }
            default { 1 }
        }

        if (-not $Config.T1113_001A_SILENT_MODE) {
            $statusColor = switch ($exitCode) {
                0 { "Green" }
                2 { "Yellow" }
                3 { "Red" }
                4 { "Red" }
                124 { "Red" }
                default { "Red" }
            }
            Write-Host "[COMPLETE] T1113.001a atomic execution finished - Exit Code: $exitCode" -ForegroundColor $statusColor
        }

        return $exitCode

    } catch {
        # Use default config if initialization failed
        if (-not $config) {
            $Config = Get-Configuration
        }

        if (-not $Config.T1113_001A_SILENT_MODE) {
            Write-Error "T1113.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)

