function Get-ADLockedOutUser {
    [CmdletBinding()]
    param()
    process {
        Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LastLogonDate
    }
}
