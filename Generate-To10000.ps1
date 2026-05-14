$PublicPath = Join-Path $PSScriptRoot "Public"
$DocsPath = Join-Path $PSScriptRoot "Docs"
$TaskFile = "C:\Users\johna\.gemini\antigravity\brain\e35f20ce-a832-4a83-a065-4b315fa16530\task.md"

if (-not (Test-Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath | Out-Null
}

$Verbs = @("Get", "Set", "New", "Remove", "Invoke")

# Define existing 20 categories, and give them Prefix and Suffix parts to generate 46 nouns each
$Generators = @{
    "ActiveDirectory" = @{ Prefixes = "AdUser","AdGroup","AdComputer","AdDomain","AdForest","AdSite","AdTrust","AdPolicy","AdCert","AdSchema"; Suffixes = "Config","Settings","Metadata","Stats","Log","Report","Audit","Profile","Sync","Mapping" }
    "Azure" = @{ Prefixes = "AzVm","AzVnet","AzStorage","AzSql","AzCosmos","AzKeyVault","AzAppSvc","AzFunc","AzAks","AzMonitor"; Suffixes = "Quota","Metric","Alert","Tag","Lock","Backup","Restore","Diagnostics","Scaling","Routing" }
    "ExchangeM365" = @{ Prefixes = "M365Mailbox","M365Group","M365Teams","M365SharePoint","M365OneDrive","M365Security","M365Compliance","M365Search","M365Audit","M365Admin"; Suffixes = "Policy","Rule","Setting","Filter","Connector","Endpoint","Log","Report","License","Quota" }
    "WindowsServer" = @{ Prefixes = "WinService","WinProcess","WinEvent","WinDisk","WinMemory","WinCpu","WinNetwork","WinFirewall","WinRegistry","WinTask"; Suffixes = "Monitor","Config","State","Dump","Trace","Log","Metric","Profile","Quota","Limit" }
    "SCCMIntune" = @{ Prefixes = "CmApp","CmUpdate","CmDevice","CmUser","CmCollection","IntuneApp","IntunePolicy","IntuneProfile","IntuneDevice","IntuneUser"; Suffixes = "Deployment","Assignment","Status","Report","Compliance","Inventory","Log","Setting","Sync","Metadata" }
    "NetworkingSecurity" = @{ Prefixes = "NetFirewall","NetRouter","NetSwitch","NetVlan","NetVpn","NetIpsec","SecDefender","SecAntivirus","SecFirewall","SecAudit"; Suffixes = "Rule","Policy","Log","State","Config","Metric","Alert","Event","Status","Report" }
    "Databases" = @{ Prefixes = "SqlDb","SqlTable","SqlIndex","SqlView","SqlProc","SqlUser","SqlRole","SqlBackup","SqlRestore","SqlLog"; Suffixes = "Stats","Size","Usage","Config","State","Metric","Report","Audit","Permission","Mapping" }
    "DevOps" = @{ Prefixes = "GitRepo","GitCommit","GitPr","DockerImage","DockerContainer","K8sPod","K8sService","K8sDeploy","JenkinsJob","TerraformState"; Suffixes = "Config","Log","Status","Metric","Action","Trigger","Event","Report","Audit","Tag" }
    "SharePointTeams" = @{ Prefixes = "SpoSite","SpoList","SpoLibrary","SpoItem","SpoFile","TeamsChannel","TeamsChat","TeamsMeeting","TeamsUser","TeamsApp"; Suffixes = "Perms","Config","Log","Usage","Report","Stats","Metadata","Setting","Quota","Limit" }
    "VMwareAWS" = @{ Prefixes = "VmwareVm","VmwareHost","VmwareDatastore","VmwareNetwork","VmwareCluster","AwsEc2","AwsS3","AwsRds","AwsVpc","AwsIam"; Suffixes = "Config","Metric","Log","Status","Report","Tag","Alert","Quota","Billing","Usage" }
    "MicrosoftGraph" = @{ Prefixes = "GraphUser","GraphGroup","GraphDevice","GraphMail","GraphEvent","GraphDrive","GraphSite","GraphTeam","GraphChannel","GraphChat"; Suffixes = "Delta","Export","Sync","Stats","Metadata","Log","Query","Report","Filter","Tag" }
    "PowerPlatform" = @{ Prefixes = "PowerApp","PowerFlow","PowerBi","PowerPages","DataverseTable","DataverseCol","DataverseRow","DataverseForm","DataverseView","DataverseChart"; Suffixes = "Config","Export","Import","Usage","Log","State","Perms","Owner","Quota","Metric" }
    "VDIAndRDS" = @{ Prefixes = "CitrixApp","CitrixDesktop","CitrixSession","CitrixUser","CitrixServer","RdsApp","RdsDesktop","RdsSession","RdsUser","RdsServer"; Suffixes = "Metric","Log","State","Config","Report","License","Quota","Profile","Trace","Stats" }
    "LinuxUnix" = @{ Prefixes = "LinuxUser","LinuxGroup","LinuxFile","LinuxDir","LinuxProcess","LinuxService","LinuxNetwork","LinuxDisk","LinuxMemory","LinuxCpu"; Suffixes = "Config","State","Log","Metric","Dump","Trace","Stats","Limit","Quota","Profile" }
    "CyberSecurity" = @{ Prefixes = "SiemAlert","SiemEvent","SiemRule","EdrAgent","EdrAlert","EdrRule","VulnScan","VulnReport","VulnAsset","VulnCve"; Suffixes = "Status","Log","Config","Action","Trigger","Metric","Severity","Tag","Owner","Metadata" }
    "CloudNative" = @{ Prefixes = "HelmChart","HelmRelease","PromMetric","PromAlert","GrafanaDash","GrafanaSource","ArgoApp","IstioSvc","EnvoyProxy","CertManager"; Suffixes = "Config","Log","State","Status","Deploy","Metric","Rule","Policy","Tag","Report" }
    "BackupDisasterRecovery" = @{ Prefixes = "VeeamJob","VeeamVm","VeeamServer","CommvaultJob","CommvaultVm","CommvaultServer","RubrikJob","RubrikVm","ZertoVpg","ZertoSite"; Suffixes = "Log","Status","Report","State","Config","Metric","Alert","Event","Usage","Stats" }
    "IdentityAccessManagement" = @{ Prefixes = "OktaUser","OktaGroup","OktaApp","PingUser","PingApp","Auth0User","Auth0App","CyberArkSafe","CyberArkUser","SailPointIdentity"; Suffixes = "Log","State","Config","Policy","Rule","Event","Alert","Report","Stats","Metadata" }
    "NetworkInfrastructure" = @{ Prefixes = "CiscoInterface","CiscoVlan","CiscoOspf","PaloAltoRule","PaloAltoNat","FortinetPol","FortinetRoute","F5Virtual","F5Pool","F5Profile"; Suffixes = "Config","State","Log","Metric","Status","Report","Tag","Alert","Event","Usage" }
    "EndUserComputing" = @{ Prefixes = "JamfDevice","JamfPolicy","JamfProfile","WvdPool","WvdSession","WvdUser","SotiDevice","SotiRule","WsOneDevice","WsOneProfile"; Suffixes = "Status","Log","Config","State","Report","Metric","Usage","Tag","Alert","Event" }
}

Write-Host "Generating remaining tools to hit 10,000 total..."

foreach ($cat in $Generators.Keys) {
    $catPath = Join-Path $PublicPath $cat
    if (-not (Test-Path $catPath)) {
        New-Item -ItemType Directory -Path $catPath | Out-Null
    }
    
    $prefixes = $Generators[$cat].Prefixes
    $suffixes = $Generators[$cat].Suffixes
    
    $count = 0
    foreach ($p in $prefixes) {
        foreach ($s in $suffixes) {
            $noun = "$p$s"
            foreach ($verb in $Verbs) {
                $tool = "$verb-$noun"
                $filePath = Join-Path $catPath "$tool.ps1"
                
                if (-not (Test-Path $filePath)) {
                    $content = @"
function $tool {
<#
.SYNOPSIS
    Stub function for $tool.
.DESCRIPTION
    This function was automatically generated as part of the massive 10,000-tool scale-out process.
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
                }
            }
            $count++
        }
    }
}

Write-Host "Updating Distributed Documentation..."

$MasterTaskContent = @(
    "# Advanced PowerShell Toolkit: 10,000-Tool Master Roadmap",
    "",
    "The tracking for these tools has been distributed into category-specific files in the `Docs/` directory due to the massive scale of the module.",
    ""
)

$allScripts = Get-ChildItem -Path $PublicPath -Filter "*.ps1" -Recurse | Sort-Object Name
$groupedScripts = $allScripts | Group-Object { Split-Path $_.Directory.Name -Leaf } | Sort-Object Name

foreach ($group in $groupedScripts) {
    $catName = $group.Name
    $docPath = Join-Path $DocsPath "Tasks-$catName.md"
    
    $MasterTaskContent += "- [Tasks: $catName (Count: $($group.Count))](./Docs/Tasks-$catName.md)"
    
    $CatTaskContent = @(
        "# Tasks: $catName",
        "",
        "## Fully Implemented"
    )
    
    $Implemented = @()
    $Stubs = @()
    
    foreach ($script in $group.Group) {
        $text = Get-Content $script.FullName -Raw
        if ($text -match "'Not Implemented'") {
            $Stubs += $script
        } else {
            $Implemented += $script
        }
    }
    
    foreach ($imp in $Implemented) {
        $CatTaskContent += "- [x] ``$($imp.Name)``"
    }
    
    $CatTaskContent += ""
    $CatTaskContent += "## Stubs"
    foreach ($stub in $Stubs) {
        $CatTaskContent += "- [ ] ``$($stub.Name)``"
    }
    
    Set-Content -Path $docPath -Value $CatTaskContent
}

Set-Content -Path $TaskFile -Value $MasterTaskContent
Write-Host "Massive Scale-Out Phase 7 Complete. Now tracking over 10,000 tools!"
