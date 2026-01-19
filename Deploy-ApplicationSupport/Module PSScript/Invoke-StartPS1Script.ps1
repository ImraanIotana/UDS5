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
    Invoke-StartPS1Script -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.4
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : October 2023
#>
####################################################################################################

function Invoke-StartPS1Script {
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

        ####################################################################################################

        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Write the no validtion message
            $this.FunctionHandler.WriteNoInputValidationMessage()
        }

        ####################################################################################################

        # Add the GetPS1Path method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetPS1Path -Value {
            # Get the full path of the script
            [System.String]$PS1Path = switch ($this.DeploymentObject.PS1PathIsAbsolute) {
                $true   { $this.DeploymentObject.PS1FileName }
                $false  { $this.DeploymentHandler.GetFilePath($this.DeploymentObject.PS1FileName) }
            }
            # Return the result
            $PS1Path
        }

        ####################################################################################################

        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value {
            # If the RunDuringInstall boolean was set to true
            if ($this.DeploymentObject.RunDuringInstall) {
                # Get the full path of the script
                [System.String]$PS1Path = $this.GetPS1Path()
                #[System.String]$PS1Path = $this.DeploymentHandler.GetFilePath($this.DeploymentObject.PS1FileName)
                # Run the script
                [System.Boolean]$ScriptRanSuccesfully = Start-PSScript -PS1Path $PS1Path -ArgumentList $this.DeploymentObject.InstallArguments -SuccessExitCodes $this.DeploymentObject.InstallSuccessExitCodes
                # Return the result
                $ScriptRanSuccesfully
            } else {
                # Else write the message and return true
                Write-Warning 'The RunDuringInstall Boolean has been set to false. No action has been taken.'
                $true
            }
        }

        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value {
            # If the RunDuringUninstall boolean was set to true
            if ($this.DeploymentObject.RunDuringUninstall) {
                # Get the full path of the script
                [System.String]$PS1Path = $this.GetPS1Path()
                #[System.String]$PS1Path = $this.DeploymentHandler.GetFilePath($this.DeploymentObject.PS1FileName)
                # Run the script
                [System.Boolean]$ScriptRanSuccesfully = Start-PSScript -PS1Path $PS1Path -ArgumentList $this.DeploymentObject.UninstallArguments -SuccessExitCodes $this.DeploymentObject.UninstallSuccessExitCodes
                # Return the result
                $ScriptRanSuccesfully
            } else {
                # Else write the message and return true
                Write-Warning 'The RunDuringUninstall Boolean has been set to false. No action has been taken.'
                $true
            }
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

