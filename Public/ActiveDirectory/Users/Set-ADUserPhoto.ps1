function Set-ADUserPhoto {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$Identity,
        [Parameter(Mandatory=$true)][string]$PicturePath
    )
    process {
        if ($pscmdlet.ShouldProcess($Identity, "Set AD Photo from $PicturePath")) {
            $photo = [byte[]](Get-Content $PicturePath -Encoding byte)
            Set-ADUser $Identity -Replace @{thumbnailPhoto=$photo}
        }
    }
}
