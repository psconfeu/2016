<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "VMs bereitstellen mit DSC und Chef"
    Part 3: Setting the DSC-Client (Local Configuration Manager)
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# The Computer which shall use DSC can be configured as a pull-client. Therefore you have
# to change the DSC-Client-Configuration. The DSC-Client is named LCM - Local Configuration Manager. 
# It is also configured through DSC. The DSC-Configuration is a special one. You have to set the attribute
# [DscLocalConfigurationManager()] above the Configuration-keyword. DSC will create a file with the ending
# computername.meta.mof instead of a simple mof-file. 
# In this special case our client will install a web-server with a DSC-compliance (report)-Server, which is
# part of the DSC-Pull-Server
# https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig

[DscLocalConfigurationManager()]
Configuration LCM {

    node localhost {
        Settings 
        { 
            RefreshFrequencyMins = 30
            ConfigurationMode = 'ApplyAndMonitor'
            AllowModuleOverwrite  = $true
            RebootNodeIfNeeded = $false
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationModeFrequencyMins = 15;
        }

    }
}

mkdir c:\lcmconfig
lcm -OutputPath c:\lcmconfig
Set-DscLocalConfigurationManager -Path c:\lcmconfig -Force -Verbose
