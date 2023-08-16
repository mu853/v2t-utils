function ExportOspf($edge_list, $output_path){
    $edge_list | %{
        $edge = $_
        if($edge.features.routing.ospf.enabled -eq "false"){
            return
        }
        $ospf = $edge.features.routing.ospf

        $area = ($ospf.ospfAreas.ospfArea | %{
            "area: {0}, type: {1}, auth: {2}" -F $_.areaId, $_.type, $_.authentication.type
        }) -Join "`n"

        $interface = ""
        if($ospf.ospfInterfaces){
            $interface = ($ospf.ospfInterfaces.ospfInterface | %{
                "vnic: {0}, areaId: {1}, hello: {2}, dead: {3}, priority: {4}, cost: {5}, mtuIgnore: {6}" -F $_.vnic, $_.areaId, $_.helloInterval, $_.deadInterval, $_.priority, $_.cost, $_.mtuIgnore
            }) -Join "`n"
        }

        $redistribution_rule = ""
        if($ospf.redistribution.enabled -eq "true"){
            $prefixlist = $edge.features.routing.routingGlobalConfig.ipPrefixes.ipPrefix
            $redistribution_rule = ($ospf.redistribution.rules.rule | %{
                $rule = $_
                $from = (@("ospf", "bgp", "static", "connected") | ?{
                    $rule.from.$_ -eq "true"
                }) -Join ":"
                $prefix = ($prefixlist | where name -eq $rule.prefixName).ipAddress
                "prefixName: {0}, prefix: {1}, from: {2}, action: {3}" -F $rule.prefixName, $prefix, $from, $rule.action
            }) -Join "`n"
        }

        [PSCustomObject]@{
            edge_name = $edge.name
            description = $edge.description
            edge_type = $edge.type
            ospfArea = $area
            ospfInterface = $interface
            redistribution = $ospf.redistribution.enabled
            redistribution_rule = $redistribution_rule
            gracefulRestart = $ospf.gracefulRestart
            defaultOriginate = $ospf.defaultOriginate
        }
    } | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "ospf.csv")
}
