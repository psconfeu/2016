<#  SESSIONS

    $computername = '192.168.0.'      # sea-nano1 
    $computername = '192.168.0.'      # sea-nano2
    $computername = '192.168.0.'      # sea-nano3     

    $pssession | Remove-PSSession
    $cimsession | Remove-CimSession
    $pssession = New-PSSession -ComputerName $computername -Credential $cred
    $cimsession = New-CimSession -ComputerName $computername -Credential $cred

#>

#region CONFIGURE WWW

    # If package "Microsoft-NanoServer-IIS-Package" is applied, the basic feature setup is done.
    Invoke-Command -Session $pssession -ScriptBlock {    
        Get-ChildItem C:\inetpub\wwwroot
        '<h1>Coming soon ..'  | Out-File C:\inetpub\wwwroot\default.html
    }

#endregion

#region CONFIGURE DNS

    Enter-PSSession -Session $pssession

    Get-Module -ListAvailable -name dns*        # NO DNS-SERVER MODULE AVALIABLE (YET)!
    
    $dnsrole = `
      Get-WindowsOptionalFeature -Online | 
        Where-Object { $_.FeatureName -like 'DNS*' }  
    
    Enable-WindowsOptionalFeature -Online -FeatureName $dnsrole.FeatureName    
    Get-Command -Module DnsServer

    # Create a standard primary zone
    Add-DnsServerPrimaryZone -ZoneName 'adatum.com' -ZoneFile db.adatum.com # ZoneFile is required to create a standard zone
    Add-DnsServerResourceRecord -ZoneName 'adatum.com' -A -IPv4Address 172.16.1.1 -Name test4
    Add-DnsServerResourceRecord -ZoneName 'adatum.com' -AAAA -IPv6Address '2001:db8::1:1' -Name test6
    
    # Test name resolution 
    nslookup test4.adatum.com localhost  # Resolve-DNSHostname does not exist on NANO
    nslookup test6.adatum.com localhost
    
    Exit-PSSession
    # On the W10 client you can utilize "Resolve-DnsName"
    Resolve-DnsName -Server $computername -Name test4.adatum.com
    Resolve-DnsName -Server $computername -Name test6.adatum.com

#endregion

#region TROUBLESHOOTING
    
    # Microsoft DNS server requires some traditonal TCP connections
    Test-NetConnection -ComputerName $computername -Port 53 -InformationLevel Quiet
    Test-NetConnection -ComputerName $computername -Port 135 -InformationLevel Quiet # RPC Endpoint Mapper

    # Create new rules: DEMO
    New-NetFirewallRule -DisplayName '_Block - RPC-EPMAP' -Protocol TCP -LocalPort 135 -Action Block -CimSession $cimsession
    Get-NetFirewallRule -DisplayName '_Block - RPC-EPMAP' -CimSession $cimsession  | Remove-NetFirewallRule 

    $rpcEpmRules = Get-NetFirewallRule -DisplayName '*RPC-EPMAP*' -CimSession $cimsession 
    $rpcEpmRules  | Select-Object -Property DisplayName, Enabled
    $rpcEpmRules  | Set-NetFirewallRule -Enabled False    

    Get-NetFirewallRule -DisplayName '_ICMPv*Echo' -CimSession $cimsession | Remove-NetFirewallRule -Confirm:$false

#endregion
