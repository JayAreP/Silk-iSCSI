function Disconnect-SilkCNode {
    param(
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [switch] $noUpdate,
        [Parameter()]
        [switch] $force,
        [Parameter()]
        [switch] $rebalance
    )

    # information gathering
    $total = Get-SilkSessions -totalOnly

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
                $sid = $k.SessionIdentifier
                Write-Verbose "Removing session $sid from the session list."
                # catch errors removing silk target
                if ($force) {
                    Write-Verbose "Removing session $sid from WMI."
                    $k | Remove-SilkFavoriteTarget -ErrorAction SilentlyContinue | Out-Null
                }
                
                Write-Verbose "--> Unregister-IscsiSession -SessionIdentifier $sid"
                Unregister-IscsiSession -SessionIdentifier $sid -ErrorAction SilentlyContinue 
                
                Write-Verbose "--> Disconnect-IscsiTarget -SessionIdentifier $sid -Confirm:0"
                Disconnect-IscsiTarget -SessionIdentifier $sid -Confirm:0 -ErrorAction SilentlyContinue 
                
            }
        }
        
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Write-Verbose "--> Update-MPIOClaimedHW -Confirm:0"
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
        
    }

    if ($portal) {
        $v = "Portal on IP " + $cnodeIP.IPAddressToString + " discovered, removing portal from the configuration."
        $v | Write-Verbose
        $cmd = "--> Remove-IscsiTargetPortal -TargetPortalAddress " + $cnodeIP.IPAddressToString + " -InitiatorInstanceName " + $portal.InitiatorInstanceName + " -InitiatorPortalAddress " + $portal.InitiatorPortalAddress + " -Confirm:0"
        $cmd | Write-Verbose
        Remove-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -InitiatorInstanceName $portal.InitiatorInstanceName -InitiatorPortalAddress $portal.InitiatorPortalAddress -Confirm:0 | Out-Null

        $cmd = "--> Get-IscsiTarget | Update-IscsiTarget"
        $cmd | Write-Verbose
        Get-IscsiTarget | Update-IscsiTarget -ErrorAction SilentlyContinue | Out-Null

        $cmd = "--> Get-IscsiTargetPortal | Update-IscsiTargetPortal"
        $cmd | Write-Verbose
        Get-IscsiTargetPortal | Update-IscsiTargetPortal -ErrorAction SilentlyContinue | Out-Null
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Write-Verbose "--> Update-MPIOClaimedHW -Confirm:0"
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
    }

    <#
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
                
                $cmd = "--> Unregister-IscsiSession -SessionIdentifier " + $k.SessionIdentifier 
                $cmd | Write-Verbose
                Unregister-IscsiSession -SessionIdentifier $k.SessionIdentifier -ErrorAction SilentlyContinue 

                $cmd = "--> Unregister-IscsiSession -SessionIdentifier " + $k.SessionIdentifier 
                $cmd | Write-Verbose
                Unregister-IscsiSession -SessionIdentifier $k.SessionIdentifier -ErrorAction SilentlyContinue 

                $cmd = "--> Disconnect-IscsiTarget -SessionIdentifier " + $k.SessionIdentifier + " -Confirm:0"
                $cmd | Write-Verbose
                Disconnect-IscsiTarget -SessionIdentifier $k.SessionIdentifier -Confirm:0 -ErrorAction SilentlyContinue 
                
            }
        }
        
        if (!$noUpdate) {
            $v = "Updating MPIO claim."
            $v | Write-Verbose
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
        }
        
    }
    #>
    $return = Get-SilkSessions

    if ($rebalance) {
        $sessions = $total.'Configured Sessions'
        $cnodes = $total.CNodes
        $cnodes--
        $sessionsPer = Get-SilkSessionsPer -nodes $cnodes -sessions $sessions
        Set-SilkSessionBalance -sessionsPer $sessionsPer
        $return = Get-SilkSessions
    }

    return $return | Format-Table

} 