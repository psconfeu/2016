<#	
.NOTES
===========================================================================
 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.116
 Created on:   	3/7/2016 12:57 PM
 Author:    	June Blender
 Organization: 	SAPIEN Technologies, Inc
 Filename:     	ManageProfiles.Integration.Tests.ps1
===========================================================================
.DESCRIPTION
A Pester integration test file for the ManageProfiles module. This file uses
the local file system and runs the functions in the module together to verify
that they run correctly.

This script requires admin permissions. To run it, start Windows PowerShell
with the 'Run as administrator' option.
#>

#  Requires admin permissions to rename profile files in System32.
#Requires -RunAsAdministrator

# Pester cannot handle more than one version of the module in in the current session
# as permitted in PowerShell 5.0.
# This command removes all versions of the module from the sessions
# but does not return an error if there are no versions of the module 
# in the session.
Get-Module ManageProfiles | Remove-Module

# Import the only the module version you want to test.
# Use ErrorAction stop to prevent the tests from running.
Import-Module ManageProfiles -RequiredVersion 1.0.0.0 -ErrorAction Stop

# InModuleScope runs the test in module scope.
# It creates all variables and functions in module scope.
# As a result, test has access to all functions, variables and aliases
# in the module even if they're not exported.
InModuleScope "ManageProfiles" {
	
	# This 'arrange' function gets profiles in the file system.
	function Get-ExpectedProfiles {
		Get-Item -Path "$HOME\Documents\WindowsPowerShell\*profile.ps1", "$PSHOME\*profile.ps1"
	}
	
	# This 'arrange' function gets disabled profiles in the file system.
	function Get-ExpectedDisabledProfiles {
		Get-Item -Path "$HOME\Documents\WindowsPowerShell\*profile.ps1.disabled", "$PSHOME\*profile.ps1.disabled"
	}
	
	# This Describe block contains all integration tests for the Get-Profile function
	Describe "Get-Profile Integration test" -Tag "Integration" {
		
		# No mocking here. Context blocks are used for organization, not scope.
		Context "Example 1: Gets all profiles" {
			Enable-Profile -ErrorAction Stop
			$expected = Get-ExpectedProfiles
			
			It "Example 1: Gets all profiles - name" {
				Get-Profile | ForEach-Object { $_ | Should BeLike "*profile.ps1" }
			}
			
			It "Example 1: Gets all and only profiles - count" {
				(Get-Profile).count | Should Be $expected.count
			}
		}
		
		Context "Example 2: Gets disabled profiles" {
			Disable-Profile -ErrorAction Stop
			$expected = Get-ExpectedDisabledProfiles
			
			It "Example 2: Gets all disabled profiles - name" {
				Get-Profile -Disabled | ForEach-Object { $_ | Should BeLike "*profile.ps1.disabled" }
			}
			
			It "Example 2: Gets all and only disabled profiles - count" {
				(Get-Profile -Disabled).count | Should Be $expected.count
			}
		}
		
		Context "Example 3: Gets no profiles" {
			Mock Get-ProfilePath -MockWith { $null }
			
			It "Example 3: Gets no profiles - enabled" {
				Get-Profile -ErrorAction Stop | Should BeNullOrEmpty
			}
			
			It "Example 3: Gets no profiles - disabled" {
				Get-Profile -ErrorAction Stop | Should BeNullOrEmpty
			}
			
			It "Example 3: No input, no errors - enabled" {
				{ Get-Profile -ErrorAction Stop } | Should Not Throw
			}
			
			It "Example 3: No input, no errors - disabled" {
				{ Get-Profile -Disabled -ErrorAction Stop } | Should Not Throw
			}
		}
	}
	
	
	# This Describe block contains all unit tests for the Disable-Profile function.
	Describe "Disable-Profile - Integration test" -Tag "Integration" {
		
		Context "Example 1: Disables all profiles" {
			Enable-Profile -ErrorAction Stop
			$expected = Get-Profile -ErrorAction Stop
			
			It "Example 1: Disables all profiles - name" {
				Disable-Profile | ForEach-Object { $_ | Should BeLike "*profile.ps1.disabled" }
			}
			
			It "Example 1: Disables all profiles - count" {
				(Get-Profile -Disabled).count | Should Be $expected.count
			}
		}
		
		Context "Example 2: Disables only user profiles" {
			Enable-Profile -ErrorAction Stop
			Mock IsAdmin -MockWith {$False}
			
			It "Example 2: Disables CurrentUser profiles" {
				(Disable-Profile -ErrorAction SilentlyContinue).Fullname | ForEach-Object {
					$_ | Should BeLike "$Home*profile.ps1.disabled"
				}
			}
			
			It "Example 2: Cannot disable AllUser profiles" {
				Get-Profile | ForEach-Object { $_ | Should BeLike "$PSHome*profile.ps1" }
			}
		}
		
		
		Context "Example 3: Gets no profiles" {
			Mock Get-Profile -MockWith { $null }
			
			It "Example 3: Gets no profiles" {
				Disable-Profile  | Should BeNullOrEmpty
			}
			
			It "Example 3: No input, no errors - enabled" {
				{ Disable-Profile -ErrorAction Stop } | Should Not Throw
			}
		}
	}
	
	# This Describe block contains all unit tests for the Enable-Profile function.
	Describe "Enable-Profile - Integration Test" -Tag "Integration" {
		
		Context "Example 1: Enables all profiles" {
			Disable-Profile -ErrorAction Stop
			$expected = Get-Profile -Disabled -ErrorAction Stop
			
			It "Enables all profiles - name" {
				Enable-Profile | ForEach-Object { $_ | Should BeLike "*profile.ps1" }
			}
			
			It "Enables all profiles - count" {
				(Get-Profile).count | Should Be $expected.count
			}
		}
		
		Context "Example 2: Enables only user profiles" {
			Disable-Profile -ErrorAction Stop
			Mock IsAdmin -MockWith { $False }
			
			It "Example 2: Disables CurrentUser profiles" {
				(Enable-Profile -ErrorAction SilentlyContinue).Fullname | ForEach-Object {
					$_ |  Should BeLike "$Home*profile.ps1" }
			}
			
			It "Example 2: Cannot disable AllUser profiles" {
				Get-Profile -Disabled | ForEach-Object {
					$_ | Should BeLike "$PSHome*profile.ps1.disabled"
				}
			}
		}
		
		Context "Example 3: Gets no profiles" {
			Mock Get-Profile -MockWith { $null }
			
			It "Example 3: Gets no profiles" {
				Enable-Profile | Should BeNullOrEmpty
			}
			
			It "Example 3: No input, no errors - enabled" {
				{ Enable-Profile -ErrorAction Stop } | Should Not Throw
			}
		}
	}
	
	# This test just makes sure that the profiles are enabled when the tests end.
	Describe "Re-enable all profiles" -Tag Integration {
		It "re-enables all profiles" {
			$allProfiles = @()
			$allProfiles = Get-Profile
			$allProfiles = Get-Profile -Disabled
				
			(Enable-Profile).count | Should Be $allProfiles.count
		}		
	}
}