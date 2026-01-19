####################################################################################################
<#
.SYNOPSIS
    This function performs the tasks that are needed as preparation, before the Deployment (i.e. validation and logging).
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-DeploymentProcess
.INPUTS
    -
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : October 2025
    Last Update     : December 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################
# Still under construction:
# EventViewer methods need further research

function Start-DeploymentProcess {
    [CmdletBinding()]
    param (
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function (The prefix is needed for the subfunctions.)
        [System.String]$PreFix                  = "[$($MyInvocation.MyCommand)]:"

        # Handlers
        [PSCustomObject]$GlobalDeploymentObject = $Global:DeploymentObject
        [System.String]$ApplicationID           = $GlobalDeploymentObject.ApplicationID
        [System.String]$WorkFolder              = $GlobalDeploymentObject.Rootfolder
        [System.String]$DeploymentScriptVersion = $GlobalDeploymentObject.DeploymentScriptVersion
        [System.String]$CopyrightMessage        = "$PreFix Deployment performed by the Universal Deployment Script version ($DeploymentScriptVersion). Copyright (C) Iotana. All rights reserved."

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        [System.Management.Automation.ScriptBlock]$TestApplicationID = {
            # Validate the ApplicationID
            if ($ApplicationID -eq '<<ASSETID>>') {
                # Write the message and exit the script
                Write-Line "$PreFix The AssetID/ApplicationID still contains the default value (<<ASSETID>>). The deployment will not start." -Type Fail
                Exit
            } elseif (Test-String -IsEmpty $ApplicationID) {
                # Write the message and exit the script
                Write-Line "$PreFix The AssetID/ApplicationID string is empty. The deployment will not start." -Type Fail
                Exit
            } else {
                # Write the message
                Write-Line "$PreFix The AssetID is valid. ($ApplicationID)"
            }
        }

        [System.Management.Automation.ScriptBlock]$TestDeploymentObjectsArray = {
            # Get the DeploymentObjectsArray
            [PSCustomObject[]]$DeploymentObjectsArray = $GlobalDeploymentObject.DeploymentObjects
            # If the DeploymentObjectsArray is not empty
            if ($DeploymentObjectsArray.Count -gt 0) {
                # Write the message
                Write-Line "$PreFix The DeploymentObjects Array is valid."
                # Write the amount of objects
                Write-Line "$PreFix There are ($($DeploymentObjectsArray.Count)) Objects to deploy."
                # During uninstall, if the boolean ReverseUninstallOrder is true, then reverse the DeploymentObjectsArray order
                if (($GlobalDeploymentObject.Action -eq 'Uninstall') -and ($GlobalDeploymentObject.ReverseUninstallOrder -eq $true)) {
                    Write-Warning "$PreFix The deployment order will be reversed during Uninstall."
                    [array]::Reverse($DeploymentObjectsArray)
                }

            } else {
                # Write the message and Exit
                Write-Line "The DeploymentObjects Array is empty. The deployment will not start." -Type Fail
                Exit
            }
        }

        [System.Management.Automation.ScriptBlock]$SetWorkFolder = {
            # Set the WorkFolder
            Write-Line "$PreFix Setting the folder where this file (Deploy-Application.ps1) is located, as the WorkFolder... ($WorkFolder)"
            Set-Location -Path $WorkFolder
        }

        <#[System.Management.Automation.ScriptBlock]$NewEventViewerLog = {
            # Create the EventViewer Log
            [System.String]$EventViewerLogName = $ApplicationID
            if (Get-EventLog -List | Where-Object { $_.Log -eq $EventViewerLogName}) {
                Write-Line "$PreFix The EventViewer Log already exists. ($EventViewerLogName)"
            } else {
                Write-Line "$PreFix The EventViewer Log does not exist yet. Creating a new Log... (Name: $EventViewerLogName, Source: $EventViewerLogName)"
                #New-EventLog -LogName $EventViewerLogName -Source 'Universal Deployment Script'
                New-EventLog -LogName "Application Installation/$EventViewerLogName" -Source $EventViewerLogName
            }
        }#>

        [System.Management.Automation.ScriptBlock]$GetFolderSize = {
            # Calculate the size of the Folder
            Write-Line "$PreFix Calculating the size of the WorkFolder... ($WorkFolder)"
            $SizeOfFolder = ( (Get-ChildItem -Path $WorkFolder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB )
            Write-Line ('{0} The size of the WorkFolder is: {1:N0} MB.' -f $PreFix,$SizeOfFolder)
        }

        [System.Management.Automation.ScriptBlock]$StartLogging = {
            # Set the Log properties
            [System.String]$LogFolder   = $GlobalDeploymentObject.LogFolder
            [System.String]$LogFileName = "$($GlobalDeploymentObject.AssetID)_$($GlobalDeploymentObject.TimeStamp)_$($GlobalDeploymentObject.Action).log"
            [System.String]$LogFilePath = (Join-Path -Path $LogFolder -ChildPath $LogFileName)
            # Add the LogFilePath to the Global DeploymentObject (For unknown reasons the GlobalDeploymentObject behaves like a hashtable)
            $GlobalDeploymentObject['LogFilePath'] = $LogFilePath
            # Create the logfolder
            Write-Verbose "$PreFix Testing if the logfolder exists... ($LogFolder)"
            if (Test-Path -Path $LogFolder) {
                Write-Verbose "$PreFix The logfolder already exists. No action has been taken ($LogFolder)"
            } else {
                Write-Verbose "$PreFix The logfolder does not exist. Creating the folder... ({0})' -f $LogFolder)"
                New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
            }
            # Start logging
            Write-Line "$PreFix Started logging. Logfile: ($LogFilePath)" -Type Special
            Start-Transcript -Path $LogFilePath | Out-Null
        }

        ####################################################################################################
    }
    
    process {
        # EXECUTION
        $StartLogging.Invoke()

        # Write the copyright message
        Write-Line $CopyrightMessage

        # Test the permissions of the current user
        [System.String]$CurrentUserName = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name
        if (Test-CurrentUserIsLocalAdmin) {
            Write-Line "The current user ($CurrentUserName) is running under Elevated Permissions."
        } else {
            Write-Line "Though the current user ($CurrentUserName) not running under Elevated Permissions, the Deployment will continue."
        }

        #$NewEventViewerLog.Invoke()
        $TestApplicationID.Invoke()
        $TestDeploymentObjectsArray.Invoke()
        $SetWorkFolder.Invoke()
        $GetFolderSize.Invoke()
    }
    
    end {
    }
}

### END OF SCRIPT
####################################################################################################
