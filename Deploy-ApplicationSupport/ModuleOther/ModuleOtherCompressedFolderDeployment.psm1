####################################################################################################
<#
.SYNOPSIS
    This function deploys a compressed folder into C:\Program Files.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-CompressedFolderDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.2
    Author          : Imraan Iotana
    Creation Date   : October 2025
    Last Update     : October 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Start-CompressedFolderDeployment {
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

        # Output
        [System.Boolean]$DeploymentSuccess  = $null

        ####################################################################################################
    }
    
    process {
        # VALIDATION
        # Switch on the action
        switch ($Action) {
            'Install'   {
                # Validate the zip file
                if (Test-String -IsEmpty $DeploymentObject.ZipFileBaseName) { Write-Line "The ZipFileBaseName string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }
                [System.String]$ZipFilePath = Get-SourceItemPath -FileName "$($DeploymentObject.ZipFileBaseName).zip"
                if (-Not($ZipFilePath)) { Write-Line -Type ValidationFail ; Return }
                
                # Validate the InstallationFolder
                if (Test-String -IsEmpty $DeploymentObject.InstallationFolder) { Write-Line "The InstallationFolder string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }
            }
            'Uninstall' {
            }
        }
        # Write the message
        Write-Line -Type ValidationSuccess

        # EXECUTION
        # Execute the deployment
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   {
                    Install-CompressedFolder -ZipFilePath $ZipFilePath -InstallationFolder $DeploymentObject.InstallationFolder -IgnoreTopFolder:$DeploymentObject.IgnoreTopFolderInZipFile
                }
                'Uninstall' {
                    Uninstall-CompressedFolder -InstallationFolder $DeploymentObject.InstallationFolder
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
    This function installs a compressed folder on the local system.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Install-CompressedFolder -ZipFilePath 'C:\Demo\MyApp.zip' -InstallationFolder 'C:\Program Files' -IgnoreTopFolder
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
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

function Install-CompressedFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the zip file.')]
        [System.String]
        $ZipFilePath,

        [Parameter(Mandatory=$true,HelpMessage='The path on the local system, into which the folder will be copied.')]
        [System.String]
        $InstallationFolder,

        [Parameter(Mandatory=$false,HelpMessage='Switch for ignoring the topmost folder inside the zip file.')]
        [System.Management.Automation.SwitchParameter]
        $IgnoreTopFolder
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Output
        [System.Boolean]$InstallationSuccess    = $null

        # Handlers
        [System.String]$TemporaryWorkFolder     = Join-Path -Path $ENV:ProgramData -ChildPath (New-Guid)

        ####################################################################################################
    }
    
    process {
        # VALIDATION
        # If the installation folder already exists, then the installation is considered successful
        if (Test-Path -Path $InstallationFolder) {
            Write-Line "The Installation Folder already exists. ($InstallationFolder)" -Type Success
            Write-Line "The Compressed Folder is considered installed. No action has been taken. ($InstallationFolder)" -Type Success
            $InstallationSuccess = $true ; Return
        }

        # INSTALLATION
        try {
            # Install the application
            Write-Line "Installing the Compressed Folder to the InstallationFolder ($InstallationFolder). One moment please..." -Type Busy
            # Create the installation folder
            if (-Not(Test-Path -Path $InstallationFolder)) {
                Write-Line "The Installation Folder does not exist yet. Creating the folder... ($InstallationFolder)"
                #New-Item -Path $InstallationFolder -ItemType Directory -Force | Out-Null
                New-Folder -Path $InstallationFolder -InheritACLFromParent
            } else {
                Write-Line "The Installation Folder already exists. ($InstallationFolder)"
            }
            # Unzip the zip file (Using the DotNet method prevents a GUI, which prevents errors when installing from an SCCM Task Sequence)
            Write-Line "Extracting the zipfile to a temporary location. One moment please... ($TemporaryWorkFolder)" -Type Busy
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath,$TemporaryWorkFolder)
            #Expand-Archive -Path $ZipFilePath -DestinationPath $TemporaryWorkFolder -Force
            # Get the top folder
            [System.IO.DirectoryInfo[]]$FolderObjects = Get-ChildItem -Path $TemporaryWorkFolder -Directory
            [System.Int32]$NumberOfFolders = $FolderObjects.Count

            # If the top folder should be ignored
            if ($IgnoreTopFolder.IsPresent) {

                # If multiple folders were found
                if ($NumberOfFolders -gt 1) {
                    # Write the message and open the folder
                    Write-Line "Multiple folders were found at the Top level. Please make sure, that there is only one folder at the Top level." -Type Fail
                    Open-Folder -Path $TemporaryWorkFolder
                    $InstallationSuccess = $false ; Return

                # If 1 folder was found
                } elseif ($NumberOfFolders -eq 1) {
                    # Set the top folder
                    [System.String]$TopFolder = $FolderObjects[0].FullName
                    Write-Line "The top folder will be ignored. ($TopFolder)"
                    #  Copy the content of the top folder to the installation folder (Use Copy instead of Move, or else the ACL of the temp folder will remain on this folder.)
                    Write-Line "Copying the content of the top folder ($TopFolder) to the installation folder ($InstallationFolder)..." -Type Busy
                    Copy-Item -Path "$TopFolder\*" -Destination $InstallationFolder -Recurse -Force
                    #Move-Item -Path "$TopFolder\*" -Destination $InstallationFolder -Force
                    # Reset the ACL of the installation folder
                    Set-AclFromParentFolder -Path $InstallationFolder
                    # Remove the temporary folder
                    Write-Line "Removing the temporary folder ($TemporaryWorkFolder)..."
                    Remove-Item -Path $TemporaryWorkFolder -Recurse -Force
                    Write-Line "The Compressed Folder has been successfully installed. ($InstallationFolder)" -Type Success
                    $InstallationSuccess = $true ; Return

                # If no folders were found
                } elseif ($NumberOfFolders -lt 1) {
                    # Write the message and open the folder
                    Write-Line "No folders were found at the Top level. Please make sure, that there is one folder at the Top level." -Type Fail
                    Open-Folder -Path $TemporaryWorkFolder
                    $InstallationSuccess = $false ; Return
                }

            # If the top folder should NOT be ignored
            } else {
                try {
                    # Copy all items to the installation folder
                    Write-Line "The top folder will not be ignored."
                    Write-Line "Copying all items from the Tempfolder ($TemporaryWorkFolder) to the InstallationFolder ($InstallationFolder)."
                    Copy-Item -Path "$TemporaryWorkFolder\*" -Destination $InstallationFolder -Force
                    # Reset the ACL of the installation folder
                    Set-AclFromParentFolder -Path $InstallationFolder
                    # Remove the temporary folder
                    Write-Line "Removing the temporary folder ($TemporaryWorkFolder)..."
                    Remove-Item -Path $TemporaryWorkFolder -Recurse -Force
                    # Write the message
                    Write-Line "The Compressed Folder has been successfully installed. ($InstallationFolder)" -Type Success
                    $InstallationSuccess = $true
                }
                catch {
                    Write-FullError
                }
            }
        }
        catch {
            Write-FullError
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
    This function uninstalls a compressed folder from the local system.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Uninstall-CompressedFolder -InstallationFolder 'C:\Program Files\MyApplication'
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

function Uninstall-CompressedFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path on the local system, into which the folder will be copied.')]
        [System.String]
        $InstallationFolder
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Input
        [System.String]$Path                = $InstallationFolder
        # Output
        [System.Boolean]$UninstallSuccess   = $null

        ####################################################################################################
    }
    
    process {
        # UNINSTALL
        # If the installation folder exists
        $UninstallSuccess = if (Test-Path -Path $Path) {
            # Uninstall the application
            Write-Line "Uninstalling the Compressed Folder-application ($Path). One moment please..." -Type Busy
            Remove-Item -Path $Path -Force -Recurse | Out-Null

            # Test if the uninstall was successful
            if (Test-Path -Path $Path) {
                Write-Line "The Installation Folder still exists. The uninstall was NOT successful. ($Path)" -Type Fail ; $false
            } else {
                Write-Line "The Installation Folder has been removed successfully. ($Path)" -Type Success ; $true
            }

        } else {
            # Else the uninstall is considered successful
            Write-Line "The Installation Folder does not exist. ($Path)"
            Write-Line "The application is not installed. The Uninstall is considered successful. ($Path)" -Type Success
            $true
        }        
    }
    
    end {
        # Return the output
        $UninstallSuccess
    }
}

### END OF SCRIPT
####################################################################################################
