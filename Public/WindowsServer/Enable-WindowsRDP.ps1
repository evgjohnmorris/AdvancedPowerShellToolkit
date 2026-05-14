function Enable-WindowsRDP {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)][string]$ComputerName = $env:COMPUTERNAME
    )
    process {
        if ($pscmdlet.ShouldProcess($ComputerName, "Enable RDP")) {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
            }
        }
    }
}
