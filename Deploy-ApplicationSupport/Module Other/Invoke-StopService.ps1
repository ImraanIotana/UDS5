####################################################################################################
<#
.SYNOPSIS
    This function stops a running service.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Invoke-StopService -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.1
    Author          : Imraan Iotana
    Creation Date   : June 2025
    Last Update     : June 2025
#>
####################################################################################################

function Invoke-StopService {
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
                    'Install'   { $this.StopService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringInstall) }
                    'Uninstall' { $this.StopService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringUninstall) }
                    'Reinstall' { $this.StopService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringUninstall) ; $this.StopService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringInstall) }
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
            # Validate the string
            if (Test-Object -IsEmpty $this.DeploymentObject.ServiceName) { $this.ValidationIsSuccessful = $false }
        }

        ####################################################################################################

        # Add the StopService method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name StopService -Value { param([System.String]$ServiceName, [System.Boolean]$ExecuteDuringDeployment)
            # Stop the Service
            if ($ExecuteDuringDeployment) {
                if ($this.TestServiceIsRunning($ServiceName)) {
                    # Stop the Service
                    Write-Host ('Stopping service... ({0})' -f $ServiceName)
                    Stop-Service -Name $ServiceName
                    Write-Host ('The service has been stopped. ({0}).' -f $ServiceName)
                    # Return true
                    $true
                } else {
                    # Write the message
                    Write-Host ('The service is not running. No action has been taken. ({0}).' -f $ServiceName)
                    # Return true
                    $true
                }
            } else {
                # Write the message
                Write-Host ('The boolean has been set to $false. The service ({0}) will not be stopped during {1}.' -f $ServiceName, $this.Action)
                # Return true
                $true
            }
        }

        # Add the TestServiceIsRunning method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestServiceIsRunning -Value { param([System.String]$ServiceName)
            # Test if the service is running
            [System.ComponentModel.Component]$ServiceObject = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            [System.Boolean]$ServiceIsRunning = ($ServiceObject.Status -eq 'Running')
            # Write the result
            [System.String]$ResultInFix = if (-Not($ServiceIsRunning)) { ' NOT' }
            Write-Host ('TestServiceIsRunning: The service is{0} running. ({1})' -f $ResultInFix, $ServiceName)
            # Return the result
            $ServiceIsRunning

            # TEST RETURN TRUE
            #$true
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

