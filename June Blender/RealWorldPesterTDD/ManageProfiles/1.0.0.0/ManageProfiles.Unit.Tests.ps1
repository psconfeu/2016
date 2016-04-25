<#	
.NOTES
===========================================================================
 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.116
 Created on:   	3/7/2016 12:57 PM
 Author:    	June Blender
 Organization: 	SAPIEN Technologies, Inc
 Filename:     	ManageProfiles.Unit.Tests.ps1
===========================================================================
.DESCRIPTION
A Pester unit test file for the ManageProfiles module. This file uses
the TestDrive: PSDrive and mocks to run each function independent of the
local file system and independent of other functions in the module.
#>


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
	
	# This 'arrange' function creates profile-like files on TestDrive: ($TestDrive),
	# a temporary PSDrive that acts as an independent file system for the test.
	# TestDrive: is created anew for each Describe block. Any files that are
	# created in a Context block are deleted when the Context block ends.
	function New-MockedProfiles {
		[OutputType([System.IO.FileInfo])]
		param
		(
			[Parameter(Mandatory = $true)]
			[ValidateSet('All', 'AllUsers', 'CurrentUser', 'Console', 'ISE')]
			[string]
			$ProfileType,
			
			[switch]
			$Disabled
		)
		
		$profilePaths = @{
			
			AllAll = 'PSHome\System32\profile.ps1'
			AllConsole = 'PSHome\System32\Microsoft.PowerShell_profile.ps1'
			UserAll = 'Home\Documents\WindowsPowerShell\profile.ps1'
			UserConsole = 'Home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
			UserISE = 'Home\Documents\WindowsPowerShell\Microsoft.PowershellISE_profile.ps1'
		}
		
		switch ($ProfileType) {
			All {
				$selectedProfiles = $profilePaths.Values
				break
			}
			AllUsers {
				$selectedProfiles = $profilePaths[$profilePaths.Keys -like "All*"]
				break
			}
			CurrentUser {
				$selectedProfiles = $profilePaths[$profilePaths.Keys -like "User*"]
				break
			}
			Console {
				$selectedProfiles = $profilePaths[$profilePaths.Keys -like "*Console"]
				break
			}
			ISE {
				$selectedProfiles = $profilePaths[$profilePaths.Keys -like "*ISE"]
				break
			}
		}
		
		try {
			foreach ($selectedProfile in $selectedProfiles) {
				if ($Disabled) {
					$selectedProfile = $selectedProfile + ".disabled"
				}
				
				$testdrivePath = Join-Path $TestDrive -ChildPath $selectedProfile
				New-Item -ItemType File -Path $testdrivePath -Force -ErrorAction Stop
			}
		}
		catch {
			
			throw 'Cannot create mocked profiles on TestDrive. Error is $($Errors.Exception.Message).'
		}
	}
	
	# This Describe block contains all unit tests for the Get-Profile function.
	Describe "Get-Profile - UnitTest" -Tag UnitTest {
		
		# I used this Context container to contain the mocks I defined so they
		# don't affect other tests.
		Context "Example 1: Mock with all profiles" {
			
			# Calling my 'arrange' function.
			$mockedProfiles = New-MockedProfiles -ProfileType All | ForEach-Object FullName
			
			# This mock mocks a helper function that passes profile paths
			# to Get-Profile. The $mockedProfiles variable contains paths
			# on the TestDrive: instead of the real paths in $home and $pshome.
			Mock -CommandName Get-ProfilePath -MockWith { $mockedProfiles }
			
			# Gets all profiles on the TestDrive:
			It "Example 1: Gets all profiles" {
				$sortedFullNames = Get-Profile | ForEach-Object FullName | Sort-Object
				$sortedFullNames[0] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
				$sortedFullNames[1] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowershellISE_profile.ps1"
				$sortedFullNames[2] | Should BeLike "*Home\Documents\WindowsPowerShell\profile.ps1"
				$sortedFullNames[3] | Should BeLike "*PSHome\System32\Microsoft.PowerShell_profile.ps1"
				$sortedFullNames[4] | Should BeLike "*PSHome\System32\profile.ps1"
			}
			
			# Doesn't get the fake profiles with similar names.
			It "Example 1: Gets only profiles" {
				$FakePathFileName = Join-Path $TestDrive -ChildPath "Home\Profile.Extrafile.ps1"
				$FakePathDirectory = Join-Path $TestDrive -ChildPath "PSHome\System32\Profile\Extrafile.ps1"
				New-Item -ItemType File -Path $FakePathFileName -Force -ErrorAction Stop
				New-Item -ItemType File -Path $FakePathDirectory -Force -ErrorAction Stop
				
				# Gets only the 5 profiles with correct name patterns.
				(Get-Profile).count | Should Be 5
			}
		}
		
		# Contains the mock for example 2.
		Context "Example 2: Mocks with all disabled profiles" {
			
			# Replace .disabled because Get-Profile -Disable adds it. You don't want it added twice (.disabled.disabled).
			$mockedProfiles = (New-MockedProfiles -ProfileType All -Disabled | ForEach-Object FullName) -replace ".disabled"
			Mock -CommandName Get-ProfilePath -MockWith { $mockedProfiles }
			
			# This is white-box testing because it tests a particular implementation that disables the files.
			It "Example 2: Gets disabled profiles" {
				$sortedFullNames = Get-Profile -Disabled | ForEach-Object FullName | Sort-Object
				$sortedFullNames[0] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1.disabled"
				$sortedFullNames[1] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowershellISE_profile.ps1.disabled"
				$sortedFullNames[2] | Should BeLike "*Home\Documents\WindowsPowerShell\profile.ps1.disabled"
				$sortedFullNames[3] | Should BeLike "*PSHome\System32\Microsoft.PowerShell_profile.ps1.disabled"
				$sortedFullNames[4] | Should BeLike "*PSHome\System32\profile.ps1.disabled"
			}
		}
		
		# This context block contains mocks for example 3. 
		# I had to decide how to handle the condition when a user runs a ManageProfile
		# cmdlet on a system with no PowerShell profile files. I decided to return no
		# errors and no output. These tests verify that functionality.
		Context "Example 3: Mocks with no profiles" {
			
			$EmptyPath = Join-Path $TestDrive -ChildPath "*profile.ps1"
			Mock -CommandName Get-ProfilePath -MockWith { $EmptyPath }
			
			It "Example 3: No output when no enabled profiles" {
				Get-Profile -ErrorAction Stop | Should BeNullOrEmpty
			}
			
			It "Example 3: No output when no disabled profiles" {
				Get-Profile -Disabled -ErrorAction Stop | Should BeNullOrEmpty
			}
			
			# If Get-Profile generated a non-terminating error, '-ErrorAction Stop' would
			# convert it to a terminating error and the test would catch it.
			#
			# Input to "Should Throw" and "Should Not Throw" must be enclosed in script blocks.
			It "Example 3: No error with no profiles" {
				{ Get-Profile -ErrorAction Stop } | Should Not Throw
			}
		}
		
		
		# This test tests Example 4, which just combines results from 2 consecutive runs of
		# Get-Profile. The example was included to show users how to combine objects in an
		# array. It's not specific to this module.
		Context "Example 4: Mocks with some enabled and some disabled profiles" {
			
			$mockedProfiles = @()
			$mockedProfiles = (New-MockedProfiles -ProfileType CurrentUser -Disabled | ForEach-Object FullName) -replace ".disabled"
			$mockedProfiles += New-MockedProfiles -ProfileType AllUsers | ForEach-Object FullName
			Mock -CommandName Get-ProfilePath -MockWith { $mockedProfiles }
			
			It "Example 4: Gets enabled profiles" {
				Get-Profile | Should BeLike "*PSHome*profile.ps1"
			}
			
			It "Example 4: Gets disabled profiles" {
				Get-Profile -Disabled | Should BeLike "*profile.ps1.disabled"
			}
			
			It "Example 4: Combines the enabled and disabled files" {
				#[IO.FileInfo[]]$result = Get-Profile
				$result = @()
				$result = Get-Profile
				$result += Get-Profile -Disabled
				$result
				
				($result | Where-Object { $_ -Like "*profile.ps1" }).count | Should Be 2
				($result | Where-Object { $_ -Like "*profile.ps1.disabled" }).count | Should Be 3
			}
		}
	}
	
	# This Describe block contains all unit tests for the Disable-Profile function.
	Describe "Disable-Profile - UnitTest" -Tag UnitTest {
		
		# This Context block contains the mocking for the CurrentUser profiles.
		Context "Example 1: Mock Get-Profile and user profiles" {
			
			# Mock only with CurrentUser profiles (Not System32)
			# In this test, we mock Get-Profile, because Disable-Profiles calls Get-Profile.
			# This mocking isolates the test of Disable-Profile from any errors in Get-Profile.
			$mockedProfiles += New-MockedProfiles -ProfileType CurrentUser
			Mock Get-Profile -MockWith { $mockedProfiles }
			
			It "Example 1: Disables user profiles" {
				$sortedFullNames = Disable-Profile | ForEach-Object FullName | Sort-Object
				$sortedFullNames[0] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1.disabled"
				$sortedFullNames[1] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowershellISE_profile.ps1.disabled"
				$sortedFullNames[2] | Should BeLike "*Home\Documents\WindowsPowerShell\profile.ps1.disabled"
			}
		}  # TestDrive files created in Context block are deleted when the Context block ends.
		
		# This Context creates all profile files in the TestDrive:
		# and mocks the IsAdmin function with $False.
		Context "Example 2: Mock all profiles - NotAdmin" {
			
			# In addition to mocking Get-Profile for isolation, we mock a helper function,
			# IsAdmin, which determines whether the session is running with
			# the permissions of an administrator. We mock IsAdmin with $False.
			#
			# Profiles are sorted so Disable-Profile disables the CurrentUser profile 
			# before it errors out any System32 profiles.
				
			
			$mockedProfiles = New-MockedProfiles -ProfileType All | Sort-Object FullName
			Mock Get-Profile -MockWith { $mockedProfiles }
			Mock IsAdmin -MockWith { $false }
			
			# Input to "Should Throw" and "Should Not Throw" must be enclosed in script blocks.
			It "Example 2: Will error out System32 if not admin" {
				{ Disable-Profile -ErrorAction Stop } | Should Throw
			}
			
			# Before erroring out the System32 profile, it should have disabled the
			# CurrentUser profiles.
			It "Example 2: Disables CurrentUser profiles" {
				$HomeDisabledProfiles = Join-Path $TestDrive -ChildPath "Home\Documents\WindowsPowerShell\*disabled"
				(Get-ChildItem $HomeDisabledProfiles).count | Should Be 3
			}
			
			# Before erroring out the System32 profile, it should NOT have disabled any
			# System32 profiles.
			It "Example 2: Does not disable System32 profiles" {
				$PSHomeDisabledProfiles = Join-Path $TestDrive -ChildPath "PSHome\System32\*disabled"
				Get-ChildItem $PSHomeDisabledProfiles -ErrorAction SilentlyContinue | Should BeNullOrEmpty
			}
		}
		
		
		# This Context creates all profile files in the TestDrive:
		# and mocks the IsAdmin function with $True.
		Context "Example 2: Mock all profiles - Admin" {
			
			# In addition to mocking Get-Profile for isolation, we mock a helper function,
			# IsAdmin, which determines whether the session is running with
			# the permissions of an administrator. We mock IsAdmin with True.			
			$mockedProfiles = New-MockedProfiles -ProfileType All
			Mock Get-Profile -MockWith { $mockedProfiles }
			Mock IsAdmin -MockWith { $true }
			
			# With admin permissions, Disable-Profile shouldn't generate any errors.
			It "Example 2: Will not error out if Admin" {
				{ Disable-Profile -ErrorAction Stop } | Should Not Throw
			}
			
			# And, when run, it should have disabled all profiles
			It "Example 2: Will disable all profiles" {
				(Get-ChildItem -Path $TestDrive\*disabled -Recurse).count | Should Be 5
			}
		}
		
		
		# This context block contains mocks for example 3. When it finds no profiles, 
		# Disable-Profile should not throw any errors or generate any output.
		Context "Example 3: Works with no profiles" {
			Mock -CommandName Get-Profile -MockWith { $null }
			
			It "returns no files" {
				Disable-Profile | Should BeNullOrEmpty
			}
			
			# Again, we detect a non-terminating error by using 'ErrorAction -Stop'
			# which throws a terminating error for any error and 'Should Not Throw.'
			#
			# Unlike a non-terminating error, which goes to the error stream, the
			# "Should Not Throw' test output goes to the output stream (stdout) and
			# is captured in the custom object that represents the test results.
			It "does not write an error" {
				{ Disable-Profile -ErrorAction Stop } | Should Not Throw
			}
		}
	}
	
	# This Describe block contains all unit tests for the Enable-Profile function.
	Describe "Enable-Profile - UnitTest" -Tag UnitTest {
		
		# This Context block contains the mocking for the CurrentUser profiles.
		Context "Example 1: Mock disabled current user profiles" {
			
			# Mock only with CurrentUser profiles (Not System32)
			# In this test, we mock Get-Profile, because Enable-Profiles calls Get-Profile.
			# This mocking isolates the test of Enable-Profile from any errors in Get-Profile.
			$mockedProfiles = New-MockedProfiles -ProfileType CurrentUser -Disabled
			Mock Get-Profile -Disabled -MockWith { $mockedProfiles }
			
			It "Example 1: Enables disabled CurrentUser profiles" {
				$sortedFullNames = Enable-Profile | ForEach-Object FullName | Sort-Object
				$sortedFullNames[0] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
				$sortedFullNames[1] | Should BeLike "*Home\Documents\WindowsPowerShell\Microsoft.PowershellISE_profile.ps1"
				$sortedFullNames[2] | Should BeLike "*Home\Documents\WindowsPowerShell\profile.ps1"
			}
		}
		
		# This Context mocks the Get-Profile cmdlet to isolate Disable-Profile.
		# and to test it with all profiles in a non-admin session. 
		Context "Example 2: Mock all profiles - NotAdmin" {
			
			# In addition, it mocks IsAdmin, a helper function that determines whether
			# the session is running with the permissions of an administrator. 
			# We mock IsAdmin with $False
			#
			# Start this test with all disabled profiles			
			$mockedProfiles = New-MockedProfiles -ProfileType All -Disabled | Sort-Object FullName
			Mock Get-Profile -MockWith { $mockedProfiles }
			Mock IsAdmin -MockWith { $false }
			
			# Enable-Profile should generate a non-terminating error. We use 'ErrorAction -Stop'
			# to make it a terminating error that we can catch with 'Should Throw.'
			#
			# Input to "Should Throw" and "Should Not Throw" must be enclosed in script blocks.
			It "Example 2: Will error out System if not admin" {
				{ Enable-Profile -ErrorAction Stop } | Should Throw
			}
			
			# Before erroring out the System32 profile, it should have enabled the
			# CurrentUser profiles.
			It "Example 2: Enables CurrentUser profiles" {
				$HomeProfilePath = Join-Path $TestDrive -ChildPath "Home\Documents\WindowsPowerShell\*profile.ps1"
				(Get-ChildItem $HomeProfilePath).count | Should Be 3
			}
			
			# Before erroring out the System32 profile, it should NOT have enabled any
			# System32 profiles.
			It "Example 2: Does not enable System32 profiles" {
				$PSHomeProfilePath = Join-Path $TestDrive -ChildPath "PSHome\System32\*profile.ps1"
				Get-ChildItem $PSHomeProfilePath -ErrorAction SilentlyContinue | Should BeNullOrEmpty
			}			
		}
		
		# This Context mocks the Get-Profile cmdlet to isolate Enable-Profile.
		# and to test it with System32 profiles in a non-admin session. 
		Context "Example 2: Mock all profiles - Admin" {
			
			# In addition, it mocks IsAdmin, a helper function that determines whether
			# the session is running with the permissions of an administrator. 
			# We mock IsAdmin with $True
			#
			# We start this test with all disabled profiles
			$mockedProfiles = New-MockedProfiles -ProfileType All -Disabled
			Mock Get-Profile -MockWith { $mockedProfiles }
			Mock IsAdmin -MockWith { $true }
			
			# When run in an admin session, Enable-Profile should not generate any errors.
			# To test, we run with '-ErrorAction Stop' and catch it with 'Should Throw'.
			#
			# Input to "Should Throw" and "Should Not Throw" must be enclosed in script blocks.
			It "Example 2: Will not error out if Admin" {
				{ Enable-Profile -ErrorAction Stop } | Should Not Throw
			}
			
			# And, when we ran it, it should have enabled all profiles
			It "Example 2: Will enable AllUsers if Admin" {
				Get-ChildItem -Path $TestDrive\*profile* -Recurse | Should BeLike "*profile.ps1"
			}
		}
		
		# This context block contains mocks for example 3. When it finds no profiles, 
		# Enable-Profile should not throw any errors or generate any output.
		Context "Example 3: Works with no profiles" {
			
			Mock -CommandName Get-Profile -MockWith { $null }
			
			It "returns no files" {
				Enable-Profile | Should BeNullOrEmpty
			}
			
			# Again, we detect a non-terminating error by using 'ErrorAction -Stop'
			# which throws a terminating error for any error and 'Should Not Throw.'
			#
			# Unlike a non-terminating error, which goes to the error stream, the
			# "Should Not Throw' test output goes to the output stream (stdout) and
			# is captured in the custom object that represents the test results.
			It "does not write an error" { { Enable-Profile -ErrorAction Stop } | Should Not Throw
			}
		}
	}
	
	# This Describe block tests the warning message that appears when profiles
	# are enabled and disabled. This isn't in an example, but I added it to
	# improve test coverage.
	Describe "Test warning" {
		Context "Disable-Profile: Writes restart warning" {
			
			# Testing with the ISE profile. This is arbitrary.
			$mockedProfiles += New-MockedProfiles -ProfileType ISE
			Mock -CommandName Get-Profile -MockWith { $mockedProfiles }
			
			# To test the warning, I redirect the warning to the output stream (stdout) and
			# then search for the warning string in the output stream.
			It "warns that changes aren't yet effective" {
				# Disable-Profile  3>&1 | Should BeLike "*changes are not effective until*"
				Disable-Profile  3>&1 | Select-String "changes are not effective until" | Should Not BeNullOrEmpty
			}
		}
		
		Context "Enable-Profile: Writes restart warning" {
			
			# Testing with the disabled console profiles. This is arbitrary.
			# To handle System32 profile, mock IsAdmin with $true.
			$mockedProfiles += New-MockedProfiles -ProfileType Console -Disabled
			Mock -CommandName IsAdmin -MockWith {$True}
			Mock -CommandName Get-Profile -MockWith { $mockedProfiles }
			
			It "warns that changes aren't yet effective" {
				# Enable-Profile  3>&1 | Should BeLike "*changes are not effective until*"
				Enable-Profile  3>&1 | Select-String "changes are not effective until" | Should Not BeNullOrEmpty
			}
		}
	}
}