#region WHAT IS CDXML ?

    # Cmdlet definition XML (CDXML) is a way to create a Windows PowerShell module from a WMI class 
    # by using the cmdlets-over-objects technology that was introduced in Windows PowerShell 3.0. 

    # The WMI source class
    Get-CimInstance -ClassName Win32_Account | Format-Table -AutoSize -Property name, SID

    # The CDXML module
    # psedit 'c:\demo\networking\CDXML\Win32_Account.cdxml'
    Import-Module 'c:\demo\networking\CDXML\Win32_Account.cdxml' -Force
    Get-Command -Module Win32_Account
    
    # The term "LocalAccount" is a bit ambiguous, 'cause Win32_Account lists all valid accounts 
    # including those from the domain, if PC is domain joined. 
    Get-LocalAccount | Format-Table -AutoSize -Property name, SID

    # Any difference? 
    Compare-Object (Get-CimInstance -ClassName Win32_Account) (Get-LocalAccount)

#endregion


#region FIND CDXML BASED CMDLETS

    $modulesFolders = Get-ChildItem "$pshome\Modules" -Directory
    $modulesCDXML = @()
    $modulesNonCDXML = @()

    foreach ($modulesFolder in $modulesFolders) {
        $cdxml = Get-ChildItem -Path $($modulesFolder.fullname) -File -Filter *.cdxml -Recurse
        if ($cdxml) {$modulesCDXML += $modulesFolder.name } else { $modulesNonCDXML += $modulesFolder.name } 
    }

    # Counting commands ..
    $a = $modulesCDXML.count
    $b = (Get-Command -Module $modulesCDXML).count
    $c = $modulesNONCDXML.count
    $d = (Get-Command -Module $modulesNONCDXML).count

    "Found $a modules based on CDXML containing $b cmdlets."
    "Found $c modules NOT based on CDXML containing $d cmdlets.`n"
    "OS:    $os"
    "Build: $version"

#endregion