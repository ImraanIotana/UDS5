####################################################################################################
<#
.SYNOPSIS
    This function installs or uninstalls an MSIX.
.DESCRIPTION
    This function is self-contained and does not refer to functions, variables or classes, that are in other files.
.EXAMPLE
    Deploy-MSIX -Path 'C:\Temp\MyApp.msix' -Install
.EXAMPLE
    Deploy-MSIX -Test -Path @('C:\Temp\MyApp1.msix', 'C:\Temp\MyApp2.msix')
.INPUTS
    [System.String[]]
    [System.Management.Automation.SwitchParameter]
    [System.String]
.OUTPUTS
    [System.Boolean]
.NOTES
    Version         : 3.2
    Author          : Imraan Noormohamed
    Creation Date   : August 2023
    Last Update     : August 2023
#>
####################################################################################################

function Deploy-MSIX {
    [CmdletBinding()]
    param (
        # Path
        [Parameter(Mandatory=$true,ParameterSetName='Install')]
        [Parameter(Mandatory=$true,ParameterSetName='Uninstall')]
        [Parameter(Mandatory=$true,ParameterSetName='Reinstall')]
        [Parameter(Mandatory=$true,ParameterSetName='Test')]
        [System.String[]]
        $Path,

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

        # GetPackageFullName
        [Parameter(Mandatory=$true,ParameterSetName='GetPackageFullName')]
        [System.String]
        $GetPackageFullName
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
            # Input
            ItemArray               = [System.String[]]$Path
            SearchString            = [System.String]$GetPackageFullName
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
                    'Install'               { $this.OutputObject = $this.InstallItemArray($this.ItemArray) }
                    'Uninstall'             { $this.OutputObject = $this.UninstallItemArray($this.ItemArray) }
                    'Reinstall'             { $this.OutputObject = $this.UninstallItemArray($this.ItemArray) ; if ($this.OutputObject) { $this.OutputObject = $this.InstallItemArray($this.ItemArray) } }
                    'Test'                  { $this.OutputObject = $this.TestItemArrayIsInstalled($this.ItemArray) }
                    'GetPackageFullName'    { $this.OutputObject = $this.GetPackageFullName($this.SearchString) }
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

        # Add the InstallItemArray method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallItemArray -Value { param([System.String[]]$ItemArray)
            # Write the message
            Write-Verbose "InstallItemArray: Each item in the array will now be installed... ($ItemArray)"
            # Create an empty result array
            [System.Boolean[]]$ResultArray = @()
            # Install each item, and add the result to the result array
            $ItemArray | ForEach-Object { $ResultArray += $this.InstallSingleItem($_) }
            # Test the result array
            Write-Verbose ('InstallItemArray: Testing if the result array contains only $true...')
            [System.Boolean]$InstallSequenceIsSuccessful = (-Not($ResultArray -contains $false))
            # Write the result
            [System.String]$ResultInFix = if ($InstallSequenceIsSuccessful) { 'All items have been successfully installed' } else { 'The installation of (one of) the items has failed' }
            Write-Verbose ('InstallItemArray: {0}.' -f $ResultInFix)
            # Return the result
            $InstallSequenceIsSuccessful
        }

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
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name InstallProcess -Value { param([System.String]$ItemPath)
            # Install the MSIX
            Add-AppProvisionedPackage -Online -PackagePath $ItemPath -SkipLicense | Out-Null
            # Test the installation
            [System.Boolean]$InstallIsSuccessful = ($this.TestSingleItemIsInstalled($ItemPath))
            # Return the result
            $InstallIsSuccessful
        }

        ####################################################################################################

        # Add the UninstallItemArray method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallItemArray -Value { param([System.String[]]$ItemArray)
            # Write the message
            Write-Verbose "UninstallItemArray: Each item in the array will now be uninstalled... ($ItemArray)"
            # Create an empty result array
            [System.Boolean[]]$ResultArray = @()
            # Uninstall each item, and add the result to the result array
            $ItemArray | ForEach-Object { $ResultArray += $this.UninstallSingleItem($_) }
            # Test the result array
            Write-Verbose ('UninstallItemArray: Testing if the result array contains $false...')
            [System.Boolean]$UninstallSequenceIsSuccessful = (-Not($ResultArray -contains $false))
            # Write the result
            [System.String]$ResultInFix = if ($UninstallSequenceIsSuccessful) { 'All items have been successfully uninstalled' } else { 'The uninstall of (one of) the items has failed' }
            Write-Verbose ('UninstallItemArray: {0}.' -f $ResultInFix)
            # Return the result
            $UninstallSequenceIsSuccessful
        }

        # Add the UninstallSingleItem method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name UninstallSingleItem -Value { param([System.String]$ItemPath)
            # If the item is not installed, then write the message and return true
            if (-Not($this.TestSingleItemIsInstalled($ItemPath))) {
                Write-Host ('The item not installed. The uninstall will be skipped. ({0})' -f $ItemPath)
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
            # Get the basename of the item
            [System.String]$ItemBaseName = (Get-ChildItem -Path $ItemPath).BaseName
            # Get the PackageFullName
            [System.String]$PackageFullName = $this.GetPackageFullName($ItemBaseName)
            # Uninstall the MSIX
            Remove-AppxPackage -Package $PackageFullName -AllUsers
            # Test the uninstall
            [System.Boolean]$UninstallIsSuccessful = (-Not($this.TestSingleItemIsInstalled($ItemPath)))
            # Return the result
            $UninstallIsSuccessful
        }

        ####################################################################################################

        # Add the TestItemArrayIsInstalled method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestItemArrayIsInstalled -Value { param([System.String[]]$ItemArray)
            # Write the message
            Write-Verbose "TestItemArrayIsInstalled: Each item in the array will now be tested... ($ItemArray)"
            # Create an empty result array
            [System.Boolean[]]$ResultArray = @()
            # Test each item, and add the result to the result array
            $ItemArray | ForEach-Object { $ResultArray += $this.TestSingleItemIsInstalled($_) }
            # Test the result array
            Write-Verbose ('TestItemArrayIsInstalled: Testing if the result array contains $false...')
            [System.Boolean]$AllItemsAreInstalled = (-Not($ResultArray -contains $false))
            # Write the result
            [System.String]$ResultInFix = if ($AllItemsAreInstalled) { 'All items are installed' } else { 'At least one of the items is not installed' }
            Write-Verbose ('TestItemArrayIsInstalled: {0}.' -f $ResultInFix)
            # Return the result
            $AllItemsAreInstalled
        }

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
            # Get the basename of the item
            [System.String]$ItemBaseName = (Get-ChildItem -Path $ItemPath).BaseName
            Write-Verbose ('TestProcess: The Basename of the item is: ({0})' -f $ItemBaseName)
            [System.Boolean]$ItemIsInstalled = $this.GetPackageFullName($ItemBaseName)
            # Return the result
            $ItemIsInstalled
        }

        ####################################################################################################

        # Add the GetPackageFullName method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name GetPackageFullName -Value { param([System.String]$SearchString)
            # Set the string to lower case
            [System.String]$StringLowerCase = $SearchString.ToLower()
            # When an MSIX file is updated, the basename can contain a buildnumber (e.g. '_1'). So the test will be, if the search string (longer) contains the PackageFullName (shorter).
            Write-Verbose ('GetPackageFullName: Getting the PackageFullNames, and testing if the search string ({0}) contains the PackageFullName...' -f $SearchString)
            [System.String]$InstalledPackageFullName = (Get-AppXPackage -AllUsers) | Where-Object { $StringLowerCase.Contains($_.PackageFullName.ToLower()) }
            # Return the result
            $InstalledPackageFullName
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
