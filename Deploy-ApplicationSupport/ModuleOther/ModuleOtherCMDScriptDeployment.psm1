####################################################################################################
<#
.SYNOPSIS
    This function runs a CMD/BAT file.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-CMDScriptDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : December 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################
# Converting to a psm1 creates module-errors. Check later.
function Start-CMDScriptDeployment {
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

        # Input
        [System.String]$CmdBatFileName          = $DeploymentObject.CmdBatFileName

        # Output
        [System.Boolean]$DeploymentSuccess      = $null

        # Handlers
        [System.String]$SuccessNoActionMessage  = "The Deployment is considered successful. No action has been taken."

        ####################################################################################################
    }
    
    process {
        # VALIDATION - ACTION
        # Validate the action
        switch ($Action) {
            'Install'   {
                if ($DeploymentObject.RunDuringInstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RunDuringInstall boolean has been set to False. The CMD/BAT file will not run during the $Action process." -Type Success
                    Write-Line $SuccessNoActionMessage -Type Success ; $DeploymentSuccess = $true ; Return
                }
            }
            'Uninstall' {
                if ($DeploymentObject.RunDuringUninstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RunDuringUninstall boolean has been set to False. The CMD/BAT file will not run during the $Action process." -Type Success
                    Write-Line $SuccessNoActionMessage -Type Success ; $DeploymentSuccess = $true ; Return
                }
            }
        }

        # VALIDATION - FILE
        # Validate the file
        if (Test-String -IsEmpty $CmdBatFileName) { Write-Line "The CmdBatFileName string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }
        [System.String]$CmdBatFilePath = Get-SourceItemPath -FileName $CmdBatFileName
        if (-Not($CmdBatFilePath)) { Write-Line -Type ValidationFail ; Return }

        # VALIDATION - SUCCESS
        # Write the success message
        Write-Line -Type ValidationSuccess


        # EXECUTION
        # Run the script
        Write-Line "Running the cmd/bat-file. One moment please... ($CmdBatFilePath)" -Type Busy
        $DeploymentSuccess = try {
            Start-Process cmd -ArgumentList "/c $CmdBatFilePath" -Verb RunAs -Wait
            Write-Line "The cmd/bat-file has been executed successfully. ($CmdBatFilePath)" -Type Success
            $true
        }
        catch {
            Write-FullError
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################

