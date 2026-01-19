####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls DotNet 3.5.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Deploy-DotNet35 -Install
.EXAMPLE
    Deploy-DotNet35 -Test
.INPUTS
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.2
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Deploy-DotNet35 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [System.Management.Automation.SwitchParameter]
        $Install,

        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [System.Management.Automation.SwitchParameter]
        $Uninstall,

        [Parameter(Mandatory=$true,ParameterSetName='Reinstall')]
        [System.Management.Automation.SwitchParameter]
        $Reinstall,

        [Parameter(Mandatory=$true,ParameterSetName='Test')]
        [System.Management.Automation.SwitchParameter]
        $Test,

        [Parameter(Mandatory=$false,ParameterSetName='Install')]
        [System.String]
        $LocalSourcePath
    )
    
    begin {
        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            FunctionName            = [System.String]$MyInvocation.MyCommand
            FunctionArguments       = [System.String]$PSBoundParameters.GetEnumerator()
            ParameterSetName        = [System.String]$PSCmdlet.ParameterSetName
            # Handlers
            ValidationIsSuccessful  = [System.Boolean]$true
            DotNet35FeatureName     = 'NetFx3'
            StatusEnabled           = 'Enabled'
            # Input
            LocalSourcePath         = $LocalSourcePath
            # Output
            OutputObject            = [System.Boolean]$null
        }

        # Add the Messages
        Add-Member -InputObject $Local:MainObject -MemberType ScriptProperty Messages -Value {
            [System.Collections.Hashtable]@{
                # Function
                Begin               = '+++ BEGIN Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments
                End                 = '___ END Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments
                # Validation
                #ValidatingInput     = 'Validating the Input...'
                ValidationSuccess   = 'The validation was successful. The Process method will now start.'
                ValidationFail      = 'The validation was NOT successful. The Process method will not start.'
                NoInputValidation   = 'This function has no input validation.'
            }
        }

        ####################################################################################################
        
        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            Write-Verbose $this.Messages.Begin
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # Validate the input
            $this.ValidateInput()
            # If the validation was successful
            if ($this.ValidationIsSuccessful) {
                # Write the success message
                Write-Verbose $this.Messages.ValidationSuccess
                # Switch on the ParameterSetName
                switch ($this.ParameterSetName) {
                    'Install'               { $this.OutputObject = $this.InstallDotNet35() }
                    'Uninstall'             { $this.OutputObject = $this.UninstallDotNet35() }
                    'Reinstall'             { $this.OutputObject = $this.UninstallDotNet35() ; if ($this.OutputObject) { $this.OutputObject = $this.InstallDotNet35() } }
                    'Test'                  { $this.OutputObject = $this.TestDotNet35IsInstalled() }
                }
            } else {
                # Write the error
                Write-Verbose $this.Messages.ValidationFail
            }
        }

        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose $this.Messages.End
        }

        ####################################################################################################

        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # Write the message
            Write-Verbose $this.Messages.NoInputValidation
        }

        ####################################################################################################

        # Add the InstallDotNet35 method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallDotNet35 -Value {
            # If the item is already installed, then write the message and return true
            if ($this.TestDotNet35IsInstalled()) {
                Write-Host 'DotNet 3.5 is already installed. The installation will be skipped.'
                $true
            } else {
                # Install the item
                Write-Host 'Installing DotNet 3.5. Please wait, this may take a while...'
                [System.Boolean]$InstallIsSuccessful = if (Test-Object -IsEmpty $this.LocalSourcePath) {
                    $this.InstallProcess()
                } else {
                    $this.InstallProcessWithLocalSourcePath()
                }
                # Write the result
                [System.String]$ResultInFix = if ($InstallIsSuccessful) { 'was successful' } else { 'has failed' }
                Write-Verbose ('InstallDotNet35: The installation of the DotNet 3.5 {0}.' -f $ResultInFix)
                # Return the result
                $InstallIsSuccessful
            }
        }

        # Add the InstallDotNet35ORIGINAL method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallDotNet35ORIGINAL -Value {
            # If the item is already installed, then write the message and return true
            if ($this.TestDotNet35IsInstalled()) {
                Write-Host 'DotNet 3.5 is already installed. The installation will be skipped.'
                $true
            } else {
                # Install the item
                Write-Host 'Installing DotNet 3.5. Please wait, this may take a while...'
                [System.Boolean]$InstallIsSuccessful = $this.InstallProcess()
                # Write the result
                [System.String]$ResultInFix = if ($InstallIsSuccessful) { 'was successful' } else { 'has failed' }
                Write-Verbose ('InstallDotNet35: The installation of the DotNet 3.5 {0}.' -f $ResultInFix)
                # Return the result
                $InstallIsSuccessful
            }
        }

        # Add the InstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallProcess -Value {
            # Install DotNet
            Enable-WindowsOptionalFeature -Online -FeatureName $this.DotNet35FeatureName -NoRestart | Out-Null
            # Test if the installation is succesful
            [System.Boolean]$InstallationIsSuccesful = $this.TestDotNet35IsInstalled()
            # Return the result
            $InstallationIsSuccesful
        }

        # Add the InstallProcessWithLocalSourcePath method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallProcessWithLocalSourcePath -Value {
            # Install DotNet
            Install-WindowsFeature -Name Net-Framework-Core -Source $this.LocalSourcePath  | Out-Null
            # Test if the installation is succesful
            [System.Boolean]$InstallationIsSuccesful = $this.TestDotNet35IsInstalled()
            # Return the result
            $InstallationIsSuccesful
        }

        ####################################################################################################

        # Add the UninstallDotNet35 method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallDotNet35 -Value {
            # If the item is not installed, then write the message and return true
            if (-Not($this.TestDotNet35IsInstalled())) {
                Write-Host 'DotNet 3.5 not installed. The uninstall will be skipped.'
                $true
            } else {
                # Uninstall the item
                Write-Host 'Uninstalling DotNet 3.5. Please wait, this may take a while...'
                [System.Boolean]$UninstallIsSuccessful = $this.UninstallProcess()
                # Write the result
                [System.String]$ResultInFix = if ($UninstallIsSuccessful) { 'was successful' } else { 'has failed' }
                Write-Verbose ('UninstallDotNet35: The uninstall of the DotNet 3.5 {0}.' -f $ResultInFix)
                # Return the result
                $UninstallIsSuccessful
            }
        }

        # Add the UninstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallProcess -Value {
            # Uninstall DotNet
            Disable-WindowsOptionalFeature -Online -FeatureName $this.DotNet35FeatureName -Remove -NoRestart | Out-Null
            # Test if the uninstall is succcesful
            [System.Boolean]$UninstallIsSuccesful = (-Not($this.TestDotNet35IsInstalled()))
            $UninstallIsSuccesful
        }

        ####################################################################################################

        # Add the TestDotNet35IsInstalled method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestDotNet35IsInstalled -Value {
            # Test if DotNet 3.5 is installed
            Write-Verbose 'TestDotNet35IsInstalled: Testing if DotNet 3.5 is installed...'
            [System.Boolean]$DotNet35IsInstalled = (Get-WindowsOptionalFeature -Online | Where-Object { ($_.FeatureName -match $this.DotNet35FeatureName -and ($_.State -eq $this.StatusEnabled)) })
            # Write the result
            [System.String]$ResultInFix = if (-Not($DotNet35IsInstalled)) { ' NOT' }
            Write-Verbose ('TestDotNet35IsInstalled: DotNet 3.5 is{0} installed.' -f $ResultInFix)
            # Return the result
            $DotNet35IsInstalled
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

