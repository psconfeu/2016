<#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo2.ps1

  Configuring LCM

  All machines Server 2012 R2 + WMF 5.0 second RTM
  Reference: - https://msdn.microsoft.com/en-us/PowerShell/dsc/overview

  WITH THANKS TO JASON HELMICK AND STEVE MURAWSKI FOR SAMPLE CODE
  all examples based on their workshop at PowerShell Summit 2016
#>

Set-Location -Path C:\DSCworkshop
Remove-Item -Path C:\DSCworkshop\MOF\*.MOF -Force

$computername = 'W12R2TGT01'
$cs = New-CimSession -ComputerName $computername 
$rs = New-PSSession  -ComputerName $computername 


## view LCM settings
##  defaults
# Notice - ActionAfterReboot - ConfigurationMode 
##       - ConfigurationModeFrequencyMins
#        - RebootNodeIfNeeded - REfreshMode
Get-DscLocalConfigurationManager -CimSession $cs

##
## configure LCM
##  with a configuration
##  notice decorator
[DSCLocalConfigurationManager()]
Configuration LCM {	
	Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Node $Computername
	{
		Settings # Hit Ctrl-Space for help
		{
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true		
		}
	}
}

# Notice MOF file name Computer.Meta.Mof 
LCM -computername $computername -OutputPath C:\DSCworkshop\MOF

##
##  apply the MOF
##  NOTICE CMDLET
##  MAKE IT SO
Clear-Host
Set-DSCLocalConfigurationManager -CimSession $cs -Path C:\DSCworkshop\MOF -Verbose

# Let's see if it worked!
Get-DscLocalConfigurationManager -CimSession $cs

##
##  Apply a config
##

## current status
Invoke-Command -Session $rs -ScriptBlock {Get-Service BITS}

##
## config
Configuration StartBITS {	
	Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Node $Computername
	{
        Service bits {
            Name = 'Bits'
            State = 'Running'
        }
	}
}

Startbits -computername $computername -OutputPath C:\DSCworkshop\MOF
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## check status
Invoke-Command -Session $rs -ScriptBlock {Get-Service BITS}

## now stop service 
Invoke-Command -Session $rs -ScriptBlock {Stop-Service BITS -PassThru }

## check status
Invoke-Command -Session $rs -ScriptBlock {Get-Service BITS}

##
Get-DscConfiguration -CimSession $cs
Get-DscConfigurationStatus -CimSession $cs 
Test-DscConfiguration  -CimSession $cs

##
## reboot server
Invoke-Command -Session $rs -ScriptBlock {Restart-Computer -Force} 

##
## NOT the best way to manage this
##  should use pull server then automatically checks
Get-PSSession | Remove-PSSession 
$rs = New-PSSession  -ComputerName $computername 
Invoke-Command -Session $rs -ScriptBlock {Get-Service BITS}

## cleanup
##  Notice CIM session survives reboot
Remove-DscConfigurationDocument -CimSession $cs -Stage Current -Verbose

## should really change the configuration!!!
Invoke-Command -Session $rs -ScriptBlock {Stop-Service BITS -PassThru }

Remove-CimSession -CimSession $cs
Remove-PSSession -Session $rs

## Questions?