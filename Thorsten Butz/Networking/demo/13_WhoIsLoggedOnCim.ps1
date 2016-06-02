#region WHO IS LOGGED ON?

    # The owner of "explorer.exe" is a good indicator for the locally logged on user on windows clients

    $wql = "Select * from Win32_Process Where Name = 'explorer.exe'"

    foreach ($computername in $computernames) 
    {     
        $user = Invoke-CimMethod -Query $wql -MethodName 'getowner' -ComputerName $computername -ErrorAction SilentlyContinue    

        if ($user) 
        {     
           "$computername : " + $user.domain + '\' + $user.user 
        }
        else {
           "$computername : (nobody)"
        }
     }

#endregion

