function ExportGwfw($edge_list, $output_path){
    $gwfw_list = $edge_list | %{
        if ( ( $_.features.firewall.enabled -eq "true" ) -and ( ( $_.features.firewall.firewallRules.firewallRule | where ruleType -eq user ).length -gt 0 ) ){
            $_.features.firewall
        }
    }

    $t = $gwfw_list | %{
        $gwfw = $_
        $edge_name = $gwfw.ParentNode.ParentNode.name
        $gwfw.firewallRules.firewallRule | %{
            $rule = $_ | select edge, id, name, ruleType, enabled, source, source_exclude, destination, destination_exclude, application, action, loggingEnabled
            $rule.edge = $edge_name

            $source = @()
            if ( $rule.source ) {
                if ( $rule.source.ipAddress ) {
                    $rule.source.ipAddress | %{ $source += $_ -Join "`n" }
                }
                if ( $rule.source.vnicGroupId ) {
                    $rule.source.vnicGroupId | %{ $source += $_ -Join "`n" }
                }
                if ( $rule.source.groupingObjectId ) {
                    $rule.source.groupingObjectId | %{ $source += $_ -Join "`n" }
                }
                $rule.source_exclude = $rule.source.exclude
            }
            $rule.source = $source -Join "`n"

            $destination = @()
            if ( $rule.destination ) {
                if ( $rule.destination.ipAddress ) {
                    $rule.destination.ipAddress | %{ $destination += $_ -Join "`n" }
                }
                if ( $rule.destination.vnicGroupId ) {
                    $rule.destination.vnicGroupId | %{ $destination += $_ -Join "`n" }
                }
                if ( $rule.destination.groupingObjectId ) {
                    $rule.destination.groupingObjectId | %{ $destination += $_ -Join "`n" }
                }
                $rule.destination_exclude = $rule.destination.exclude
            }
            $rule.destination = $destination -Join "`n"

            $application = @()
            if ( $rule.application ) {
                if ( $rule.application.service ) {
                    $rule.application.service | %{ $application += "{0}({1})" -F $_.protocol, $_.port }
                }
                if ( $rule.application.applicationId ) {
                    $rule.application.applicationId | %{ $application += $_ }
                }
            }
            $rule.application = $application -Join "`n"

            $rule
        }
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "gwfw.csv")
}
