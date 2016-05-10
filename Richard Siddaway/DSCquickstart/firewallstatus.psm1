#requires -version 5.0

## define values for properties
enum FWprofile {
    Domain
    Private
    Public
}


##
## need [DscResource()] to show class is a resource
##
[DscResource()]
class FireWallStatus {

# A DSC resource must define at least one key property
    [DscProperty(Key)]
    [FWprofile]$profileName

    [DscProperty(Mandatory)]
    [string]$enabled


    [FirewallStatus]Get() {
        Write-Verbose "[$(Get-Date)] Starting Get method"

        $fwprofile = Get-NetFirewallProfile -Name $this.profileName
        $test = [Hashtable]::new()
        $test.Add('ProfileName',$fwprofile.Name)
        $test.Add('Enabled',$fwprofile.Enabled)

        Write-Verbose "[$(Get-Date)] Ending Get method"

        return $test
    }

    ## set returns nothing
    [void]Set() {
        Write-Verbose "[$(Get-Date)] Starting Set method"

        Write-Verbose "Setting Firewall profile $this.profilename to $this.Enabled"

        Set-NetFirewallProfile -Name $this.profileName -Enabled $this.enabled

        Write-Verbose "[$(Get-Date)] Ending Set method"
    }


    [bool]Test() {
        Write-Verbose "[$(Get-Date)] Starting Test method"
        Write-Verbose "Target status is $($this.enabled)"

        $result = Get-NetFirewallProfile -Name $this.profileName

        if ($result.Enabled -eq $this.enabled) {
            Write-Verbose "Actual result is $($result.Enabled)"
            Write-Verbose "Nothing to configure"
            
            return $true 
        }
        else {
            Write-Verbose "Actual result is $($result.Enabled)"
            Write-Verbose "Need to configure"
            
            return $false 
        }

        Write-Verbose "[$(Get-Date)] Ending Test method"
    }

}