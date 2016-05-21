<#
    # A very simple demo using Lucene from PowerShell V5 to index
    # and search eventlog events.
 #>
 # Load the Lucene assembly...
using assembly Lucene.Net\Lucene.Net.dll

# And the namespaces to use...
using namespace System.IO
using namespace Lucene.Net.Analysis
using namespace Lucene.Net.Analysis.Standard
using namespace Lucene.Net.Documents
using namespace Lucene.Net.Index
using namespace Lucene.Net.QueryParsers
using namespace Lucene.Net.Store
using namespace Lucene.Net.Util
using namespace Lucene.Net.Search

param (
    [switch] $RebuildEventLogDataCache
)

# If a disk index is used, it will be placed in this directory
$INDEX_DIRECTORY='c:\temp\'

# Eventlog text files will be generated here
$EVENTLOG_TEXT_DIR = 'c:\temp\eventlogtext'
# Create the directory if it doesn't exist
# If the parent directories don't exist
# you'll have to create them by hand. Sorry.
if (-not [IO.Directory]::Exists($EVENTLOG_TEXT_DIR))
{
    mkdir -ea Stop $EVENTLOG_TEXT_DIR > $null
    $RebuildEventLogDataCache = $true
}

if ($RebuildEventLogDataCache)
{
    Write-Host -ForegroundColor green 'Rebuilding event log data cache.'
    $logToProcess = "system"
    Write-Host -ForegroundColor green 'Reading $logToProcess eventlog...'
    $events = Get-EventLog -LogName $logToProcess
    Write-Host -ForegroundColor green 'Retrieved $($events.Length) events...'
    $totalEvents = $events.Length
    $count = 0;
    Write-Host -ForegroundColor green 'Writing event files...'
    foreach ($event in $events)
    {
        $event | Format-List * | Out-String > "$EVENTLOG_TEXT_DIR\$($event.Index).txt"
        $count++;
        if ($count % 100 -eq 0)
        {
            #cls
            Write-Host -ForegroundColor green "Wrote $count records out of $totalEvents..." 
        }
    }
    #cls
    Write-Host -ForegroundColor green "Wrote a total of $count log record files."
}

#
# Choose what type of index you want to use true==in-memory false==on-disk
#
if ($false)
{			
    # Store a transient index in memory only.
    $directory = [RAMDirectory]::new();
}
else
{
    # Store a persistent index on disk but first 
    $directory = [FSDirectory]::Open("$INDEX_DIRECTORY\eventlogindex");
}

#
# Use the standard built-in full text analyzer
#
$analyzer = [StandardAnalyzer]::new("LUCENE_CURRENT");

# Now create the index writer object using the analyzer and index store we've chosen
$indexWriter   = [IndexWriter]::new($directory, $analyzer, $true,
    [Lucene.Net.Index.IndexWriter+MaxFieldLength]::new(250000))
	
#
# Ingest the pre-rendered eventlog entries into the index
#
Write-Host -ForegroundColor green 'Starting to ingest log event files.'
$start     = [datetime]::Now
$count     = 0
$totalSize = 0
foreach ($file in [IO.Directory]::EnumerateFiles($EVENTLOG_TEXT_DIR, "*.txt"))
{
    $doc = [Document]::new()
    $text = [IO.File]::ReadAllText($file)
    $doc.Add([Field]::new('fulltext', $text, 'YES', 'ANALYZED'))
    $indexWriter.AddDocument($doc);
    $count++
    $totalSize += [FileInfo]::new($file).Length
}
$indexWriter.Close();
Write-Host -ForegroundColor green "Indexed $count files in $(([datetime]::now - $start).TotalSeconds)"
Write-Host -ForegroundColor green "Total size of indexed documents: $($totalSize/1mb) MB"

#			
# Now set up to query the database
#
$isearcher = [IndexSearcher]::new($directory, $true); # read-only=true
$parser    = [QueryParser]::new('LUCENE_CURRENT', 'fulltext', $analyzer);
Write-Host -ForegroundColor green @"

You can now query the generated index using the Lucene query
language. Results will vary depending on log contents.

"@


while (1)
{
    # Parse a simple query...
    $queryString = Read-Host -Prompt @"
Enter search query; some example queries are:'
    kernel                        # single word search
    "Hyper-V"                     # quoted word search
    "device driver"               # multi-word phrase search
    "entrytype error" domain      # OR search (default for two phrases)
    "entrytype error" OR domain   # OR search with explicit operator
    "entrytype error" AND domain  # AND search
    power AND firmware
    error+ domain                 # Must contain "error", may contain domain
    kernel NOT "cannot be found"  # must contain kernal but not "cannot be found"
    power NOT firmware
QUERY (or q to quit) 
"@
    if ($queryString -eq "q")
    {
        break
    }
    # Ignore empty lines
    if (! $queryString) { continue }

    $query = $parser.Parse($queryString)
   
    Write-Host -ForegroundColor green "Starting search......................................"
    $searchDuration = Measure-Command {
        $script:hits = $isearcher.Search($query, $null, 1000).ScoreDocs;
    }
    Write-Host -ForegroundColor green "Search complete......................................"
    # Iterate through the results:
    for ($i = 0; $i -lt $hits.Length; $i++)
    {
        "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
        $hitDoc = $isearcher.Doc($hits[$i].Doc);
        $resText = $hitDoc.Get("fulltext")
        $maxText = 1024
        if ($restext.Length -lt $maxText)
        {
            $maxText = $restext.Length
        }
        $resText = $resText.Substring(0, $maxText)
        "$resText`n`n"
    }
    Write-Host -ForegroundColor green "Got $($hits.length) hits!, search took $($searchDuration.TotalMilliseconds)ms`n`n"
}
$isearcher.Close();
$directory.Close();

