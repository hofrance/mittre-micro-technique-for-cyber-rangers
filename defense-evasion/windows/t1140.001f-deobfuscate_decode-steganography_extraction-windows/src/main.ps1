# T1140.001F - Steganography Extraction
# MITRE ATT&CK Technique: T1140 - Deobfuscate/Decode Files or Information
# Platform: Windows | Privilege: User | Tactic: Defense Evasion

#Requires -Version 5.0


# AUXILIARY FUNCTIONS


function Test-CriticalDependencies {
    # .NET imaging support
    try {
        Add-Type -AssemblyName System.Drawing
        return $true
    } catch {
        return $false
    }
}

function Initialize-EnvironmentVariables {
    @{
        OutputBase = if ($env:OUTPUT_BASE) { $env:OUTPUT_BASE } else { "C:\temp\mitre_results" }
        Timeout = if ($env:TIMEOUT) { [int]$env:TIMEOUT } else { 300 }
        SourceImage = if ($env:T1140_001F_SOURCE_IMAGE) { $env:T1140_001F_SOURCE_IMAGE } else { "" }
        StegoMethod = if ($env:T1140_001F_STEGO_METHOD) { $env:T1140_001F_STEGO_METHOD } else { "lsb" }
        OutputFile = if ($env:T1140_001F_OUTPUT_FILE) { $env:T1140_001F_OUTPUT_FILE } else { "" }
        OutputMode = if ($env:T1140_001F_OUTPUT_MODE) { $env:T1140_001F_OUTPUT_MODE } else { "simple" }
        SilentMode = if ($env:T1140_001F_SILENT_MODE -eq "true") { $true } else { $false }
        Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
}

function Extract-LSBData {
    param($ImagePath)
    
    try {
        if (-not (Test-Path $ImagePath)) {
            return @{ Success = $false; Error = "Image file not found" }
        }
        
        $bitmap = New-Object System.Drawing.Bitmap($ImagePath)
        $extractedBits = ""
        $byteList = New-Object System.Collections.ArrayList
        
        # Extract from least significant bits
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                
                # Extract LSB from each color channel
                $extractedBits += ($pixel.R -band 1).ToString()
                $extractedBits += ($pixel.G -band 1).ToString()
                $extractedBits += ($pixel.B -band 1).ToString()
                
                # Convert to bytes when we have 8 bits
                while ($extractedBits.Length -ge 8) {
                    $byte = [Convert]::ToByte($extractedBits.Substring(0, 8), 2)
                    
                    # Check for end marker (null bytes)
                    if ($byte -eq 0) {
                        $bitmap.Dispose()
                        $extractedBytes = $byteList.ToArray()
                        $extractedText = [System.Text.Encoding]::UTF8.GetString($extractedBytes)
                        
                        return @{
                            Success = $true
                            ExtractedData = $extractedText
                            ByteCount = $extractedBytes.Length
                            Method = "LSB (Least Significant Bit)"
                        }
                    }
                    
                    [void]$byteList.Add($byte)
                    $extractedBits = $extractedBits.Substring(8)
                }
            }
        }
        
        $bitmap.Dispose()
        
        # If no null terminator found, return what we have
        $extractedBytes = $byteList.ToArray()
        $extractedText = [System.Text.Encoding]::UTF8.GetString($extractedBytes)
        
        return @{
            Success = $true
            ExtractedData = $extractedText
            ByteCount = $extractedBytes.Length
            Method = "LSB (Least Significant Bit)"
            Warning = "No end marker found"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Extract-MetadataData {
    param($ImagePath)
    
    try {
        if (-not (Test-Path $ImagePath)) {
            return @{ Success = $false; Error = "Image file not found" }
        }
        
        $image = [System.Drawing.Image]::FromFile($ImagePath)
        $extractedData = @{}
        
        # Check all property items (EXIF data)
        foreach ($prop in $image.PropertyItems) {
            $propName = "Property_$($prop.Id)"
            
            # Common EXIF tags that might contain hidden data
            switch ($prop.Id) {
                0x9286 { $propName = "UserComment" }      # User comments
                0x010E { $propName = "ImageDescription" } # Image description
                0x013B { $propName = "Artist" }           # Artist
                0x8298 { $propName = "Copyright" }        # Copyright
                0x0132 { $propName = "DateTime" }         # Date time
                0x010F { $propName = "Make" }             # Camera make
                0x0110 { $propName = "Model" }            # Camera model
            }
            
            # Extract value based on type
            $value = switch ($prop.Type) {
                2 { [System.Text.Encoding]::UTF8.GetString($prop.Value).TrimEnd([char]0) }
                default { [System.BitConverter]::ToString($prop.Value) }
            }
            
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $extractedData[$propName] = $value
            }
        }
        
        $image.Dispose()
        
        # Check for base64 encoded data in metadata
        $hiddenData = ""
        foreach ($key in $extractedData.Keys) {
            $value = $extractedData[$key]
            if ($value -match '^[A-Za-z0-9+/]+=*$' -and $value.Length -gt 20) {
                try {
                    $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
                    $hiddenData += "[$key]: $decoded`n"
                }
                catch {
                    # Not valid base64
                }
            }
        }
        
        if ($hiddenData) {
            return @{
                Success = $true
                ExtractedData = $hiddenData
                ByteCount = $hiddenData.Length
                Method = "EXIF Metadata"
                Metadata = $extractedData
            }
        }
        else {
            return @{
                Success = $true
                ExtractedData = ($extractedData | ConvertTo-Json -Compress)
                ByteCount = 0
                Method = "EXIF Metadata"
                Metadata = $extractedData
                Warning = "No hidden data found in metadata"
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

function Extract-AppendedData {
    param($FilePath)
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{ Success = $false; Error = "File not found" }
        }
        
        # Read file as bytes
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Look for common file format end markers
        $markers = @{
            JPEG = @(0xFF, 0xD9)
            PNG = @(0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82)
            GIF = @(0x00, 0x3B)
        }
        
        $fileExt = [System.IO.Path]::GetExtension($FilePath).ToLower().TrimStart('.')
        $endMarker = $null
        
        switch ($fileExt) {
            "jpg" { $endMarker = $markers.JPEG }
            "jpeg" { $endMarker = $markers.JPEG }
            "png" { $endMarker = $markers.PNG }
            "gif" { $endMarker = $markers.GIF }
        }
        
        if ($endMarker) {
            # Search for end marker
            $markerPos = -1
            for ($i = 0; $i -le $fileBytes.Length - $endMarker.Length; $i++) {
                $match = $true
                for ($j = 0; $j -lt $endMarker.Length; $j++) {
                    if ($fileBytes[$i + $j] -ne $endMarker[$j]) {
                        $match = $false
                        break
                    }
                }
                if ($match) {
                    $markerPos = $i + $endMarker.Length
                    break
                }
            }
            
            if ($markerPos -gt 0 -and $markerPos -lt $fileBytes.Length) {
                # Extract appended data
                $appendedBytes = New-Object byte[] ($fileBytes.Length - $markerPos)
                [Array]::Copy($fileBytes, $markerPos, $appendedBytes, 0, $appendedBytes.Length)
                
                $appendedText = [System.Text.Encoding]::UTF8.GetString($appendedBytes)
                
                return @{
                    Success = $true
                    ExtractedData = $appendedText
                    ByteCount = $appendedBytes.Length
                    Method = "Appended Data"
                    AppendedAt = $markerPos
                }
            }
        }
        
        return @{
            Success = $true
            ExtractedData = ""
            ByteCount = 0
            Method = "Appended Data"
            Warning = "No appended data found"
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Create-StegoSample {
    # Create a simple BMP with hidden message in LSB
    $width = 100
    $height = 100
    $message = "Hidden steganography payload!"
    $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
    
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::White)
    
    # Embed message in LSB
    $bitIndex = 0
    $messageBits = ""
    
    # Convert message to bits
    foreach ($byte in $messageBytes) {
        $messageBits += [Convert]::ToString($byte, 2).PadLeft(8, '0')
    }
    $messageBits += "00000000"  # Null terminator
    
    # Embed in pixels
    for ($y = 0; $y -lt $height -and $bitIndex -lt $messageBits.Length; $y++) {
        for ($x = 0; $x -lt $width -and $bitIndex -lt $messageBits.Length; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            
            $r = $pixel.R
            $g = $pixel.G
            $b = $pixel.B
            
            # Modify LSB of each channel
            if ($bitIndex -lt $messageBits.Length) {
                $r = ($r -band 0xFE) -bor [int]($messageBits[$bitIndex] -eq '1')
                $bitIndex++
            }
            if ($bitIndex -lt $messageBits.Length) {
                $g = ($g -band 0xFE) -bor [int]($messageBits[$bitIndex] -eq '1')
                $bitIndex++
            }
            if ($bitIndex -lt $messageBits.Length) {
                $b = ($b -band 0xFE) -bor [int]($messageBits[$bitIndex] -eq '1')
                $bitIndex++
            }
            
            $newPixel = [System.Drawing.Color]::FromArgb($r, $g, $b)
            $bitmap.SetPixel($x, $y, $newPixel)
        }
    }
    
    $tempPath = [System.IO.Path]::GetTempFileName() + ".bmp"
    $bitmap.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $graphics.Dispose()
    $bitmap.Dispose()
    
    return $tempPath
}


# 4 MAIN ORCHESTRATORS


function Get-Configuration {
    param()
    
    $config = @{
        Success = $false
        Technique = "T1140.001F"
        TechniqueName = "Steganography Extraction"
        Results = @{
            InitialPrivilege = ""
            ExtractedData = ""
            ByteCount = 0
            Method = ""
            SourceImage = ""
            OutputPath = ""
            ErrorMessage = ""
        }
    }
    
    # Test critical dependencies
    if (-not (Test-CriticalDependencies)) {
        $Config.Results.ErrorMessage = "Failed to load imaging dependencies"
        return $config
    }
    
    # Load environment variables
    $envConfig = Initialize-EnvironmentVariables
    foreach ($key in $envConfig.Keys) {
        $config[$key] = $envConfig[$key]
    }
    
    # Validate stego method
    if ($Config.StegoMethod -notin @("lsb", "metadata", "append", "auto")) {
        $Config.StegoMethod = "lsb"
    }
    
    # If no source image provided, create a sample
    if (-not $Config.SourceImage) {
        $Config.SourceImage = Create-StegoSample
        $Config.TempImage = $true
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
        Write-Host "[INFO] Extracting steganography data..." -ForegroundColor Yellow
    }
    
    # ATOMIC ACTION: Extract hidden data
    $Config.Results.SourceImage = $Config.SourceImage
    
    $extractionSuccess = $false
    
    if ($Config.StegoMethod -eq "auto") {
        # Try all methods
        $methods = @("lsb", "metadata", "append")
        foreach ($method in $methods) {
            $result = switch ($method) {
                "lsb" { Extract-LSBData -ImagePath $Config.SourceImage }
                "metadata" { Extract-MetadataData -ImagePath $Config.SourceImage }
                "append" { Extract-AppendedData -FilePath $Config.SourceImage }
            }
            
            if ($result.Success -and $result.ExtractedData -and -not $result.Warning) {
                $Config.Results.ExtractedData = $result.ExtractedData
                $Config.Results.ByteCount = $result.ByteCount
                $Config.Results.Method = $result.Method
                $extractionSuccess = $true
                break
            }
        }
    }
    else {
        # Use specified method
        $result = switch ($Config.StegoMethod) {
            "lsb" { Extract-LSBData -ImagePath $Config.SourceImage }
            "metadata" { Extract-MetadataData -ImagePath $Config.SourceImage }
            "append" { Extract-AppendedData -FilePath $Config.SourceImage }
        }
        
        if ($result.Success) {
            $Config.Results.ExtractedData = $result.ExtractedData
            $Config.Results.ByteCount = $result.ByteCount
            $Config.Results.Method = $result.Method
            $extractionSuccess = $true
            
            if ($result.Warning) {
                $Config.Results.Warning = $result.Warning
            }
        }
    }
    
    if ($extractionSuccess) {
        if ($Config.OutputFile -and $Config.Results.ExtractedData) {
            Set-Content -Path $Config.OutputFile -Value $Config.Results.ExtractedData
            $Config.Results.OutputPath = $Config.OutputFile
        }
        
        if (-not $Config.SilentMode) {
            Write-Host "[SUCCESS] Steganography data extracted" -ForegroundColor Green
        }
    }
    else {
        $Config.Results.ErrorMessage = if ($result.Error) { $result.Error } else { "No hidden data found" }
        if (-not $Config.SilentMode) {
            Write-Host "[ERROR] Extraction failed: $($Config.Results.ErrorMessage)" -ForegroundColor Red
        }
    }
    
    # Clean up temp image if created
    if ($Config.TempImage -and (Test-Path $Config.SourceImage)) {
        Remove-Item $Config.SourceImage -Force
    }
    
    return $Config
}

function Write-StandardizedOutput {
    param($Config)
    
    $outputDir = Join-Path $Config.OutputBase "T1140.001f_stego_extract_$($Config.Timestamp)"
    
    switch ($Config.OutputMode) {
        "simple" {
            Write-Host "`n[+] Steganography Extraction Results" -ForegroundColor Green
            Write-Host "    Initial Privilege: $($Config.Results.InitialPrivilege)"
            Write-Host "    Source Image: $([System.IO.Path]::GetFileName($Config.Results.SourceImage))"
            Write-Host "    Extraction Method: $($Config.Results.Method)"
            Write-Host "    Bytes Extracted: $($Config.Results.ByteCount)"
            if ($Config.Results.OutputPath) {
                Write-Host "    Output File: $($Config.Results.OutputPath)"
            }
            if ($Config.Results.ExtractedData -and $Config.Results.ExtractedData.Length -le 100) {
                Write-Host "    Extracted: $($Config.Results.ExtractedData)"
            }
            if ($Config.Results.Warning) {
                Write-Host "    Warning: $($Config.Results.Warning)" -ForegroundColor Yellow
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
                    StegoMethod = $Config.StegoMethod
                }
                EnvironmentContext = @{
                    Hostname = $env:COMPUTERNAME
                    Username = $env:USERNAME
                    OSVersion = [System.Environment]::OSVersion.VersionString
                }
            }
            $debugOutput | ConvertTo-Json -Depth 4 | Out-File "$outputDir\t1140_001f_stego_extract.json"
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
    if ($Config.Results.ByteCount -gt 0 -or $Config.Results.ExtractedData) {
        exit 0
    } else {
        exit 1
    }
}

# Execute main function
Main

