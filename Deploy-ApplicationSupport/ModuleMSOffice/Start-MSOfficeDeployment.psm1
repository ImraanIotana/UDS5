####################################################################################################
<#
.SYNOPSIS
    This function deploys Microsoft Office.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-MSOfficeDeployment -DeploymentObject $MyObject -Action 'Install'
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

function Start-MSOfficeDeployment {
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
        [System.String]$PreFix              = "[$($MyInvocation.MyCommand)]:"
        # Output
        [System.Boolean]$DeploymentSuccess  = $null

        ####################################################################################################
    }
    
    process {
        # VALIDATION
        # Switch on the action
        switch ($Action) {
            'Install'   {
                # Validate the Install executable
                if (Test-String -IsEmpty $DeploymentObject.SetupFileBaseName) { Write-Fail "$PreFix The SetupFileBaseName string is empty." ; Write-Line -Type ValidationFail ; Return }
                [System.String]$SetupFileName = "$($DeploymentObject.SetupFileBaseName).exe"
                [System.String]$SetupFilePath = Get-SourceItemPath -FileName $SetupFileName
                if (-Not($SetupFilePath)) { Write-Line -Type ValidationFail ; Return }

                # Validate the Installation XML File
                if (Test-String -IsEmpty $DeploymentObject.InstallXMLFileBaseName) { Write-Fail "$PreFix The InstallXMLFileBaseName string is empty." ; Write-Line -Type ValidationFail ; Return }
                [System.String]$InstallXMLFileName = "$($DeploymentObject.InstallXMLFileBaseName).xml"
                [System.String]$InstallXMLFilePath = Get-SourceItemPath -FileName $InstallXMLFileName
                if (-Not($InstallXMLFilePath)) { Write-Line -Type ValidationFail ; Return }

                # Validate the Products to license
                # Set the array of license keys
                [System.Collections.Generic.List[System.String]]$LicenseKeyArrayList = @()
                if ($DeploymentObject.ProductsToLicense.Count -eq 0) {
                    Write-Line "$PreFix The ProductsToLicense array is empty."
                } else {
                    foreach ($ProductID in $DeploymentObject.ProductsToLicense) {
                        [System.String]$LicenseKey = Get-MSOfficeLicenseKey -Path $InstallXMLFilePath -ProductID $ProductID -OutHost -PassThru
                        if ($LicenseKey) { $LicenseKeyArrayList.Add($LicenseKey) }
                    }
                }

            }
            'Uninstall' {
            }
        }
        # Write the message
        Write-Line -Type ValidationSuccess

        # EXECUTION
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   {
                    Install-MSOffice -Path $SetupFilePath -InstallXMLFilePath $InstallXMLFilePath -LicenseKeys $LicenseKeyArrayList -AutoActivate -DisableUpdates
                }
                'Uninstall' {
                    Write-Fail "The Uninstall of MS Office has not yet been defined. No action has been taken." ; $false
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
