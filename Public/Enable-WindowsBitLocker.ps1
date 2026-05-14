function Enable-WindowsBitLocker {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$MountPoint
    )
    process {
        if ($pscmdlet.ShouldProcess($MountPoint, "Enable BitLocker")) {
            Enable-BitLocker -MountPoint $MountPoint -EncryptionMethod XtsAes256 -UsedSpaceOnly
        }
    }
}
