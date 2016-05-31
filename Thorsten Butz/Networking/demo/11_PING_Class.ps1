#region PING AS A CLASS

    # Credit to Trevor Jones
    # https://smsagent.wordpress.com/posh-5-custom-classes/power-ping/

    class Ping
    {
       # Property 
       [array] $Results
       [array] $Online
       [array] $Offline
       $ExecutionTime
       $TotalComputers
       $OnlineCount
       $OnlinePercent
       $OfflineCount
       $OfflinePercent

       # Constructor
       Ping ([array] $Computers)
       {
           function Invoke-MultiThreadedCommand 
            {
                [CmdletBinding()]
                param(
                    [parameter(Mandatory = $True,ValueFromPipeline=$true,Position = 0)]
                    $ProcessArray,
                    [parameter(Mandatory = $True)]
                    [ScriptBlock]$Scriptblock,
                    [parameter()]
                    $ThrottleLimit = 32,
                    [parameter()]
                    [switch]
                    $ShowProgress
                )

                Begin 
                {
                    # Create runspacepool, add code and parameters and invoke Powershell
                    [void][runspacefactory]::CreateRunspacePool()
                    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                    $script:RunspacePool = [runspacefactory]::CreateRunspacePool(1,$ThrottleLimit,$SessionState,$host)
                    $RunspacePool.Open()
        
                    # Function to start a runspace job
                    function Start-RSJob
                    {
                        param(
                            [parameter(Mandatory = $True,Position = 0)]
                            [ScriptBlock]$Code,
                            [parameter()]
                            $Arguments
                        )
                        if ($RunspacePool.GetAvailableRunspaces() -eq 0)
                            {
                                do {}
                                Until ($RunspacePool.GetAvailableRunspaces() -ge 1)
                            }
            
                        $PowerShell = [powershell]::Create()
                        $PowerShell.runspacepool = $RunspacePool
                        [void]$PowerShell.AddScript($Code)
                        foreach ($Argument in $Arguments)
                        {
                            [void]$PowerShell.AddArgument($Argument)
                        }
                        $job = $PowerShell.BeginInvoke()
    
                        # Add the job and PS instance to the arraylist
                        $temp = '' | Select-Object -Property PowerShell, Job
                        $temp.PowerShell = $PowerShell
                        $temp.Job = $job
                        [void]$Runspaces.Add($temp)  
            
                    }
            
                    # Start a 'timer'
                    $Start = Get-Date
                
                    # Define an arraylist to add the runspaces to
                    $script:Runspaces = New-Object -TypeName System.Collections.ArrayList
                    $i = 0
                }
            
                Process 
                {
                    # Start an RS job for each computer
                    $ProcessArray | ForEach-Object -Process {
                        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent) 
                        {
                            $host.UI.WriteVerboseLine("Starting RS job for $_")
                        }
                        Start-RSJob -Code $Scriptblock -Arguments $_
                        $i ++
                        if ($ShowProgress)
                            {Write-Progress -Activity "Invoking Jobs" -CurrentOperation $_}
                    }
                }
            
                End 
                {
                    # Wait for each script to complete
                    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent) 
                    {
                        $host.UI.WriteVerboseLine('Waiting for RS jobs to finish')
                    }
                    $x = 0
            
                    foreach ($item in $Runspaces)
                    {
                        $x ++
                        if ($ShowProgress)
                            {Write-Progress -Activity "Retrieving Job Output" -PercentComplete ($x / $i * 100) -Status "$([math]::Round(($x / $i * 100),0)) %"}
                        do 
                        {
                        }
                        until ($item.Job.IsCompleted -eq 'True')
                    }
            
                    # Grab the output from each script, and dispose the runspaces
                    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent) 
                    {
                        $host.UI.WriteVerboseLine('Retrieving results and disposing runspaces')
                    }
                    $return = $Runspaces | ForEach-Object -Process {
                        $_.powershell.EndInvoke($_.Job)
                        $_.PowerShell.Dispose()
                    }
                    $Runspaces.clear()
                    [void]$RunspacePool.Close()
                    [void]$RunspacePool.Dispose
            
                    # Stop the 'timer'
                    $End = Get-Date
                    $TimeTaken = [math]::Round(($End - $Start).TotalSeconds,2)
                    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent) 
                    {
                        $host.UI.WriteVerboseLine("Command completed in $TimeTaken seconds")
                    }
            
                    # Return the results
                    $return
                }
            }
                   
            # Define the "Test-Connection" code
            $code = 
            {
                param($ComputerName)
                $t = Test-connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue
                if ($t)
                {
                    $t
                }
            }
        
            $Start = Get-date
            $Result = $Computers | Invoke-MultiThreadedCommand -Scriptblock $Code -ShowProgress -ThrottleLimit 64
            $End = Get-Date
            $On = $Result.ForEach{$_.Address}
            $Off = $Computers.Where{$_ -notin $On}
       
       
           $this.Results = $Result
           $this.Online = $On  
           $this.Offline = $Off
           $this.ExecutionTime = "$([math]::Round(($End - $Start).TotalSeconds,2)) seconds"
           $this.OfflineCount = $off.Count
           $this.OnlineCount = $on.Count
           $this.TotalComputers = $Computers.Count
           $this.OnlinePercent = "$([math]::Round(($($on.Count) / $($Computers.Count) * 100))) %"
           $this.OfflinePercent = "$([math]::Round(($($off.Count) / $($Computers.Count) * 100))) %"
       }
    }

#endregion

# Check the duration 
$start = Get-Date

# Build subnet IPs
$ips = @()
1..254 | % {$ips += '192.168.0.' + $_ }

# Ping it!
[ping]$test = $ips

# Get (simple) results
$test.online

$seconds = [int]((Get-Date) - $start).TotalSeconds
"It took $seconds to ping the subnet."