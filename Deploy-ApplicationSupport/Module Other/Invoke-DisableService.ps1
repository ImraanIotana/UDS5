####################################################################################################
<#
.SYNOPSIS
    This function disables a service.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Invoke-DisableService -DeploymentObject $MyObject -Action 'Install'
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

function Invoke-DisableService {
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
                    'Install'   { $this.DisableService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringInstall) }
                    'Uninstall' { $this.DisableService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringUninstall) }
                    'Reinstall' { $this.DisableService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringUninstall) ; $this.DisableService($this.DeploymentObject.ServiceName, $this.DeploymentObject.StopDuringInstall) }
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

        # Add the DisableService method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name DisableService -Value { param([System.String]$ServiceName, [System.Boolean]$ExecuteDuringDeployment)
            # Stop the Service
            if ($ExecuteDuringDeployment) {
                if ($this.TestServiceExists($ServiceName)) {
                    # Stop the Service
                    Write-Host ('Disabling service... ({0})' -f $ServiceName)
                    Set-Service -Name $ServiceName -StartupType Disabled
                    Write-Host ('The service has been disbled. ({0}).' -f $ServiceName)
                    # Return true
                    $true
                } else {
                    # Write the message
                    Write-Host ('The service is not found. No action has been taken. ({0}).' -f $ServiceName)
                    # Return true
                    $true
                }
            } else {
                # Write the message
                Write-Host ('The boolean has been set to $false. The service ({0}) will not be disabled during {1}.' -f $ServiceName, $this.Action)
                # Return true
                $true
            }
        }

        # Add the TestServiceExists method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestServiceExists -Value { param([System.String]$ServiceName)
            # Test if the service exists
            [System.ComponentModel.Component]$ServiceObject = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            [System.Boolean]$ServiceExists = (-Not($null -eq $ServiceObject))
            # Write the result
            [System.String]$ResultInFix = if (-Not($ServiceExists)) { ' NOT' }
            Write-Host ('TestServiceExists: The service is{0} present on the system. ({1})' -f $ResultInFix, $ServiceName)
            # Return the result
            $ServiceExists
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

