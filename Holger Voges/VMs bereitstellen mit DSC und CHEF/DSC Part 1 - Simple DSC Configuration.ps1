<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 1: Simple DSC-Configuration
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# To install an application via DSC, you need its GUID. It can be retrieved through different ways. 
# One is to use WMI:
get-wmiobject -Query "Select * from Win32_Product" | ogv

# A Simple DSC-Configuration. It will check if 7-Zip is installed on the Computer (node) localhost and, 
# if not present, will install it. 
#region Installapplication
Configuration InstallApplication
{

Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node localhost
    {
          Package Install7Zip
         {
             Ensure = 'Present'
             Name = '7-Zip 15.14 (x64 edition)'
             Path = 'C:\7z1514-x64.msi'
             ProductId = '{23170F69-40C1-2702-1514-000001000000}'
             Logpath = 'c:\temp\install.log'
         }
    }
}

#endregion

# A more complex configuration
# The Configuration defines dependencies (.net framework has to be installed prior to 7-zip)
# Also, an Environment-Variable is set and a configuration-file must be present. 
#region InstallApplication2

Configuration InstallApplication2
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    
    Node Localhost
    {
        WindowsFeature DotNet
        {
            Ensure = 'Present'
            Name = 'NET-Framework-45-Core'
        }
 
        Environment AppEnvVariable
        {
            Ensure = 'Present'
            Name = 'ConfigFileLocation'
            Value = 'C:\temp\config.ini'
        }

        File ConfigFile
        {
            DestinationPath = 'C:\temp\config.xml'
            Contents = 'Installed=true'
        }

        Package Install7Zip
        {
             Ensure = 'Present'
             Name = '7-Zip 15.14 (x64 edition)'
             Path = 'C:\7z1514-x64.msi'
             ProductId = '{23170F69-40C1-2702-1514-000001000000}'      
             DependsOn = @('[WindowsFeature]DotNet')
        }

    }
}

#endregion