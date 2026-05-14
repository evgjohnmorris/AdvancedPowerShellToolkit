function Get-WindowsBackupStatus {
    <#
    .SYNOPSIS
        Retrieves the status of Windows Server Backup jobs.

    .DESCRIPTION
        This advanced function queries the local or remote server for current Windows Server Backup (WBAdmin) jobs.
        If a backup is currently running, it can optionally wait for it to complete.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .PARAMETER Wait
        If specified, the script will loop and wait for the currently running backup to finish before returning the final status.

    .EXAMPLE
        Get-WindowsBackupStatus -ComputerName "BackupServer" -Wait
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )

    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose "[$Computer] Querying Windows Backup status..."
                
                $ScriptBlock = {
                    if (-not (Get-Command Get-WBJob -ErrorAction SilentlyContinue)) {
                        throw "WindowsServerBackup module is not installed or available on this system."
                    }
                    
                    $Job = Get-WBJob
                    if (-not $Job) {
                        return [PSCustomObject]@{
                            ComputerName = $env:COMPUTERNAME
                            JobState     = 'No Active Jobs'
                            Operation    = $null
                            StartTime    = $null
                        }
                    }

                    if ($using:Wait) {
                        while ($Job -and $Job.JobState -eq 'Running') {
                            Start-Sleep -Seconds 15
                            $Job = Get-WBJob
                        }
                    }

                    # Output the job details
                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        JobState     = $Job.JobState
                        Operation    = $Job.CurrentOperation
                        StartTime    = $Job.StartTime
                        EndTime      = $Job.EndTime
                        Error        = $Job.ErrorDescription
                    }
                }

                if ($Computer -eq $env:COMPUTERNAME -or $Computer -eq 'localhost') {
                    Invoke-Command -ScriptBlock $ScriptBlock
                } else {
                    Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ErrorAction Stop
                }

            } catch {
                Write-Error "[$Computer] Failed to retrieve backup status: $_"
            }
        }
    }
}
