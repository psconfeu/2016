####################################################################################################
##  WMI type accelerators
##    - WMIClass
##    - WMISearcher
##    - WMI
##
####################################################################################################
# use [WMIClass] to create instance
#
$c = [WMIClass]'Win32_Process'
$c.Create('calc.exe')

####################################################################################################
# use [WMISearcher] to find instance
#

calc.exe
## using Get-Process
Get-Process | Where-Object Name -eq 'Calc' 

## windows 10 vs 2012 !!!!
## alternatively use [WMISearcher] to conduct a search
$query = [WMISEARCHER] "Select * from Win32_Process where Name = 'Calc.exe'" 

## $query.get() 
## will return mountains of data
## so filter
$query.get() | Format-Table Handlecount, WS, VM, Name -auto 

## same as
## 
Get-WmiObject -Class Win32_Process -Filter "Name = 'Calc.exe'" | 
Format-Table Handlecount, WS, VM, Name -auto 

####################################################################################################
## use [WMI] to find instance
## 

[wmi]"root\cimv2:Win32_Process.Name=’calc.exe'"

## have to use class key
##
foreach ($property in (Get-CimClass -ClassName Win32_Process).CimClassProperties) {
    $property | Select-Object -ExpandProperty Qualifiers | 
        foreach {
            if ($_.Name -eq 'key'){
                $property
            }
        }
}

$h = Get-CimInstance Win32_Process -Filter "Name = 'calc.exe'" | 
Select-Object -ExpandProperty Handle
[wmi]"root\cimv2:Win32_Process.Handle=$h"

## has to be Handle returned by WMI class
##  NOT get-process which changes!
Get-Process calc | Select-Object Handle
Get-Process calc | Select-Object Handle
Get-Process calc | Select-Object Handle