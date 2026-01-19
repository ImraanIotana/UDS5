####################################################################################################
<#
.SYNOPSIS
    This function performs the administrative tasks, that are needed as after the Deployment.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Stop-DeploymentProcess
.INPUTS
    -
.OUTPUTS
    This function returns no stream output.
.NOTES
    Version         : 5.6
    Author          : Imraan Iotana
    Creation Date   : October 2025
    Last Update     : December 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Stop-DeploymentProcessOLD {
    [CmdletBinding()]
    param (
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Handlers
        [PSCustomObject]$GlobalDeploymentObject = $Global:DeploymentObject

        # Administration properties
        [System.String]$CompanyName             = $GlobalDeploymentObject.CompanyName
        [System.String]$ApplicationID           = $GlobalDeploymentObject.ApplicationID
        [System.String]$AdministrationParentKey = "HKLM:\SOFTWARE\$CompanyName Application Administration"
        [System.String]$AdministrationKey       = (Join-Path -Path $AdministrationParentKey -ChildPath $ApplicationID)
        [System.String[]]$UnneededProperties    = @('MSIExecutablePath','DeploymentObjects','SupportScriptsFolder')

        ####################################################################################################
    }
    
    process {
        # EXECUTION - REGISTRY
        # Remove the unneeded properties from the GlobalDeploymentObject (For unknown reasons the GlobalDeploymentObject behaves like a hashtable, instead of PSCustomObject)
        $UnneededProperties | ForEach-Object { Write-Verbose "Removing unneeded Property... ($_)" ; $GlobalDeploymentObject.Remove($_) }

        # Write the Administration into the registry
        Write-Line "Writing the Deployment Information into the Registry... ($AdministrationKey)"
        if (-Not(Test-Path -Path $AdministrationKey)) { New-Item -Path $AdministrationKey -Force | Out-Null }
        $GlobalDeploymentObject.GetEnumerator() | ForEach-Object { Set-ItemProperty -Path $AdministrationKey -Name $_.Name -Value $_.Value -Force }


        # EXECUTION - LOGGING
        # Stop PowerShell logging
        Write-Line "Stopped logging. Logfile: ($($GlobalDeploymentObject.LogFilePath))" -Type Special
        Stop-Transcript
    }
    
    end {
    }
}

### END OF SCRIPT
####################################################################################################
