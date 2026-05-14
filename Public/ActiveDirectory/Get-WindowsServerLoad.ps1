function Get-WindowsServerLoad {
    <#
    .SYNOPSIS
        Retrieves current CPU and Memory load percentages for one or more Windows computers.

    .DESCRIPTION
        This function queries Win32_Processor and Win32_OperatingSystem CIM classes
        to calculate the average CPU usage and the percentage of physical memory in use.

    .PARAMETER ComputerName
        One or more computer names to query. Defaults to the local computer.

    .PARAMETER Credential
        Specifies a user account that has permission to perform this action.

    .EXAMPLE
        Get-WindowsServerLoad -ComputerName "Server01"
        Gets the current CPU and RAM load for Server01.

    .EXAMPLE
        "Server01", "Server02" | Get-WindowsServerLoad
        Gets the load for multiple servers via pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [pscredential]$Credential
    )

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Retrieving load information for $Computer..."
            
            # Setup CIM Session options if credentials are provided
            $CimSessionParams = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $CimOption = New-CimSessionOption -Protocol DCOM
                $CimSessionParams.Credential = $Credential
                $CimSessionParams.SessionOption = $CimOption
            }

            try {
                $CimSession = New-CimSession @CimSessionParams

                # Get CPU Load
                Write-Verbose "Querying Win32_Processor for $Computer..."
                $CPULoad = Get-CimInstance -CimSession $CimSession -ClassName Win32_Processor |
                    Measure-Object -Property LoadPercentage -Average

                # Get Memory Load
                Write-Verbose "Querying Win32_OperatingSystem for $Computer..."
                $OS = Get-CimInstance -CimSession $CimSession -ClassName Win32_OperatingSystem
                $MemoryUsage = 0
                if ($OS.TotalVisibleMemorySize -gt 0) {
                    $MemoryUsage = [Math]::Round(((($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) * 100) / $OS.TotalVisibleMemorySize), 2)
                }

                [PSCustomObject]@{
                    ComputerName = $Computer
                    CPUUsage     = $CPULoad.Average
                    MemoryUsage  = $MemoryUsage
                    Status       = "Success"
                }
            }
            catch {
                Write-Error "Failed to retrieve load for $Computer. Error: $_"
                [PSCustomObject]@{
                    ComputerName = $Computer
                    CPUUsage     = $null
                    MemoryUsage  = $null
                    Status       = "Error: $_"
                }
            }
            finally {
                if ($CimSession) {
                    Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
