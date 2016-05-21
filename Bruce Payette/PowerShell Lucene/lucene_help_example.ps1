<#
    # A very simple demo showing hot how to use Lucene from PowerShell V5.0
    #
    # This example indexes all of the PowerShell help files and
    # then allows you to interactively query them.
    #
    # NOTE: For this example, the MAML based help files must be pre-rendered to
    # text before indexing them. This is done using the "genhelpfiles.ps1" script.
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

# If a disk index is used, it will be placed in this directory
$INDEX_DIRECTORY="c:\temp\"

# This is where we'll look for the generated help files. This
# value must match the value in "genhelpfile.ps1"
$HELPFILE_DIR = "c:\temp\helpfiles"

cls

#
# Create the document analyzer we're going to use
$analyzer = [StandardAnalyzer]::new("LUCENE_CURRENT");

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
    # remove the old index for to ilustrate indexing performance
    rm  "c:\temp\testindex\*"
    $directory = [FSDirectory]::Open("$INDEX_DIRECTORY\helpindex");
}

# Now create the index writer object using the analyzer and index store we've chosen
$indexWriter   = [IndexWriter]::new($directory, $analyzer, $true, [Lucene.Net.Index.IndexWriter+MaxFieldLength]::new(25000))

#
# Start with ingesting all of the about_*.txt files.
#
$start = [DateTime]::Now
$count = 0
$totalSize = 0
Write-Host -ForegroundColor green 'Injesting about_ files in $PSHOME'
foreach ($file in [IO.Directory]::EnumerateFiles("$PSHOME\en-us", "*.txt"))
{
    $doc = [Document]::new();
    $text = [File]::ReadAllText($file)
    $doc.Add([Field]::new('fulltext', $text, 'YES', 'ANALYZED'))
    $indexWriter.AddDocument($doc);
    $count++
    $totalSize += [FileInfo]::new($file).Length
}
Write-Host -ForegroundColor green "Completed in $(([DateTime]::now - $start).TotalSeconds) seconds"

Write-Host -ForegroundColor green 'Ingest rendered MAML files'
foreach ($fn in [IO.Directory]::EnumerateFiles($HELPFILE_DIR, "*.txt"))
{
    $doc = [Document]::new();
    $text = [File]::ReadAllText($file)
    $doc.Add([Field]::new("fulltext", $text, "YES", "ANALYZED"))
    $indexWriter.AddDocument($doc);
    $count++
    $totalSize += [FileInfo]::new($file).Length
}
$indexWriter.Close();
Write-Host -ForegroundColor green "Indexed $count total files in $(([datetime]::now - $start).TotalSeconds) seconds"
Write-Host -ForegroundColor green "Total size of indexed documents: $($totalSize/1mb) MB"
	
# Now search the index:
$isearcher = [IndexSearcher]::new($directory, $true); # read-only=true
$parser =    [QueryParser]::new("LUCENE_CURRENT", "fulltext", $analyzer)
Write-Host -ForegroundColor green @"

You can now query the generated index using the Lucene query language."
Example queries:'
    about_operators             # single word search
    "Language Mode"             # multi-word search
    "restricted language"
    "about_operators -split"
    "about_operators -split"~4  # proximity within 4 words

"@
while (1)
{
    # Parse a simple query...
    $queryString = Read-Host -Prompt "Enter search query (or q to quit)"
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
        if ($resText.length -gt 120)
        {
            $resText = $resText.Substring(0, 500)
        }
        "$resText`n`n"
    }
    Write-Host -ForegroundColor green "Got $($hits.length) hits!, search took $($searchDuration.TotalMilliseconds)ms`n`n"
}
$isearcher.Close();
$directory.Close();

