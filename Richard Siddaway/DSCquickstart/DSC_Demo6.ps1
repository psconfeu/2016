<#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo6.ps1

  Creating DSC resource

  All machines Server 2012 R2 + WMF 5.0 second RTM
  Reference: - https://msdn.microsoft.com/en-us/PowerShell/dsc/overview
  
  WITH THANKS TO JASON HELMICK AND STEVE MURAWSKI FOR SAMPLE CODE
  all examples based on their workshop at PowerShell Summit 2016
#>

Set-Location -Path C:\DSCworkshop
Remove-Item -Path C:\DSCworkshop\MOF\*.MOF -Force
Remove-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus' -Recurse -Force

## can create resources hard way or easy way
##   easy way is to use PowerShell class
##   shan't talk about hard way

<#
   view firewallstatus.psm1 and adbout_firewallstatus.help.txt
#>
Get-Content -Path C:\DSCworkshop\About_FirewallStatus.help.txt

$computername = 'W12R2TGT02'
$cs = New-CimSession -ComputerName $computername 
$rs = New-PSSession  -ComputerName $computername 

## create module for resource
##
New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules' -Name 'FirewallStatus' -ItemType Directory -Force
New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus' -Name 'en-US' -ItemType Directory -Force  

Copy-Item -Path C:\DSCworkshop\firewallstatus.psm1 -Destination 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus' -Force -Verbose
Copy-Item -Path C:\DSCworkshop\About_FirewallStatus.help.txt -Destination 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\en-US' -Force -Verbose

## create manifest
New-ModuleManifest -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\firewallstatus.psd1' `
-RootModule firewallstatus.psm1 -Guid ([GUID]::NewGuid()) -ModuleVersion 1.0 -Author 'Richard' `
-Description 'Class based resource to toggle Windows firewall' -DscResourcesToExport 'FirewallStatus'

##
## create a config
Configuration fwstatus {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$computername,

        [Parameter(Mandatory=$true)]
        [string]$profilename,

        [Parameter(Mandatory=$true)]
        [string]$enabled

    )

    Import-DscResource -ModuleName firewallstatus 

    Node $computername {
        FirewallStatus fwstoggle {
            ProfileName = $profilename 
            Enabled = $enabled
        }
    }
}

fwstatus -computername $computername -profilename Domain -enabled 'False' -OutputPath C:\DSCworkshop\MOF

Invoke-Command -Session $rs -ScriptBlock {
  Get-NetFirewallProfile | select Name, Enabled
}

##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## fails because need to get resource onto remote system because using PUSH
Invoke-Command -Session $rs -ScriptBlock {
  New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules' -Name 'FirewallStatus' -ItemType Directory
  New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus' -Name 'en-US' -ItemType Directory
}

Copy-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\*'  -Destination 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\' -Verbose -Force -Tosession $rs
Copy-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\en-US\*'  -Destination 'C:\Program Files\WindowsPowerShell\Modules\FirewallStatus\en-US\' -Recurse -Verbose -Force -Tosession $rs

##  MAKE IT SO
##    again
Clear-Host
Remove-DscConfigurationDocument -CimSession $cs -Stage Current -Verbose
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose -Force

## test
Invoke-Command -Session $rs -ScriptBlock {
  Get-NetFirewallProfile | select Name, Enabled
}

## test configuration
Clear-Host
Test-DscConfiguration -CimSession $cs -Verbose

## view configuration
Clear-Host
Get-DscConfiguration -CimSession $cs -Verbose

Get-CimSession | Remove-CimSession
Get-PSSession | Remove-PSSession

## Questions?