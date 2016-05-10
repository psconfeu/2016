####################################################################################################
##  WMI issues and 'gotchas'
##    - Dates
##    - Integer code values
##    - CIM cmdlets = inert objects
##    - Invoke-WmiMethod arguments for method
##    - Amended data
##    - DCOM authentication required e.g. Accessing IIS
##
####################################################################################################
## Dates
##  - WMI format

Get-WmiObject -Class Win32_OperatingSystem | 
Select-Object -Property LastBootUpTime

##
## YYYYMMDDHHMMSS + fraction + timezone offset from GMT

Get-WmiObject -Class Win32_OperatingSystem | 
Select-Object -Property @{N='BootTime'; E={$_.ConvertTodateTime($_.LastBootUpTime)}}

##
## Easier still use CIM cmdets
## remember Windows 10 issue
Get-CimInstance -Class Win32_OperatingSystem | 
Select-Object -Property LastBootUpTime

####################################################################################################
## Integer code values
## 

Get-CimInstance -ClassName Win32_LogicalDisk

## drive type 3 = local hard disk
## https://msdn.microsoft.com/en-us/library/windows/desktop/aa394173(v=vs.85).aspx
##
## could use hash table
## No spaces in text
##

$dtype = DATA {
    ConvertFrom-StringData -StringData @'
    2 = RemovableDisk
    3 = HardDisk
    5 = CD
'@
}
Get-CimInstance -ClassName Win32_LogicalDisk |
Select-Object DeviceId, @{N='DiskType'; E={$dtype["$($_.DriveType)"]}},
VolumeName, Size, FreeSpace


## In PowerShell 5.0 could use enum
## No spaces in text
##

enum disktype {
    RemovableDisk = 2
    HardDisk = 3
    CD = 5
}

Get-CimInstance -ClassName Win32_LogicalDisk |
Select-Object DeviceId, @{N='DiskType'; E={[disktype]$_.DRiveType}},
VolumeName, Size, FreeSpace

####################################################################################################
##  CIM cmldets = inert objects
##
## WMI cmdlets
##
notepad.exe
$procw =  Get-WmiObject -Class Win32_Process -Filter "Name = 'notepad.exe'"
$procw

## kill process
##
$procw.Terminate()

## now try with CIM cmdlets
##
notepad.exe
$procc = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'"
$procc

$procc.Terminate()

## Huh?

## test WMI object
## class methods
$procw | Get-Member -MemberType Method
## with added methods
$procw | Get-Member -MemberType Methods

## compare with CIM object
$procc | Get-Member -MemberType Method
$procc | Get-Member -MemberType Methods

## note object type
## CIM cmdlets return inert objects because work over WSMAN remotely by default
## need to use Invoke-CimMethod

Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'" |
Invoke-CimMethod -MethodName Terminate

####################################################################################################
## Invoke-WmiMethod arguments for method
## 
##   see slide

## lets view part of registry
Get-ChildItem -Path HKLM:\SOFTWARE

## create a subkey
$reg = [wmiclass]'StdRegProv'
[uint32]$hdefkey = 2147483650
$sSubKeyName = 'SOFTWARE\MethodTest'
$reg.CreateKey($hdefkey, $sSubKeyName)

## set a value
$sValueName = 'Date'
$sValue = 'April 2015'
$reg.SetStringValue($hdefkey, $sSubKeyName, $sValueName, $sValue)

## view result
Get-ItemProperty -Path HKLM:\SOFTWARE\MethodTest -Name Date

## WRONG DATE!
$sValue = 'April 2016'

## appears to work
## BUT doesn't change the value
Invoke-WmiMethod -Class StdRegProv -Name SetSTRINGvalue -ArgumentList $hdefkey, $sSubKeyName, $sValueName, $sValue
Get-ItemProperty -Path HKLM:\SOFTWARE\MethodTest -Name Date

## 
## lets check parameters
##   NOTE ORDER of parameters
$cc = Get-CimClass -ClassName StdRegProv
$cc.CimClassMethods['SetStringValue'].Parameters

## double check
($reg.Methods | Where-Object Name -eq 'SetStringValue').Inparameters

## 
## retry
Invoke-WmiMethod -Class StdRegProv -Name SetSTRINGvalue -ArgumentList $hdefkey, $sSubKeyName, $sValue, $sValueName
Get-ItemProperty -Path HKLM:\SOFTWARE\MethodTest -Name Date

## 
##  CIM cmdlet doesn't have the problem
##  arguments as hashtable
##  order doesn't matter
$sValue = 'April 2017'
Invoke-CimMethod -ClassName StdRegProv -MethodName SetSTRINGvalue `
-Arguments @{sValue=$sValue; sSubKeyName=$sSubKeyName; hDefKey=$hdefkey; sValueName=$sValueName}
Get-ItemProperty -Path HKLM:\SOFTWARE\MethodTest -Name Date

## remove demo key
Invoke-CimMethod -ClassName StdRegProv -MethodName DeleteKey -Arguments @{sSubKeyName=$sSubKeyName; hDefKey=$hdefkey} 
Get-ChildItem -Path HKLM:\SOFTWARE

####################################################################################################
## Ammended data
##  normally don't access because its expensive
Get-WmiObject -List Win32*networkadapter* |
foreach {
    "`n$($_.Name)"
   ((Get-WmiObject -List $($_.Name) -Amended).Qualifiers |
    Where-Object Name -eq 'Description').Value
}

####################################################################################################
## DCOM authentication required e.g. Accessing IIS
## 
## on W12R2SUS run
Get-WmiObject -Namespace root\webadministration -List 
## on W8R2STD01 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS
## on server02 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS
## 
## changed in WMF 5
## but before that some namespaces (eg IIS & Cluster) required DCOM authentication
##  - actually encryption level
## on W8R2STD01 run
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS -Authentication PacketPrivacy
Get-WmiObject -Namespace root\webadministration -List -ComputerName W12R2SUS -Authentication 6
##
Get-WmiObject -Namespace root\webadministration -Class Server -ComputerName W12R2SUS -Authentication 6
##
## CIM cmdlets don't have the problem
Get-CimInstance -Namespace root\webadministration -ClassName Server -ComputerName W12R2SUS