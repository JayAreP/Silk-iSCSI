function Disconnect-SilkCNode {
    param(
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP
    )


    $portal = Get-IscsiTargetPortal | Where-Object {$_.TargetPortalAddress -eq $cnodeIP.IPAddressToString}

    if ($portal) {
        $v = "Portal on IP " + $cnodeIP.IPAddressToString + " discovered, removing portal from the configuration."
        $v | Write-Verbose
        Remove-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -InitiatorInstanceName $portal.InitiatorInstanceName -InitiatorPortalAddress $portal.InitiatorPortalAddress -Confirm:0 | Out-Null
        Get-IscsiTarget | Update-IscsiTarget | Out-Null
        Get-IscsiTargetPortal | Update-IscsiTargetPortal | Out-Null
        Update-MPIOClaimedHW -Confirm:0 | Out-Null 
    }

    # Removes persistence for those now-undiscovered sessions 

    $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}

    if ($allConnections) {
        $killSessions =  $allConnections | Get-IscsiSession | Where-Object {$_.IsDiscovered -eq 0}  # ensure unique sessions for the desired portal

        if ($killSessions) {
            $v = "Discovered " + $killSessions.count + " iscsi sessions to remove."
            $v | Write-Verbose
    
            foreach ($k in $killSessions) {
                $v = "Removing session " + $k.SessionIdentifier + " from the session list."
                $v | Write-Verbose
                $k | Remove-SilkFavoriteTarget -ErrorAction SilentlyContinue | Out-Null
                Disconnect-IscsiTarget -SessionIdentifier $k.SessionIdentifier -Confirm:0 -ErrorAction SilentlyContinue 
                Unregister-IscsiSession -SessionIdentifier $k.SessionIdentifier -ErrorAction SilentlyContinue 
            }
        }
        
        Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
    }

    

    # Now, add the desired number of sessions back in...
    $return = Get-SilkSessions
    return $return

} 