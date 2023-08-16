function ExportServiceList($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "ServicesExport.xml")
    $srv_list = $tmp.Objs.obj.DCT.En | %{
        [xml]$srv = $_.S[1].'#text'
        $srv.application
    } | sort-object -property objectId
    $srv_list | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "srv.csv")

    function GetServiceObject () {
        param (
            $srv_list,
            $objectId
        )
        $srv_list | %{
            $app = $_
            if ( $app.objectId -eq $objectId ) {
                return $app
            }
        }
    }
}
