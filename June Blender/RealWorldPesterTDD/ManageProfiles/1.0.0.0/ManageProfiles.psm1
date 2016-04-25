<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015
	 Created on:   	9/22/2015 7:05 PM
	 Created by:   	June Blender
	 Organization: 	SAPIEN Technologies, Inc
	 Filename:     	ManageProfiles.psm1
	 Version:       1.0.0.0
	===========================================================================
#>

$ProfileWarning = 'Profile changes are not effective until you restart Windows PowerShell'

<#
.SYNOPSIS
Is the current session elevated?

.DESCRIPTION
This helper function returns a Boolean value that indicates whether the current session is elevated,
that is, whether it is running with the permissions of a member of the Administrators
group on the computer.

In the ManageProfiles module, the CanRename function calls this function when you submit a file to 
it that is in the System32 directory.

.OUTPUTS
System.Boolean

.NOTES
ManageProfiles does not export this function.
#>
function isAdmin
{
	[OutputType([System.Boolean])]
	Param ()
	
	$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
	$admin = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	$principal.IsInRole($admin)
}

<#
.SYNOPSIS
Does the current user have permission to rename the specified profile file?

.DESCRIPTION
This helper function returns a Boolean value that indicates whether the current user has permission
to rename the specified profile file. 

This function returns False when the file is in the System32 directory and
the current session is not elevated. Otherwise, it returns True.

In the ManageProfiles module, the Enable-Profile and Disable-Profile functions
call this function before trying to add or remove '.disabled' from the profile
file name.

.PARAMETER File
Specifies the file that you want to rename. Enter a FileInfo object, such
as one returned by Get-Item and Get-ChildItem.

.OUTPUTS
System.Boolean

.NOTES
ManageProfiles does not export this function.
#>
function CanRename
{
	[OutputType([System.Boolean])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[System.IO.FileInfo]
		$File
	)
	
	if ($file.Directory.FullName -like "*System32*" -and (!(isAdmin)))
	{
		return $False
	}
	else
	{
		return $True
	}
}

<#
.SYNOPSIS
Gets the paths where Windows PowerShell stores profile files.

.DESCRIPTION
This helper function returns the Windows PowerShell profile
paths on the computer, complete with wildcard characters.

The Get-Profile cmdlet function calls this function to get the 
paths to the profile files. The Pester tests for this module 
mock this function, returning paths on the TestDrive instead of
the local paths.
	
.EXAMPLE
PS C:\> Get-ProfilePath

"$PSHOME\*profile.ps1", "$HOME\Documents\WindowsPowerShell\*profile.ps1"

.OUTPUTS 
System.String[]
	
.NOTES
This function is designed for testing. ManageProfiles does not export this function.
#>
function Get-ProfilePath
{
	[OutputType([System.String[]])]
	Param ()
	
	return "$PSHOME\*profile.ps1", "$HOME\Documents\WindowsPowerShell\*profile.ps1"
}

# .EXTERNALHELP ManageProfiles.psm1-Help.xml
function Get-Profile {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param
	(
		[switch]
		$Disabled
	)
	
	if ($Paths = Get-ProfilePath) {
		if ($Disabled) {
			$Paths = $Paths | ForEach-Object { $_ + ".disabled" }
			Get-Item $Paths -ErrorAction SilentlyContinue
		}
		else {
			Get-Item -Path $Paths -ErrorAction SilentlyContinue
		}
	}
}
New-Alias -Name gpro -Value Get-Profile

#	.EXTERNALHELP ManageProfiles.psm1-Help.xml
function Disable-Profile {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param ()
	
	$renamed = $false
	
	if ($profiles = Get-Profile) {
		foreach ($pro in $profiles) {
			if (CanRename -file $pro) {
				Rename-Item -Path $pro.fullname -NewName ($pro.fullName + '.disabled') -PassThru
				$renamed = $True
			}
			else {
				Write-Error "Cannot disable AllUsers profile: $pro. `nTry again in an elevated session."
			}
		}
	}
	
	if ($renamed) {
		Write-Warning $ProfileWarning
	}
}

#	.EXTERNALHELP ManageProfiles.psm1-Help.xml
function Enable-Profile {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param ()
	
	$renamed = $false
	
	if ($profiles = Get-Profile -Disabled) {
		foreach ($pro in $profiles) {
			if (CanRename -file $pro) {
				Rename-Item -Path $pro.fullname -NewName ($pro.Name -replace '.disabled') -PassThru
				$renamed = $true
			}
			else {
				Write-Error "Cannot enable profile in unelevated session: $pro.fullname"
			}
		}
	}
	
	if ($renamed) {
		Write-Warning $ProfileWarning
	}
}