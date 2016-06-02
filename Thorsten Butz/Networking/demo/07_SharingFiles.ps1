#region LOCAL

    Get-SmbShare
    New-Item -ItemType Directory 'c:\sales'

    New-SmbShare -Path 'C:\sales' -Name sales -FullAccess 'contoso\ITSupport'

    # A little bit of permissions vodooo 
    Set-SmbPathAcl -ShareName 'sales' 
    $acl = Get-Acl -Path 'c:\sales'              ## You may want to observe the filesystem permissions in "explorer.exe" now!
    $acl.SetAccessRuleProtection($true,$false)   ## $true = Disable inheritance  // $false = Do not copy current permissions
    Set-Acl -Path 'c:\sales' -AclObject $acl

    Grant-SmbShareAccess -name 'sales' -AccountName 'contoso\Sales' -AccessRight Change -Force
    Revoke-SmbShareAccess -Name 'sales'-AccountName 'contoso\Sales' -Force
    Get-SmbShareAccess -Name 'sales'

    Get-SmbShare -Name 'sales' | Remove-SmbShare -Force    
    Remove-Item 'c:\sales'

#endregion

#region REMOTE

    Get-CimSession | Remove-CimSession
    $cimsession = New-CimSession -ComputerName 'sea-dc1'

    # Get-SMBShare does not provide a "computername" parameter!
    Get-SmbShare -CimSession $cimsession  
           
    New-Item -ItemType Directory -Path '\\sea-dc1\c$\marketing' 
    New-SmbShare -CimSession $cimsession -Name 'marketing' -Path 'c:\marketing' -FullAccess  'contoso\Domain Admins' 
    Grant-SmbShareAccess  -CimSession $cimsession -name 'marketing' -AccountName 'contoso\ITSupport' -AccessRight Change -Force
    Remove-SmbShare -CimSession $cimsession -Name marketing -Force

    Remove-Item -Path '\\sea-dc1\c$\marketing'

#endregion

#region CONNECTION TO SHARES

    ## Which command SHOULD work? 

    # Example 1
    $password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'
    New-SmbMapping -LocalPath Z: -RemotePath \\sea-dc1\depot # -UserName 'contoso\administrator' -Password $password

    # Example 2
    New-SmbMapping -LocalPath Z: -RemotePath \\sea-dc1\depot # -UserName 'contoso\administrator' -Password 'Pa$$w0rd'

    Remove-SmbMapping -LocalPath Z: -Force

    Get-SmbOpenFile -CimSession $cimsession  | Where-Object { $_.path -like '*somefile.txt*' }
    notepad "\\sea-dc1\depot\somefile.txt"

    Get-SmbConnection -ServerName sea-dc1 
        


#endregion

#region ODDITIES

    # Remoting? 
    Set-SmbPathAcl -ShareName marketing -cimsession $cimsession 

    # Introduced in WS2012/W8, but still no "-whatif" support
    Get-SmbShare -name 'data' | Remove-SmbShare -Force
    New-SmbShare -Name 'data' -Path 'c:\data' -WhatIf

#endregion