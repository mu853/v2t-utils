function EdgeList($path){
    $edge_list = @()

    [xml]$tmp = gc (Join-Path $path "EdgeExport.xml")
    $i = 0
    $tmp.Objs.Obj.DCT.En.S | %{
        if ( $i % 2 -eq 1 ) {
            [xml]$e = $_.'#text'
            $edge_list += $e.edge
        }
        $i++
    }

    [xml]$tmp = gc (Join-Path $path "LrExport.xml")
    $i = 0
    $tmp.Objs.Obj.DCT.En.S | %{
        if ( $i % 2 -eq 1 ) {
            [xml]$lr = $_.'#text'
            $edge_list += $lr.edge
        }
        $i++
    }

    return $edge_list
}

function ExportEdgeList($edge_list, $output_path){
    $t = $edge_list | %{
        $edge = $_
        $nat_rules = 0
        if ( $edge.features.nat.natRules.Length -gt 0 ){
            $nat_rules = ( $edge.features.nat.natRules.natRule | where ruleType -eq user ).length
        }

        $obj = [PSCustomObject]@{
            id = $edge.id
            name = $edge.name
            description = $edge.description
            type = $edge.type
            size = $edge.appliances.applianceSize
            datastore = ( $edge.appliances.appliance.datastoreName ) -Join ","
            resourcePoolName = $edge.appliances.appliance[0].resourcePoolName
            cpu_reserv = $edge.appliances.appliance[0].cpuReservation.reservation
            mem_reserv = $edge.appliances.appliance[0].memoryReservation.reservation
            ha = $edge.features.highAvailability.enabled
            ha_timer = $edge.features.highAvailability.declareDeadTime
            nat = $edge.features.nat.enabled
            nat_rules = $nat_rules
            gwfw = $edge.features.firewall.enabled
            gwfw_rules = ( $edge.features.firewall.firewallRules.firewallRule | where ruleType -eq user ).length
            gwfw_default_rule = $edge.features.firewall.defaultPolicy.action
            lb = $edge.features.loadBalancer.enabled
            ipsec = $edge.features.ipsec.enabled
            sslvpn = $edge.features.sslvpnConfig.enabled
            l2vpn = $edge.features.l2Vpn.enabled
            dhcp = $edge.features.dhcp.enabled
            dns = $edge.features.dns.enabled
            bridge = $edge.features.bridges.enabled
            ospf = $edge.features.routing.ospf.enabled
        }
        $nic_num = 1
        $edge.vnics.vnic | %{
            $vnic = $_
            $ip = ""
            if ( $vnic.addressGroups ) {
                $ip = "{0}/{1}" -F $vnic.addressGroups.addressGroup.primaryAddress, $vnic.addressGroups.addressGroup.subnetPrefixLength
            }
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_connected") -Value $vnic.isConnected
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_type") -Value $vnic.type
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_mtu") -Value $vnic.mtu
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_pg") -Value $vnic.portgroupName
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_pgid") -Value $vnic.portgroupId
            $obj | Add-Member -MemberType NoteProperty -Name ($vnic.label + "_ip") -Value $ip

            if ( $vnic.type -eq "trunk") {
                $vnic.subInterfaces.subInterface | %{
                    $subif = $_
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_name") -Value $subif.name
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_connected") -Value $subif.isConnected
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_tunnelid") -Value $subif.tunnelId
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_pgid") -Value $subif.logicalSwitchName
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_pg") -Value $subif.logicalSwitchId
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_mtu") -Value $subif.mtu
                    $obj | Add-Member -MemberType NoteProperty -Name ($subif.label + "_sendredirects") -Value $subif.enableSendRedirects
                    
                }
            }
            $nic_num++
        }
        $obj
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "edge.csv")
}
