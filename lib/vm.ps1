function ExportVmList($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "VmExport.xml" )
    $t = $tmp.Objs.Obj.DCT.En.Obj.MS | %{
        $vm = $_
        $type = "VM"
        if ( $vm.B[0].'#text' -eq "true" ) { $type = "NSX Manager" }
        if ( $vm.B[1].'#text' -eq "true" ) { $type = "NSX Edge" }
        if ( $vm.B[2].'#text' -eq "true" ) { $type = "NSX LogicalRouter" }
        if ( $vm.B[3].'#text' -eq "true" ) { $type = "NSX Controller" }
        $ips = ""
        $network = ""
        if ( $vm.Obj -is [array] ) {
            $ips = ( $vm.Obj[1].LST.S | Select-String -NotMatch fe80 | Select-String -NotMatch "^169.254" ) -Join ":"
            if($vm.Obj[0].LST){
                $network = $vm.Obj[0].LST.Obj.MS.S[0].'#text' -Join ":"
            }
        }
        [PSCustomObject]@{
            moref = $vm.S[0].'#text'
            name = $vm.S[1].'#text'
            network = $network
            ip = $ips
            type = $type
        }
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "vm.csv")
}
