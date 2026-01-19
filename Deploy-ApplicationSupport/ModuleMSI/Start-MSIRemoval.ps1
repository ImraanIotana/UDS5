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

        # Output
        [System.Boolean]$DeploymentSuccess  = $null

        # MSI Handlers
        [System.String]$MSIExecutablePath   = $Global:DeploymentObject.MSIExecutablePath
        [System.String]$MSIArgumentFix      = '/X "{0}" REBOOT=Suppress /QN'
        [System.Int32[]]$SuccessExitCodes   = @(0,3010)


        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            # If both are empty, add false
            if ((Test-String -IsEmpty $MSIFileName) -and (Test-String -IsEmpty $DeploymentObject.MSIProductCode)) {
                Write-Fail ('[{0}]: Both the MSIFileName and the MSIProductCode properties are empty. Either of these is mandatory.' -f $FunctionName)
                $ValidationArrayList.Add($false)
            } else {
                $ValidationArrayList.Add($true)
            }
            # If an MSIFileName is entered, get the MSIFilePath and validate it 
            if (Test-String -IsPopulated $MSIFileName) {
                [System.String]$MSIFilePath = Get-SourceItemPath -FileName $MSIFileName
                $ValidationArrayList.Add((Confirm-Object -MandatoryItem $MSIFilePath))
            }
        }

        function Uninstall-MSIInternalFunction {
            # Run the MSI process
            Write-Host ("[$FunctionName]: Running the MSIexec process with the following arguments: $ArgumentList")
            [System.Int32]$ExitCode = (Start-Process -FilePath $MSIExecutablePath -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
            # Return the result
            if ($ExitCode -in $SuccessExitCodes) {
                Write-Success ('[{0}]: The ExitCode of the MSI Process is: ({1})' -f $FunctionName,$ExitCode)
                $true
            } else {
                Write-Fail ('[{0}]: The ExitCode of the MSI Process is: ({1})' -f $FunctionName,$ExitCode)
                $false
            }
        }

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
            $DeploymentSuccess = $false ; Return
        }

        
        # EXECUTION
        # for each item in the array
        foreach($Item in $MSIBaseNamesOrProductCodes) {
            # If the item is a GUID
            [System.String]$MSIIdentifier = if (Test-String -IsGUID $Item) {
                # Use the GUID
                $Item
            } else {
                # Get the path of the MSI
                [System.String]$MSIFilePath = Get-SourceItemPath -FileName "$Item.msi"
                # Get the ProductCode from the MSI
                [System.String]$MSIProductCode = Get-MSIProductCode -Path $MSIFilePath
                # Return the ProductCode
                $MSIProductCode
            }

        }


        # Set the ArgumentList
        [System.String]$MSIIdentifier   =  if ($MSIFilePath) { $MSIFilePath } else { $MSIProductCode }
        [System.String]$ArgumentList    = ($MSIArgumentFix -f $MSIIdentifier)
        # Test if the MSI is installed
        [System.Boolean]$MSIIsInstalled = if ($MSIFilePath) { Test-MSIIsInstalled -Path $MSIIdentifier -OutHost } else { Test-MSIIsInstalled -ProductCode $MSIIdentifier -OutHost }
        # If the MSI is not installed then return
        $DeploymentSuccess = if (-Not($MSIIsInstalled)) {
            Write-Success "[$FunctionName]: The MSI is not installed. No action has been taken. ($MSIIdentifier)"
            Return $true
        } else {
            Uninstall-MSIInternalFunction
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################

