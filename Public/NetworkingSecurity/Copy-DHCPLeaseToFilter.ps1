function Copy-DHCPLeaseToFilter {
    <#
    .SYNOPSIS
        Copies active DHCP leases from a scope to the DHCP MAC address filter list.

    .DESCRIPTION
        This advanced function retrieves all 'Active' leases from a specified DHCP Scope
        on a DHCP Server, and automatically adds their MAC addresses to the Allow or Deny filter list.

    .PARAMETER ScopeId
        The IPv4 Scope ID (e.g. 10.20.192.0) to pull active leases from.

    .PARAMETER ComputerName
        The DHCP Server hostname or IP. Defaults to the local computer.

    .PARAMETER FilterList
        The MAC address filter list to add the leases to. Valid options are 'Allow' or 'Deny'. Defaults to 'Allow'.

    .EXAMPLE
        Copy-DHCPLeaseToFilter -ComputerName "DHCPSrv01" -ScopeId "10.20.192.168" -FilterList Allow
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScopeId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Allow', 'Deny')]
        [string]$FilterList = 'Allow'
    )

    process {
        try {
            Write-Verbose "Connecting to DHCP server $ComputerName, Scope $ScopeId..."
            
            # Require DhcpServer module
            if (-not (Get-Command Get-DhcpServerv4Lease -ErrorAction SilentlyContinue)) {
                throw "DhcpServer module is not available. Please install the RSAT DHCP tools."
            }

            $ActiveLeases = Get-DhcpServerv4Lease -ComputerName $ComputerName -ScopeId $ScopeId -AllLeases -ErrorAction Stop |
                Where-Object { $_.AddressState -eq 'Active' }

            if (-not $ActiveLeases) {
                Write-Warning "No active leases found in scope $ScopeId on $ComputerName."
                return
            }

            Write-Verbose "Found $($ActiveLeases.Count) active leases. Adding to $FilterList list..."

            foreach ($Lease in $ActiveLeases) {
                $MacAddress = $Lease.ClientId
                $Description = if ($Lease.HostName) { $Lease.HostName } else { "Imported from Lease $($Lease.IPAddress)" }

                if ($pscmdlet.ShouldProcess("MAC: $MacAddress (IP: $($Lease.IPAddress))", "Add to $FilterList Filter")) {
                    try {
                        Add-DhcpServerv4Filter -ComputerName $ComputerName -MacAddress $MacAddress -Description $Description -List $FilterList -Force -ErrorAction Stop
                        
                        [PSCustomObject]@{
                            ComputerName = $ComputerName
                            ScopeId      = $ScopeId
                            IPAddress    = $Lease.IPAddress
                            MacAddress   = $MacAddress
                            HostName     = $Description
                            List         = $FilterList
                            Status       = 'Added'
                        }
                    } catch {
                        # Suppress error if it already exists, otherwise throw
                        if ($_.Exception.Message -match "already exists") {
                            Write-Verbose "MAC $MacAddress is already in the filter list."
                            [PSCustomObject]@{
                                ComputerName = $ComputerName
                                ScopeId      = $ScopeId
                                IPAddress    = $Lease.IPAddress
                                MacAddress   = $MacAddress
                                HostName     = $Description
                                List         = $FilterList
                                Status       = 'Already Exists'
                            }
                        } else {
                            Write-Error "Failed to add MAC $MacAddress to $FilterList list: $_"
                        }
                    }
                }
            }
        } catch {
            Write-Error "Failed to process DHCP leases: $_"
        }
    }
}
