function Disconnect-SilkCNode {
    param(
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [switch] $noUpdate,
        [Parameter()]
        [switch] $force
    )

    # Try clearing the portal LAST...
    $portal = Get-IscsiTargetPortal | Where-Object {$_.TargetPortalAddress -eq $cnodeIP.IPAddressToString}

    # Removes persistence for those now-undiscovered sessions 

    $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}

    # Chnage this to a while loop, and put a counter threshold on to run through it perhaps 3 times in case the connections remain after the MPIO claim
    if ($allConnections) {
        $killSessions =  $allConnections | Get-IscsiSession  # ensure unique sessions for the desired portal

        if ($killSessions) {
            $v = "Discovered " + $killSessions.count + " iscsi sessions to remove."
            $v | Write-Verbose
    
            foreach ($k in $killSessions) {
                $v = "Removing session " + $k.SessionIdentifier + " from the session list."
                $v | Write-Verbose
                # catch errors removing silk target
                if ($force) {
                    $v = "Removing session " + $k.SessionIdentifier + " from WMI."
                    $v | Write-Verbose
                    $k | Remove-SilkFavoriteTarget -ErrorAction SilentlyContinue | Out-Null
                }
                
                Unregister-IscsiSession -SessionIdentifier $k.SessionIdentifier -ErrorAction SilentlyContinue 
                Disconnect-IscsiTarget -SessionIdentifier $k.SessionIdentifier -Confirm:0 -ErrorAction SilentlyContinue 
                
            }
        }
        
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
        
    }

    if ($portal) {
        $v = "Portal on IP " + $cnodeIP.IPAddressToString + " discovered, removing portal from the configuration."
        $v | Write-Verbose
        Remove-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -InitiatorInstanceName $portal.InitiatorInstanceName -InitiatorPortalAddress $portal.InitiatorPortalAddress -Confirm:0 | Out-Null
        Get-IscsiTarget | Update-IscsiTarget -ErrorAction SilentlyContinue | Out-Null
        Get-IscsiTargetPortal | Update-IscsiTargetPortal -ErrorAction SilentlyContinue | Out-Null
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
    }

    
    $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}

    # Chnage this to a while loop, and put a counter threshold on to run through it perhaps 3 times in case the connections remain after the MPIO claim
    if ($allConnections) {
        $killSessions =  $allConnections | Get-IscsiSession | Where-Object {$_.IsDiscovered -eq 0}  # ensure unique sessions for the desired portal

        if ($killSessions) {
            $v = "Discovered " + $killSessions.count + " iscsi sessions to remove."
            $v | Write-Verbose
    
            foreach ($k in $killSessions) {
                $v = "Removing session " + $k.SessionIdentifier + " from the session list."
                $v | Write-Verbose
                # catch errors removing silk target
                if ($force) {
                    $v = "Removing session " + $k.SessionIdentifier + " from WMI."
                    $v | Write-Verbose
                    $k | Remove-SilkFavoriteTarget -ErrorAction SilentlyContinue | Out-Null
                }
                
                Unregister-IscsiSession -SessionIdentifier $k.SessionIdentifier -ErrorAction SilentlyContinue 
                Disconnect-IscsiTarget -SessionIdentifier $k.SessionIdentifier -Confirm:0 -ErrorAction SilentlyContinue 
                
            }
        }
        
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
        
    }

    # Now, add the desired number of sessions back in...
    $return = Get-SilkSessions
    return $return

} 