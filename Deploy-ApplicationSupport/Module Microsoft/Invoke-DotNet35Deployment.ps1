####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls DotNet 3.5.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : [FunctionHandler], [DeploymentHandler], [DotNetHandler]
    External functions  : -
    External variables  : -
.EXAMPLE
    Invoke-DotNetDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.1
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Invoke-DotNet35Deployment {
    [CmdletBinding()]
    param (
        # DeploymentObject
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentObject,

        # Action
        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )
    
    begin {

        ####################################################################################################

        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Handlers
            FunctionHandler         = [FunctionHandler]::New([System.String]$MyInvocation.MyCommand,[System.String]$PSBoundParameters.GetEnumerator(),[System.String]$PSCmdlet.ParameterSetName)
            DeploymentHandler       = [DeploymentHandler]::New()
            ValidationIsSuccessful  = [System.Boolean]$true
            # Input
            DeploymentObject        = [PSCustomObject]$DeploymentObject
            Action                  = [System.String]$Action
            # Output
            DeploymentIsSuccesful   = [System.Boolean]$null
        }

        ####################################################################################################

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            $this.FunctionHandler.WriteBeginMessage()
            # Validate the input
            $this.ValidateInput()
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # If the validation was successful
            if ($this.ValidationIsSuccessful) {
                # Write the success message
                $this.FunctionHandler.WriteValidationSuccessMessage()
                # Switch on the Action
                $this.DeploymentIsSuccesful = switch ($this.Action) {
                    'Install'   {
                        if (Test-Object -IsEmpty $this.DeploymentObject.LocalSourcePath) { Deploy-DotNet35 -Install }
                        else { Deploy-DotNet35 -Install -LocalSourcePath $this.DeploymentObject.LocalSourcePath }
                    }
                    'Uninstall' { $this.Uninstall() }
                    'Reinstall' { Deploy-DotNet35 -Reinstall }
                }
            } else {
                # Write the fail message and return
                $this.FunctionHandler.WriteValidationFailMessage()
                Return
            }
        }

        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            $this.FunctionHandler.WriteEndMessage()
        }

        ####################################################################################################


        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Write the no validtion message
            $this.FunctionHandler.WriteNoInputValidationMessage()
        }

        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value {
            # If the Remove boolean was set to true
            if ($this.DeploymentObject.RemoveDuringUninstall) {
                # Uninstall DotNet
                [System.Boolean]$UninstallIsSuccesful = (Deploy-DotNet35 -Uninstall)
                # Return the result
                $UninstallIsSuccesful
            } else {
                # Else write the message and return true
                Write-Host 'The RemoveDuringUninstall Boolean has been set to false. The uninstall of DotNet 3.5 skipped.'
                $true
            }
        }

        ####################################################################################################

        $Local:MainObject.Begin()
    }
    
    process {
        $Local:MainObject.Process()
    }

    end {
        $Local:MainObject.End()
        # Return the output
        $Local:MainObject.DeploymentIsSuccesful
    }
}


