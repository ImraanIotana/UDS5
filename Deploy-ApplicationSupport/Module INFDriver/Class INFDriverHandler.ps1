####################################################################################################
<#
.SYNOPSIS
    This class contains methods that handle the deployment of INF drivers.
.DESCRIPTION
    This class is self-contained and does not refer to functions and variables, that are in other files.
.EXAMPLE
    $MyNewINFDriverHandler = [INFDriverHandler]::New()
.INPUTS
    -
.OUTPUTS
    [System.Boolean]InstallINFDriverArray
    [System.Boolean]UninstallINFDriverArray
.NOTES
    Version         : 3.1
    Author          : Imraan Noormohamed
    Creation Date   : July 2023
    Last Updated    : August 2023
#>
####################################################################################################

class INFDriverHandler {

    # INITIALIZATION
    ####################################################################################################
    INFDriverHandler(){
        # Write the loading message
        Write-Verbose '+++ CLASS: Loading Class INFDriverHandler'
    }


    # PROPERTIES
    ####################################################################################################
    # PNP Executable
    [System.String]$PNPUtilExecutable   = (Join-Path -Path $env:SystemRoot -ChildPath 'System32\pnputil.exe')
    # PNP Arguments
    [System.String[]]$ArgumentList      = @()
    [System.String]$INFArgumentFix      = '"{0}"'
    [System.String]$InstallArgument1    = '/add-driver'
    [System.String]$InstallArgument2    = '/install'
    [System.String]$UninstallArgument1  = '/delete-driver'
    [System.String]$UninstallArgument2  = '/uninstall /force'


    # METHODS
    ####################################################################################################

