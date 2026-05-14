function Get-ADPrivilegedUser {
    [CmdletBinding()]
    param()
    process {
        $groups = @("Domain Admins", "Enterprise Admins", "Schema Admins")
        foreach ($group in $groups) {
            Get-ADGroupMember -Identity $group | Select-Object @{N='GroupName';E={$group}}, Name, SamAccountName, ObjectClass
        }
    }
}
