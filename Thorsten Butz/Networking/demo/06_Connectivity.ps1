#region PING

    # The regular ping
    ping 192.168.0.1 -n 1
    $LASTEXITCODE

    # Dont fragment: -f
    # Buffersize: -f <byte>
    ping 8.8.8.8 -f -l 1471 -n 1 
    # => Mind the $LASTEXITCODE now!!

    # .NET
    $ping = New-Object System.Net.NetworkInformation.Ping
    $ping.Send('localhost') 
    Test-NetConnection -ComputerName localhost

 
    # WMI
    $wql = 'select * from Win32_PingStatus where Address="8.8.8.8"'
    $wql = 'select * from Win32_PingStatus where Address="127.0.0.1" or Address="::1" and TimeOut=1000'
    $wql = 'select * from Win32_PingStatus where Address="www.microsoft.com" and TimeOut=1000' # Default Timeout: 4000 ms 
    $wql = 'select * from Win32_PingStatus where Address="www.microsoft.com" and TimeOut=1000 and NoFragmentation="true" and BufferSize=2500' 
    Get-CimInstance -Query $wql | Format-List *


    # Investigate reasons for failure: StatusCode
    $wql = 'select * from Win32_PingStatus where Address="172.31.31.31"'
    Get-CimInstance -Query $wql | Select-Object -Property Address, StatusCode  

    <# StatusCode return codes (Win32_PingStatus)

          0='Success'
      11001='Buffer Too Small'
      11002='Destination Net Unreachable'
      11003='Destination Host Unreachable'
      11004='Destination Protocol Unreachable'
      11005='Destination Port Unreachable'
      11006='No Resources'
      11007='Bad Option'
      11008='Hardware Error'
      11009='Packet Too Big'
      11010='Request Timed Out'
      11011='Bad Request'
      11012='Bad Route'
      11013='TimeToLive Expired Transit'
      11014='TimeToLive Expired Reassembly'
      11015='Parameter Problem'
      11016='Source Quench'
      11017='Option Too Big'
      11018='Bad Destination'
      11032='Negotiating IPSEC'
      11050='General Failure'

    #>

    # WMI ping by cmdlet
    Test-Connection -ComputerName 127.0.0.1 -BufferSize 1600 -Count 1
    Test-Connection -ComputerName 127.0.0.1 -count 1 | Select-Object -Property __class
    Test-Connection www.microsoft.com -count 1 -Quiet

#endregion


#region TCP CONNECTIONS

    # psedit C:\Windows\System32\WindowsPowerShell\v1.0\Modules\NetTCPIP\Test-NetConnection.psm1

    Test-NetConnection -ComputerName ::1  # System.Net.NetworkInformation.ping // see above

    # Port scan
    $computername = 'sea-dc1'
    Test-NetConnection -ComputerName $computername -CommonTCPPort RDP 
    Test-NetConnection -ComputerName $computername -Port 53 -InformationLevel Quiet
    
    Test-NetConnection -ComputerName 'notexisting' -CommonTCPPort RDP -InformationLevel Quiet -WarningAction SilentlyContinue  
    Test-NetConnection -ComputerName '172.16.8.8' -CommonTCPPort RDP -InformationLevel Quiet -WarningAction SilentlyContinue  

    # WinRM/WSMan
    Test-NetConnection -ComputerName $computername -CommonTCPPort WINRM  -InformationLevel Quiet
    Test-WSMan -ComputerName $computername

    Remove-Variable -Name result -ErrorAction SilentlyContinue
    if (Test-WSMan -ComputerName $computername) { [bool]$result = $true ; $result}    

    Invoke-WebRequest http://www.google.de
    Get-NetTCPConnection -RemotePort 80
    Get-NetTCPConnection -RemoteAddress 192.168.0.1
    
    # Similiar to netstat.exe, but TCP only
    Get-NetTCPConnection -State Listen

    <# STATES:

    -- Closed
    -- CloseWait
    -- Closing
    -- DeleteTCB
    -- Established
    -- FinWait1
    -- FinWait2
    -- LastAck
    -- Listen
    -- SynReceived
    -- SynSent
    -- TimeWait
 
    #>

    # Gaterhing information
    Get-NetTCPConnection -State Established | Select-Object -First 1 -Property *

    # Find specific connections
    $cimsession = New-CimSession -ComputerName sea-dc1 

    Get-NetTCPConnection -RemotePort 5985 | Select-Object -Property RemoteAddress
    Get-NetTCPConnection -RemoteAddress 192.168.0.1 

    $cimsession | Remove-CimSession

#endregion