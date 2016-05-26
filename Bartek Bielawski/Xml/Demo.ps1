#region Basics...

# implicit foreach on Adapted Type System object.
$xml = [xml]@'
<node attribute="attributeValue">
    <CaseSensitive>First</CaseSensitive>
    <caseSensitive>second</caseSensitive>
</node>
'@
$PSDefaultParameterValues.'Select-Xml:Xml' = $xml

$xml.node.casesensitive
$xml.node 

$xml | Format-Custom

$xml.node.CaseSensitive | Where-Object {
    $_ -match 'sec'
}
#endregion

#region Select-Xml - raw XML

Select-Xml -XPath /
Select-Xml -XPath /node | ForEach-Object {
    $_.Node
}

Select-Xml -XPath /node/*
Select-Xml -XPath /node/@attribute
# it is case-sensitivie...
Select-Xml -XPath /node/casesensitive
Select-Xml -XPath /node/caseSensitive
Select-Xml -XPath "//*[@attribute = 'attributeValue']" | % Node
Select-Xml -XPath "//*[contains(text(),'sec')]" | % Node
Select-Xml -XPath "//node[translate(@attribute,'V','v') = 'attributevalue']" | % Node

#endregion

#region Select-Xml - namespaces

$xmlNamespaces = [xml](Get-Content -Path 'C:\Program Files\WindowsPowerShell\Modules\OptiverFunctions\1.1.7.0\PSGetModuleInfo.xml')
$PSDefaultParameterValues.'Select-Xml:Xml' = $xmlNamespaces

Select-Xml -XPath //Version


Select-Xml -XPath //def:Version -Namespace @{
    def = 'http://schemas.microsoft.com/powershell/2004/04'
} | ForEach-Object Node

# what namespaces does document have...?
$document = New-Object System.Xml.XPath.XPathDocument (
    New-Object System.IO.StringReader $xmlNamespaces.OuterXml
)
$namespaces = @{}
$navigator = $document.CreateNavigator()
while ($navigator.MoveToFollowing('Element')) {
    $local = $navigator.GetNamespacesInScope('Local')
    foreach ($key in $local.Keys) {
        $value = $local[$key]
        if (-not $key) {
            $key = 'domyślna'
        }
        $namespaces[$key] = $value
    }
}

$namespaces


#endregion

#region Real life examples

#region example 1 - workflow definitions

$PSDefaultParameterValues.Remove('Select-Xml:Xml')

$wf = @{
    Name = 'Workflow'
    Expression = {
        $_.ParentNode.wfname
    }
}

$outputKey = @{
    Name = 'OutputVariable'
    Expression = {
        Select-Xml -Xml $_ -XPath "*/property[@name = 'OutputVariable']" |
            ForEach-Object { $_.Node.'#cdata-section' }
    }
}

$outputVar = @{
    Name = 'OutputKey'
    Expression = {
        Select-Xml -Xml $_ -XPath "*/property[@name = 'OutputKey']" |
            ForEach-Object { $_.Node.'#cdata-section' }
    }
}


(Select-Xml -Path $Pwd\WorkflowExport.xml -XPath "//action[contains(@type,'HPSM Create C')]").Node | 
    Select-Object name, type, $wf, $outputKey, $outputVar | ft

#endregion

#region Example 2 - WPF and Names.
Add-Type -AssemblyName PresentationFramework
Add-Type -Path D:\PowerShell\Microsoft.Expression.Drawing.dll

$read = [System.Xml.XmlReader]::Create("$Pwd\xaml.xml")
$xaml = [System.Windows.Markup.XAMLReader]::Load($read)

$controls = @{}
Select-Xml -Path $Pwd\xaml.xml -XPath //*/@x:Name -Namespace @{
    x = 'http://schemas.microsoft.com/winfx/2006/xaml'
} | ForEach-Object {
    $name = $_.Node.Value
    $controls[$name] = $xaml.FindName($name)
}

$controls.Keys

#endregion

#region Example 3 - Parsing event log
Get-WinEvent -FilterXPath "*[System[Level = 2 and EventID = 1001 and TimeCreated[@SystemTime >= '2016-04-20T01:00:00.0000Z']]]" -ProviderName Microsoft-Windows-Dhcp-Client

#endregion

#endregion

#region XsltTransforms
function Set-Configuration {
    param (
        [String]$Source,
        [String]$Config,
        [String]$Template, 
        [hashtable]$Parameters
    )

    # Resolve paths...
    Write-Verbose "Converting paths ($Config, $Source and $Template) - just in case"
    $inPath = (Resolve-Path -LiteralPath $Source).ProviderPath
    $xslPath = (Resolve-Path -LiteralPath $Template).ProviderPath

    try {
        Write-Verbose 'Creating temporary file to store configuration'
        $tempFile = [IO.Path]::GetTempFileName()
    } catch {
        throw "Failed to create temporary file - $_"
    }

    try {
        Write-Verbose "Creating Transform object and arguments collection $($Parameters.Keys -join ', ')"
        $xslt = New-Object System.Xml.Xsl.XslCompiledTransform $true
        $argumentList = new-object System.Xml.Xsl.XsltArgumentList
        foreach ($param in $Parameters.Keys) {
            $argumentList.AddParam(
                $param, 
                '', 
                $Parameters.$param
            )
        }
    } catch {
        throw "Failed to create Transofrm object and/or argument list - $_"
    }

    try {
        Write-Verbose "Loading XSLT document from $xslPath"
        $xslt.Load($xslPath)
    } catch {
        throw "Failed to load XSLT from $xslPath - $_"
    }
    
    try {
        Write-Verbose "Creatinig FileStream object ($tempFile)"
        $out = New-Object System.IO.FileStream -ArgumentList @( 
            $tempFile, 
            [System.IO.FileMode]::Append, 
            [System.IO.FileAccess]::Write
        )
    } catch {
        throw "Failed to create FileStream object ($tempFile) - $_"
    }
    
    try {
        Write-Verbose "Performing configuration transform with file $Config and $xslPath"
        $xslt.Transform(
            $inPath, 
            $argumentList, 
            $out
        )
    } catch {
        throw "Failed to transform configuration ($Config) - $_"
    }
    
    try {
        Write-Verbose "Saving transformed file to temporary location ($tempFile)"
        $out.Close()
    } catch {
        throw "Failed to save transformed configuration to disk ($tempFile) - $_"
    }

    try {
        Move-Item -Path $tempFile -Destination $Config -Force -Confirm:$false -ErrorAction Stop
    } catch {
        throw "Failed to move $tempfile back to $Config - $_"
    }
}

#endregion

