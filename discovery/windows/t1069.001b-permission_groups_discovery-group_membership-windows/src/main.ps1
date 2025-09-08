# MITRE ATT&CK T1069.001B - Permission Groups Discovery: Group Membership
# This script performs group membership analysis and detailed extraction

Write-Host "MITRE ATT&CK T1069.001B - Permission Groups Discovery: Group Membership ===" -ForegroundColor Cyan
Write-Host "Performing group membership analysis and detailed extraction..." -ForegroundColor Yellow

# Get local groups and their members
$localGroups = Get-LocalGroup

Write-Host "`nLocal Groups ===" -ForegroundColor Green
$localGroups | Format-Table -AutoSize

Write-Host "`nGroup Membership Analysis ===" -ForegroundColor Green
foreach ($group in $localGroups) {
    Write-Host "`nGroup: $($group.Name)" -ForegroundColor Yellow
    try {
        $members = Get-LocalGroupMember -Group $group.Name
        $members | Format-Table -AutoSize
        Write-Host "Members count: $($members.Count)" -ForegroundColor White
    } catch {
        Write-Host "Unable to retrieve members for group: $($group.Name)" -ForegroundColor Red
    }
}

Write-Host "`nAdministrative Groups Analysis ===" -ForegroundColor Green
$adminGroups = $localGroups | Where-Object { $_.Name -match "admin|administrator" }
foreach ($group in $adminGroups) {
    Write-Host "`nAdministrative Group: $($group.Name)" -ForegroundColor Yellow
    try {
        $members = Get-LocalGroupMember -Group $group.Name
        $members | Format-Table -AutoSize
    } catch {
        Write-Host "Unable to retrieve members" -ForegroundColor Red
    }
}

Write-Host "`nGroup membership analysis completed successfully!" -ForegroundColor Green
