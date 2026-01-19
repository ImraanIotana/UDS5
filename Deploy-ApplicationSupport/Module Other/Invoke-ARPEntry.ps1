####################################################################################################
<#
.SYNOPSIS
    This function creates or removes an entry in Add/Remove Programs.
.DESCRIPTION
    This function is part of the Iotana Deployment Script. It may contain references to classes, functions or variables, that may be in other files.
    External classes    : [DeploymentHandler]
    External functions  : Test-Object
    External variables   -
.EXAMPLE
    Invoke-ARPEntry -DeploymentObject $MyObject -Action 'Install'
.INPUTS
    [PSCustomObject]
    [System.String]
.OUTPUTS
    [System.Boolean] (If the deployment was succesful, then $true is returned. Else $false is returned.)
.NOTES
    Version         : 3.1
    Author          : Imraan Noormohamed
    Creation Date   : April 2023
    Last Update     : September 2023
#>
####################################################################################################

function Invoke-ARPEntry {
    [CmdletBinding()]
    param (
        # The PSCustomObject containing properties that are needed for this function
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DeploymentObject,

        # Action to perform. Valid values are: Install, Uninstall, Reinstall.
        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall','Reinstall')]
        [System.String]
        $Action = 'Install'
    )
    
    begin {
        # Create the main object
        [PSCustomObject]$Local:MainObject = @{
            # Function
            DeploymentHandler       = [DeploymentHandler]::New()
            ValidationIsSuccessful  = [System.Boolean]$null
            DeploymentIsSuccessful  = [System.Boolean]$null
            # Input
            DeploymentObject        = [PSCustomObject]$DeploymentObject
            Action                  = [System.String]$Action
            # Handlers
            ARPParentPath           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
            ExpectedIconLocation    = Join-Path -Path $env:ProgramFiles -ChildPath $DeploymentObject.AssetID
            DefaultIcon             = '$env:SystemRoot\system32\shell32.dll,21'
            DefaultUninstallString  = 'calc.exe'
            InstallDate             = Get-Date -UFormat '%Y%m%d'
            # Messages
            Messages                = [System.Collections.Hashtable]@{
                # Testing
                TestingInstalled    = 'Testing if the ARP Entry exists in the Registry... ({0})'
                IsInstalled         = 'The ARP Entry exists in the Registry... ({0})'
                NotInstalled        = 'The ARP Entry does NOT exist in the Registry... ({0})'
                # Install
                InstalledSkip       = 'The ARP Entry is already present in the Registry. No action has been taken. ({0})'
                Installing          = 'Writing the ARP Entry into the Registry... ({0})'
                CreatingProperty    = 'Creating a property with the name ({0}) and the value ({1})...'
                InstallFailed       = 'The installation of the ARP Entry has failed. The ARP Entry was NOT detected in the Registry. ({0})'
                InstallSuccess      = 'The ARP Entry was succesfully written into the Registry. ({0})'
                # Uninstall
                NotInstalledSkip    = 'The ARP Entry is NOT present in the Registry. No action has been taken. ({0})'
                Uninstalling        = 'Removing the ARP Entry from the Registry... ({0})'
                UninstallFailed     = 'The removal of the ARP Entry has failed. The ARP Entry is still present in the Registry. ({0})'
                UninstallSuccess    = 'The ARP Entry was successfully removed. ({0})'
            }
        }

        ####################################################################################################

        # Add the Begin method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Begin -Value {
            # Write the Begin message
            Write-Verbose ('+++ BEGIN Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
            # Validate the input
            $this.ValidateInput()
            # Add the ARP Registry Path
            Add-Member -InputObject $this -NotePropertyName ARPRegistryPath -NotePropertyValue (Join-Path -Path $this.ARPParentPath -ChildPath $this.DeploymentObject.AssetID)
        }

        # Add the Process method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Process -Value {
            # If the validation was not successful, return
            if (-Not($this.ValidationIsSuccessful)) {
                # Write the error
                Write-Host 'The validation was NOT successful. The Process method will NOT start.' -ForegroundColor Red
                # Set DeploymentIsSuccessful to false and return
                $this.DeploymentIsSuccessful = $false
                Return
            }
            # Write the message
            Write-Host 'The validation was successful. The Process method will now start.'
            # Execute the proper action
            switch ($this.Action) {
                'Install'   { $this.Install() }
                'Uninstall' { $this.Uninstall() }
                'Reinstall' { $this.Uninstall() ; $this.Install() }
            }
        }

        # Add the End method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name End -Value {
            # Write the End message
            Write-Verbose ('___ END Function: [{0}] ParameterSetName: [{1}] Arguments: {2}' -f $this.FunctionName, $this.ParameterSetName, $this.FunctionArguments)
        }

        ####################################################################################################

        # Add the ValidateInput method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name ValidateInput -Value {
            # If both the DisplayName and the AssetID are empty
            if ((Test-Object -IsEmpty ($this.DeploymentObject.DisplayName)) -and (Test-Object -IsEmpty ($this.DeploymentObject.AssetID)) ) {
                # Write the error
                Write-Host 'Both the DisplayName and the AssetID are empty. One of these has to be filled.' -ForegroundColor Red
                # Set the validation to false
                $this.ValidationIsSuccessful = $false
            }
            # If the Version is empty
            elseif (Test-Object -IsEmpty ($this.DeploymentObject.DisplayVersion)) {
                # Write the error
                Write-Host 'The Version is empty.' -ForegroundColor Red
                # Set the validation to false
                $this.ValidationIsSuccessful = $false
            }
            # If the Publisher is empty
            elseif (Test-Object -IsEmpty ($this.DeploymentObject.Publisher)) {
                # Write the error
                Write-Host 'The Publisher is empty.' -ForegroundColor Red
                # Set the validation to false
                $this.ValidationIsSuccessful = $false
            }
            else {
                # Else set the validation to true
                $this.ValidationIsSuccessful = $true
            }
        }

        ####################################################################################################

        # Add the SetItemProperties method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name SetItemProperties -Value {
            # Set the Item Properties
            [System.Collections.Hashtable]$ItemProperties = @{
                DisplayName     = if (Test-Object -IsPopulated $this.DeploymentObject.DisplayName) { $this.DeploymentObject.DisplayName } else { $this.DeploymentObject.AssetID }
                DisplayVersion  = $this.DeploymentObject.DisplayVersion
                DisplayIcon     = if (Test-Object -IsPopulated $this.DeploymentObject.DisplayIcon) { $this.DeploymentHandler.GetFilePath($this.DeploymentObject.DisplayIcon, $this.ExpectedIconLocation) } else { $this.DefaultIcon }
                Publisher       = $this.DeploymentObject.Publisher
                UninstallString = if (Test-Object -IsPopulated $this.DeploymentObject.UninstallString) { $this.DeploymentObject.UninstallString } else { $this.DefaultUninstallString }
                InstallDate     = $this.InstallDate
            }
            # Add the Item Properties to the main object
            Add-Member -InputObject $this -NotePropertyName ItemProperties -NotePropertyValue $ItemProperties
        }

        ####################################################################################################

        # Add the TestARPEntryExists method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name TestARPEntryExists -Value {
            # Set the Path
            [System.String]$Path = $this.ARPRegistryPath
            # Write the message
            Write-Host ($this.Messages.TestingInstalled -f $Path)
            # Test if the ARP Registry Path exists
            [System.Boolean]$ARPRegistryPathExists = Test-Path -Path $Path
            # If the ARP Registry Path exists
            if ($ARPRegistryPathExists) {
                # Write the message and return true
                Write-Host ($this.Messages.IsInstalled -f $Path)
                Return $true
            } else {
                # Write the message and return false
                Write-Host ($this.Messages.NotInstalled -f $Path)
                Return $false
            }
        }

        ####################################################################################################

        # Add the Install method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Install -Value {
            # Set the Path
            [System.String]$Path = $this.ARPRegistryPath
            # If the ARP Entry exists
            if ($this.TestARPEntryExists()) {
                # Write the Skip message
                Write-Warning ($this.Messages.InstalledSkip -f $Path)
                # Set DeploymentIsSuccessful to true
                $this.DeploymentIsSuccessful = $true
            } else {
                # Write the Installing message
                Write-Host ($this.Messages.Installing -f $Path)
                # Create the ARPRegistryPath
                New-Item -Path $Path | Out-Null
                # Set the Item Properties
                $this.SetItemProperties()
                # Create the Properties
                $this.ItemProperties.GetEnumerator() | ForEach-Object {
                    # Write the message
                    Write-Host ($this.Messages.CreatingProperty -f $_.Name, $_.Value)
                    New-ItemProperty -Path $Path -Name $_.Name -Value $_.Value -Force | Out-Null
                }
                # Test if the Install was successful
                if ($this.TestARPEntryExists()) {
                    # Write the Success message
                    Write-Host ($this.Messages.InstallSuccess -f $Path) -ForegroundColor Green
                    # Set DeploymentIsSuccessful to true
                    $this.DeploymentIsSuccessful = $true
                } else {
                    # Write the Fail message
                    Write-FullError ($this.Messages.InstallFailed -f $Path)
                    # Set DeploymentIsSuccessful to false
                    $this.DeploymentIsSuccessful = $false
                }
            }
        }

        ####################################################################################################

        # Add the Uninstall method
        Add-Member -InputObject $Local:MainObject -MemberType ScriptMethod -Name Uninstall -Value {
            # Set the Path
            [System.String]$Path = $this.ARPRegistryPath
            # If the ARP Entry exists
            if ($this.TestARPEntryExists()) {
                # Write the Uninstalling message
                Write-Host ($this.Messages.Uninstalling -f $Path)
                # Remove the ARP Entry
                Remove-Item -Path $Path -Force
                # Test if the Uninstall was successful
                if ($this.TestARPEntryExists()) {
                    # Write the Fail message
                    Write-FullError ($this.Messages.UninstallFailed -f $Path)
                    # Set DeploymentIsSuccessful to false
                    $this.DeploymentIsSuccessful = $false
                } else {
                    # Write the Success message
                    Write-Host ($this.Messages.UninstallSuccess -f $Path) -ForegroundColor Green
                    # Set DeploymentIsSuccessful to true
                    $this.DeploymentIsSuccessful = $true
                }
            } else {
                # Write the Skip message
                Write-Warning ($this.Messages.NotInstalledSkip -f $Path)
                # Set DeploymentIsSuccessful to true
                $this.DeploymentIsSuccessful = $true
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
        Return $Local:MainObject.DeploymentIsSuccessful
        #endregion END
    }
}

