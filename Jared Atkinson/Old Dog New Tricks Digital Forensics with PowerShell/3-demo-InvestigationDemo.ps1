#region Find initial pivot point
# List children of the volume's root directory
Get-ForensicChildItem -Path H:\

# Store all MFT records in $mft
$mft = Get-ForensicFileRecord -VolumeName H:

# Filter for files in H:\xampp and its subdirectories
$xampp = $mft.Where({$_.FullName -like 'H:\xampp*'})

# Compare number of records in $mft to $xampp
Write-Host "mft count: $($mft.Count)"
Write-Host "xampp count: $($xampp.Count)"

# Group files in H:\xampp based on 
$xampp | Group-Object {$_.FNModifiedTime.ToString('yyyy-MM-dd')}

# Store the groups in a variable for later use
$groups = $xampp | Group-Object {$_.FNModifiedTime.ToString('yyyy-MM-dd')}

# View the files that were created outside
$groups[1] | Select-Object -ExpandProperty Group | Sort-Object FNModifiedTime | Select-Object FullName, FNModifiedTime
$groups[2] | Select-Object -ExpandProperty Group | Sort-Object FNModifiedTime | Select-Object FullName, FNModifiedTime

# View the contents of a couple interesting files
Get-ForensicContent -Path H:\xampp\tmp\sess_gt9jmpq3k9h0hbtrpiqgrj0nc0
Get-ForensicContent -Path H:\xampp\htdocs\DVWA\hackable\uploads\phpshell2.php
#endregion Find initial pivot point

#region Create a temporal Window around our pivot point
# Create a starting bound for investigation timeframe
$start = Get-Date -Date 09/03/2015

# Create an ending bound for investigation timeframe
$end = $start.AddDays(1)
#endregion Create a temporal Window around our pivot point

#region Review MFT Entries from our window
# Parse the MFT into $mft
$mft = Get-ForensicFileRecord -VolumeName H:

# Filter out MFT records not in our window
$mftwindow = $mft | Where-Object {($_.FNModifiedTime -gt $start) -and ($_.FNModifiedTime -lt $end)}

# Compare number of records in $mft to $mftwindow
Write-Host "mft count: $($mft.Count)"
Write-Host "mftwindow count: $($mftwindow.Count)"

# View contents of $mftwindow
$mftwindow | Sort-Object FNModifiedTime | Select-Object FullName, FNModifiedTime | Format-List
#endregion Review MFT Entries from our window

#region Review UsnJrnl entries from our window
# Parse UsnJrnl into $usn
$usn = Get-ForensicUsnJrnl -VolumeName H:

# Filter out UsnJrnl records not in our window
$usnwindow = $usn | Where-Object {($_.TimeStamp -gt $start) -and ($_.TimeStamp -lt $end)}

# Show how much reduced our data set
Write-Host "usn Count: $($usn.Count)"
Write-Host "usnwindow Count: $($usnwindow.Count)"

# Group UsnJrnl entries by FileName
$usnwindow | Group-Object FileName

# Read the contents of a file based on MFT Record Index
Get-ForensicContent -VolumeName H: -Index 62330
#endregion Review UsnJrnl entries from our window

#region Apache Access Log
$access = [PowerForensics.Artifacts.ApacheAccessLog]::GetInstances('H:\xampp\apache\logs\access.log')

# Show what an ApacheAccessLog object looks like
$access[0]

# Group ApacheAccessLog objects by their HttpMethod properties 
$access | Group-Object HttpMethod

# View ApacheAccessLog objects that used the POST HttpMethod
($access | Group-Object HttpMethod)[1].Group

# view the Request property of ApacheAccessLog objects that used the POST HttpMethod
($access | Group-Object HttpMethod)[1].Group | select Request
#endregion Apache Access Log

#region Forensic Timeline
# Show how FileRecord objects can be Converted to Timeline objects
$record = Get-ForensicFileRecord -Path H:\xampp\htdocs\DVWA\c99.php 

# Show FileRecord
$record

# Convert FileRecord to ForensicTimeline object
$record | ConvertTo-ForensicTimeline

# Create a forensic timeline for the H: logical volume
$timeline = Get-ForensicTimeline -VolumeName H:

# Show Timeline Data Types
$timeline | Group-Object Source

# Filter down timeline 
$timelinewindow = $timeline | Where-Object {($_.Date -gt $start) -and ($_.Date -lt $end)}

# Show how much reduced our data set
Write-Host "timeline Count: $($timeline.Count)"
Write-Host "timelinewindow Count: $($timelinewindow.Count)"

# Show limited timeline in Excel
$timelinewindow | Export-Excel -Path C:\demo\PowerForensics\timeline.xlsx -AutoSize -FreezeTopRow -Show
#endregion Forensic Timeline