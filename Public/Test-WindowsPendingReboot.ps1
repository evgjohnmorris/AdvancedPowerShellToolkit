function Test-WindowsPendingReboot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$ComputerName = $env:COMPUTERNAME
    )
    process {
        $rebootPending = $false
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $reg1 = Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
            $reg2 = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
            $reg3 = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
            if ($reg1 -or $reg2 -or $reg3) { $true } else { $false }
        }
    }
}
