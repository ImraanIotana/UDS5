####################################################################################################
<#
.SYNOPSIS
    This function deploys a Python module.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Start-PythonModuleDeployment -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Start-PythonModuleDeployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The object containing the needed information')]
        [PSCustomObject]
        $DeploymentObject,

        [Parameter(Mandatory=$false,HelpMessage='The action that will be performed')]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Output
        [System.Boolean]$DeploymentSuccess  = $null

        ####################################################################################################
    }
    
    process {
        # PREPARATION
        # Set the properties
        [System.String]$PipPathOnLocalSystem        = $DeploymentObject.PipPathOnLocalSystem
        [System.String]$ModulePathOnLocalSystem     = $DeploymentObject.ModulePathOnLocalSystem
        [System.String]$ModuleFileNameInSourceFiles = $DeploymentObject.ModuleFileNameInSourceFiles

        # VALIDATION
        # Switch on the action
        switch ($Action) {
            'Install'   {
                # Validate the ModulePathOnLocalSystem
                if (Test-String -IsEmpty $PipPathOnLocalSystem) { Write-Line "$PreFix The PipPathOnLocalSystem string is empty." -Type Fail ; Write-Line -Type ValidationFail ; Return }
                if (Test-Path -Path $PipPathOnLocalSystem) {
                        Write-Line "Pip.exe was found on the local system. ($PipPathOnLocalSystem)"
                } else {
                        Write-Line "Pip.exe was not found on the local system. ($PipPathOnLocalSystem)" -Type Fail ; Write-Line -Type ValidationFail ; Return
                }

                # Validate the properties
                if ((Test-String -IsEmpty $ModulePathOnLocalSystem) -and (Test-String -IsEmpty $ModuleFileNameInSourceFiles)) {
                    Write-Line "Both the ModulePathOnLocalSystem AND the ModuleFileNameInSourceFiles strings are empty. One of these is mandatory." -Type Fail ; Return
                }
                if ((Test-String -IsPopulated $ModulePathOnLocalSystem) -and (Test-String -IsPopulated $ModuleFileNameInSourceFiles)) {
                    Write-Line "Both the ModulePathOnLocalSystem AND the ModuleFileNameInSourceFiles strings are filled. Please remove one." -Type Fail ; Return
                }

                # Validate the ModulePathOnLocalSystem
                if (Test-String -IsPopulated $ModulePathOnLocalSystem) {
                    [System.Boolean]$FileIsPresentOnSystem = (Test-Path -Path $ModulePathOnLocalSystem)
                    if ($FileIsPresentOnSystem) {
                        Write-Line "The Module was found on the local system. ($ModulePathOnLocalSystem)"
                        [System.String]$ModulePath = $ModulePathOnLocalSystem
                    } else {
                        Write-Line "The Module was not found on the local system. ($ModulePathOnLocalSystem)" -Type Fail ; Write-Line -Type ValidationFail ; Return
                    }
                }

                # Validate the ModuleFileNameInSourceFiles
                if (Test-String -IsPopulated $ModuleFileNameInSourceFiles) {
                    [System.String]$ModulePath = Get-SourceItemPath -FileName $ModuleFileNameInSourceFiles
                    if (-Not($ModulePath)) { Write-Line -Type ValidationFail ; Return }
                }
            }
            'Uninstall' {
                Write-Line "No validation required during Uninstall."
            }
        }

        # Write the message
        Write-Line -Type ValidationSuccess

        # EXECUTION
        # Execute the deployment
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   {
                    Install-PythonModule -PipPath $PipPathOnLocalSystem -ModulePath $ModulePath
                }
                'Uninstall' {
                    Write-Line "The Python Module will not be removed during the Uninstall process. The Uninstall is considered successful." -Type Success
                    $true
                }
            }
        }
        catch {
            Write-FullError
        }

        ####################################################################################################
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################


####################################################################################################
<#
.SYNOPSIS
    This function installs a Python Module, using pip.exe on the local system.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains functions or variables, that are in other files.
.EXAMPLE
    Install-PythonModule -PipPath 'C:\Program Files\Python\pip.exe' -ModulePath 'C:\Program Files\MyApplication\MyModule.whl'
.INPUTS
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.3
    Author          : Imraan Iotana
    Creation Date   : November 2025
    Last Update     : November 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Install-PythonModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The path of pip.exe on the local system.')]
        [System.String]
        $PipPath,

        [Parameter(Mandatory=$true,HelpMessage='The path of the Python Module.')]
        [System.String]
        $ModulePath
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Output
        [System.Boolean]$InstallationSuccess = $null

        ####################################################################################################
    }
    
    process {
        # INSTALLATION
        $InstallationSuccess = try {
            # Install the module
            Write-Line "Installing the Python Module ($ModulePath). One moment please..." -Type Busy
            Install-Executable -Path $PipPath -AdditionalArguments "install `"$ModulePath`" --upgrade"
        }
        catch [System.Management.Automation.CommandNotFoundException] {
            Write-Line "The executable pip.exe was not found. Make sure Python is installed, and the Directory has been added to the PATH Environment Variable." -Type Fail
            $false
        }
        catch {
            Write-FullError
            $false
        }
    }
    
    end {
        # Return the output
        $InstallationSuccess
    }
}

### END OF SCRIPT
####################################################################################################
