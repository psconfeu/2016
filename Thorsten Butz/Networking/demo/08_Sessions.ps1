#region GROUNDWORK

    ## Creating credentials objects (lab only!)

    # A: $cred = Get-Credential
    # B: Lab only
    $username = 'administrator@contoso.com'
    $password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'
    $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

    ## Allow workgroup computing 
    # DISCLAIMER: YoU shoud use the asterisk (*) only in lab environment only
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force     
    
    $computername1 = 'sea-dc1'
    $computername2 = 'sea-cl3'
    $computernames = $computername1, $computername2

    Test-WSMan -ComputerName $computername1 
    $computernames | Test-WSMan -Authentication Negotiate 

    # A little bit longer than above ...
    foreach ($computername in $computernames) 
    {  
        if (Test-WSMan -ComputerName $computername -Authentication Negotiate -ErrorAction SilentlyContinue) 
        {
            $computername } else { Write-Warning $computername 
        } 
    }
#endregion

#region NON-PERSISTENT CONNECTIONS

    ## Exammple A: Remoting by parameter
    Get-NetIPConfiguration -ComputerName $computername1  # DOES NOT PROVIDE a "Credential" parameter !
    
    ## Example B: Remoting via Invoke-Command without PSSession // ONE to MANY
    Invoke-Command -ComputerName $computernames -Credential $cred -ScriptBlock {
        Get-NetIPConfiguration 
    } | Select-Object Computername, InterfaceAlias, IPv?Address  |  Out-GridView -Title 'IPAddresses'

#endregion

#region PERSISTENT CONNECTIONS    

    ## Example C: PSSession // ONE to MANY

    # Create a (persistant) connection
    $PSSession = New-PSSession -ComputerName $computernames -Credential $cred

    # Run commands
    Invoke-Command -Session $PSSession -ScriptBlock {
            Get-NetIPConfiguration 
    } | Select-Object InterfaceAlias, IPv?Address  |  Out-GridView -Title 'IPAddresses' 

    # Remove connection
    $PSSession | Remove-PSSession


    ## Example D: CIMSessions // ONE to ONE
    
    # Create CIMSession // ONE to ONE
    $cimsession = New-CimSession -ComputerName $computername1 -Credential $cred -Authentication Default

    # Utilize CIMSession 
    Get-NetIPConfiguration -CimSession $cimsession | Select-Object InterfaceAlias, IPv?Address |  Out-GridView -Title "IPAddresses on $computername1" 

    # Destroy CIMSession
    $cimsession | Remove-CimSession

#endregion