####################################################################################################
<#
.SYNOPSIS
    This class contains methods that handle the deployment of DotNet 3.5.
.DESCRIPTION
    This class is part of the Iotana Deployment Script. It contains references to classes, functions or variables, that are in other files.
    External classes    : -
    External functions  : -
    External variables  : $Global:DeploymentObject
.EXAMPLE
    $MyNewDeploymentHandler = [DeploymentHandler]::New()
.INPUTS
    -
.OUTPUTS
    [System.Boolean]
    [System.String]
    [System.String[]]
.NOTES
    Version         : 3.1
    Author          : Imraan Noormohamed
    Creation Date   : July 2023
    Last Updated    : August 2023
#>
####################################################################################################

class DeploymentHandler {

    # INITIALIZATION
    ####################################################################################################
    DeploymentHandler(){
    }

    # PROPERTIES
    ####################################################################################################
    # External Properties (used for GetFilePath and WriteAdministrationIntoRegistry)
    [PSCustomObject]$ExternalGlobalDeploymentObject = $Global:DeploymentObject
    # Administration properties
    [System.String]$AdministrationParentKey = ('HKLM:\SOFTWARE\{0} Application Administration' -f $this.ExternalGlobalDeploymentObject.CompanyName)
    [System.String]$AdministrationKey       = (Join-Path -Path $this.AdministrationParentKey -ChildPath $this.ExternalGlobalDeploymentObject.AssetID)
    [System.String[]]$UnneededProperties    = @('CompanyName','DeploymentObjects','SupportScriptsFolder')


    # METHODS
    ####################################################################################################

    # PUBLIC METHOD PrepareDeployment
    [void]PrepareDeployment([PSCustomObject]$GlobalDeploymentObject) {
        # Validate the AssetID
        #$this.ValidateAssetID($GlobalDeploymentObject.AssetID)
        # Start logging
        #$this.StartLogging($GlobalDeploymentObject)
        # Validate the Deployment Objects Array
        #$this.ValidateDeploymentObjectsArray($GlobalDeploymentObject)
        # Set the WorkFolder
        #$this.SetWorkFolder($GlobalDeploymentObject.Rootfolder)
        # Calculate the size of the WorkFolder
        #$this.CalculateFolderSize($GlobalDeploymentObject.Rootfolder)
    }

    # PUBLIC METHOD PostpareDeployment
    [void]PostpareDeployment() {
        # Write the Administration into the registry
        #$this.WriteAdministrationIntoRegistry()
        # Stop logging
        #$this.StopLogging()
    }

    ####################################################################################################

    <# PUBLIC METHOD ValidateAssetID
    [void]ValidateAssetID([System.String]$AssetIDToValidate) {
        # Write the message
        Write-Verbose ('[DeploymentHandler]: ValidateAssetID: Validating the AssetID... ({0})' -f $AssetIDToValidate)
        # Validate the AssetID
        if ($AssetIDToValidate -eq '<<ASSETID>>') {
            # Write the message and exit the script
            Write-Fail '[DeploymentHandler]: ValidateAssetID: The AssetID still contains the default value (<<ASSETID>>). The deployment will not start.'
            Exit
        } elseif ($this.StringIsEmpty($AssetIDToValidate)) {
            # Write the message and exit the script
            Write-Fail '[DeploymentHandler]: ValidateAssetID: The AssetID string is empty. The deployment will not start.'
            Exit
        } else {
            # Write the message
            Write-Success '[DeploymentHandler]: ValidateAssetID: The AssetID is valid.'
        }
    }#>

    ####################################################################################################

    <# PUBLIC METHOD StartLogging
    [void]StartLogging([PSCustomObject]$GlobalDeploymentObject) {
        # Get the AssetID
        [System.String]$LogFileName    = ('{0}_{1}_{2}.log' -f $GlobalDeploymentObject.AssetID, $GlobalDeploymentObject.TimeStamp, $GlobalDeploymentObject.Action)
        [System.String]$LogFolder      = $GlobalDeploymentObject.LogFolder
        #[System.String]$LogFolder      = (Join-Path -Path $Env:SystemRoot -ChildPath 'System32\LogFiles')
        #[System.String]$LogFolder      = (Join-Path -Path $env:ProgramData -ChildPath 'Intune\Logs')
        [System.String]$LogFilePath    = (Join-Path -Path $LogFolder -ChildPath $LogFileName)
        # Write the message
        Write-Verbose ('StartLogging: Creating the logfolder... ({0})' -f $LogFolder)
        # Create the logfolder
        $this.CreateFolder($LogFolder)
        # Start logging
        Write-Verbose ('StartLogging: Starting logging. Logfile: ({0})' -f $LogFilePath)
        Start-Transcript -Path $LogFilePath | Out-Null
    }

