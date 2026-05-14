function Get-DnsRecordStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Type = "A"
    )
    process {
        Resolve-DnsName -Name $Name -Type $Type -ErrorAction SilentlyContinue | Select-Object Name, Type, TTL, IPAddress, NameHost
    }
}
