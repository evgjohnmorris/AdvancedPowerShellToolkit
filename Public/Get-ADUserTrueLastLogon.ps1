function Get-ADUserTrueLastLogon {
    <#
    .SYNOPSIS
        Retrieves the true LastLogon time for one or more Active Directory users.

    .DESCRIPTION
        Because the 'LastLogon' attribute is not replicated across Domain Controllers,
        you must query every Domain Controller in the domain to find the most recent
        logon time for a user. This function automates that process.

    .PARAMETER Identity
        Specifies the user to query. You can pass the SamAccountName, DistinguishedName,
        or an ADUser object.

    .PARAMETER DomainControllers
        Optional array of Domain Controller hostnames. If not provided, it will automatically
        discover all Domain Controllers in the current domain.

    .EXAMPLE
        Get-ADUserTrueLastLogon -Identity "jsmith"
        Retrieves the true LastLogon time for the user 'jsmith'.

    .EXAMPLE
        Get-ADGroupMember "Domain Admins" | Get-ADUserTrueLastLogon
        Retrieves the true LastLogon time for all Domain Admins.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('SamAccountName', 'DistinguishedName', 'UserName')]
        [string[]]$Identity,

        [Parameter()]
        [string[]]$DomainControllers
    )

    begin {
        # Require ActiveDirectory module
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        # Discover Domain Controllers if not provided
        if (-not $DomainControllers) {
            Write-Verbose "Discovering all Domain Controllers in the current domain..."
            try {
                $DomainControllers = (Get-ADDomainController -Filter * -ErrorAction Stop).HostName
                Write-Verbose "Found $($DomainControllers.Count) Domain Controllers."
            } catch {
                Write-Error "Failed to discover Domain Controllers. Ensure you are on a domain-joined machine with RSAT installed."
                throw
            }
        }
    }

    process {
        foreach ($User in $Identity) {
            Write-Verbose "Querying true LastLogon for user: $User"
            
            try {
                $ADUser = Get-ADUser -Identity $User -ErrorAction Stop
                
                $LatestLogonTime = 0

                foreach ($DC in $DomainControllers) {
                    Write-Verbose "  -> Checking DC: $DC"
                    try {
                        # We must specify -Server $DC to query the specific Domain Controller
                        $DCUser = Get-ADUser -Identity $ADUser.ObjectGUID -Server $DC -Properties LastLogon -ErrorAction Stop
                        
                        if ($DCUser.LastLogon -gt $LatestLogonTime) {
                            $LatestLogonTime = $DCUser.LastLogon
                        }
                    } catch {
                        Write-Warning "Failed to query Domain Controller $DC for user $User. It may be offline."
                    }
                }

                $LastLogonDate = if ($LatestLogonTime -gt 0) { [DateTime]::FromFileTime($LatestLogonTime) } else { $null }

                [PSCustomObject]@{
                    Name              = $ADUser.Name
                    SamAccountName    = $ADUser.SamAccountName
                    UserPrincipalName = $ADUser.UserPrincipalName
                    Enabled           = $ADUser.Enabled
                    TrueLastLogon     = $LastLogonDate
                }
            } catch {
                Write-Error "Failed to process user '$User'. Error: $_"
            }
        }
    }
}
