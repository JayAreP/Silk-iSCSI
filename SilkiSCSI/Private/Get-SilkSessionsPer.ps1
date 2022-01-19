function Get-SilkSessionsPer {
    param(
        [Parameter(Mandatory)]
        [int] $nodes,
        [Parameter(Mandatory)]
        [int] $sessions
    )
    Write-Verbose ">> Invoking - Get-SilkSessionsPer"
    
    if ( ($sessions % $nodes) -eq 0 ) {
        $sessionsPer = $sessions / $nodes
    } else {
        $sessionsPer = [math]::truncate($sessions/$nodes)+1
    }
    
    return $sessionsPer
}