function Get-CMDeploymentSummary {
    <#
    .SYNOPSIS
        Retrieves SCCM deployment summary statistics for a given collection.

    .DESCRIPTION
        This advanced function connects to an SCCM Primary Site server, triggers a deployment
        summarization for a specific collection, and returns the success rate of the deployment.

    .PARAMETER CollectionName
        The name of the SCCM collection to query.

    .PARAMETER SiteServer
        The hostname of the SCCM Primary Site server.

    .PARAMETER SiteCode
        The 3-character site code of the SCCM environment.

    .EXAMPLE
        Get-CMDeploymentSummary -CollectionName "All Windows 10 Devices" -SiteServer "SCCM01" -SiteCode "PS1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3,3)]
        [string]$SiteCode
    )

    process {
        try {
            Write-Verbose "Connecting to SCCM Site Server: $SiteServer ($SiteCode)"
            
            $ScriptBlock = {
                param($CollectionName, $SiteCode)

                # Assume the ConfigurationManager module is installed in the default location or available in PSModulePath
                if (-not (Get-Module ConfigurationManager)) {
                    $ConfigMgrModulePath = "$($env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
                    if (Test-Path $ConfigMgrModulePath) {
                        Import-Module $ConfigMgrModulePath
                    } else {
                        throw "ConfigurationManager module not found on the site server."
                    }
                }

                $SiteDrive = "${SiteCode}:"
                if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
                    throw "SCCM Site Drive $SiteDrive not found."
                }

                Set-Location $SiteDrive -ErrorAction Stop
                
                Write-Verbose "Triggering Summarization for $CollectionName"
                Invoke-CMDeploymentSummarization -CollectionName $CollectionName -ErrorAction SilentlyContinue
                
                # Sleep briefly to allow summarization to process
                Start-Sleep -Seconds 10
                
                Get-CMDeployment -CollectionName $CollectionName | Select-Object ApplicationName, NumberSuccess, NumberTargeted, SummarizationTime
            }

            $Deployments = Invoke-Command -ComputerName $SiteServer -ScriptBlock $ScriptBlock -ArgumentList $CollectionName, $SiteCode -ErrorAction Stop

            foreach ($Dep in $Deployments) {
                $SuccessRate = 0
                if ($Dep.NumberTargeted -gt 0) {
                    $SuccessRate = $Dep.NumberSuccess / $Dep.NumberTargeted
                }

                [PSCustomObject]@{
                    CollectionName    = $CollectionName
                    ApplicationName   = $Dep.ApplicationName
                    Targeted          = $Dep.NumberTargeted
                    Success           = $Dep.NumberSuccess
                    SuccessRatePct    = "{0:P2}" -f $SuccessRate
                    SummarizationTime = $Dep.SummarizationTime
                }
            }

        } catch {
            Write-Error "Failed to retrieve CM Deployment Summary for $CollectionName : $_"
        }
    }
}
