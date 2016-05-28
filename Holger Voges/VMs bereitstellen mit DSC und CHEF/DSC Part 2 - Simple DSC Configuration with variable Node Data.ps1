<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 2: Simple DSC-Configuration with Configuration-Block
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# To make it easier to differentiate the DSC-Configuration from it´s variable values like 
# the computernames, it is possible to call the Configuration Configurationdata. Configurationdata
# is passed as a hashtable which contains an array with the Name Allnodes. Allnodes itself contains
# a hashtable for each node to configure and can also contain a global configuration by defining a node
# named *

$ConfigData = @{
AllNodes = @(
    @{
        NodeName = 'chefDemoNode'
        Roles = @('Web')

    },
    @{
        NodeName = 'server2'
        Roles = @('Hyper-V')
    },
    @{
        NodeName = '*'
        ExampleSoftware = @{
            Name = '7Zip'
            ProductId = '{23170F69-40C1-2702-1514-000001000000}'
            SourcePath = 'c:\Temp\7z1514-x64.msi'
        }
    }
);
    NonNodeData = @{
        ConfigFileContents = (Get-Content 'Config.xml')
    }
}

Configuration InstallServer
{
    Node $AllNodes.NodeName
    {
        WindowsFeature DotNet
        {
            Ensure = 'Present'
            Name = 'NET-Framework-45-Core'
        }
    }

    Node $AllNodes.Where({ $_.Roles -contains 'Web' }).NodeName
    {
        Environment AppEnvVariable
        {
            Ensure = 'Present'
            Name = 'ConfigFileLocation'
            Value = $Node.ExampleSoftware.ConfigFile
        }

        File ConfigFile
        {
            DestinationPath = $Node.ExampleSoftware.ConfigFile
            Contents = $ConfigurationData.NonNodeData.ConfigFileContents
        }

        Package InstallExampleSoftware
        {
            Ensure = 'Present'
            Name = $Node.ExampleSoftware.Name
            ProductId = $Node.ExampleSoftware.ProductId
            Path = $Node.ExampleSoftware.SourcePath
            DependsOn = @('[WindowsFeature]DotNet')
        }
    }
}

# Install with external Configuration
# Install from a variable (as definied in the head of this file)
InstallServer -ConfigurationData $configData

# In practice, you divide the DSC-Configuration-File from it´s Configuration-Data by putting the above
# hashtable into a psd-file. You can just copy the outer Hashtable (without the $configdata =) into a 
# textfile with the ending psd1. You then call the configuration by referencing the psd1-file
installserver -ConfigurationData D:\Holger\Dokumente\_Firma\Powershell-Konferenz\2016\Chef\configdata.psd1