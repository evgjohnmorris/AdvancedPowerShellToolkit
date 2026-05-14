$PublicPath = Join-Path $PSScriptRoot "Public"
$PrivatePath = Join-Path $PSScriptRoot "Private"

function Get-Subcategory {
    param([string]$BaseName)
    
    # Extract Noun
    $Noun = $BaseName -replace '^[A-Za-z]+-', ''
    
    if ($Noun -match 'User|Account|Profile|Session|Manager') { return "Users" }
    if ($Noun -match 'Group') { return "Groups" }
    if ($Noun -match 'Computer|Device|Server|Machine') { return "Devices" }
    if ($Noun -match 'Cert|PKI|Adcs') { return "Certificates" }
    if ($Noun -match 'Domain|Forest|Trust|Site|Schema|Topology|Replication|FSMO|OU|OrganizationalUnit|Tenant') { return "Infrastructure" }
    if ($Noun -match 'Policy|GPO|GPP') { return "Policies" }
    if ($Noun -match 'Mailbox|Message|Mail|Exo') { return "Exchange" }
    if ($Noun -match 'Network|Dns|Dhcp|Ip|Route|Port|Radius|Subnet|Vlan') { return "Networking" }
    if ($Noun -match 'Security|AppLocker|Defender|Laps|Credential|Password|Audit|Cleartext|Privilege|AttackSurface|ExploitGuard|Baseline|Secret') { return "Security" }
    if ($Noun -match 'Disk|Volume|Storage|Partition|Pool') { return "Storage" }
    if ($Noun -match 'Database|Sql') { return "Databases" }
    if ($Noun -match 'App|Application|Software|Package|Addin|ClickToRun') { return "Applications" }
    if ($Noun -match 'Event|Log|Wef|Telemetry') { return "Logging" }
    if ($Noun -match 'VM|VirtualMachine|HyperV') { return "Virtualization" }
    if ($Noun -match 'Docker|Container|Image') { return "Containers" }
    if ($Noun -match 'Print|Printer|Spooler') { return "Printing" }
    if ($Noun -match 'Graph|Api|Request') { return "API" }
    if ($Noun -match 'GitHub|Action|Repository') { return "DevOps" }
    if ($Noun -match 'Wsl|Linux|Distribution|Kernel') { return "Linux" }
    if ($Noun -match 'Scom|Alert|MaintenanceMode|ManagementPack|Agent') { return "Monitoring" }
    if ($Noun -match 'Registry|Hive') { return "Registry" }
    
    # Fallback to the first capitalized word block of the Noun
    if ($Noun -match '^([A-Z]+[a-z]*|[A-Z][a-z]+)') {
        return $Matches[1]
    }
    
    return "Miscellaneous"
}

function Reorganize-Folder {
    param([string]$TargetFolder)
    
    if (-not (Test-Path $TargetFolder)) { return }
    
    Write-Host "Reorganizing $TargetFolder..."
    
    # Get all category directories
    $Categories = Get-ChildItem -Path $TargetFolder -Directory
    
    foreach ($Cat in $Categories) {
        $Files = Get-ChildItem -Path $Cat.FullName -Filter "*.ps1" -File
        foreach ($File in $Files) {
            $SubCat = Get-Subcategory -BaseName $File.BaseName
            $SubCatPath = Join-Path $Cat.FullName $SubCat
            
            if (-not (Test-Path $SubCatPath)) {
                New-Item -ItemType Directory -Path $SubCatPath | Out-Null
            }
            
            Move-Item -Path $File.FullName -Destination $SubCatPath -Force
        }
        
        # Output progress
        Write-Host "Processed $($Cat.Name) - Moved $($Files.Count) files into subcategories."
    }
}

Reorganize-Folder -TargetFolder $PublicPath
Reorganize-Folder -TargetFolder $PrivatePath

Write-Host "Subcategories created and populated successfully!"
