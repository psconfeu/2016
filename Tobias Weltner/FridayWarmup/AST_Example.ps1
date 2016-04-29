

$code = 
{
  $a = 1
  $b = 100
  $c = $a * $b
  $c
}

$code.Ast.FindAll( { $true }, $true) | Foreach-Object { $_.GetType().FullName }

$code.Ast.FindAll( { param($willi) $willi.GetType().Name -eq 'AssignmentStatementAst' }, $true) |
  Out-GridView
  
$code.Ast.FindAll( { param($willi) $willi.GetType().Name -eq 
    'AssignmentStatementAst' -and $willi.Operator -eq 
    'Equals' }, $true) |
  Select-Object -ExpandProperty Left | 
  Select-Object -ExpandProperty VariablePath | 
  Select-Object -ExpandProperty UserPath |
  Sort-Object -Unique
  
$code.Ast.FindAll( { param($willi) $willi.GetType().Name -eq 
    'AssignmentStatementAst' -and $willi.Operator -eq 
    'Equals' }, $true).Left.VariablePath.UserPath |
  Sort-Object -Unique


$path = 'C:\Users\tobwe\Documents\willi.ps1'

$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
$ast.FindAll( { param($willi) $willi.GetType().Name -eq 
    'AssignmentStatementAst' -and $willi.Operator -eq 
    'Equals' }, $true).Left.VariablePath.UserPath |
  Sort-Object -Unique
