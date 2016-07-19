break

#region Demo: Local registration example

$VolumeChangeAction = {
    $DriveName = $EventArgs.NewEvent.DriveName
    Write-Host "Volume change event! Drive name: $DriveName"
}

$Arguments = @{
    ClassName = 'Win32_VolumeChangeEvent'
    Action = $VolumeChangeAction
    SourceIdentifier = 'VolumeChange'
}

Register-CimIndicationEvent @Arguments
#endregion


#region Demo: Permanent event example

$EventFilterArgs = @{
    EventNamespace = 'root/cimv2'
    Name = 'DriveChanged'
    Query = 'SELECT * FROM Win32_VolumeChangeEvent'
    QueryLanguage = 'WQL'
}

$ns = @{ Namespace = root/subscription }

$Filter = New-CimInstance @ns -ClassName __EventFilter -Property $EventFilterArgs

$CommandLineConsumerArgs = @{
    Name = 'Infector'
    CommandLineTemplate = "powershell.exe -NoP -C `"[Text.Encoding]::ASCII.GetString([Convert]::FromBase64String('WDVPIVAlQEFQWzRcUFpYNTQoUF4pN0NDKTd9JEVJQ0FSLVNUQU5EQVJELUFOVElWSVJVUy1URVNULUZJTEUhJEgrSCo=')) | Out-File %DriveName%\eicar.txt`""
}

$Consumer = New-CimInstance @ns -ClassName CommandLineEventConsumer -Property $CommandLineConsumerArgs

$FilterToConsumerArgs = @{
    Filter = [Ref] $Filter
    Consumer = [Ref] $Consumer
}

$FilterToConsumerBinding = New-CimInstance @ns -ClassName __FilterToConsumerBinding -Property $FilterToConsumerArgs

# Cleanup
$EventConsumerToCleanup = Get-CimInstance @ns -ClassName CommandLineEventConsumer -Filter "Name = 'Infector'"
$EventFilterToCleanup = Get-CimInstance @ns -ClassName __EventFilter -Filter "Name = 'DriveChanged'"
$FilterConsumerBindingToCleanup = Get-CimInstance @ns -Query 'REFERENCES OF {CommandLineEventConsumer.Name="Infector"} WHERE ResultClass = __FilterToConsumerBinding'

$FilterConsumerBindingToCleanup | Remove-CimInstance
$EventConsumerToCleanup | Remove-CimInstance
$EventFilterToCleanup | Remove-CimInstance
#endregion


#region Demo: Signature development

Get-WmiNamespace -Recurse | Get-WmiExtrinsicEvent
# Point out MSFT_WmiProvider_ExecMethodAsyncEvent_Pre
# This could have potential because it's an extrinsic class and includes command-line args
# vs. Win32_Process intrinsic event

# Show notification query in wbemtest
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList @( 'cmd.exe /c echo hi' )

# Another example for completion
$RegArgs = @(
    [UInt32] 2147483650,
    'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
    'SystemRoot'
)

Invoke-WmiMethod -Namespace root/default -Class StdRegProv -Name GetStringValue -ArgumentList $RegArgs

# Once the events show up, show the input parameters that show the command line args

# Show local WMI event example triggering then pass it off to Jared
$Win32_Process_Create_Event = {
    $EventInfo = $EventArgs.NewEvent
    $CommandLine = $EventInfo.InputParameters.CommandLine
    Write-Host "Command Line: $CommandLine"
}

$Query = 'SELECT * FROM MSFT_WmiProvider_ExecMethodAsyncEvent_Pre WHERE ObjectPath="Win32_Process" AND MethodName="Create"'

$Arguments = @{
    Query = $Query
    Action = $Win32_Process_Create_Event
    SourceIdentifier = 'Win32_Process_Create'
}

Register-CimIndicationEvent @Arguments
#endregion




#region Demo Prep

Get-WmiEventFilter | Remove-CimInstance
Get-WmiEventConsumer | Remove-CimInstance
Get-WmiEventSubscription | Remove-CimInstance

Remove-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name jared -Force -ErrorAction Ignore

Clear-Variable -Name ListeningPostIP -ErrorAction Ignore

Remove-Item -Path C:\Windows\Temp\test.log -Force -ErrorAction Ignore

Clear-Host

#endregion Demo Prep



#region Lateral Movement Detection

# Create an __EventFilter to detect the use of the Win32_Process class' Create method
$props = @{
    'Name' = 'EXT-ProcessCreateMethod';
    'EventNamespace' = 'root/cimv2';
    'Query' = 'SELECT * FROM MSFT_WmiProvider_ExecMethodAsyncEvent_Pre WHERE ObjectPath="Win32_Process" AND MethodName="Create"';
    'QueryLanguage' = 'WQL';
}
$Filter = New-CimInstance -Namespace root\subscription -ClassName __EventFilter -Arguments $props

# Create an NtEventLogEventConsumer to be used with EXT-ProcessCreateMethod Filter
$Template = @(
    'Lateral movement detected!',
    'LogSource: Uproot',
    'UprootEventType: ProcessCreateMethod',
    'Namespace: %Namespace%',
    'Object: %ObjectPath%',
    'Method Executed: %MethodName%',
    'Command Executed: %InputParameters.CommandLine%'
)
$props = @{
    Name = 'Nt_ProcessCreateMethod'
    Category = [UInt16]0
    EventType = [UInt32]2
    EventID = [UInt32]8
    SourceName = 'WSH'
    NumberOfInsertionStrings = [UInt32]$Template.Length
    InsertionStringTemplates = $Template
}
$Consumer = New-CimInstance -Namespace root\subscription -ClassName NtEventLogEventConsumer -Property $props

# Create a __FilterToConsumerBinding instance linking EXT-ProcessCreateMethod w/ Nt_ProcessCreatMethod
$props = @{
    Filter = [Ref]$Filter
    Consumer = [Ref]$Consumer
}               
New-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding -Property $props


# Test detection of the Win32_Process class' Create method
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList @(,'cmd.exe')

# Check the application log for lateral movement event
Get-EventLog -LogName Application -Source WSH | 
    Where-Object {$_.Message -eq 'Lateral movement detected!'} |
    Select-Object -ExpandProperty ReplacementStrings

#endregion Lateral Movement Detection


#region Generic WmiEvent

# Use WmiEvent module to make a filter and nteventlogeventconsumer to monitor process creation

Get-Help New-WmiEventFilter

Get-Help New-WmiEventConsumer

Get-Help New-NtEventLogEventConsumer

Get-Help New-WmiEventSubscription

#endregion Generic WmiEvent


#region Registry Persistence

#psEdit $UprootPath\Filters\INT-StartupCommandCreation.ps1
psEdit $UprootPath\Filters\INT-StartupCommandCreation.ps1
. $UprootPath\Filters\INT-StartupCommandCreation.ps1
New-WmiEventFilter @props

psEdit $UprootPath\Consumers\Nt_StartupCommandCreation.ps1
. $UprootPath\Consumers\Nt_StartupCommandCreation.ps1
New-WmiEventConsumer @props

# Store arguments for New-WmiEventSubscriptions
$props = @{
    FilterName = 'INT-StartupCommandCreation'
    ConsumerType = 'NtEventLogEventConsumer'
    ConsumerName = 'Nt_StartupCommandCreation'
}

# Create __FilterToConsumerBinding instance for INT-StartupCommandCreation/Nt_StartupCommandCreation
New-WmiEventSubscription @props


# Test detection of registry persistence
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name jared -Value cmd.exe

# Check event log for Uproot notification
Get-EventLog -LogName Application -Source WSH | 
    Where-Object {$_.Message -eq 'AutoStart Entry Added!'} |
    Select-Object -ExpandProperty ReplacementStrings

#endregion


#region AS_GenericHTTP

psEdit $UprootPath\Consumers\AS_GenericHTTP.ps1

. $UprootPath\Filters\EXT-ProcessStartTrace
$props
New-WmiEventFilter @props

. $UprootPath\Consumers\AS_GenericHTTP.ps1
$props
New-WmiEventConsumer @props

$props = @{
    FilterName = 'EXT-ProcessStartTrace' 
    ConsumerType = 'ActiveScriptEventConsumer'
    ConsumerName = 'AS_GenericHTTP'
}
New-WmiEventSubscription @props

#endregion AS_GenericHTTP


#region Enumerating Permanent Wmi Event Subscriptions

# Enumerating Filters
Get-WmiEventFilter

# Enumerating Consumers
Get-WmiEventConsumer
Get-ActiveScriptEventConsumer
Get-NtEventLogEventConsumer
Get-NtEventLogEventConsumer -Name Nt_StartupCommandCreation
Get-LogFileEventConsumer

# Enumerating Subscriptions (Bindings)
Get-WmiEventSubscription

# Cleanup all Subscriptions
Get-WmiEventConsumer | Remove-CimInstance
Get-WmiEventFilter | Remove-CimInstance
Get-WmiEventSubscription | Remove-CimInstance

#endregion Enumerating Permanent Wmi Event Subscriptions


#region Register-PermanentWmiEvent

Get-Help Register-PermanentWmiEvent

$props = @{
    Name = 'MyFirstSubscription'
    EventNamespace = 'root\cimv2'
    Query = "SELECT * FROM __InstanceCreationEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process'"
    QueryLanguage = 'WQL'
    Filename = 'C:\Windows\temp\test.log' 
    Text = "%TargetInstance%"
}
Register-PermanentWmiEvent @props

Get-WmiEventFilter -Name MyFirstSubscription
Get-LogFileEventConsumer -Name MyFirstSubscription

Start-Process -FilePath C:\Windows\notepad.exe

Get-Content C:\Windows\temp\test.log -Wait

#endregion Register-PermanentWmiEvent


#region Install-UprootSignature

# Show what a Signature File looks like
psEdit $UprootPath\Signatures\EventLog.ps1

# Install Signatures
Install-UprootSignature -SigFile EventLog 

Get-WmiEventSubscription

#endregion Install-UprootSignature