function Get-WindowsDiskInfo {
    <#
    .SYNOPSIS
        Retrieves partition and logical volume information for one or more computers.

    .DESCRIPTION
        This function queries the Win32_DiskPartition and Win32_LogicalDisk CIM classes
        to retrieve details such as Volume Name, Disk Index, File System, Free Space, 
        and Utilization percentage.

    .PARAMETER ComputerName
        One or more computer names to query. Defaults to the local computer name.

    .PARAMETER Credential
        Specifies a user account that has permission to perform this action. The default is the current user.

    .EXAMPLE
        Get-WindowsDiskInfo -ComputerName "Server01"
        Gets disk information for Server01.

    .EXAMPLE
        "Server01", "Server02" | Get-WindowsDiskInfo
        Gets disk information for multiple servers via pipeline input.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [pscredential]$Credential
    )

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Retrieving disk info for $Computer..."
            
            # Setup CIM Session options if credentials are provided
            $CimSessionParams = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $CimOption = New-CimSessionOption -Protocol DCOM
                $CimSessionParams.Credential = $Credential
                $CimSessionParams.SessionOption = $CimOption
            }

            try {
                $CimSession = New-CimSession @CimSessionParams
                
                # Retrieve Disk Partitions
                Write-Verbose "Querying Win32_DiskPartition..."
                $Disks = Get-CimInstance -CimSession $CimSession -ClassName Win32_DiskPartition |
                    Select-Object -Property Name, DiskIndex, @{
                        Name = "GPT"
                        Expression = { $_.Type.StartsWith("GPT") } 
                    }

                # Retrieve Logical Disks (DriveType 3 = Local Disk)
                Write-Verbose "Querying Win32_LogicalDisk..."
                $LogicalDisks = Get-CimInstance -CimSession $CimSession -ClassName Win32_LogicalDisk -Filter "DriveType=3"

                foreach ($LogicalDisk in $LogicalDisks) {
                    # Link logical disk to physical disk index
                    $Query = "Associators of {Win32_LogicalDisk.DeviceID='$($LogicalDisk.DeviceID)'} WHERE ResultRole=Antecedent"
                    $Volume = Get-CimInstance -CimSession $CimSession -Query $Query

                    $Disk = $Disks | Where-Object { $_.DiskIndex -eq $Volume.DiskIndex }
                    
                    $Utilization = 0
                    if ($Volume.Size -gt 0) {
                        $Utilization = 1 - (($LogicalDisk.FreeSpace / 1GB) / ($Volume.Size / 1GB))
                    }

                    [PSCustomObject]@{
                        ComputerName = $Computer
                        Error        = ''
                        VolumeName   = $LogicalDisk.VolumeName
                        DiskName     = ($Disk.Name -join ', ')
                        GPT          = ($Disk.GPT -join ', ')
                        DiskIndex    = $Volume.DiskIndex
                        DriveLetter  = $LogicalDisk.DeviceID
                        FreeSpaceGB  = [Math]::Round($LogicalDisk.FreeSpace / 1GB, 2)
                        Utilization  = $Utilization.ToString('P')
                        SizeGB       = [Math]::Round($Volume.Size / 1GB, 2)
                        FileSystem   = $LogicalDisk.FileSystem
                    }
                }
            } catch {
                Write-Error "Failed to retrieve disk info for $Computer. Error: $_"
                [PSCustomObject]@{
                    ComputerName = $Computer
                    Error        = $_.Exception.Message
                    VolumeName   = ''
                    DiskName     = ''
                    GPT          = ''
                    DiskIndex    = ''
                    DriveLetter  = ''
                    FreeSpaceGB  = ''
                    Utilization  = ''
                    SizeGB       = ''
                    FileSystem   = ''
                }
            } finally {
                if ($CimSession) {
                    Remove-CimSession -CimSession $CimSession -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
