
# PowershellGet
Get-Module -ListAvailable PowerShellGet    #  Requires NuGet
Get-Command -Module PowerShellGet

Get-PSRepository                           # 1 Repo: PSGallery
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Listing PSGallery modules 
Find-Module       
(Find-Module).count

# Find and install specific modules
Find-Module ISESteroids

Find-Module *ssh* | Select-Object -Property Name, Author
Install-Module -Name 'PoSh-SSH' -Force
Get-Command -Module 'PoSh-SSH'

Find-Module -Name PowerShellCookbook | Install-Module 
Get-Module -ListAvailable PowerShellCookbook | Select-Object -Property path
Get-Command -Module PowerShellCookbook

Update-Module -Name PowerShellCookbook
Remove-Module -Name PowerShellCookbook
Uninstall-Module -Name PowerShellCookbook -AllVersions

# Runspaces module
Find-Module -Name *rsjob | Select-Object -Property Name, Author
Install-Module -Name PoShRSJob -Force

# PackageManagement (aka OneGet)
Get-Module -ListAvailable PackageManagement           #  NuGet (also) required
Get-Module -ListAvailable PackageManagement | Select-Object -ExpandProperty ExportedCommands

Get-PackageSource
Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/ -Force
# Get-PackageSource chocolatey | Unregister-PackageSource

Find-Package sysinternals | Install-Package -Force 
Install-Package Opera -Force 

# Uninstall-Package Sysinternals -AllVersions
# Uninstall-Package Opera -AllVersions