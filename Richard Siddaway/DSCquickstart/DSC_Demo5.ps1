<#
  DSC quick start 
  PowerShell European Conference 2016

  DSC_Demo5.ps1

  Creating and using pull server

  All machines Server 2012 R2 + WMF 5.0 second RTM
  Reference: - https://msdn.microsoft.com/en-us/PowerShell/dsc/overview
  
  WITH THANKS TO JASON HELMICK AND STEVE MURAWSKI FOR SAMPLE CODE
  all examples based on their workshop at PowerShell Summit 2016
#>

Set-Location -Path C:\DSCworkshop
Remove-Item -Path C:\DSCworkshop\MOF\*.MOF -Force

## pull server
$computername = 'W12R2TGT03'
$cs = New-CimSession -ComputerName $computername 
$rs = New-PSSession  -ComputerName $computername 

## find modules with resources
##  just taking 'official' DSC resource kit
#Find-Module -Tag DscResourceKit | Install-Module

<#
## save modules locally for future use
Find-Module -Tag DscResourceKit | Save-Module -Path C:\Source\DscResources

## then copy to C:\Program Files\WindowsPowerShell\Modules
#>

##
##  need some modules on pull server
#Invoke-Command -Session $rs {Install-Module -name xPSDesiredStateConfiguration -force} 

## could make ths a configuration !!
## If no Internet
##  copy across a remoting session
Copy-Item -Path C:\Source\DscResources\xPSDesiredStateConfiguration\* -Destination 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration' -Recurse -Force -Verbose -ToSession $rs

##
## contents of xPSDesiredStateConfiguration
Get-DscResource -Module xPSDesiredStateConfiguration
Get-DscResource -Module xPSDesiredStateConfiguration -Name xDSCWebService | select -ExpandProperty Properties

<#
YOU CAN SET UP A PULL SERVER BASED ON AN SMB SHARE

DON'T

NOT AS VERSATILE - ONLY USE FOR TESTING PULL CONCEPT
https://msdn.microsoft.com/en-us/powershell/dsc/pullserversmb
#>

## pull server info
## https://msdn.microsoft.com/en-us/powershell/dsc/pullserver
## to create pull server use a configuration
## this is a simple configuration
##   can make more complex by configuring IIS further
$ConfigurationData=@{
    # Node specific data
    AllNodes = @(
       # All Servers need following identical information 
       @{
            NodeName = '*' 
       },

       # Unique Data for each Role
         @{
            NodeName = 'W12R2TGT03'
            Role = @('PullServer')
  
            CertThumbPrint = Invoke-Command -Computername 'W12R2TGT03' {Get-Childitem Cert:\LocalMachine\My | where Subject -Like '*W12R2TGT03.Manticore.org*' | Select-Object -ExpandProperty ThumbPrint}
        }

    );
} 
$ConfigurationData.AllNodes

Configuration Pullserver
{
    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration, xPSDesiredStateConfiguration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'PullServer'}.NodeName {
    
#       # Install DSC Service & web server for a pull server
         WindowsFeature DSCServiceFeature {

            Ensure = "Present"
            Name   = "DSC-Service"
        }


#       # GUI Remote Management of IIS requires the following:

        WindowsFeature Management {

            Name = 'Web-Mgmt-Service'
            Ensure = 'Present'
            DependsOn = @('[WindowsFeature]DSCServiceFeature')
        }

        Registry RemoteManagement {
            Key = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server'
            ValueName = 'EnableRemoteManagement'
            ValueType = 'Dword'
            ValueData = '1'
            DependsOn = @('[WindowsFeature]DSCServiceFeature','[WindowsFeature]Management')
       }

       Service StartWMSVC {
            Name = 'WMSVC'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[Registry]RemoteManagement'

       }

       xDscWebService PSDSCPullServer {
        
            Ensure = "Present"
            EndpointName = "PullServer"
            Port = 8080   # <--------------------------------------- Why this port?
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PullServer"
            CertificateThumbPrint =  $Node.CertThumbprint # <---------------------------------- Certificate Thumbprint
            ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State = "Started"
            DependsOn = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer {
        
            Ensure = "Present"
            EndpointName = "ComplianceServer"
            Port = 9080
            PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\ComplianceServer"
            CertificateThumbPrint = "AllowUnencryptedTraffic" #<--------------------------HTTP reporting site
            State = "Started"
            DependsOn = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }


    } #End Node Role Web

} # End Config

Pullserver -ConfigurationData $ConfigurationData -outputPath C:\DSCworkshop\MOF

## runs as job
##  because NOT using -Wait
Clear-Host
Start-DscConfiguration -CimSession $cs -Path C:\DSCworkshop\MOF -Verbose 

<#
  use Get-Job to view progress
  use Receive-Job to view data
#>
while ($true){Get-Job; Start-Sleep -Seconds 10}

Restart-computer -ComputerName W12R2TGT03 -Wait -Force

## recreate remote session
Get-PSSession | Remove-PSSession
$rs = New-PSSession  -ComputerName $computername 

# Test  Pull Server
Start-Process -FilePath iexplore.exe https://W12R2TGT03.manticore.org:8080/PSDSCPullServer.svc

