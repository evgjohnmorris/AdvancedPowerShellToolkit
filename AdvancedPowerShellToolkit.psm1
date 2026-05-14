# Root module for AdvancedPowerShellToolkit

$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

# Dot source private functions
if (Test-Path -Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        try {
            . $_.FullName
        } catch {
            Write-Error "Failed to dot-source private function: $($_.FullName)"
        }
    }
}

# Dot source public functions
$PublicFunctions = @()
if (Test-Path -Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        try {
            . $_.FullName
            $PublicFunctions += $_.BaseName
        } catch {
            Write-Error "Failed to dot-source public function: $($_.FullName)"
        }
    }
}

# Export only public functions
Export-ModuleMember -Function $PublicFunctions
