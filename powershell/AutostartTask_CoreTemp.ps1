# --- CONFIGURATION ---

# Task settings
$TaskName = "Core Temp Autostart as Admin for kroli"
$AppPath = "C:\Tools\CoreTemp\CoreTemp.exe"   # <-- <-- SET THIS TO YOUR ACTUAL PATH

# Target user (must exist)
$User = "CODING-X360\kroli"

# --- BUILD TASK ---

# Define trigger: at logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $User

# Define action: launch Core Temp
$Action = New-ScheduledTaskAction -Execute $AppPath

# Define principal: run with highest privileges as target user
$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest

# Build the full task definition
$Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger

# Register (overwrite if already exists)
Register-ScheduledTask -TaskName $TaskName -InputObject $Task -Force

Write-Host "Task '$TaskName' has been created successfully."
