$number06 = {
  'MR. BOOL AND THE EVIL SWITCH'  
}

#region PROBLEM STATEMENT

 Get-NetFirewallRule -Enabled true
 New-ADUser -Name 'John' -Enabled $true 
 Remove-ADUser -Identity 'John' -Confirm:$false

#endregion

#region INVESTIGATION

    # A: Custom type/System Enum: true, false, 1, 2
    Get-NetFirewallRule -Enabled True

    # B: Boolean: $true, $false, 0 , 1
    New-ADUser -Name 'John' -Enabled $true 

    # Switch:
    try { Get-ADUser -Identity 'John' } catch { New-ADUser -Name 'John' -Enabled $true }

    Remove-ADUser -Identity 'John' -Confirm:$false   
    Remove-ADUser -Identity 'John' -Confirm:0      

#endregion 

#region YET ANTHER EXAMPLE, EVEN MORE CONFUSING

    function RunNetworkChecks {
     [CmdletBinding()]  
    #[CmdletBinding(PositionalBinding=$false)]   #requires -version 3
      param(
        [switch]$enableWMICheck, 
        [bool]$enableWSManCheck, 
        [ValidateSet('True','False')]
        [string]$enableRDPCheck='False'
      )
    
      "WMI check enabled?   $enableWMICheck"
      "WSMan check enabled? $enableWSManCheck"  
      "RDP check enabled?   $enableRDPCheck" 
  
      # To be continued later  ..
    }

    RunNetworkChecks
    RunNetworkChecks -enableWMICheck:$true -enableWSManCheck:$false -enableRDPCheck:true
    RunNetworkChecks -enableWMICheck $true -enableWSManCheck $false -enableRDPCheck true  # SYNTAX ERROR // ADV. FUNCTION
    RunNetworkChecks $true $true

#endregion 