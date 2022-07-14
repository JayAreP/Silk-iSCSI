function Connect-SilkCNode {
    param(
        [Parameter()]
        [int] $SessionCount = 1,
        [Parameter(Mandatory)]
        [ipaddress] $cnodeIP,
        [parameter()]
        [System.Management.Automation.PSCredential] $chapCredentials,
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

    # generate chap user and secret

    if ($chapCredentials) {
        $chapUser = $chapCredentials.UserName
        $chapSecret = $chapCredentials.GetNetworkCredential().Password
        Write-Verbose " -chapCredentials specified --- connecting using chap authentication"
        $cmd = "--> Set-IscsiChapSecret -ChapSecret " + $chapSecret
        $cmd | Write-Verbose
        Set-IscsiChapSecret -ChapSecret $chapSecret
    }

    # Use the decided upon interface to connect
    $v = "Determined interface " + $sourceNic.InterfaceAlias + " as prefered source."
    $iSCSIData1 = Get-NetIPAddress -InterfaceAlias $sourceNic.InterfaceAlias -AddressFamily ipv4
    if ($chapCredentials) {
        $cmd = "--> New-IscsiTargetPortal -TargetPortalAddress " + $cnodeIP.IPAddressToString + " -TargetPortalPortNumber 3260 -InitiatorPortalAddress " + $iSCSIData1.IPAddress + ' -ChapUserName ' + $chapUser + " -ChapSecret " + $chapSecret + ' -AuthenticationType ONEWAYCHAP'
        $cmd | Write-Verbose
        try {
            New-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress -ChapUserName $chapUser -ChapSecret $chapSecret -AuthenticationType ONEWAYCHAP | Out-Null
        } catch {
            Write-Verbose "-- Connect-IscsiTargetPortal failed -- Verify chap username and secret"
            $error[0]
            break
        }
        
    } else {
        $cmd = "--> New-IscsiTargetPortal -TargetPortalAddress " + $cnodeIP.IPAddressToString + " -TargetPortalPortNumber 3260 -InitiatorPortalAddress " + $iSCSIData1.IPAddress 
        $cmd | Write-Verbose
        New-IscsiTargetPortal -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress | Out-Null
    }

    $SDPIQN = Get-IscsiTarget | Where-Object {$_.NodeAddress -match "kaminario" -or $_.NodeAddress -match "silk"}

    $session = 0
    while ($session -lt $SessionCount) {
        if ($chapCredentials) {
            $v = "Connecting session " + $session + " to " + $cnodeIP.IPAddressToString + " via " + $iSCSIData1.IPAddress
            $v | Write-Verbose
            $cmd = '--> Connect-IscsiTarget -NodeAddress ' + $SDPIQN.NodeAddress + ' -TargetPortalAddress ' + $cnodeIP.IPAddressToString + ' -TargetPortalPortNumber 3260 -InitiatorPortalAddress ' + $iSCSIData1.IPAddress + ' -IsPersistent $true -IsMultipathEnabled $true' + ' -ChapUserName ' + $chapUser + ' -ChapSecret ' + $chapSecret + ' -AuthenticationType ONEWAYCHAP'
            $cmd | Write-Verbose
            Connect-IscsiTarget -NodeAddress $SDPIQN.NodeAddress -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress -IsPersistent $true -IsMultipathEnabled $true -ChapUsername $chapUser -ChapSecret $chapSecret -AuthenticationType ONEWAYCHAP | Out-Null
            $session++
        } else {
            $v = "Connecting session " + $session + " to " + $cnodeIP.IPAddressToString + " via " + $iSCSIData1.IPAddress
            $v | Write-Verbose
            $cmd = '--> Connect-IscsiTarget -NodeAddress ' + $SDPIQN.NodeAddress + ' -TargetPortalAddress ' + $cnodeIP.IPAddressToString + ' -TargetPortalPortNumber 3260 -InitiatorPortalAddress ' + $iSCSIData1.IPAddress + ' -IsPersistent $true -IsMultipathEnabled $true'
            $cmd | Write-Verbose
            Connect-IscsiTarget -NodeAddress $SDPIQN.NodeAddress -TargetPortalAddress $cnodeIP.IPAddressToString -TargetPortalPortNumber 3260 -InitiatorPortalAddress $iSCSIData1.IPAddress -IsPersistent $true -IsMultipathEnabled $true | Out-Null
            $session++
        }

    }

    # Return Get-SilkSessions 

    $return = Get-SilkSessions 

    if ($rebalance) {
        $sessions = $total.'Configured Sessions'
        $cnodes = $total.CNodes
        $cnodes++
        $sessionsPer = Get-SilkSessionsPer -nodes $cnodes -sessions $sessions
        $v = "Set-SilkSessionBalance -sessionsPer " + $sessionsPer
        $v | Write-Verbose
        Set-SilkSessionBalance -sessionsPer $sessionsPer
        $return = Get-SilkSessions
    }

    return $return | Format-Table
}