function ExportLs($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "LsExport.xml")
    $ls_list = @()
    if ($tmp.Objs.Obj.DCT) {
        $tmp.Objs.Obj.DCT.En | %{
            [xml]$ls = $_.S[1].'#text'
            $backing = $ls.virtualWire.vdsContextWithBacking | %{
                [PSCustomObject]@{
                    name = $_.switch.name
                    backing = $_.backingValue
                    mtu = $_.mtu
                }
            }
            $ls_list += [PSCustomObject]@{
                id = $ls.virtualWire.objectId
                name = $ls.virtualWire.name
                description = $ls.virtualWire.description
                vds_name = $backing.name -Join "`n"
                pg_name = $backing.backing -Join "`n"
                mtu = $backing.mtu -Join "`n"
            }
        }
    }
    $ls_list | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "ls.csv")
}
