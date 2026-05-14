function Restart-WindowsServer {
    <#
    .SYNOPSIS
        Safely restarts one or more Windows servers with logging and connection checks.

    .DESCRIPTION
        This function tests the connection to each specified server. If the server is reachable,
        it initiates a reboot. It supports ShouldProcess (-WhatIf and -Confirm) to prevent
        accidental reboots, and logs the outcome to a specified directory.

    .PARAMETER ComputerName
        An array of computer names or IP addresses to restart.

    .PARAMETER LogPath
        The directory where the restart log should be written. Defaults to 'C:\Logs'.

    .EXAMPLE
        Restart-WindowsServer -ComputerName "Server01", "Server02"
        Restarts Server01 and Server02, logging to C:\Logs.

    .EXAMPLE
        "Server01", "Server02" | Restart-WindowsServer -WhatIf
        Shows what would happen if the servers were to be restarted.

    .EXAMPLE
        Get-XAWorkerGroup "MyGroup" | Select-Object -ExpandProperty ServerNames | Restart-WindowsServer
        Takes a list of Citrix XenApp worker group servers and pipes them to be restarted.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ServerName')]
        [string[]]$ComputerName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath = "C:\Logs"
    )

    begin {
        $Date = (Get-Date).ToString('yyyyMMdd-HHmm')
        
        # Ensure log directory exists
        if (-not (Test-Path -Path $LogPath)) {
            Write-Verbose "Creating log directory at $LogPath"
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        
        $LogFile = Join-Path -Path $LogPath -ChildPath "RestartServers-$Date.log"
        Write-Verbose "Logging actions to $LogFile"
    }

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Processing $Computer..."
            
            # Use Test-Connection (ping) to check if it's reachable
            # -Quiet returns a boolean in Windows PowerShell
            if (Test-Connection -ComputerName $Computer -Count 2 -Quiet -ErrorAction SilentlyContinue) {
                
                # ShouldProcess prompts for confirmation or respects -WhatIf
                if ($PSCmdlet.ShouldProcess($Computer, "Restart Server")) {
                    try {
                        Write-Verbose "Initiating restart on $Computer"
                        Restart-Computer -ComputerName $Computer -Force -ErrorAction Stop
                        Add-Content -Path $LogFile -Value "$(Get-Date) [$Computer] - Reboot initiated successfully."
                    }
                    catch {
                        Write-Error "Failed to restart $Computer. Error: $_"
                        Add-Content -Path $LogFile -Value "$(Get-Date) [$Computer] - ERROR: $_"
                    }
                } else {
                    Add-Content -Path $LogFile -Value "$(Get-Date) [$Computer] - Skipped due to WhatIf/Confirm."
                }
            }
            else {
                Write-Warning "Unable to ping $Computer. Skipping restart."
                Add-Content -Path $LogFile -Value "$(Get-Date) [$Computer] - WARNING: Unable to ping."
            }
        }
    }
}
