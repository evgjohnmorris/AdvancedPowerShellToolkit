function Get-ADUserGroupMembership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$Identity
    )
    process {
        Get-ADPrincipalGroupMembership -Identity $Identity | Select-Object Name, GroupCategory, GroupScope
    }
}
