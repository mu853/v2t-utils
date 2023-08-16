param(
    [string]$env_list_file = "env.csv",
    [string]$env = "all",
    [string]$input_base = "."
)

if (! (Test-Path $input_base)) {
    "Input path {0} not found" -F $input_base
    return
}

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
. $scriptPath/lib/dfw.ps1

if(! $env_list_file.StartsWith("/")){
    $env_list_file = Join-Path $scriptPath $env_list_file
}
$env_list = Import-Csv $env_list_file
if($env -ne "all"){
    $env_list = $env_list | where env -eq $env
}
$env_list | %{
    $path = $_.path
    if(! $path.StartsWith("/")){
        $path = Join-Path $input_base $path
    }
    $_.env | Write-Host -ForegroundColor Cyan
    GetDFWRulePattern (Dfw $path) | ft * -AutoSize
}
