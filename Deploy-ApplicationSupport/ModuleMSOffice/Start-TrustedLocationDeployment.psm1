####################################################################################################
<#
.SYNOPSIS
    This function deploys a Trusted Location for Microsoft Office product.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-TrustedLocationDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.2
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Start-TrustedLocationDeployment {
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
        [System.String]$PreFix                  = "[$($MyInvocation.MyCommand)]:"
        # Validation
        [System.String[]]$AllowedOfficeProducts = @('Word','Excel','PowerPoint','Access')
        # Output
        [System.Boolean]$DeploymentSuccess      = $null

        ####################################################################################################
    }
    
    process {
        # VALIDATION
        # Switch on the action
        switch ($Action) {
            'Install'   {
                # Validate the TrustedLocationPath
                [System.String]$TrustedLocationPath = $DeploymentObject.TrustedLocationPath
                if (Test-String -IsEmpty $TrustedLocationPath) { Write-Fail "$PreFix The TrustedLocationPath string is empty." ; Write-Line -Type ValidationFail ; Return }
                if (-Not(Test-Path -Path $TrustedLocationPath)) { Write-Fail "$PreFix The TrustedLocation could not be reached. ($TrustedLocationPath)" ; Write-Line -Type ValidationFail ; Return }
                # Validate the OfficeProduct
                if (Test-String -IsEmpty $DeploymentObject.OfficeProduct) { Write-Fail "$PreFix The OfficeProduct string is empty." ; Write-Line -Type ValidationFail ; Return }
                if (-Not($AllowedOfficeProducts -contains $DeploymentObject.OfficeProduct)) { Write-Fail "$PreFix The OfficeProduct is not valid. The valid options are: $AllowedOfficeProducts." ; Write-Line -Type ValidationFail ; Return }
                # Validate the OfficeVersion
                if (Test-String -IsEmpty $DeploymentObject.OfficeVersion) { Write-Fail "$PreFix The OfficeVersion string is empty." ; Write-Line -Type ValidationFail ; Return }
            }
            'Uninstall' {
                # Validate the TrustedLocationPath
                [System.String]$TrustedLocationPath = $DeploymentObject.TrustedLocationPath
                if (Test-String -IsEmpty $TrustedLocationPath) { Write-Fail "$PreFix The TrustedLocationPath string is empty." ; Write-Line -Type ValidationFail ; Return }
            }
        }

        # VALIDATION - SUCCESS
        # Write the message
        Write-Line -Type ValidationSuccess

        # EXECUTION
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   {
                    Install-TrustedLocation -Path $TrustedLocationPath -OfficeProduct $DeploymentObject.OfficeProduct -OfficeVersion $DeploymentObject.OfficeVersion -AllowSubfolders $DeploymentObject.AllowSubfolders
                }
                'Uninstall' {
                    Uninstall-TrustedLocation -Path $TrustedLocationPath -OfficeProduct $DeploymentObject.OfficeProduct -OfficeVersion $DeploymentObject.OfficeVersion
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
