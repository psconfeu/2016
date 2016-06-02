#region DEFINE CLASS

    Enum Vendor
    {
      HP = 1
      Dell = 2
      IBM = 3
      Lenovo = 4  
    }

    class Server
    {
      # Properties
      [string]$Computername
      [vendor]$Vendor
      [string]$Model
      [int64]$Contract
      [datetime]$LastEchoReply
      [datetime]$LastRDPConnection
      [datetime]$LastWSManConnection

      # Methods
      [string]GetBasicInfo() 
      {
        return "$($this.Computername) (Contract: $($this.Contract))"
      }

      RunTests(){
        # ICMP Echo 
        $this.LastEchoReply = $(if (Test-Connection -ComputerName $this.computername -Count 1 -Quiet) {Get-Date}
          else { Get-Date -Date 0 })

        # RDP
        try {
          $this.LastRDPConnection = $(if (Test-NetConnection -ComputerName $($this.computername) -CommonTCPPort RDP `
            -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue){ Get-Date } 
              else { Get-Date -Date 0 })
        } 
        catch 
        {
          $this.LastRDPConnection = Get-Date -Date 0
        }
       # WSMan
       $this.LastWSManConnection = $(if (Test-WSMan -ComputerName $this.computername -ErrorAction SilentlyContinue) {get-date} 
         else { Get-Date -Date 0 })      
      }

      # Constructor
      Server($computername)
      {
        $this.Computername = $Computername
        $this.RunTests()
      }
     
      # Overloading          
      Server($computername,$contract)
      {
        $this.Computername = $Computername
        $this.Contract = $Contract
        $this.RunTests()
      }   
    }

#endregion

#region USE CLASS

    # Use it!
    [Server]::new('127.0.0.1')

    [Server]::new('sea-dc1')

    $dc1 = [Server]::new('sea-dc1')

    $dc1 | Format-Table -Property Computername, Vendor, Model, 
      @{n='Contract';e={ if ($_.Contract -ne 0){$_.Contract }}},
      @{n='LastEchoReplay';e={ if ($_.LastEchoReply -eq 0){'(never)'} else {$_.LastEchoReply }}},
      @{n='LastRDPConnection';e={ if ($_.LastRDPConnection -eq 0){'(never)'} else {$_.LastRDPConnection }}},
      @{n='LastWSManConnection';e={ if ($_.LastWSManConnection -eq 0){'(never)'} else {$_.LastWSManConnection }}}

#endregion