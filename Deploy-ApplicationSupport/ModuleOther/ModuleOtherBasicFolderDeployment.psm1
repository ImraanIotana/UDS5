####################################################################################################
<#
.SYNOPSIS
    This function deploys a folder, in a folder on the local system, for example C:\Program Files.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-BasicFolderDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Start-BasicFolderDeployment {
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

        # Handlers
        [System.String]$ApplicationID       = $Global:DeploymentObject.ApplicationID
        # Output
        [System.Boolean]$DeploymentSuccess  = $null

        ####################################################################################################
    }
    
    process {
        # VALIDATION
        # Validate the FolderToCopy
        if (Test-String -IsEmpty $DeploymentObject.FolderToCopy) { Write-Line "The FolderToCopy string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }
        [System.String]$FolderPath = Get-SourceItemPath -FolderName $DeploymentObject.FolderToCopy
        if (-Not($FolderPath)) { Write-Line -Type ValidationFail ; Return }

        # Validate the DestinationParentFolder
        if (Test-String -IsEmpty $DeploymentObject.DestinationParentFolder) { Write-Line "The DestinationParentFolder string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }

        # Write the message
        Write-Line -Type ValidationSuccess

        # EXECUTION
        # Set the leaf name
        [System.String]$LeafName = if ($DeploymentObject.KeepCurrentFolderName -eq $true) { (Split-Path -Path $FolderPath -Leaf) } else { $ApplicationID }
        # Execute the deployment
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   {
                    Install-BasicFolder -SourceFolderPath $FolderPath -DestinationFolder $DeploymentObject.DestinationParentFolder -LeafName $LeafName
                }
                'Uninstall' {
                    Uninstall-BasicFolder -SourceFolderPath $FolderPath -DestinationFolder $DeploymentObject.DestinationParentFolder -LeafName $LeafName
                }
            }
        }
        catch {
            Write-FullError
        }

        ####################################################################################################
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function installs a folder, in a folder on the local system, for example C:\Program Files.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Install-BasicFolder -SourceFolderPath 'C:\Demo\MyApplication1.0' -DestinationFolder 'C:\Program Files' -LeafName 'My Application 1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Install-BasicFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the folder that will be copied.')]
        [System.String]
        $SourceFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The path of the destination, into which the folder will be copied.')]
        [System.String]
        $DestinationFolder,

        [Parameter(Mandatory=$false,HelpMessage='The foldername after the copy.')]
        [System.String]
        $LeafName
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Handlers
        [System.String]$ParentFolderToCopyTo    = $DestinationFolder
        # Output
        [System.Boolean]$InstallationSuccess    = $null

        ####################################################################################################
    }
    
    process {
        # PREPARATION
        # Set the installation folder
        [System.String]$InstallationFolder = Join-Path -Path $ParentFolderToCopyTo -ChildPath $LeafName

        # VALIDATION
        # If the installation folder already exists, then the installation is considered successful
        if (Test-Path -Path $InstallationFolder) {
            Write-Line "The Installation Folder already exists. ($InstallationFolder)" -Type Success
            Write-Line "The application is considered installed. No action has been taken. ($LeafName)" -Type Success
            $InstallationSuccess = $true ; Return
        }

        # INSTALLATION
        try {
            # Install the application
            Write-Line "Installing the Folder ($LeafName). One moment please..." -Type Busy
            # Create the installation folder
            Write-Line "Creating the Installation Folder... ($InstallationFolder)"
            New-Item -Path $InstallationFolder -ItemType Directory -Force | Out-Null
            # Copy the folder
            Write-Line "Copying the items from the sourcefolder ($SourceFolderPath) to the Installation Folder... ($InstallationFolder)"
            Copy-Item -Path "$SourceFolderPath\*" -Destination $InstallationFolder -Recurse -Force
            Write-Line "The application has been successfully installed. ($LeafName)" -Type Success
            $InstallationSuccess = $true
        }
        catch {
            Write-FullError
            $InstallationSuccess = $false
        }
    }
    
    end {
        # Return the output
        $InstallationSuccess
    }
}

### END OF SCRIPT
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function removes a folder, from a folder on the local system, for example C:\Program Files.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Uninstall-BasicFolder -SourceFolderPath 'C:\Demo\MyApplication1.0' -DestinationFolder 'C:\Program Files' -LeafName 'My Application 1.0'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Uninstall-BasicFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the folder.')]
        [System.String]
        $SourceFolderPath,

        [Parameter(Mandatory=$true,HelpMessage='The path of the destination.')]
        [System.String]
        $DestinationFolder,

        [Parameter(Mandatory=$false,HelpMessage='The foldername after the copy.')]
        [System.String]
        $LeafName
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Handlers
        [System.String]$ParentFolderToCopyTo    = $DestinationFolder
        # Output
        [System.Boolean]$UninstallSuccess       = $null

        ####################################################################################################
    }
    
    process {
        # PREPARATION
        # Set the installation folder
        [System.String]$InstallationFolder = Join-Path -Path $ParentFolderToCopyTo -ChildPath $LeafName

        # VALIDATION
        # If the installation folder does not exists, then the uninstall is considered successful
        if (-Not(Test-Path -Path $InstallationFolder)) {
            Write-Line "The Installation Folder does not exist. ($InstallationFolder)" -Type Success
            Write-Line "The uninstall is considered successful. No action has been taken." -Type Success
            $UninstallSuccess = $true ; Return
        }

        # UNINSTALL
        try {
            # Install the application
            Write-Line "Uninstalling the Folder ($InstallationFolder). One moment please..." -Type Busy
            # Remove the installation folder
            Write-Line "Removing the Installation Folder... ($InstallationFolder)"
            Remove-Item -Path $InstallationFolder -Recurse -Force
            Write-Line "The application has been successfully uninstalled. ($InstallationFolder)" -Type Success
            $UninstallSuccess = $true
        }
        catch {
            Write-FullError
            $UninstallSuccess = $false
        }
    }
    
    end {
        # Return the output
        $UninstallSuccess
    }
}

### END OF SCRIPT
####################################################################################################
