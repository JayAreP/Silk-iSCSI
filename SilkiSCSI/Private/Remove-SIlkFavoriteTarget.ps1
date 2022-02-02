function Remove-SilkFavoriteTarget {
    param(
        [Parameter(Mandatory)]
        [IPAddress] $cnodeIP
    )

    process {
        Write-Verbose ">> Invoking - Remove-SilkFavoriteTarget"
        $response = @()
        $wmiQuery = Get-WmiObject -Class MSiSCSIInitiator_PersistentLoginClass -Namespace ROOT/WMI
            foreach ($w in $wmiQuery) {
                if ($w.TargetPortal.Address -eq $cnodeIP.IPAddressToString) {
                    # Remove-WmiObject -InputObject $w
                    $init = $w.InitiatorInstance
                    $target = $w.TargetName
                    $port = $w.InitiatorPortNumber
                    $IPString = $cnodeIP.IPAddressToString
                    $RemoveCommand = "iscsicli RemovePersistentTarget $init $target $port $IPString 3260"
                    Write-Verbose "---> $RemoveCommand"
                    Invoke-Expression $RemoveCommand | Out-Null
                }
            }

        return $response
    }
}
