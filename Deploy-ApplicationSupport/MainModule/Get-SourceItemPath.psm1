####################################################################################################
<#
.SYNOPSIS
    This function searches a file or folder, in the sourcefiles folder, and returns the full path.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Get-SourceItemPath -SearchPath 'C:\Program Files' -FileName 'MyApplicationFile.exe'
.EXAMPLE
    Get-SourceItemPath -FolderName 'FolderThatWillBeCopied'
.INPUTS
    [System.String]
.OUTPUTS
    [System.String]
.NOTES
    Version         : 5.6
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : December 2025
#>
####################################################################################################

function Get-SourceItemPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='FindFilePath',HelpMessage='The name of the file, of which the full path will be obtained.')]
        [System.String]
        $FileName,

        [Parameter(Mandatory=$true,ParameterSetName='FindFolderPath',HelpMessage='The name of the folder, of which the full path will be obtained.')]
        [System.String]
        $FolderName,

        [Parameter(Mandatory=$false,HelpMessage='The folder that will be searched.')]
        [System.String]
        $SearchPath = $Global:DeploymentObject.SourceFilesFolder
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String]$ParameterSetName    = $PSCmdlet.ParameterSetName

        # Input
        [System.String]$FolderToSearch      = $SearchPath

        [System.String]$ItemToFind          = switch ($ParameterSetName) {
            'FindFilePath'                  { $FileName }
            'FindFolderPath'                { $FolderName }
        }

        [System.String]$ItemType            = switch ($ParameterSetName) {
            'FindFilePath'                  { 'file' }
            'FindFolderPath'                { 'folder' }
        }

        # Output
        [System.String]$SourceItemPath      = [System.String]::Empty


        ####################################################################################################
    }
    
    process {
        # EXECUTION
        # Search the item in the SearchPath
        $SourceItemPath = try {
            Write-Line "Searching for the $ItemType ($ItemToFind) in the folder ($FolderToSearch) and all subfolders..."
            switch ($ParameterSetName) {
                'FindFilePath' {
                    [System.IO.FileInfo[]]$FoundItemObjects = Get-ChildItem -Path $FolderToSearch -Recurse -File -Filter $ItemToFind -ErrorAction SilentlyContinue
                }
                'FindFolderPath' {
                    [System.IO.DirectoryInfo[]]$FoundItemObjects = Get-ChildItem -Path $FolderToSearch -Recurse -Directory -Filter $ItemToFind -ErrorAction SilentlyContinue
                }
            }
            # Switch on the amount of found items
            switch ($FoundItemObjects.Count) {
                {$_ -eq 0} {
                    # Write the message
                    Write-Line "The $ItemType ($ItemToFind) was not found in the folder ($FolderToSearch) or any subfolders." -Type Fail
                }
                {$_ -eq 1} {
                    # If 1 was found, then return the full path
                    [System.String]$FirstItemPath = $FoundItemObjects[0].FullName
                    Write-Line "The $ItemType was found. The full path is: ($FirstItemPath)'"
                    $FirstItemPath
                }
                {$_ -gt 1} {
                    # If multiple items were found, then write the message
                    Write-Line "Multiple items with the name ($ItemToFind) were found. Please make sure the item is unique." -Type Fail
                }
            }
        }
        catch {
            Write-FullError
        }
    }
    
    end {
        # Return the output
        $SourceItemPath
    }
}

### END OF SCRIPT
####################################################################################################
