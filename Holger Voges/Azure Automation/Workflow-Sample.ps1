<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "Automatisierung mit Azure Automation, Runbooks und Workflows"
    Part 3: A Workflow Example
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>

# Workflows
# Ausführliche Beschreibung unter
# https://technet.microsoft.com/de-de/library/jj574157.aspx
# https://blogs.technet.microsoft.com/heyscriptingguy/2012/12/26/powershell-workflows-the-basics/
# https://technet.microsoft.com/de-de/library/jj574140.aspx
# https://azure.microsoft.com/en-us/documentation/articles/automation-powershell-workflow/#inline-script

Workflow Demo
{
    param(
        $param1
    )

    'Dies ist eine normale Aktivität'
    Get-Process -Name chrome -PSComputerName Server01 # alle Aktivitäten bekommen alltemeine Aktivitätsparameter wie PSComputerName
    Checkpoint-Workflow 

    InlineScript { Get-Variable -Name PSVersionTable } # Get-Variable ist ein ausgeschlossenes Cmdlet
    InlineScript { \\DC01\Scripte\test-Workflow.ps1 -Online } -PSPersist # Aufrufen eines Scripts, Prüfpunkt anlegen
    Get-WIndowsfeature -Name Hyper-V # Get-Windowsfeature wird automatisch in ein InlineScript umgewandelt 

    Parallel
    {
        Get-Process
        Get-Service
    }

    $Disks = Get-Disk
    Foreach -Parallel ($disk in $Disks)
    {
        $DiskPath = $Disk.Path   
        $Disk | Initialize-Disk
        Set-Disk -Path $DiskPath

    }

    Parallel
    {
      
       Sequence
       {
            $Data = Get-Data
            $Data | Set-Data
       }

    }

}

# Einschränkungen: Keine Positionsparameter
# Innerhalb eines Workflows sind Objekte de-serialisiert, Methoden sind also nicht verfügbar
