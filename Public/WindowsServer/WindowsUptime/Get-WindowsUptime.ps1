function Get-WindowsUptime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][string[]]$ComputerName = $env:COMPUTERNAME
    )
    process {
        foreach ($comp in $ComputerName) {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $comp -ErrorAction Stop
                $uptime = (Get-Date) - $os.LastBootUpTime
                [PSCustomObject]@{
                    ComputerName = $comp
                    LastBootUpTime = $os.LastBootUpTime
                    Days = $uptime.Days
                    Hours = $uptime.Hours
                    Minutes = $uptime.Minutes
                }
            } catch {
                Write-Error "Failed to get uptime for $comp : $_"
            }
        }
    }
}
