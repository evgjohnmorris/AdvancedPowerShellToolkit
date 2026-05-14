function Unlock-ADUserAccount {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$Identity
    )
    process {
        if ($pscmdlet.ShouldProcess($Identity, "Unlock AD Account")) {
            Unlock-ADAccount -Identity $Identity
        }
    }
}
