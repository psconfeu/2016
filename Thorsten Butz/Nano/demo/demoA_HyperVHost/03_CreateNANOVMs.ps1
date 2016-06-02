<#
    sea-nano1: Workgroup, Gen1
    sea-nano2: Domain, Gen2, DNS, Webserver
    sea-nano3: Domain, Gen2, VirtHost
#>


#region NANO1

    $vmName = 'sea-nano11'

    $paramsNewVM = @{
        Computername = $env:computername
        Name = $vmName
        Generation = 1
        MemoryStartupBytes = 1GB # Minimum: 512 GB 
        VHDPath = "$vmName.vhd"        SwitchName = 'HV_Private1'
    }

    New-VM @paramsNewVM | Start-VM

#endregion

#region NANO2

    $vmName = 'sea-nano12'
    $paramsNewVM = @{
        Computername = $env:computername
        Name = $vmName
        Generation = 2
        MemoryStartupBytes = 1GB # Minimum: 512 GB 
        VHDPath = "$vmName.vhdx"        SwitchName = 'HV_Private1'
    }

    New-VM @paramsNewVM | Start-VM

#endregion

#region NANO3

    $vmname = 'sea-nano13'
    $paramsNewVM = @{
        Computername = $env:computername
        Name = $vmName
        Generation = 2
        MemoryStartupBytes = 4GB 
        VHDPath = "$vmName.vhdx"        SwitchName = 'HV_Private1'
    }

    New-VM @paramsNewVM

    # Nested virtualization
    Set-VMProcessor -VMName $vmName  -ExposeVirtualizationExtensions $true
    Set-VMNetworkAdapter -VMName $vmName  -MacAddressSpoofing On
    Set-VMMemory -VMName $vmName  -DynamicMemoryEnabled:$false -StartupBytes 4GB # optional

    Start-VM -ComputerName $env:computername -VMName $vmName

#endregion