    # PUBLIC METHOD StopLogging
    [void]StopLogging() {
        # Stop PowerShell logging
        Stop-Transcript
    }#>

    ####################################################################################################

    <# PUBLIC METHOD WriteAdministrationIntoRegistry
    [void]WriteAdministrationIntoRegistry() {
        # Refresh the object to get the most recent changes (For unknown reason this PSCustomObject turned into a Hashtable)
        $this.ExternalGlobalDeploymentObject = $Global:DeploymentObject
        # Remove the unneeded properties from the hashtable
        $this.UnneededProperties | ForEach-Object { Write-Verbose ('[DeploymentHandler]: Removing unneeded Property... ({0})' -f $_) ; $this.ExternalGlobalDeploymentObject.Remove($_) }
        # Write the Administration into the registry
        Write-Line "[DeploymentHandler]: Writing the deployment information into the registry... ($($this.AdministrationKey))"
        if (-Not(Test-Path -Path $this.AdministrationKey)) { New-Item $this.AdministrationKey -Force | Out-Null }
        $this.ExternalGlobalDeploymentObject.GetEnumerator() | ForEach-Object { Set-ItemProperty -Path $this.AdministrationKey -Name $_.Name -Value $_.Value -Force }
    }#>

    ####################################################################################################

    # PUBLIC METHOD StringIsEmpty
    [System.Boolean]StringIsEmpty([System.String]$StringToTest) {
        # Write the message
        Write-Verbose ('StringIsEmpty (DeploymentHandler): Testing if the string is empty... ({0})' -f $StringToTest)
        # Test if the string is empty        
        [System.Boolean]$StringIsEmpty = [System.String]::IsNullOrWhiteSpace($StringToTest)
        # Write the result
        if ($StringIsEmpty) { Write-Verbose 'StringIsEmpty (DeploymentHandler): The string is empty.' } else { Write-Verbose 'StringIsEmpty (DeploymentHandler): The string is not empty.' }
        # Return the result
        Return $StringIsEmpty
    }
    
    # PUBLIC METHOD StringIsPopulated
    [System.Boolean]StringIsPopulated([System.String]$StringToTest) {
        # Write the message
        Write-Verbose ('StringIsPopulated (DeploymentHandler): Testing if the string is populated... ({0})' -f $StringToTest)
        # Test if the string is populated        
        [System.Boolean]$StringIsPopulated = (-Not($this.StringIsEmpty($StringToTest)))
        # Write the result
        if ($StringIsPopulated) { Write-Verbose 'StringIsPopulated (DeploymentHandler): The string is populated.' } else { Write-Verbose 'StringIsPopulated (DeploymentHandler): The string is not populated.' }
        # Return the result
        Return $StringIsPopulated
    }
    
    # PUBLIC METHOD ArrayIsPopulated
    [System.Boolean]ArrayIsPopulated([System.Object[]]$ArrayToTest) {
        # Write the message
        Write-Verbose "ArrayIsPopulated (DeploymentHandler): Testing if the array is populated... ($ArrayToTest)"
        # Test if the collection is populated
        [System.Boolean]$ArrayIsPopulated = ($ArrayToTest.Count -gt 0)
        # Write the result
        [System.String]$ResultInFix = if (-Not($ArrayIsPopulated)) { ' NOT' }
        Write-Verbose ('ArrayIsPopulated (DeploymentHandler): The array is{0} populated.' -f $ResultInFix)
        # Return the result
        Return $ArrayIsPopulated
    }

    ####################################################################################################

    # PUBLIC METHOD GetFilePath WITHOUT PATH
    [System.String]GetFilePath([System.String]$FileName) {
        # Call the GetFilePath method with the Global Rootfolder/WorkFolder
        Return ($this.GetFilePath($FileName, $this.ExternalGlobalDeploymentObject.Rootfolder))
    }

    # PUBLIC METHOD GetFilePath WITH PATH
    [System.String]GetFilePath([System.String]$FileName,[System.String]$Path) {
        # Write the message
        Write-Verbose ('GetFilePath: Searching for the file ({0}) in the folder ({1}) and all subfolders...' -f $FileName, $Path)
        # Search the file
        [System.String]$FilePath = (Get-ChildItem -Path $Path -Recurse -Filter $FileName -ErrorAction SilentlyContinue).FullName
        # If the file was NOT found
        if ($this.StringIsEmpty($FilePath)) {
            # Write the error
            Write-Host ('GetFilePath: The file ({0}) was NOT found in the folder ({1}) or any subfolder.' -f $FileName, $Path) -ForegroundColor Red
        } else {
            # Write the message
            Write-Verbose ('GetFilePath: The file was found. The full path is: ({0})' -f $FilePath)
        }
        # Return the file path
        Return $FilePath
    }

