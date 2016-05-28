<#
    The following scripts are examples from the European Powershell Conference 2016
    
    Track-Title: "Automatisierung mit Azure Automation, Runbooks und Workflows"
    Part 1: Run Azure Automation Runbooks
    
    Author: Holger Voges
    web: www.netz-weise-it.training
    email: holger.voges(at)netz-weise.de
    twitter: @HolgerVoges
#>


$AzureSubscription = 'Visual Studio Premium bei MSDN'
# Installing and Importing the Azure-Automation Module 
# If the module is not already installed, get it via Powershell Package Manager
Install-Module AzureAutomationAuthoringToolkit -Scope CurrentUser
Import-Module AzureAutomationAuthoringToolkit


# Loging in to azure
Add-AzureRmAccount
# Get the Subscription in which the Automation-Account resides
$Subscription = Get-AzureRmSubscription -SubscriptionName $AzureSubscription | Set-AzureRmContext

# Get the Resource-Group in which the Azure-Automationaccount resides. A Resource-Group groups
# several Azure Resources and can be used for assigning permissions and make it easier to set default 
# settings, because they only have to be assigned to the group, not each resource. 
$RG = Get-AzureRmResourceGroup -Name PsConfEU
$automationAccountName = $RG | Get-AzureRmAutomationAccount

# https://azure.microsoft.com/en-us/documentation/articles/automation-configuring/
# Use Automation-Credentials as runas-accounts for Scripts
$credential = Get-AutomationPSCredential -Name 'Automation' # get the Account "Automation"
Add-AzureAccount -Credential $Credential # Login with the account named under -credential

#region Start a runbook
Get-AzureRmAutomationRunbook -AutomationAccountName $automationAccountName.AutomationAccountName -ResourceGroupName $RG.ResourceGroupName
$job = Start-AzureRmAutomationRunbook -AutomationAccountName $automationAccountName.AutomationAccountName -Name AzureAutomationTutorial -ResourceGroupName $RG.ResourceGroupName
# Getting the Job and it´s generated output
Get-AzureRmAutomationJob
Get-AzureRmAutomationJobOutput

# Ein Runbook in einer Hybrid Group starten
# Start a runbook in a Hybrid Group.
# Hybrid Groups are local servers which are connected to Azure via Operations Management Suite, another Cloud Service from Microso
Start-AzureRmAutomationRunbook –AutomationAccountName $automationAccountName.AutomationAccountName –Name 'MfR-PSH' -ResourceGroupName $RG.ResourceGroupName -RunOn 'PSConfEU'

# Schedule a runbook
$automationAccountName = 'MyAutomationAccount'
$scheduleName = 'Sample-DailySchedule'
New-AzureAutomationSchedule –AutomationAccountName $automationAccountName –Name $scheduleName –StartTime '1/20/2015 15:30:00' –DayInterval 1

# connecting a schedule
$automationAccountName = 'MyAutomationAccount'
$runbookName = 'Test-Runbook'
$scheduleName = 'Sample-DailySchedule'
$params = @{'FirstName'='Joe';'LastName'='Smith';'RepeatCount'=2;'Show'=$true}
Register-AzureAutomationScheduledRunbook –AutomationAccountName $automationAccountName –Name $runbookName –ScheduleName $scheduleName –Parameters $params

# disabling a schedule
$automationAccountName = 'MyAutomationAccount'
$scheduleName = 'Sample-DailySchedule'
Set-AzureAutomationSchedule –AutomationAccountName $automationAccountName –Name $scheduleName –IsEnabled $false


# Den Status eines laufenden Runbooks abfragen
# Get the status of an executing runbook
$doLoop = $true
While ($doLoop) {
   $job = Get-AzureAutomationJob –AutomationAccountName 'MyAutomationAccount' -Id $job.Id
   $status = $job.Status
   $doLoop = (($status -ne 'Completed') -and ($status -ne 'Failed') -and ($status -ne 'Suspended') -and ($status -ne 'Stopped'))
}

Get-AzureAutomationJobOutput –AutomationAccountName 'MyAutomationAccount' -Id $job.Id –Stream Output

#endregion

#region Parameter 

