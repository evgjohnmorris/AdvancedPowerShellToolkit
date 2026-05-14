function Get-WindowsTimeOffset {
    <#
    .SYNOPSIS
        Retrieves the NTP time offset for a computer compared to a specified NTP server.

    .DESCRIPTION
        This function uses the w32tm.exe utility to sample the time difference (offset)
        between the target computer and a specified NTP server. It returns the offset
        in seconds, along with the status of the query.

    .PARAMETER ComputerName
        One or more computer names to query. Defaults to the local computer.

    .PARAMETER NtpServer
        The NTP server to compare against. Defaults to 'pool.ntp.org'.

    .PARAMETER Samples
        The number of samples to take. Defaults to 3.

    .EXAMPLE
        Get-WindowsTimeOffset -ComputerName "Server01"
        Gets the time offset for Server01 compared to pool.ntp.org.

    .EXAMPLE
        "Server01", "Server02" | Get-WindowsTimeOffset -NtpServer "time.windows.com"
        Gets the time offset for multiple servers via pipeline against time.windows.com.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$NtpServer = 'pool.ntp.org',

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$Samples = 3
    )

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Retrieving time offset for $Computer against $NtpServer..."
            
            # Using Invoke-Command to run w32tm on the target machine if it's remote, 
            # otherwise running locally to avoid WinRM requirement for local queries.
            try {
                $ScriptBlock = {
                    param($NtpTarget, $SampleCount)
                    # We use 2>&1 to catch stderr if w32tm fails
                    $W32TMResult = w32tm /stripchart /computer:$NtpTarget /dataonly /samples:$SampleCount /ipprotocol:4 2>&1
                    return $W32TMResult
                }

                if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq 'localhost') {
                    $W32TMResult = & $ScriptBlock -NtpTarget $NtpServer -SampleCount $Samples
                } else {
                    $W32TMResult = Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $NtpServer, $Samples -ErrorAction Stop
                }

                $FoundTime = $false
                $Offset = $null
                $Status = "Unknown"

                if ($null -eq $W32TMResult -or $W32TMResult.Count -eq 0) {
                    $Status = "Offline or w32tm failed"
                } else {
                    # W32tm outputs headers and then samples: e.g., "15:30:00, +0.0123456s"
                    foreach ($Line in $W32TMResult) {
                        if ($Line -match ", ([-+]\d+\.\d+)s") {
                            $Offset = [float]$Matches[1]
                            $Status = "Online"
                            $FoundTime = $true
                            break # We just grab the first valid sample offset
                        }
                    }

                    if (-not $FoundTime) {
                        if ($W32TMResult -match "error") {
                            $Status = "NTP not responding or error"
                        } else {
                            # Join the output to show the actual error message
                            $Status = ($W32TMResult -join " | ")
                        }
                    }
                }

                [PSCustomObject]@{
                    ComputerName = $Computer
                    NtpServer    = $NtpServer
                    OffsetSec    = $Offset
                    Status       = $Status
                }
            }
            catch {
                Write-Error "Failed to retrieve time offset for $Computer. Error: $_"
                [PSCustomObject]@{
                    ComputerName = $Computer
                    NtpServer    = $NtpServer
                    OffsetSec    = $null
                    Status       = "Error: $_"
                }
            }
        }
    }
}
