function Disable-WindowsUAC {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)][string]$ComputerName = $env:COMPUTERNAME
    )
    process {
        if ($pscmdlet.ShouldProcess($ComputerName, "Disable UAC (EnableLUA=0)")) {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
                Write-Warning "A reboot is required to fully disable UAC."
            }
        }
    }
}