# If the runbook requires parameters, then you must provide them as a hashtable where the key of the hashtable matches the parameter name and the value is the parameter value. 
# If the parameter is data type [object], then you can use the following JSON format to send it a list of named values: 
# {"Name1":Value1, "Name2":Value2, "Name3":Value3}.
# https://azure.microsoft.com/en-us/documentation/articles/automation-starting-a-runbook/

Workflow Test-Parameters
{
   param (
      [Parameter(Mandatory=$true)][object]$user
   )

    if ($user.Show) {
        foreach ($i in 1..$user.RepeatCount) {
            $user.FirstName
            $user.LastName
        }
    }
}

# Das Runbook aufrufen
# Call the runbook: 
$params = @{'FirstName'='Joe';'LastName'='Smith';'RepeatCount'=2;'Show'=$true}
Start-AzureAutomationRunbook –AutomationAccountName 'MyAutomationAccount' –Name 'Test-Runbook' –Parameters $params
#endregion


# Anmeldeinformationen erstellen
# Create Login-Credentials

$user = 'MyDomain\MyUser'
$pw = ConvertTo-SecureString 'PassWord!' -AsPlainText -Force
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pw
New-AzureAutomationCredential -AutomationAccountName 'MyAutomationAccount' -Name 'MyCredential' -Value $cred

# Beispiel: Die Automation Credentials abfragen
# Die Credentials liegen verschlüsselt bei Azure im Automation Account und können nur von einem Benutzer mit 
# Berechtigungen auf dem Automation Account abgefragt werden. 
# Sample: Get the secure Automation-Credentials. 
# The credentials are securely saved in Azure and can only be retrieved by an account with sufficient permissions on the
# Automation-Account
$myCredential = Get-AutomationPSCredential -Name 'MyCredential'
$userName = $myCredential.UserName
$securePassword = $myCredential.Password
$password = $myCredential.GetNetworkCredential().Password

#region Child-Runbooks
# Child Runbooks können als Befehl aufgerufen werden. Das Runbook wartet auf das Ergebnis wie auf den Aufruf eines Cmdlets
# Es können beliebige Input-Parameter verwendet werden. Das Ergebnis kann direkt in einer Variablen gespeichert werden. 
# Child-Runbook "Test-Childrunbook" ist ein Workflow. Aufruf wie ein Cmdlet
# Child-Runbooks are called like Commands. The Runbooks is waiting for the result like it waits for a called cmdlet. 
# You can use as many Input-Parameters as you like. The result can be saved in a Variable. 
# The Child-runbook "Test-Childrunbook" is a workflow and is called like a cmdlet. 

$vm = Get-AzureVM –ServiceName 'MyVM' –Name 'MyVM'
$output = Test-ChildRunbook –VM $vm –RepeatCount 2 –Restart $true

# Gleiches Beispiel, aber das Childrunbook ist ein Powershell-Script
# Same Example, but now the Childrunbook is a powershell-script
$vm = Get-AzureVM –ServiceName 'MyVM' –Name 'MyVM'
$output = .\Test-ChildRunbook.ps1 –VM $vm –RepeatCount 2 –Restart $true

# Child-Runbook per Cmdlet "Start-AzureAutomationRunbook
# Start-AzureAutomationRunbook startet das Runbook wie ein Job. Es können nur einfache Parameter übergeben werden. 
# Alternativ kann das Help-script Start-CHildrunbook aus der Gallery verwendet werden. 
# Start-AzureAutomationRunbook starts the runbook like a job. Only simple Parameters (no Objects) can be used, as 
# the Parameters are serialized. 
# Alternatively, you can use the Helper-Script Start-childrunbook from the Powershell Gallery. 

params = @{'VMName'='MyVM';'RepeatCount'=2;'Restart'=$true} 
$job = Start-AzureAutomationRunbook –AutomationAccountName 'MyAutomationAccount' –Name 'Test-ChildRunbook' –Parameters $params

$doLoop = $true
While ($doLoop) {
   $job = Get-AzureAutomationJob –AutomationAccountName 'MyAutomationAccount' -Id $job.Id
   $status = $job.Status
   $doLoop = (($status -ne 'Completed') -and ($status -ne 'Failed') -and ($status -ne 'Suspended') -and ($status -ne 'Stopped') 
}

Get-AzureAutomationJobOutput –AutomationAccountName 'MyAutomationAccount' -Id $job.Id –Stream Output
#endregion
