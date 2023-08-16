param(
    [string]$env_list_file = "env.csv",
    [string]$env = "all",
    [string]$input_base = ".",
    [string]$output_base = "~/Desktop",
    [string]$encoding = "shift_jis"
)

function Create-CsvFromXML() {
    param(
        $env,
        $path,
        $output_path
    )

    "Processing {0} ..." -F $env | Write-Host -ForegroundColor Cyan -NoNewLine
    if (! (Test-Path $output_path)) {
        mkdir $output_path
    }

    $edge_list = EdgeList($path)
    ExportEdgeList $edge_list $output_path
    ExportOspf $edge_list $output_path
    ExportLb $edge_list $output_path
    ExportGwfw $edge_list $output_path
    ExportNat $edge_list $output_path
    ExportDhcp $edge_list $output_path

    ExportPortgroup $path $output_path
    ExportLs $path $output_path

    ExportDfw $path $output_path
    ExportIpSet $path $output_path
    ExportSecurityGroup $path $output_path
    ExportServiceList $path $output_path

    ExportVmList $path $output_path

    "Done" | Write-Host -ForegroundColor Green
}

if (! (Test-Path $input_base)) {
    "Input path {0} not found" -F $input_base
    return
}
if (! (Test-Path $output_base)) {
    "Output path {0} not found" -F $output_base
    return
}

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
Get-ChildItem $scriptPath/lib/*.ps1 | %{
    . $_.FullName
}

$global:encoding = $encoding

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
    Create-CsvFromXML -env $_.env -path $path -output_path (Join-Path $output_base $_.env)
}
