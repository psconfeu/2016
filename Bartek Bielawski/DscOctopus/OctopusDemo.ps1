#region prep
$nugetKey = 'f8dd4ee2-aebd-4f63-83fa-1999e96ca66c'
$ApiKey = 'API-MDDUP8RCKVGKTSTZZGPDLTO8S'
Add-Type -Path 'C:\Program Files\WindowsPowerShell\Modules\Octoposh\0.4.6\bin\Octopus.Platform.dll'
Clear-Host
$PSDefaultParameterValues.'*-OPGitPullRequest:Credential' = $MonadCredentials
# start powershell `-file, d:\stash\Animation.ps1
#endregion

#region Stash/Git repo

# Using git cli/ PowerShell to talk to Git API
Get-OPGitPullRequest -Repository octopus -State ALL |
    Format-Table
New-OPGitPullRequest -Repository Octopus -SourceBranch op_bartek -Title 'Another smart title' -Description 'It''s not like we will show it to everybody on stage, right?'
Get-OPGitPullRequest -Repository Octopus -OutVariable myRequest
$myRequest | Merge-OPGitPullRequest

New-OPGitPullRequest -Repository dsc-resources -SourceBranch op_bartek -Title 'Who reads it anyway?' -Description 'Go!'
Get-OPGitPullRequest -Repository dsc-resources -OutVariable dscRequest
$dscRequest | Merge-OPGitPullRequest
$dscRequest.Show()
$dscRequest | Merge-OPGitPullRequest

#endregion

#region Bamboo/CI server
Start-Process http://bamboo.monad.net
#endregion

#region Gallery/Code repo
Start-Process http://gallery.monad.net
Get-PSRepository
Find-Module -Repository InternalPSGallery
#endregion

#region DSC/ Partials/ Baseline
psedit D:\Stash\Dsc-Configurations\Partial\*.ps1
#endregion

#region Octopus
Start-Process http://octopus.monad.net
Add-OPOctopusVariable -ProjectName 'Variable sack' -OctopusConfigurationFile .\Octopus.App.config -ApplicationConfigurationFile .\OTL.PositionFeeder.exe.config -EnvironmentScope Test -Mode Overwrite -OctopusServerUrl http://octopus.monad.net -OctopusApiKey $ApiKey -Verbose
#endregion