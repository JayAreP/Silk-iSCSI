function Disconnect-SilkCNode {
    param(
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [switch] $force,
        [Parameter()]
        [switch] $rebalance
    )

    # information gathering
    $total = Get-SilkSessions -totalOnly

    # Try clearing the portal LAST...
    
    # Removes persistence for those now-undiscovered sessions 
    if ($force) {
        if ($rebalance) {
            $msg = "You cannot use -force with -rebalance. Please select one, and then the other."
            return $msg | Write-Error
        }
        Remove-SilkStaleSessions -cnodeIP $cnodeIP.IPAddressToString -force
    } else {
        $portal = Get-IscsiTargetPortal | Where-Object {$_.TargetPortalAddress -eq $cnodeIP.IPAddressToString}
        $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}
    }
    

    # Chnage this to a while loop, and put a counter threshold on to run through it perhaps 3 times in case the connections remain after the MPIO claim
    if ($allConnections) { 
        $killSessions =  $allConnections | Get-IscsiSession  # ensure unique sessions for the desired portal

        if ($killSessions) {
            $v = "Discovered " + $killSessions.count + " iscsi sessions to remove."
            $v | Write-Verbose
    
            foreach ($k in $killSessions) {
                $sid = $k.SessionIdentifier
                Write-Verbose "Removing session $sid from the session list."

                Write-Verbose "--> Unregister-IscsiSession -SessionIdentifier $sid"
                Unregister-IscsiSession -SessionIdentifier $sid -ErrorAction SilentlyContinue 
                
                Write-Verbose "--> Disconnect-IscsiTarget -SessionIdentifier $sid -Confirm:0"
                Disconnect-IscsiTarget -SessionIdentifier $sid -Confirm:0 -ErrorAction SilentlyContinue 
                
            }
        }
        
        $v = "Updating MPIO claim."
        $v | Write-Verbose
        Write-Verbose "--> Update-MPIOClaimedHW -Confirm:0"
        Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan

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

    $return = Get-SilkSessions

    if ($rebalance) {
        $sessions = $total.'Configured Sessions'
        $cnodes = $total.CNodes
        $cnodes--
        $sessionsPer = Get-SilkSessionsPer -nodes $cnodes -sessions $sessions
        $v = "Set-SilkSessionBalance -sessionsPer " + $sessionsPer
        $v | Write-Verbose
        Set-SilkSessionBalance -sessionsPer $sessionsPer
        $return = Get-SilkSessions
    }

    return $return | Format-Table

} 