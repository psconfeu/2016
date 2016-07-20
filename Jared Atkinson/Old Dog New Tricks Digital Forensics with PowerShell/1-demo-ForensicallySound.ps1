break
#region Demo Prep

Remove-Item C:\temp\MFT -Force -ErrorAction Ignore

#endregion Demo Prep


#region Master Boot Record

# Read first sector of the Disk (Master Boot Record)
$props = @{
    InFile = '\\.\PHYSICALDRIVE0'
    Offset = 0
    BlockSize = 512
    Count =  1
}
Invoke-ForensicDD @props | Format-Hex

# Parse Master Boot Record Bytes into human readable object
Get-ForensicMasterBootRecord -Path \\.\PHYSICALDRIVE0 | Format-List

# Show Partition Table
Get-ForensicMasterBootRecord -Path \\.\PHYSICALDRIVE0 | Select-Object -ExpandProperty PartitionTable

# Show cmdlet to specifically get Partition Table
Get-ForensicPartitionTable -Path \\.\PHYSICALDRIVE0 | Format-Table

# Get Bootable Partition
Get-ForensicPartitionTable -Path \\.\PHYSICALDRIVE0 | Where-Object {$_.Bootable}

# Store bootable partition
$partition = Get-ForensicPartitionTable -Path \\.\PHYSICALDRIVE0 | Where-Object {$_.Bootable}

#endregion Master Boot Record


#region Volume Boot Record
# Read first sector ($partition[0].StartSector) of Logical Volume (Volume Boot Record)
$props = @{
    InFile = '\\.\PHYSICALDRIVE0'
    Offset = ($partition[0].StartSector * 512)
    BlockSize = 512
    Count = 1
}
Invoke-ForensicDD @props | Format-Hex

# Parse Volume Boot Record Bytes into human readable object
Get-ForensicVolumeBootRecord -VolumeName C:

# Store VolumeBootRecord object in $vbr for later use
$vbr = Get-ForensicVolumeBootRecord -VolumeName C:

#endregion Volume Boot Record


#region Master File Table

# Follow the VBR's pointer ($vbr.MftStartIndex) to the Master File Table and read the first record ($vbr.BytesPerFileRecord) 
$props = @{
    InFile = '\\.\C:'
    Offset = ($vbr.MftStartIndex * $vbr.BytesPerCluster)
    BlockSize = $vbr.BytesPerFileRecord
    Count = 1
}
Invoke-ForensicDD @props | Format-Hex

# Parse first Master File Table Record into human readable object
Get-ForensicFileRecord -VolumeName C: -Index 0

# Store MFT record in $record for later use
$record = Get-ForensicFileRecord -VolumeName C: -Index 0

# Show the Property Members of the FileRecord object
$record | Get-Member -MemberType Properties | Format-Table

# Show the MFT record attributes associated with the record at index 0
$record.Attribute

#endregion Master File Table


#region DATA Attribute

# Show the DATA attribute
$record.Attribute | Where-Object {$_.Name -eq 'DATA'}

# Store the DATA attribute in $data
$data = $record.Attribute | Where-Object {$_.Name -eq 'DATA'}

# Store bytes
foreach($dr in $data.DataRun){
    $props = @{
        InFile = '\\.\C:'
        OutFile = 'C:\temp\MFT'
        Offset = ($dr.StartCluster * $vbr.BytesPerCluster)
        BlockSize = $vbr.BytesPerCluster
        Count = $dr.ClusterLength
    }
    Invoke-ForensicDD @props
}

# Check that file was created
Get-ChildItem C:\temp\MFT

# Show method members of FileRecord object
$record | Get-Member -MemberType Method

# Use the FileRecord object's GetContent method
$byte = $record.GetContent()

Write-Host "Real Length: $($data.RealSize)"
Write-Host "File Length: $((Get-ChildItem C:\temp\MFT).Length)"
Write-Host "byte Length: $($byte.Count)"

# Store all MFT records in $mft
$mft = Get-ForensicFileRecord -VolumeName C:

# Show length of mft array
$mft.Length

# Show mft record for root directory
$mft[5]

#endregion DATA Attribute


#region INDEX_ALLOCATION Attribute

# Show MFT record for the volume's root directory
Get-ForensicFileRecord -VolumeName C: -Index 5

# Store the MFT record for the volume's root directory in $root
$root = Get-ForensicFileRecord -VolumeName C: -Index 5

# Show the INDEX_ALLOCATION (Non-Resident) Attribute
$root.Attribute | Where-Object {$_.Name -eq 'INDEX_ALLOCATION'}

# Store the INDEX_ALLOCATION (Non-Resident) Attribute in $indx
$indx = $root.Attribute | Where-Object {$_.Name -eq 'INDEX_ALLOCATION'}

# Show method members of the NonResident object type
$indx | Get-Member -MemberType Method

# Read the contents of the INDEX_ALLOCATION Attribute 
@(,[byte[]]$indx.GetBytes('\\.\C:')) | Format-Hex

#endregion INDEX_ALLOCATION Attribute