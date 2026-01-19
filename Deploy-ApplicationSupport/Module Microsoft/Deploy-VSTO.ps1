####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls a VSTO Addin.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Deploy-VSTO -VSTOPath 'https://VendorURL.com/OfficeAddins/VendorAddin.vsto' -Install
.EXAMPLE
    Deploy-VSTO -VSTOPath $URLtoVSTO -Install -Silent
.INPUTS
    [System.String]
    [System.Management.Automation.SwitchParameter]
    [System.Boolean[]]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.2
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Deploy-VSTO {
    [CmdletBinding()]
    param (
        # VSTOPath
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [System.String]
        $VSTOPath,

        # Install
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [System.Management.Automation.SwitchParameter]
        $Install,

        # Uninstall
        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [System.Management.Automation.SwitchParameter]
        $Uninstall,

        # Silent
        [Parameter(Mandatory=$false,ParameterSetName='Install')]
        [Parameter(Mandatory=$false,ParameterSetName='Uninstall')]
        [System.Management.Automation.SwitchParameter]
        $Silent,

        # SuccessExitCodes
        [Parameter(Mandatory=$false)]
        [System.Boolean[]]
        $SuccessExitCodes = @(0,-401)
    )
    
    begin {
        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName            = [System.String]$MyInvocation.MyCommand
            FunctionArguments       = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            ValidationIsSuccessful  = [System.Boolean]$true
            # Handlers
            VSTOInstallerPath       = [System.String](Join-Path -Path $env:CommonProgramFiles -ChildPath 'Microsoft Shared\VSTO\10.0\VSTOInstaller.exe')
            InstallParameter        = [System.String]'/Install'
            UninstallParameter      = [System.String]'/Uninstall'
            SilentParameter         = [System.String]'/Silent'
            VSTOPathCircumFix       = [System.String]'"{0}"'
            # Input
            VSTOPath                = [System.String]$VSTOPath
            Silent                  = [System.Management.Automation.SwitchParameter]$Silent
            Uninstall               = [System.Management.Automation.SwitchParameter]$Uninstall
            SuccessExitCodes        = [System.Boolean[]]$SuccessExitCodes
            # Output
            OutputObject            = [System.Boolean]$null
        }

        ####################################################################################################
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            Write-Verbose ('+++ BEGIN Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Run the RunVSTOInstaller method
            $this.OutputObject = $this.RunVSTOInstaller()
        }

        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
        }

        ####################################################################################################

        # Add the RunVSTOInstaller method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name RunVSTOInstaller -Value {
            try {
                # Create the argument list
                [System.String[]]$ArgumentList = @()
                # Add the deployment parameter
                $ArgumentList += switch ($this.ParameterSetName) {
                    'Install'   { $this.InstallParameter }
                    'Uninstall' { $this.UninstallParameter }
                }
                # Add the VSTOPath parameter
                $ArgumentList += ($this.VSTOPathCircumFix -f $this.VSTOPath)
                # Add the silent parameter
                if ($this.Silent.IsPresent) { $ArgumentList += $this.SilentParameter }
                # Run the VSTOInstaller
                Write-Host ("Running the VSTO Installer with the following arguments ($ArgumentList). One moment please...")
                [System.Int32]$ExitCode = (Start-Process -FilePath $this.VSTOInstallerPath -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
                # Write the result
                switch ($ExitCode) {
                    -300    { Write-Host 'This VSTO can only be installed silently, if the required certificate is installed first (in the Trusted Publisher Store).' }
                    -401    { Write-Host 'The VSTO was not installed. The uninstall will be skipped' }
                    -500    { Write-Host 'The user canceled the operation.' }
                    Default { Write-Verbose ('The ExitCode is: ({0})' -f $ExitCode) }
                }
                # Return the result
                [System.Boolean]$ProcessIsSuccesful = ($ExitCode -in $this.SuccessExitCodes)
                $ProcessIsSuccesful
            }
            catch [System.InvalidOperationException] {
                # Write the error and return false
                Write-Host ('The VSTO Installer was not found at the expected location: ({0})' -f $this.VSTOInstallerPath)
                $false
            }
            catch {
                # Write the error and return false
                [System.Management.Automation.ErrorRecord]$LastErrorRecord = $Error[0]
                Write-Host $LastErrorRecord
                Write-Host $LastErrorRecord.Exception.GetType().FullName
                $false
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
        # Return the output
        $Local:MainObject.OutputObject
        #endregion END
    }
}
