function Get-ComputerNetInfo {
    <#
    .SYNOPSIS
        Retrieves basic network information for one or more computers.

    .DESCRIPTION
        This function queries the DNS provider and WMI to retrieve the DNS Host Name,
        IP Address, and MAC Address for the specified computer(s).

    .PARAMETER ComputerName
        One or more computer names to query. Defaults to the local computer name.

    .EXAMPLE
        Get-ComputerNetInfo -ComputerName "Server01", "Server02"
        Retrieves the network info for Server01 and Server02.

    .EXAMPLE
        "Server01", "Server02" | Get-ComputerNetInfo
        Retrieves the network info using pipeline input.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($Computer in $ComputerName) {
            try {
                # Get hostname and IP address from DNS provider
                Write-Verbose "Getting DNS provider info for $Computer..."
                $DNSHostEntry = [System.Net.Dns]::GetHostEntry($Computer)
                $HostName = $DNSHostEntry.HostName
                
                # Handling multiple IP addresses (e.g., IPv6 and IPv4) by grabbing the first IPv4
                $IPAddress = ($DNSHostEntry.AddressList | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1).IPAddressToString

                if ([string]::IsNullOrWhiteSpace($IPAddress)) {
                    Write-Warning "Could not resolve an IPv4 address for $Computer."
                    continue
                }

                # Get MAC from WMI class
                Write-Verbose "Getting WMI provider info for $Computer..."
                # Use Get-CimInstance instead of deprecated Get-WmiObject
                $NetAdapter = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction Stop
                $MACAddress = ($NetAdapter | Where-Object { $_.IpAddress -contains $IPAddress }).MACAddress 

                # Output a custom object
                [PSCustomObject]@{
                    ComputerName = $Computer
                    DNSHostName  = $HostName
                    IPAddress    = $IPAddress
                    MACAddress   = $MACAddress
                }
            }
            catch {
                Write-Error "Failed to retrieve network info for computer '$Computer'. Error: $_"
            }
        }
    }
}
