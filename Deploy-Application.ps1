####################################################################################################
<#
.SYNOPSIS
    This function install and uninstalls a collection of applications. These can be MSI, exe, font, driver, etc.
.DESCRIPTION
    This script can be used to deploy applications manually, and also with Intune or SCCM:
    Compile this file with the sourcefiles, into an intunewin file.
    Import the intunewin file into Intune, and use these commandlines to install and uninstall the application:
    - Install Command: %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -WindowStyle Hidden -File .\Deploy-Application.ps1 -Install -Verbose
    - Uninstall command: %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -Executionpolicy Bypass -WindowStyle Hidden -File .\Deploy-Application.ps1 -Uninstall -Verbose
    Or import the Application into SCCM, and use these commandlines to install and uninstall the application:
    - Powershell.exe -ExecutionPolicy Bypass -File Deploy-Application.ps1 -Install -Verbose
    - Powershell.exe -ExecutionPolicy Bypass -File Deploy-Application.ps1 -Uninstall -Verbose
.EXAMPLE
    Deploy-Application.ps1
.EXAMPLE
    Deploy-Application.ps1 -Install
.EXAMPLE
    Deploy-Application.ps1 -Uninstall
.INPUTS
    This script requires at minimum an Application/Asset ID and 1 Deployment Object, to function properly.
    The sourcefiles (EXE, MSI, fonts, drivers, certificates, icons, etc.) can be placed in the rootfolder, or any subfolder. The script wil automatically search the files.
    (If you have setup files with the same name, then add the parentfoldername to the filename, to create a unique string.)
.OUTPUTS
    This script returns no output to the stream. All output is written to the host, and to a logfile.
.NOTES
    Version         : See below (at line 862: DeploymentScriptVersion = 'x.y')
    Author          : Imraan Iotana
    Creation Date   : January 2023
    Last Update     : January 2026
.COPYRIGHT
    Copyright (C) Iotana. All rights reserved.
#>
####################################################################################################


[CmdletBinding(DefaultParameterSetName='Install')]
param (
    # Switch for Installation
    [Parameter(Mandatory=$false,ParameterSetName='Install',Position=0)]
    [System.Management.Automation.SwitchParameter]
    $Install,

    # Switch for Uninstallation
    [Parameter(Mandatory=$true,ParameterSetName='Uninstall',Position=0)]
    [System.Management.Automation.SwitchParameter]
    $Uninstall,

    # Switch for Reinstallation
    [Parameter(Mandatory=$true,ParameterSetName='Reinstall',Position=0)]
    [System.Management.Automation.SwitchParameter]
    $Reinstall
)

begin {

####################################################################################################
####################################################################################################
####################################################################################################
#region ### START PACKAGER INPUT ###

# 1. SET THE ASSET ID
[System.String]$AssetID                 = '<<ASSETID>>'
# 1a. If you want to reverse the deployment order during Uninstall, then set this boolean to true. (Default value is $false. Note: this only works with Uninstall, not with Reinstall.)
[System.Boolean]$ReverseUninstallOrder  = $false
# 1b. If you want to abort the installation sequence, when the deployment of one object fails, then set this boolean to true. (Default value is $true)
[System.Boolean]$AbortWhenOneFails      = $true
# 1c. If the sourcefiles are on a network location, then change this value. Only fill in the Parent Folder. (For example: '//Domain/SCCMSources/NetworkInstallations'. The Application ID will be added automatically. Default value is 'Default')
[System.String]$SourceFilesFolder       = 'Default'
# 1d. The default Buildnumber is 01. If you created a new build of the same application and version, then increment this value.
[System.String]$BuildNumber             = '01'

####################################################################################################
# 2. SET THE DEPLOYMENT OBJECTS
# Add the Deployment Objects here. Please see the explanation in the lower section of this script.
[PSCustomObject[]]$DeploymentsObjectsArray = @(
)
####################################################################################################

#endregion ### END PACKAGER INPUT ###
####################################################################################################
####################################################################################################
####################################################################################################
### NO PACKAGER INPUT BELOW THIS POINT ###




####################################################################################################
<#region ###### EXPLANATION AND EXAMPLE ######

Instructions:
Add DeploymentObjects to the DeploymentsObjectsArray. The objects will be deployed from top to bottom.

THIS IS AN EXAMPLE:
The following example firstly installs an MSI, then waits 10 seconds, then configures the application, and the removes the desktopshortcut:
[PSCustomObject[]]$DeploymentsObjectsArray = @(
    @{ # Install the main application
        Type                        = 'DEPLOYMSI'
        MSIBaseName                 = 'TeamViewer_Host'
        MSTBaseName                 = 'TeamViewer_WithMyChanges'
        MSPBaseNames                = @('Patch_1.2','Patch_1.3')
        AdditionalArguments         = @('ADDLOCAL=ALL','ALLUSERS=1')
        InstallSuccessExitCodes     = @(0)
        UninstallSuccessExitCodes   = @(0)
    }
    @{ # Wait for the installation to finish
        Type                        = 'DEPLOYPAUSE'
        SecondsToPause              = '10'
        PauseDuringInstall          = $true
        PauseDuringUninstall        = $false
    }
    @{ # Configure the application
        Type                        = 'RUNEXE'
        ExeFullPath                 = 'C:\Program Files (x86)\TeamViewer\TeamViewer.exe'
        ArgumentList                = @('assignment','--id 0001CoABChBKuKbwRXwR7YjOAt758SqwBJYzjOwkVDKLFM9K3n4ze','--retries=3','--timeout=120')
        WaitUntilFinished           = $true
        RunDuringInstall            = $true
        RunDuringUninstall          = $false
    }
    @{ # Remove the desktop shortcut
        Type                        = 'REMOVESHORTCUT'
        ShortcutFileName            = 'TeamViewer.lnk'
        RemoveFromDesktop           = $true
        RemoveFromStartMenu         = $false
        RemoveDuringInstall         = $true
        RemoveDuringUninstall       = $false
    }
)

#endregion ###### EXPLANATION AND EXAMPLE ######
#>

####################################################################################################
<#region ### DEPLOYMENT OBJECT TEMPLATES ###


####################################################################################################
###################################### GENERAL INSTALLATIONS #######################################

###### TEMPLATE DEPLOYMSI OBJECT ###### 5.6
# Copy from here:
    @{
        Type                        = 'DEPLOYMSI'
        MSIBaseName                 = ''        # (Mandatory String) Set the MSI BASENAME WITHOUT the extension (.msi). Example: 'Orca-x86_en-us'.
        MSTBaseName                 = ''        # (Optional String) Set the MST BASENAME WITHOUT the extension (.mst). Example: 'Orca_WithMyAdjustments'. (If there is no MST file then leave this empty.)
        MSPBaseNames                = @()       # (Optional String Array) Set the MSP BASENAMES WITHOUT the extensions (.msp). Example: @('OrcaPatch01','OrcaPatch02'). (If there are no MSP's then leave this empty.)
        AdditionalArguments         = @('ADDLOCAL=ALL','ALLUSERS=1','REBOOT=Suppress')  # (Optional String Array) Add any ADDITIONAL INSTALL arguments. Example: @('DATABASE=SQL01','AUTOUPDATE=OFF'). (If there are no additional arguments then leave this empty.)
        InstallSuccessExitCodes     = @(0,3010) # (Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the MSI. Example: @(0,123) (The default value is @(0,3010).)
        UninstallSuccessExitCodes   = @(0,3010) # (Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the MSI. Example: @(0,123) (The default value is @(0,3010).)
    }
###### TEMPLATE DEPLOYMSI OBJECT ###### 5.6

###### TEMPLATE REMOVEMSI OBJECT ###### 5.6
# NOTE : This object only uninstalls an MSI. This can be used for example, to remove a previous version of an MSI, before installing the new version.
# Copy from here:
    @{
        Type                        = 'REMOVEMSI'
        MSIBaseNamesOrProductCodes  = @()       # (Mandatory String Array) Enter EITHER the MSI Filename OR the MSI Productcode. Example: @('MyApplication.msi','{6B29FC40-CA47-1067-B31D-00DD010662DA}'). (If an MSI is entered, then also provide that file in the sourcefiles.)
        RemoveDuringInstall         = $true     # (Mandatory Boolean) If the MSI should be removed DURING INSTALL, then set this to $true.
        RemoveDuringUninstall       = $false    # (Mandatory Boolean) If the MSI should be removed DURING UNINSTALL, then set this to $true.
        UninstallSuccessExitCodes   = @(0,3010) # (Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the MSI. Example: @(0,123) (The default value is @(0,3010).)
    }
###### TEMPLATE REMOVEMSI OBJECT ###### 5.6

###### TEMPLATE DEPLOYEXECUTABLE OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYEXECUTABLE'
        InstallEXEBaseName          = ''        # (Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: 'setup'
        InstallArguments            = @()       # (Optional String Array) Set the INSTALL ARGUMENTS for the Executable. Example: @('/SILENT','/nodesktopshortcut')
        InstallSuccessExitCodes     = @(0)      # (Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
        UninstallEXEOnLocalSystem   = ''        # (Exclusive String) If the UNINSTALL EXE file is on the Local System, then enter the FULL PATH. Example: 'C:\Program Files\MyApplication\Uninstall.exe'
        UninstallEXEBaseName        = ''        # (Exclusive String) If the UNINSTALL EXE file is in the Source Files, then enter the BASENAME. Example: 'setup'
        UninstallArguments          = @()       # (Optional String Array) Set the UNINSTALL ARGUMENTS for the Executable. Example: @('/SILENT')
        UninstallSuccessExitCodes   = @(0)      # (Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
        ZipFileBaseName             = ''        # (Optional String) If the Source Files are in a zip file, then set the BASENAME of the zip-file, EXCLUDING the extension (.zip). Example: 'MyZipFile'.
    }
