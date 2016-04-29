####################################################################################################
## https://msdn.microsoft.com/en-us/library/aa394606(v=vs.85).aspx
##
##  Using WQL - WMI Query language 
##    - Basic search
##    - Operators
##    - IS and IS NOT
##
##  WQL is subset of SQL
##    SELECT ONLY
##    SCCM expands WQL but only within SCCM
##
####################################################################################################
# Basic search
Clear-Host
calc.exe
##
## query can be on 1 line
## or split for readability
$query = @"
SELECT *
FROM Win32_Process
WHERE Name = 'calc.exe'
"@

Get-WmiObject -Query $query
Get-CimInstance -Query $query

##
## will only use Get-CimInstance for rest of demo
##
## -Filter = WQL after the WHERE keyword
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'calc.exe'"

##
## can select properties
$query = @"
SELECT Name, Threadcount, UserModeTime
FROM Win32_Process
WHERE Name = 'calc.exe'
"@
Get-CimInstance -Query $query
Get-CimInstance -Query $query | fl *
## Not what expecting
##
Get-WmiObject -Query $query

##
## get-CimInstance producing object with all properties 
## but only the default properties and those requested are populated
##
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'calc.exe'"  -Property Name, Threadcount, UserModeTime

##
## need to use select-object
Get-CimInstance -ClassName Win32_Process -Filter "Name = 'calc.exe'"  -Property Name, Threadcount, UserModeTime |
Select-Object Name, Threadcount, UserModeTime

Get-CimInstance -Query $query |
Select-Object Name, Threadcount, UserModeTime

####################################################################################################
# Logical operators
Clear-Host
notepad.exe

$query = @"
SELECT *
FROM Win32_Process
WHERE Name = 'calc.exe'
OR Name = 'notepad.exe'
"@

Get-CimInstance -Query $query

$query = @"
SELECT *
FROM Win32_Process
WHERE HandleCount > 500
AND Priority > 8
"@

Get-CimInstance -Query $query | 
Format-Table Processid, Name, HandleCount, WorkingSetSize, VirtualSize, Priority

####################################################################################################
## Boolean operators
##   True = 1
##   False = 0 
Clear-Host

$query = @"
SELECT *
FROM Win32_NetworkAdapterConfiguration
WHERE DHCPEnabled = TRUE
"@

Get-CimInstance -Query $query 

$query = @"
SELECT *
FROM Win32_NetworkAdapterConfiguration
WHERE DHCPEnabled = FALSE
"@

Get-CimInstance -Query $query 

####################################################################################################
## Comparison Operators
##  =, <, >, <=, >=, != or <>
##  already seen =
Clear-Host

$query = @"
SELECT *
FROM Win32_Process
WHERE HandleCount > 200
AND Priority < 8
"@

Get-CimInstance -Query $query | 
Format-Table Processid, Name, HandleCount, WorkingSetSize, VirtualSize, Priority

$query = @"
SELECT *
FROM Win32_Process
WHERE HandleCount >= 200
AND Priority <= 8
"@

Get-CimInstance -Query $query | Sort-Object Priority |
Format-Table Processid, Name, HandleCount, WorkingSetSize, VirtualSize, Priority

## not equal to
##
$query = @"
SELECT *
FROM Win32_Process
WHERE HandleCount != 200
AND Priority <> 8
"@

Get-CimInstance -Query $query | 
Format-Table Processid, Name, HandleCount, WorkingSetSize, VirtualSize, Priority

####################################################################################################
## LIKE Operator
Clear-Host

## WQL wildcard equivalent of * 
##
$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'c%'
"@

Get-CimInstance -Query $query

## WQL wildcard equivalent of .* 
##  
$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'not_pad.exe'
"@

Get-CimInstance -Query $query

## selected characters
##  
$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'not[e-h]pad.exe'
"@

Get-CimInstance -Query $query

$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'not[efgh]pad.exe'
"@

Get-CimInstance -Query $query

## not selected characters
##  start with set of processes
$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'd%host.exe'
"@

Get-CimInstance -Query $query

$query = @"
SELECT *
FROM Win32_Process
WHERE Name LIKE 'd[^a][^s]host.exe'
"@

Get-CimInstance -Query $query

Get-Process notepad | Stop-Process
Get-Process calculator | Stop-Process

####################################################################################################
## IS & IS NOT
##    ONLY WITH NULL

$query = @"
SELECT *
FROM Win32_NetworkAdapterConfiguration
WHERE DHCPServer IS NULL
"@

Get-CimInstance -Query $query

$query = @"
SELECT *
FROM Win32_NetworkAdapterConfiguration
WHERE DHCPServer IS NOT NULL
"@

Get-CimInstance -Query $query 