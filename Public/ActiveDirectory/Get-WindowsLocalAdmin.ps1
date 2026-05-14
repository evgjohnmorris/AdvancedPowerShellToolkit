function Get-WindowsLocalAdmin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$ComputerName = $env:COMPUTERNAME
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-LocalGroupMember -Group "Administrators" | Select-Object Name, PrincipalSource, ObjectClass
        }
    }
}
