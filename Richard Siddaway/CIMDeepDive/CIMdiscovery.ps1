####################################################################################################
##
##  WMI Discovery
##
####################################################################################################
##
## WMI settings
Get-WmiObject Win32_WMISetting | 
Select-Object ASPScriptDefaultNamespace, 
BuildVersion, DatabaseDirectory, 
EnableEvents, EnableStartupHeapPreallocation,
HighThresholdOnClientObjects,
InstallationDirectory, 
LoggingDirectory, LoggingLevel,
LowThresholdOnEvents, MaxLogFileSize,
MaxWaitOnEvents

Get-WmiObject Win32_WMISetting | 
Select-Object -ExpandProperty AutorecoverMofs

## 
## Providers
Get-CimInstance -ClassName __Win32Provider | 
Sort-Object Name | Select-Object Name, HostingModel

##
## Impersonation level = COM impersonation level
##  0 = default (no impersonation); 1 = uses impersonation
##  if 1 PerUserInitialization should be true
##  
## pure = $false => transition to client role after complete servicing requests
##  all actions by non-pure providers must complete before WMI can shutdown safely
Get-CimInstance -ClassName __Win32Provider | Sort-Object ImpersonationLevel |
Format-Table Name, ImpersonationLevel, PerUserInitialization, Pure -AutoSize

## register provider
##  multiple registration types available
Get-CimClass -ClassName *ProviderRegistration*

## each provider can have multiple registrations
Get-CimInstance __ProviderRegistration | 
Sort-Object provider | 
Format-Table provider, CimClass -AutoSize

## namespaces are hierarchical
Get-CimInstance -Namespace root -ClassName __NAMESPACE
Get-CimInstance -Namespace root\StandardCimv2 -ClassName __NAMESPACE

## root\cimv2 is default namespace
##  NOT root\DEFAULT

## namespaces have classes
##  standard classes
Get-CimClass | Select-Object CimClassName 

## classes for new CDXML modules
Get-CimClass -Namespace root\StandardCimv2 | Select-Object CimClassName 

## search for classes
##  note CIM_ & Win32_
Get-CimClass *Network*

## search recursively
Get-WmiObject -List -Namespace root -Class *Network* -Recurse

## class information
Get-CimClass -ClassName Win32_NetworkAdapter

$class = Get-CimClass -ClassName Win32_NetworkAdapter
$class | Format-List *

## class qualifiers
$class.CimClassQualifiers

$class.CimSystemProperties
# compare with
Get-WmiObject -Class Win32_NetworkAdapter | 
Select-Object -First 1 | Select-Object __*

$class.CimClassMethods
$class.CimClassMethods['SetPowerState'].Parameters

## many properties read only
$class.CimClassProperties

## some classes have a description
## can't access Amended daat through CIM cmdlets
Get-WmiObject -List 'Win32_NetworkAdapter*' | 
foreach {
    (( Get-WmiObject -List $_.Name  -Amended ).Qualifiers | 
    Where-Object {$_.Name -eq 'Description'}).Value
}

## class key
##  needed for certain actions - including creation
foreach ($property in (Get-CimClass -ClassName Win32_NetworkAdapter).CimClassProperties) {
    $property | Select-Object -ExpandProperty Qualifiers | 
        foreach {
            if ($_.Name -eq 'key'){
                $property
            }
        }
}