###### TEMPLATE DEPLOYEXECUTABLE OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYISSSETUP OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYISSSETUP'
        InstallEXEBaseName          = ''        # (Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: 'setup'
        InstallISSBaseName          = ''        # (Mandatory String) Set the INSTALL INF BASENAME WITHOUT the extension. Example: 'InstallationConfuguration'.
        AdditionalInstallArguments  = @()       # (Optional String Array) Set any ADDITIONAL INSTALL ARGUMENTS for the Executable. Example: @('/norestart','/nodesktopshortcut')
        InstallSuccessExitCodes     = @(0)      # (Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
        UninstallEXEOnLocalSystem   = ''        # (Exclusive String) If the UNINSTALL EXE file is on the Local System, then enter the FULL PATH. Example: 'C:\Program Files\MyApplication\Uninstall.exe'
        UninstallEXEInSourceFiles   = ''        # (Exclusive String) If the UNINSTALL EXE file is in the Source Files, then enter the BASENAME. Example: 'setup'
        UninstallISSBaseName        = ''        # (Optional String) Set the UNINSTALL INF BASENAME WITHOUT the extension. Example: 'UninstallConfuguration'.
        AdditionalUninstallArguments = @()      # (Optional String Array) Set any ADDITIONAL UNINSTALL ARGUMENTS for the Executable. Example: @('/norestart')
        UninstallSuccessExitCodes   = @(0)      # (Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
    }
###### TEMPLATE DEPLOYISSSETUP OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYINNOSETUP OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYINNOSETUP'
        InstallEXEBaseName          = ''        # (Mandatory String) Set the INSTALL EXE BASENAME WITHOUT the extension. Example: 'setup'
        InstallINFBaseName          = ''        # (Mandatory String) Set the INSTALL INF BASENAME WITHOUT the extension. Example: 'InstallationConfuguration'.
        AdditionalInstallArguments  = @('/VERYSILENT') # (Optional String Array) Set the INSTALL ARGUMENTS for the Executable. Example: @('/SILENT','/nodesktopshortcut')
        InstallSuccessExitCodes     = @(0)      # (Mandatory Integer Array) Set the INSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
        UninstallEXEFilePath        = ''        # (Optional String) Set the UNINSTALL EXE file path INCLUDING the extension (.exe). If there is no executable to run during UNINSTALL, then leave this empty.
        UninstallArguments          = @('/VERYSILENT') # (Optional String Array) Set the UNINSTALL ARGUMENTS for the Executable. Example: @('/SILENT')
        UninstallSuccessExitCodes   = @(0)      # (Mandatory Integer Array) Set the UNINSTALL SUCCESS EXIT CODES for the Executable. Example: @(0,123) (The default value is @(0).)
    }
###### TEMPLATE DEPLOYINNOSETUP OBJECT ###### 5.5.3

###################################### GENERAL INSTALLATIONS #######################################
####################################################################################################



####################################################################################################
######################################## FILES AND FOLDERS #########################################

