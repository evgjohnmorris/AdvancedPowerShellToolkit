$RootPath = $PSScriptRoot
$PublicPath = Join-Path $RootPath "Public"
$PrivatePath = Join-Path $RootPath "Private"
$ModuleFile = Join-Path $RootPath "AdvancedPowerShellToolkit.psm1"
$ManifestFile = Join-Path $RootPath "AdvancedPowerShellToolkit.psd1"

Write-Host "Starting build process..."

$Sb = [System.Text.StringBuilder]::new()
$FunctionsToExport = [System.Collections.Generic.List[string]]::new()

$Files = @()
if (Test-Path $PublicPath) {
    $Files += Get-ChildItem -Path $PublicPath -Filter "*.ps1" -Recurse
}
if (Test-Path $PrivatePath) {
    $Files += Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -Recurse
}

foreach ($File in $Files) {
    if ($File.FullName.StartsWith($PublicPath)) {
        $FunctionsToExport.Add($File.BaseName)
    }
    $Sb.AppendLine([System.IO.File]::ReadAllText($File.FullName)) | Out-Null
    $Sb.AppendLine() | Out-Null
}

Write-Host "Found $($Files.Count) scripts. ($($FunctionsToExport.Count) public)"

[System.IO.File]::WriteAllText($ModuleFile, $Sb.ToString())
Write-Host "Successfully compiled $ModuleFile"

$ManifestContent = [System.IO.File]::ReadAllText($ManifestFile)

$ManifestContent = $ManifestContent -replace "(?m)^(\s*FunctionsToExport\s*=\s*)'.*'", "`$1@('$($FunctionsToExport -join "','")')"
$ManifestContent = $ManifestContent -replace "(?m)^(\s*CmdletsToExport\s*=\s*)'.*'", '$1@()'
$ManifestContent = $ManifestContent -replace "(?m)^(\s*VariablesToExport\s*=\s*)'.*'", '$1@()'
$ManifestContent = $ManifestContent -replace "(?m)^(\s*AliasesToExport\s*=\s*)'.*'", '$1@()'

[System.IO.File]::WriteAllText($ManifestFile, $ManifestContent)

Write-Host "Successfully updated $ManifestFile"
