#region PREREQUISITES

    # Variables
    $password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'
    $iso_X = 'C:\depot\iso_x\en_windows_server_2016_technical_preview_4_x64_dvd_7258292\'
    $VirtualHardDiskPath = (Get-VMHost).VirtualHardDiskPath 

    # Nano creation module (from WS 2016 ISO) 
    Import-Module C:\NanoServer_TP4\NanoServerImageGenerator.psm1 

#endregion

#region  NANO1     # GEN 1 VM (Workgroup)    $nanoName = 'sea-nano11'    $nanoHardDisk = "$VirtualHardDiskPath\$nanoName.vhd"    if (Test-Path $nanoHardDisk) {      Get-ChildItem $nanoHardDisk | Remove-Item -Confirm    }    New-NanoServerImage `     -MediaPath $iso_x `     -BasePath 'C:\NanoServer_TP4\Base' `     -TargetPath "C:\Hyper-V\Virtual Hard Disks\$nanoName.vhd" `     -GuestDrivers `     -EnableRemoteManagementPort `     -AdministratorPassword $password `     -Language en-US `     -ComputerName $nanoname     Get-ChildItem $nanoHardDisk -ErrorAction SilentlyContinue
#endregion

#region NANO2

    # GEN 2 VM: DNS + DSC + IIS + ReverseForwarders + DomainJoin    $nanoName = 'sea-nano12'    $nanoHardDisk = "$VirtualHardDiskPath\$nanoName.vhdx"    $params = @{                MediaPath =  $iso_x         BasePath =  'C:\NanoServer_TP4\Base'         TargetPath = $nanoHardDisk         GuestDrivers = $true         EnableRemoteManagementPort = $true         AdministratorPassword = $password         ReverseForwarders = $true           Language = 'en-US'                Packages = 'Microsoft-NanoServer-DNS-Package', 'Microsoft-NanoServer-DSC-Package', 'Microsoft-NanoServer-IIS-Package'        DomainBlobPath = "C:\NanoServer_TP4\$nanoName.djoin"         ReuseDomainNode = $true    }    if (Test-Path $nanoHardDisk) {      Get-ChildItem $nanoHardDisk | Remove-Item -Confirm    }    New-NanoServerImage @params     
#endregion

#region NANO3

    # GEN 2 VM: Hyper-V + Container + Cluster + DSC + DomainJoin    $nanoName = 'sea-nano13'    $nanoHardDisk = "$VirtualHardDiskPath\$nanoName.vhdx"    $params = @{                MediaPath =  $iso_x         BasePath =  'C:\NanoServer_TP4\Base'         TargetPath = $nanoHardDisk         GuestDrivers = $true         EnableRemoteManagementPort = $true         AdministratorPassword = $password         Language = 'en-US'        Compute = $true        Container = $true                Clustering = $true        Defender = $true                 DomainBlobPath = "C:\NanoServer_TP4\$nanoName.djoin"         ReuseDomainNode = $true        Packages = 'Microsoft-NanoServer-DSC-Package'    }    if (Test-Path $nanoHardDisk) {      Get-ChildItem $nanoHardDisk | Remove-Item -Confirm    }    New-NanoServerImage @params

#endregion


<#  EDIT NANO IMAGE
    
    # In case you missed something ..
    $newpassword = Read-Host 'New Password' -AsSecureString

    Edit-NanoServerImage `
    -BasePath 'C:\NanoServer_TP4\Base' `
    -TargetPath 'C:\Hyper-V\Virtual Hard Disks\sea-nano1.vhd' `
    -AdministratorPassword $password 

#>