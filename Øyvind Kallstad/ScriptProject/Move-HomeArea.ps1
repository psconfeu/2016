[CmdletBinding()]
param (
    [Parameter()]
    [Alias('Path')]
    [string] $InputFile = 'C:\Demo\ScriptProject\inputfile_test.csv',

    [Parameter()]
    [int] $NumberOfPasses = 1,

    [Parameter()]
    [int] $DelayBetweenPasses = 0 # in seconds
)

function Get-Info {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Username,

        [Parameter()]
        [string] $Path
    )
}

function Invoke-SanityCheck {
    [CmdletBinding()]
    param (
        [Parameter()]
        [psobject] $InputObject
    )

    return $true
}

function Get-UserConnection {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Username,

        [Parameter()]
        [string] $Hostname
    )

    return $true
}

function Invoke-RobocopyWrapper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Path,

        [Parameter()]
        [string] $Destination,

        [Parameter()]
        [string] $Username
    )

    return $false
}

function Update-ADUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Username,

        [Parameter()]
        [hashtable] $PropertyValue
    )

    return $false
}

function Invoke-ProcessInput {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Username,

        [Parameter()]
        [string] $Path
    )

    $inputInfo = Get-Info

    # perform sanity check before we begin
    if (Invoke-SanityCheck -InputObject $inputInfo) {
        Write-Host 'Sanity check ok'

        # check if user have open files on the server
        if (-not (Get-UserConnection -Username $Username -Hostname $inputInfo.OldHomePathServer)) {
            Write-Host 'No user connection found'

            # perform copy of files
            if (Invoke-RobocopyWrapper -Path $inputInfo.OldHomepath -Destination $inputInfo.NewHomePath -Username $Username) {
                Write-Host 'Files copied'

                # update the user object in AD
                if (Update-ADUser -Username $Username -PropertyValue @{'homeDrive' = 'H:';'homeDirectory' = $inputInfo.newHomePathFull}) {
                    Write-Host 'Updated ADUser'
                }
                else {
                    # AD Update failed
                    Write-Warning 'AD Update failed'
                }
            }
            else {
                # file copy failed
                Write-Warning 'File copy failed'
            }
        }
        else {
            # user have open files
            Write-Host 'User have open files / User connection found'
            $script:SkippedBecauseOfOpenFiles += (,([PSCustomObject] @{Username = $inputInfo.Username;NewHomeShare = $inputInfo.NewHomePath}))
            
            # perform copy job anyway
            if (Invoke-RobocopyWrapper -Path $inputInfo.OldHomepath -Destination $inputInfo.NewHomePath -Username $Username) {
                # copy files
                Write-Host 'Copying files anyway...'
            }
            else {
                # copy failed
                Write-Warning 'File Copy failed'
            }
        }
    }
    else {
        # sanity check failed
        Write-Warning 'Sanity check failed'
    }
}

$currentPass = 0
$processingArray = @()

$processingArray = Import-Csv -Path $InputFile

do {
    $currentPass++
    Write-Host "Current pass: $currentPass"
    $script:SkippedBecauseOfOpenFiles = @()

    foreach ($input in $processingArray) {
        Invoke-ProcessInput -Username $input.Username -Path $input.NewHomeShare
    }

    $processingArray = $script:SkippedBecauseOfOpenFiles

    if ($script:SkippedBecauseOfOpenFiles.Count -gt 0) {
        if ($DelayBetweenPasses -gt 0) {
            Write-Host "Delaying $DelayBetweenPasses seconds"
            Start-Sleep -Seconds $DelayBetweenPasses
        }
    }
} until (($currentPass -eq $NumberOfPasses) -or ($SkippedBecauseOfOpenFiles.Count -eq 0))

