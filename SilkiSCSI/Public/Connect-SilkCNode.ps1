function Connect-SilkCNode {
    param(
        [Parameter()]
        [int] $SessionCount = 1,
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [switch] $rebalance
    )

    # Process

    # information gathering for current status

    $total = Get-SilkSessions -totalOnly
    if ($rebalance) {
        $SessionCount = 1
    }

    # Test-Netconnection against the IP to either select the best interface, or validate the specified interface.

    $pingTest = Test-NetConnection -ComputerName $cnodeIP.IPAddressToString -Port 3260
    if ($pingTest.TcpTestSucceeded) {
        $sourceNic = Get-NetIPConfiguration | Where-Object {$_.IPv4Address.IPAddress -eq $pingTest.SourceAddress.IPAddress}
    } else {
        $return = "Could not reach the Cnode on any available interface. Please check that the correct CNode IP was supplied and that any required routes are configured."
        return $return | Write-Error
    }



    # Use the decided upon interface to connect
    $v = "Determined interface " + $sourceNic.InterfaceAlias + " as prefered source."
    $iSCSIData1 = Get-NetIPAddress -InterfaceAlias $sourceNic.InterfaceAlias -AddressFamily ipv4
    $cmd = "--> New-IscsiTargetPortal -TargetPortalAddress " + $cnodeIP.IPAddressToString + " -TargetPortalPortNumber 3260 -InitiatorPortalAddress " + $iSCSIData1.IPAddress
    $cmd | Write-Verbose
    New-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress | Out-Null
    $SDPIQN = Get-IscsiTarget | Where-Object {$_.NodeAddress -match "kaminario"} 

    $session = 0
    while ($session -lt $SessionCount) {
        $v = "Connecting session " + $session + " to " + $cnodeIP.IPAddressToString + " via " + $iSCSIData1.IPAddress
        $v | Write-Verbose
        $cmd = '--> Connect-IscsiTarget -NodeAddress ' + $SDPIQN.NodeAddress + ' -TargetPortalAddress ' + $cnodeIP.IPAddressToString + ' -TargetPortalPortNumber 3260 -InitiatorPortalAddress ' + $iSCSIData1.IPAddress + ' -IsPersistent $true -IsMultipathEnabled $true'
        $cmd | Write-Verbose
        Connect-IscsiTarget -NodeAddress $SDPIQN.NodeAddress -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress -IsPersistent $true -IsMultipathEnabled $true | Out-Null
        $session++
    }

    # Return Get-SilkSessions 

    $return = Get-SilkSessions 

    if ($rebalance) {
        $sessions = $total.'Configured Sessions'
        $cnodes = $total.CNodes
        $cnodes++
        $sessionsPer = Get-SilkSessionsPer -nodes $cnodes -sessions $sessions
        Set-SilkSessionBalance -sessionsPer $sessionsPer
        $return = Get-SilkSessions
    }

    return $return | Format-Table
}