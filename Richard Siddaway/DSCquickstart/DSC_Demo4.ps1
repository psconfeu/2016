<#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo4.ps1

  Parameterising configurations:
  Roles and nested configurations

  All machines Server 2012 R2 + WMF 5.0 second RTM
  Reference: - https://msdn.microsoft.com/en-us/PowerShell/dsc/overview
  
  WITH THANKS TO JASON HELMICK AND STEVE MURAWSKI FOR SAMPLE CODE
  all examples based on their workshop at PowerShell Summit 2016
#>

Set-Location -Path C:\DSCworkshop
Remove-Item -Path C:\DSCworkshop\MOF\*.MOF -Force

<#
  So far seen configuration for single node
  with hard coded computer name.

  Often need to apply same configuration to
  many computers; or make reusable across machines
#>
$computers = 'W12R2TGT01', 'W12R2TGT02', 'W12R2TGT03'

##
## create connectivity
$cs = New-CimSession -ComputerName $computers
$rs = New-PSSession -ComputerName $computers

<#
   Your task - should you choose to accept it - is:
   Install the following Windows features:
     Hyper-V-PowerShell on W12R2TGT01
     RSAT-AD-PowerShell on W12R2TGT02
     RSAT-DNS-Server on W12R2TGT03

     could just use configuration data as previously
     but...
#>

##
## view current state
Invoke-Command -Session $rs -ScriptBlock {
Get-WindowsFeature -Name Hyper-V-PowerShell, RSAT-AD-PowerShell, RSAT-DNS-Server
} | sort Name | select Name, DisplayName, Installed, PSComputerName

##
## first define configuration data
##
## need to specify data per machine
##  use configuration data
Clear-Host

$ConfigurationData = @{
  AllNodes = @(
    @{NodeName = 'W12R2TGT01';Role = 'Hyper-V'},
    @{NodeName = 'W12R2TGT02';Role = 'AD'},
    @{NodeName = 'W12R2TGT03';Role = 'DNS'}
  )
}
$ConfigurationData.AllNodes

Configuration RoleConfiguration
{
  param ($Roles)
  switch ($Roles) {
    'Hyper-V' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature Hyper-V {
            Ensure = 'Present'
            Name = 'Hyper-V-PowerShell'
        }
    }     
    
    'AD' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature AD {
            Ensure = 'Present'
            Name = 'RSAT-AD-PowerShell'
        } 
    }

    'DNS' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature DNS {
            Ensure = 'Present'
            Name = 'RSAT-DNS-Server'
        } 
    }
 }
   
}

Configuration ToolsConfig 
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $allnodes.NodeName
    {
        RoleConfiguration ServerRoles
        {
        	Roles = $Node.Role
    	}
    }
}

##
## configurations stored as functions
Get-ChildItem function:
Get-ChildItem function:ToolsConfig | Format-List *
Get-Command toolsconfig -Syntax

##
## create multiple MOFS
##  use configuration data NOT computer names
##  use TOP level configuration
Clear-Host
ToolsConfig -ConfigurationData $ConfigurationData -OutputPath .\MOF

##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

##
## view  state
Invoke-Command -Session $rs -ScriptBlock {
Get-WindowsFeature -Name Hyper-V-PowerShell, RSAT-AD-PowerShell, RSAT-DNS-Server
} | sort Name | select Name, DisplayName, Installed, PSComputerName

## test configuration
Clear-Host
Test-DscConfiguration -CimSession $cs -Verbose

## view configuration
Clear-Host
Get-DscConfiguration -CimSession $cs -Verbose

##
## back out the configuration
Configuration RoleConfiguration
{
  param ($Roles)
  switch ($Roles) {
    'Hyper-V' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature Hyper-V {
            Ensure = 'Absent'
            Name = 'Hyper-V-PowerShell'
        }
    }     
    
    'AD' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature AD {
            Ensure = 'Absent'
            Name = 'RSAT-AD-PowerShell'
        } 
    }

    'DNS' {
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        WindowsFeature DNS {
            Ensure = 'Absent'
            Name = 'RSAT-DNS-Server'
        } 
    }
 }
   
}

Configuration ToolsConfig 
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $allnodes.NodeName
    {
        RoleConfiguration ServerRoles
        {
        	Roles = $Node.Role
    	}
    }
}

<#
  Rather than create new configuration 
  could parameterise Present/Absent 
  in configuration data

  Home work is to create the configuration data 
  to do that and modify the config to work with it
#>

Clear-Host
ToolsConfig -ConfigurationData $ConfigurationData -OutputPath .\MOF

##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

##
## view  state
Clear-Host
Invoke-Command -Session $rs -ScriptBlock {
Get-WindowsFeature -Name Hyper-V-PowerShell, RSAT-AD-PowerShell, RSAT-DNS-Server
} | sort Name | select Name, DisplayName, Installed, PSComputerName

## clean up
Remove-CimSession -CimSession $cs
Remove-PSSession -Session $rs

## Questions?