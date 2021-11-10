function Get-SilkDisks {
    param(
        [Parameter()]
        [ipaddress] $cnodeIP,
        [Parameter()]
        [int] $diskNumber
    )

    if ($diskNumber) {
        $silkDisks = Get-Disk -number $diskNumber| Where-Object {$_.Manufacturer -match 'KMNRIO'}
    } else {
        $silkDisks = Get-Disk | Where-Object {$_.Manufacturer -match 'KMNRIO'}
    }
    

    if ($cnodeIP) {
        $allConnections = Get-IscsiConnection | where-object {$_.TargetAddress -eq $cnodeIP.IPAddressToString}
    } else {
        $allConnections = Get-IscsiConnection 
    }

    $returnArray = @()

    $allTargetIPs = ($allConnections | Select-Object TargetAddress -Unique).TargetAddress

    foreach ($d in $silkDisks) {
        $o = New-Object psobject
        $o | Add-Member -MemberType NoteProperty -Name "Number" -Value $d.Number
        $o | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $d.SerialNumber
        foreach ($i in $allTargetIPs) {
            $paths = 0
            foreach ($s in $allConnections) {
                if ($s.TargetAddress -eq $i) {                    
                    $path = $s | Get-IscsiSession | Get-Disk | Where-Object {$_.SerialNumber -eq $d.SerialNumber}
                    if ($path) {
                        $paths++
                    }
                }
            }

            $o | Add-Member -MemberType NoteProperty -Name $i -Value $paths
        }
        $returnArray += $o
    }
    return $returnArray
}