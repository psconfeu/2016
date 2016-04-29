#region GROUNDWORK

    # Find the nano server
    Get-DhcpServerv4Lease -ScopeId 192.168.0.0 -ComputerName sea-dc1 |
       Where-Object { $_.HostName -like 'sea-nano*' }

    # Variables
    $computername = '192.168.0.142' #nano2
    $password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential('contoso\administrator',$password)
    
    # Workgroup: 
    # Try login through Recovery Console to change password first
    # $cred = New-Object System.Management.Automation.PSCredential('administrator',$password)

    # Allow workgroup computing 
    # DISCLAIMER: YoU shoud use the asterisk (*) only in lab environment only
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force       

    # Test connection
    Test-WSMAN -ComputerName $computername
    Test-WSMAN -ComputerName $computername -Credential $cred -Authentication Negotiate

#endregion 

#region PSSESSION

    # Establish a "Windows PowerShell Session"
    $pssession = New-PSSession -ComputerName $computername -Credential $cred

    # Connect via interactive session, This will also be reflected in the "commands pane", if visible    
    Enter-PSSession -Session $pssession            # MIND THE COMMANDS PANE!
    
    # If you do not want to connect via session, use this:
    # Enter-PSSession -ComputerName $computername -Credential $cred


    <# On the remote NANO server, try (for instance):
      whoami.exe, $env:username
      ipconfig.exe, Get-NetIPConfiguration      
      net share, Get-SMBShare
      Get-NetFirewallRule, netsh advfirewall firewall show rule name=all      
      
      Get-Command | Measure-Object                  <= MIND THE COMMANDS PANE 
      psedit c:\windows\System32\drivers\etc\hosts  <= REMOTE EDITING 
    #>

    # Send commands
    Invoke-Command -ComputerName $computername -Credential $cred -ScriptBlock {
      #Get-NetAdapter | Select-Object -Property MacAddress, LinkSpeed, AdminStatus, DriverFileName, InterfaceName
      Get-NetIPConfiguration | Select-Object -Property InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer
    }

    # Copy via PSRemoting and session configuration 
    Copy-Item -Path c:\demo\nano\demofile.txt -Destination 'c:\' -ToSession $pssession

    Invoke-Command -Session $pssession -ScriptBlock { 
      Get-ChildItem -Path 'c:\'  
      Get-Content -Path 'c:\demofile.txt'    
    }
    
    Invoke-Command -Session $pssession -ScriptBlock { 
      Remove-Item -Path c:\demofile.txt 
    }
    
    $pssession | Remove-PSSession

#endregion

#region CIMSESION

    # Configure NANO server via CIM 
    # ATTENTION: PSSession (above) -ne CIMSession (below)
    
    $cimsession = New-CimSession -ComputerName $computername -Credential $cred

    # Create new rules
    New-NetFirewallRule -DisplayName '_ICMPv4Echo' -Protocol "ICMPv4" -IcmpType 8 -Enabled True -Action Allow -CimSession $cimsession
    New-NetFirewallRule -DisplayName '_ICMPv6Echo' -Protocol "ICMPv4" -IcmpType 8 -Enabled True -Action Allow -CimSession $cimsession

    Get-NetFirewallRule -DisplayName '_ICMPv*Echo' -CimSession $cimsession | Select-Object -Property DisplayName, Enabled
    Get-NetFirewallRule -DisplayName '_ICMPv*Echo' -CimSession $cimsession | Remove-NetFirewallRule -Confirm:$false

    # Enable existing rules
    $smbrules = Get-NetFirewallRule -DisplayName 'File and Printer Sharing*' -CimSession $cimsession
    $smbrules | Select-Object -Property DisplayName, Profile, Enabled
    $smbrules | Set-NetFirewallRule -Enabled True
    
    # Create a shared folder
    Test-Path "\\$computername\c`$\depot" 
    New-Item -Path "\\$computername\c`$\depot" -ItemType Directory

    # Remember? There was no cmdlet "Get-SMBShare" ...
    Get-SmbShare -CimSession $cimsession
    New-SmbShare -CimSession $cimsession -Name depot -Path 'c:\depot' -FullAccess Administrators
    Get-SmbShare -CimSession $cimsession -Name depot | Remove-SmbShare -Force

    $cimsession | Remove-CimSession

#endregion