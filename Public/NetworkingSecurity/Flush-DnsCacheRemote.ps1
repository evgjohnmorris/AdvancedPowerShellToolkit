function Flush-DnsCacheRemote {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string[]]$ComputerName
    )
    process {
        foreach ($comp in $ComputerName) {
            if ($pscmdlet.ShouldProcess($comp, "Flush DNS Cache")) {
                Invoke-Command -ComputerName $comp -ScriptBlock { Clear-DnsClientCache }
            }
        }
    }
}