###### TEMPLATE DEPLOYBASICFOLDERCOPY OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYBASICFOLDERCOPY'
        FolderToCopy                = ''        # (Mandatory String) Set NAME OF THE FOLDER to copy. Example: 'MyApplication'
        DestinationParentFolder     = 'C:\Program Files' # (Mandatory String) Set the destination PARENT folder to which your folder will be copied. Example: 'C:\Program Files'
        KeepCurrentFolderName       = $true     # (Mandatory Boolean) If you want to keep the current foldername, then set this value to $true. Otherwise it will be renamed to the ApplicationID.
    }
###### TEMPLATE DEPLOYBASICFOLDERCOPY OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYCOMPRESSEDFOLDER OBJECT######## 5.5.2
# Copy from here:
    @{
        Type                        = 'DEPLOYCOMPRESSEDFOLDER'
        ZipFileBaseName             = ''        # (Mandatory String) Set the BASENAME of the zip-file, WITHOUT the extension (.zip). Example: 'MyZipFile'.
        InstallationFolder          = 'C:\Program Files' # (Mandatory String) Set the INSTALLATION FOLDER to which the zipfile will be extracted. Example: 'C:\Program Files\MyApplication'
        IgnoreTopFolderInZipFile    = $true     # (Mandatory Boolean) If (after extraction) the topmost folder should be ignored, then set this value to $true.
    }
###### TEMPLATE DEPLOYCOMPRESSEDFOLDER OBJECT######## 5.5.2

###### TEMPLATE DEPLOYBASICFILECOPY OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYBASICFILECOPY'
        FileToCopy                  = ''        # (Mandatory String) Set NAME of the FILE to copy. Example: 'MyConfiguration.xml'
        DestinationFolder           = ''        # (Mandatory String) Set the DESTINATION FOLDER to which your file will be copied. Example: 'C:\ProgramData\MyApplication'
        OverwriteExistingFile       = $false    # (Mandatory Boolean) If an existing file needs to be overwritten, then set this value to $true.
        RemoveDuringUninstall       = $false    # (Mandatory Boolean) If the file needs to be removed during uninstall, then set this value to $true.
    }
###### TEMPLATE DEPLOYBASICFILECOPY OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYSYSTEMFILECOPY OBJECT ###### 5.5.3
# This object copies a file from the local system, to a folder on the local system.
# Copy from here:
    @{
        Type                        = 'DEPLOYSYSTEMFILECOPY'
        FilePathToCopy              = ''        # (Mandatory String) Set FULL PATH of the FILE to copy. Example: 'C:\Windows\System32\Robocopy.exe'
        DestinationFolder           = ''        # (Mandatory String) Set the DESTINATION FOLDER to which your file will be copied. Example: 'C:\Program Files\MyApplication'
        NewFileName                 = ''        # (Optional String) If the file must be renamed, then set NEW NAME of the file to copy. Example: 'MyCopyOfRobocopy.exe'. Otherwise leave this empty.
        OverwriteExistingFile       = $false    # (Mandatory Boolean) If an existing file needs to be overwritten, then set this value to $true.
        CopyDuringInstall           = $true     # (Mandatory Boolean) If the file needs to be copied during uninstall, then set this value to $true.
        CopyDuringUninstall         = $false    # (Mandatory Boolean) If the file needs to be copied during uninstall, then set this value to $true.
    }
###### TEMPLATE DEPLOYSYSTEMFILECOPY OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYPOWERSHELLAPP OBJECT ###### 5.6
# Copy from here:
    @{
        Type                        = 'DEPLOYPOWERSHELLAPP'
        Ps1FileBaseName             = ''        # (Mandatory String) Set the BASENAME of the PS1-file, WITHOUT the extension (.ps1). Example: 'MyScript'.
        ShortcutDisplayName         = ''        # (Mandatory String) Set the DISPLAYNAME of the shortcut. Example: 'Start MyScript'
        StartMenuSubFolder          = ''        # (Optional String) Set the Startmenu SUBFOLDER. Example: 'My Application'
    }
###### TEMPLATE DEPLOYPOWERSHELLAPP OBJECT ###### 5.6

###### TEMPLATE DEPLOYSHORTCUT OBJECT ###### 5.5.2
# Copy from here:
    @{
        Type                        = 'DEPLOYSHORTCUT'
        DisplayName                 = ''        # (Mandatory String) Set the DISPLAYNAME of the Shortcut. Example: 'Help for Users'
        TargetFilePath              = ''        # (Mandatory String) Set the FULL PATH of the Target File. Example: 'C:\Program Files\ArcGIS\help.exe'
        WorkingDirectory            = ''        # (Optional String) Set the WORKING DIRECTORY of the Shortcut. Example: 'C:\Program Files\ArcGIS'
        Arguments                   = ''        # (Optional String) Set the ARGUMENTS for the Target File. Example: '-readonly'
        IconFilePath                = ''        # (Optional String) Set the FULL PATH of the ICON FILE, INCLUDING the extension (.ico). Example: 'C:\windows\cross.ico'
        StartMenuSubFolder          = ''        # (Optional String) Set the Startmenu SUBFOLDER. Example: 'My Application'
    }
###### TEMPLATE DEPLOYSHORTCUT OBJECT ###### 5.5.2

###### TEMPLATE REMOVESHORTCUT OBJECT ######
# Copy from here:
    @{
        Type                        = 'REMOVESHORTCUT'
        ShortcutFileName            = ''        # (Mandatory String) Set the FILENAME of the SHORTCUT to remove, INCLUDING the extension. Examples: 'Acrobat Cloud.lnk' or 'Online Registration.url'
        RemoveDuringInstall         = $true     # (Mandatory Boolean) If the shortcut must be removed during INSTALL, then set this value to $true.
        RemoveDuringUninstall       = $false    # (Mandatory Boolean) If the shortcut must be removed during UNINSTALL, then set this value to $true.
        RemoveFromDesktopOnly       = $false    # (Optional Boolean) If the shortcut must be removed from the DESKTOP only, then set this value to $true. (If false, it will be removed from both Desktop and Startmenu)
    }
###### TEMPLATE REMOVESHORTCUT OBJECT ######

######################################## FILES AND FOLDERS #########################################
####################################################################################################



####################################################################################################
############################################ MS OFFICE #############################################

###### TEMPLATE DEPLOYMSOFFICE OBJECT ###### 5.5.2
# Copy from here:
    @{
        Type                        = 'DEPLOYMSOFFICE'
        SetupFileBaseName           = ''        # (Mandatory String) Set the BASENAME the SETUP file. Example: 'setup'
        InstallXMLFileBaseName      = ''        # (Mandatory String) Set the BASENAME the CONFIGURATION file. Example: 'Office2024Configuration'
        ProductsToLicense           = @()       # (Optional String Array) Set the PRODUCT ID's that need to be licensed. The PIDKEY has to be in the XML. Example: @('ProPlus2024Volume','VisioPro2024Volume'). When using MS Office AutoActivation, then leave this empty.
    }
