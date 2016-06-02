#region ROUTING

    Get-CimInstance -Namespace 'root/StandardCimv2' -ClassName MSFT_NetRoute
    Get-NetRoute # Module NetTCPIP

    New-NetRoute -DestinationPrefix '172.30.30.0/24' –InterfaceIndex 8 –NextHop 172.16.1.254 -PolicyStore ActiveStore # nonpermanent route
    New-NetRoute -DestinationPrefix '172.30.30.0/24' –InterfaceIndex 8 –NextHop 172.16.1.254 -PolicyStore PersistentStore # <== NOT IMPLEMENTED
    Get-NetRoute -DestinationPrefix '172.30.30.0/24' | Remove-NetRoute -Confirm:$false

    New-NetRoute -DestinationPrefix '2001:db8::/64' -InterfaceIndex 8 -NextHop '2003:7a:ee76:5a00::cec4'  # persistant (w/o "-Policystore")
    Get-NetRoute -DestinationPrefix '2001:db8::/64' | Remove-NetRoute -Confirm:$false

    # Find Persistant routes in IPv4 
    Get-CimInstance -ClassName Win32_IP4PersistedRouteTable | Select-Object -Property Caption, Nexthop # 
    # There is no correspondent IPv6 class!

    Find-NetRoute -RemoteIPAddress '8.8.8.8'
    Find-NetRoute -RemoteIPAddress '2001:4860:4860::8888'

    # Testing
    Test-NetConnection -ComputerName '8.8.8.8' -TraceRoute -InformationLevel Detailed # similiar to: tracert.exe -d 8.8.8.8

#endregion

#region NAME RESOLUTION
    
    Resolve-DnsName -Name 8.8.8.8 
    Resolve-DnsName -Name contoso.com -Server 192.168.0.1

    # Check the local cache
    Resolve-DnsName -Name www.microsoft.com -CacheOnly            # Utilize the local cache only
    Test-Connection -ComputerName www.microsoft.com -Count 1
    Clear-DnsClientCache # similiar to ipconfig.exe /flushdns

    # Limit the protocols: DNS only, NetBios only
    Resolve-DnsName sea-dc1 -LlmnrNetbiosOnly      # Do not use DNS
    Resolve-DnsName 8.8.8.8 -DnsOnly           # Only DNS, no LLMNR or Netbios used

    # Query specific records
    Resolve-DnsName -Name microsoft.com -Type MX
    Resolve-DnsName -Name sixxs.net -Type AAAA
    Resolve-DnsName -Name _gc._tcp.contoso.com -Type SRV | Select-Object Target, Port


    # Register DNS records
    Register-DnsClient # similiar to ipconfig.exe /registerdns

#endregion