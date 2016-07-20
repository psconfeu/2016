#region Directory Structure Parsing
# List directory contents based on parsing MFT
Get-ForensicChildItem C:\

# Get the MFT record index for C:\$AttrDef
Get-ForensicFileRecordIndex -Path 'C:\$AttrDef'

# Read the contents of the hidden $AttrDef file
Get-ForensicContent -Path 'C:\$AttrDef' -Encoding Unicode

# Parse the binary format of the $AttrDef file
Get-ForensicAttrDef -VolumeName C:

# Get the MFT record index for C:\Windows\System32\config\SAM
Get-ForensicFileRecordIndex -Path C:\Windows\System32\config\SAM

# Get FileRecord for all files in root directory
Get-ChildItem C:\ | Get-ForensicFileRecord

# Get MFT record by parsing the directory structures
Measure-Command {$r0 = Get-ForensicFileRecord -Path C:\Windows\System32\config\SAM}

# Get MFT record by brute Forcing the MFT
Measure-Command {$r1 = (Get-ForensicFileRecord -VolumeName C:).Where({$_.FullName -eq 'C:\windows\system32\config\sam'})}
#endregion Directory Structure Parsing

#region Dealing with Locked Files
# Attempt to read the contents of the SAM hive
Get-Content -Path C:\Windows\System32\config\SAM

# Use PowerForensics to read the contents of the SAM hive
Get-ForensicContent -Path C:\Windows\System32\config\SAM

# Attempt to copy SAM hive
Copy-Item -Path C:\Windows\System32\config\SAM -Destination C:\demo\PowerForensics\SAM

# Use PowerForensics to copy the contents of the SAM hive to another file
Copy-ForensicFile -Path C:\Windows\System32\config\SAM -Destination C:\demo\PowerForensics\SAM

# Show that the file was truly copied
Get-ChildItem -Path C:\Windows\System32\config\SAM
Get-ChildItem -Path C:\demo\PowerForensics\SAM
#endregion Dealing with Locked Files

#region Registry Parsing
# Get the first set of subkeys in the SOFTWARE hive
Get-ForensicRegistryKey -HivePath C:\Windows\System32\config\SOFTWARE

# Parse all Run keys on the system
Get-ForensicRunKey -VolumeName C:
#endregion Registry Parsing

#region Proper .Net Objects
# Show all members of a FileRecord object
Get-ForensicFileRecord -VolumeName C: -Index 0 | Get-Member

# Show the BornTime property
(Get-ForensicFileRecord -VolumeName C: -Index 0).BornTime | Select-Object *
#endregion Proper .Net Objects