###### TEMPLATE DEPLOYMSOFFICE OBJECT ###### 5.5.2

###### TEMPLATE DEPLOYTRUSTEDLOCATION OBJECT ###### 5.5.2
# Copy from here:
    @{
        Type                        = 'DEPLOYTRUSTEDLOCATION'
        TrustedLocationPath         = ''        # (Mandatory String) Set the FULL PATH of the Trusted Location. Example: 'C:\Data\ExtraOfficeFiles'
        OfficeProduct               = ''        # (Mandatory String) Set the OFFICE PRODUCT for which the Trusted Location must be added. Valid values are: Word, Excel, PowerPoint, Access
        OfficeVersion               = '2024'    # (Mandatory String) Set the OFFICE VERSION. Example: '2024'
        AllowSubfolders             = $true     # (Mandatory Boolean) If the SUBFOLDERS of the Trusted Location should also be allowed, then set this value to $true.
    }
###### TEMPLATE DEPLOYTRUSTEDLOCATION OBJECT ###### 5.5.2

############################################ MS OFFICE #############################################
####################################################################################################



####################################################################################################
##################################### LOCAL GROUPS AND USERS #######################################

###### TEMPLATE DEPLOYLOCALGROUP OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYLOCALGROUP'
        LocalGroupName              = ''        # (Mandatory String) The NAME of the LOCAL GROUP you wish to create. Example: 'Adobe_Administrators'
        Description                 = ''        # (Optional String) The DESCRIPTION of the LOCAL GROUP. Example: 'Administrators of Adobe Products'
        MakeMemberOfParentGroups    = @()       # (Optional String Array) The NAMES of the PARENT GROUPS, that this new Group must become a member of. Example: @('Administrators','Guests')
        AddMemberUsersOrGroups      = @()       # (Optional String Array) The NAMES of the MEMBERS, you wish to ADD to this new Group. Example: @('DOMAIN\ADGroupName1','DOMAIN\ADGroupName2')
        CreateDuringInstall         = $true     # (Mandatory Boolean) If the GROUP must be CREATED during INSTALL, then set this value to $true.
        RemoveDuringUninstall       = $false    # (Mandatory Boolean) If the GROUP must be REMOVED during UNINSTALL, then set this value to $true. (Note: this can also be used to cleanup groups, that you did not create)
    }
###### TEMPLATE DEPLOYLOCALGROUP OBJECT ###### 5.5.3

###### TEMPLATE REMOVELOCALGROUPMEMBER OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'REMOVELOCALGROUPMEMBER'
        LocalGroupName              = ''        # (Mandatory String) The NAME of the LOCAL GROUP. Example: 'Adobe_Users'
        MemberNameToRemove          = ''        # (Exclusive String) The NAME of the MEMBER that will be REMOVED. Example: 'Everyone'. (This is exlusive with MemberSIDToRemove)
        MemberSIDToRemove           = ''        # (Exclusive String) The SID of the MEMBER that will be REMOVED. Example: 'S-1-1-0'. (This is exlusive with MemberNameToRemove)
        RemoveDuringInstall         = $true     # (Mandatory Boolean) If the MEMBER must be removed during INSTALL, then set this value to $true.
        RemoveDuringUninstall       = $false    # (Mandatory Boolean) If the MEMBER must be removed during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE REMOVELOCALGROUPMEMBER OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYLOCALUSER OBJECT ###### (Not yet created. Will be added in the future)
# Copy from here:
    @{
        Type                        = 'DEPLOYLOCALUSER'
        LocalGroupName              = ''        # (Mandatory String) The NAME of the LOCAL GROUP you wish to create. Example: 'Adobe_Users'
        MakeMemberOf                = ''        # (Optional String) The NAME of the PARENT GROUP, that this new Group must become a member of. Example: 'Administrators'
    }
###### TEMPLATE DEPLOYLOCALGROUP OBJECT ######

##################################### LOCAL GROUPS AND USERS #######################################
####################################################################################################



####################################################################################################
########################################### RUN SCRIPTS ############################################

###### TEMPLATE RUNCMDFILE OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'RUNCMDFILE'
        CmdBatFileName              = ''        # (Mandatory String) Set the FILENAME of the cmd/bat-file, INCLUDING the extension (.cmd or .bat). Example: 'MyConfiguration.bat'.
        ArgumentList                = @()       # (Optional String Array) Set the EXTRA ARGUMENTS for the cmd/bat. Example: @('/SILENT','/nodesktopshortcut')
        RunDuringInstall            = $true     # (Mandatory Boolean) If the script must RUN during INSTALL, then set this value to $true.
        RunDuringUninstall          = $false    # (Mandatory Boolean) If the script must RUN during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE RUNCMDFILE OBJECT ###### 5.5.3

###### TEMPLATE RUNPS1SCRIPT OBJECT ######
# PS1FileName (Mandatory String)                    : Set the file name of the script INCLUDING the extension (.ps1). Example: 'MyScript.ps1'
# PS1PathIsAbsolute (Mandatory Boolean)             : If the script is on the local system, the set the FULL PATH as the PS1FileName, and set this to true.
# RunDuringInstall (Mandatory Boolean)              : If the script must run during INSTALL, then set this to true.
# InstallArguments (Non-mandatory Array)            : Set the INSTALL ARGUMENTS for the script. Example: @('-Verbose')
# InstallSuccessExitCodes (Mandatory Array)         : Set the INSTALL SUCCESS EXIT CODES for the script, the default value is @(0). Example: @(0,1223,1651)
# RunDuringUninstall (Mandatory Boolean)            : If the script must run during UNINSTALL, then set this to true.
# UninstallArguments (Non-mandatory Array)          : Set the UNINSTALL ARGUMENTS for the script. Example: @('-Verbose')
# UninstallSuccessExitCodes (Mandatory Array)       : Set the UNINSTALL SUCCESS EXIT CODES for the script, the default value is @(0). Example: @(0,1223,1651)
# Copy from here:
    @{
        Type                        = 'RUNPS1SCRIPT'
        PS1FileName                 = ''
        PS1PathIsAbsolute           = $false
        RunDuringInstall            = $true
        InstallArguments            = @()
        InstallSuccessExitCodes     = @(0)
        RunDuringUninstall          = $false
        UninstallArguments          = @()
        UninstallSuccessExitCodes   = @(0)
    }
###### TEMPLATE RUNPS1SCRIPT OBJECT ######

