####################################################################################################
<#
.SYNOPSIS
    This function deploys a font.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Deploy-Font -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : September 2025
    Last Update     : September 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Deploy-Font {
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
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        [System.String]$FunctionName        = $FunctionDetails[0]
        # Output
        [System.Boolean]$DeploymentSuccess  = $null
        [System.Collections.Generic.List[System.Boolean]]$ResultArrayList = @()
        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()

        ####################################################################################################
        ### SUPPORTING PROPERTIES ###

        # Get the filename of the font
        [System.String[]]$Verb1,$Verb2 =  switch ($Action) {
                'Install'   { 'installation','installed' }
                'Uninstall' { 'uninstall','uninstalled' }
            }

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            $ValidationArrayList.Add((Confirm-Object -MandatoryArray $DeploymentObject.FontFileNames))
        }

        ####################################################################################################

        # Validate the input
        Confirm-Input
    }
    
    process {
        # If the validation failed, then return
        if ($ValidationArrayList -contains $false) { Write-Line -Type ValidationFail ; Return }
        Write-Line -Type ValidationSuccess
        # For each font
        foreach ($FontFileName in $DeploymentObject.FontFileNames) {
            # Get the path
            [System.String]$FontFilePath = Get-SourceItemPath -FileName $FontFileName
            # Switch on the action
            switch ($Action) {
                'Install'   { $ResultArrayList.Add((Install-Font -Path $FontFilePath -OutHost -PassThru -Force)) }
                'Uninstall' { $ResultArrayList.Add((Uninstall-Font -Path $FontFilePath -OutHost -PassThru -Force)) }
            }
        }
        $DeploymentSuccess = if ($ResultArrayList -contains $false) {
            Write-Fail ('[{0}]: The {1} of one of the Fonts has failed.' -f $FunctionName,$Verb1) ; $false
        } else {
            Write-Success ('[{0}]: All Fonts have been succesfully {1}.' -f $FunctionName,$Verb2) ; $true
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################
