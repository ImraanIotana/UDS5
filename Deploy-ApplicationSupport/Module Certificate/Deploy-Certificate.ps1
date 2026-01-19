####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls a certificate.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Deploy-Certificate -Path 'C:\Temp\MyCertificate.cer' -Store 'TrustedPublisher' -Install
.EXAMPLE
    Deploy-Certificate -Path 'C:\Temp\MyCertificate.cer' -GetThumbprint
.INPUTS
    [System.String]
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

function Deploy-Certificate {
    [CmdletBinding()]
    param (
        # Path
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [Parameter(Mandatory=$true,ParameterSetName='Reinstall')]
        [Parameter(Mandatory=$true,ParameterSetName='Test')]
        [Parameter(Mandatory=$true,ParameterSetName='GetThumbprint')]
        [System.String]
        $Path,

        # Store
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [Parameter(Mandatory=$true,ParameterSetName='Reinstall')]
        [System.String]
        $Store,

        # Install
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [System.Management.Automation.SwitchParameter]
        $Install,

        # Uninstall
        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [System.Management.Automation.SwitchParameter]
        $Uninstall,

        # Reinstall
        [Parameter(Mandatory=$true,ParameterSetName='Reinstall')]
        [System.Management.Automation.SwitchParameter]
        $Reinstall,

        # Test
        [Parameter(Mandatory=$true,ParameterSetName='Test')]
        [System.Management.Automation.SwitchParameter]
        $Test,

        # GetThumbprint
        [Parameter(Mandatory=$true,ParameterSetName='GetThumbprint')]
        [System.Management.Automation.SwitchParameter]
        $GetThumbprint
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
            CertUtilExecutable      = [System.String](Join-Path -Path $env:SystemRoot -ChildPath 'System32\certutil.exe')
            CerExtension            = [System.String]'.cer'
            PfxExtension            = [System.String]'.pfx'
            ValidExtensions         = [System.String[]]@($this.CerExtension, $this.PfxExtension)
            PathCircumFix           = [System.String]'"{0}"'
            InstallArgument         = [System.String]'-f -addstore'
            SuccessExitCodes        = [System.String[]]@(0)
            PowerShellVersion       = [System.Int32]$PSVersionTable.PSVersion.Major
            # Input
            ItemPath                = [System.String[]]$Path
            CertificateStore        = [System.String[]]$Store
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
                    'Install'       { $this.OutputObject = $this.InstallSingleItem($this.ItemPath) }
                    'Uninstall'     { $this.OutputObject = $this.UninstallSingleItem($this.ItemPath) }
                    'Reinstall'     { $this.OutputObject = $this.UninstallSingleItem($this.ItemPath) ; if ($this.OutputObject) { $this.OutputObject = $this.InstallSingleItem($this.ItemPath) } }
                    'Test'          { $this.OutputObject = $this.TestSingleItemIsInstalled($this.ItemPath) }
                    'GetThumbprint' { $this.OutputObject = $this.GetThumbprint($this.ItemPath) }
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

        # Add the InstallSingleItem method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallSingleItem -Value { param([System.String]$ItemPath)
            # If the item is already installed, then write the message and return true
            if ($this.TestSingleItemIsInstalled($ItemPath)) {
                Write-Host ('The item is already installed. The installation will be skipped. ({0})' -f $ItemPath)
                $true
            } else {
                # Install the item
                Write-Host ('Installing the item... ({0})' -f $ItemPath)
                [System.Boolean]$InstallIsSuccessful = $this.InstallProcess($ItemPath)
                # Write the result
                [System.String]$ResultInFix = if ($InstallIsSuccessful) { 'was successful' } else { 'has failed' }
                Write-Verbose ('InstallSingleItem: The installation of the item {0}. ({1})' -f $ResultInFix, $ItemPath)
                # Return the result
                $InstallIsSuccessful
            }
        }

        # Add the InstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallProcess -Value { param([System.String]$ItemPath, [System.String]$Store)
            # Install the certificate
            Write-Verbose ("InstallProcess: Running the certutil process with the following arguments: $ArgumentList")
            # Create the argument list
            [System.String]$ItemPathInQuotes    = ($this.PathCircumFix -f $ItemPath)
            [System.String[]]$ArgumentList      = @($this.InstallArgument,$this.CertificateStore,$ItemPathInQuotes)
            # Run the certutil process
            [System.Int32]$ExitCode = (Start-Process -FilePath $this.CertUtilExecutable -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
            Write-Verbose ('InstallProcess: The ExitCode of the certutil Process is: ({0})' -f $ExitCode)
            # If the ExitCode is one of the succes codes, then the install is successful
            [System.Boolean]$InstallIsSuccessful = ($ExitCode -in $this.SuccessExitCodes)
            # Return the result
            $InstallIsSuccessful
        }

        ####################################################################################################

        # Add the UninstallSingleItem method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallSingleItem -Value { param([System.String]$ItemPath)
            # If the item is not installed, then write the message and return true
            if (-Not($this.TestSingleItemIsInstalled($ItemPath))) {
                Write-Host ('The item not installed. The uninstall of the item will be skipped. ({0})' -f $ItemPath)
                $true
            } else {
                # Uninstall the item
                Write-Host ('Uninstalling the item... ({0})' -f $ItemPath)
                [System.Boolean]$UninstallIsSuccessful = $this.UninstallProcess($ItemPath)
                # Write the result
                [System.String]$ResultInFix = if ($UninstallIsSuccessful) { 'was successful' } else { 'has failed' }
                Write-Verbose ('UninstallSingleItem: The uninstall of the item {0}. ({1})' -f $ResultInFix, $ItemPath)
                # Return the result
                $UninstallIsSuccessful
            }
        }

        # Add the UninstallProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallProcess -Value { param([System.String]$ItemPath)
            try {
                # Write the message
                Write-Verbose ('UninstallProcess: Removing the certificate: ({0})' -f $ItemPath)
                # Get the Thumbprint
                [System.String]$Thumbprint = $this.GetThumbprint($ItemPath)
                # Remove the certificate
                [void](Get-ChildItem -Path Cert:LocalMachine -Recurse | Where-Object { $_.Thumbprint -eq $Thumbprint } | Remove-Item)
                # Test if the removal was succesful
                [System.Boolean]$ProcessIsSuccessful = (-Not($this.TestSingleItemIsInstalled($ItemPath)))
                # Write and return the result
                Write-Verbose ('UninstallProcess: The Return Boolean of the removal process is: ({0})' -f $ProcessIsSuccessful)
                $ProcessIsSuccessful
            }
            catch {
                # Write the error and return null
                $Error[0] | Out-Host
                $null
            }
        }

        ####################################################################################################

        # Add the TestSingleItemIsInstalled method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestSingleItemIsInstalled -Value { param([System.String]$ItemPath)
            # Write the message
            Write-Verbose ('TestSingleItemIsInstalled: Testing if the item is installed... ({0})' -f $ItemPath)
            # Test if the item is installed
            [System.Boolean]$ItemIsInstalled = $this.TestProcess($ItemPath)
            # Write the result
            [System.String]$ResultInFix = if (-Not($ItemIsInstalled)) { ' NOT' }
            Write-Verbose ('TestSingleItemIsInstalled: The item is{0} installed. ({1})' -f $ResultInFix, $ItemPath)
            # Return the result
            $ItemIsInstalled
        }

        # Add the TestProcess method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestProcess -Value { param([System.String]$ItemPath)
            try {
                # Get the Thumbprint
                [System.String]$Thumbprint = $this.GetThumbprint($ItemPath)
                # Test if Certificate is installed
                Write-Verbose ('TestProcess: Testing if the certificate ({0}) is installed based on the Thumbprint... ({1})' -f $ItemPath, $Thumbprint)
                [System.Boolean]$CertificateIsInstalled = Get-ChildItem -Path Cert:LocalMachine -Recurse | Where-Object { $_.Thumbprint -eq $Thumbprint }
                # Write the result
                [System.String]$ResultInFix = if (-Not($CertificateIsInstalled)) { ' NOT' }
                Write-Verbose ('TestProcess: The certificate is{0} installed.' -f $ResultInFix)
                # Return the result
                $CertificateIsInstalled
            }
            catch {
                # Write the error and return null
                $Error[0] | Out-Host
                $null
            }
        }

        ####################################################################################################

        # Add the GetThumbprint method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetThumbprint -Value { param([System.String]$ItemPath)
            # Get the file extension
            [System.String]$FileExtension = (Get-ChildItem -Path $ItemPath).Extension
            # Switch on the file extension
            [System.String]$Thumbprint = switch ($FileExtension) {
                $this.CerExtension {
                    if ($this.PowerShellVersion -in 5,7) { $this.GetThumbprintFromCerPS5($ItemPath)}
                }
                $this.PfxExtension {
                    if ($this.PowerShellVersion -in 5,7) { $this.GetThumbprintFromPfxPS5($ItemPath)}
                }
                Default {}
            }
            # Return the Thumbprint
            $Thumbprint
        }

        # Add the GetThumbprintFromCerPS5 method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetThumbprintFromCerPS5 -Value { param([System.String]$ItemPath)
            try {
                # Get the Thumbprint
                Write-Verbose ('GetThumbprintFromCerPS5: Getting the Thumbprint of the certificate... ({0})' -f $ItemPath)
                [System.String]$Thumbprint = (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ItemPath)).Thumbprint
                Write-Verbose ('GetThumbprintFromCerPS5: The Thumbprint of the certificate ({0}) is: {1}' -f $ItemPath, $Thumbprint)
                $Thumbprint
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Write the error and return null
                Write-Host 'GetThumbprintFromCerPS5: The certificate requires a password. The Thumbprint could not be obtained.' -ForegroundColor Red
                $null
            }
            catch {
                # Write the error and return null
                $Error[0] | Out-Host
                $null
            }
        }

        # Add the GetThumbprintFromPfxPS5 method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetThumbprintFromPfxPS5 -Value { param([System.String]$ItemPath)
            try {
                # Get the Thumbprint
                Write-Verbose ('GetThumbprintFromPfxPS5: Getting the Thumbprint of the certificate... ({0})' -f $ItemPath)
                [System.String]$Thumbprint = (Get-PfxCertificate -FilePath $ItemPath).Thumbprint
                Write-Verbose ('GetThumbprintFromPfxPS5: The Thumbprint of the certificate ({0}) is: {1}' -f $ItemPath, $Thumbprint)
                $Thumbprint
            }
            catch [System.Management.Automation.MethodInvocationException] {
                # Write the error and return null
                Write-Host 'GetThumbprintFromPfxPS5: The certificate requires a password. The Thumbprint could not be obtained.' -ForegroundColor Red
                $null
            }
            catch {
                # Write the error and return null
                $Error[0] | Out-Host
                $null
            }
        }
    
        ####################################################################################################
   
        # Add the ValidateFileType method (Not yet in use)
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateFileType -Value { param([System.String]$ItemPath) 
            # Write the message
            Write-Host 'ValidateFileType: Testing if the file is an approved type...'
            # Get the file extension
            [System.String]$FileExtension = (Get-ChildItem -Path $ItemPath).Extension
            # Validate the file type
            [System.Boolean]$FileTypeIsValid = ($this.ValidExtensions -contains $FileExtension)
            # Write the result
            [System.String]$ResultInFix = if (-Not($FileTypeIsValid)) { ' NOT' }
            Write-Host ('ValidateFileType: The file type is{0} valid. ({1})' -f $ResultInFix, $FileExtension)
            # Return the result
            $FileTypeIsValid
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

