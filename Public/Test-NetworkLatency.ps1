function Test-NetworkLatency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ComputerName,
        [Parameter(Mandatory=$false)][int]$Count = 4
    )
    process {
        $ping = Test-Connection -ComputerName $ComputerName -Count $Count -ErrorAction SilentlyContinue
        if ($ping) {
            $stats = $ping | Measure-Object -Property ResponseTime -Average -Minimum -Maximum
            [PSCustomObject]@{
                ComputerName = $ComputerName
                PacketsSent = $Count
                AverageLatency = $stats.Average
                MinLatency = $stats.Minimum
                MaxLatency = $stats.Maximum
            }
        } else {
            Write-Warning "Host $ComputerName is unreachable."
        }
    }
}
