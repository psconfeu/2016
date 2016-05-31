# Check the current config. the current of NANO server
Invoke-Command -Session $pssession -ScriptBlock { 
    Get-Module -ListAvailable -Name *desired*
    Import-Module PSDesiredStateConfiguration
    Get-Command -Module PSDesiredStateConfiguration -
    Get-DscResource
    Get-DscLocalConfigurationManager
}

# Remote via CIMSESSION
Get-DscLocalConfigurationManager -CimSession $cimsession

# Define DSC configuration
Configuration UnderConstruction {
    Import-DscResource -ModuleName PSDesiredStateConfiguration      
    Node '192.168.0.142' {
        File InetpubFolder {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot'
            Ensure = "Present"
        }

        File Start {
            DestinationPath = 'C:\inetpub\wwwroot\start.html'
            Ensure = "Present"
            Contents = '<h1>Under Construction!'
            DependsOn = '[File]InetpubFolder'
        }
    }
}

# Create the mof file 
UnderConstruction

# Apply the configuration
Start-DscConfiguration -Path .\UnderConstruction -CimSession $cimsession -Wait -Verbose

# Check the configuration
Get-DscConfiguration -CimSession $cimsession

Invoke-Command -Session $pssession -ScriptBlock {
    Get-ChildItem 'C:\inetpub\wwwroot'
    Get-Content 'C:\inetpub\wwwroot\start.html'
}

<#  
    You can utilize PowerShell Gallery to install non built-in DSC Resource:
    Find-Module -Name x*
    Install-Module -Name ' xSmbShare' 
#>