###### TEMPLATE RUNBATCHFILE OBJECT ###### ARCHIVED
# BatchFileName (Mandatory String)      : Set the FILENAME the batchfile that must be started. Example: 'Configuration.bat'
# ArgumentList (Non-mandatory Array)    : Set the ARGUMENTS for the Executable. Example: @('-start','-database:SQL01')
# WaitUntilFinished (Mandatory Boolean) : If the process should wait until the batchfile is done, then set this boolean to $true.
# RunDuringInstall (Mandatory Boolean)  : If this should be executed during INSTALL, then set this value to $true.
# RunDuringUninstall (Mandatory Boolean): If this should be executed during UNINSTALL, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'RUNBATCHFILE'
        BatchFileName               = ''
        ArgumentList                = @()
        WaitUntilFinished           = $true
        RunDuringInstall            = $true
        RunDuringUninstall          = $false
    }
###### TEMPLATE RUNBATCHFILE OBJECT ###### ARCHIVED

###### TEMPLATE DEPLOYPYTHONMODULE OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYPYTHONMODULE'
        PipPathOnLocalSystem        = ''        # (Mandatory String) Set the FULL PATH of pip.exe on the local system. Example: 'C:\Program Files\Python\pip.exe'
        ModulePathOnLocalSystem     = ''        # (Optional String) If the MODULE file is on the Local System, then enter the FULL PATH. Example: 'C:\Program Files\MyApplication\MyModule.whl'
        ModuleFileNameInSourceFiles = ''        # (Optional String) If the MODULE file is in the Source Files, then enter the FILENAME. Example: 'MyModule.tar.gz'
    }
###### TEMPLATE DEPLOYPYTHONMODULE OBJECT ###### 5.5.3

########################################### RUN SCRIPTS ############################################
####################################################################################################



####################################################################################################
############################################## SQL #################################################

###### TEMPLATE DEPLOYSQLEXPRESS OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                            = 'DEPLOYSQLEXPRESS'
        SetupFileBaseName               = ''    # (Mandatory String) Set the BASENAME of the SETUP FILE, WITHOUT the extension (.exe). Example: 'SQLEXPR_x64_ENU'.
        InstallConfigurationBaseName    = ''    # (Mandatory String) Set the BASENAME the CONFIGURATION FILE that will be used for INSTALLATION, WITHOUT the extension (.ini). Example: 'InstallConfiguration'
        UninstallConfigurationBaseName  = ''    # (Mandatory String) Set the BASENAME the CONFIGURATION FILE that will be used for UNINSTALL, WITHOUT the extension (.ini). Example: 'UninstallConfiguration'
    }
###### TEMPLATE DEPLOYSQLEXPRESS OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYSQLSCRIPT OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYSQLSCRIPT'
        SQLFileBaseName             = ''        # (Mandatory String) Set the BASENAME of the SQLFILE, WITHOUT the extension (.sql). Example: 'ConfigureDatabase'
        SQLInstanceName             = ''        # (Mandatory String) Set the NAME of the SQL INSTANCE. Example: 'SQLEXPRESS2012'
        RunScriptDuringInstall      = $true     # (Mandatory Boolean) If the SCRIPT should RUN during INSTALL, then set this value to $true.
        RunScriptDuringUninstall    = $false    # (Mandatory Boolean) If the SCRIPT should RUN during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE DEPLOYSQLSCRIPT OBJECT ######

############################################## SQL #################################################
####################################################################################################



####################################################################################################
########################################### REGISTRY ###############################################

###### TEMPLATE DEPLOYREGFILE OBJECT ######### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYREGFILE'
        REGFileBaseName             = ''        # (Mandatory String) Set the BASENAME of the REGFILE (WITHOUT the extension). Example: 'AppSettings'
        ImportDuringInstall         = $true     # (Mandatory Boolean) If the regfile should be IMPORTED during INSTALL, then set this value to $true.
        ImportDuringUninstall       = $false    # (Mandatory Boolean) If the regfile should be IMPORTED during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE DEPLOYREGFILE OBJECT ######### 5.5.3

########################################### REGISTRY ###############################################
####################################################################################################



####################################################################################################
############################################## OTHER ###############################################

###### TEMPLATE DEPLOYSYSTEMPATH OBJECT ######### 5.5.1
# Copy from here:
    @{
        Type                        = 'DEPLOYSYSTEMPATH'
        Directory                   = ''        # (Mandatory String) Set the DIRECTORY that should be added to the SYSTEM Environment Variable PATH. (Example: 'C:\Program Files\MyNewApplication')
        AddDuringInstall            = $true     # (Mandatory Boolean) If the Path should be ADDED during INSTALL, then set this to $true.
        RemoveDuringUninstall       = $true     # (Mandatory Boolean) If the Path should be REMOVED during UNINSTALL, then set this to $true.
    }
###### TEMPLATE DEPLOYSYSTEMPATH OBJECT ######### 5.5.1

###### TEMPLATE DEPLOYPROCESSSTOP OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYPROCESSSTOP'
        ProcessBaseName             = ''        # (Mandatory String) Set the BASENAME of the PROCESS to stop (WITHOUT the extension). Example: 'vpn-connector'
        StopDuringInstall           = $false    # (Mandatory Boolean) If the PROCESS must be stopped during INSTALL, then set this value to $true.
        StopDuringUninstall         = $true     # (Mandatory Boolean) If the PROCESS must be stopped during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE DEPLOYPROCESSSTOP OBJECT ###### 5.5.3

###### TEMPLATE DISABLESCHEDULEDTASK OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DISABLESCHEDULEDTASK'
        TaskName                    = ''        # (Mandatory String) Set the NAME of the TASK.
        DisableDuringInstall        = $true     # (Mandatory Boolean) If the TASK should be DISABLED during INSTALL, then set this value to $true.
        DisableDuringUninstall      = $false    # (Mandatory Boolean) If the TASK should be DISABLED during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE DISABLESCHEDULEDTASK OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYWINDOWSPACKAGE OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYWINDOWSPACKAGE'
        CABFileBaseName             = ''        # (Mandatory String) Set the BASENAME of the CAB file (WITHOUT the extension). Example: 'microsoft-windows-netfx3-ondemand-package~31bf3856ad364e35~amd64~~'
    }
###### TEMPLATE DEPLOYWINDOWSPACKAGE OBJECT ###### 5.5.3

