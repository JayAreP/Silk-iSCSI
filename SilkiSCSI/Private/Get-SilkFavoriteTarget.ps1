function Get-SilkFavoriteTarget {
    param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string] $SessionIdentifier
    )

    process {
        Write-Verbose ">> Invoking - Get-SilkFavoriteTarget"
        $wmiResponse = Get-WmiObject -Class MSFT_iSCSISession -Namespace ROOT/Microsoft/Windows/Storage | Where-Object {$_.SessionIdentifier -eq $SessionIdentifier}

        return $wmiResponse
    }
}