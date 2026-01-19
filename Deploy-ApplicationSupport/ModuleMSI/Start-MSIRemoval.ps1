####################################################################################################
<#
.SYNOPSIS
    This function uninstalls an MSI, based on the MSI file or ProductCode. It can be used for example, to remove and old version, before installing a new version.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-MSIRemoval -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.6
    Author          : Imraan Iotana
    Creation Date   : September 2025
    Last Update     : January 2026
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Start-MSIRemoval {
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
        [System.String[]]$MSIBaseNamesOrProductCodes    = $DeploymentObject.MSIBaseNamesOrProductCodes
        [System.Int32[]]$SuccessExitCodes               = $DeploymentObject.UninstallSuccessExitCodes

        # Output
        [System.Boolean]$DeploymentSuccess  = $false

        # MSI Handlers
        [System.String]$MSIExecutablePath   = $Global:DeploymentObject.MSIExecutablePath
        [System.String]$MSIArgumentFix      = '/X "{0}" REBOOT=Suppress /QN'

        ####################################################################################################
    }
    
    process {
        # VALIDATION - ACTION
        # Validate the action
        switch ($Action) {
            'Install'   {
                if ($DeploymentObject.RemoveDuringInstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RemoveDuringInstall boolean has been set to False. The MSI will NOT be removed during the $Action process." -Type Success
                    Write-Line -Type SuccessNoAction ; $DeploymentSuccess = $true ; Return
                }
            }
            'Uninstall' {
                if ($DeploymentObject.RemoveDuringUninstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RemoveDuringUninstall boolean has been set to False. The MSI will NOT be removed during the $Action process." -Type Success
                    Write-Line -Type SuccessNoAction ; $DeploymentSuccess = $true ; Return
                }
            }
        }

        # VALIDATION - INPUT
        if ($MSIBaseNamesOrProductCodes.Count -le 0) {
            # Write the message and return false
            Write-Line "The MSIBaseNamesOrProductCodes Array is empty. Please enter at least 1 MSI or ProductCode." -Type Fail
            Return
        }

        
        # PREPARATION
        # Set the result array
        [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()

        # EXECUTION
        try {
            # for each item in the array
            foreach($Item in $MSIBaseNamesOrProductCodes) {

                # If the item is a GUID
                Write-Line "Testing if the Item is a GUID... ($Item)"
                [System.String]$MSIProductCode = if (Test-String -IsGUID $Item) {
                    # Use the GUID
                    $Item
                } else {
                    # Return the ProductCode from the MSI
                    Get-MSIProductCode -Path (Get-SourceItemPath -FileName "$Item.msi")
                }

                # If the MSI is installed, then uninstall it
                $UninstallSuccess = if (Test-MSIIsInstalled -ProductCode $MSIProductCode -OutHost) {

                    # Set the ArgumentList
                    [System.String]$ArgumentList = ($MSIArgumentFix -f $MSIProductCode)

                    # Uninstall the MSI
                    Write-Line ("Uninstalling the MSI with the following arguments: $ArgumentList") -Type Busy
                    [System.Int32]$ExitCode = (Start-Process -FilePath $MSIExecutablePath -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
                    Write-Line "The ExitCode of the MSI Process is: ($ExitCode)" -Type Busy

                    # Return the result
                    if ($ExitCode -in $SuccessExitCodes) { $true } else { $false }

                } else {
                    # Else write the message, and return true
                    Write-Line "The MSI is not installed. No action has been taken. ($Item)" -Type Success
                    $true
                }

                # Add the result to the array
                $ResultArray.Add($UninstallSuccess)
            }
        }
        catch {
            Write-FullError
            $ResultArray.Add($false)
        }


        # EVALUATION
        # Evaluate the results
        if (($ResultArray.Count -eq 0) -or ($ResultArray -contains $false)) {
            # If any of the results is false, then the deployment failed
            Write-Line "One or more MSIs failed to uninstall." -Type Fail
        } else {
            # Else, the deployment succeeded
            Write-Line "All MSIs have been uninstalled successfully." -Type Success
            $DeploymentSuccess = $true
        }

    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################

