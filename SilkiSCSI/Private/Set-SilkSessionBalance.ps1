function Set-SilkSessionBalance {
    param(
        [parameter()]
        [switch] $up,
        [parameter()]
        [switch] $down,
        [parameter()]
        [int] $sessionsPer
    )

    Write-Verbose ">> Invoking - Set-SilkSessionBalance"

    $total = Get-SilkSessions -totalOnly
    $sessions = Get-SilkSessions | Sort-Object 'Connected Sessions' -Descending

    $currentSessions = $total.'Configured Sessions'
    $currentCnodes = $total.CNodes
    if ($up) {
        $currentCnodes++
    }
    if ($down) {
        $currentCnodes--
    }
    
    if (!$sessionsPer) {
        $sessionsPer = Get-SilkSessionsPer -nodes $currentCnodes -sessions $currentSessions
        Write-Verbose "---- Dynamically determined - $sessionsPer - sessions per CNode"
    }

    foreach ($s in $sessions) {
        $nodeSessions = $s.'Configured Sessions'
        $cnodeIP = $s.'CNode IP'
        if ($nodeSessions -lt $sessionsPer) {
            $sessionCount = $sessionsPer - $nodeSessions
            Write-Verbose "---- Adding - $sessionCount - to CNode - $cnodeIP -"
            Connect-SilkCNode -SessionCount $sessionCount -cnodeIP $cnodeIP | Out-Null
        } elseif ($nodeSessions -gt $sessionsPer) {
            Write-Verbose "---- Removing - $cnodeIP - and adding $sessionsPer"
            Disconnect-SilkCNode -cnodeIP $cnodeIP | Out-Null
            Connect-SilkCNode -cnodeIP $cnodeIP -SessionCount $sessionsPer | Out-Null
        }
    }
}