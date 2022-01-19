function Remove-SilkFavoriteTarget {
    param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string] $SessionIdentifier
    )

    process {
        Write-Verbose ">> Invoking - Remove-SilkFavoriteTarget"
        $wmiResponse = Get-WmiObject -Class MSFT_iSCSISession -Namespace ROOT/Microsoft/Windows/Storage | Where-Object {$_.SessionIdentifier -eq $SessionIdentifier}
        $wmiResponse = $wmiResponse.Unregister()

        return $wmiResponse
    }
}