###### TEMPLATE DEPLOYPAUSE OBJECT ###### 5.5.3
# Copy from here:
    @{
        Type                        = 'DEPLOYPAUSE'
        SecondsToPause              = ''        # (Mandatory String) Set the length of the pause in SECONDS. Example: '10' (Note: This is a String, not an Integer)
        PauseDuringInstall          = $true     # (Mandatory Boolean) If the PAUSE be executed during INSTALL, then set this value to $true.
        PauseDuringUninstall        = $false    # (Mandatory Boolean) If the PAUSE be executed during UNINSTALL, then set this value to $true.
    }
###### TEMPLATE DEPLOYPAUSE OBJECT ###### 5.5.3

############################################## OTHER ###############################################
####################################################################################################



###### TEMPLATE MSIX OBJECT ######
# MSIXFileNames (Mandatory Array)   : Set the MSIX Filenames WITH the extension. Example: '@('NotepadPlusPlus_8.4.8.1_x64__h8vhay9grb1ec.msix','Orca-5.0.10011x64__h8vhay9grb1ec.msix')'
# Note                              : The MSIX's will be deployed for all users (machine wide).
# Copy from here:
    @{
        Type                        = 'MSIX'
        MSIXFileNames               = @()
    }
###### TEMPLATE MSIX OBJECT ######


###### TEMPLATE DEPLOYACTIVESETUP OBJECT ######### 5.5.1
# HKCURegFileName (Mandatory String)        : Set the REGFILE name (containing the HKCU keys), INCLUDING the extension. Example: 'HKCUSettings.reg'
# ImportDuringInstall (Mandatory Boolean)   : If the regfile should be IMPORTED DURING INSTALL, then set this to $true.
# ImportDuringUninstall (Mandatory Boolean) : If the regfile should be IMPORTED DURING UNINSTALL, then set this to $true.
# Copy from here:
    @{
        Type                        = 'DEPLOYACTIVESETUP'
        HKCURegFileName             = ''
        ImportDuringInstall         = $true
        ImportDuringUninstall       = $false
    }
###### TEMPLATE DEPLOYACTIVESETUP OBJECT ######### 5.5.1


###### TEMPLATE DEPLOYFONT OBJECT ###### 5.5.1
# FontFileNames (Mandatory Array)   : Set the font FILENAMES INCLUDING the EXTENSION (.ttf, .otf). Example: @('Flora.ttf','Fauna.otf')
# Copy from here:
    @{
        Type                        = 'DEPLOYFONT'
        FontFileNames               = @()
    }
###### TEMPLATE DEPLOYFONT OBJECT ###### 5.5.1


###### TEMPLATE FONT OBJECT ######
# FontFileNames (Mandatory Array)   : Set the FONT file names INCLUDING the extension (.ttf, .otf). Example: @('Flora.ttf','Fauna.otf')
# Copy from here:
    @{
        Type                        = 'FONT'
        FontFileNames               = @()
    }
###### TEMPLATE FONT OBJECT ######


###### TEMPLATE VSCODEEXTENSION OBJECT ###### 5.5.1
# VSIXExtensionBaseName (Mandatory String)  : Set the BASENAME of the VSIX file WITHOUT the file-extension. Example: 'ms-vscode.PowerShell-2025.5.0'
# Copy from here:
    @{
        Type                        = 'VSCODEEXTENSION'
        VSCodeExtensionBaseName     = ''
    }
###### TEMPLATE VSCODEEXTENSION OBJECT ###### 5.5.1


###### TEMPLATE CERTIFICATE OBJECT #########
# CertificateFileName (Mandatory String)    : Set the CERTIFICATE file name INCLUDING the extension (.cer, .pfx). Example: 'VendorCertificate.cer'
# CertificateStoreName (Mandatory String)   : Set the STORE name. (The default store is set to TrustedPublisher.)
# Note                                      : The certificate will be deployed for all users (in the local machine segment).
# Copy from here:
    @{
        Type                        = 'CERTIFICATE'
        CertificateFileName         = ''
        CertificateStoreName        = 'TrustedPublisher'
        RemoveDuringUninstall       = $false
    }
###### TEMPLATE CERTIFICATE OBJECT #########


###### TEMPLATE INFDRIVER OBJECT ######
# INFFileNames (Mandatory Array)    : Set the INF file names INCLUDING the extension (.inf). Example: @('driver64.inf','driver32.inf')
# Copy from here:
    @{
        Type                        = 'INFDRIVER'
        INFFileNames                = @()
    }
###### TEMPLATE INFDRIVER OBJECT ######


###### TEMPLATE DEPLOYUSERFILE OBJECT########
# FileToCopy (Mandatory String)             : Set the FILE name INCLUDING the extension. Example: 'settings.ini'
# UserFolder (Mandatory String)             : Set the Userfolder to copy to. Valid values are 'Roaming', 'Local', 'LocalLow' or 'UserProfile'
# SubfolderToCopyTo (Mandatory String)      : Set the subfolder to copy the file to. Example: 'Vendor\Configuration Files'.
# OverwriteExistingFile (Mandatory Boolean) : If an existing file needs to be overwritten, then set this value to $true.
# RemoveDuringUninstall (Mandatory Boolean) : If the file needs to be removed during uninstall, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'DEPLOYUSERFILE'
        FileToCopy                  = ''
        UserProfileLocation         = 'Roaming'
        SubfolderToCopyTo           = ''
        OverwriteExistingFile       = $false
        RemoveDuringUninstall       = $false
    }
###### TEMPLATE DEPLOYUSERFILE OBJECT########


###### TEMPLATE DEPLOYUSERPROFILEFOLDER OBJECT########
# FolderToCopy (Mandatory String)               : Set the FILE name INCLUDING the extension. Example: 'settings.ini'
# UserProfileLocation (Mandatory String)        : Set the UserProfileLocation to copy to. Valid values are 'Roaming', 'Local', 'LocalLow' or 'UserProfile'
# OverwriteExistingFolder (Mandatory Boolean)   : If an existing file needs to be overwritten, then set this value to $true.
# RemoveDuringUninstall (Mandatory Boolean)     : If the folder needs to be removed during uninstall, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'DEPLOYUSERPROFILEFOLDER'
        FolderToCopy                = ''
        UserProfileLocation         = 'Roaming'
        OverwriteExistingFolder     = $false
        RemoveDuringUninstall       = $false
        ValidateSetUserProfile      = @('Roaming','Local','LocalLow','UserProfile')
    }
###### TEMPLATE DEPLOYUSERPROFILEFOLDER OBJECT########


