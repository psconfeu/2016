$number08 = {
  'CONSINSTENCY'  
}
 
# TRY CRTL J => SNIPPETS

1..10 | ForEach-Object `
{
  $_
}

#region LOOPING
    Remove-Variable -Name a,b,c,d -ErrorAction SilentlyContinue

    1..5 | ForEach-Object `
    {
     $_ 
    }
    

    foreach ($a in (1..5)) 
    {
        $a | Write-Host -ForegroundColor green
    }

    while ($b -lt 5)
    {
        $b++
        $b | Write-Host -ForegroundColor Yellow
    }

    do
    {
        $c++
        $c | Write-Host -ForegroundColor green
    }   
    while ($c -lt 5)

    for ($d = 1; $d -le 5; $d++)
    { 
        $d | Write-Host -ForegroundColor Yellow
    }
#endregion
