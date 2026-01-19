####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls a VSTO Addin.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : [FunctionHandler], [DeploymentHandler]
    External functions  : -
    External variables  : -
.EXAMPLE
    Invoke-VSTODeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.2
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Invoke-VSTODeployment {
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
        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Handlers
            FunctionHandler         = [FunctionHandler]::New([System.String]$MyInvocation.MyCommand,[System.String]$PSBoundParameters.GetEnumerator(),[System.String]$PSCmdlet.ParameterSetName)
            DeploymentHandler       = [DeploymentHandler]::New()
            ValidationIsSuccessful  = [System.Boolean]$true
            # Input
            VSTOPath                = [PSCustomObject]$DeploymentObject.VSTOPathOrURL
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
                    'Install'   { Deploy-VSTO -VSTOPath $this.VSTOPath -Install -Silent }
                    'Uninstall' { Deploy-VSTO -VSTOPath $this.VSTOPath -Uninstall -Silent }
                    'Reinstall' { Deploy-VSTO -VSTOPath $this.VSTOPath -Uninstall -Silent ; Deploy-VSTO -VSTOPath $this.VSTOPath -Install -Silent }
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
            # Write the no validation message
            $this.FunctionHandler.WriteNoInputValidationMessage()
            # Validate the VSTOPath
            if ($this.DeploymentHandler.StringIsEmpty($this.VSTOPath)) { $this.ValidationIsSuccessful = $false }
        }

        ####################################################################################################

        #region BEGIN
        $Local:MainObject.Begin()
        #endregion BEGIN
    }
    
    process {
        #region PROCESS
        $Local:MainObject.Process()
        #endregion PROCESS
    }

    end {
        #region END
        $Local:MainObject.End()
        Return $Local:MainObject.DeploymentIsSuccesful
        #endregion END
    }
}

