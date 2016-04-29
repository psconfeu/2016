 <#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo1.ps1

  DSC features

  All machines Server 2012 R2 + WMF 5.0 second RTM
  Reference: - https://msdn.microsoft.com/en-us/PowerShell/dsc/overview

  WITH THANKS TO JASON HELMICK AND STEVE MURAWSKI FOR SAMPLE CODE
  all examples based on their workshop at PowerShell Summit 2016
#>

<#
   Ensure W12R2TGT01-03 are running
   Should have logged on to 1-3
   Check network connections
   only LAN connectivity needed
#>
Get-VM -ComputerName server02 -Name W12R2TGT*

Set-Location -Path C:\DSCworkshop
Remove-Item -Path C:\DSCworkshop\MOF\*.MOF* -Force
Remove-Item -Path C:\DSCworkshop\ModuleZips\* -Force
## check MOF folder is empty
Get-ChildItem -Path C:\DSCworkshop\MOF

##
## installing DSC for push
## need some IIS features for pull
## as we'll see later
## Add-WindowsFeature -Name DSC-Service

Get-WindowsFeature | where Installed -eq $true

<#
  DSC components:
    DSC module
    Resources
    Configurations
    MOF files
    LCM
#>

##
## PowerShell DSC cmdlets
Get-Module -ListAvailable PSDes*
Get-Command -Module PSDesiredStateConfiguration

##
##  builtin resources
Get-DscResource -Module PSDesiredStateConfiguration

<#
  Script resource is
  your get out of jail card

  better to  create a resource
#>

## other resources
##  PSGallery or roll your own
##  PSgallery holds DSC resource kit - open source
##  x resource modules
##  c resource modules
Find-DscResource
Find-DscResource | sort ModuleName -Unique | select ModuleName, Version

<#
  if no internet
  view file c:\DSCworkshop\resources.txt
#>
Get-Content -Path .\resources.txt
Import-Csv -Path .\resources.csv | sort ModuleName -Unique | select ModuleName, Version
Import-Csv -Path .\resources.csv | select -First 1 | Format-List

<#
 configurations use resources
 builtin resources
   https://msdn.microsoft.com/en-us/powershell/dsc/resources
 to see attributes put cursor
 on resource name and press
 CTRL spacebar

PUSH DSC => ITS YOUR RESPONSIBILITY TO GET RESOURCE ON TARGET
PULL DSC => PUT RESOURCE ON PULL SERVER AND ITS PULLED TO TARGET

#>

## this is declarative
## need to load configuration
##  cf function load
Configuration AddFile {
    
    File TestFolder {
        Ensure = 'Present'
        Type = 'Directory'
        DestinationPath = 'C:\TestFolder'
        Force = $true
    }

    File TestFile {
        Ensure = 'Present'
        Type = 'File'
        DestinationPath = 'C:\TestFolder\TestFile1.txt'
        Contents = 'My first Configuration'
        Force = $true
        DependsOn = '[File]TestFolder'
    }

}

##
## equivalent PowerShell commands
##  imperative
#New-Item -Path c:\ -Name 'TestFolder' -ItemType Directory
#New-Item -Path c:\TestFolder -Name TestFile1 -ItemType File
#Set-Content -Path c:\TestFolder\TestFile1.txt -Value 'My first Configuration'

##
## run the configuration
##  create MOF files
##  default is current location
##   OR subfolder with configuration name
AddFile -OutputPath .\MOF 

## notice mOF is localhost.mof
##  need to apply it to remote computers 
## so add Node key word
Configuration AddFile {
    Node W12R2TGT01 {       ## <-- name of remote machine
        File TestFolder {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\TestFolder'
            Force = $true
        }

        File TestFile {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'C:\TestFolder\TestFile1.txt'
            Contents = 'My first Configuration'
            Force = $true
            DependsOn = '[File]TestFolder'
        }
    }
}
AddFile -OutputPath .\MOF

##
## check MOFs
Get-ChildItem -Path C:\DSCworkshop\MOF
Clear-Host
Get-Content -Path C:\DSCworkshop\MOF\W12R2TGT01.mof

## LCM settings
##  defaults
##  modification in next demo
$cs = New-CimSession -ComputerName W12R2TGT01
$cs
Get-DscLocalConfigurationManager -CimSession $cs

## check the file system on remote machine
##  no test folder
$rs = New-PSSession -ComputerName W12R2TGT01
$rs
Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\ | Select FullName, LastAccessTime }

## apply configuration
##  use ComputerName or CIMsession
##  notice DON'T implicitly specify MOF file
##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

##
## check file system
Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\ | Select FullName, LastAccessTime}
Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\TestFolder}
Invoke-Command -Session $rs -ScriptBlock {Get-Content -Path c:\TestFolder\TestFile1.txt}

## test configuration
Clear-Host
Test-DscConfiguration -CimSession $cs -Verbose

## view configuration
Clear-Host
Get-DscConfiguration -CimSession $cs -Verbose

## now what happens if we apply configuration again?
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## DSC is IDEMPOTENT
##  means can apply configuration many times
##  and if already configured no action taken
##  i.e. always get same result
## cf multiplying by 1
5*1
5*1*1
5*1*1*1
5*1*1*1*1
## always get same result no matter how many times multiply by 1

##
## removing the configuration 
##  could use PowerShell script but better to
##  reverse the configurtaion
Clear-Host
Configuration AddFile {
    Node W12R2TGT01 {       ## <-- name of remote machine
        File TestFolder {
            Ensure = 'Absent'  # <-- CHANGED
            Type = 'Directory'
            DestinationPath = 'C:\TestFolder'
            Force = $true
            DependsOn = '[File]TestFile'  # <-- remove file before folder
        }

        File TestFile {
            Ensure = 'Absent'
            Type = 'File'
            DestinationPath = 'C:\TestFolder\TestFile1.txt'
            Contents = 'My first Configuration'
            Force = $true
        }
    }
}
AddFile -OutputPath .\MOF
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## view file system
Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\}

## test configuration
Clear-Host
Test-DscConfiguration -CimSession $cs -Verbose

## view configuration
Clear-Host
Get-DscConfiguration -CimSession $cs -Verbose

## clean up
Remove-CimSession -CimSession $cs
Remove-PSSession -Session $rs

## Questions?