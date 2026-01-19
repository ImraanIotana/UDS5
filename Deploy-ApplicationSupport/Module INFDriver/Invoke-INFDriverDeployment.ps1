####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls an INF driver.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : [FunctionHandler], [DeploymentHandler], [INFDriverHandler]
    External functions  : -
    External variables  : -
.EXAMPLE
    Invoke-INFDriverDeployment -DeploymentObject $MyObject -Action 'Install'
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

function Invoke-INFDriverDeployment {
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
            INFDriverHandler        = [INFDriverHandler]::New()
            ValidationIsSuccessful  = [System.Boolean]$true
            # Input
            INFFileNames            = [System.String[]]$DeploymentObject.INFFileNames
            Action                  = [System.String]$Action
            # Output
            DeploymentIsSuccesful   = [System.Boolean]$null
        }

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
                # Add the full paths array to the main
                Add-Member -InputObject $this -NotePropertyName INFFullPaths -NotePropertyValue $this.DeploymentHandler.CreateFullPathsArrayFromFileNames($this.INFFileNames)
                # Switch on the Action
                switch ($this.Action) {
                    'Install'   { $this.Install() }
                    'Uninstall' { $this.Uninstall() }
                    'Reinstall' { $this.Uninstall() ; $this.Install() }
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


        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Write the message
            $this.FunctionHandler.WriteValidatingInputMessage()
            # Validate the INFFileNames
            if (-Not($this.DeploymentHandler.ValidateMandatoryFileArray($this.INFFileNames))) { $this.ValidationIsSuccessful = $false }
        }

        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value {
            # Install the INF drivers
            $this.DeploymentIsSuccesful = $this.INFDriverHandler.InstallINFDriverArray($this.INFFullPaths)
        }

        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value {
            # Uninstall the INF drivers
            $this.DeploymentIsSuccesful = $this.INFDriverHandler.UninstallINFDriverArray($this.INFFullPaths)
        }

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

