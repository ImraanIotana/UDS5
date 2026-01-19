####################################################################################################
<#
.SYNOPSIS
    This function runs an sql file.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Invoke-DeployOffice -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.4.4
    Author          : Imraan Iotana
    Creation Date   : July 2025
    Last Update     : July 2025
#>
####################################################################################################

function Invoke-DeployOffice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentObject,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )
    
    begin {

        ####################################################################################################

        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionDetails         = [System.String[]]@($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
            #FunctionName            = [System.String]$MyInvocation.MyCommand
            #FunctionArguments       = [System.String]$PSBoundParameters.GetEnumerator()
            #ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            #FunctionCircumFix       = [System.String]'Function: [{0}] ParameterSetName: [{1}] Arguments: {2}'
            # Validation Handlers
            ValidationIsSuccessful  = [System.Boolean]$true
            PropertiesToValidate    = [System.String[]]@('SetupFileName','InstallXMLFileName','UninstallXMLFileName','ProductKey')
            # Input
            DeploymentObject        = $DeploymentObject
            Action                  = $Action
            # Output
            SuccessExitCodes        = [System.Int32[]](0)
            DeploymentIsSuccesful   = [System.Boolean]$null
        }

        ####################################################################################################

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Validate the input
            $this.ValidateInput()
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # If the validation was not successful then return
            if (-Not($this.ValidationIsSuccessful)) { Return }
            # Add the full path of the file to the main object
            [System.String]$SetupFilePath           = Get-FileFullPath -FileName $this.DeploymentObject.SetupFileName
            [System.String]$InstallXMLFilePath      = Get-FileFullPath -FileName $this.DeploymentObject.InstallXMLFileName
            [System.String]$UninstallXMLFilePath    = Get-FileFullPath -FileName $this.DeploymentObject.UninstallXMLFileName
            # Switch on the Action
            [System.Int32]$ExitCode = switch ($this.Action) {
                'Install'   { $this.Install($SetupFilePath,$InstallXMLFilePath) }
                'Uninstall' { $this.Uninstall($SetupFilePath,$UninstallXMLFilePath) }
                'Reinstall' { $this.Uninstall($SetupFilePath,$UninstallXMLFilePath) ; $this.Install($SetupFilePath,$InstallXMLFilePath) }
            }
            # Write the result
            Write-Host ('The ExitCode is: ({0})' -f $ExitCode)
            $this.DeploymentIsSuccesful = ($ExitCode -in $this.SuccessExitCodes)
        }

        ####################################################################################################
    
        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Validate the strings
            $this.PropertiesToValidate | ForEach-Object {
                if (Test-Object -IsEmpty $this.DeploymentObject.($_)) {
                    Write-Host ('ValidateInput: The {0} string is empty.' -f $_) -ForegroundColor Red
                    $this.ValidationIsSuccessful = $false
                }
            }
            # Switch on the boolean
            switch ($this.ValidationIsSuccessful) {
                $true   { Write-Host ('{0}: The validation was successful. The Process method will now start.' -f $this.FunctionDetails[0]) }
                $false  { Write-Host ('{0}: The validation was NOT successful. The Process method will not start.' -f $this.FunctionDetails[0]) -ForegroundColor Red }
            }
        }

        ####################################################################################################
    
        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value { param([System.String]$SetupFilePath,[System.String]$InstallXMLFilePath)
            try {
                # Install Office
                $ArgumentList = ('/configure "{0}"' -f $InstallXMLFilePath)
                Write-Host ("Running the file ($SetupFilePath) with the Arguments ($ArgumentList). One moment please...")
                [System.Int32]$ExitCode = (Start-Process -FilePath $SetupFilePath -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
                # Return the result
                $ExitCode
            }
            catch {
                Write-FullError
            }
        }

    
        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value { param([System.String]$SetupFilePath,[System.String]$UninstallXMLFilePath)
            try {
                # Uninstall Office
                $ArgumentList = ('/configure "{0}"' -f $UninstallXMLFilePath)
                Write-Host ("Running the file ($SetupFilePath) with the Arguments ($ArgumentList). One moment please...")
                [System.Int32]$ExitCode = (Start-Process -FilePath $SetupFilePath -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
                # Return the result
                $ExitCode
            }
            catch {
                Write-FullError
            }
        }

        ####################################################################################################

        $Local:MainObject.Begin()
    }
    
    process {
        $Local:MainObject.Process()
    }

    end {
        # Return the output
        $Local:MainObject.DeploymentIsSuccesful
    }
}

