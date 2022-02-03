function Get-SilkSessions {
    param(
        [Parameter()]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [switch] $update,
        [Parameter()]
        [switch] $totalOnly
    )

    if ($update) {
        Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
    }

    $target = Get-IscsiTarget | Where-Object {$_.NodeAddress -match "kaminario"}

    if ($cnodeIP) {
        $allConnections = Get-IscsiConnection -ErrorAction silentlycontinue | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}
        while (!$allConnections -and $target) {
            Write-Verbose "SCSI query failed - forcing MPIO claim update"
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
            Start-Sleep -Seconds 4
            $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}
        }
    } else {
        $allConnections = Get-IscsiConnection -ErrorAction silentlycontinue 
        while (!$allConnections -and $target) {
            Write-Verbose "SCSI query failed - forcing MPIO claim update"
            Update-MPIOClaimedHW -Confirm:0 | Out-Null # Rescan
            Start-Sleep -Seconds 4
            $allConnections = Get-IscsiConnection -ErrorAction silentlycontinue 
        }
    }

    $returnArray = @()

    # Change this query to Get-IscsiTargetPortal to better represent orphaned target portals.
    # $allTargetIPs = ($allConnections | Select-Object TargetAddress -Unique).TargetAddress
    $alltargetIPs = (Get-IscsiTargetPortal).TargetPortalAddress

    $configuredTotal = 0 
    $connectedTotal = 0
    $cnodeTotal = 0

    foreach ($i in $allTargetIPs) {

        $cnodeTotal++

        $hostIP = ($allConnections | Where-Object {$_.TargetAddress -eq $i} | Select-Object InitiatorAddress -Unique).InitiatorAddress

        $o = New-Object psobject
        $o | Add-Member -MemberType NoteProperty -Name "CNode IP" -Value $i
        $o | Add-Member -MemberType NoteProperty -Name "Host IP" -Value $hostIP
        $configured = ($allConnections | Where-Object {$_.TargetAddress -eq $i} | Get-IscsiSession | Where-Object {$_.IsDiscovered} | Measure-Object).count
        if ($configured) {
            $configuredTotal = $configuredTotal + $configured
            $o | Add-Member -MemberType NoteProperty -Name "Configured Sessions" -Value $configured
        } else {
            $o | Add-Member -MemberType NoteProperty -Name "Configured Sessions" -Value 0
        }

        $connected = ($allConnections | Where-Object {$_.TargetAddress -eq $i} | Measure-Object).count
        if ($connected) {
            $connectedTotal = $connectedTotal + $connected
            $o | Add-Member -MemberType NoteProperty -Name "Connected Sessions" -Value $connected
        } else {
            $o | Add-Member -MemberType NoteProperty -Name "Connected Sessions" -Value 0 
        }
        $o | Add-Member -MemberType NoteProperty -Name "Silk IQN" -Value ($allConnections | Where-Object {$_.TargetAddress -eq $i} |Get-IscsiSession | Select-Object TargetNodeAddress -Unique).TargetNodeAddress

        $returnArray += $o

    }

    if ($totalOnly) {
        $t = New-Object psobject
        $t | Add-Member -MemberType NoteProperty -Name "CNode IP" -Value "Total"
        $t | Add-Member -MemberType NoteProperty -Name "CNodes" -Value $cnodeTotal
        $t | Add-Member -MemberType NoteProperty -Name "Configured Sessions" -Value $configuredTotal
        $t | Add-Member -MemberType NoteProperty -Name "Connected Sessions" -Value $connectedTotal

        $returnArray = $t
    }

    if ($returnArray) {
        $returnArray = $returnArray | Sort-Object "CNode IP"
        return $returnArray 
    } else {
        return $null
    }
}