    # PUBLIC METHOD InstallINFDriverArray
    [System.Boolean]InstallINFDriverArray([System.String[]]$INFFullPaths){
        # Write the message
        Write-Host "InstallINFDriverArray: Each INF driver in the array will now be installed... ({$INFFullPaths})"
        # Create an empty result array
        [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()
        # Install each INF driver, and add the result to the result array
        foreach ($INFPath in $INFFullPaths) {
            # If the driver is already installed
            if ($this.TestDriverIsInstalled($INFPath)) {
                # Write the message and add true
                Write-Host ('InstallINFDriverArray: The INF driver is already installed. The Installation will be skipped. ({0})' -f $INFPath) -ForegroundColor Green
                $ResultArray.Add($true)
            } else {
                # Create the argument list
                [System.String[]]$ArgumentsArray = @($this.InstallArgument1,($this.INFArgumentFix -f $INFPath),$this.InstallArgument2)
                $this.ArgumentList = @()
                $this.AddArgumentsToArgumentList($ArgumentsArray)
                # Install the INF driver
                Write-Host ('InstallINFDriverArray: Installing the INF driver... ({0})' -f $INFPath) -ForegroundColor Yellow
                $this.RunPNPUtilProcess($this.ArgumentList)
                # Test if the installation is succcesful
                [System.Boolean]$DriverInstallationIsSuccesful = $this.TestDriverIsInstalled($INFPath)
                # Write the result and add it to the result array
                [System.String]$ResultInFix,[System.String]$TextColor = if ($DriverInstallationIsSuccesful) { 'The INF driver has been successfully installed','Green' } else { 'The installation of the INF driver has failed','Red' }
                Write-Host ('InstallINFDriverArray: {0}. ({1})' -f $ResultInFix,$INFPath) -ForegroundColor $TextColor
                $ResultArray.Add($DriverInstallationIsSuccesful)
            }
        }
        # If the result array contains only true, then the install sequence is succesful
        Write-Verbose ('InstallINFDriverArray: Testing if the result array contains only $true...')
        [System.Boolean]$InstallSequenceIsSuccesful = (-Not($ResultArray -contains $false))
        # Write the result
        [System.String]$ResultInFix,[System.String]$TextColor = if ($InstallSequenceIsSuccesful) { 'is','Green' } else { 'is NOT','Red' }
        Write-Host ('InstallINFDriverArray: The install sequence {0} succesful.' -f $ResultInFix) -ForegroundColor $TextColor
        # Return the result
        Return $InstallSequenceIsSuccesful
    }

    # PUBLIC METHOD UninstallINFDriverArray
    [System.Boolean]UninstallINFDriverArray([System.String[]]$INFFullPaths){
        # Write the message
        Write-Host "UninstallINFDriverArray: Each INF driver in the array will now be uninstalled... ({$INFFullPaths})"
        # Create an empty result array
        [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()
        # Uninstall each INF driver, and add the result to the result array
        foreach ($INFPath in $INFFullPaths) {
            # If the driver is not installed
            if (-Not($this.TestDriverIsInstalled($INFPath))) {
                # Write the message and add true
                Write-Host ('UninstallINFDriverArray: The INF driver is not installed. The Uninstall will be skipped. ({0})' -f $INFPath) -ForegroundColor Green
                $ResultArray.Add($true)
            } else {
                # Create the argument list
                [System.String[]]$ArgumentsArray = @($this.UninstallArgument1,($this.INFArgumentFix -f $INFPath),$this.UninstallArgument2)
                $this.ArgumentList = @()
                $this.AddArgumentsToArgumentList($ArgumentsArray)
                # Uninstall the INF driver
                Write-Host ('UninstallINFDriverArray: Uninstalling the INF driver... ({0})' -f $INFPath) -ForegroundColor Yellow
                $this.RunPNPUtilProcess($this.ArgumentList)
                # Test if the uninstall is succcesful
                [System.Boolean]$DriverUninstallIsSuccesful = (-Not($this.TestDriverIsInstalled($INFPath)))
                # Write the result and add it to the result array
                [System.String]$ResultInFix,[System.String]$TextColor = if ($DriverUninstallIsSuccesful) { 'The INF driver has been successfully uninstalled','Green' } else { 'The uninstall of the INF driver has failed','Red' }
                Write-Host ('UninstallINFDriverArray: {0}. ({1})' -f $ResultInFix,$INFPath) -ForegroundColor $TextColor
                $ResultArray.Add($DriverUninstallIsSuccesful)
            }
        }
        # If the result array contains only true, then the uninstall sequence is succesful
        Write-Verbose ('UninstallINFDriverArray: Testing if the result array contains only $true...')
        [System.Boolean]$UninstallSequenceIsSuccesful = (-Not($ResultArray -contains $false))
        # Write the result
        [System.String]$ResultInFix,[System.String]$TextColor = if ($UninstallSequenceIsSuccesful) { 'is','Green' } else { 'is NOT','Red' }
        Write-Host ('UninstallINFDriverArray: The uninstall sequence {0} succesful.' -f $ResultInFix) -ForegroundColor $TextColor
        # Return the result
        Return $UninstallSequenceIsSuccesful
    }

    ####################################################################################################

    # PRIVATE METHOD RunPNPUtilProcess
    [System.Boolean]RunPNPUtilProcess([System.String[]]$ArgumentList){
        # Run the PNPUtil process
        Write-Host ("RunPNPUtilProcess: Running the PNPUtil process with the following arguments: ($ArgumentList)") -ForegroundColor Yellow
        [System.Int32]$ExitCode = (Start-Process -FilePath $this.PNPUtilExecutable -ArgumentList $ArgumentList -Wait -PassThru).ExitCode
        # Write the result
        [System.Boolean]$ProcessIsSuccesful,[System.String]$TextColor = if ($ExitCode -eq 0) { $true,'Green' } else { $false,'Red' }
        Write-Host ('RunPNPUtilProcess: The ExitCode is: ({0})' -f $ExitCode) -ForegroundColor $TextColor
        # Return the result
        Return $ProcessIsSuccesful
    }

    ####################################################################################################

    # PRIVATE METHOD TestDriverIsInstalled
    [System.Boolean]TestDriverIsInstalled([System.String]$INFPath){
        # Write the message
        Write-Host ('TestDriverIsInstalled: Testing if the driver is installed... ({0})' -f $INFPath)
        # Get the filename of the INPUTINF file
        [System.String]$INPUTINFFileName = $this.GetFileNameFromFilePath($INFPath)
        # Get the paths of the locally installed drivers
        [System.String[]]$LocallyInstalledDriverPaths = $this.GetLocallyInstalledDriverPaths()
        # Create an empty result array
        [System.Collections.Generic.List[System.Boolean]]$ResultArray = @()
        # For each driver path
        $LocallyInstalledDriverPaths | ForEach-Object {
            # Get the filename of the INSTALLEDINF file
            [System.String]$INSTALLEDINFFileName = $this.GetFileNameFromFilePath($_)
            # If the filenames match
            if ($INPUTINFFileName -eq $INSTALLEDINFFileName) {
                # Compare the content and add the result to the result array
                Write-Verbose ('TestDriverIsInstalled: Filename match found: ({0}) and ({1})' -f $INFPath, $_)
                $ResultArray.Add($this.TestContentIsEqual($INFPath,$_))
            }
        }
        # If the result array contains true once, then the driver is installed
        Write-Verbose ('TestDriverIsInstalled: Testing if the result array contains $true...')
        [System.Boolean]$DriverIsInstalled = ($ResultArray -contains $true)
        # Write the result
        [System.String]$ResultInFix = if ($DriverIsInstalled) { 'is' } else { 'is NOT' }
        Write-Host ('TestDriverIsInstalled: The driver {0} installed. ({1})' -f $ResultInFix, $INFPath)
        # Return the result
        Return $DriverIsInstalled
    }

    ####################################################################################################

    # PRIVATE METHOD TestContentIsEqual
    [System.Boolean]TestContentIsEqual([System.String]$FilePath1,[System.String]$FilePath2) {
        # Get the content of the files
        Write-Verbose ('TestContentIsEqual: Comparing the content of the two files: ({0}) and ({1})' -f $FilePath1, $FilePath2)
        [System.String]$ContentOfFile1  = $this.GetRawContent($FilePath1)
        [System.String]$ContentOfFile2  = $this.GetRawContent($FilePath2)
        # Compare the content
        [System.Boolean]$ContentIsEqual = ($ContentOfFile1 -eq $ContentOfFile2)
        # Write the result
        [System.String]$ResultInFix = if ($ContentIsEqual) { 'are' } else { 'are NOT' }
        Write-Verbose ('TestContentIsEqual: The contents of the files {0} equal.' -f $ResultInFix)
        # Return the result
        Return $ContentIsEqual
    }

    ####################################################################################################

    # PRIVATE METHOD GetLocallyInstalledDriverPaths
    [System.String[]]GetLocallyInstalledDriverPaths() {
        # Get the paths of the locally installed drivers
        Write-Verbose 'GetLocallyInstalledDriverPaths: Getting the paths of the locally installed drivers...'
        [System.String[]]$LocallyInstalledDriverPaths = (Get-WindowsDriver -Online).OriginalFileName
        # Return the paths
        Return $LocallyInstalledDriverPaths
    }

    ####################################################################################################

    # PRIVATE METHOD GetRawContent
    [System.String]GetRawContent([System.String]$FilePath) {
        # Get the content of the file
        Write-Verbose ('GetRawContent: Getting the raw content of: ({0})' -f $FilePath)
        [System.String]$RawContent = Get-Content -Path $FilePath -Raw
        # Return the content
        Return $RawContent
    }

    ####################################################################################################

    # PRIVATE METHOD GetFileNameFromFilePath
    [System.String]GetFileNameFromFilePath([System.String]$FilePath) {
        # Get the FileName of the file
        Write-Verbose ('GetFileNameFromFilePath: Getting the filename of: ({0})' -f $FilePath)
        [System.String]$FileName = (Get-ChildItem -Path $FilePath).Name
        # Return the FileName
        Return $FileName
    }

    ####################################################################################################

    # PRIVATE METHOD AddArgumentsToArgumentList
    [void]AddArgumentsToArgumentList([System.String[]]$ArgumentsArray){
        # For each argument
        foreach ($Argument in $ArgumentsArray) {
            # Write the message
            Write-Verbose ('AddArgumentsToArgumentList: Adding the following argument to the argument list: ({0})' -f $Argument)
            # Add the argument to the argument list
            $this.ArgumentList += @($Argument)
        }
    }

    ####################################################################################################

}
