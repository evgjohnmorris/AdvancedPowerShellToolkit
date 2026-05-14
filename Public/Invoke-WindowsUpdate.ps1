function Invoke-WindowsUpdate {
    <#
    .SYNOPSIS
        Installs Windows Updates on remote computers and manages RDS/Terminal Service logon states.
        
    .DESCRIPTION
        This advanced function disables Remote Desktop logons, optionally sends warning messages,
        invokes the Windows Update installation (requires PSWindowsUpdate or similar module),
        restarts the computer if necessary, and re-enables logons. 

    .PARAMETER ComputerName
        One or more computer names to run the updates on.

    .PARAMETER MessageIntervals
        Intervals in seconds to wait after sending warning messages before forcing logoff/update.
        Defaults to a 1 minute warning.

    .PARAMETER SendWarning
        Switch to send warning messages using the 'msg.exe' command to connected users.

    .EXAMPLE
        Invoke-WindowsUpdate -ComputerName "Server01", "Server02" -SendWarning -MessageIntervals 60
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [int[]]$MessageIntervals = @(60),

        [Parameter(Mandatory = $false)]
        [switch]$SendWarning
    )

    begin {
        function Set-ComputerLogon {
            [CmdletBinding(SupportsShouldProcess = $true)]
            param (
                [Parameter(Mandatory = $true)]
                [string]$ComputerName,

                [Parameter(Mandatory = $true)]
                [ValidateSet('Enable', 'Disable')]
                [string]$Action
            )
            
            try {
                $Logon = Get-CimInstance -ClassName win32_terminalservicesetting -Namespace 'root\cimv2\TerminalServices' -ComputerName $ComputerName -ErrorAction Stop

                if ($Action -eq 'Enable') {
                    $Logon.SessionBrokerDrainMode = 0
                    $Logon.Logons = 0
                } else {
                    $Logon.Logons = 1
                }

                Set-CimInstance -CimInstance $Logon -ComputerName $ComputerName -ErrorAction Stop
                Write-Verbose "[$ComputerName] Remote Desktop logons set to $Action."
            } catch {
                Write-Error "[$ComputerName] Error setting computer logon to $Action. $_"
            }
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $ResultObject = [PSCustomObject]@{
                ComputerName = $Computer
                Status       = 'Unknown'
                Installed    = $null
                Errors       = $null
            }

            if (-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                Write-Warning "[$Computer] Unreachable."
                $ResultObject.Status = 'Unreachable'
                Write-Output $ResultObject
                continue
            }

            if ($pscmdlet.ShouldProcess($Computer, "Install Windows Updates")) {
                try {
                    # Disable logons
                    Set-ComputerLogon -ComputerName $Computer -Action Disable

                    # Warnings
                    if ($SendWarning) {
                        foreach ($Interval in ($MessageIntervals | Sort-Object -Descending)) {
                            $MessageTime = if ($Interval -lt 3600) { "$($Interval / 60) minutes" } else { "$($Interval / 3600) hours" }
                            Write-Verbose "[$Computer] Sending warning message. Updates in $MessageTime."
                            
                            $Message = "Please save your work. This server is being shut down for updates in $MessageTime."
                            # Use Invoke-Command to run msg.exe locally on the target to ensure it hits all sessions
                            Invoke-Command -ComputerName $Computer -ScriptBlock {
                                param($msg)
                                msg * /SERVER:localhost $msg
                            } -ArgumentList $Message -ErrorAction SilentlyContinue

                            Start-Sleep -Seconds $Interval
                        }
                    }

                    # We assume PSWindowsUpdate module is available on the target or locally
                    Write-Verbose "[$Computer] Starting Windows Update installation..."
                    $UpdateJob = Invoke-Command -ComputerName $Computer -ScriptBlock {
                        if (-not (Get-Module -ListAvailable PSWindowsUpdate)) {
                            throw "PSWindowsUpdate module is not installed on the target machine."
                        }
                        Import-Module PSWindowsUpdate
                        # Install all updates, accept all, auto reboot if needed but we'll handle reboot manually if preferred.
                        # For this script we will tell it not to reboot so we can manage the logon state after.
                        Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose
                    } -ErrorAction Stop

                    $ResultObject.Status = 'Updates Applied'
                    $ResultObject.Installed = ($UpdateJob | Select-Object -ExpandProperty Title) -join ", "
                    
                    Write-Verbose "[$Computer] Restarting computer..."
                    Restart-Computer -ComputerName $Computer -Wait -For WinRM -Force -ErrorAction Stop

                    # Re-enable logons
                    Set-ComputerLogon -ComputerName $Computer -Action Enable

                } catch {
                    $ResultObject.Status = 'Failed'
                    $ResultObject.Errors = $_.Exception.Message
                    Write-Error "[$Computer] Failed to update: $_"
                }

                Write-Output $ResultObject
            }
        }
    }
}
