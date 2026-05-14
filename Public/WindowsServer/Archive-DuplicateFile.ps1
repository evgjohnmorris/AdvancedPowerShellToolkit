function Archive-DuplicateFile {
    <#
    .SYNOPSIS
        Finds and archives duplicate files based on file name, keeping the newest file.

    .DESCRIPTION
        This advanced function searches a directory recursively for files with the exact same name.
        When duplicates are found, it keeps the file with the most recent LastWriteTime in its
        original location, and moves the older file(s) to a specified archive directory while
        maintaining the folder structure.

    .PARAMETER Path
        The directory to search for duplicate files.

    .PARAMETER ArchivePath
        The destination directory where older duplicate files will be moved.

    .EXAMPLE
        Archive-DuplicateFile -Path "C:\Data" -ArchivePath "C:\Archive\Duplicates"
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )

    begin {
        # Ensure the archive base path exists
        if (-not (Test-Path $ArchivePath)) {
            New-Item -Path $ArchivePath -ItemType Directory -Force | Out-Null
        }
    }

    process {
        foreach ($Dir in $Path) {
            # Use a hashtable to track seen files: @{ "FileName" = @($LastWriteTime, $FullName) }
            $SeenFiles = @{}

            Write-Verbose "Scanning for duplicate files in [$Dir]..."

            # Get all files, excluding the ArchivePath if it happens to be nested
            $Files = Get-ChildItem -Path $Dir -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.FullName -notmatch "^([regex]::Escape($ArchivePath))"
            }

            foreach ($File in $Files) {
                if ($SeenFiles.ContainsKey($File.Name)) {
                    $PreviousLastWriteTime = $SeenFiles[$File.Name][0]
                    $PreviousFullName      = $SeenFiles[$File.Name][1]

                    $FileToArchive = $null
                    $FileToKeep    = $null

                    if ($File.LastWriteTime -gt $PreviousLastWriteTime) {
                        # The current file is newer, so archive the previously seen (older) file
                        $FileToArchive = $PreviousFullName
                        $FileToKeep    = $File.FullName
                        
                        # Update the hashtable to track the newer file going forward
                        $SeenFiles[$File.Name][0] = $File.LastWriteTime
                        $SeenFiles[$File.Name][1] = $File.FullName
                    } else {
                        # The previously seen file is newer (or same age), so archive the current file
                        $FileToArchive = $File.FullName
                        $FileToKeep    = $PreviousFullName
                    }

                    # Determine destination path maintaining original tree structure relative to $Dir
                    $RelativePath = $FileToArchive.Substring($Dir.Length).TrimStart('\')
                    $Destination  = Join-Path -Path $ArchivePath -ChildPath $RelativePath
                    $DestinationDir = Split-Path $Destination -Parent

                    if ($pscmdlet.ShouldProcess($FileToArchive, "Archive older duplicate to $Destination")) {
                        try {
                            if (-not (Test-Path $DestinationDir)) {
                                New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null
                            }
                            Move-Item -Path $FileToArchive -Destination $Destination -Force

                            # Output an object detailing the action
                            [PSCustomObject]@{
                                FileName      = $File.Name
                                KeptFile      = $FileToKeep
                                ArchivedFile  = $Destination
                                Status        = 'Archived'
                            }
                        } catch {
                            Write-Error "Failed to archive [$FileToArchive]. $_"
                            [PSCustomObject]@{
                                FileName      = $File.Name
                                KeptFile      = $FileToKeep
                                ArchivedFile  = $FileToArchive
                                Status        = "Error: $($_.Exception.Message)"
                            }
                        }
                    }
                } else {
                    # First time seeing this file name
                    $SeenFiles.Add($File.Name, @($File.LastWriteTime, $File.FullName))
                }
            }
        }
    }
}
