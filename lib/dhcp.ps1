function ExportDhcp($edge_list, $output_path){
    $dhcp_list = $edge_list | %{
        if ( $_.features.dhcp.enabled -eq "true" ) {
            $_.features.dhcp
        }
    }
    $t = $dhcp_list | %{
        $edge_name = $_.ParentNode.ParentNode.name
        $_.ipPools.ipPool | %{
            $obj = $_ | select edge, poolId, ipRange, defaultGateway, leaseTime, autoConfigureDNS, allowHugeRange
            $obj.edge = $edge_name
            $obj
        }
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "dhcp.csv")
}
