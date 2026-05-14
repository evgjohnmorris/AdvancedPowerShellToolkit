function Get-ADInactiveComputer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][int]$DaysInactive = 90
    )
    process {
        $Date = (Get-Date).AddDays(-$DaysInactive)
        Get-ADComputer -Filter {LastLogonDate -lt $Date} -Properties LastLogonDate | Select-Object Name, LastLogonDate, Enabled
    }
}
