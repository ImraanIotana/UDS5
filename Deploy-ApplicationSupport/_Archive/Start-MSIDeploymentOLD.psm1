####################################################################################################
<#
.SYNOPSIS
    This function deploys an MSI, along with an MST, and MSP's.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-MSIDeployment -DeploymentObject $MyObject -Action 'Install'
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

function Start-MSIDeploymentOLD {
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

        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            # Validate the DeploymentObject
            $ValidationArrayList.Add((Test-String -IsPopulated $DeploymentObject.MSIBaseName))

            # Validate the MSI
            [System.String]$Script:MSIFilePath = Get-SourceItemPath -FileName "$($DeploymentObject.MSIBaseName).msi"
            $ValidationArrayList.Add((Confirm-Object -MandatoryItem $Script:MSIFilePath))

            # Validate the MST
            [System.String]$Script:TransformFilePath = [System.String]::Empty
            if (Test-String -IsPopulated $DeploymentObject.MSTBaseName) {
                $Script:TransformFilePath = Get-SourceItemPath -FileName "$($DeploymentObject.MSTBaseName).mst"
                $ValidationArrayList.Add((Confirm-Object -MandatoryItem $Script:TransformFilePath))
            }

            # Validate the MSP's
            [System.Collections.Generic.List[System.String]]$Script:PatchFilePathsArray = @()
            if ($DeploymentObject.MSPBaseNames.Count -gt 0) {
                foreach ($MSPBaseName in $DeploymentObject.MSPBaseNames) {
                    [System.String]$PatchFilePath = Get-SourceItemPath -FileName "$MSPBaseName.msp"
                    $ValidationArrayList.Add((Confirm-Object -MandatoryItem $PatchFilePath))
                    $Script:PatchFilePathsArray.Add($PatchFilePath)
                }
            }

            # Validate the Additional Arguments
            if ($DeploymentObject.AdditionalArguments.Count -gt 0) {
                foreach ($Argument in $DeploymentObject.AdditionalArguments) {
                    $ValidationArrayList.Add((Test-String -IsPopulated $Argument))
                }
            }
        }

        ####################################################################################################

        # Validate the input
        Confirm-Input
    }
    
    process {
        # VALIDATION
        # If the validation failed, then return
        if ($ValidationArrayList -contains $false) { Write-Line -Type ValidationFail ; Return }

        # Write the message
        Write-Line -Type ValidationSuccess

        # Get the size of the MSI
        [System.Double]$SizeOfMSI = ( (Get-ChildItem -Path $Script:MSIFilePath | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB )
        Write-Line ('The size of the MSI is: {0:N0} MB.' -f $SizeOfMSI)

        # EXECUTION
        try {
            switch ($Action) {
                'Install' {
                    # Set the parameters
                    [System.Collections.Hashtable]$Parameters = @{
                        MSI                 = $Script:MSIFilePath
                        MST                 = $Script:TransformFilePath
                        AdditionalArguments = $DeploymentObject.AdditionalArguments
                        SuccessExitCodes    = $DeploymentObject.InstallSuccessExitCodes
                    }
                    # Install the MSI
                    $DeploymentSuccess = Install-MSI @Parameters
                    # Install the Patches
                    if ( ($DeploymentSuccess -eq $false) -and ($Script:PatchFilePathsArray.Count -gt 0) ) {
                        Write-Line "The installation of the MSI has failed. The installation of the MSP's/Patches will be skipped." -Type Fail
                    }
                    if ( ($DeploymentSuccess -eq $true) -and ($Script:PatchFilePathsArray.Count -eq 0) ) {
                        Write-Line "No MSP's/Patches to install."
                    }
                    if ( ($DeploymentSuccess -eq $true) -and ($Script:PatchFilePathsArray.Count -gt 0) ) {
                        $DeploymentSuccess = Install-MSP -MSP $Script:PatchFilePathsArray
                    }
                }
                'Uninstall' {
                    # Uninstall the MSI
                    $DeploymentSuccess = Uninstall-MSI -MSI $Script:MSIFilePath -SuccessExitCodes $DeploymentObject.UninstallSuccessExitCodes
                }
            }
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
