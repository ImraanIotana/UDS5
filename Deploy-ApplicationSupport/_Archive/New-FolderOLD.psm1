####################################################################################################
<#
.SYNOPSIS
    This function creates a new folder, and performs some extra related tasks.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    New-Folder -Path 'C:\Demo\MyNewFolder'
.EXAMPLE
    New-Folder -Path 'C:\Program Files\MyApplication' -InheritACLFromParent
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream-output.
.NOTES
    Version         : 5.6
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : December 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function New-FolderOLD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of the folder that will be created.')]
        [System.String]
        $Path,

        [Parameter(Mandatory=$false,HelpMessage='Switch for inheriting the ACL of the Parentfolder.')]
        [System.Management.Automation.SwitchParameter]
        $InheritACLFromParent
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Input
        [System.String]$NewFolderToCreate   = $Path

        # Handlers
        [System.String]$ParentFolder        = Split-Path -Path $NewFolderToCreate -Parent

        ####################################################################################################
    }
    
    process {
        # EXECUTION - FOLDER
        # If the folder already exists, write the message
        if (Test-Path -Path $NewFolderToCreate) {
            Write-Line "The folder already exists. ($NewFolderToCreate)"
        } else {
            # Else create the folder
            Write-Line "The folder does not exist yet. Creating the folder... ($NewFolderToCreate)"
            New-Item -Path $NewFolderToCreate -ItemType Directory -Force
            # Test the creation
            if (Test-Path -Path $NewFolderToCreate) {
                Write-Line "The folder has been created: ($NewFolderToCreate)" -Type Success
            } else {
                Write-Line "The folder could not be created: ($NewFolderToCreate)" -Type Fail
                Return
            }
        }

        # EXECUTION - ACL
        if ($InheritACLFromParent.IsPresent) {
            try {
                # Validate if icacls is present on the local system
                [System.Management.Automation.ApplicationInfo]$IcaclsCommand = Get-Command icacls -ErrorAction SilentlyContinue
                if ($IcaclsCommand) {
                    # Use cacls
                    Write-Line "The command 'icacls' was found. Using the following icacls-executable: ($($IcaclsCommand.Path))"
                    Write-Line "Resetting the permissions, so the ACL of the Parentfolder will be inherited... ($NewFolderToCreate)" -Type Busy
                    Install-Executable -Path $IcaclsCommand.Path -AdditionalArguments "`"$NewFolderToCreate`" /reset /t /c /q"
                } else {
                    # Use Set-Acl
                    Write-Line "Equalizing the ACL of the new folder to the ACL of the Parentfolder, using Set-Acl... ($NewFolderToCreate)" -Type Busy
                    [System.Security.AccessControl.DirectorySecurity]$AclOfParentFolder = Get-Acl -Path $ParentFolder
                    Set-Acl -Path $NewFolderToCreate -AclObject $AclOfParentFolder
                }
                # Compare the two ACL's
                if (Compare-AclToParentFolder -Path $NewFolderToCreate) {
                    Write-Line "The ACL of the new folder ($NewFolderToCreate) is the same as the Parentfolder. ($ParentFolder)" -Type Success
                    Return
                } else {
                    Write-Line "The ACL of the new folder ($NewFolderToCreate) is NOT the same as the Parentfolder. ($ParentFolder)" -Type Fail
                }
            }
            catch {
                Write-FullError
            }
        }

    }
    
    end {
    }
}

### END OF SCRIPT
####################################################################################################

