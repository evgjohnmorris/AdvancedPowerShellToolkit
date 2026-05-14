function Test-WindowsNetworkPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ComputerName,
        [Parameter(Mandatory=$true)][int]$Port
    )
    process {
        $result = Test-NetConnection -ComputerName $ComputerName -Port $Port -WarningAction SilentlyContinue
        [PSCustomObject]@{
            ComputerName = $ComputerName
            Port = $Port
            TcpTestSucceeded = $result.TcpTestSucceeded
        }
    }
}
