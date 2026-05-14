$PublicPath = Join-Path $PSScriptRoot "Public"
$TaskFile = "C:\Users\johna\.gemini\antigravity\brain\52d269ef-589f-4f86-9a56-bda365825a15\task.md"

# Define Categories and their mapping
$Categories = @(
    "ActiveDirectory", "Windows", "FileAndStorage", "Exchange", 
    "M365", "SCCM", "Intune", "Network", "Security", "IIS", "Azure", 
    "Utilities", "Teams", "VMware", "GroupPolicy", "RemoteDesktop", 
    "SharePoint", "SQLServer", "AWS", "HyperV", "LinuxWSL", "GraphAPI", 
    "OfficeDesktop", "DevOps", "DiskManagement", "EventLogs", "PrintServer", "SCOM", "Uncategorized"
)

# Create category folders
foreach ($cat in $Categories) {
    $catPath = Join-Path $PublicPath $cat
    if (-not (Test-Path $catPath)) {
        New-Item -ItemType Directory -Path $catPath | Out-Null
    }
}

# Function to determine category from filename
function Get-Category ($Name) {
    if ($Name -match "AD|User|GroupMember|GPO|Password") { return "ActiveDirectory" }
    if ($Name -match "EXO|Mailbox|MessageTrace") { return "Exchange" }
    if ($Name -match "M365|Teams|SharePoint|SPO|OneDrive") {
        if ($Name -match "Teams") { return "Teams" }
        if ($Name -match "SPO|SharePoint|OneDrive") { return "SharePoint" }
        return "M365"
    }
    if ($Name -match "CMDeployment|CMClient|CMMobile|CMApplication|CMDevice|CMEndpoint|CMTaskSequence") { return "SCCM" }
    if ($Name -match "Intune") { return "Intune" }
    if ($Name -match "File|Folder|Directory|Cabinet|SmbShare|Disk") { return "FileAndStorage" }
    if ($Name -match "Network|Dns|Dhcp|Vpn|Radius|Ipsec") { return "Network" }
    if ($Name -match "Security|Defender|Audit|Certificate|Laps|Credential|AppLocker|Cleartext|Adcs") { return "Security" }
    if ($Name -match "IIS") { return "IIS" }
    if ($Name -match "Az|Azure") { return "Azure" }
    if ($Name -match "AWS") { return "AWS" }
    if ($Name -match "VMware") { return "VMware" }
    if ($Name -match "RDS|Citrix") { return "RemoteDesktop" }
    if ($Name -match "Sql") { return "SQLServer" }
    if ($Name -match "HyperV|VMGuest|VHD") { return "HyperV" }
    if ($Name -match "Linux|Wsl") { return "LinuxWSL" }
    if ($Name -match "Graph") { return "GraphAPI" }
    if ($Name -match "Office|ClickToRun") { return "OfficeDesktop" }
    if ($Name -match "GitHub|Docker|Jenkins|DevOps") { return "DevOps" }
    if ($Name -match "Event|Log") { return "EventLogs" }
    if ($Name -match "Printer|Print") { return "PrintServer" }
    if ($Name -match "SCOM") { return "SCOM" }
    if ($Name -match "Windows") { return "Windows" }
    return "Utilities"
}

# 1. Reorganize existing tools
Write-Host "Reorganizing existing tools..."
Get-ChildItem -Path $PublicPath -Filter "*.ps1" -File | ForEach-Object {
    $cat = Get-Category $_.BaseName
    $dest = Join-Path $PublicPath $cat
    Move-Item -Path $_.FullName -Destination $dest -Force
}

