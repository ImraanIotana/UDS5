####################################################################################################
<#
.SYNOPSIS
    This function test if the current user is Local Administrator.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Test-CurrentUserIsLocalAdmin
.EXAMPLE
    Test-CurrentUserIsLocalAdmin -OutHost
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.6
    Author          : Imraan Iotana
    Creation Date   : December 2025
    Last Update     : December 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Test-CurrentUserIsLocalAdminOLD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='Switch for writing the details to the host.')]
        [System.Management.Automation.SwitchParameter]
        $OutHost
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Output
        [System.Boolean]$OutputObject       = $null

        ####################################################################################################
    }
    
    process {
        try {
            # PREPARATION
            # Get the CurrentUserObject
            [Security.Principal.WindowsIdentity]$CurrentUserObject = [Security.Principal.WindowsIdentity]::GetCurrent()
            # Write the message
            if ($OutHost) { Write-Line "Testing if the current user is Local Administrator, and is running under Elevated Permissions... ($($CurrentUserObject.Name))" }
            # Create a new Principal Object
            [Security.Principal.WindowsPrincipal]$CurrentUserPrincipalObject = New-Object Security.Principal.WindowsPrincipal($CurrentUserObject)
            # Get the Administrator Role
            [Security.Principal.WindowsBuiltInRole]$BuiltInAdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

            # EXECUTION
            # Test the Role of the Current User
            [System.Boolean]$UserIsLocalAdmin = $CurrentUserPrincipalObject.IsInRole($BuiltInAdminRole)
            # Write the result
            if ($OutHost) {
                [System.String]$MessageInfix = if ($UserIsLocalAdmin) { 'is' } else { 'is NOT' }
                Write-Line "The current user ($($CurrentUserObject.Name)) $MessageInfix running under Elevated Permissions."
            }
            # Set the output
            $OutputObject = $UserIsLocalAdmin
        }
        catch {
            Write-FullError
        }
    }
    
    end {
        # Return the output
        $OutputObject
    }
}

### END OF SCRIPT
####################################################################################################