###### TEMPLATE DOTNET35 OBJECT ######
# LocalSourcePath (Non-Mandatory String)    : If there is an on-premise location with the Windows Features, then add this here. If empty then the sourcefiles will be downloaded from the internet.
# RemoveDuringUninstall (Mandatory Boolean) : If DotNet should be removed during UNINSTALL, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'DOTNET35'
        LocalSourcePath             = ''
        RemoveDuringUninstall       = $false
    }
###### TEMPLATE DOTNET35 OBJECT ######


###### TEMPLATE VSTO OBJECT ######
# VSTOPathOrURL (Mandatory String)  : The URL of the VSTO. Example: 'https://VendorURL.com/OfficeAddins/VendorAddin.vsto'
# Note                              : The VSTO can only be installed silently, if the certificate is installed first. You can use the Certificate Object for this.
# Copy from here:
    @{
        Type                        = 'VSTO'
        VSTOPathOrURL               = ''
    }
###### TEMPLATE VSTO OBJECT ######


###### TEMPLATE RUNEXE OBJECT ######
# ExeFullPath (Mandatory String)        : Set the full path of the exe that must be started. Example: 'C:\Program Files\MyApp\MyService.exe'
# ArgumentList (Non-mandatory Array)    : Set the ARGUMENTS for the Executable. Example: @('-start','-database:SQL01')
# WaitUntilFinished (Mandatory Boolean) : If the process should wait until this exe is done, then set this boolean to $true. (E.g. when uninstalling an extra item)
#                                         If the process should NOT wait until this exe is done, then set this boolean to $false. (E.g. when starting a service)
# RunDuringInstall (Mandatory Boolean)  : If this should be executed during INSTALL, then set this value to $true.
# RunDuringUninstall (Mandatory Boolean): If this should be executed during UNINSTALL, then set this value to $true.
# Note                                  : The difference between this object and the DEPLOYEXE object, is that this object can only run a exe on the local system, and does not check for an exitcode.
# Copy from here:
    @{
        Type                        = 'RUNEXE'
        ExeFullPath                 = ''
        ArgumentList                = @()
        WaitUntilFinished           = $true
        RunDuringInstall            = $true
        RunDuringUninstall          = $false
    }
###### TEMPLATE RUNEXE OBJECT ######


###### TEMPLATE ARPENTRY OBJECT ######
# DisplayName (Non mandatory String)        : Set the name of the application. Example: 'Scanner Driver'. (If this is empty, then the AssetID will be used)
# DisplayVersion (Mandatory String)         : Set the version. Example: '1.1'
# Publisher (Mandatory String)              : Set the name of the publisher. Example: 'MyCompany Inc.'
# DisplayIcon (Non mandatory String)        : Set the icon. Example: 'C:\Program Files\MyApp\myicon.ico'. (If this is empty, then shell32.dll,21 will be used).
# UninstallString (Non mandatory String)    : Set the uninstallstring. Example: 'C:\Program Files\MyApp\Uninstall.exe /silent'. (If this is empty, then 'calc.exe' will be used).
# Copy from here:
    @{
        Type                        = 'ARPENTRY'
        AssetID                     = $AssetID
        DisplayName                 = ''
        DisplayVersion              = ''
        Publisher                   = ''
        DisplayIcon                 = ''
        UninstallString             = ''
    }
###### TEMPLATE ARPENTRY OBJECT ######


###### TEMPLATE STOPSERVICE OBJECT ######
# SeriviceName (Mandatory String)       : Set the NAME of the SERVICE.
# DuringInstall (Mandatory Boolean)     : If this should be executed during INSTALL, then set this value to $true.
# DuringUninstall (Mandatory Boolean)   : If this should be executed during UNINSTALL, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'STOPSERVICE'
        ServiceName                 = ''
        StopDuringInstall           = $true
        StopDuringUninstall         = $false
    }
###### TEMPLATE STOPSERVICE OBJECT ######


###### TEMPLATE DISABLESERVICE OBJECT ######
# SeriviceName (Mandatory String)       : Set the NAME of the SERVICE.
# DuringInstall (Mandatory Boolean)     : If this should be executed during INSTALL, then set this value to $true.
# DuringUninstall (Mandatory Boolean)   : If this should be executed during UNINSTALL, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'DISABLESERVICE'
        ServiceName                 = ''
        StopDuringInstall           = $true
        StopDuringUninstall         = $false
    }
###### TEMPLATE DISABLESERVICE OBJECT ######


###### TEMPLATE PAUSE OBJECT ######
# Seconds (Mandatory String)            : Set the length of the pause in SECONDS. Example: '10' (Note: This is a String, not an Integer)
# DuringInstall (Mandatory Boolean)     : If this should be executed during INSTALL, then set this value to $true.
# DuringUninstall (Mandatory Boolean)   : If this should be executed during UNINSTALL, then set this value to $true.
# Copy from here:
    @{
        Type                        = 'PAUSE'
        Seconds                     = ''
        DuringInstall               = $true
        DuringUninstall             = $false
    }
###### TEMPLATE PAUSE OBJECT ######


####################################################################################################
###### ARCHIVED OBJECTS - DO NOT USE ######

# Archived since version 3.2:

###### TEMPLATE ASKUSERSTRING OBJECT ######
# Note: A pop-up will appear to ask the user for input.
#       The input of the user will be written into the file 'C:\ProgramData\Intune\SupportFiles\UserInput\UserInput.ini'.
#       The content of the file will be: UserInput=xxx
#       When deploying this script with Intune, it MUST be installed in USER context, for the popup to appear for the user. 
# Copy from here:
@{
    Type                            = 'ASKUSERSTRING'
}
###### TEMPLATE ASKUSERSTRING OBJECT ######

###### TEMPLATE NETWORKPRINTER OBJECT ######
# PrintServer (Mandatory String)        : Set the name of the printserver WIHOUT the backslashes. Example: 'PSERV201'
# PrinterName (Non mandatory String)    : Set the name to the network printer. Example: 'LP0106'. (If this is empty, then the file 'C:\ProgramData\Intune\SupportFiles\NetworkPrinterFile\NetworkPrinter.ini' will be used.)
# Copy from here:
@{
    Type                            = 'NETWORKPRINTER'
    PrintServer                     = ''
    PrinterName                     = ''
}
###### TEMPLATE NETWORKPRINTER OBJECT ######