    # PUBLIC METHOD CreateFullPathsArrayFromFileNames WITHOUT PATH
    [System.String[]]CreateFullPathsArrayFromFileNames([System.String[]]$FileNamesArray) {
        # Write the message
        Write-Verbose "CreateFullPathsArrayFromFileNames: Create the FullPathsArray from the filenames... ($FileNamesArray)"
        # Create an empty array
        [System.String[]]$FullPathsArray = @()
        # Add the full paths to the array
        foreach ($FileName in $FileNamesArray) { $FullPathsArray += $this.GetFilePath($FileName) }
        # Write the FullPathsArray
        Write-Verbose "CreateFullPathsArrayFromFileNames: The FullPathsArray is: ($FullPathsArray)"
        # Return the FullPathsArray
        Return $FullPathsArray
    }

    ####################################################################################################

    # PUBLIC METHOD ValidateMandatoryFile
    [System.Boolean]ValidateMandatoryFile([System.String]$FileName) {
        # Write the message
        Write-Verbose ('ValidateMandatoryFile: Testing if the string is empty... ({0})' -f $FileName)
        # If the FileName is empty
        if ($this.StringIsEmpty($FileName)) {
            # Return false
            Write-Host ('ValidateMandatoryFile: The string is empty. ({0})' -f $FileName) -ForegroundColor Red
            Return $false
        } else {
            # Else write the message
            Write-Verbose ('ValidateMandatoryFile: The string is not empty. Testing if the file exists... ({0})' -f $FileName)
            # If the file can not be found
            [System.String]$FilePath = $this.GetFilePath($FileName)
            if ($this.StringIsEmpty($FilePath)) {
                # Return false
                Write-Host ('ValidateMandatoryFile: The file was NOT found: ({0})' -f $FileName) -ForegroundColor Red
                Return $false
            } else {
                # Return true
                Write-Verbose ('ValidateMandatoryFile: The file was found: ({0})' -f $FilePath)
                Return $true
            }
        }
    }
    
    # PUBLIC METHOD ValidateOptionalFile
    [System.Boolean]ValidateOptionalFile([System.String]$FileName) {
        # Write the message
        Write-Verbose ('ValidateOptionalFile: Testing if the string is empty... ({0})' -f $FileName)
        # If the FileName is empty
        if ($this.StringIsEmpty($FileName)) {
            # Return true
            Write-Verbose 'ValidateOptionalFile: The string is empty. No further actions needed.'
            Return $true
        } else {
            # Else write the message
            Write-Verbose ('ValidateOptionalFile: The string is not empty. Testing if the file exists... ({0})' -f $FileName)
            # If the file can not be found
            [System.String]$FilePath = $this.GetFilePath($FileName)
            if ($this.StringIsEmpty($FilePath)) {
                # Return false
                Write-Host ('ValidateOptionalFile: The file was NOT found: ({0})' -f $FileName) -ForegroundColor Red
                Return $false
            } else {
                # Return true
                Write-Verbose ('ValidateOptionalFile: The file was found: ({0})' -f $FilePath)
                Return $true
            }
        }
    }
    
