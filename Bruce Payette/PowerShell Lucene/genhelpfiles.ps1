#
# Utility to render all MAML cmdlet help to simple text files in a 
# single directory. Depending on how your machine is configured this can
# take a while to run.
#

#
# Location where the text files will be created. This must match the 
# corresponding variable in lucene_help_example.ps1
#
$HELPFILE_DIR = "c:\temp\helpfiles"

$allcmds = Get-Command -type cmdlet
$numCommands = $allcmds.Length
$count=0
foreach ($cmd in $allcmds)
{
    $n = $cmd.Name

    cls

    Get-Help -full $n | Out-String > "$HELPFILE_DIR\$n.txt"
    if ($count % 100 -eq 0)
    {
        Write-Host -ForegroundColor green "Processing topic $n ($((++$count)) of $numCommands)..."
    }
}
cls
Write-Host -ForegroundColor green "Generation Complete, processed $count files."


