# MITRE ATT&CK T1057.001A - Process Discovery: Running Inventory
# This script performs basic process enumeration and inventory discovery

Write-Host "MITRE ATT&CK T1057.001A - Process Discovery: Running Inventory ===" -ForegroundColor Cyan
Write-Host "Performing process enumeration and inventory discovery..." -ForegroundColor Yellow

# Get all running processes
$processes = Get-Process | Select-Object Id, Name, CPU, Memory, StartTime, Path

Write-Host "`nProcess Inventory ===" -ForegroundColor Green
$processes | Format-Table -AutoSize

Write-Host "`nProcess Count ===" -ForegroundColor Green
Write-Host "Total running processes: $($processes.Count)" -ForegroundColor White

Write-Host "`nProcess Analysis ===" -ForegroundColor Green
$processes | Group-Object Name | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize

Write-Host "`nSystem Process Information ===" -ForegroundColor Green
$systemProcesses = $processes | Where-Object { $_.Name -match "system|wininit|csrss|lsass|svchost" }
$systemProcesses | Format-Table -AutoSize

Write-Host "`nProcess discovery completed successfully!" -ForegroundColor Green
