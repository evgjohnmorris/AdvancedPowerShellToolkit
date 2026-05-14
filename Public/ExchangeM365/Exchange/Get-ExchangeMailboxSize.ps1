function Get-ExchangeMailboxSize {
    <#
    .SYNOPSIS
        Retrieves the mailbox size and statistics for Exchange Online mailboxes.

    .DESCRIPTION
        This advanced function connects to Exchange Online (if not already connected)
        and retrieves mailbox statistics such as item count, storage limit status,
        and total item size in MB. It outputs PSCustomObjects instead of CSV files
        for better pipeline integration.

    .PARAMETER Identity
        Optional. Specifies a specific mailbox to query. If omitted, queries all mailboxes.

    .PARAMETER ResultSize
        The maximum number of mailboxes to return. Defaults to 'Unlimited'.

    .EXAMPLE
        Get-ExchangeMailboxSize -ResultSize 10
        Retrieves the sizes of 10 mailboxes.

    .EXAMPLE
        Get-ExchangeMailboxSize -Identity "user@domain.com"
        Retrieves the size of a specific mailbox.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Identity,

        [Parameter(Mandatory = $false)]
        [string]$ResultSize = 'Unlimited'
    )

    begin {
        # Check if ExchangeOnlineManagement module is available/loaded
        if (-not (Get-Command Get-EXOMailbox -ErrorAction SilentlyContinue)) {
            Write-Verbose "ExchangeOnline cmdlets not found. Attempting to load ExchangeOnlineManagement."
            if (-not (Get-Module -ListAvailable ExchangeOnlineManagement)) {
                throw "ExchangeOnlineManagement module is not installed. Please install it using 'Install-Module ExchangeOnlineManagement'."
            }
            Import-Module ExchangeOnlineManagement
        }

        # Prompt for connection if not connected
        if (-not (Get-PSSession | Where-Object ConfigurationName -match 'Exchange')) {
            Write-Verbose "Not connected to Exchange Online. Please run Connect-ExchangeOnline first."
            # Optionally we could run Connect-ExchangeOnline here, but best practice is to let the user manage authentication outside the tool
            # For ease of use, we'll try to connect if they haven't:
            try {
                Connect-ExchangeOnline -ShowProgress $true
            } catch {
                throw "Failed to connect to Exchange Online. $_"
            }
        }
    }

    process {
        try {
            $MailboxParams = @{
                ResultSize = $ResultSize
            }
            if ($PSBoundParameters.ContainsKey('Identity') -and $Identity) {
                $MailboxParams.Identity = $Identity
            }

            Write-Verbose "Querying mailboxes..."
            $Mailboxes = Get-EXOMailbox @MailboxParams -ErrorAction Stop

            foreach ($Mailbox in $Mailboxes) {
                Write-Verbose "Getting statistics for $($Mailbox.UserPrincipalName)..."
                $Stats = Get-EXOMailboxStatistics -Identity $Mailbox.UserPrincipalName -ErrorAction SilentlyContinue
                
                if ($Stats) {
                    $SizeMB = 0
                    if ($Stats.TotalItemSize) {
                        # TotalItemSize is often returned as a string like "1.23 GB (1,320,000 bytes)"
                        # Using RegEx to extract the byte value safely
                        if ($Stats.TotalItemSize.ToString() -match '\((?<bytes>[\d,]+)\s+bytes\)') {
                            $Bytes = $matches['bytes'] -replace ','
                            $SizeMB = [math]::Round([double]$Bytes / 1MB, 2)
                        }
                    }

                    [PSCustomObject]@{
                        DisplayName        = $Mailbox.DisplayName
                        UserPrincipalName  = $Mailbox.UserPrincipalName
                        ItemCount          = $Stats.ItemCount
                        TotalItemSizeMB    = $SizeMB
                        StorageLimitStatus = $Stats.StorageLimitStatus
                    }
                }
            }
        } catch {
            Write-Error "Failed to retrieve mailbox statistics: $_"
        }
    }
}
