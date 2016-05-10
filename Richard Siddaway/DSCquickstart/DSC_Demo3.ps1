<#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo3.ps1

  Parameterising configurations: computer names

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
$computers

Configuration AddFile {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration  # <-- remove warning message

    Node $computername {       ## <-- name of remote machine
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
            Contents = "My first Configuration for $computername"
            Force = $true
            DependsOn = '[File]TestFolder'
        }
    }
}
##
## create multiple MOFS
Clear-Host
AddFile -ComputerName $computers -OutputPath .\MOF

## 
## create cim sessions
$cs = New-CimSession -ComputerName $computers
$cs

## check the file system on remote machines
##  no test folder
$rs = New-PSSession -ComputerName $computers
$rs

Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\ } | 
sort Fullname, PSComputerName |select Fullname, PSComputerName  

## apply configuration
##  CIM session simplifies accessing 
##  multiple machines
##  notice DON'T explicitly specify MOF file
##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## 
## test configuration
Clear-Host
Test-DscConfiguration -CimSession $cs -Verbose

Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\ } | 
sort Fullname, PSComputerName |select Fullname, PSComputerName  

## notice content
Invoke-Command -Session $rs -ScriptBlock {Get-Content -Path c:\TestFolder\TestFile1.txt}

## view configuration
Clear-Host
Get-DscConfiguration -CimSession $cs -Verbose

##
## need to specify data per machine
##  use configuration data
Clear-Host
$ConfigurationData = @{
  AllNodes = @(
    @{NodeName = 'W12R2TGT01';FileText='Configuration for W12R2TGT01'},
    @{NodeName = 'W12R2TGT02';FileText='W12R2TGT02 configuration'},
    @{NodeName = 'W12R2TGT03';FileText='My configuration for W12R2TGT03'}
  )
}
$ConfigurationData
$ConfigurationData.AllNodes

Configuration AddFile {
    Import-DscResource -ModuleName PSDesiredStateConfiguration  # <-- remove warning message

    Node $AllNodes.NodeName {       ## <-- name of remote machine
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
            Contents = $Node.FileText  # <-- accessing configuration data
            Force = $true
            DependsOn = '[File]TestFolder'
        }
    }
}
##
## create multiple MOFS
##  use configuration data NOT computer names
Clear-Host
AddFile -ConfigurationData $ConfigurationData -OutputPath .\MOF

##  MAKE IT SO
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

## and check
Clear-Host
Invoke-Command -Session $rs -ScriptBlock {Get-Content -Path c:\TestFolder\TestFile1.txt}

##
## CLEAN UP
Clear-Host

Configuration AddFile {
    Import-DscResource -ModuleName PSDesiredStateConfiguration  # <-- remove warning message

    Node $AllNodes.NodeName {       ## <-- name of remote machine

        File TestFolder {
            Ensure = 'Absent'
            Type = 'Directory'
            DestinationPath = 'C:\TestFolder'
            Force = $true
            DependsOn = '[File]TestFile'  # <-- remove file before folder
        }

        File TestFile {
            Ensure = 'Absent'
            Type = 'File'
            DestinationPath = 'C:\TestFolder\TestFile1.txt'
            Force = $true
        }
    }
}

AddFile -ConfigurationData $ConfigurationData -OutputPath .\MOF
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Wait -Verbose

Clear-Host
Invoke-Command -Session $rs -ScriptBlock {Get-ChildItem -Path c:\ } | 
sort Fullname, PSComputerName |select Fullname, PSComputerName  

Remove-CimSession -CimSession $cs
Remove-PSSession -Session $rs

## Questions?