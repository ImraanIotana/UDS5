####################################################################################################
<#
.SYNOPSIS
    This function uninstalls an MSI, based on the MSI file or ProductCode. It can be used for example, to remove and old version, before installing a new version.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Remove-MSI -DeploymentObject $MyObject -Action 'Install'
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

function Remove-MSIOLD {
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
        # Input
        [System.String]$MSIFileName         = $DeploymentObject.MSIFileName
        [System.String]$MSIProductCode      = $DeploymentObject.MSIProductCode
        # Output
        [System.Boolean]$DeploymentSuccess  = $null
        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()
        # Message handlers
        [System.String]$BooleanFalseMessage = '[{0}]: The {1} property has been set to false. The MSI will not be removed during the {2}-process.'
        # MSI Handlers
        [System.String]$MSIExecutablePath   = $Global:DeploymentObject.MSIExecutablePath
        [System.String]$MSIArgumentFix      = '/X "{0}" REBOOT=Suppress /QN'
        [System.Int32[]]$SuccessExitCodes   = @(0)

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

        # Validate the input
        Confirm-Input
    }
    
    process {
        # VALIDATION
        # If the corresponding booleans are set to false, then return
        if (($Action -eq 'Install') -and ($DeploymentObject.RemoveDuringInstall -eq $false)) {
            Write-Success ($BooleanFalseMessage -f $FunctionName,'RemoveDuringInstall',$Action)
            $DeploymentSuccess = $true
            Return
        }
        if (($Action -eq 'Uninstall') -and ($DeploymentObject.RemoveDuringUninstall -eq $false)) {
            Write-Success ($BooleanFalseMessage -f $FunctionName,'RemoveDuringUninstall',$Action)
            $DeploymentSuccess = $true
            Return
        }
        # If the validation failed, then return
        if ($ValidationArrayList -contains $false) { Write-Line -Type ValidationFail ; Return }
        Write-Line -Type ValidationSuccess
        
        # EXECUTION
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