    # PUBLIC METHOD ValidateMandatoryFileArray
    [System.Boolean]ValidateMandatoryFileArray([System.String[]]$FileNameArray) {
        # Write the message
        Write-Verbose "ValidateMandatoryFileArray: Testing if the array is empty... ($FileNameArray)"
        # If the array is empty
        if ($FileNameArray.Count -eq 0) {
            # Return false
            Write-Host 'ValidateMandatoryFileArray: The array is empty.' -ForegroundColor Red
            Return $false
        } else {
            # Write the message
            Write-Verbose 'ValidateMandatoryFileArray: The array is NOT empty. Each filename in the array will now be validated.'
            # Create an empty result array
            [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()
            # Check each filename, and add the result to the result array
            $FileNameArray | ForEach-Object { $ResultArray.Add($this.ValidateMandatoryFile($_)) }
            # Test the result array
            Write-Verbose ('ValidateMandatoryFileArray: Testing if the result array contains $false...')
            if ($ResultArray -contains $false) {
                # Return false
                Write-Host ('ValidateMandatoryFileArray: The result array contains $false.') -ForegroundColor Red
                Return $false
            } else {
                # Return true
                Write-Verbose ('ValidateMandatoryFileArray: The result array contains only $true.')
                Return $true
            }
        }
    }
    
    # PUBLIC METHOD ValidateOptionalFileArray
    [System.Boolean]ValidateOptionalFileArray([System.String[]]$FileNameArray) {
        # Write the message
        Write-Verbose "ValidateOptionalFileArray: Testing if the array is empty... ($FileNameArray)"
        # If the array is empty
        if ($FileNameArray.Count -eq 0) {
            # Return true
            Write-Verbose 'ValidateOptionalFileArray: The array is empty. No further actions needed.'
            Return $true
        } else {
            # Write the message
            Write-Verbose 'ValidateOptionalFileArray: The array is NOT empty. Each filename in the array will now be validated.'
            # Create an empty result array
            [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()
            # Check each filename, and add the result to the result array
            $FileNameArray | ForEach-Object { $ResultArray.Add($this.ValidateMandatoryFile($_)) }
            # Test the result array
            Write-Verbose ('ValidateOptionalFileArray: Testing if the result array contains $false...')
            if ($ResultArray -contains $false) {
                # Return false
                Write-Host ('ValidateOptionalFileArray: The result array contains $false.') -ForegroundColor Red
                Return $false
            } else {
                # Return true
                Write-Verbose ('ValidateOptionalFileArray: The result array contains only $true.')
                Return $true
            }
        }
    }

    ####################################################################################################

    <# PUBLIC METHOD ValidateDeploymentObjectsArray
    [void]ValidateDeploymentObjectsArray([PSCustomObject]$GlobalDeploymentObject) {
        # Write the message
        Write-Verbose 'Validating the Deployment Objects Array...'
        # Get the DeploymentObjectsArray
        [PSCustomObject[]]$DeploymentObjectsArray = $GlobalDeploymentObject.DeploymentObjects
        # If the DeploymentObjectsArray is not empty
        if ($DeploymentObjectsArray.Count -gt 0) {
            # Write the message
            Write-Success '[DeploymentHandler]: The Deployment Objects Array is valid.'
            # Write the amount of objects
            Write-Line ('[DeploymentHandler]: There are ({0}) Objects to deploy.' -f $DeploymentObjectsArray.Count)        
            # During uninstall, if the boolean ReverseUninstallOrder is true, then reverse the DeploymentObjectsArray order
            if (($GlobalDeploymentObject.Action -eq 'Uninstall') -and ($GlobalDeploymentObject.ReverseUninstallOrder -eq $true)) {
                Write-Warning 'The deployment order will be reversed during Uninstall.'
                [array]::Reverse($DeploymentObjectsArray)
            }

        } else {
            # Write the message and Exit
            Write-Fail '[DeploymentHandler]: The Deployment Objects Array is empty. The deployment will not start.'
            Exit
        }
         
    }#>

    ####################################################################################################

    <# PUBLIC METHOD SetWorkFolder
    [void]SetWorkFolder([System.String]$WorkFolder) {
        # Write the message
        Write-Verbose ('Setting the folder where the file Deploy-Application.ps1 is located, as the Work Folder... ({0})' -f $WorkFolder)
        # Set the WorkFolder
        Set-Location -Path $WorkFolder
    }#>

    ####################################################################################################

    <# PUBLIC METHOD CalculateFolderSize
    [void]CalculateFolderSize([System.String]$Path){
        # Calculate the size of the Folder
        Write-Verbose ('CalculateFolderSize: Calculating the size of the Folder... ({0})' -f $Path)
        $SizeOfFolder = ( (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB )
        # Write the message
        Write-Verbose ('CalculateFolderSize: The size of the Work Folder is: {0:N0} MB.' -f $SizeOfFolder)
    }#>

    ####################################################################################################

    # PRIVATE METHOD CreateFolder
    [void]CreateFolder([System.String]$FolderToCreate){
        # Create the folder if it does not exist
        Write-Verbose ('CreateFolder: Testing if the folder exists... ({0})' -f $FolderToCreate)
        if (Test-Path $FolderToCreate) {
            Write-Verbose ('CreateFolder: The folder already exists. No action has been taken ({0})' -f $FolderToCreate)
        } else {
            Write-Verbose ('CreateFolder: The folder does not exist. Creating the folder... ({0})' -f $FolderToCreate)
            New-Item -Path $FolderToCreate -ItemType Directory | Out-Null
        }
    }

    ####################################################################################################
}

