####################################################################################################
##
##  CIM events
##   known as Indications when dealing with CIM cmdlets
##
####################################################################################################
##
## CIM classes that deal with general events
##  
Get-CimClass -ClassName CIM_Inst*
## lets drill in a bit
Get-CimClass -ClassName CIM_Inst* |
foreach {
    if ($_.CimClassQualifiers['Indication'].Value){
        $_.CimClassQualifiers['Description'].Value
    }
}

## in use
$query = "SELECT * FROM CIM_InstModification WHERE TargetInstance ISA 'Win32_LocalTime'"
Register-CimIndicationEvent -Query $query -SourceIdentifier 'Timer'

## see results with Get-Event
Clear-Host
Get-Event -SourceIdentifier 'Timer' | Select-Object -Last 3
Start-Sleep -Seconds 10
Get-Event -SourceIdentifier 'Timer' | Select-Object -Last 3
Start-Sleep -Seconds 10
Get-Event -SourceIdentifier 'Timer' | Select-Object -Last 3
##
## lets stop that
Unregister-Event -SourceIdentifier 'Timer'
## check ended
Get-Event -SourceIdentifier 'Timer' | Select-Object -Last 1
## double check
Get-Event -SourceIdentifier 'Timer' | Select-Object -Last 1
## clear events
Get-Event -SourceIdentifier 'Timer' | Remove-Event
Get-Event -SourceIdentifier 'Timer'

## other classes deal with
## specific events
Get-CimClass -ClassName Win32_ProcessStartTrace
Get-CimClass -ClassName Win32_ProcessStopTrace
##
##  register event
$query = 'SELECT * FROM Win32_ProcessStartTrace'
Register-CimIndicationEvent -Query $query -SourceIdentifier 'ProcessStart'
## start process
notepad.exe
Get-Event -SourceIdentifier 'ProcessStart'
##
## lets dig a bit more
$myevent = Get-Event -SourceIdentifier 'ProcessStart' | Select-Object -First 1
$myevent.Sender
#
$myevent.SourceArgs
#
$myevent.SourceEventArgs
## and now get to process
$myevent.SourceEventArgs.NewEvent
## time is in 100-nanosecond intervals
##  after 1 January 1601
##  aka FileTime
[DateTime]::FromFileTimeUtc($myevent.SourceEventArgs.NewEvent.TIME_CREATED)
##
## start powershell console
##  - can get multiple events 
Get-Event -SourceIdentifier 'ProcessStart' |
foreach {
    $_.SourceEventArgs.NewEvent
}
##
Get-Event -SourceIdentifier 'ProcessStart' | Remove-Event
Unregister-Event -SourceIdentifier 'ProcessStart'
##
## can also take actions
##  triggered by event
##  close an unwanted process
$action = {
    if ($($event.SourceEventArgs.NewEvent.ProcessName) -eq 'notepad.exe' ){
        Get-CimInstance -ClassName Win32_Process -Filter "ProcessId= $($event.SourceEventArgs.NewEvent.ProcessId)" |
        Remove-CimInstance
        Write-Warning 'Illegal copy of notepad running - ternminated with extreme prejudice'
    }
}
$query = 'SELECT * FROM Win32_ProcessStartTrace'
Register-CimIndicationEvent -Query $query -SourceIdentifier 'ProcessStart' -Action $action
##
## and we have a job
##  if use -Action its handled through a job
##  notice not started
Get-Job | Select-Object -ExpandProperty Command
## and we start notepad
notepad.exe
## job now running
## and no notepad
Get-Process n*
Get-Job -Name ProcessStart
Stop-Job -Name ProcessStart
## no data
Receive-Job -Name ProcessStart -Keep
Get-Job -Name ProcessStart | Remove-Job
##
Get-Event -SourceIdentifier 'ProcessStart' | Remove-Event
Unregister-Event -SourceIdentifier 'ProcessStart'
#####################
##
## Event registrations are lost when close 
##  PowerShell session
##
## option: 
## WMI permament events
## talk by Atkinson on Wednesday
## My opinion permanent events are more trouble
##  than they're worth