# 2. Phase 4 Tools (100)
$Phase4Tools = @(
    # Hyper-V (10)
    "Get-VMReplicationStatus", "Set-VMReplication", "Test-VMReplication", "Start-VMInitialReplication", "Get-VMSwitch", "New-VMSwitch", "Remove-VMSwitch", "Get-VMNetworkAdapter", "Set-VMNetworkAdapterVlan", "Get-VMMemory",
    # Linux & WSL (10)
    "Get-WslDistribution", "Start-WslDistribution", "Stop-WslDistribution", "Restart-WslDistribution", "Set-WslDefaultDistribution", "Export-WslDistribution", "Import-WslDistribution", "Invoke-WslCommand", "Update-WslKernel", "Get-WslStatus",
    # Microsoft Graph API (10)
    "Connect-GraphApiAuto", "Get-GraphUser", "Get-GraphGroup", "Get-GraphApplication", "Get-GraphDevice", "Invoke-GraphApiRequest", "Get-GraphSubscribedSku", "Get-GraphOrganization", "Get-GraphConditionalAccessPolicy", "Set-GraphConditionalAccessPolicy",
    # Office Desktop (10)
    "Get-OfficeClickToRunConfig", "Set-OfficeClickToRunConfig", "Update-OfficeDesktopApp", "Get-OfficeAddin", "Set-OfficeAddinState", "Remove-OfficeAddin", "Get-OfficeTelemetryState", "Set-OfficeTelemetryState", "Test-OfficeLicenseActivation", "Invoke-OfficeRepair",
    # CI/CD & DevOps (10)
    "Invoke-GitHubAction", "Get-GitHubRepository", "Set-GitHubRepositorySecret", "Get-DockerContainerStatus", "Start-DockerContainer", "Stop-DockerContainer", "Restart-DockerContainer", "Get-DockerImage", "Remove-DockerImage", "Invoke-DockerBuild",
    # Advanced Disk & Partition Management (10)
    "Get-DiskPartitionInfo", "Resize-DiskPartition", "Clear-DiskPartition", "Format-DiskVolume", "Get-DiskVolumeHealth", "Set-DiskVolumeLabel", "Optimize-DiskVolume", "Get-PhysicalDiskHealth", "Reset-PhysicalDisk", "Update-StoragePool",
    # Windows Event Forwarding & Logs (10)
    "Get-WefSubscription", "Set-WefSubscription", "Test-WefSubscription", "Get-WeffForwarderStatus", "Enable-WefService", "Disable-WefService", "Get-EventLogSource", "New-EventLogSource", "Remove-EventLogSource", "Clear-AllEventLogs",
    # Print Server & Document Management (10)
    "Get-PrintServerSpooler", "Restart-PrintServerSpooler", "Get-PrintJobSummary", "Remove-PrintJob", "Suspend-PrintJob", "Resume-PrintJob", "Get-PrinterDriverInfo", "Add-PrinterDriver", "Remove-PrinterDriver", "Set-PrinterProperty",
    # System Center Operations Manager (SCOM) (10)
    "Get-ScomAgentStatus", "Restart-ScomAgent", "Get-ScomAlertSummary", "Resolve-ScomAlert", "Get-ScomMaintenanceMode", "Set-ScomMaintenanceMode", "Remove-ScomMaintenanceMode", "Get-ScomManagementPack", "Import-ScomManagementPack", "Export-ScomManagementPack",
    # Advanced Security (10)
    "Get-WindowsAppLockerRule", "Set-WindowsAppLockerRule", "Get-WindowsCredentialGuard", "Enable-WindowsCredentialGuard", "Disable-WindowsCredentialGuard", "Get-WindowsAttackSurfaceReduction", "Set-WindowsAttackSurfaceReduction", "Get-WindowsExploitGuard", "Set-WindowsExploitGuard", "Test-WindowsSecurityBaseline"
)

Write-Host "Generating Phase 4 tools..."
foreach ($tool in $Phase4Tools) {
    $cat = Get-Category $tool
    $filePath = Join-Path $PublicPath $cat "$tool.ps1"
    
    if (-not (Test-Path $filePath)) {
        $content = @"
function $tool {
<#
.SYNOPSIS
    Stub function for $tool.
.DESCRIPTION
    This function was automatically generated as part of the Phase 4 400-tool scale-out process.
    Implementation details pending.
.PARAMETER ExampleParam
    Placeholder parameter.
.EXAMPLE
    $tool
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = `$false)]
        [string]`$ExampleParam
    )

    begin {
        Write-Verbose "Starting `$(`$MyInvocation.MyCommand.Name)..."
    }
    process {
        if (`$PSCmdlet.ShouldProcess("TargetItem", "ActionDetails")) {
            [PSCustomObject]@{
                ToolName = `$MyInvocation.MyCommand.Name
                Status = 'Not Implemented'
            }
        }
    }
    end {
        Write-Verbose "Completed `$(`$MyInvocation.MyCommand.Name)."
    }
}
"@
        Set-Content -Path $filePath -Value $content
        Write-Host "Created: $tool.ps1 in $cat" -ForegroundColor Green
    }
}

# 3. Update task.md
Write-Host "Updating task.md..."
$TaskContent = @(
    "# Advanced PowerShell Toolkit: 400-Tool Roadmap",
    ""
)

# Read all files from categories to rebuild task list accurately
$allScripts = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -Recurse

# Separate Implemented from Stubs by looking for 'Not Implemented' string
$Implemented = @()
$Stubs = @()

foreach ($script in $allScripts) {
    $text = Get-Content $script.FullName -Raw
    if ($text -match "'Not Implemented'") {
        $Stubs += $script
    } else {
        $Implemented += $script
    }
}

$TaskContent += "## Fully Implemented ($($Implemented.Count))"
foreach ($imp in $Implemented | Sort-Object Name) {
    $TaskContent += "- `[x`] `$($imp.Name)`"
}
$TaskContent += ""
$TaskContent += "## Stubs ($($Stubs.Count))"

# Group stubs by category
$groupedStubs = $Stubs | Group-Object { Split-Path $_.Directory.Name -Leaf } | Sort-Object Name

foreach ($group in $groupedStubs) {
    $TaskContent += "### $($group.Name) ($($group.Count))"
    foreach ($stub in $group.Group | Sort-Object Name) {
        $TaskContent += "- `[ `] `$($stub.Name)`"
    }
    $TaskContent += ""
}

Set-Content -Path $TaskFile -Value $TaskContent
Write-Host "Done!"
