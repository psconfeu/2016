####################################################################################################
##
##  CIM cmdlets
##
####################################################################################################
## 
## CIM cmldets
##  introduced with WMF 3.0
Get-Command -Module  CimCmdlets
##
## getting CIM data
##  easiest is class name
## WQL covered separately
Get-CimInstance -ClassName Win32_Process
##
## root/cimv2 is default namespace
Get-CimInstance -Namespace root/cimv2  -ClassName Win32_Process
##
## other namespaces
Get-CimInstance -Namespace root/StandardCimv2 -ClassName MSFT_NetAdapter | 
Format-List Name, InterfaceDescription, InterfaceIndex, Status, LinkLayerAddress
## or use cmdlet
Get-NetAdapter
##
## filters
##  WQL AFTER where statement
Get-CimInstance -ClassName Win32_Process -Filter "Name like 'powershell%'"
Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'"
Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell_ise.exe'"
## SHALLOW
##  need example

## KEYONLY
##  - just the key
Get-CimInstance -ClassName Win32_Process -KeyOnly | Select-Object -First 1
## adding filter
##  changes results
Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'"
Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell.exe'" -KeyOnly
## Resource URI
##  useful occasionally against remote CIM
##  carry over from WSMAN cmdlets - not really used any more
$uri = 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/Win32_LogicalDisk'
Get-CimInstance -ResourceUri $uri
## need to run over WSMAN
## so use -ComputerName or CimSession
Get-CimInstance -ResourceUri $uri -ComputerName $env:COMPUTERNAME
##
##  selecting from multiple instances
$uri = 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/Win32_Process'
Get-CimInstance -ResourceUri $uri -ComputerName $env:COMPUTERNAME
## this won't work - filter ignored
#Get-CimInstance -ResourceUri $uri -ComputerName $env:COMPUTERNAME -Filter "Name='powershell.exe'"
# can't use $uri = "http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/Win32_Process?Handle=3824"
## which is allowed as WinRM uri! 
Get-CimInstance -ResourceUri $uri -ComputerName $env:COMPUTERNAME | Where-Object Name -like 'powershell*' | 
Format-Table ProcessId, Name, HandleCount, WorkingSetSize, VirtualSize


## refresh object property values
$s = Get-CimInstance -ClassName Win32_Process -Filter "Name='powershell_ise.exe'"
$s
## try this few times
$s | Get-CimInstance

## Invoking methods
##  Invoke-Cimmethod
Get-Command Invoke-CimMethod -Syntax
##
$class = Get-CimClass -ClassName win32_process
$class.CimClassMethods['Create'].Parameters
##
##  method without arguments
notepad
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'"
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'" | Invoke-CimMethod -MethodName Terminate
##
## method with arguments
##  Create class automatically handles creation of instance key
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine='notepad.exe'}
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'" | Select-Object Name, Handle, Priority
##
## dealing with embedded class
$class.CimClassMethods['Create'].Parameters
## actually instance of Win32_ProcessStartup
$psuclass = Get-CimClass -ClassName Win32_ProcessStartUp
## don't often need to create new CIM instance
##   can't create using many classes e.g. Hardware related 
##create new instance in memory only
Get-Command New-CimInstance -Syntax
$psuclass.CimClassProperties | Select-Object Name, CimType, Qualifiers
$psi = New-CimInstance -CimClass $psuclass -Property @{PriorityClass=128; ShowWindow=3} -ClientOnly
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine='notepad.exe'; ProcessStartUpInformation=$psi}
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'" | Select-Object Name, Handle, Priority
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'notepad.exe'" | Invoke-CimMethod -MethodName Terminate
##
## modifying instances
##  NOTE many properties are read only
Get-Command Set-CimInstance -Syntax
## lets create an environment variable
$ce = Get-CimClass -ClassName Win32_Environment
## 2 keys
##  need to define key(s) when creating instance
$ce.CimClassProperties | Select-Object Name, CimType, Qualifiers
New-CimInstance -ClassName Win32_Environment -Property @{Name = 'CWvar'; 
VariableValue = 'CIM workshop 2016'; UserName = "manticore\Richard"}
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'"
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'" | Set-CimInstance -Property @{VariableValue='What about next year?'}
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'"
##
## deleting CIM instances
##  be careful bad things happen if delete Win32_LogicalDisk
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'" | Remove-CimInstance -WhatIf
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'" | Remove-CimInstance -Confirm
## go for it
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'" | Remove-CimInstance
Get-CimInstance -ClassName Win32_Environment -Filter "Name = 'CWvar'"
Get-Command Remove-CimInstance -Syntax