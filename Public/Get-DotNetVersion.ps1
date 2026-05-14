function Get-DotNetVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$ComputerName = $env:COMPUTERNAME
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
            if ($reg) {
                [PSCustomObject]@{
                    ComputerName = $env:COMPUTERNAME
                    Version = $reg.Version
                    Release = $reg.Release
                }
            } else {
                Write-Warning "Could not read .NET registry key."
            }
        }
    }
}
