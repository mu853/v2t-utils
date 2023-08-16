function Dfw($path){
    [xml]$tmp = gc (Join-Path $path "DfwConfigExport.xml")
    $dfw = $tmp.firewallConfiguration.layer3Sections.section
    return $dfw
}

function ExportDfw($path, $output_path){
    [xml]$tmp = gc (Join-Path $path "DfwConfigExport.xml")
    $dfw = $tmp.firewallConfiguration.layer3Sections.section
 
    $sec_i = 1
    $t = $dfw | %{
        $sec = $_

        $rule_i = 1
        $sec.rule | %{
            $rule = $_
            
            $source = ""
            $destination = ""
            $service = ""
            $appliedTo = ""

            if($rule.sources.source){
                $source = ($rule.sources.source | %{
                    "{0}({1}:{2})" -F $_.name, $_.value, $_.type
                }) -Join "`n"
            }
            if($rule.destinations.destination){
                $destination = ($rule.destinations.destination | %{
                    "{0}({1}:{2})" -F $_.name, $_.value, $_.type
                }) -Join "`n"
            }
            if($rule.services.service){
                $service = ($rule.services.service | %{
                    "{0}({1}:{2})" -F $_.name, $_.value, $_.type
                }) -Join "`n"
            }
            if($rule.appliedToList.appliedTo){
                $appliedTo = ($rule.appliedToList.appliedTo | %{
                    "{0}({1}:{2})" -F $_.name, $_.value, $_.type
                }) -Join "`n"
            }

            [PSCustomObject]@{
                section_name = $sec.name
                section_id = $sec.id
                section_seq = $sec_i
                tcpStrict = $sec.tcpStrict
                stateless = $sec.stateless
                rule_name = $rule.name
                rule_id = $rule.id
                rule_seq = $rule_i
                disabled = $rule.disabled
                source = $source
                destination = $destination
                service = $service
                appliedTo = $appliedTo
                direction = $rule.direction
                action = $rule.action
                logged = $rule.logged
            }
            $rule_i += 1
        }
        $sec_i += 1
    }
    $t | Export-Csv -Encoding $global:encoding -NoTypeInformation -Path (Join-Path $output_path "dfw.csv")
}

function GetDFWRulePattern ($dfw) {
    $obj = @{
        "Source" = @{}
        "Destination" = @{}
        "AppliedTo" = @{}
        "Service" = @{}
    }

    $dfw.rule | %{
        $_.sources.source | Group-Object -Property type | %{
            $obj.Source[$_.Name] += 1
        }
    }
    $dfw.rule | %{
        $_.destinations.destination | Group-Object -Property type | %{
            $obj.Destination[$_.Name] += 1
        }
    }
    $dfw.rule | %{
        $_.appliedToList.appliedTo | Group-Object -Property type | %{
            $obj.AppliedTo[$_.Name] += 1
        }
    }
    $dfw.rule | %{
        $_.services.service | Group-Object -Property type | %{
            $obj.Service[$_.Name] += 1
        }
    }

    $obj.Keys | %{
        $k = $_
        $v = $obj[$k]
        $v.Keys | %{
            $k2 = $_
            $v2 = $v[$k2]
            [PSCustomObject]@{
                "Column" = $k
                ObjectType = $k2
                Count = $v2
            }
        }
    }
}
