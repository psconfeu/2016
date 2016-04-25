<#
	Module manifest for module 'ManageProfiles'

	NOTE: This file should be saved with the same name as your module and a psd1
	file extension.

	For more information, see:
		Get-Help New-ModuleManifest
#>

# In ManageProfiles.psd1

@{

# Populate for script module
ModuleToProcess = ''
	
# Populate for manifest module
NestedModules = 'ManageProfiles.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '82bc1516-6efa-45de-91a8-75a2a5c3c505'
	
# Author of this module
Author = 'June Blender'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = '(c) 2015. All rights reserved.'

# Description of the functionality provided by this module
Description = ''

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = ''

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing
# this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()


# Functions to export from this module
FunctionsToExport = 'Get-Profile', 'Disable-Profile', 'Enable-Profile'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @()

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}