####################################################################################################
## https://msdn.microsoft.com/en-us/library/aa394606(v=vs.85).aspx
##
##  ASSOCIATORS & REFERENCES
##
####################################################################################################
# Basic search
Clear-Host

##
## some WMI classes are linked
## for example
## can also use
##   Get-WmiObject -List Win32_NetworkAdapter*
Get-CimClass Win32_NetworkAdapter*

####################################################################################################
##  REFERENCES
##
## Win32_NetworkAdapterSetting is
##   the Reference 
##  A reference links 2 classes that
##   are associated


## get the physical adapter
##  DeviceId is class Key
Get-CimInstance Win32_NetworkAdapter |  
Select-Object Name, DeviceId, NetEnabled

##
##  check the deviceId
$query = @"
REFERENCES OF
{Win32_NetworkAdapter.DeviceId='11'}
"@

Get-CimInstance -Query $query | Format-List

##
## could view directly
Get-CimInstance -ClassName Win32_NetworkAdapterSetting

Get-CimInstance -ClassName Win32_NetworkAdapterSetting | 
Where-Object {$_.Element.DeviceID -eq '11'} | Format-List *

##
## property names on references not consistent
##   SameElement    SystemElement
##   GroupComponent PartComponent
##   Element        Setting
##   Antecedent     Dependent
## can all be seen

## if only want classes 
$query = @"
REFERENCES OF
{Win32_NetworkAdapter.DeviceId='11'} 
WHERE ClassDefsOnly
"@

## this doesn't work
Get-CimInstance -Query $query | Select-Object Name, Properties
Get-CimInstance -Query $query | Select-Object *

## this works
Get-WmiObject -Query $query | Select-Object Name, Properties
Get-WmiObject -Query $query | Select-Object Name, Properties


####################################################################################################
## ASSOCIATORS
##
##  REFERENCES show you the links
##  ASSOCIATORS retreive the linked object or objects

$query = @"
ASSOCIATORS OF
{Win32_NetworkAdapter.DeviceId='11'}
"@

Get-CimInstance -Query $query

## A lot of data
##  let's start witht the classes available

$query = @"
ASSOCIATORS OF
{Win32_NetworkAdapter.DeviceId='11'} 
WHERE ClassDefsOnly
"@

## this doesn't work
Get-CimInstance -Query $query

## this works
Get-WmiObject -Query $query

##
## look at specific classes

$query = @"
ASSOCIATORS OF
{Win32_NetworkAdapter.DeviceId='11'} 
WHERE RESULTCLASS = Win32_NetworkAdapterConfiguration
"@

Get-CimInstance -Query $query

$query = @"
ASSOCIATORS OF
{Win32_NetworkAdapter.DeviceId='11'} 
WHERE RESULTCLASS = Win32_NetworkProtocol
"@

Get-CimInstance -Query $query

##
## Alternative approach with CIM cmdlets
##

$nic = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "DeviceId='11'"
$nic
Get-CimAssociatedInstance -InputObject $nic

##
## no easy way to see just associated classes
Get-CimAssociatedInstance -InputObject $nic | 
Select-Object -ExpandProperty CimSystemProperties | 
Sort-Object ClassName -Unique

##
## direct to associated class
Get-CimAssociatedInstance -InputObject $nic -ResultClassName Win32_NetworkAdapterConfiguration

## 
## discovering reference class
Get-CimClass -ClassName *Network* -QualifierName 'Association'

## going via Reference class
##
Get-CimAssociatedInstance -InputObject $nic -Association Win32_NetworkAdapterSetting | fl