function ExportLb($edge_list, $output_path){
    $lb_list = $edge_list | %{
        if ( ( $_.features.loadBalancer.enabled -eq "true" ) -and ( $_.features.loadBalancer.virtualServer ) ){
            $_.features.loadBalancer
        }
    }

    $t = $lb_list | %{
        $lb = $_
        $pools = $lb.pool
        $apps = $lb.applicationProfile
        $monitors = $lb.monitor
        $rules = $lb.applicationRule
        $lb.virtualServer | %{
            $vip = $_
            $app = ( $apps | where applicationProfileId -eq $vip.applicationProfileId )
            $pool = ( $pools | where poolId -eq $vip.defaultPoolId )
            $rule = ( $rules | where applicationRuleId -in $vip.applicationRuleId )
            $monitor = ( $monitors | where monitorId -eq $pool.monitorId )
            $obj = [PSCustomObject]@{
                edge = $lb.ParentNode.ParentNode.name
                name = $vip.name
                enabled = $vip.enabled
                vip_ip = $vip.ipAddress
                vip_protocol = $vip.protocol
                vip_port = $vip.port
                vip_conn_limit = $vip.connectionLimit
                vip_acceleration = $vip.accelerationEnabled
                app_name = $app.name
                app_xff = $app.insertXForwardedFor
                app_sslpassthrough = $app.sslPassthrough
                app_template = $app.template
                app_serverssl = $app.serverSslEnabled
                pool_name = $pool.name
                pool_algorithm = $pool.algorithm
                pool_transparent = $pool.transparent
                monitor_name = $monitor.name
                monitor_type = $monitor.type
                monitor_interval = $monitor.interval
                monitor_maxretries = $monitor.maxRetries
                monitor_timeout = $monitor.timeout
                pool_members = $pool.member.length
                member_name = ""
                member_ip = ""
                member_port = ""
                member_m_port = ""
                member_weight = ""
                member_minconn = ""
                member_maxconn = ""
                member_condition = ""
                rule_name = ""
                rule_script = ""
            }
            $i = 0
            $j = 0
            while ( ( $i -lt $rule.length ) -or ( $j -lt $pool.member.length ) ) {
                $obj2 = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($obj))
                if ( $i -lt $rule.length ) {
                    $tmp_r = $rule
                    if ( $rule -is [array] ) {
                        $tmp_r = $rule[$i]
                    }
                    $obj2.rule_name = $tmp_r.name
                    $obj2.rule_script = $tmp_r.script -replace "_x000A_", "`n"
                    $obj2
                    $i++
                }
                if ( $j -lt $pool.member.length ) {
                    $tmp_m = $pool.member
                    if ( $pool.member -is [array] ) {
                        $tmp_m = $pool.member[$j]
                    }
                    $obj2.member_name = $tmp_m.name
                    $obj2.member_ip = $tmp_m.ipAddress
                    $obj2.member_port = $tmp_m.port
                    $obj2.member_m_port = $tmp_m.monitorPort
                    $obj2.member_weight = $tmp_m.weight
                    $obj2.member_minconn = $tmp_m.minConn
                    $obj2.member_maxconn = $tmp_m.maxConn
                    $obj2.member_condition = $tmp_m.condition
                    $obj2
                    $j++
                }
            }
        }
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "lb.csv")
}
