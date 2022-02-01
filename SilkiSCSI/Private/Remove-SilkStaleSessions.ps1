function Remove-SilkStaleSessions {
    param(
        [parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [parameter()]
        [switch] $force
    )

    $killSessions = @()

    $totalSessions = Get-SilkSessions -totalOnly
    $upSessions = Get-IscsiConnection | Get-IscsiSession
    $allSessions = Get-IscsiSession

    foreach ($s in $allSessions) {
        if ($upSessions.SessionIdentifier -notcontains $s.SessionIdentifier) {
            $killSessions += $s
        }
    }

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

        if ($force) {
            Remove-SilkFavoriteTarget -cnodeIP $cnodeIP.IPAddressToString
        }
    }

    if ($cnodeIP) {
        $portal = Get-IscsiTargetPortal | Where-Object {$_.TargetPortalAddress -eq $cnodeIP.IPAddressToString}
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
    }

    $sessionsPer = Get-SilkSessionsPer -nodes $totalsessions.CNodes -sessions $totalsessions.'Configured Sessions'
    Set-SilkSessionBalance -sessionsPer $sessionsPer

}