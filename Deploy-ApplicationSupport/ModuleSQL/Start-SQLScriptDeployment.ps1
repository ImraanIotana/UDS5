####################################################################################################
<#
.SYNOPSIS
    This function runs an SQL script, using the locally installed sqlcmd-command.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-SQLScriptDeployment -DeploymentObject $MyObject -Action 'Install'
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

function Start-SQLScriptDeployment {
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
        [System.String]$SQLFileBaseName         = $DeploymentObject.SQLFileBaseName
        [System.String]$SQLInstanceName         = $DeploymentObject.SQLInstanceName

        # Output
        [System.Boolean]$DeploymentSuccess      = $null

        ####################################################################################################
    }
    
    process {
        # VALIDATION - ACTION
        # Validate the action
        switch ($Action) {
            'Install'   {
                if ($DeploymentObject.RunScriptDuringInstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RunScriptDuringInstall boolean has been set to False. The SQL script file will not be run during the $Action process." -Type Success
                    Write-Line -Type SuccessNoAction ; $DeploymentSuccess = $true ; Return
                }
            }
            'Uninstall' {
                if ($DeploymentObject.RunScriptDuringUninstall -eq $false) {
                    # Write the message and return true
                    Write-Line "The RunScriptDuringUninstall boolean has been set to False. The SQL script file will not be run during the $Action process." -Type Success
                    Write-Line -Type SuccessNoAction ; $DeploymentSuccess = $true ; Return
                }
            }
        }

        # VALIDATION - FILE
        # Validate the SQLFile
        if (Test-String -IsEmpty $SQLFileBaseName) { Write-Line "The SQLFileBaseName string is empty." -Type Fail ; Return }
        [System.String]$SQLFilePath = Get-SourceItemPath -FileName "$SQLFileBaseName.sql"
        if (-Not($SQLFilePath)) { Write-Line -Type ValidationFail ; Return }

        # VALIDATION - SQLCMD
        # Validate if sqlcmd is present on the local system
        [System.Management.Automation.ApplicationInfo]$SQLCommand = Get-Command sqlcmd -ErrorAction SilentlyContinue
        if (-Not($SQLCommand)) {
            Write-Line "The command 'sqlcmd' can not be found. Make sure SQL is installed, and the SQLCMD.exe-folder is added to the System's PATH Variable." -Type Fail
            Write-Line -Type ValidationFail ; Return
        } else {
            Write-Line "The command 'sqlcmd' was found. Using the following sqlcmd-executable: ($($SQLCommand.Path))"
        }

        # VALIDATION - SUCCESS
        # Write the success message
        Write-Line -Type ValidationSuccess


        # EXECUTION
        # Run the SQL script
        Write-Line "Running the SQL script. One moment please... (Script Name: ($($SQLFileBaseName).sql)) - Instance Name: ($SQLInstanceName))" -Type Busy
        $DeploymentSuccess = try {
            #Start-Process sqlcmd -ArgumentList "-s .\$SQLInstanceName -E -i $SQLFilePath" -Verb RunAs
            Install-Executable -Path $SQLCommand.Path -AdditionalArguments "-s .\$SQLInstanceName -E -i $SQLFilePath -o C:\ProgramData\sql.log"
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