##
## configure target machine to use pull server
##
[DSCLocalConfigurationManager()]
Configuration LCMpull 
{
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName,

            [Parameter(Mandatory=$true)]
            [string]$guid, # <----- identifies machine

            [Parameter(Mandatory=$true)]
            [string]$ThumbPrint #<---- pull server cert

        )      	
	Node $ComputerName {
	
		Settings {
		
			AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Pull' #<-------- change mode
			ConfigurationID = $guid #<--------  identifier
            }

            ConfigurationRepositoryWeb DSCHTTPS {
                ServerURL = 'https://W12R2TGT03.manticore.org:8080/PSDSCPullServer.svc'
                CertificateID = $thumbprint #<------- cert
                AllowUnsecureConnection = $false #<----- force security
            }
 	}
}

## target computer
$psclient = 'W12R2TGT01'
$pscs = New-CimSession -ComputerName 'W12R2TGT01'
Get-DscLocalConfigurationManager -CimSession $pscs

# Create Guid for the computers
$guid=[guid]::NewGuid()
$guid

## cert of pull server
$thumbprint=Invoke-Command -Computername $computername {Get-Childitem Cert:\LocalMachine\My | where Subject -Like '*W12R2TGT03.Manticore.org*' | Select-Object -ExpandProperty ThumbPrint}
$thumbprint

# Create the Computer.Meta.Mof in folder
LCMpull -computername $psclient -Guid $guid -Thumbprint $Thumbprint -OutputPath C:\DSCworkshop\MOF 
##
##  apply the MOF
##  NOTICE CMDLET
##  MAKE IT SO
Set-DSCLocalConfigurationManager -CimSession $pscs -Path C:\DSCworkshop\MOF -Verbose

# Let's see if it worked!
Get-DscLocalConfigurationManager -CimSession $pscs

##
## test modules currently installed
Invoke-Command -ComputerName $psclient -ScriptBlock {
  Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\Modules'
}

## To create  config to pull:
##  1. Create config
##  2. Copy to pull server
##  3. Ensure resources are on pull server
##  4. force pull (for demo)

## test target machine
Invoke-Command -ComputerName $psclient  -ScriptBlock {
  Get-SmbShare | select Name, Path, Description
}

## lets create an SMB share
Configuration stdShare {
    param
        (
            [Parameter(Mandatory=$true)]
            [string[]]$ComputerName

        )      	
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSmbShare

	Node $ComputerName {
   
    
        ## create folder and file
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

        xSmbShare StandardShare
        {
            Ensure = "Present" 
            Name   = "Standard"
            Path = 'C:\TestFolder'  
            Description = "This is a test SMB Share"
            ConcurrentUserLimit = 0          
        }
    }
} 

stdShare -ComputerName $psclient -OutputPath C:\DSCworkshop\MOF

$psclientid = Get-DscLocalConfigurationManager -CimSession $pscs |
select -ExpandProperty ConfigurationID

## rename moff file using the target's guid
Get-ChildItem -Path "C:\DSCworkshop\MOF"

Get-ChildItem -Path "C:\DSCworkshop\MOF\$psclient.mof" |
Rename-Item -NewName "C:\DSCworkshop\MOF\$psclientid.mof"

Get-ChildItem -Path "C:\DSCworkshop\MOF"

## create checksum 
New-DscChecksum -Path "C:\DSCworkshop\MOF\$psclientid.mof" -Force
Get-ChildItem -Path "C:\DSCworkshop\MOF\$psclientid.*"

## copy config and checksum to pull server
##  make sure Windows firewall turn off on pull server
Get-ChildItem -Path "C:\DSCworkshop\MOF\$psclientid.*" |
Copy-Item -Destination "\\W12R2TGT03\C$\Program Files\WindowsPowerShell\DscService\Configuration" -Force -Verbose

Invoke-Command -Session $rs -ScriptBlock {
  Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
}

## need to send xSmbShare to pull server
##  must use module version
$module = Get-Module -ListAvailable xSmbShare
$version = ((Select-String -Path $module.path -Pattern 'ModuleVersion' -SimpleMatch) -split '= ' -replace "'", "")[1]
$version

## ZIP module contents
##   best to copy one you actually used
Compress-Archive -Path 'C:\Program Files\WindowsPowerShell\Modules\xSmbShare\1.1.0.0\*' -DestinationPath "C:\DSCworkshop\ModuleZips\xSMBShare_$version.zip" -Force

New-DscChecksum -Path "C:\DSCworkshop\ModuleZips\xSMBShare_$version.zip" -Force

Get-ChildItem -Path "C:\DSCworkshop\ModuleZips\xSMBShare_$version.*"

## copy to pull server
Get-ChildItem -Path "C:\DSCworkshop\ModuleZips\xSMBShare_$version.*" |
Copy-Item -Destination "\\W12R2TGT03\C$\Program Files\WindowsPowerShell\DscService\Modules" -Force -Verbose

## test copy
Invoke-Command -Session $rs -ScriptBlock {
  Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\DscService\Modules'
}

## eventaully pull server will be contacted by client
##  lets force it
##  check networking !!!
Update-DscConfiguration -CimSession $pscs -Verbose -Wait

Test-DscConfiguration -CimSession $pscs -Verbose

Invoke-Command -ComputerName $psclient  -ScriptBlock {
  Get-SmbShare | select Name, Path, Description
}

Invoke-Command -ComputerName $psclient  -ScriptBlock {
  Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\Modules'
}

Get-PSSession | Remove-PSSession
Get-CimSession | Remove-CimSession

## Questions?