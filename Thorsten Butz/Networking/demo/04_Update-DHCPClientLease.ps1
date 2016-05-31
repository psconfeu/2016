#requires -Version 2
function Update-DHCPClientLease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Position=0)]
        [int]$InterfaceIndex,
        [string]$Computername = $env:computername,
        [switch]$release, 
        [switch]$renew
    )  
  
    if (!($release) -and !($renew)) {    
        "Usage: 
            Update-DHCPClientLease -release 
            Udate-DHCPClientLease -renew
            Update-DHCPClientLease -release -renew
        Update-DHCPClientLease -InterfaceIndex 11 -renew"

        return
    }      

    $verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

    if ($InterfaceIndex) {  
        [string]$wql = "select * from Win32_NetworkAdapterConfiguration where IPEnabled='true' and DHCPEnabled='true' and InterfaceIndex=$InterfaceIndex" 
    }
    else {
        [string]$wql = "select * from Win32_NetworkAdapterConfiguration where IPEnabled='true' and DHCPEnabled='true'" 
    }

    [array]$nics = Get-WmiObject -Query $wql

    if ($Verbose) {
        $nics | Format-List -Property Description,*index 
    }

    foreach ($nic in $nics) {

        if ($release) {
            $result1 = $nic.ReleaseDHCPLease()      
            if ($verbose) {'ReleaseDHCPLease return code: ' + $result1.returnvalue}
        }

        if ($renew) {
            $result2 = $nic.RenewDHCPLease()      
            if ($verbose) {'RenewDHCPLease return code: ' + $result2.returnvalue}
        }        

    }
}

# Main

# Verifying configuration
$InterfaceIndex # = 8
Get-NetAdapter -InterfaceIndex $InterfaceIndex  | Get-NetIPAddress
Get-NetIPConfiguration | Format-List Interface*, InterfaceIndex, IPv4Address

# Updating Lease
Update-DHCPClientLease -release -InterfaceIndex 8 -Verbose
Get-NetIPConfiguration -InterfaceIndex $InterfaceIndex | Update-DHCPClientLease -renew -Verbose
