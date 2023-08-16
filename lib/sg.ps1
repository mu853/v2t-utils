function ExportSecurityGroup($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "SecurityGroupExport.xml")
    $sg_list = $tmp.Objs.obj.DCT.En | %{
        [xml]$sg = $_.S[1].'#text'
        $sg.securitygroup
    }

    $t = $sg_list | %{
        $sg2 = $_
        $m = $sg2.member | Group-Object -Property objectTypeName
        $key = $sg2.dynamicMemberDefinition.dynamicSet.dynamicCriteria | Group-Object -Property key

        [PSCustomObject]@{
            name = $sg2.name
            description = $sg2.description
            objectId = $sg2.objectId
            dpg = ( $m | where name -eq DistributedVirtualPortgroup ).count
            ls = ( $m | where name -eq VirtualWire ).count
            ipset = ( $m | where name -eq IPSet ).count
            sg = ( $m | where name -eq SecurityGroup ).count
            vm = ( $m | where name -eq VirtualMachine ).count
            static_member = ( $sg2.member | %{ "{0}({1})" -F $_.name, $_.type.typeName } ) -join "`n"
            dynamic_member_key = $key.name -join "`n"
        }
    } | sort-object -property objectId
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "sg.csv")
}
