$number10 = {
  'WALKING ON THIN ICE' | Write-Warning
  Get-Help about_scrubby_cmdlets
}

#region RUNNER-UP
  
  'localhost' | Test-Connection
  Get-Help Test-Connection -ShowWindow
  
  [pscustomobject]@{'Computername'='localhost'} | Test-Connection

  New-SmbShare -Name 'sales' -path 'c:\sales' -WhatIf
  Get-SmbShare -Name 'sales'

#endregion

#region THE WINNER IS ... Get-Service

    <#
      ServiceController.StartType Property
      https://msdn.microsoft.com/en-us/library/system.serviceprocess.servicecontroller.starttype(v=vs.110).aspx 
      requires .NET 4.6.1
    #>

    # Cmdlet 
    Get-Service 
    Get-Service -ComputerName sea-cl10 |  Select-Object -First 1 -Property Name,St*
    Invoke-Command -ComputerName sea-cl10 { Get-Service } |  Select-Object -First 1 -Property Name,St*

    # ServiceController class 
    Add-Type -AssemblyName System.ServiceProcess
    [System.ServiceProcess.ServiceController]::GetServices() | Select-Object -First 1 -Property Name,St*

    # WMI class // TRY ADDING '| Format-Table'
    Get-CimInstance -ClassName Win32_Service | Select-Object -First 1 -Property Name,St* 

#endregion


#region .NET FRAMEWORK VERSIONS
    <#
     How to: Determine Which .NET Framework Versions Are Installed
     https://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx

     Find .NET Framework versions by viewing the registry (.NET Framework 1-4)
     The installed versions are listed under the NDP subkey:
     HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP

     Find .NET Framework versions by viewing the registry (.NET Framework 4.5 and later)
     HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full

     RELEASE to VERSION translation:
     378389 .NET Framework 4.5
     378675 .NET Framework 4.5.1 installed with Windows 8.1
     378758 .NET Framework 4.5.1 installed on Windows 8, Windows 7 SP1, or Windows Vista SP2
     379893 .NET Framework 4.5.2
     393295 .NET Framework 4.6 installed with Windows 10
     393297 .NET Framework 4.6 installed on all other Windows OS versions
     394254 .NET Framework 4.6.1 installed on Windows 10
     394271 .NET Framework 4.6.1 installed on all other Windows OS versions

    #>

    Invoke-Command -ComputerName sea-cl3 -ScriptBlock {
        [string]$netA = 'Registry::' + 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP'
        [string]$netB = 'Registry::' + 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'

        'NET Framework v1-4:'
        (Get-ChildItem $netA).name.Split('\') | Where-Object { $_ -like "v*"}

        "`nNET Framework greater than v4.5:"
        'Version: ' + (Get-ItemProperty $netB version).version
        'Release: ' + (Get-ItemProperty $netB release).release
        
        Get-Service | Select-Object -First 1 -Property Name,St* 
    }

#endregion