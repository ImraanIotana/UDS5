####################################################################################################
<#
.SYNOPSIS
    This function creates an Active Setup entry in the Registry.
.DESCRIPTION
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Deploy-ActiveSetup -DeploymentObject $DeploymentObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : August 2025
    Last Update     : September 2025
#>
####################################################################################################

function Deploy-ActiveSetup {
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

        # Function
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        [System.String]$FunctionName        = $FunctionDetails[0]
        # Output
        [System.Boolean]$DeploymentSuccess  = $null
        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()

        ####################################################################################################
        ### EXTRA PROPERTIES ###

        # Get the ApplicationID
        [System.String]$ApplicationID       = $Global:DeploymentObject.AssetID
        [System.String]$REGExeFilePath      = Join-Path -Path $ENV:SystemRoot -ChildPath 'System32\REG.exe'


        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            $ValidationArrayList.Add((Confirm-Object -MandatoryString $DeploymentObject.HKCURegFileName))
        }

        function Copy-RegFileToProgramData { param([System.String]$HKCURegFileName,[System.String]$SubfolderName = $ApplicationID)
            try {
                # Create the destination folder
                [System.String]$DestinationFolder = Join-Path -Path $ENV:ProgramData -ChildPath $SubfolderName
                New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
                # Copy the file
                [System.String]$HKCURegFilePath = Get-SourceItemPath -FileName $HKCURegFileName
                Write-Line ('[{0}]: Copying the regfile ({1}) to the folder ({2})' -f $FunctionName,$HKCURegFileName,$DestinationFolder)
                Copy-Item -Path $HKCURegFilePath -Destination $DestinationFolder -Force
                # Get the path of the destination file
                [System.String]$RegFileToImportFullPath = Join-Path -Path $DestinationFolder -ChildPath $HKCURegFileName
                # Return the result
                $RegFileToImportFullPath
            }
            catch {
                # Write the error and return null
                Write-FullError ; $null
            }
        }
    
        function Import-RegFileForInstallingUser { param([System.String]$RegFileToImportFullPath,[System.String]$REGExeFilePath = $REGExeFilePath)
            try {
                # Import the regfile
                Write-Line ('[{0}]: Importing the regfile into the Registry... ({1})' -f $FunctionName,$RegFileToImportFullPath)
                [System.Int32]$ExitCode = (Start-Process -FilePath $REGExeFilePath -ArgumentList ('import', ('"{0}"' -f $RegFileToImportFullPath) ) -Wait -PassThru).ExitCode
                if ($ExitCode -eq 0) {
                    Write-Line ('[{0}]: The regfile ({1}) has been successfullly imported into the Registry.' -f $FunctionName,$RegFileToImportFullPath)
                    $true
                } else {
                    Write-Line ('[{0}]: The import of the regfile ({1}) has failed. Please make sure this script is run with Administrative Rights.' -f $FunctionName,$RegFileToImportFullPath) -Type Fail
                    $false
                }
            }
            catch {
                # Write the error and return false
                Write-FullError ; $false
            }
        }
    
        function New-ActiveSetupEntry { param([System.String]$HKCURegFileInProgramDataPath,[System.String]$KeyName = $ApplicationID)
            try {
                # Set the properties
                [System.String]$HKLMKeyPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{0}' -f $KeyName
                # Create the key
                Write-Line ('[{0}]: Creating the Active Setup key in the Registry... ({1})' -f $FunctionName,$HKLMKeyPath)
                New-Item -Path $HKLMKeyPath -Force | Out-Null
                # Create the properties
                New-ItemProperty -Path $HKLMKeyPath -Name StubPath -Value ('regedit.exe /s "{0}"' -f $HKCURegFileInProgramDataPath) -PropertyType String -Force
                New-ItemProperty -Path $HKLMKeyPath -Name Version -Value '1.0' -PropertyType String -Force
                # Return true
                $true
            }
            catch {
                # Write the error and return false
                Write-FullError ; $false
            }
        }

        ####################################################################################################

        # Validate the input
        Confirm-Input
    }
    
    process {
        # If the validation failed, then return
        if ($ValidationArrayList -contains $false) { Write-Line -Type ValidationFail ; Return }

        # VALIDATION - SUCCESS
        # Write the message
        Write-Line -Type ValidationSuccess

        # Switch on the Action
        $DeploymentSuccess = switch ($Action) {
            'Install'   {
                [System.String]$RegFileToImportFullPath = Copy-RegFileToProgramData -HKCURegFileName $DeploymentObject.HKCURegFileName
                Import-RegFileForInstallingUser -RegFileToImportFullPath $RegFileToImportFullPath | Out-Null
                New-ActiveSetupEntry -HKCURegFileInProgramDataPath $RegFileToImportFullPath
            }
            'Uninstall' { Write-Line ('[{0}]: The method for Uninstall has not been defined yet.' -f $FunctionName) }
            'Reinstall' { Write-Line ('[{0}]: The method for Reinstall has not been defined yet.' -f $FunctionName) }
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################
