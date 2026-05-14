function Find-ADServiceAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$SearchBase
    )
    process {
        Write-Verbose "Searching for accounts with ServicePrincipalName..."
        Get-ADUser -Filter {ServicePrincipalNames -like "*"} -Properties ServicePrincipalNames, PasswordLastSet -SearchBase $SearchBase | 
            Select-Object Name, SamAccountName, PasswordLastSet, Enabled
    }
}
