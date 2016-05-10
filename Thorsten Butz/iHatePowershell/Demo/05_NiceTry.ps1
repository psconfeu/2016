$number05 = {
  'Nice try ...' # Trouble with ADWS
}


<# DELETE Groups
 
        Get-ADGroup -filter { name -like "Research DL Group*"} | Remove-ADGroup -Confirm:0 
#>


## Tokenbloat demo

# $ErrorActionPreference = 'SilentlyContinue'
# Example OU
New-ADOrganizationalUnit -Name 'Research' -ProtectedFromAccidentalDeletion:$false 
$ou = Get-ADOrganizationalUnit -Filter { name -eq 'Research' } | Select-Object -First 1

# Create Example User
New-ADUser -Name 'Toni Bloat' -SamAccountName 'BloatT' -AccountPassword (ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force) -Enabled:$true -Path $ou
 
# Create 1st Group
New-ADGroup -Name 'Research DL Group 1' -GroupScope DomainLocal -Path $ou -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity 'Research DL Group 1' -Members 'BloatT' -ErrorAction SilentlyContinue

# Create more Groups
2..10| ForEach-Object { 
 New-ADGroup -Name "Research DL Group $_" -GroupScope DomainLocal -Path $ou 
 Add-ADGroupMember -Identity "Research DL Group $_"  -Members "Research DL Group $($_-1)"
}

# Investigation
Get-ADPrincipalGroupMembership BloatT | Format-Table -Property Name -AutoSize
Get-ADAccountAuthorizationGroup 'BloatT' | Format-Table -Property Name -AutoSize
dsquery.exe user -samid 'BloatT' -limit 10000 | dsget.exe user -memberof -expand 


# Alternative LDAP-Filter
$user = Get-ADUser BloatT
$search = [adsisearcher]"(member:1.2.840.113556.1.4.1941:=$user)"
$search.FindAll().path
$search.FindAll().properties.cn

# Alternative

Get-ADObject -LDAPFilter "(member:1.2.840.113556.1.4.1941:=CN=Toni Bloat,OU=Research,DC=contoso,dc=com)"
dsquery.exe *  -limit 10000 -filter "(member:1.2.840.113556.1.4.1941:=CN=Toni Bloat,OU=Research,DC=contoso,dc=com)"

#$ErrorActionPreference = 'Continue'