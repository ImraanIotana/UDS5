####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls an executable.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : [FunctionHandler], [DeploymentHandler]
    External functions  : -
    External variables  : -
.EXAMPLE
    Invoke-RunEXE -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean] (If the deployment was succesful, then $true is returned. Else $false is returned.)
.NOTES
    Version         : 3.2
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Invoke-RunEXE {
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
            # Validate the input based on the Action
            switch ($this.Action) {
                'Install'   { $this.ValidateInputDuringInstall() }
                'Uninstall' { $this.ValidateInputDuringUninstall() }
                'Reinstall' { $this.ValidateInputDuringUninstall() ; $this.ValidateInputDuringInstall() }
            }
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # If the validation was successful
            if ($this.ValidationIsSuccessful) {
                # Write the success message
                $this.FunctionHandler.WriteValidationSuccessMessage()
                # Switch on the Action
                switch ($this.Action) {
                    'Install'   { $this.RunExeDuringInstall() }
                    'Uninstall' { $this.RunExeDuringUninstall() }
                    'Reinstall' { $this.RunExeDuringUninstall() ; $this.RunExeDuringInstall() }
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

        # Add the ValidateInputDuringInstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInputDuringInstall -Value {
            # Write the message
            $this.FunctionHandler.WriteValidatingInputMessage()
            # Validate the ExeFullPath
            if ($this.DeploymentObject.RunDuringInstall) {
                if (-Not(Test-Path -Path ($this.DeploymentObject.ExeFullPath))) { $this.ValidationIsSuccessful = $false }
            }
        }

        # Add the ValidateInputDuringUninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInputDuringUninstall -Value {
            # Write the message
            $this.FunctionHandler.WriteValidatingInputMessage()
            # Validate the ExeFullPath
            if ($this.DeploymentObject.RunDuringUninstall) {
                if (-Not(Test-Path -Path ($this.DeploymentObject.ExeFullPath))) { $this.ValidationIsSuccessful = $false }
            }
        }

        ####################################################################################################

        # Add the RunExeDuringInstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunExeDuringInstall -Value {
            # If RunDuringInstall is true, run the exe, else write the message
            if ($this.DeploymentObject.RunDuringInstall) { $this.RunExe() } else { Write-Host ('RunExeDuringInstall: The RunDuringInstall Boolean is set to $false. The exe will not run during install: ({0})' -f $this.DeploymentObject.ExeFullPath) }
            # Set DeploymentIsSuccesful to true
            $this.DeploymentIsSuccesful = $true
        }

        # Add the RunExeDuringUninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunExeDuringUninstall -Value {
            # If RunDuringUninstall is true, run the exe, else write the message
            if ($this.DeploymentObject.RunDuringUninstall) { $this.RunExe() } else { Write-Host ('RunExeDuringUninstall: The RunDuringInstall Boolean is set to $false. The exe will not run during install: ({0})' -f $this.DeploymentObject.ExeFullPath) }
            # Set DeploymentIsSuccesful to true
            $this.DeploymentIsSuccesful = $true
        }

        ####################################################################################################

        # Add the RunExe method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunExe -Value {
            # If the ArgumentList is empty, run the RunExeWithoutArguments method, else run the RunExeWithArguments method
            [System.String[]]$ArgumentList = $this.DeploymentObject.ArgumentList
            Write-Host ("RunExe: Testing if there are arguments...($ArgumentList)")
            if ($ArgumentList.Count -eq 0) { $this.RunExeWithoutArguments() } else { $this.RunExeWithArguments() }
        }

        # Add the RunExeWithoutArguments method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunExeWithoutArguments -Value {
            Write-Host ('RunExeWithoutArguments: Running the executable WITHOUT arguments. One moment please... ({0})' -f $this.DeploymentObject.ExeFullPath)
            Start-Process -FilePath $this.DeploymentObject.ExeFullPath -Wait:$this.DeploymentObject.WaitUntilFinished
        }

        # Add the RunExeWithArguments method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunExeWithArguments -Value {
            [System.String]$FilePath        = $this.DeploymentObject.ExeFullPath
            [System.String[]]$ArgumentList  = $this.DeploymentObject.ArgumentList
            Write-Host ("RunExeWithArguments: Running the executable ($FilePath) WITH arguments ($ArgumentList). One moment please...")
            Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait:$this.DeploymentObject.WaitUntilFinished
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