###### TEMPLATE MSI OBJECT ######
# MSIFileName (Mandatory String)            : Set the MSI file name INCLUDING the extension (.msi). Example: 'Acrobat.msi'
# MSTFileName (Non-mandatory String)        : Set the MST file name INCLUDING the extension (.mst). If there is no MST file then leave this empty. Example: 'Acrobat.mst'
# MSPFileNames (Non-mandatory Array)        : Set the MSP file names INCLUDING the extension (.msp). If there are no MSP's then leave this empty. Example: @('AcrobatPatch01.msp','AcrobatPatch02.msp')
# AdditionalArguments (Non-mandatory Array) : Add any ADDITIONAL INSTALL arguments. If there are no additional arguments then leave this empty. Example: @('DATABASE=SQL01','AUTOUPDATE=OFF')
# Copy from here:
    @{
        Type                        = 'MSI'
        MSIFileName                 = ''
        MSTFileName                 = ''
        MSPFileNames                = @()
        AdditionalArguments         = @('ADDLOCAL=ALL','ALLUSERS=1')
    }
###### TEMPLATE MSI OBJECT ######


###### TEMPLATE CUSTOMFOLDER OBJECT ######
# FolderToCopy (Mandatory String)               : Set NAME OF THE FOLDER to copy to 'C:\Program Files\'. It will be renamed to the Asset ID.
# ShortcutName (Non mandatory String)           : Set the DISPLAYNAME of the shortcut. Example: 'Text Editor'. (If no shortcut is needed, then leave this empty.)
# TargetFileName (Non Mandatory String)         : Set the NAME of the TargetFileName (that is inside your sourcefolder). Example: 'TextEditor.exe'. (If no shortcut is needed, then leave this empty.)
# Arguments (Non mandatory String)              : Set the ARGUMENTS for the shortcut. Example: '/open:SQL01'
# IconFileName (Non mandatory String)           : Set the name of the ICON file INCLUDING the extension (.ico). Example: 'cross.ico'. (If this is empty, then the icon of the TargetFileName will be used.)
# WorkingDirectory (Non mandatory String)       : Set the name of the WORKING DIRECTORY. (If this is empty, then the location of the TargetFileName will be used.)
# InStartmenu (Mandatory Boolean)               : If the shortcut needs to be placed in the STARTMENU, then set this value to $true.
# OnDesktop (Mandatory Boolean)                 : If the shortcut needs to be placed on the DESKTOP, then set this value to $true.
# KeepOriginalFolderName (Mandatory Boolean)    : If you want to keep the original folder name instead of the Asset ID, then set this value to $true.
# DivertToProgramData (Mandatory Boolean)       : If you need to divert from 'C:\Program Files\' (i.e. for spaces in foldernames, or permissions), then set this value to $true. In this case, the folder 'C:\ProgramData\' will be used instead.
# DivertToRoot (Mandatory Boolean)              : If you need to divert from 'C:\Program Files\' (i.e. for spaces in foldernames, or permissions), then set this value to $true. In this case, the folder 'C:\' will be used instead.
# Copy from here:
    @{
        Type                        = 'CUSTOMFOLDER'
        FolderToCopy                = ''
        ShortcutName                = ''
        TargetFileName              = ''
        Arguments                   = ''
        IconFileName                = ''
        WorkingDirectory            = ''
        InStartmenu                 = $true
        OnDesktop                   = $false
        KeepOriginalFolderName      = $false
        DivertToProgramData         = $false
        DivertToRoot                = $false
    }
###### TEMPLATE CUSTOMFOLDER OBJECT ######


###### ARCHIVED OBJECTS ######
####################################################################################################


#endregion ### DEPLOYMENT OBJECT TEMPLATES ###
#>
####################################################################################################

    # Create the Global DeploymentObject
    [PSCustomObject]$Global:DeploymentObject = @{
        # Main
        Name                    = [System.String]'Universal Deployment Script'
        DeploymentScriptVersion = [System.String]'5.6.2'
        CompanyName             = [System.String]'KeyStone'
        # Deployment Handlers
        AssetID                 = [System.String]$AssetID
        ApplicationID           = [System.String]$AssetID
        BuildNumber             = [System.String]$BuildNumber
        DeploymentObjects       = [PSCustomObject[]]$DeploymentsObjectsArray
        Action                  = [System.String]$PSCmdlet.ParameterSetName
        ReverseUninstallOrder   = [System.Boolean]$ReverseUninstallOrder
        AbortWhenOneFails       = [System.Boolean]$AbortWhenOneFails
        # Folders
        SupportScriptsFolder    = [System.String](Join-Path -Path $PSScriptRoot -ChildPath 'Deploy-ApplicationSupport')
        SourceFilesFolder       = if ($SourceFilesFolder -eq 'Default') { $PSScriptRoot } else { Join-Path -Path $SourceFilesFolder -ChildPath $AssetID }
        Rootfolder              = [System.String]$PSScriptRoot
        LogFolder               = [System.String](Join-Path -Path $ENV:ProgramData -ChildPath 'Application Installation Logs')
        SystemStartmenuFolder   = [System.String](Join-Path -Path $ENV:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs')
        SystemDesktopFolder     = [System.String]'C:\Users\Public\Desktop'
        # Files
        PowerShellExePath       = [System.String](Join-Path -Path ([System.Environment]::SystemDirectory) -ChildPath 'WindowsPowerShell\v1.0\powershell.exe')
        MSIExecutablePath       = [System.String](Join-Path -Path $ENV:SystemRoot -ChildPath 'System32\msiexec.exe')
        REGExecutablePath       = [System.String](Join-Path -Path $ENV:SystemRoot -ChildPath 'System32\REG.exe')
        # Administrative Handlers
        TimeStamp               = [System.String]((Get-Date -UFormat '%Y%m%d%R') -replace ':','')
        DeploymentResult        = [System.String]'DEFAULT_VALUE'
    }

    # Add the Module path to the Environment Variable
    $ENV:PSModulePath += ";$($Global:DeploymentObject.SupportScriptsFolder)"
    # Import the Write module
    Import-Module ModuleWrite

    # Get all ps1 files from the support folder
    [System.IO.FileInfo[]]$Local:AllSupportScriptFiles = Get-ChildItem -Path $Global:DeploymentObject.SupportScriptsFolder -Recurse -File -Include *.ps1 -ErrorAction SilentlyContinue
    # Unblock the ps1 files
    $Local:AllSupportScriptFiles | Unblock-File
    # Dot-source the ps1 files (External functions can be used after this line)
    $Local:AllSupportScriptFiles | ForEach-Object { . $_.FullName }
    
    # Add the Process method
    Add-Member -InputObject $Global:DeploymentObject -MemberType ScriptMethod -Name Process -Value {
        # Deploy the Objects
        Deploy-Objects
    }
}

process {
    $Global:DeploymentObject.Process()
}

end {
}

### END OF DEPLOYMENTSCRIPT
####################################################################################################
