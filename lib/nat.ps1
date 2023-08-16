function ExportNat($edge_list, $output_path){
    $nat_list = $edge_list | %{
        if ( $_.features.nat.natRules ) {
            $_.features.nat
        }
    }
    $t = $nat_list | %{
        $edge_name = $_.ParentNode.ParentNode.name
        $_.natRules.natRule | %{
            $obj = $_ | select edge, ruleId, ruleTag, enabled, action, ruleType, protocol, originalAddress, originalPort, translatedAddress, translatedPort, snatMatchDestinationAddress, snatMatchDestinationPort, dnatMatchSourceAddress, dnatMatchSourcePort, vnic
            $obj.edge = $edge_name
            $obj
        }
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "nat.csv")
}
