function Get-DirectoryLargerThan {
    <#
    .SYNOPSIS
        Finds directories that exceed a specified size threshold.

    .DESCRIPTION
        This advanced function recursively measures the total size of files within
        top-level child directories of a specified path, and returns those that
        exceed the given size threshold.

    .PARAMETER Path
        The root directory to inspect. The function will evaluate the immediate child directories of this path.

    .PARAMETER SizeThreshold
        The minimum size required for a directory to be included in the output. Accepts byte sizes like 1GB, 500MB, etc.

    .EXAMPLE
        Get-DirectoryLargerThan -Path "\\server\users" -SizeThreshold 5GB
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [long]$SizeThreshold
    )

    begin {
        function Format-Size {
            param ([long]$Size)
            if ($Size -ge 1GB) {
                "{0:N2} GB" -f ($Size / 1GB)
            } elseif ($Size -ge 1MB) {
                "{0:N2} MB" -f ($Size / 1MB)
            } else {
                "{0:N2} KB" -f ($Size / 1KB)
            }
        }
    }

    process {
        foreach ($Directory in $Path) {
            Write-Verbose "Analyzing child directories in [$Directory]"

            $ChildDirectories = Get-ChildItem -Path $Directory -Directory -ErrorAction SilentlyContinue

            foreach ($Child in $ChildDirectories) {
                Write-Verbose "Measuring [$($Child.FullName)]..."
                
                # Measure the total size of files inside this child directory recursively
                $Files = Get-ChildItem -Path $Child.FullName -File -Recurse -Force -ErrorAction SilentlyContinue
                if ($Files) {
                    $SumObj = $Files | Measure-Object -Property Length -Sum
                    $TotalSize = [long]$SumObj.Sum
                    
                    if ($TotalSize -gt $SizeThreshold) {
                        [PSCustomObject]@{
                            DirectoryName = $Child.Name
                            Path          = $Child.FullName
                            SizeBytes     = $TotalSize
                            SizeFormatted = Format-Size -Size $TotalSize
                        }
                    }
                }
            }
        }
    }
}
