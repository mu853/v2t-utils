Connect-NsxtServer XXXXXXXX -user admin -Password XXXXX

$api_group = Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.groups
$api_gwfw = Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.gateway_policies
$api_gwfwr = Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.gateway_policies.rules

## Create IPsets
# Read NSX-v data
$dir = “/Path/to/ObjectCapture”
[xml]$tmp = gc ( $dir + “/IpSetExport.xml” ) 

$ipset_list = $tmp.Objs.obj.DCT.En | %{
    [xml]$ipset = $_.S[1].‘#text’
    $ipset.ipset | select name, objectId, value
} | sort-object -property objectId

# Import to NSX-T
$ipset_list | %{
    $i = $_

    $new_e = $api_group.Help.patch.group.expression.Element.IP_address_expression.Create()
    $new_e.ip_addresses = $_.value –Split “,”

    $new_g = $api_group.Help.patch.group.Create()
    $new_g.display_name = $i.name
    $new_g.id = $new_g.display_name
    $new_g.expression.Add( $new_e )
    $api_group.patch( "default", $new_g.id, $new_g )
}

## Create Gateway FW Policies and Rules
# Read NSX-v data
[xml]$tmp = gc ( $dir + “/EdgeExport.xml” )
$edge_list = @()
$i = 0
$tmp.Objs.Obj.DCT.En.S | %{
    if ( $i % 2 -eq 1 ) {
        [xml]$e = $_.‘#text’
        $edge_list += $e.edge
    }
    $i++
}
$gwfw_list = $edge_list | %{
    if ( $_.features.firewall.enabled -eq "true" ){
        $_.features.firewall
    }
}

# Import to NSX-T (Tier-1 gateways are required in advance)
$gwfw_list | %{
    $gwfw = $_
    $edge_name = $gwfw.ParentNode.ParentNode.Name
    "edge_name = {0}" -F $edge_name

    # New Policy
    $new_policy = $api_gwfw.Help.patch.gateway_policy.Create()
    $new_policy.display_name = "Migrated Rules from NSX-v"
    $new_policy.id = $new_policy.display_name -replace “ ”, “_”

    # New Rules
    $gwfw.firewallRules.firewallRule | ?{ $_.ruleType -eq “user”} | %{
        $r = $_

        $new_rule = $api_gwfw.Help.patch.gateway_policy.rules.Element.Create()
        $new_rule.display_name = $r.name

        # source
        $src = $r.source
        if ( $src -isnot [array] ) {
            $src = @( $src )
        }
        $new_rule.source_groups = @()
        $src | %{
            $s = $_
            if ( $s.vnicGroupId ) {
                $new_rule.source_groups += GetIPsetOrIPAddress( $_ )
            } elseif ( $s.groupingObjectId ) {
                $new_rule.source_groups += "/infra/domains/default/groups/” + $s.groupingObjectId
            } else {
                $new_rule.source_groups += $s.ipAddress.ToUpper()
            }
        }

        # destination
        $new_rule.destination_groups = @( "ANY" )

        # service
        $new_rule.services = @( "ANY" )

        # applied to
        $new_rule.scope = @( “/infra/tier-1s/{0}” -F $edge_name )

        # action
        $new_rule.action = switch ( $r.action ) {
            "accept" { “ALLOW”; break; }
            "deny" { “DROP”; break; }
            default { “REJECT” }
        }

        # other
        $new_rule.logged = $r.loggingEnabled
        $new_policy.rules.Add( $new_rule ) | Out-Null
    }

    # Publish Policy
    $api_gwfw.patch( "default", $new_policy.id, $new_policy )
}

# Set Default Rule
$gwfw_list | %{
    $gwfw = $_
    $edge_name = $gwfw.ParentNode.ParentNode.Name
    "edge_name = {0}" -F $edge_name

    $policy = $api_gwfw.list( "default" ).results | where id -eq ( "Policy_Default_Infra-tier1-" + $edge_name )
    
    $default_rule = $api_gwfwr.list( "default", $policy.id ).results | where id -eq "default_rule"
    $default_rule.action = switch ( $gwfw.defaultPolicy.action ) {
        "accept" { “ALLOW”; break; }
        "deny" { “DROP”; break; }
        default { “REJECT” }
    }
    $default_rule.logged = $gwfw.defaultPolicy.loggingEnabled

    $api_gwfwr.update( "default", $policy.id, $default_rule.id, $default_rule )
}
