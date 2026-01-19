####################################################################################################
<#
.SYNOPSIS
    This function ...
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
    This function is part of the Universal Deployment Script. It contains references to classes, functions or variables, that are in other files.
.EXAMPLE
    Function-Template -Initialize
.EXAMPLE
    Function-Template -Write -PropertyName OutputFolder -PropertyValue 'C:\Demo\WorkFolder'
.EXAMPLE
    Function-Template -Read -PropertyName OutputFolder
.EXAMPLE
    Function-Template -Remove -PropertyName OutputFolder
.EXAMPLE
    Deploy-MSI -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
    [System.Management.Automation.SwitchParameter]
.OUTPUTS
    This function returns no stream output.
    [System.Boolean]
    [System.String]
.NOTES
    Version         : 5.5.1
    Author          : Imraan Iotana
    Creation Date   : October 2025
    Last Update     : October 2025
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################

function Function-Template551 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='The object containing the needed information')]
        [PSCustomObject]
        $DeploymentObject,

        [Parameter(Mandatory=$false,HelpMessage='The action that will be performed')]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install',

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='The ID of the application that will be handled.')]
        [Alias('Application','ApplicationName','Name')]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $ApplicationID,

        [Parameter(Mandatory=$true,ParameterSetName='ParameterSetName1',HelpMessage='Switch for ... .')]
        [System.Management.Automation.SwitchParameter]
        $SwitchParameter,

        [Parameter(Mandatory=$true,HelpMessage='The subfolder of the application that must be retrieved.')]
        [ValidateSet('DocumentationFolder','AppLockerFolder','ShortcutsFolder','WorkFolder','MetadataFolder','BackupsFolder')]
        [System.String]
        $Subfolder,

        [Parameter(Mandatory=$false,HelpMessage='Switch for writing the details to the host.')]
        [System.Management.Automation.SwitchParameter]
        $OutHost,

        [Parameter(Mandatory=$false,HelpMessage='Switch for returning the result as a boolean.')]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    begin {
        ####################################################################################################
        ### MAIN PROPERTIES ###

        # Function
        [System.String[]]$FunctionDetails   = @($MyInvocation.MyCommand,$PSCmdlet.ParameterSetName,$PSBoundParameters.GetEnumerator())
        [System.String]$FunctionName        = $FunctionDetails[0]
        [System.String]$PreFix              = "[$($MyInvocation.MyCommand)]:"
        # Output
        [System.Boolean]$DeploymentSuccess  = $null
        [System.Boolean]$OutputObject       = $null
        [System.String]$OutputObject        = [System.String]::Empty
        # Validation
        [System.Collections.Generic.List[System.Boolean]]$ValidationArrayList = @()

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###

        function Confirm-Input {
            $ValidationArrayList.Add((Confirm-Object -MandatoryString $DeploymentObject.FolderToCopy))
            $ValidationArrayList.Add((Confirm-Object -MandatoryString $DeploymentObject.UserProfileLocation -ValidateSet $DeploymentObject.ValidateSetUserProfile))
        }

        function Confirm-Input {
            # Validate the DeploymentObject
            $ValidationArrayList.Add((Test-String -IsPopulated $DeploymentObject.InstallEXEBaseName))

            # VALIDATION DURING INSTALL
            if ($Action -eq 'Install') {
                # Validate the Install executable
                [System.String]$InstallEXEFileName = "$($DeploymentObject.InstallEXEBaseName).exe"
                [System.String]$Script:InstallEXEFilePath = Get-SourceItemPath -FileName $InstallEXEFileName
                $ValidationArrayList.Add((Confirm-Object -MandatoryItem $Script:InstallEXEFilePath))

                # Validate the Installation INF
                [System.String]$InstallINFBaseName = $DeploymentObject.InstallINFBaseName
                if (Test-String -IsPopulated $InstallINFBaseName) {
                    [System.String]$Script:InstallINFFilePath = Get-SourceItemPath -FileName "$($InstallINFBaseName).inf"
                    $ValidationArrayList.Add((Confirm-Object -MandatoryItem $Script:InstallINFFilePath))
                }
            }

            # VALIDATION DURING UNINSTALL
            if ($Action -eq 'Uninstall') {
                # Validate the Uninstall executable
                $ValidationArrayList.Add((Confirm-Object -MandatoryItem $DeploymentObject.UninstallEXEFilePath))
            }
        }

        ####################################################################################################
        ### SUPPORTING FUNCTIONS ###
        
        # Add the ReadProperty method
        function Read-Property { param([System.String]$Path,[System.String]$Name)
            try {
                # Write the message
                Write-Verbose ('ReadProperty: Reading the value of the property ({0}) in the RegistryKey ({1})...' -f $Name,$Path)
                # Read the Property
                [System.String]$PropertyValue = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue
            }
            catch [System.Management.Automation.PSArgumentException] {
                # The property does not exist in the registry
                Write-Verbose ('ReadProperty: The propertyname ({0}) does not exist in the RegistryKey ({1})' -f $Name,$Path)
                [System.String]$PropertyValue = $null
            }
            catch {
                Write-Host ('ReadProperty: An unknow error has occured.') -ForegroundColor Red
                [System.String]$PropertyValue = $null
            }
            # Add the OutputObject to the main object
            Add-Member -InputObject $this -NotePropertyName OutputObject -NotePropertyValue $PropertyValue
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

        # Switch on the ParameterSetName
        $DeploymentSuccess = switch ($FunctionDetails[1]) {
            'ParameterSetName1' { $this.InitializeRegistryKey($this.ParentRegistryKey) }
        }

        # EXECUTION
        try {
            $DeploymentSuccess = switch ($Action) {
                'Install'   { Install-INNOSetup -Path $InstallEXEFilePath -INF $InstallINFFilePath -AdditionalArguments $DeploymentObject.AdditionalInstallArguments -SuccessExitCodes $DeploymentObject.InstallSuccessExitCodes }
                'Uninstall' { Uninstall-INNOSetup -Path $DeploymentObject.UninstallEXEFilePath -AdditionalArguments $DeploymentObject.UninstallArguments -SuccessExitCodes $DeploymentObject.UninstallSuccessExitCodes }
            }
        }
        catch {
            Write-FullError
        }
    }
    
    end {
        # Return the output
        $DeploymentSuccess
    }
}

### END OF SCRIPT
####################################################################################################
