####################################################################################################
##
##  CIM sessions
##
##  about_CimSession
####################################################################################################
## run this on server02
##  need following to be running
##  Arista - allow to complete checks
##  W16TP4CIM01,  W12R2DSC, W12R2SUS, W8R2STD01

## remote DCOM based WMI call
Get-WmiObject -Class Win32_OperatingSystem -ComputerName W16TP4CIM01

## call over WSMAN
Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName W16TP4CIM01

## check WSMAN
Test-WSMan -ComputerName W16TP4CIM01
## with OS info
Test-WSMan -ComputerName W16TP4CIM01 -Authentication Default

## create CIM session
##  MUST be WSMAN 3.0 (or higher?) [Stack property]
Get-Command New-CimSession -Syntax
$cs1 = New-CimSession -ComputerName W16TP4CIM01
$cs1

Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs1

## compare times
##  Cim session quicker because don't have
## to set up and tear down the connection
Measure-Command -Expression {Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName W16TP4CIM01}
Measure-Command -Expression {Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs1}

## working with multiple computers
$cs2 =  New-CimSession -ComputerName W12R2DSC, W12R2SUS
Get-CimSession | Format-Table -AutoSize

Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs2

## working with multiple sessions
## not this
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs1, $cs2

## but this
##  need to create a collection of sessions
$allsess = Get-CimSession
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $allsess

## can run session to local machine
## so doesn't feel neglected
$cs3 = New-CimSession -ComputerName $env:COMPUTERNAME
$cs3

Get-CimInstance -ClassName Win32_OperatingSystem -CimSession (Get-CimSession)

## can pick subset of computers in session
##
$cs2
## but not like this
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs2 -ComputerName W12R2SUS

## use
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession (Get-CimSession -ComputerName W12R2SUS)
## OR
$csSUS = Get-CimSession -ComputerName W12R2SUS
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $csSUS

## multiple sessions to same machine
##
## this errors
$ms = @($csSUS, $cs2)
$ms
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $ms

## get duplicates
$ms = $cs2 + $csSUS
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $ms

## if don't want duplicates
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession ($ms | Sort-Object ComputerName -Unique)

##  ISSUE
##
$cs4 = New-CimSession -ComputerName W8R2STD01
$cs4
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs4

## try direct
Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName W8R2STD01

## try WMI cmdlet
Get-WmiObject -Class Win32_OperatingSystem -ComputerName W8R2STD01

##  DCOM works but not WSMAN
## Wrong WSMAN
##
Test-WSMan -ComputerName W8R2STD01 -Authentication Default  

## lets remove CIM session to W8R2STD01
## view sessions
Get-CimSession
## for W8R2STD01
Get-CimSession -ComputerName W8R2STD01
## remove session
Get-CimSession -ComputerName W8R2STD01 | Remove-CimSession

## can create a DCOM based CIM session
##  DCOM sessions automatically get packet privacy
Get-Command New-CimSessionOption -Syntax
$csdopt = New-CimSessionOption -Protocol Dcom
$csd = New-CimSession -ComputerName W8R2STD01 -SessionOption $csdopt
$csd
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $csd

## can combine use of WSMAN & DCOM sessions
##
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession (Get-CimSession)

## CDXML cmdlets don't have -computerName
##   just CIMsession
Get-Command Get-NetAdapter -Syntax
Get-NetAdapter -CimSession (Get-CimSession)

## error because CIM class not present
##  notice namespace being used
Get-NetAdapter | Get-Member

## can revert to Win32_NetworkAdapter
Get-CimInstance -ClassName Win32_NetworkAdapter -CimSession (Get-CimSession)

## Note Nano server doesn't have this class
Get-CimInstance -ClassName Win32_NetworkAdapter -CimSession $cs1

##
## connecting to non-domain
##  OR non-Windows machines

$pwd = ConvertTo-SecureString -AsPlainText -Force -String 'Password1'
$params = @{
    ComputerName = '10.10.54.70'
    Credential = New-Object pscredential -ArgumentList root, $pwd
    Authentication = 'Basic'
    SessionOption = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck
}
$csA = New-CimSession @params
$csA

## Now have a WSMAN connection
##  to a Linux based network switch!!!
## can do same with LInux server or ESX
##  for based device Linux using OMI

## this fails
##   OMI issue
Get-CimClass -CimSession $csA -ClassName CIM_*

Get-CimClass -CimSession $csA -ClassName CIM_EthernetPort

Get-CimClass -CimSession $csA -ClassName Arista_EthernetPort

$class = Get-CimClass -CimSession $csA -ClassName Arista_EthernetPort
$class.CimClassProperties | Select-Object Name
$class.CimClassMethods

Get-CimInstance -CimSession $csA -ClassName Arista_EthernetPort |
Format-Table -AutoSize DeviceId, OperationalStatus, EnabledState

## WMF 5.0 NetworkSwitch module
Get-Command -Module NetworkSwitchManager

Get-NetworkSwitchFeature -CimSession $csA

## Notice working over CIM!
## Notice class
Get-NetworkSwitchFeature -CimSession $csA | Format-List *

Get-NetworkSwitchGlobalData -CimSession $csA | Format-List *

Get-NetworkSwitchVlan -CimSession $csA | Format-List *

Get-NetworkSwitchEthernetPort -CimSession $csA

# Notice class
Get-NetworkSwitchEthernetPort -PortNumber 1 -CimSession $csA | Format-List *
Get-NetworkSwitchEthernetPort -CimSession $csA | Select-Object Name, EnabledState, PortNumber  

Disable-NetworkSwitchEthernetPort -PortNumber 1 -CimSession $csA 
Get-NetworkSwitchEthernetPort -CimSession $csA | Select-Object Name, EnabledState, PortNumber  

Enable-NetworkSwitchEthernetPort -PortNumber 1 -CimSession $csA
Get-NetworkSwitchEthernetPort -CimSession $csA | Select-Object Name, EnabledState, PortNumber  

Save-NetworkSwitchConfiguration -CimSession $csA -Verbose

## clean up
Get-CimSession | Remove-CimSession