####################################################################################################
<#
.SYNOPSIS
    This function copies a folder to the user profile.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Deploy-UserProfileFolder -DeploymentObject $DeploymentObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : August 2025
#>
####################################################################################################

function Deploy-UserProfileFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The object containing the needed information')]
        [PSCustomObject]
        $DeploymentObject,

        [Parameter(Mandatory=$false,HelpMessage='The action that will be performed')]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        # Output
        [System.Boolean]$DeploymentSuccess  = $null
        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            $ValidationArrayList.Add((Confirm-Object -MandatoryString $DeploymentObject.FolderToCopy))
            $ValidationArrayList.Add((Confirm-Object -MandatoryString $DeploymentObject.UserProfileLocation -ValidateSet $DeploymentObject.ValidateSetUserProfile))
        }

        function Copy-FolderToUserProfile { param([PSCustomObject]$InputObject,[System.String]$UserName)
            try {
                # Set the destination folder
                [System.String]$UserRootFolder      = ('C:\Users\{0}' -f $UserName)
                [System.String]$DestinationFolder   = switch ($InputObject.UserProfileLocation) {
                    'UserProfile'   { $UserRootFolder }
                    Default         { Join-Path -Path $UserRootFolder -ChildPath ('AppData\{0}' -f $InputObject.UserProfileLocation) }
                }
                # Get the folder to copy
                [System.String]$FolderToCopy = Get-SourceItemPath -FolderName $InputObject.FolderToCopy
                # Test if the folder already exists
                [System.String]$ExistingFolder = Join-Path -Path $DestinationFolder -ChildPath $InputObject.FolderToCopy
                if ((Test-Path -Path $ExistingFolder) -and (-Not($InputObject.OverwriteExistingFolder))) {
                    # Write the message
                    Write-Line ('The folder ({0}) already exists, and the OverwriteExistingFolder boolean has been set to false. The folder ({1}) will not be copied!' -f $ExistingFolder,$InputObject.FolderToCopy) -Type Busy
                } else {
                    # Copy the folder
                    Write-Host ('Copying the folder ({0}) to the destination folder ({1})...' -f $FolderToCopy,$DestinationFolder)
                    Copy-Item -Path $FolderToCopy -Destination $DestinationFolder -Recurse -Force
                }
                # Return true
                $true
            }
            catch {
                # Write the error and return false
                Write-FullError ; $false
            }
        }
    
        function Copy-FolderForAllUsers { param([PSCustomObject]$InputObject)
            try {
                # Get the user folders
                [System.IO.DirectoryInfo[]]$AllUserFolderObjects = Get-ChildItem -Path 'C:\Users' -Directory -Exclude 'Public' -ErrorAction SilentlyContinue
                [System.String[]]$AllUserFolderNames = (Get-ChildItem -Path 'C:\Users' -Directory -Exclude 'Public' -ErrorAction SilentlyContinue).Name
                [System.String[]]$AllUserFolderNames += 'Default'
                foreach($FolderName in $AllUserFolderNames) { Copy-FolderToUserProfile -InputObject $InputObject -UserName $FolderName }
                # Return true
                $true
            }
            catch {
                # Write the error and return false
                Write-FullError ; $false
            }
        }

        ####################################################################################################

        # Validate the input
        Confirm-Input
    }
    
    process {
        # If the validation failed, then return
        if ($ValidationArrayList -contains $false) { Write-Line -Type ValidationFailed $FunctionDetails[0] ; Return }

        # VALIDATION - SUCCESS
        # Write the message
        Write-Line -Type ValidationSuccess

        # Switch on the Action
        $DeploymentSuccess = switch ($Action) {
            'Install'   { Copy-FolderForAllUsers -InputObject $DeploymentObject }
            'Uninstall' { Write-Line 'The method for Uninstall has not been defined yet. The user files will remain' ; $true }
            'Reinstall' { Write-Line 'The method for Reinstall has not been defined yet.' }
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################
