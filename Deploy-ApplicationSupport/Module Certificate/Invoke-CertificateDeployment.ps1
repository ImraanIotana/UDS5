####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls certificates.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : [FunctionHandler], [DeploymentHandler], [CertificateHandler]
    External functions  : -
    External variables  : -
.EXAMPLE
    Invoke-TemplateDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean] (If the deployment was succesful, then $true is returned. Else $false is returned.)
.NOTES
    Version         : 3.1
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Invoke-CertificateDeployment {
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
            # Validate the CertificateFileName
            if (-Not($this.DeploymentHandler.ValidateMandatoryFile($this.DeploymentObject.CertificateFileName))) { $this.ValidationIsSuccessful = $false }
            # Validate the CertificateStoreName
            elseif ($this.DeploymentHandler.StringIsEmpty($this.DeploymentObject.CertificateStoreName)) { $this.ValidationIsSuccessful = $false }
        }

        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value {
            # Get the full path of the certificate
            [System.String]$CertificatePath = $this.DeploymentHandler.GetFilePath($this.DeploymentObject.CertificateFileName)
            # Install the certificate
            $this.DeploymentIsSuccesful = Deploy-Certificate -Path $CertificatePath -Store $this.DeploymentObject.CertificateStoreName -Install
        }

        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value {
            # If the RemoveDuringUninstall Boolean is true
            if ($this.DeploymentObject.RemoveDuringUninstall) {
                # Get the full path of the certificate
                [System.String]$CertificatePath = $this.DeploymentHandler.GetFilePath($this.DeploymentObject.CertificateFileName)
                # Uninstall the certificate
                $this.DeploymentIsSuccesful = Deploy-Certificate -Path $CertificatePath -Uninstall
            } else {
                # Else write the message
                Write-Host 'The RemoveDuringUninstall Boolean is set to $false. The uninstall will be skipped.'
                $this.DeploymentIsSuccesful = $true
            }
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

