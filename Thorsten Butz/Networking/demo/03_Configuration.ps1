#region DHCP

    # Query the Win32_NetworkAdapterConfiguration class

    $InterfaceIndex = 15
    Get-NetAdapter -InterfaceIndex $InterfaceIndex 
    
    # Win32_NetworkAdapterConfiguration does NOT provide and InterfaceAlias, take care!
    Get-CimInstance  -Class Win32_NetworkAdapterConfiguration |
     Where-Object { $_.IPEnabled -and $_.DHCPenabled -and $_.InterfaceIndex -eq $InterfaceIndex } | 
       Format-List -Property *Description, *Index, IPAddress

    Get-CimInstance  -Class Win32_NetworkAdapterConfiguration |
     Where-Object { $_.IPEnabled -and $_.DHCPenabled -and $_.InterfaceIndex -eq $InterfaceIndex} | 
       Get-NetIPConfiguration -Detailed |  
         Format-List *Description, InterfaceAlias, *Index, IP*Address, InterfaceDescription

    # Optimized query: WQL
    $wql = "select * from Win32_NetworkAdapterConfiguration where IPEnabled='true' and DHCPEnabled='true' and InterfaceIndex=`'$InterfaceIndex`'"
    $instance = Get-CimInstance -Query $wql 

    ($instance | Get-NetIPAddress).IPAddress			# Array of addresses
    ($instance | Get-NetIPAddress).IPv4Address		 	# Array of addresses
    ($instance | Get-NetIPAddress).IPv6Address			# Array of addresses

    $instance | Invoke-CimMethod -MethodName ReleaseDHCPLease 
    # $instance | Invoke-CimMethod -MethodName RenewDHCPLease 

    # ReturnValue 0  <= Successfull release/renewed IP
    # ReturnValue 82 <= Unable to renew

#endregion

#region MANUAL CONFIGURATION

    # Show current config
    Get-NetAdapter -InterfaceIndex $InterfaceIndex  | Get-NetIPAddress
    Get-NetIPConfiguration -InterfaceIndex $InterfaceIndex 

    # In case you prefer to use the "InterfaceAlias"
    $interfaceAlias = Get-NetAdapter -InterfaceIndex $InterfaceIndex | Select-Object -ExpandProperty InterfaceAlias

    Get-NetAdapter -Name $interfaceAlias  | Get-NetIPAddress
    Get-NetIPConfiguration -InterfaceAlias $interfaceAlias 


    # Show only IPv4 or IPv6 address(es)
    Get-NetAdapter -Name $interfaceAlias  | Get-NetIPAddress | Select-Object -ExpandProperty IPv4Address 
    Get-NetAdapter -Name $interfaceAlias  | Get-NetIPAddress | Select-Object -ExpandProperty IPv6Address 


    # "Set" ip configuration
    # .. only 1 IP address at at time .. 
    New-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress '172.17.17.1' -PrefixLength 24 -AddressFamily IPv4 -DefaultGateway '172.17.17.254'
    New-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress '172.17.17.2' -PrefixLength 24 -AddressFamily IPv4 # DefaultGateway aready configured
    New-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress 'fd83:08ab::1' -PrefixLength 64 -AddressFamily IPv6 

    # Modify: Set-NetIPAddress is ONLY valid if an IPAddress was already assigned !
    Set-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress '172.17.17.1' -PrefixLength 16 -AddressFamily IPv4 

    Remove-NetIPAddress -InterfaceAlias $interfaceAlias -Confirm:$false # Does not remove DefaultGateway
    Remove-NetRoute -InterfaceAlias $interfaceAlias -Confirm:$false

    # Switch to DHCP
    Set-NetIPInterface -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -Dhcp Enabled

    # DNS configuration: There is nothing like "Add-DnsClientServerAddress'
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses '8.8.8.8' 				# Array of addresses
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses '127.0.0.1','::1'       # Array of addresses

    # Remove DNS clientconfiguration
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ResetServerAddresses

#endregion


<# Old fashioned // This example code is intended to be used in cmd.exe:
 
    set nic="Ethernet"
    netsh interface ipv4 set address %nic% static 172.17.17.2 255.255.255.0 172.17.17.254
    netsh interface ipv4 set dnsserver %nic% static 8.8.8.8 primary
    netsh interface ipv4 set dnsserver %nic% static 194.77.8.1
    
    netsh interface ipv6 set address %nic%  2001:db8::a1    netsh interface ipv6 add route ::/0 %nic% 2001:db8::fe
    netsh interface ipv6 set dnsserver %nic% static 2001:db8::1 primary    
    
#>
