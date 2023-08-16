function ExportIpSet($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "IpSetExport.xml")
    $ipset_list = $tmp.Objs.obj.DCT.En | %{
        [xml]$ipset = $_.S[1].'#text'
        $ipset.ipset
    } | sort-object -property objectId
    $ipset_list | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "ipset.csv")
}
