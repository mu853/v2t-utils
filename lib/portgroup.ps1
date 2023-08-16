function ExportPortgroup($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "StdPgExport.xml")
    $pg_list = @()
    $tmp.Objs.Obj.DCT.En | %{
        $pg_list += [PSCustomObject]@{
            name = $_.Obj.MS.S.'#text'
            vlanId = $_.Obj.MS.I32.'#text'
        }
    }

    [xml]$tmp = gc (Join-Path $path "VdPgExport.xml")
    $vdp_list = @()
    $tmp.Objs.Obj.DCT.En | %{
        $vdp_list += [PSCustomObject]@{
            moref = $_.Obj.MS.S[0].'#text'
            name = $_.Obj.MS.S[1].'#text'
            vlanId = $_.Obj.MS.I32.'#text'
        }
    }

    $vlan_pg_list = @()
    $vdp_list | %{
        $pg = $_
        if ( $pg.name -notlike "vxw-*" ) {
            $vlan_pg_list += [PSCustomObject]@{
                name = $pg.name
                type = "VDPortGroup"
                vlanId = $pg.vlanId
            }
        }
    }
    $pg_list | %{
        $pg = $_
        $vlan_pg_list += [PSCustomObject]@{
            name = $pg.name
            type = "Standard"
            vlanId = $pg.vlanId
        }
    }
    $vlan_pg_list | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "pg.csv")
}
